// lib/models/cloud_file.dart

class CloudFile {
  final String? id; 
  final String name; 
  final String? cloudPath; 
  final bool isFolder; 
  final int size; 
  
  final DateTime updatedAt; 
  
  final bool isDeleted; 
  
  final String? mimeType; 
  final String? parentId; 
  final String? storageObjectId; 
  final DateTime createdAt; 
  final bool isPublic; 

  CloudFile({
    this.id,
    required this.name,
    this.cloudPath,
    this.isFolder = false,
    required this.size,
    required this.updatedAt,
    this.isDeleted = false,
    this.mimeType,
    this.parentId,
    this.storageObjectId,
    required this.createdAt,
    this.isPublic = false,
  });

  factory CloudFile.fromSupabase(Map<String, dynamic> data) {
    final defaultDate = DateTime.now().toUtc();
    
    return CloudFile(
      id: data['id'],
      name: data['name'] ?? 'Unnamed',
      cloudPath: data['path'], 
      isFolder: data['is_folder'] ?? false,
      size: data['size'] ?? data['metadata']?['size'] ?? 0,
      
      updatedAt: DateTime.tryParse(data['updated_at'] ?? '') ?? defaultDate,
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? defaultDate,
      
      isDeleted: data['is_deleted'] ?? false,
      
      mimeType: data['mime_type'],
      parentId: data['parent_id'],
      storageObjectId: data['storage_object_id'],
      isPublic: data['is_public'] ?? false,
    );
  }

  CloudFile copyWith({
    String? id,
    String? name,
    String? cloudPath,
    bool? isFolder,
    int? size,
    DateTime? updatedAt,
    bool? isDeleted,
    String? mimeType,
    String? parentId,
    String? storageObjectId,
    DateTime? createdAt,
    bool? isPublic,
  }) {
    return CloudFile(
      id: id ?? this.id,
      name: name ?? this.name,
      cloudPath: cloudPath ?? this.cloudPath,
      isFolder: isFolder ?? this.isFolder,
      size: size ?? this.size,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      mimeType: mimeType ?? this.mimeType,
      parentId: parentId ?? this.parentId,
      storageObjectId: storageObjectId ?? this.storageObjectId,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}