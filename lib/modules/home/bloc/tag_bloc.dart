import 'dart:async';
import 'dart:developer' as developer;

import 'package:document_companion/local_database/handler/tag_database_handler.dart';
import 'package:document_companion/local_database/models/tag_model.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TagBloc {
  final StreamController<List<TagModel>> _tagsController =
      StreamController<List<TagModel>>.broadcast();
  Stream<List<TagModel>> get tagsStream => _tagsController.stream;

  final TagDatabaseHandler _databaseHandler = tagDatabaseHandler;
  final Uuid _uuid = Uuid();

  Future<void> fetchTags() async {
    try {
      final tags = await _databaseHandler.getAllTags();
      _tagsController.sink.add(tags);
    } catch (e) {
      developer.log('Error fetching tags', error: e);
      _tagsController.sink.add([]);
    }
  }

  Future<TagModel> createTag(String name, String color) async {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final tag = TagModel(
      id: _uuid.v4(),
      name: name.trim(),
      color: color,
      createdOn: timestamp,
    );

    await _databaseHandler.insertTag(tag);
    await fetchTags();
    return tag;
  }

  Future<void> updateTag(TagModel tag) async {
    await _databaseHandler.updateTag(tag);
    await fetchTags();
  }

  Future<void> deleteTag(String tagId) async {
    await _databaseHandler.deleteTag(tagId);
    await fetchTags();
  }

  Future<List<TagModel>> getTagsByFolderId(String folderId) async {
    try {
      return await _databaseHandler.getTagsByFolderId(folderId);
    } catch (e) {
      developer.log('Error getting tags by folder id', error: e);
      return [];
    }
  }

  Future<List<TagModel>> getTagsByDocumentId(String documentId) async {
    try {
      return await _databaseHandler.getTagsByDocumentId(documentId);
    } catch (e) {
      developer.log('Error getting tags by document id', error: e);
      return [];
    }
  }

  Future<void> addTagToFolder(String folderId, String tagId) async {
    await _databaseHandler.addTagToFolder(folderId, tagId);
  }

  Future<void> removeTagFromFolder(String folderId, String tagId) async {
    await _databaseHandler.removeTagFromFolder(folderId, tagId);
  }

  Future<void> addTagToDocument(String documentId, String tagId) async {
    await _databaseHandler.addTagToDocument(documentId, tagId);
  }

  Future<void> removeTagFromDocument(String documentId, String tagId) async {
    await _databaseHandler.removeTagFromDocument(documentId, tagId);
  }

  void dispose() {
    _tagsController.close();
  }
}

final tagBloc = TagBloc();
