import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'book.dart';

class ParsedPreview {
  final String title;
  final String path;
  final String description;
  final Uint8List preview;
  String opened;

  int get openedNum => DateTime.parse(opened).millisecondsSinceEpoch;

  ParsedPreview({
    @required this.title,
    @required this.path,
    @required this.description,
    @required this.preview,
    @required this.opened,
  });

  factory ParsedPreview.fromBook(BookModel book) {
    return ParsedPreview(
      title: book.title,
      path: book.path,
      description: book.description,
      preview: book.preview,
      opened: book.opened,
    );
  }

  factory ParsedPreview.fromJson(Map<String, dynamic> jsn) {
    return ParsedPreview(
      title: jsn['title'],
      path: jsn['path'],
      description: jsn['description'],
      preview: jsn['preview'],
      opened: jsn['opened'],
    );
  }
}
