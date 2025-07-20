// lib/models/cloud_file.dart

class CloudFile {
  final String? id; // UUID from Supabase
  final String name;
  final String? cloudPath; // Full path in Supabase Storage
  final bool isFolder;
  final int size;
  final DateTime lastModified;

  CloudFile({
    this.id,
    required this.name,
    this.cloudPath,
    this.isFolder = false,
    required this.size,
    required this.lastModified,
  });

  factory CloudFile.fromSupabase(Map<String, dynamic> data) {
    return CloudFile(
      id: data['id'],
      name: data['name'] ?? 'Unnamed',
      cloudPath: data['path'], 
      isFolder: data['is_folder'] ?? false,
      size: data['metadata']?['size'] ?? 0,
      lastModified: DateTime.parse(data['updated_at'] ?? data['created_at']),
    );
  }

  CloudFile copyWith({
    String? id,
    String? name,
    String? cloudPath,
    bool? isFolder,
    int? size,
    DateTime? lastModified,
  }) {
    return CloudFile(
      id: id ?? this.id,
      name: name ?? this.name,
      cloudPath: cloudPath ?? this.cloudPath,
      isFolder: isFolder ?? this.isFolder,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}