import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fb2_reader/store/actions/get_images.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tuple/tuple.dart';
import 'package:xml/xml.dart' as xml;

import '../models/chapter.dart';
import '../models/parsed_book.dart';
import '../models/parsed_description.dart';
import '../models/book.dart';
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
  } catch (e) {}

  return Future.value(null);
}

Future<ParsedDescription> _parseBookDescription(String path) async {
  if (path.split('/').last == 'zip') {
    path = await _prepareZip(path);
  }

  final file = File(path);
  final contents = await file.readAsString();
  final document = xml.XmlDocument.parse(contents);

  final desc = document.findAllElements('description').first;

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

  return Future.value(ParsedDescription(path, desc.toXmlString(), cover));
}

Future<Uint8List> compressImage(Uint8List list, int maxSize) async {
  final img = await decodeImageFromList(list);

  print('Size - $maxSize, Preview width - ${img.width}, Preview height - ${img.height}');

  final minSize = Math.min(img.width, maxSize);

  if (img.width > minSize) {
    list = await instantiateImageCodec(
      list,
      targetWidth: minSize,
    )
        .then((c) => c.getNextFrame())
        .then((f) => f.image.toByteData(format: ImageByteFormat.png))
        .then((v) => v.buffer.asUint8List());
  }

  final imgResized = await decodeImageFromList(list);

  print('Resized - Preview width - ${imgResized.width}, Preview height - ${imgResized.height}');

  final result = await FlutterImageCompress.compressWithList(list, quality: 70);

  print('InitialLength: ${list.length}, CompressedLength: ${result.length}');
  print('---');

  return Uint8List.fromList(result);
}

Future<ParsedBook> _parseBook(String path) async {
  if (path.split('/').last == 'zip') {
    path = await _prepareZip(path);
  }

  final file = File(path);
  final contents = await file.readAsString();
  final document = xml.XmlDocument.parse(contents);

  final desc = document.findAllElements('description').first;
  final title = desc.getElement('title-info').getElement('book-title').text;

  final Map<String, Uint8List> imagesMap = {};

  final pixelWidth = (window.physicalSize.width / window.devicePixelRatio).round();
  final pixelHeight = (window.physicalSize.height / window.devicePixelRatio).round();
  final maxSize = Math.max(pixelWidth, pixelHeight);

  try {
    final binaries = document.findAllElements('binary');
    var temp = 0;

    await Future.forEach(binaries, (element) async {
      temp++;
      final elementId = element.getAttribute('id') ?? temp.toString();
      final id = '#' + elementId;

      try {
        final decoded = base64Decode(element.text.trim());
        final img = await compressImage(decoded, maxSize);

        imagesMap[id] = img;
        return;
      } catch (e) {}
    });
  } catch (e) {}

  final coverpage = desc.findAllElements('coverpage').first;
  final coverId = coverpage.getElement('image').getAttribute('l:href');

  print('Preview compressing');
  final preview = await compressImage(imagesMap[coverId], 200);

  final Map<int, ChapterModel> offsetsMap = {};

  final finalBody = '<body>' +
      document.findAllElements('body').map((body) {
        // TODO asd
        // final sections = body.findElements('section');
        // final childrenLength = body.children.length;

        // if (sections.length != childrenLength) {
        //   body.children.forEach((child) {
        //     if (true) {
        //       return child.;
        //     }
        //   });
        // }

        return body.innerXml.replaceAll('<image', '<img').replaceAll(RegExp(r">\s+<"), '><').trim();
      }).join('') +
      '</body>';

  return Future.value(ParsedBook(title, path, imagesMap, offsetsMap, finalBody, preview));
}

Future<void> addToDB(
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

Future<Tuple2<BookModel, Map<String, Uint8List>>> readFromDB(
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
    final res = await _parseBookDescription(path);

    return _state.openedDescription.change((_) => res);
  }

  void clearOpenedDescription() {
    _state.openedDescription.change((_) => null);
  }

  Future<void> setOpenedBook(String path) async {
    final res = await _parseBook(path);

    return _state.openedBook.change((_) => res);
  }

  void clearOpenedBook() {
    _state.openedBook.change((_) => null);
  }

  Future<void> addToDBAndOpen(String path) async {
    final res1 = await _prepareBook(path);
    await addToDB(path, res1, _state.db);
    final res = await readFromDB(path, _state.db);

    final book = res.item1;
    final imagesMap = res.item2;

    final parsedBook = ParsedBook.fromBook(book, imagesMap);

    _state.booksList.change((prev) {
      prev.add(parsedBook);
      return prev;
    });

    return _state.openedBook.change((_) => parsedBook);
  }
}
