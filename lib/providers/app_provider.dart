// C:\dev\memoir\lib\providers\app_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/services/cloud_file_service.dart';
import 'package:memoir/services/local_storage_service.dart';
import 'package:memoir/services/notification_service.dart';
import 'package:memoir/services/persistence_service.dart';
import 'package:memoir/models/note_model.dart';

import 'package:memoir/services/realtime_service.dart'; 
import 'package:memoir/services/sync_service.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class AppState {
  final String? storagePath;
  final List<Person> persons;
  final List<Note> deletedNotes;
  final List<Note> deletedPersonsInfoNotes; // Renamed for clarity
  final bool isLoading;
  final bool isSyncing;
  final ({String text, List<String> tags}) searchQuery;
  final User? currentUser;

  const AppState({
    this.storagePath,
    this.persons = const [],
    this.deletedNotes = const [],
    this.deletedPersonsInfoNotes = const [],
    this.isLoading = true,
    this.isSyncing = false,
    this.searchQuery = (text: '', tags: const []),
    this.currentUser,
  });

  bool get isStorageSet => storagePath != null;
  bool get isSignedIn => currentUser != null;

  List<Person> get filteredPersons {
    if (searchQuery.text.isEmpty && searchQuery.tags.isEmpty) {
      return persons;
    }

    return persons.where((person) {
      final lowerCaseTitle = person.info.title.toLowerCase();
      final lowerCaseTags = person.info.tags.map((t) => t.toLowerCase()).toList();

      final textMatch = searchQuery.text.isEmpty || lowerCaseTitle.contains(searchQuery.text.toLowerCase());
      final tagsMatch = searchQuery.tags.isEmpty || searchQuery.tags.every((searchTag) => lowerCaseTags.contains(searchTag.toLowerCase()));

      return textMatch && tagsMatch;
    }).toList();
  }
  
  AppState copyWith({
    String? storagePath,
    List<Person>? persons,
    List<Note>? deletedNotes,
    List<Note>? deletedPersonsInfoNotes,
    bool? isLoading,
    bool? isSyncing,
    ({String text, List<String> tags})? searchQuery,
    User? currentUser,
    bool clearStoragePath = false,
    bool clearCurrentUser = false, 
  }) {
    return AppState(
      storagePath: clearStoragePath ? null : storagePath ?? this.storagePath,
      persons: persons ?? this.persons,
      deletedNotes: deletedNotes ?? this.deletedNotes,
      deletedPersonsInfoNotes: deletedPersonsInfoNotes ?? this.deletedPersonsInfoNotes,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      searchQuery: searchQuery ?? this.searchQuery,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
    );
  }
}

final persistenceServiceProvider = Provider((ref) => PersistenceService());
final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier(
    persistenceService: ref.read(persistenceServiceProvider),
    localStorageService: ref.read(localStorageServiceProvider),
    syncService: ref.read(syncServiceProvider), 
    realtimeService: ref.read(realtimeServiceProvider),
    ref: ref, 
  );
});

final rawNoteContentProvider = FutureProvider.family<String, String>((ref, relativePath) async {
  final service = ref.read(localStorageServiceProvider);
  final storagePath = ref.watch(appProvider.select((s) => s.storagePath));

  if (storagePath == null) {
    throw Exception("Storage path is not set.");
  }
  return service.readRawFileContent(storagePath, relativePath);
});

final detailSearchProvider = StateProvider<({String text, List<String> tags})>((ref) => (text: '', tags: const []));

final vaultImagesProvider = FutureProvider<List<File>>((ref) async {
  final storagePath = ref.watch(appProvider.select((s) => s.storagePath));
  if (storagePath == null) return [];

  final service = ref.read(localStorageServiceProvider);
  return service.listImages(storagePath);
});

class AppNotifier extends StateNotifier<AppState> {
  final PersistenceService _persistenceService;
  final LocalStorageService _localStorageService;
  final SyncService _syncService;
  final RealtimeService _realtimeService;
  final NotificationService _notificationService = NotificationService();
  final Ref _ref;
  StreamSubscription<AuthState>? _authSubscription;

