import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseHandler {
  static Database? _db;

  Future<Database?> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  Future<Database?> initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "test.db");
    var theDb = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    // Create [CurrentImage] table
    await db.execute(
      "CREATE TABLE CurrentImages(id TEXT PRIMARY KEY, image BLOB, timestamp TEXT, is_shoot_through_fast_camera TEXT, low_res_image BLOB )",
    );
    // Create [Folders] table
    await db.execute(
      "CREATE TABLE Folders(id TEXT PRIMARY KEY, folder_name TEXT, created_on TEXT, modified_on TEXT )",
    );
    // Create [Images] table for folder-linked images
    await db.execute(
      "CREATE TABLE Images(id TEXT PRIMARY KEY, folder_id TEXT, image BLOB, name TEXT, created_on TEXT, modified_on TEXT, size INTEGER, width INTEGER, height INTEGER, FOREIGN KEY (folder_id) REFERENCES Folders(id) ON DELETE CASCADE)",
    );
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add Images table for existing databases
      await db.execute(
        "CREATE TABLE IF NOT EXISTS Images(id TEXT PRIMARY KEY, folder_id TEXT, image BLOB, name TEXT, created_on TEXT, modified_on TEXT, size INTEGER, width INTEGER, height INTEGER, FOREIGN KEY (folder_id) REFERENCES Folders(id) ON DELETE CASCADE)",
      );
    }
  }
}

final localDatabaseHandler = LocalDatabaseHandler();
