import 'package:flutter_observable_state/flutter_observable_state.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/parsed_book.dart';
import '../models/parsed_description.dart';

final tableImages = 'Images';
final tableBooks = 'Books';

Future<void> onOpen(Database db) async {
  return db.transaction((txn) async {
    await txn.execute("DROP TABLE IF EXISTS $tableImages");
    await txn.execute("DROP TABLE IF EXISTS $tableBooks");

    await txn.execute("CREATE TABLE $tableImages ("
        "guid INTEGER PRIMARY KEY AUTOINCREMENT,"
        "source TEXT,"
        "id TEXT,"
        "image BLOB"
        ")");

    await txn.execute("CREATE TABLE $tableBooks ("
        "guid INTEGER PRIMARY KEY AUTOINCREMENT,"
        "path TEXT,"
        "filename TEXT,"
        "description TEXT,"
        "content TEXT,"
        "cover BLOB,"
        "preview BLOB,"
        "modified TEXT,"
        "opened TEXT,"
        "chapters TEXT,"
        "title TEXT"
        ")");
  });
}

class AppState {
  final isInitialized = Observable(false);

  final fontSize = Observable(14.0);

  final openedDescription = Observable<ParsedDescription>(null);

  final openedBook = Observable<ParsedBook>(null);

  final booksList = Observable<List<ParsedBook>>([]);

  Database db;

  Future<void> initConfig() {
    return SharedPreferences.getInstance().then((prefs) {
      try {
        final fSize = prefs.getDouble('fontSize');
        if (fontSize == null) throw Error();
        fontSize.change((_) => fSize);
      } catch (e) {
        fontSize.change((_) => 14.0);
        prefs.setDouble('fontSize', 14.0);
      }
    });
  }

  Future<void> openDB() async {
    final databasesPath = await getDatabasesPath();
    print('databasesPath: $databasesPath');
    String path = join(databasesPath, 'database.db');
    db = await openDatabase(path, version: 1, onOpen: onOpen).then((value) {
      print('Opened DB');
      return value;
    });

    return;
  }

  AppState() {
    Future.wait([openDB(), initConfig()])
        .then((_) => isInitialized.change((_) => true))
        .catchError((e) => print(e));
  }
}
