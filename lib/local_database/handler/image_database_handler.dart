import 'package:document_companion/local_database/handler/local_database_handler.dart';
import 'package:document_companion/local_database/models/image_model.dart';
import 'package:sqflite/sqflite.dart';

class ImageDatabaseHandler {
  static const _tableName = 'Images';

  Future<void> insertImage(ImageModel image) async {
    final database = await localDatabaseHandler.db;
    await database?.insert(
      _tableName,
      image.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ImageModel>> getImagesByFolderId(String folderId) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _tableName,
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'created_on DESC',
    );
    return List.generate(maps?.length ?? 0, (i) {
      return ImageModel.fromMap(maps![i]);
    });
  }

  Future<List<ImageModel>> getAllImages() async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _tableName,
      orderBy: 'created_on DESC',
    );
    return List.generate(maps?.length ?? 0, (i) {
      return ImageModel.fromMap(maps![i]);
    });
  }

  Future<ImageModel?> getImageById(String id) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps != null && maps.isNotEmpty) {
      return ImageModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteImage(String id) async {
    final database = await localDatabaseHandler.db;
    await database?.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteImagesByFolderId(String folderId) async {
    final database = await localDatabaseHandler.db;
    await database?.delete(
      _tableName,
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  Future<int> getImageCountByFolderId(String folderId) async {
    final database = await localDatabaseHandler.db;
    final result = await database?.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE folder_id = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result ?? []) ?? 0;
  }

  Future<void> updateImage(ImageModel image) async {
    final database = await localDatabaseHandler.db;
    await database?.update(
      _tableName,
      image.toMap(),
      where: 'id = ?',
      whereArgs: [image.id],
    );
  }
}

final imageDatabaseHandler = ImageDatabaseHandler();

