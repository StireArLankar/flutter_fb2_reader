import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:tuple/tuple.dart';
import 'package:xml/xml.dart' as xml;

/// Tuple of `preview`, `cover` and `imagesMap`
Future<Tuple3<Uint8List, Uint8List, Map<String, Uint8List>>> getImages(
  xml.XmlDocument document,
) async {
  try {
    final desc = document.findAllElements('description').first;

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

    // print('Preview compressing');
    final preview = await compressImage(imagesMap[coverId], 200);

    return Tuple3(preview, imagesMap[coverId], imagesMap);
  } catch (e) {
    print('Error in gathering images');
    return Tuple3(null, null, {});
  }
}

Future<Uint8List> compressImage(Uint8List list, int maxSize) async {
  final img = await decodeImageFromList(list);

  // print('Size - $maxSize, Preview width - ${img.width}, Preview height - ${img.height}');

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

  // final imgResized = await decodeImageFromList(list);

  // print('Resized - Preview width - ${imgResized.width}, Preview height - ${imgResized.height}');

  final result = await FlutterImageCompress.compressWithList(list, quality: 70);

  // print('InitialLength: ${list.length}, CompressedLength: ${result.length}');
  // print('---');

  return Uint8List.fromList(result);
}
