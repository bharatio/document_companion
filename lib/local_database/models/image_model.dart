import 'dart:typed_data';

class ImageModel {
  ImageModel({
    required this.id,
    required this.folderId,
    required this.image,
    required this.name,
    required this.createdOn,
    required this.modifiedOn,
    this.size,
    this.width,
    this.height,
  });

  String id;
  String folderId;
  Uint8List image;
  String name;
  String createdOn;
  String modifiedOn;
  int? size;
  int? width;
  int? height;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folder_id': folderId,
      'image': image,
      'name': name,
      'created_on': createdOn,
      'modified_on': modifiedOn,
      'size': size,
      'width': width,
      'height': height,
    };
  }

  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
      id: map['id'] as String,
      folderId: map['folder_id'] as String,
      image: map['image'] as Uint8List,
      name: map['name'] as String,
      createdOn: map['created_on'] as String,
      modifiedOn: map['modified_on'] as String,
      size: map['size'] as int?,
      width: map['width'] as int?,
      height: map['height'] as int?,
    );
  }
}

