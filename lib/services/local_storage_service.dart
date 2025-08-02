// C:\dev\memoir\lib\services\local_storage_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:memoir/models/person_model.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:memoir/services/markdown_analyzer_service.dart';
import 'package:memoir/models/note_model.dart';
import 'package:yaml_writer/yaml_writer.dart';

class LocalStorageService {
  String _generateFriendlyId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Generates a random number up to 16,777,215 for added uniqueness
    final random = Random().nextInt(0xffffff); 
    return '${now.toRadixString(36)}${random.toRadixString(36)}';
  }

  String _generateUniqueFilename(String originalPath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(originalPath);
    return '$timestamp$extension';
  }

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

  // This method now expects an ABSOLUTE path for writing.
  Future<void> writeNote({
    required String path,
    required Note note, // Note object should contain relative paths
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

      if (note.images.isNotEmpty) {
        frontmatter['Avatar'] = note.images.first;
      }

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

  Future<void> _updateFrontmatter(String absolutePath, Map<String, dynamic> updates, List<String> removals) async {
      final file = File(absolutePath);
      if (!await file.exists()) {
        throw FileSystemException("File not found for updating frontmatter", absolutePath);
      }
      
      final content = await file.readAsString();
      String frontmatterRaw = '';
      String body = content;

      if (content.startsWith('---')) {
          final parts = content.split('---');
          if (parts.length >= 3) {
              frontmatterRaw = parts[1];
              body = parts.sublist(2).join('---').trim();
          }
      }

      dynamic yamlMap;
      try {
        yamlMap = loadYaml(frontmatterRaw);
      } catch (e) {
        yamlMap = {};
      }
      
      final newFrontmatter = (yamlMap is Map) ? Map<String, dynamic>.from(yamlMap) : <String, dynamic>{};
      
      newFrontmatter.addAll(updates);
      for (final key in removals) {
        newFrontmatter.remove(key);
      }

      final yamlWriter = YAMLWriter();
      final newYamlString = yamlWriter.write(newFrontmatter);
      
      final fullContent = '---\n$newYamlString---\n\n$body';
      await file.writeAsString(fullContent);
  }

  Future<void> setNoteDeleted(String vaultRoot, String notePath, DateTime? deletedTime) async {
    final absolutePath = p.join(vaultRoot, notePath);
    if (deletedTime != null) {
      await _updateFrontmatter(absolutePath, {'deleted_date': deletedTime.toIso8601String()}, []);
    } else {
      await _updateFrontmatter(absolutePath, {}, ['deleted_date']);
    }
  }

  Future<void> softDeletePerson(String vaultRoot, String personPath) async {
    final infoFilePath = p.join(vaultRoot, personPath, 'info.md');
    await _updateFrontmatter(infoFilePath, {'deleted_date': DateTime.now().toIso8601String()}, []);
  }

  Future<void> restorePerson(String vaultRoot, String personPath) async {
      final infoFilePath = p.join(vaultRoot, personPath, 'info.md');
      await _updateFrontmatter(infoFilePath, {}, ['deleted_date']);
  }


  // Receives an absolute file and the vault root to produce a Note with relative paths.
  Future<Note> readNoteFromFile(File file, String vaultRoot) async {
    final stats = await file.stat();
    final fileContent = await file.readAsString();
    // The fallback title is now the file's ID, but will be overwritten by YAML `Name`
    String noteTitle = p.basenameWithoutExtension(file.path);
    DateTime creationDate = stats.changed;
    DateTime lastModified = stats.modified;
    String noteMainContent = fileContent;
    List<String> tags = [];
    DateTime? deletedDate;
    String? avatarPath;

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

            if (yamlMap['deleted_date'] != null) {
              deletedDate = DateTime.tryParse(yamlMap['deleted_date'].toString());
            }

            if (yamlMap['Avatar'] != null) {
              avatarPath = yamlMap['Avatar'].toString();
            }
          }
        } catch (e) {
          print("Error parsing YAML for file ${file.path}: $e");
        }
      }
    }

    final analysis = analyzeMarkdown(noteMainContent);
    final List<String> orderedImages = [];
    if (avatarPath != null) {
      orderedImages.add(avatarPath);
      // Add other images, ensuring no duplicates
      for (final img in analysis.images) {
        if (img != avatarPath) {
          orderedImages.add(img);
        }
      }
    } else {
      orderedImages.addAll(analysis.images);
    }
    
    return Note(
      path: p.relative(file.path, from: vaultRoot), 
      title: noteTitle,
      creationDate: creationDate, 
      lastModified: lastModified,
      tags: tags,
      images: orderedImages,
      events: analysis.events,
      mentions: analysis.mentions,
      locations: analysis.locations,
      deletedDate: deletedDate,
    );
  }

  // Receives an absolute directory path and the vault root.
  Future<Person> readPersonFromDirectory(Directory directory, String vaultRoot) async {
    final infoFilePath = p.join(directory.path, 'info.md');
    final infoFile = File(infoFilePath);

    if (!await infoFile.exists()) {
      throw FileSystemException(
        "Invalid Person directory structure: 'info.md' not found.",
        directory.path,
      );
    }
    
    final Note infoNote = await readNoteFromFile(infoFile, vaultRoot);

    List<Note> personNotes = [];
    final notesDirPath = p.join(directory.path, 'notes');
    final notesDir = Directory(notesDirPath);

    if (await notesDir.exists()) {
      final entities = await notesDir.list().toList();
      final mdFiles = entities
          .whereType<File>()
          .where((file) => p.extension(file.path) == '.md');

      if (mdFiles.isNotEmpty) {
        final noteFutures = mdFiles.map((file) => readNoteFromFile(file, vaultRoot));
        personNotes = await Future.wait(noteFutures);
      }
    }

    return Person(
      path: p.relative(directory.path, from: vaultRoot),
      info: infoNote,
      notes: personNotes,
    );
  }

  // The parentPath is the vault root.
  Future<List<Person>> readAllPersonsFromDirectory(String parentPath) async {
    final peopleDir = Directory(p.join(parentPath, 'people'));
    if (!await peopleDir.exists()) {
      return []; // No people directory, so no persons.
    }

    final entities = await peopleDir.list().toList();
    final personDirectories = entities.whereType<Directory>();

    if (personDirectories.isEmpty) {
      return [];
    }
    
    final personFutures = personDirectories.map((dir) async {
      try {
        return await readPersonFromDirectory(dir, parentPath);
      } catch (e) {
        print("Skipping directory '${dir.path}' due to an error: $e");
        return null;
      }
    }).toList();

    final allPersons = await Future.wait(personFutures);

    return allPersons.whereType<Person>().toList();
  }

  // Receives vaultRoot and a relativePath
  Future<String> readRawFileContent(String vaultRoot, String relativePath) async {
    try {
      final absolutePath = p.join(vaultRoot, relativePath);
      final file = File(absolutePath);
      if (await file.exists()) {
        return await file.readAsString();
      } else {
        throw FileSystemException("File not found", absolutePath);
      }
    } catch (e) {
      print("Error reading raw file content from $relativePath: $e");
      rethrow;
    }
  }

  Future<Uint8List> readRawFileByte(String vaultRoot, String relativePath) async {
    try {
      final absolutePath = p.join(vaultRoot, relativePath);
      final file = File(absolutePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        throw FileSystemException("File not found", absolutePath);
      }
    } catch (e) {
      print("Error reading raw file content from $relativePath: $e");
      rethrow;
    }
  }

  // parentPath is the vault root
  Future<Person> createPerson({
    required String parentPath,
    required String personName,
  }) async {
    String id;
    Directory personDir;
    do {
      id = _generateFriendlyId();
      personDir = Directory(p.join(parentPath, 'people', id));
    } while (await personDir.exists()); // Loop until a unique ID is found
    
    // Create the main person directory and its 'notes' subdirectory
    await Directory(p.join(personDir.path, 'notes')).create(recursive: true);

    final infoFileAbsolutePath = p.join(personDir.path, 'info.md');
    final now = DateTime.now();
    final trimmedName = personName.trim();

    // The note's title is the human-readable name, but its path is based on the generated ID.
    final newPersonNote = Note(
        path: p.relative(infoFileAbsolutePath, from: parentPath),
        title: trimmedName, 
        creationDate: now,
        lastModified: now,
        tags: const []);
        
    // Format it to YYYY-MM-DDTHH:MM:SS
    final formattedDate = now.toIso8601String().split('.').first;

    // Create the default markdown body using the new template
    final markdownBody = """
❤️ First met on:

 {event}[first met $trimmedName]($formattedDate) 

🎂Birthday:

...

📞Phone:

...

🗺️Address:

...
""";

    await writeNote(
        path: infoFileAbsolutePath, 
        note: newPersonNote, 
        markdownBody: markdownBody);
        
    return await readPersonFromDirectory(personDir, parentPath);
  }

  Future<Note> createNote({
    required String vaultRoot, 
    required String personPath, // This will be relative
    required String noteName,
  }) async {
    final personAbsolutePath = p.join(vaultRoot, personPath);

    String id;
    File noteFileAbsolutePath;
    do {
      id = _generateFriendlyId();
      final noteFileName = '$id.md';
      noteFileAbsolutePath = File(p.join(personAbsolutePath, 'notes', noteFileName));
    } while (await noteFileAbsolutePath.exists()); // Loop until a unique ID is found
    
    final now = DateTime.now();
    final newNote = Note(
      path: p.relative(noteFileAbsolutePath.path, from: vaultRoot), 
      title: noteName.trim(), 
      creationDate: now, 
      lastModified: now
    );
    
    await writeNote(path: noteFileAbsolutePath.path, note: newNote, markdownBody: '# ${noteName.trim()}');
    
    return await readNoteFromFile(noteFileAbsolutePath, vaultRoot);
  }

  // Receives a relative path
  Future<void> deletePersonPermanently(String vaultRoot, String personPath) async {
    try {
      final absolutePath = p.join(vaultRoot, personPath);
      final dir = Directory(absolutePath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      print("Error deleting person directory at $personPath: $e");
      rethrow;
    }
  }

  // Receives a relative path
  Future<void> deleteNote(String vaultRoot, String notePath) async {
    try {
      final absolutePath = p.join(vaultRoot, notePath);
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Error deleting note file at $notePath: $e");
      rethrow;
    }
  }

  Future<void> deleteImage(String vaultRoot, String relativePath) async {
    try {
      final absolutePath = p.join(vaultRoot, relativePath);
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Error deleting image file at $relativePath: $e");
      rethrow;
    }
  }

  Future<List<File>> listImages(String vaultRoot) async {
    final imagesDir = Directory(p.join(vaultRoot, 'images'));
    if (!await imagesDir.exists()) {
      return [];
    }
    final entities = await imagesDir.list().toList();
    return entities.whereType<File>().toList();
  }

  Future<String> saveImage(String vaultRoot, File imageFile) async {
    final imagesDir = Directory(p.join(vaultRoot, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    final uniqueFilename = _generateUniqueFilename(imageFile.path);
    final newPath = p.join(imagesDir.path, uniqueFilename);
    await imageFile.copy(newPath);
    
    // Return the relative path for use in Markdown
    return p.join('images', uniqueFilename);
  }
}