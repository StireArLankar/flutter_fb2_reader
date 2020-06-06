import 'package:flutter_observable_state/flutter_observable_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:typed_data';

Future<void> onCreate(Database db, int version) async {
  return db.transaction((txn) async {
    await txn.execute("DROP TABLE IF EXISTS Images");
    await txn.execute("DROP TABLE IF EXISTS Test");

    await txn
        .execute('CREATE TABLE Images(guid TEXT PRIMARY KEY, source TEXT, id TEXT, image BLOB)');

    await txn.execute(
      'CREATE TABLE Test (path TEXT PRIMARY KEY, filename TEXT, description TEXT, content TEXT, cover BLOB, modified TEXT)',
    );
  });
}

Future<Database> openDB() async {
  var databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'demo.db');

  return openDatabase(path, version: 1, onCreate: onCreate).then((value) {
    print('Opened DB');
    return value;
  });
}

class ParsedDescription {
  final String path;
  final String description;
  final Uint8List cover;

  ParsedDescription(this.path, this.description, this.cover);
}

class ParsedBook {
  final String title;
  final String path;
  final Map<String, Uint8List> imagesMap;
  final Map<int, int> offsetsMap;
  final String content;
  final Uint8List cover;

  ParsedBook(
    this.title,
    this.path,
    this.imagesMap,
    this.offsetsMap,
    this.content,
    this.cover,
  );
}

class AppState {
  final isInitialized = Observable(false);

  final fontSize = Observable(14.0);

  final openedDescription = Observable<ParsedDescription>(null);

  final openedBook = Observable<ParsedBook>(null);

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
    db = await openDatabase(path, version: 1, onCreate: onCreate).then((value) {
      print('Opened DB');
      return value;
    });
  }

  AppState() {
    Future.wait([openDB(), initConfig()])
        .then((_) => isInitialized.change((_) => true))
        .catchError((e) => print(e));
  }
}
