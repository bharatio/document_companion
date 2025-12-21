class RecentDocumentModel {
  RecentDocumentModel({
    required this.id,
    required this.documentId,
    required this.documentType,
    required this.folderId,
    required this.documentName,
    required this.accessedOn,
    this.thumbnail,
  });

  String id;
  String documentId;
  String documentType; // 'image' or 'pdf'
  String folderId;
  String documentName;
  String accessedOn;
  List<int>? thumbnail; // Thumbnail bytes for quick preview

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'document_type': documentType,
      'folder_id': folderId,
      'document_name': documentName,
      'accessed_on': accessedOn,
      'thumbnail': thumbnail,
    };
  }

  factory RecentDocumentModel.fromMap(Map<String, dynamic> map) {
    return RecentDocumentModel(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      documentType: map['document_type'] as String,
      folderId: map['folder_id'] as String,
      documentName: map['document_name'] as String,
      accessedOn: map['accessed_on'] as String,
      thumbnail: map['thumbnail'] != null
          ? List<int>.from(map['thumbnail'] as List)
          : null,
    );
  }
}

