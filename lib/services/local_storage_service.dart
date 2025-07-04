import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:memoir/models/person_model.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:memoir/services/markdown_analyzer_service.dart';
import 'package:memoir/models/note_model.dart';

class LocalStorageService {
  /// Opens the native directory picker and returns the selected path.
  /// Returns null if the user cancels.
  Future<String?> pickDirectory() async {
    return await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Please select your local storage directory',
    );
  }

  /// Lists all files and folders within a given path.
  /// Throws an exception if the directory does not exist.
  Future<List<FileSystemEntity>> listFiles(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      return dir.list().toList();
    }
    throw FileSystemException("Directory not found", path);
  }

  Future<void> writeNoteToFile(String path, String content) async {
    try {
      final file = File(path);
      await file.writeAsString(content);
    } catch (e) {
      print("Error writing to file $path: $e");
      rethrow;
    }
  }

  Future<Note> readNoteFromFile(File file) async {
    final stats = await file.stat();
    final fileContent = await file.readAsString();
    String noteTitle = p.basenameWithoutExtension(file.path);
    DateTime creationDate = stats.changed;
    DateTime lastModified = stats.modified;
    String noteMainContent = fileContent;
    List<String> tags = [];

    if (fileContent.startsWith('---')) {
      final parts = fileContent.split('---');
      if (parts.length >= 3) {
        final frontmatterRaw = parts[1];
        noteMainContent = parts.sublist(2).join('---').trim();
        try {
          final yamlMap = loadYaml(frontmatterRaw);
          if (yamlMap is YamlMap) {
            // Use the 'Name' from YAML, or keep the filename as a fallback.
            noteTitle = yamlMap['Name'] ?? noteTitle;

            // Parse 'CreationDate' from YAML. Use file stat as a fallback.
            if (yamlMap['CreationDate'] != null) {  
              final parsedDate = DateTime.tryParse(yamlMap['CreationDate'].toString());
              creationDate = parsedDate ?? creationDate; // If parsing fails, keep the fallback.
            }

            // Parse 'LastModified' from YAML. Use file stat as a fallback.
            if (yamlMap['LastModified'] != null) {
              final parsedDate = DateTime.tryParse(yamlMap['LastModified'].toString());
              lastModified = parsedDate ?? lastModified; // If parsing fails, keep the fallback.
            }
            
            // Parse 'Tags' from YAML.
            if (yamlMap['Tags'] is YamlList) {
              tags = yamlMap['Tags'].map<String>((tag) => tag.toString()).toList();
            }
          }
        } catch (e) {
          print("Error parsing YAML for file ${file.path}: $e");
        }
      }
    }

    final analysis = analyzeMarkdown(noteMainContent);
    print(file.path);
    return Note(
      path: file.path, 
      title: noteTitle,
      creationDate: creationDate, 
      lastModified: lastModified,
      tags: tags,
      events: analysis.events,
      mentions: analysis.mentions,
      locations: analysis.locations);
  }

  Future<Person> readPersonFromDirectory(Directory directory) async {
    // 1. Find and validate the main info.md file for the Person.
    // This file is required. If it doesn't exist, we can't create a Person.
    final infoFilePath = p.join(directory.path, 'info.md');
    final infoFile = File(infoFilePath);

    if (!await infoFile.exists()) {
      // It's good practice to fail fast if the required structure is missing.
      throw FileSystemException(
        "Invalid Person directory structure: 'info.md' not found.", // if you hit this it might not be dev fault
        directory.path,
      );
    }

    // 2. Parse the info.md file into a Note object.
    // We reuse our existing powerful method for this.
    final Note infoNote = await readNoteFromFile(infoFile);

    // 3. Find and process the 'notes' subdirectory.
    // This is optional. If it doesn't exist, the list will be empty.
    List<Note> personNotes = [];
    final notesDirPath = p.join(directory.path, 'notes');
    final notesDir = Directory(notesDirPath);

    if (await notesDir.exists()) {
      // Get all entities in the directory, filter for .md files.
      final entities = await notesDir.list().toList();
      final mdFiles = entities
          .whereType<File>()
          .where((file) => p.extension(file.path) == '.md');

      // 4. Parse all .md files concurrently for performance.
      // Future.wait is perfect for running multiple async operations at once.
      if (mdFiles.isNotEmpty) {
        final noteFutures = mdFiles.map((file) => readNoteFromFile(file));
        personNotes = await Future.wait(noteFutures);
      }
    }

    // 5. Construct and return the final Person object.
    return Person(
      path: directory.path,
      info: infoNote,
      notes: personNotes,
    );
  }

  Future<List<Person>> readAllPersonsFromDirectory(String parentPath) async {
    final parentDir = Directory(parentPath);
    if (!await parentDir.exists()) {
      throw FileSystemException("Parent directory not found", parentPath); // if you hit this its dev fault
    }

    // 1. Get all entities and filter for subdirectories ONLY.
    final entities = await parentDir.list().toList();
    final personDirectories = entities.whereType<Directory>();

    if (personDirectories.isEmpty) {
      return []; // Return an empty list if no person folders are found.
    }

    // 2. Create a list of "futures", where each future represents the
    // task of parsing one person's directory.
    final personFutures = personDirectories.map((dir) async {
      try {
        // Call our existing function to do the detailed work for one person.
        return await readPersonFromDirectory(dir);
      } catch (e) {
        // 3. Graceful Error Handling: If a subdirectory is invalid
        // (e.g., missing info.md), we print a warning and return null.
        // This prevents one bad folder from stopping the entire load process.
        print("Skipping directory '${dir.path}' due to an error: $e");
        return null;
      }
    }).toList();

    // 4. Execute all parsing tasks concurrently.
    final allPersons = await Future.wait(personFutures);

    // 5. Filter out any nulls that resulted from errors and return
    // a clean, non-nullable list of Person objects.
    return allPersons.whereType<Person>().toList();
  }

  Future<String> readRawFileContent(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsString();
      } else {
        throw FileSystemException("File not found", path);
      }
    } catch (e) {
      print("Error reading raw file content from $path: $e");
      rethrow;
    }
  }

  Future<void> createPerson({
    required String parentPath,
    required String personName,
  }) async {
    // Sanitize the name to be a valid directory name.
    // This is a simple example; a real app might need a more robust slugify function.
    final saneName = personName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    if (saneName.isEmpty) {
      throw Exception("Person name is invalid or empty after sanitization.");
    }

    final personDir = Directory(p.join(parentPath, saneName));
    if (await personDir.exists()) {
      throw FileSystemException("A person with this name already exists.", personDir.path);
    }

    // Create the main directory and the 'notes' subdirectory
    await Directory(p.join(personDir.path, 'notes')).create(recursive: true);

    // Create the initial info.md file with minimal content
    final infoFilePath = p.join(personDir.path, 'info.md');
    final creationTime = DateTime.now().toIso8601String();
    final initialContent = """
---
Name: $saneName
CreationDate: $creationTime
LastModified: $creationTime
Tags:
  - new
---

# $saneName

This is the main information file for $saneName.
""";
    await writeNoteToFile(infoFilePath, initialContent);
  }

  Future<void> createNote({
    required String personPath,
    required String noteName,
  }) async {
    String saneName = noteName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    if (saneName.isEmpty) {
      throw Exception("Note name is invalid or empty after sanitization.");
    }

    // Ensure the filename ends with .md
    if (!saneName.toLowerCase().endsWith('.md')) {
      saneName += '.md';
    }

    final noteFile = File(p.join(personPath, 'notes', saneName));
    if (await noteFile.exists()) {
      throw FileSystemException("A note with this name already exists.", noteFile.path);
    }

    final creationTime = DateTime.now().toIso8601String();
    final initialContent = """
---
Name: ${p.basenameWithoutExtension(saneName)}
CreationDate: $creationTime
LastModified: $creationTime
Tags:
---

# ${p.basenameWithoutExtension(saneName)}
""";
    await writeNoteToFile(noteFile.path, initialContent);
  }

  Future<void> deletePerson(String personPath) async {
    try {
      final dir = Directory(personPath);
      if (await dir.exists()) {
        // The 'recursive: true' flag ensures everything inside is deleted.
        await dir.delete(recursive: true);
      }
    } catch (e) {
      print("Error deleting person directory at $personPath: $e");
      rethrow;
    }
  }

  Future<void> deleteNote(String notePath) async {
    try {
      final file = File(notePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Error deleting note file at $notePath: $e");
      rethrow;
    }
  }
}