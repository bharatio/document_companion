import 'dart:async';

import 'package:document_companion/local_database/handler/folder_table_handler.dart';
import 'package:document_companion/local_database/models/folder_model.dart';
import 'package:uuid/uuid.dart';

import '../models/folder_view_model.dart';

class FolderBloc {
  final uuid = Uuid();
  StreamController<List<FolderViewModel>> folderListController =
      StreamController<List<FolderViewModel>>.broadcast();
  Stream<List<FolderViewModel>> get folderList => folderListController.stream;

  List<FolderViewModel> _allFolders = [];
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'created', 'modified'
  bool _sortAscending = true;

  Future<void> createFolder(String folderName) async {
    final tableData = FolderModel(
      id: uuid.v4(),
      folderName: folderName,
      createdOn: DateTime.now().millisecondsSinceEpoch.toString(),
      modifiedOn: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    await folderTableHandler.insertFolder(tableData);
    await fetchFolders();
  }

  Future<void> fetchFolders() async {
    List<FolderModel> foldersData = await folderTableHandler.getFolders();
    _allFolders = [];
    for (var folder in foldersData) {
      _allFolders.add(
        FolderViewModel(
          id: folder.id,
          createdOn: folder.createdOn,
          folderName: folder.folderName,
          modifiedOn: folder.modifiedOn,
        ),
      );
    }
    _applyFilters();
  }

  void searchFolders(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void sortFolders(String sortBy, {bool ascending = true}) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFilters();
  }

  void _applyFilters() {
    List<FolderViewModel> filtered = List.from(_allFolders);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((folder) {
        return folder.folderName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.folderName.compareTo(b.folderName);
          break;
        case 'created':
          comparison = a.createdOn.compareTo(b.createdOn);
          break;
        case 'modified':
          comparison = a.modifiedOn.compareTo(b.modifiedOn);
          break;
        default:
          comparison = a.folderName.compareTo(b.folderName);
      }
      return _sortAscending ? comparison : -comparison;
    });

    folderListController.add(filtered);
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  Future<void> updateFolder(String folderId, String newName) async {
    final folder = _allFolders.firstWhere((f) => f.id == folderId);
    final updatedFolder = FolderModel(
      id: folder.id,
      folderName: newName,
      createdOn: folder.createdOn,
      modifiedOn: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    await folderTableHandler.updateFolder(updatedFolder);
    await fetchFolders();
  }

  Future<void> deleteFolder(String folderId) async {
    await folderTableHandler.deleteFolder(folderId);
    await fetchFolders();
  }
}

final folderBloc = FolderBloc();
