import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'app_state.dart';
import 'services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';

class ParsedBook {
  final String path;
  final String filename;
  final String description;
  final String content;
  final Uint8List cover;

  ParsedBook(this.path, this.filename, this.description, this.content, this.cover);
  // path TEXT PRIMARY KEY, filename TEXT, description TEXT, content TEXT, cover BLOB
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

class ActionS {
  final _state = getIt.get<AppState>();

  Future<void> setFontSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setDouble('fontSize', size);
      _state.fontSize.change((_) => size);
    } catch (e) {}
  }

  void setOpenedDescription(String path) async {
    final res = await _parseBookDescription(path);

    _state.openedDescription.change((_) => res);
  }

  void clearOpenedDescription() {
    _state.openedDescription.change((_) => null);
  }
}
