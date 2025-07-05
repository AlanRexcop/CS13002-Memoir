// C:\dev\memoir\lib\services\local_storage_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:memoir/models/person_model.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:memoir/services/markdown_analyzer_service.dart';
import 'package:memoir/models/note_model.dart';
import 'package:yaml_writer/yaml_writer.dart'; // A helper for writing YAML

class LocalStorageService {
  Future<String?> pickDirectory() async {
    return await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Please select your local storage directory',
    );
  }

  Future<List<FileSystemEntity>> listFiles(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      return dir.list().toList();
    }
    throw FileSystemException("Directory not found", path);
  }

  // --- REPLACED: This method is now obsolete ---
  // Future<void> writeNoteToFile(String path, String content) async { ... }

  // --- NEW: Smart note writer ---
  Future<void> writeNote({
    required String path,
    required Note note,
    required String markdownBody,
  }) async {
    try {
      final file = File(path);

      // Construct the YAML frontmatter map
      final frontmatter = {
        'Name': note.title,
        'CreationDate': note.creationDate.toIso8601String(),
        'LastModified': note.lastModified.toIso8601String(),
        'Tags': note.tags,
      };

      // Use a writer for clean YAML output
      final yamlWriter = YAMLWriter();
      final yamlString = yamlWriter.write(frontmatter);

      // Combine frontmatter and body
      final fullContent = '---\n$yamlString---\n\n$markdownBody';
      
      await file.writeAsString(fullContent);
    } catch (e) {
      print("Error writing note to file $path: $e");
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
            noteTitle = yamlMap['Name'] ?? noteTitle;

            if (yamlMap['CreationDate'] != null) {  
              final parsedDate = DateTime.tryParse(yamlMap['CreationDate'].toString());
              creationDate = parsedDate ?? creationDate;
            }

            if (yamlMap['LastModified'] != null) {
              final parsedDate = DateTime.tryParse(yamlMap['LastModified'].toString());
              lastModified = parsedDate ?? lastModified;
            }
            
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
    final infoFilePath = p.join(directory.path, 'info.md');
    final infoFile = File(infoFilePath);

    if (!await infoFile.exists()) {
      throw FileSystemException(
        "Invalid Person directory structure: 'info.md' not found.",
        directory.path,
      );
    }

    final Note infoNote = await readNoteFromFile(infoFile);

    List<Note> personNotes = [];
    final notesDirPath = p.join(directory.path, 'notes');
    final notesDir = Directory(notesDirPath);

    if (await notesDir.exists()) {
      final entities = await notesDir.list().toList();
      final mdFiles = entities
          .whereType<File>()
          .where((file) => p.extension(file.path) == '.md');

      if (mdFiles.isNotEmpty) {
        final noteFutures = mdFiles.map((file) => readNoteFromFile(file));
        personNotes = await Future.wait(noteFutures);
      }
    }

    return Person(
      path: directory.path,
      info: infoNote,
      notes: personNotes,
    );
  }

  Future<List<Person>> readAllPersonsFromDirectory(String parentPath) async {
    final parentDir = Directory(parentPath);
    if (!await parentDir.exists()) {
      throw FileSystemException("Parent directory not found", parentPath);
    }

    final entities = await parentDir.list().toList();
    final personDirectories = entities.whereType<Directory>();

    if (personDirectories.isEmpty) {
      return [];
    }

    final personFutures = personDirectories.map((dir) async {
      try {
        return await readPersonFromDirectory(dir);
      } catch (e) {
        print("Skipping directory '${dir.path}' due to an error: $e");
        return null;
      }
    }).toList();

    final allPersons = await Future.wait(personFutures);

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
    final saneName = personName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    if (saneName.isEmpty) {
      throw Exception("Person name is invalid or empty after sanitization.");
    }

    final personDir = Directory(p.join(parentPath, saneName));
    if (await personDir.exists()) {
      throw FileSystemException("A person with this name already exists.", personDir.path);
    }

    await Directory(p.join(personDir.path, 'notes')).create(recursive: true);

    final infoFilePath = p.join(personDir.path, 'info.md');
    // For new persons, creation and modified are the same.
    final now = DateTime.now();
    final newPersonNote = Note(
        path: infoFilePath,
        title: saneName,
        creationDate: now,
        lastModified: now,
        tags: ['new']);

    await writeNote(path: infoFilePath, note: newPersonNote, markdownBody: "# $saneName\n\nThis is the main information file for $saneName.");
  }

  Future<void> createNote({
    required String personPath,
    required String noteName,
  }) async {
    String saneName = noteName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    if (saneName.isEmpty) {
      throw Exception("Note name is invalid or empty after sanitization.");
    }
    
    final noteFile = File(p.join(personPath, 'notes', '$saneName.md'));
    if (await noteFile.exists()) {
      throw FileSystemException("A note with this name already exists.", noteFile.path);
    }
    
    final now = DateTime.now();
    final newNote = Note(
      path: noteFile.path, 
      title: saneName, 
      creationDate: now, 
      lastModified: now
    );
    
    await writeNote(path: noteFile.path, note: newNote, markdownBody: '# $saneName');
  }

  Future<void> deletePerson(String personPath) async {
    try {
      final dir = Directory(personPath);
      if (await dir.exists()) {
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