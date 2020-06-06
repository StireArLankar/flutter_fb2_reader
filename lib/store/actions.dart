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

    // TODO Compress
    // static double dblScreenHeight = window.physicalSize.height / window.devicePixelRatio;
    // static double dblScreenWidth = window.physicalSize.width / window.devicePixelRatio;

    cover = base64Decode(binary.text.trim());
  } catch (e) {}

  return Future.value(ParsedDescription(path, desc.toXmlString(), cover));
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

  try {
    final binaries = document.findAllElements('binary').toList().asMap();

    binaries.forEach((index, element) {
      final elementId = element.getAttribute('id') ?? index.toString();
      final id = '#' + elementId;

      try {
        imagesMap[id] = base64Decode(element.text.trim());
      } catch (e) {}
    });
  } catch (e) {}

  final coverpage = desc.findAllElements('coverpage').first;
  final coverId = coverpage.getElement('image').getAttribute('l:href');
  final cover = imagesMap[coverId];

  final Map<int, int> offsetsMap = {};

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

  return Future.value(ParsedBook(title, path, imagesMap, offsetsMap, finalBody, cover));
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

  void setOpenedBook(String path) async {
    final res = await _parseBook(path);

    _state.openedBook.change((_) => res);
  }

  void clearOpenedBook() {
    _state.openedBook.change((_) => null);
  }
}
