import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/notification_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/services/app_message_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class NotificationState {
  final bool isLoading;
  final List<AppNotification> notifications;
  final int unreadCount;
  const NotificationState({
    this.isLoading = true,
    this.notifications = const [],
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    bool? isLoading, List<AppNotification>? notifications, int? unreadCount,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// Provider for our new AppMessageService
final appMessageServiceProvider = Provider((ref) => AppMessageService());

// The main provider for our UI to interact with
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref _ref;
  // Hold a reference to our new service
  final AppMessageService _appMessageService;
  RealtimeChannel? _realtimeChannel;

  NotificationNotifier(this._ref)
      // Read the new service provider in the initializer list
      : _appMessageService = _ref.read(appMessageServiceProvider),
        super(const NotificationState()) {
    _ref.listen<User?>(appProvider.select((s) => s.currentUser), (previous, next) {
      if (next != null && (previous == null || previous.id != next.id)) _initialize();
      else if (next == null && previous != null) _disposeResources();
    });
    if (_ref.read(appProvider).currentUser != null) _initialize();
  }

  Future<void> _initialize() async {
    await _disposeResources();
    await loadNotifications();
    final user = _ref.read(appProvider).currentUser;
    if (user == null) return;
    _realtimeChannel = Supabase.instance.client.channel('public-notifications:${user.id}');
    _realtimeChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      callback: (payload) => loadNotifications(),
    ).subscribe();
  }

  Future<void> loadNotifications() async {
    if (mounted && state.isLoading == false) state = state.copyWith(isLoading: true);
    try {
      // Use the new service to fetch notifications
      final notifications = await _appMessageService.fetchAllNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      if (mounted) state = state.copyWith(notifications: notifications, unreadCount: unreadCount, isLoading: false);
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markNotificationAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    // Use the new service to mark as read
    await _appMessageService.markAsRead(notification);
    final updatedList = state.notifications.map((n) {
      if (n.id == notification.id) n.isRead = true;
      return n;
    }).toList();
    if (mounted) state = state.copyWith(notifications: updatedList, unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0);
  }

  Future<void> _disposeResources() async {
    if (_realtimeChannel != null) {
      await Supabase.instance.client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
    if (mounted) state = const NotificationState(isLoading: false);
  }

  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }
}

// The provider for unauthenticated users, now using the new service
final publicNotificationProvider = FutureProvider<List<AppNotification>>((ref) async {
  // Read the service from its provider
  final service = ref.watch(appMessageServiceProvider);
  return service.fetchPublicNotifications();
});