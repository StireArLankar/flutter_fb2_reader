import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tuple/tuple.dart';
import 'package:xml/xml.dart' as xml;

import '../models/book.dart';
import '../models/chapter.dart';
import '../models/parsed_book.dart';
import '../models/parsed_description.dart';
import '../models/parsed_preview.dart';
import '../store/actions/get_images.dart';
import 'app_state.dart';
import 'services.dart';

Future<Tuple2<BookModel, Map<String, Uint8List>>> _prepareBook(String path) async {
  if (path.split('/').last == 'zip') {
    path = await _prepareZip(path);
  }

  final file = File(path);
  final filename = path.split('/').last;
  final contents = await file.readAsString();
  final document = xml.XmlDocument.parse(contents);

  final description = document.findAllElements('description').first;
  final title = description.getElement('title-info').getElement('book-title').text;

  final bodyies = document.findAllElements('body').map((body) {
    return body.innerXml.replaceAll('<image', '<img').replaceAll(RegExp(r">\s+<"), '><').trim();
  }).join('');
  final content = '<body>' + bodyies + '</body>';

  final images = await getImages(document);
  final preview = images.item1;
  final cover = images.item2;
  final imagesMap = images.item3;
  final fileStats = await file.stat();
  final modified = fileStats.modified;
  final opened = DateTime.now();
  final Map<int, ChapterModel> chapters = {};

  final book = BookModel(
    path: path,
    filename: filename,
    description: description.toXmlString(),
    content: content,
    cover: cover,
    preview: preview,
    modified: modified.toIso8601String(),
    opened: opened.toIso8601String(),
    chapters: chapters,
    currentChapter: 0,
    title: title,
  );

  return Tuple2(book, imagesMap);
}

