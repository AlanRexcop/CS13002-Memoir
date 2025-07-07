// C:\dev\memoir\lib\providers\app_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/models/person_model.dart';
import 'package:memoir/services/local_storage_service.dart';
import 'package:memoir/services/persistence_service.dart';
import 'package:memoir/models/note_model.dart';
import 'package:path/path.dart' as p;

// --- REMOVED: This function is no longer needed. ---
// The UI will now construct the search record directly.

// --- State Class ---
@immutable
class AppState {
  final String? storagePath;
  final List<Person> persons;
  final bool isLoading;
  final ({String text, List<String> tags}) searchQuery;

  const AppState({
    this.storagePath,
    this.persons = const [],
    this.isLoading = true,
    this.searchQuery = (text: '', tags: const []),
  });

  bool get isStorageSet => storagePath != null;

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
    bool clearStoragePath = false,
  }) {
    return AppState(
      storagePath: clearStoragePath ? null : storagePath ?? this.storagePath,
      persons: persons ?? this.persons,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// --- Riverpod Providers ---
final persistenceServiceProvider = Provider((ref) => PersistenceService());
final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier(
    // --- FIX: Removed ref from constructor ---
    persistenceService: ref.read(persistenceServiceProvider),
    localStorageService: ref.read(localStorageServiceProvider),
  );
});

final rawNoteContentProvider = FutureProvider.family<String, String>((ref, relativePath) async {
  final service = ref.read(localStorageServiceProvider);
  final storagePath = ref.watch(appProvider.select((s) => s.storagePath));

  if (storagePath == null) {
    throw Exception("Storage path is not set.");
  }
  // Pass both vault root and relative path to the service
  return service.readRawFileContent(storagePath, relativePath);
});

final detailSearchProvider = StateProvider<({String text, List<String> tags})>((ref) => (text: '', tags: const []));

// --- NEW: Provider for listing images in the vault ---
final vaultImagesProvider = FutureProvider<List<File>>((ref) async {
  final storagePath = ref.watch(appProvider.select((s) => s.storagePath));
  if (storagePath == null) return [];
  
  final service = ref.read(localStorageServiceProvider);
  return service.listImages(storagePath);
});


// --- StateNotifier Class ---
class AppNotifier extends StateNotifier<AppState> {
  final PersistenceService _persistenceService;
  final LocalStorageService _localStorageService;

  late final Future<void> initializationComplete;

  AppNotifier({
    required PersistenceService persistenceService,
    required LocalStorageService localStorageService,
  })  : _persistenceService = persistenceService,
        _localStorageService = localStorageService,
        super(const AppState()) {
    initializationComplete = _loadInitialPath();
  }

  // ... (rest of the class is unchanged)

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
      // --- MODIFIED: Service now handles subdirectory logic ---
      final persons = await _localStorageService.readAllPersonsFromDirectory(path);
      persons.sort((a, b) => a.info.title.compareTo(b.info.title));
      state = state.copyWith(persons: persons, isLoading: false);
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
      // --- MODIFIED: Service now handles subdirectory logic ---
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
      // --- MODIFIED: Pass vault root to service method ---
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
      // --- MODIFIED: Pass vault root to service method ---
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

  Future<void> updateNote(String notePath) async {
    if (state.storagePath == null) return;
    try {
      // --- MODIFIED: Construct absolute path and pass vault root ---
      final absolutePath = p.join(state.storagePath!, notePath);
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
    } catch (e) {
      print("Failed to update note in state: $e");
    }
  }

  Future<bool> deleteNote(Note noteToDelete) async {
    if (state.storagePath == null) return false;
    try {
      // --- MODIFIED: Pass vault root to service method ---
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

  Future<void> changeStorageLocation() async {
    await _persistenceService.clearLocalStoragePath();
    state = state.copyWith(
      storagePath: null,
      persons: [],
      isLoading: false,
      clearStoragePath: true,
    );
  }

  // --- NEW: Method to save an image and refresh the provider ---
  Future<String> saveImageToVault(File imageFile) async {
    if (state.storagePath == null) {
      throw Exception("Storage path is not set");
    }
    final relativePath = await _localStorageService.saveImage(state.storagePath!, imageFile);
    // --- FIX: Removed the line causing the circular dependency ---
    // _ref.refresh(vaultImagesProvider); 
    return relativePath;
  }
}