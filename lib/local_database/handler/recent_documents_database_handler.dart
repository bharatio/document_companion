import 'package:document_companion/local_database/handler/local_database_handler.dart';
import 'package:document_companion/local_database/models/recent_document_model.dart';
import 'package:sqflite/sqflite.dart';

class RecentDocumentsDatabaseHandler {
  static const _tableName = 'RecentDocuments';

  Future<void> insertOrUpdateRecentDocument(
    RecentDocumentModel recentDocument,
  ) async {
    final database = await localDatabaseHandler.db;
    await database?.insert(
      _tableName,
      recentDocument.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RecentDocumentModel>> getRecentDocuments({int limit = 10}) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _tableName,
      orderBy: 'accessed_on DESC',
      limit: limit,
    );
    return List.generate(maps?.length ?? 0, (i) {
      return RecentDocumentModel.fromMap(maps![i]);
    });
  }

  Future<void> deleteRecentDocument(String id) async {
    final database = await localDatabaseHandler.db;
    await database?.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearRecentDocuments() async {
    final database = await localDatabaseHandler.db;
    await database?.delete(_tableName);
  }

  Future<void> deleteRecentDocumentByDocumentId(String documentId) async {
    final database = await localDatabaseHandler.db;
    await database?.delete(
      _tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  Future<RecentDocumentModel?> getRecentDocumentByDocumentId(
    String documentId,
  ) async {
    final database = await localDatabaseHandler.db;
    final List<Map<String, Object?>>? maps = await database?.query(
      _tableName,
      where: 'document_id = ?',
      whereArgs: [documentId],
      limit: 1,
    );
    if (maps != null && maps.isNotEmpty) {
      return RecentDocumentModel.fromMap(maps.first);
    }
    return null;
  }
}

final recentDocumentsDatabaseHandler = RecentDocumentsDatabaseHandler();