Future<String> _prepareZip(String path) async {
  try {
    final bytes = File(path).readAsBytesSync();

    final archive = ZipDecoder().decodeBytes(bytes);

    final tempDirectory = await getTemporaryDirectory();

    for (final file in archive) {
      final filename = file.name;

      if (file.isFile && filename.split('.').last == 'fb2') {
        final data = file.content;

        final cachePath = p.join(tempDirectory.path, filename);

        if (!await File(cachePath).exists()) {
          File(cachePath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }

        return Future.value(cachePath);
      }
    }
  } catch (e) {
    print('Failder to cache zip file');
  }

  return Future.value(null);
}

Future<void> _addBookToDB(
  String path,
  Tuple2<BookModel, Map<String, Uint8List>> res,
  Database db,
) async {
  final book = res.item1;
  final imagesMap = res.item2;

  await db.transaction((txn) async {
    await txn.insert(
      tableBooks,
      book.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    var batch = txn.batch();

    imagesMap.forEach((key, value) {
      batch.insert(
        tableImages,
        {'source': path, 'id': key, 'image': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    await batch.commit();
  });
}

Future<Tuple2<BookModel, Map<String, Uint8List>>> _readBookFromDB(
  String path,
  Database db,
) async {
  List<Map<String, dynamic>> booksRaw;
  List<Map<String, dynamic>> imagesRaw;

  await db.transaction((txn) async {
    print('Getting books');
    booksRaw = await txn.query(tableBooks, where: "path = ?", whereArgs: [path]);
    print('Getting Images');
    imagesRaw = await txn.query(tableImages, where: "source = ?", whereArgs: [path]);
    print('Got resources');
    return;
  });

  final bookRaw = booksRaw.first;
  final book = BookModel.fromJson(bookRaw);

  final Map<String, Uint8List> imagesMap = {};

  try {
    imagesRaw.forEach((element) {
      imagesMap[element['id']] = element['image'];
    });
  } catch (e) {
    print('Failed in parsing images');
  }

  return Tuple2(book, imagesMap);
}

Future<ParsedDescription> _readDescriptionFromDB(
  String path,
  Database db,
) async {
  final rawList = await db.query(
    tableBooks,
    where: "path = ?",
    whereArgs: [path],
    columns: ['cover', 'description', 'title'],
  );

  if (rawList.length == 0) {
    return null;
  }

  final book = rawList.first;

  return ParsedDescription(
    path,
    book['description'],
    book['cover'],
    book['title'],
    true,
  );
}

Future<ParsedDescription> _readDescriptionFromFile(String initialPath) async {
  // TODO decide smthing with unique paths
  var path = initialPath;

  if (path.split('.').last == 'zip') {
    path = await _prepareZip(path);
  }

  final file = File(path);
  final contents = await file.readAsString();
  final document = xml.XmlDocument.parse(contents);

  final desc = document.findAllElements('description').first;
  final title = desc.getElement('title-info').getElement('book-title').text;
  Uint8List cover;

  try {
    final coverpage = desc.findAllElements('coverpage').first;

    final imgId = coverpage
        .findElements('image')
        .first
        .attributes
        .firstWhere((element) => element.name.toString() == 'l:href')
        .value;

    final binary = document.findAllElements('binary').firstWhere((element) {
      final attrib = element.attributes.firstWhere((element) => element.name.toString() == 'id');
      final res = '#' + attrib.value == imgId;

      return res;
    });

    cover = base64Decode(binary.text.trim());
  } catch (e) {}

  final res = ParsedDescription(path, desc.toXmlString(), cover, title, false);

  return Future.value(res);
}

Future<ParsedDescription> _readDescription(String path, Database db) async {
  var res = await _readDescriptionFromDB(path, db);

  if (res == null) {
    res = await _readDescriptionFromFile(path);
  }

  return res;
}

class ActionS {
  final _state = getIt.get<AppState>();

  Future<void> setFontSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setDouble('fontSize', size);
      _state.fontSize.change((_) => size);
    } catch (e) {}
  }

  Future<void> setOpenedDescription(String path) async {
    final res = await _readDescription(path, _state.db);

    return _state.openedDescription.change((_) => res);
  }

  void clearOpenedDescription() {
    _state.openedDescription.change((_) => null);
  }

  void clearOpenedBook() {
    _state.openedBook.change((_) => null);
  }

  Future<void> openBook(
    String path,
    Tuple2<BookModel, Map<String, Uint8List>> res,
  ) async {
    final book = res.item1;
    final imagesMap = res.item2;
    final parsedBook = ParsedBook.fromBook(book, imagesMap);
    final parsedPreview = ParsedPreview.fromBook(book);

    _state.booksList.change((prev) {
      final hasBook = prev.any((element) => element.path == path);
      if (!hasBook) {
        prev.add(parsedPreview);
      }
      return prev;
    });

    return _state.openedBook.change((_) => parsedBook);
  }

  Future<void> openBookFromDB(String path) async {
    final res = await _readBookFromDB(path, _state.db);

    await openBook(path, res);
  }

  void _updateDescription(BookModel book, bool isInLibrary) {
    final res = ParsedDescription(
      book.path,
      book.description,
      book.cover,
      book.title,
      isInLibrary,
    );

    _state.openedDescription.change((_) => res);
  }

  Future<void> addBookToDBAndOpen(String path) async {
    final res = await _prepareBook(path);

    await _addBookToDB(path, res, _state.db);

    _updateDescription(res.item1, true);

    await openBook(path, res);
  }

  Future<void> updateBookChapters(int currentChapter) async {
    try {
      final book = _state.openedBook.get();
      final path = book.path;
      final chapters =
          book.offsetsMap.map((key, value) => MapEntry(key.toString(), value.toJson()));
      final date = DateTime.now().toIso8601String();

      _state.db.update(
        tableBooks,
        {
          'chapters': json.encode(chapters),
          'currentChapter': currentChapter,
          'opened': date,
        },
        where: "path = ?",
        whereArgs: [path],
      );

      _state.booksList.change((prev) {
        final currentInList = prev.firstWhere((element) => element.path == path);
        currentInList.opened = date;
        prev.sort((a, b) => b.openedNum - a.openedNum);
        return prev;
      });
    } catch (e) {
      print('Failed to update chapters!');
    }
  }
}
