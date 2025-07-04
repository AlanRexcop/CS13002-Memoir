// C:\dev\memoir\lib\providers\app_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/services/local_storage_service.dart';
import 'package:memoir/services/persistence_service.dart';
import 'package:memoir/models/note_model.dart';


// --- State Class ---
@immutable
class AppState {
  final String? storagePath;
  final List<Person> persons;
  final bool isLoading;
  final String searchTerm;

  const AppState({
    this.storagePath,
    this.persons = const [],
    this.isLoading = true, // Start in loading state
    this.searchTerm = '',
  });

  bool get isStorageSet => storagePath != null;

  // Filtered list of persons based on the search term
  List<Person> get filteredPersons {
    if (searchTerm.isEmpty) {
      return persons;
    }
    final lowerCaseSearch = searchTerm.toLowerCase();
    return persons.where((person) {
      final nameMatch = person.info.title.toLowerCase().contains(lowerCaseSearch);
      final tagMatch = person.info.tags.any((tag) => tag.toLowerCase().contains(lowerCaseSearch));
      return nameMatch || tagMatch;
    }).toList();
  }

  AppState copyWith({
    String? storagePath,
    List<Person>? persons,
    bool? isLoading,
    String? searchTerm,
    bool clearStoragePath = false,
  }) {
    return AppState(
      storagePath: clearStoragePath ? null : storagePath ?? this.storagePath,
      persons: persons ?? this.persons,
      isLoading: isLoading ?? this.isLoading,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}

// --- Riverpod Providers ---
final persistenceServiceProvider = Provider((ref) => PersistenceService());
final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier(
    persistenceService: ref.read(persistenceServiceProvider),
    localStorageService: ref.read(localStorageServiceProvider),
  );
});

final rawNoteContentProvider = FutureProvider.family<String, String>((ref, path) async {
  final service = ref.read(localStorageServiceProvider);
  return service.readRawFileContent(path);
});
// --- StateNotifier Class ---
class AppNotifier extends StateNotifier<AppState> {
  final PersistenceService _persistenceService;
  final LocalStorageService _localStorageService;

  AppNotifier({
    required PersistenceService persistenceService,
    required LocalStorageService localStorageService,
  })  : _persistenceService = persistenceService,
        _localStorageService = localStorageService,
        super(const AppState()) {
    _loadInitialPath();
  }

  Future<void> _loadInitialPath() async {
    final path = await _persistenceService.getLocalStoragePath();
    if (path != null) {
      await loadAllPersons(path);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  // This is now public to be used by the refresh logic
  Future<void> loadAllPersons(String path) async {
    state = state.copyWith(isLoading: true, storagePath: path);
    try {
      final persons = await _localStorageService.readAllPersonsFromDirectory(path);
      // Sort persons alphabetically by title
      persons.sort((a, b) => a.info.title.compareTo(b.info.title));
      state = state.copyWith(persons: persons, isLoading: false);
    } catch (e) {
      print("Failed to load persons: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  /// --- NEW ---
  /// Provides a clean public API for the UI to trigger a full vault reload.
  Future<void> refreshVault() async {
    if (state.storagePath != null) {
      // Re-run the loading logic with the existing path.
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

  void setSearchTerm(String term) {
    state = state.copyWith(searchTerm: term);
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
    try {
      await _localStorageService.deletePerson(person.path);
      state = state.copyWith(
        persons: state.persons.where((p) => p.path != person.path).toList(),
      );
      return true;
    } catch (e) {
      print("Failed to delete person: $e");
      return false;
    }
  }

  Future<void> updateNote(String notePath) async {
    try {
      final updatedNote = await _localStorageService.readNoteFromFile(File(notePath));

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

    } catch (e) {
      print("Failed to update note in state: $e");
    }
  }

  Future<bool> deleteNote(Note noteToDelete) async {
    if (state.storagePath == null) return false;
    try {
      await _localStorageService.deleteNote(noteToDelete.path);
      
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

  Future<void> changeStorageLocation() async {
    await _persistenceService.clearLocalStoragePath();

    state = state.copyWith(
      storagePath: null,
      persons: [],
      isLoading: false,
      clearStoragePath: true,
    );
  }
}