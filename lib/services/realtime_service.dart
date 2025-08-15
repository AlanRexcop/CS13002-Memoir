// lib/services/realtime_service.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/cloud_file.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class RealtimeService {
  final Ref _ref;
  final SupabaseClient _client;
  RealtimeChannel? _filesChannel;

  RealtimeService(this._ref) : _client = Supabase.instance.client;

  void subscribe() {
    if (_filesChannel != null) {
      return;
    }
    //print('Subscribing to real-time file changes...');

    _filesChannel = _client
        .channel('db-files')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'files',
          callback: (payload) {
            //print('Realtime change received: ${payload.toString()}');
            _handlePayload(payload);
          },
        )
        .subscribe((status, [ref]) {
            //print('Realtime subscription status: $status');
        });
  }

  Future<void> _handlePayload(PostgresChangePayload payload) async {
    final eventType = payload.eventType;
    
    switch (eventType) {
      case PostgresChangeEvent.insert:
      case PostgresChangeEvent.update:
        final newRecord = payload.newRecord;
        if (newRecord.isEmpty) return;

        final cloudFile = CloudFile.fromSupabase(newRecord);
        if (cloudFile.isFolder) return;
        
        await _handleUpsert(cloudFile);
        break;

      case PostgresChangeEvent.delete:
        final oldRecord = payload.oldRecord;
        if (oldRecord.isEmpty || oldRecord['id'] == null) return;
        await _handleDelete();
        break;

      default:
        print('Realtime: Unhandled event type received: $eventType');
        break;
    }
  }

  Future<void> _handleUpsert(CloudFile cloudFile) async {
    try {
      final vaultRoot = _ref.read(appProvider).storagePath;
      final userRootPath = _ref.read(cloudNotifierProvider).userRootPath;

      if (vaultRoot == null || userRootPath == null || cloudFile.cloudPath == null) {
        print('Cannot handle upsert: missing vault or cloud paths.');
        return;
      }
      
      print('Realtime: Downloading update for ${cloudFile.cloudPath}');

      await _ref.read(cloudNotifierProvider.notifier).downloadFile(cloudFile, vaultRoot);

      await _ref.read(appProvider.notifier).refreshVault();
      print('Realtime: Local file updated and vault refreshed.');

    } catch (e) {
      print('Error handling real-time upsert: $e');
    }
  }

  Future<void> _handleDelete() async {
    try {
      print('Realtime: DELETE event received. Refreshing vault.');
      await _ref.read(appProvider.notifier).refreshVault();
    } catch (e) {
      print('Error handling real-time delete: $e');
    }
  }

  void unsubscribe() {
    if (_filesChannel != null) {
      print('Unsubscribing from real-time file changes...');
      _client.removeChannel(_filesChannel!);
      _filesChannel = null;
    }
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService(ref);
});