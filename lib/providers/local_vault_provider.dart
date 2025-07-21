// lib/providers/local_vault_provider.dart
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/services/cloud_file_service.dart';
import 'package:memoir/services/local_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocalVaultNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final String _vaultRoot;
  final User _currentUser;
  final LocalStorageService _localService;
  final CloudFileService _cloudService;
  final Ref _ref;

  LocalVaultNotifier(this._vaultRoot, this._currentUser, this._localService, this._cloudService, this._ref) : super(const AsyncValue.loading()) {
    _loadLocalNotes();
  }

  Future<void> _loadLocalNotes() async {
    try {
      state = const AsyncValue.loading();
      final persons = await _localService.readAllPersonsFromDirectory(_vaultRoot);
      final List<Note> allNotes = [];
      for (var person in persons) {
        allNotes.add(person.info);
        allNotes.addAll(person.notes);
      }
      allNotes.sort((a,b) => a.title.compareTo(b.title));
      state = AsyncValue.data(allNotes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> uploadNote(Note note) async {
    try {
      final rootFolder = await _cloudService.getUserRootFolder(_currentUser.id);
      final userRootPath = rootFolder['path'] as String;

      final localRelativePath = note.path;
      final cloudPath = '$userRootPath/${localRelativePath.replaceAll(r'\', '/')}';

      final fileContent = await _localService.readRawFileContent(_vaultRoot, localRelativePath);
      final fileBytes = Uint8List.fromList(fileContent.codeUnits);

      await _cloudService.uploadFile(path: cloudPath, fileBytes: fileBytes);
      
      _ref.invalidate(allCloudFilesProvider);
      _ref.invalidate(cloudNotifierProvider);

      return true;
    } catch(e) {
      print("Upload failed for note ${note.path}: $e");
      return false;
    }
  }
}

final localVaultNotifierProvider = StateNotifierProvider<LocalVaultNotifier, AsyncValue<List<Note>>>((ref) {
  final vaultRoot = ref.watch(appProvider).storagePath;
  final user = ref.watch(appProvider).currentUser;
  final localService = ref.watch(localStorageServiceProvider);
  final cloudService = ref.watch(cloudFileServiceProvider);

  if (vaultRoot == null || user == null) {
    // Return a notifier with an error state instead of throwing an exception
    // FIX: Added the required 'createdAt' parameter.
    final dummyUser = User(
      id: '', 
      appMetadata: {}, 
      userMetadata: {}, 
      aud: '', 
      createdAt: DateTime.now().toIso8601String()
    );
    final notifier = LocalVaultNotifier('', dummyUser, localService, cloudService, ref);
    notifier.state = AsyncValue.error(
        "A local vault and authenticated user are required.", 
        StackTrace.current
    );
    return notifier;
  }

  return LocalVaultNotifier(vaultRoot, user, localService, cloudService, ref);
});