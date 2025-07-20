// lib/viewmodels/local_vault_viewmodel.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/services/cloud_file_service.dart';
import 'package:memoir/services/local_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class LocalVaultViewModel extends StateNotifier<AsyncValue<List<Note>>> {
  final String _vaultRoot;
  final User _currentUser;
  final LocalStorageService _localService;
  final CloudFileService _cloudService;

  LocalVaultViewModel(this._vaultRoot, this._currentUser, this._localService, this._cloudService) : super(const AsyncValue.loading()) {
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
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
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
      return true;
    } catch(e) {
      print("Upload failed for note ${note.path}: $e");
      return false;
    }
  }
}

final localVaultViewModelProvider = StateNotifierProvider<LocalVaultViewModel, AsyncValue<List<Note>>>((ref) {
  final vaultRoot = ref.watch(appProvider).storagePath;
  final user = Supabase.instance.client.auth.currentUser;
  final localService = ref.watch(localStorageServiceProvider);
  final cloudService = ref.watch(cloudFileServiceProvider);

  if (vaultRoot == null || user == null) {
    throw Exception("LocalVaultViewModel requires a vault path and an authenticated user.");
  }

  return LocalVaultViewModel(vaultRoot, user, localService, cloudService);
});