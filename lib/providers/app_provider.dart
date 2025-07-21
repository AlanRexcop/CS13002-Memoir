// lib/providers/app_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/services/local_storage_service.dart';
import 'package:memoir/services/notification_service.dart';
import 'package:memoir/services/persistence_service.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/services/sync_service.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class AppState {
  final String? storagePath;
  final List<Person> persons;
  final bool isLoading;
  final ({String text, List<String> tags}) searchQuery;
  final User? currentUser;

  const AppState({
    this.storagePath,
    this.persons = const [],
    this.isLoading = true,
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
    bool? isLoading,
    ({String text, List<String> tags})? searchQuery,
    User? currentUser,
    bool clearStoragePath = false,
    bool clearCurrentUser = false, 
  }) {
    return AppState(
      storagePath: clearStoragePath ? null : storagePath ?? this.storagePath,
      persons: persons ?? this.persons,
      isLoading: isLoading ?? this.isLoading,
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
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<AuthState>? _authSubscription;

  late final Future<void> initializationComplete;

  AppNotifier({
    required PersistenceService persistenceService,
    required LocalStorageService localStorageService,
    required SyncService syncService,
  })  : _persistenceService = persistenceService,
        _localStorageService = localStorageService,
        _syncService = syncService,
        super(const AppState()) {
    initializationComplete = _loadInitialPath();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final User? user = data.session?.user;
      // Only update state if the user's ID has actually changed.
      if (state.currentUser?.id != user?.id) {
         // FIX: Use the 'clearCurrentUser' flag when the user is null
         if (user == null) {
           state = state.copyWith(clearCurrentUser: true);
         } else {
           state = state.copyWith(currentUser: user);
         }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
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
    try {
      await _syncService.autoDelete(noteToDelete);

      await _notificationService.cancelAllNotificationsForNote(noteToDelete);
      await _localStorageService.deleteNote(state.storagePath!, noteToDelete.path);
      final newPersonsList = state.persons.map((person) {
        if (person.notes.any((n) => n.path == noteToDelete.path)) {
          final newNotesForPerson = person.notes.where((n) => n.path != noteToDelete.path).toList();
          return Person(path: person.path, info: person.info, notes: newNotesForPerson);
        }
        return person;
      }).toList();
      state = state.copyWith(persons: newPersonsList);
      return true;
    } catch (e) {
      print("Failed to delete note: $e");
      return false;
    }
  }

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
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadAllPersons(String path) async {
    state = state.copyWith(isLoading: true, storagePath: path);
    try {
      final persons = await _localStorageService.readAllPersonsFromDirectory(path);
      persons.sort((a, b) => a.info.title.compareTo(b.info.title));
      state = state.copyWith(persons: persons, isLoading: false);

      await _scheduleAllReminders(persons);

    } catch (e) {
      print("Failed to load persons: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshVault() async {
    if (state.storagePath != null) {
      await loadAllPersons(state.storagePath!);
    }
  }

  Future<void> selectAndSetStorage() async {
    final path = await _localStorageService.pickDirectory();
    if (path != null) {
      await _persistenceService.saveLocalStoragePath(path);
      await loadAllPersons(path);
    }
  }

  void setSearchQuery(({String text, List<String> tags}) query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> createNewPerson(String name) async {
    if (state.storagePath == null) return false;
    try {
      await _localStorageService.createPerson(
        parentPath: state.storagePath!,
        personName: name,
      );
      await loadAllPersons(state.storagePath!);
      return true;
    } catch (e) {
      print("Failed to create person: $e");
      return false;
    }
  }

  Future<bool> createNewNoteForPerson(Person person, String noteName) async {
     if (state.storagePath == null) return false;
    try {
      await _localStorageService.createNote(
        vaultRoot: state.storagePath!,
        personPath: person.path,
        noteName: noteName,
      );
      await loadAllPersons(state.storagePath!);
      return true;
    } catch (e) {
      print("Failed to create note: $e");
      return false;
    }
  }

  Future<bool> deletePerson(Person person) async {
    if (state.storagePath == null) return false;
    try {
      for (final note in [person.info, ...person.notes]) {
        await _notificationService.cancelAllNotificationsForNote(note);
      }
      await _localStorageService.deletePerson(state.storagePath!, person.path);
      state = state.copyWith(
        persons: state.persons.where((p) => p.path != person.path).toList(),
      );
      return true;
    } catch (e) {
      print("Failed to delete person: $e");
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