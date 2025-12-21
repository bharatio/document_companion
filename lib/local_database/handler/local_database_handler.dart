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
      version: 5, // Increment version for indexes
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
    // Create [RecentDocuments] table for tracking recently accessed documents
    await db.execute(
      "CREATE TABLE RecentDocuments(id TEXT PRIMARY KEY, document_id TEXT, document_type TEXT, folder_id TEXT, document_name TEXT, accessed_on TEXT, thumbnail BLOB)",
    );
    // Create [Tags] table
    await db.execute(
      "CREATE TABLE Tags(id TEXT PRIMARY KEY, name TEXT UNIQUE, color TEXT, created_on TEXT)",
    );
    // Create [Folder_Tags] junction table
    await db.execute(
      "CREATE TABLE Folder_Tags(folder_id TEXT, tag_id TEXT, PRIMARY KEY (folder_id, tag_id), FOREIGN KEY (folder_id) REFERENCES Folders(id) ON DELETE CASCADE, FOREIGN KEY (tag_id) REFERENCES Tags(id) ON DELETE CASCADE)",
    );
    // Create [Document_Tags] junction table
    await db.execute(
      "CREATE TABLE Document_Tags(document_id TEXT, tag_id TEXT, PRIMARY KEY (document_id, tag_id), FOREIGN KEY (document_id) REFERENCES Images(id) ON DELETE CASCADE, FOREIGN KEY (tag_id) REFERENCES Tags(id) ON DELETE CASCADE)",
    );

    // Create indexes for better query performance
    await db.execute("CREATE INDEX idx_images_folder_id ON Images(folder_id)");
    await db.execute(
      "CREATE INDEX idx_images_created_on ON Images(created_on)",
    );
    await db.execute(
      "CREATE INDEX idx_images_modified_on ON Images(modified_on)",
    );
    await db.execute(
      "CREATE INDEX idx_folders_created_on ON Folders(created_on)",
    );
    await db.execute(
      "CREATE INDEX idx_folders_modified_on ON Folders(modified_on)",
    );
    await db.execute(
      "CREATE INDEX idx_recent_documents_accessed_on ON RecentDocuments(accessed_on)",
    );
    await db.execute(
      "CREATE INDEX idx_recent_documents_document_id ON RecentDocuments(document_id)",
    );
    await db.execute(
      "CREATE INDEX idx_folder_tags_folder_id ON Folder_Tags(folder_id)",
    );
    await db.execute(
      "CREATE INDEX idx_folder_tags_tag_id ON Folder_Tags(tag_id)",
    );
    await db.execute(
      "CREATE INDEX idx_document_tags_document_id ON Document_Tags(document_id)",
    );
    await db.execute(
      "CREATE INDEX idx_document_tags_tag_id ON Document_Tags(tag_id)",
    );
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add Images table for existing databases
      await db.execute(
        "CREATE TABLE IF NOT EXISTS Images(id TEXT PRIMARY KEY, folder_id TEXT, image BLOB, name TEXT, created_on TEXT, modified_on TEXT, size INTEGER, width INTEGER, height INTEGER, FOREIGN KEY (folder_id) REFERENCES Folders(id) ON DELETE CASCADE)",
      );
    }
    if (oldVersion < 3) {
      // Add RecentDocuments table for tracking recently accessed documents
      await db.execute(
        "CREATE TABLE IF NOT EXISTS RecentDocuments(id TEXT PRIMARY KEY, document_id TEXT, document_type TEXT, folder_id TEXT, document_name TEXT, accessed_on TEXT, thumbnail BLOB)",
      );
    }
    if (oldVersion < 4) {
      // Add Tags table
      await db.execute(
        "CREATE TABLE IF NOT EXISTS Tags(id TEXT PRIMARY KEY, name TEXT UNIQUE, color TEXT, created_on TEXT)",
      );
      // Add Folder_Tags junction table
      await db.execute(
        "CREATE TABLE IF NOT EXISTS Folder_Tags(folder_id TEXT, tag_id TEXT, PRIMARY KEY (folder_id, tag_id), FOREIGN KEY (folder_id) REFERENCES Folders(id) ON DELETE CASCADE, FOREIGN KEY (tag_id) REFERENCES Tags(id) ON DELETE CASCADE)",
      );
      // Add Document_Tags junction table
      await db.execute(
        "CREATE TABLE IF NOT EXISTS Document_Tags(document_id TEXT, tag_id TEXT, PRIMARY KEY (document_id, tag_id), FOREIGN KEY (document_id) REFERENCES Images(id) ON DELETE CASCADE, FOREIGN KEY (tag_id) REFERENCES Tags(id) ON DELETE CASCADE)",
      );

      // Create indexes for better query performance
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_images_folder_id ON Images(folder_id)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_images_created_on ON Images(created_on)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_images_modified_on ON Images(modified_on)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_folders_created_on ON Folders(created_on)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_folders_modified_on ON Folders(modified_on)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_recent_documents_accessed_on ON RecentDocuments(accessed_on)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_recent_documents_document_id ON RecentDocuments(document_id)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_folder_tags_folder_id ON Folder_Tags(folder_id)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_folder_tags_tag_id ON Folder_Tags(tag_id)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_document_tags_document_id ON Document_Tags(document_id)",
      );
      await db.execute(
        "CREATE INDEX IF NOT EXISTS idx_document_tags_tag_id ON Document_Tags(tag_id)",
      );
    }
  }
}

final localDatabaseHandler = LocalDatabaseHandler();
