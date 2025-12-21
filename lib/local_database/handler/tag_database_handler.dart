import 'package:document_companion/local_database/handler/local_database_handler.dart';
import 'package:document_companion/local_database/models/tag_model.dart';
import 'package:sqflite/sqflite.dart';

class TagDatabaseHandler {
  static const _tableName = 'Tags';
  static const _folderTagsTableName = 'Folder_Tags';
  static const _documentTagsTableName = 'Document_Tags';

  Future<void> insertTag(TagModel tag) async {
    final database = await localDatabaseHandler.db;
    await database?.insert(
      _tableName,
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TagModel>> getAllTags() async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _tableName,
      orderBy: 'name ASC',
    );
    return List.generate(maps?.length ?? 0, (i) {
      return TagModel.fromMap(maps![i]);
    });
  }

  Future<TagModel?> getTagById(String id) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps != null && maps.isNotEmpty) {
      return TagModel.fromMap(maps.first);
    }
    return null;
  }

  Future<TagModel?> getTagByName(String name) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _tableName,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (maps != null && maps.isNotEmpty) {
      return TagModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteTag(String id) async {
    final database = await localDatabaseHandler.db;
    // Delete tag from junction tables first
    await database?.delete(
      _folderTagsTableName,
      where: 'tag_id = ?',
      whereArgs: [id],
    );
    await database?.delete(
      _documentTagsTableName,
      where: 'tag_id = ?',
      whereArgs: [id],
    );
    // Delete tag itself
    await database?.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTag(TagModel tag) async {
    final database = await localDatabaseHandler.db;
    await database?.update(
      _tableName,
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  // Folder Tags
  Future<void> addTagToFolder(String folderId, String tagId) async {
    final database = await localDatabaseHandler.db;
    await database?.insert(_folderTagsTableName, {
      'folder_id': folderId,
      'tag_id': tagId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeTagFromFolder(String folderId, String tagId) async {
    final database = await localDatabaseHandler.db;
    await database?.delete(
      _folderTagsTableName,
      where: 'folder_id = ? AND tag_id = ?',
      whereArgs: [folderId, tagId],
    );
  }

  Future<List<TagModel>> getTagsByFolderId(String folderId) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.rawQuery(
      '''
      SELECT t.* FROM $_tableName t
      INNER JOIN $_folderTagsTableName ft ON t.id = ft.tag_id
      WHERE ft.folder_id = ?
      ORDER BY t.name ASC
      ''',
      [folderId],
    );
    return List.generate(maps?.length ?? 0, (i) {
      return TagModel.fromMap(maps![i]);
    });
  }

  // Document Tags
  Future<void> addTagToDocument(String documentId, String tagId) async {
    final database = await localDatabaseHandler.db;
    await database?.insert(_documentTagsTableName, {
      'document_id': documentId,
      'tag_id': tagId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeTagFromDocument(String documentId, String tagId) async {
    final database = await localDatabaseHandler.db;
    await database?.delete(
      _documentTagsTableName,
      where: 'document_id = ? AND tag_id = ?',
      whereArgs: [documentId, tagId],
    );
  }

  Future<List<TagModel>> getTagsByDocumentId(String documentId) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.rawQuery(
      '''
      SELECT t.* FROM $_tableName t
      INNER JOIN $_documentTagsTableName dt ON t.id = dt.tag_id
      WHERE dt.document_id = ?
      ORDER BY t.name ASC
      ''',
      [documentId],
    );
    return List.generate(maps?.length ?? 0, (i) {
      return TagModel.fromMap(maps![i]);
    });
  }

  Future<List<String>> getDocumentIdsByTagId(String tagId) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _documentTagsTableName,
      columns: ['document_id'],
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );
    return maps?.map((map) => map['document_id'] as String).toList() ?? [];
  }

  Future<List<String>> getFolderIdsByTagId(String tagId) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _folderTagsTableName,
      columns: ['folder_id'],
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );
    return maps?.map((map) => map['folder_id'] as String).toList() ?? [];
  }
}

final tagDatabaseHandler = TagDatabaseHandler();
