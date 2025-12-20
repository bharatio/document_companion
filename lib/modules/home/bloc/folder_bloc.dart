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
      folder_name: folderName,
      created_on: DateTime.now().millisecondsSinceEpoch.toString(),
      modified_on: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    await folderTableHandler.insertFolder(tableData);
    await fetchFolders();
  }

  Future<void> fetchFolders() async {
    List<FolderModel> foldersData = await folderTableHandler.getFolders();
    _allFolders = [];
    foldersData.forEach(
      (folder) => _allFolders.add(
        FolderViewModel(
          id: folder.id,
          created_on: folder.created_on,
          folder_name: folder.folder_name,
          modified_on: folder.modified_on,
        ),
      ),
    );
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
        return folder.folder_name.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.folder_name.compareTo(b.folder_name);
          break;
        case 'created':
          comparison = a.created_on.compareTo(b.created_on);
          break;
        case 'modified':
          comparison = a.modified_on.compareTo(b.modified_on);
          break;
        default:
          comparison = a.folder_name.compareTo(b.folder_name);
      }
      return _sortAscending ? comparison : -comparison;
    });

    folderListController.add(filtered);
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }
}

final folderBloc = FolderBloc();