  late final Future<void> initializationComplete;

  AppNotifier({
    required PersistenceService persistenceService,
    required LocalStorageService localStorageService,
    required SyncService syncService,
    required RealtimeService realtimeService,
    required Ref ref,
  })  : _persistenceService = persistenceService,
        _localStorageService = localStorageService,
        _syncService = syncService,
        _realtimeService = realtimeService,
        _ref = ref,
        super(const AppState()) {
    initializationComplete = _loadInitialPath();
    _listenToAuthChanges();
    
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      state = state.copyWith(currentUser: currentUser);
      // Wait for path to load before trying to cache images
      initializationComplete.then((_) {
        if (state.storagePath != null) {
          _downloadAndCacheAvatar(currentUser.id, state.storagePath!);
          _downloadAndCacheBackground(currentUser.id, state.storagePath!);
        }
      });
      _realtimeService.subscribe();
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final User? user = data.session?.user;
      if (state.currentUser?.id != user?.id) {
         if (user == null) {
           if (state.storagePath != null) {
             await _localStorageService.deleteLocalAvatar(state.storagePath!);
             await _localStorageService.deleteLocalBackground(state.storagePath!);
           }
           state = state.copyWith(clearCurrentUser: true);
           // Refresh both providers
           _ref.read(avatarVersionProvider.notifier).update((s) => s + 1);
           _ref.read(backgroundVersionProvider.notifier).update((s) => s + 1);
           _realtimeService.unsubscribe();
         } else {
           // On login, set user and download assets
           state = state.copyWith(currentUser: user);
           if (state.storagePath != null) {
             await _downloadAndCacheAvatar(user.id, state.storagePath!);
             await _downloadAndCacheBackground(user.id, state.storagePath!);
           }
           _realtimeService.subscribe();
         }
      }
    });
  }

  Future<void> _downloadAndCacheAvatar(String userId, String vaultRoot) async {
    try {
      final cloudPath = '$userId/profile/avatar.png';
      final bytes = await Supabase.instance.client.storage.from(supabaseBucket).download(cloudPath);
      await _localStorageService.saveLocalAvatar(vaultRoot, bytes);
    } catch (e) {
      print('Failed to download avatar (this may be expected): $e');
      await _localStorageService.deleteLocalAvatar(vaultRoot);
    } finally {
      _ref.read(avatarVersionProvider.notifier).update((s) => s + 1);
    }
  }

  Future<void> _downloadAndCacheBackground(String userId, String vaultRoot) async {
    try {
      final cloudPath = '$userId/profile/background.png';
      final bytes = await Supabase.instance.client.storage.from(supabaseBucket).download(cloudPath);
      await _localStorageService.saveLocalBackground(vaultRoot, bytes);
    } catch (e) {
      print('Failed to download background (this may be expected): $e');
      await _localStorageService.deleteLocalBackground(vaultRoot);
    } finally {
      _ref.read(backgroundVersionProvider.notifier).update((s) => s + 1);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _realtimeService.unsubscribe();
    super.dispose();
  }

  Future<void> signOut() async {
    if (state.storagePath != null) {
      await _localStorageService.deleteLocalAvatar(state.storagePath!);
      await _localStorageService.deleteLocalBackground(state.storagePath!);
    }
    await Supabase.instance.client.auth.signOut();
  }

  // ... (rest of the file is unchanged)
  
  Future<void> _scheduleAllReminders(List<Person> persons) async {
    for (final person in persons) {
      for (final note in [person.info, ...person.notes]) {
        for (final event in note.events) {
          await _notificationService.scheduleEventNotification(event, note);
        }
      }
    }
  }

  Future<void> _loadInitialPath() async {
    final path = await _persistenceService.getLocalStoragePath();
    if (path != null) {
      await loadAllPersons(path);
      // Non-blocking call to start the sync process in the background
      _syncService.performInitialSync();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadAllPersons(String path) async {
    state = state.copyWith(isLoading: true, storagePath: path);
    try {
      final peopleDir = Directory(p.join(path, 'people'));
      if (!await peopleDir.exists()) {
        state = state.copyWith(persons: [], deletedNotes: [], deletedPersonsInfoNotes: [], isLoading: false);
        return;
      }

      final List<Person> activePersons = [];
      final List<Note> tempDeletedNotes = [];
      final List<Note> tempDeletedPersonInfos = [];
      const deletionPeriod = Duration(days: 10);

      final entities = await peopleDir.list().toList();
      final personDirectories = entities.whereType<Directory>();

      for (final dir in personDirectories) {
        final infoFile = File(p.join(dir.path, 'info.md'));
        if (!await infoFile.exists()) continue;

        final infoNote = await _localStorageService.readNoteFromFile(infoFile, path);

        if (infoNote.deletedDate != null) {
          // This person is soft-deleted
          if (DateTime.now().difference(infoNote.deletedDate!) > deletionPeriod) {
            await _localStorageService.deletePersonPermanently(path, p.relative(dir.path, from: path));
          } else {
            tempDeletedPersonInfos.add(infoNote);
          }
        } else {
          // This is an active person, process them fully
          final fullPerson = await _localStorageService.readPersonFromDirectory(dir, path);
          final List<Note> activeNotes = [];
          for (final note in fullPerson.notes) {
            if (note.deletedDate != null) {
              if (DateTime.now().difference(note.deletedDate!) > deletionPeriod) {
                await _localStorageService.deleteNote(path, note.path);
              } else {
                tempDeletedNotes.add(note);
              }
            } else {
              activeNotes.add(note);
            }
          }
          activePersons.add(Person(path: fullPerson.path, info: fullPerson.info, notes: activeNotes));
        }
      }

      activePersons.sort((a, b) => a.info.title.compareTo(b.info.title));
      tempDeletedNotes.sort((a, b) => b.deletedDate!.compareTo(a.deletedDate!));
      tempDeletedPersonInfos.sort((a, b) => b.deletedDate!.compareTo(a.deletedDate!));
      
      state = state.copyWith(
        persons: activePersons,
        deletedNotes: tempDeletedNotes,
        deletedPersonsInfoNotes: tempDeletedPersonInfos,
        isLoading: false,
      );
      
      await _scheduleAllReminders(activePersons);
    } catch (e) {
      print("Failed to load persons: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void setSyncLoading(bool isLoading) {
    state = state.copyWith(isSyncing: isLoading);
  }

  Future<void> refreshVault() async {
    if (state.storagePath != null) {
      await loadAllPersons(state.storagePath!);
      _syncService.performInitialSync();
    }
  }

  Future<void> selectAndSetStorage() async {
    final path = await _localStorageService.pickDirectory();
    if (path != null) {
      await _persistenceService.saveLocalStoragePath(path);
      await loadAllPersons(path);
      _syncService.performInitialSync();
    }
  }

  void setSearchQuery(({String text, List<String> tags}) query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> createNewPerson(String name) async {
    if (state.storagePath == null) return false;
    try {
      final newPerson = await _localStorageService.createPerson(
        parentPath: state.storagePath!,
        personName: name,
      );
      
      final updatedPersons = List<Person>.from(state.persons)..add(newPerson);
      updatedPersons.sort((a, b) => a.info.title.compareTo(b.info.title));
      
      state = state.copyWith(persons: updatedPersons);
      return true;
    } catch (e) {
      print("Failed to create person: $e");
      return false;
    }
  }

  Future<bool> createNewNoteForPerson(Person person, String noteName) async {
     if (state.storagePath == null) return false;
    try {
      final newNote = await _localStorageService.createNote(
        vaultRoot: state.storagePath!,
        personPath: person.path,
        noteName: noteName,
      );

      final updatedPersons = state.persons.map((p) {
        if (p.path == person.path) {
          final updatedNotes = List<Note>.from(p.notes)..add(newNote);
          return Person(path: p.path, info: p.info, notes: updatedNotes);
        }
        return p;
      }).toList();
      
      state = state.copyWith(persons: updatedPersons);
      return true;
    } catch (e) {
      print("Failed to create note: $e");
      return false;
    }
  }

  Future<bool> deletePerson(Person person) async {
    if (state.storagePath == null) return false;

    // --- 1. IMMEDIATE STATE UPDATE ---
    final now = DateTime.now();
    final updatedInfoNote = person.info.copyWith(deletedDate: now);

    final newPersonsList = state.persons.where((p) => p.path != person.path).toList();
    final newDeletedPersonInfos = List<Note>.from(state.deletedPersonsInfoNotes)..add(updatedInfoNote);
    newDeletedPersonInfos.sort((a, b) => b.deletedDate!.compareTo(a.deletedDate!));

    // Update state right away.
    state = state.copyWith(
      persons: newPersonsList,
      deletedPersonsInfoNotes: newDeletedPersonInfos,
    );

    // --- 2. BACKGROUND I/O ---
    try {
      final backgroundTasks = <Future>[];
      backgroundTasks.add(_localStorageService.softDeletePerson(state.storagePath!, person.path));
      for (final note in [person.info, ...person.notes]) {
        backgroundTasks.add(_syncService.autoTrash(note));
        backgroundTasks.add(_notificationService.cancelAllNotificationsForNote(note));
      }
      await Future.wait(backgroundTasks);
      return true;
    } catch (e) {
      print("Failed to complete background tasks for person deletion: $e");
      return false;
    }
  }

  Future<bool> restorePerson(Note personInfoNote) async {
    if (state.storagePath == null) return false;
    try {
      final personPath = p.dirname(personInfoNote.path);
      await _localStorageService.restorePerson(state.storagePath!, personPath);
  
      final personDir = Directory(p.join(state.storagePath!, personPath));
      final unfilteredRestoredPerson = await _localStorageService.readPersonFromDirectory(personDir, state.storagePath!);
      
      await _syncService.autoRestore(unfilteredRestoredPerson.info);
      for (final note in unfilteredRestoredPerson.notes) {
        if (note.deletedDate == null) {
          await _syncService.autoRestore(note);
        }
      }

      // Filter out notes that are still meant to be in the trash for the final state update.
      final activeNotesForRestoredPerson = unfilteredRestoredPerson.notes
          .where((note) => note.deletedDate == null)
          .toList();
  
      final cleanRestoredPerson = Person(
        path: unfilteredRestoredPerson.path,
        info: unfilteredRestoredPerson.info,
        notes: activeNotesForRestoredPerson,
      );
      
      final newPersonsList = List<Person>.from(state.persons)..add(cleanRestoredPerson);
      newPersonsList.sort((a,b) => a.info.title.compareTo(b.info.title));
      
      final newDeletedPersonInfos = state.deletedPersonsInfoNotes.where((n) => n.path != personInfoNote.path).toList();
      
      state = state.copyWith(
        persons: newPersonsList,
        deletedPersonsInfoNotes: newDeletedPersonInfos,
      );
      
      await _scheduleAllReminders([cleanRestoredPerson]);
      return true;
    } catch(e) {
      print("Failed to restore person: $e");
      return false;
    }
  }

  Future<bool> deletePersonPermanently(Note personInfoNote) async {
    if (state.storagePath == null) return false;
    try {
      final personPath = p.dirname(personInfoNote.path);
      
      // To ensure cloud files are deleted, we must read the directory before deleting it locally.
      final personDir = Directory(p.join(state.storagePath!, personPath));
      if (await personDir.exists()) {
        final personToDelete = await _localStorageService.readPersonFromDirectory(personDir, state.storagePath!);
        for (final note in [personToDelete.info, ...personToDelete.notes]) {
          await _syncService.autoDeletePermanently(note);
        }
      } else {
        // Fallback if directory is already gone, at least try to delete the info note.
        await _syncService.autoDeletePermanently(personInfoNote);
      }

      await _localStorageService.deletePersonPermanently(state.storagePath!, personPath);
      
      final newDeletedPersonInfos = state.deletedPersonsInfoNotes.where((n) => n.path != personInfoNote.path).toList();
      state = state.copyWith(deletedPersonsInfoNotes: newDeletedPersonInfos);
      return true;
    } catch (e) {
      print("Failed to permanently delete person: $e");
      return false;
    }
  }

  // Surgically updates a single note in the state after a download.
  // This is the key to breaking the sync loop.
  Future<void> updateSingleNoteInState(String notePath) async {
    if (state.storagePath == null) return;
    try {
      // 1. Read the definitive, updated data for this one file from disk.
      final absolutePath = p.join(state.storagePath!, notePath);
      final updatedNote = await _localStorageService.readNoteFromFile(File(absolutePath), state.storagePath!);

      // 2. Find and replace the old note object within the existing state.
      final newPersonsList = state.persons.map((person) {
        // Check if the info note needs updating
        if (person.info.path == notePath) {
          return Person(path: person.path, info: updatedNote, notes: person.notes);
        }
        
        // Check if a note in the notes list needs updating
        final noteIndex = person.notes.indexWhere((n) => n.path == notePath);
        if (noteIndex != -1) {
          final newNotesForPerson = List<Note>.from(person.notes);
          newNotesForPerson[noteIndex] = updatedNote;
          return Person(path: person.path, info: person.info, notes: newNotesForPerson);
        }
        
        // If no match, return the person unchanged
        return person;
      }).toList();

      // 3. Update the state with the new list of persons.
      state = state.copyWith(persons: newPersonsList);
      print('State successfully updated for note: $notePath');

    } catch (e) {
      print("Failed to surgically update note in state: $e");
    }
  }

  Future<void> updateNote(String notePath) async {
    if (state.storagePath == null) return;
    try {
      final absolutePath = p.join(state.storagePath!, notePath);
      
      Note? oldNote;
      for (final person in state.persons) {
        final found = [person.info, ...person.notes].where((note) => note.path == notePath);
        if (found.isNotEmpty) {
          oldNote = found.first;
          break;
        }
      }
      if (oldNote != null) {
        await _notificationService.cancelAllNotificationsForNote(oldNote);
      }

      final updatedNote = await _localStorageService.readNoteFromFile(File(absolutePath), state.storagePath!);
      
      final newPersonsList = state.persons.map((person) {
        if (person.info.path == notePath) {
          return Person(path: person.path, info: updatedNote, notes: person.notes);
        }
        final noteIndex = person.notes.indexWhere((n) => n.path == notePath);
        if (noteIndex != -1) {
          final newNotesForPerson = List<Note>.from(person.notes);
          newNotesForPerson[noteIndex] = updatedNote;
          return Person(path: person.path, info: person.info, notes: newNotesForPerson);
        }
        return person;
      }).toList();

      state = state.copyWith(persons: newPersonsList);
      
      for (final event in updatedNote.events) {
        await _notificationService.scheduleEventNotification(event, updatedNote);
      }

      if (state.storagePath != null) {
        _syncService.autoUpload(updatedNote, state.storagePath!);
      }

    } catch (e) {
      print("Failed to update note in state: $e");
    }
  }

  Future<bool> deleteNote(Note noteToDelete) async {
    if (state.storagePath == null) return false;

    // --- 1. IMMEDIATE STATE UPDATE ---
    // Calculate the new state synchronously based on the incoming data.
    final now = DateTime.now();
    // Create an in-memory copy with the deleted date.
    final updatedDeletedNote = noteToDelete.copyWith(deletedDate: now);

    final newPersonsList = state.persons.map((person) {
      final newNotesForPerson = person.notes.where((n) => n.path != noteToDelete.path).toList();
      return Person(path: person.path, info: person.info, notes: newNotesForPerson);
    }).toList();

    final newDeletedNotes = List<Note>.from(state.deletedNotes)..add(updatedDeletedNote);
    newDeletedNotes.sort((a, b) => b.deletedDate!.compareTo(a.deletedDate!));

    // Update state right away. This is the key fix.
    state = state.copyWith(persons: newPersonsList, deletedNotes: newDeletedNotes);

    // --- 2. BACKGROUND I/O ---
    // Now, perform all async operations. The UI is already updated and won't block.
    try {
      // We can run these in parallel.
      await Future.wait([
        _localStorageService.setNoteDeleted(state.storagePath!, noteToDelete.path, now),
        _syncService.autoTrash(noteToDelete),
        _notificationService.cancelAllNotificationsForNote(noteToDelete),
      ]);
      return true;
    } catch (e) {
      print("Failed to complete background tasks for note deletion: $e");
      // The item was removed from the list, but background tasks failed.
      return false;
    }
  }

  Future<bool> restoreNote(Note noteToRestore) async {
    if (state.storagePath == null) return false;
    try {
      // Safety check to prevent restoring a note if its parent person is also deleted.
      final personPath = p.dirname(p.dirname(noteToRestore.path));
      final isPersonDeleted = state.deletedPersonsInfoNotes.any((info) => p.dirname(info.path) == personPath);
      if (isPersonDeleted) {
        print("Cannot restore note because its parent person is also in the trash. Please restore the person first.");
        return false;
      }
      
      await _syncService.autoRestore(noteToRestore);
      await _localStorageService.setNoteDeleted(state.storagePath!, noteToRestore.path, null);

      final file = File(p.join(state.storagePath!, noteToRestore.path));
      final restoredNote = await _localStorageService.readNoteFromFile(file, state.storagePath!);
      
      final newDeletedNotes = state.deletedNotes.where((n) => n.path != noteToRestore.path).toList();
      
      final newPersonsList = state.persons.map((person) {
        if (person.path == personPath) {
          final newNotes = List<Note>.from(person.notes)..add(restoredNote);
          return Person(path: person.path, info: person.info, notes: newNotes);
        }
        return person;
      }).toList();

      state = state.copyWith(persons: newPersonsList, deletedNotes: newDeletedNotes);
      
      for (final event in restoredNote.events) {
        await _notificationService.scheduleEventNotification(event, restoredNote);
      }
      return true;
    } catch (e) {
      print("Failed to restore note: $e");
      return false;
    }
  }

  Future<bool> deleteNotePermanently(Note noteToDelete) async {
    if (state.storagePath == null) return false;
    try {
      await _syncService.autoDeletePermanently(noteToDelete);
      await _notificationService.cancelAllNotificationsForNote(noteToDelete);
      await _localStorageService.deleteNote(state.storagePath!, noteToDelete.path);
      
      final newDeletedNotes = state.deletedNotes.where((n) => n.path != noteToDelete.path).toList();
      state = state.copyWith(deletedNotes: newDeletedNotes);
      return true;
    } catch (e) {
      print("Failed to permanently delete note: $e");
      return false;
    }
  }

  Future<void> changeStorageLocation() async {
    await _persistenceService.clearLocalStoragePath();
    state = state.copyWith(
      persons: [],
      isLoading: false,
      clearStoragePath: true,
    );
  }

  Future<String> saveImageToVault(File imageFile) async {
    if (state.storagePath == null) {
      throw Exception("Storage path is not set");
    }
    final relativePath = await _localStorageService.saveImage(state.storagePath!, imageFile);
    return relativePath;
  }

  Future<bool> deleteImage(String relativePath) async {
    if (state.storagePath == null) return false;
    try {
        await _localStorageService.deleteImage(state.storagePath!, relativePath);
        return true;
    } catch (e) {
        print("Failed to delete image: $e");
        return false;
    }
  }
}