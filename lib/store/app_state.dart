import 'package:flutter_observable_state/flutter_observable_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';

Future<void> onOpen(Database db) async {
  return db.transaction((txn) async {
    await txn.execute("DROP TABLE IF EXISTS Images");
    await txn.execute("DROP TABLE IF EXISTS Test");
    await txn.execute("DROP TABLE IF EXISTS Books");

    await txn
        .execute('CREATE TABLE Images(guid TEXT PRIMARY KEY, source TEXT, id TEXT, image BLOB)');

    await txn.execute(
      'CREATE TABLE Books (path TEXT PRIMARY KEY, filename TEXT, description TEXT, content TEXT, cover BLOB, modified TEXT, opened TEXT, chapters TEXT)',
    );
  });
}

class ParsedDescription {
  final String path;
  final String description;
  final Uint8List cover;

  ParsedDescription(this.path, this.description, this.cover);
}

class ChapterModel {
  double progress;
  int leadingIndex;
  double leadingOffset;

  ChapterModel({this.progress, this.leadingIndex, this.leadingOffset});

  ChapterModel.fromJson(Map<String, dynamic> json) {
    progress = json['progress'];
    leadingIndex = json['leadingIndex'];
    leadingOffset = json['leadingOffset'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['progress'] = this.progress;
    data['leadingIndex'] = this.leadingIndex;
    data['leadingOffset'] = this.leadingOffset;
    return data;
  }
}

class ParsedBook {
  final String title;
  final String path;
  final Map<String, Uint8List> imagesMap;
  // [leadingIndex, leadingOffset, progress]
  final Map<int, ChapterModel> offsetsMap;
  final String content;
  final Uint8List preview;

  ParsedBook(
    this.title,
    this.path,
    this.imagesMap,
    this.offsetsMap,
    this.content,
    this.preview,
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
