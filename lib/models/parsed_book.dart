import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'book.dart';

import 'chapter.dart';

class ParsedBook {
  String title;
  String path;
  Map<String, Uint8List> imagesMap;
  Map<int, ChapterModel> offsetsMap;
  int currentChapter;
  String content;
  Uint8List preview;

  ParsedBook({
    @required this.title,
    @required this.path,
    @required this.imagesMap,
    @required this.offsetsMap,
    @required this.currentChapter,
    @required this.content,
    @required this.preview,
  });

  ParsedBook.fromBook(BookModel book, Map<String, Uint8List> images) {
    this.title = book.title;
    this.path = book.path;
    this.imagesMap = images;
    this.offsetsMap = book.chapters;
    this.currentChapter = book.currentChapter;
    this.content = book.content;
    this.preview = book.preview;
  }
}
