// lib/viewmodels/cloud_viewmodel.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/cloud_file.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/services/cloud_file_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

@immutable
class CloudState {
  final List<CloudFile> items;
  final List<Map<String, dynamic>> breadcrumbs;
  final bool isLoading;
  final String? errorMessage;
  final String? currentFolderId;
  final String? userRootPath; // Added to store the root path (e.g., 'user-id-string')

  const CloudState({
    this.items = const [],
    this.breadcrumbs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentFolderId,
    this.userRootPath,
  });

  CloudState copyWith({
    List<CloudFile>? items,
    List<Map<String, dynamic>>? breadcrumbs,
    bool? isLoading,
    String? errorMessage,
    String? currentFolderId,
    String? userRootPath,
  }) {
    return CloudState(
      items: items ?? this.items,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentFolderId: currentFolderId ?? this.currentFolderId,
      userRootPath: userRootPath ?? this.userRootPath,
    );
  }
}

class CloudViewModel extends StateNotifier<CloudState> {
  final CloudFileService _cloudService;
  final User _currentUser;

  CloudViewModel(this._cloudService, this._currentUser) : super(const CloudState()) {
    initialize();
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final rootFolder = await _cloudService.getUserRootFolder(_currentUser.id);
      final rootFolderId = rootFolder['id'] as String;
      // Store the root path to correctly construct relative paths later
      final rootPath = rootFolder['path'] as String; 
      state = state.copyWith(userRootPath: rootPath);
      await _fetchFolderContents(rootFolderId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load root folder. It may not exist yet.');
    }
  }

  Future<void> _fetchFolderContents(String? folderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, currentFolderId: folderId);
    try {
      if (folderId == null) {
        await initialize();
        return;
      }
      
      final contentsFuture = _cloudService.getFolderContents(folderId);
      final pathFuture = _cloudService.getFolderPath(folderId);

      final results = await Future.wait([contentsFuture, pathFuture]);
      
      final items = (results[0] as List<Map<String, dynamic>>)
          .map((data) => CloudFile.fromSupabase(data))
          .toList();
      items.sort((a, b) {
        if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
        return a.name.compareTo(b.name);
      });

      final breadcrumbs = (results[1] as List<Map<String, dynamic>>);
      breadcrumbs[0]['name'] = 'root';
      state = state.copyWith(
        items: items,
        breadcrumbs: breadcrumbs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error fetching folder contents: ${e.toString()}');
    }
  }

  Future<void> navigateToFolder(String? folderId) async {
    await _fetchFolderContents(folderId);
  }

  Future<void> refreshCurrentFolder() async {
    if (state.currentFolderId != null) {
      await _fetchFolderContents(state.currentFolderId);
    } else {
      await initialize();
    }
  }

  Future<bool> downloadFile(CloudFile file, String vaultRoot) async {
    if (file.cloudPath == null || state.userRootPath == null) return false;
    try {
      final fullCloudPath = file.cloudPath!;
      final relativePath = fullCloudPath.replaceFirst(state.userRootPath!, '');

      final localPath = p.join(vaultRoot, relativePath);
      final fileBytes = await _cloudService.downloadFile(path: fullCloudPath);
      
      final localFile = File(localPath);
      final parentDir = Directory(p.dirname(localPath));

      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await localFile.writeAsBytes(fileBytes);
      return true;
    } catch (e) {
      print('Download failed: $e');
      return false;
    }
  }
}

final cloudViewModelProvider = StateNotifierProvider<CloudViewModel, CloudState>((ref) {
  final cloudService = ref.watch(cloudFileServiceProvider);
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) {
    throw Exception("CloudViewModel requires an authenticated user.");
  }
  return CloudViewModel(cloudService, user);
});

// A simple provider that gives a flat list of all cloud files for sync checking
final allCloudFilesProvider = FutureProvider<List<CloudFile>>((ref) async {
  final cloudService = ref.read(cloudFileServiceProvider);
  final fileMaps = await cloudService.getAllFiles();
  return fileMaps.map((data) => CloudFile.fromSupabase(data)).toList();
});