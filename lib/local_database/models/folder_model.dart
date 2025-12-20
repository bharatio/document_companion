class FolderModel {
  FolderModel({
    required this.id,
    required this.folderName,
    required this.createdOn,
    required this.modifiedOn,
  });
  String id;
  String folderName;
  String createdOn;
  String modifiedOn;
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folder_name': folderName,
      'created_on': createdOn,
      'modified_on': modifiedOn,
    };
  }
}
