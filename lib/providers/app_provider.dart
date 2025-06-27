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
      await _loadAllPersons(path);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadAllPersons(String path) async {
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

  Future<void> selectAndSetStorage() async {
    final path = await _localStorageService.pickDirectory();
    if (path != null) {
      await _persistenceService.saveLocalStoragePath(path);
      await _loadAllPersons(path);
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
      await _loadAllPersons(state.storagePath!);
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
      await _loadAllPersons(state.storagePath!);
      return true;
    } catch (e) {
      print("Failed to create note: $e");
      return false;
    }
  }

  Future<bool> deletePerson(Person person) async {
    try {
      await _localStorageService.deletePerson(person.path);
      // To update the UI, we simply remove the person from the current state list.
      // This is much faster than reloading everything from disk.
      state = state.copyWith(
        persons: state.persons.where((p) => p.path != person.path).toList(),
      );
      return true;
    } catch (e) {
      print("Failed to delete person: $e");
      return false;
    }
  }

  Future<bool> deleteNote(Note note) async {
    if (state.storagePath == null) return false;
    try {
      await _localStorageService.deleteNote(note.path);
      // After a note is deleted, the parent Person object has changed.
      // The simplest way to reflect this is to reload everything.
      await _loadAllPersons(state.storagePath!);
      return true;
    } catch (e) {
      print("Failed to delete note: $e");
      return false;
    }
  }
}
