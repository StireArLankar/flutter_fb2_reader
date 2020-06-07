import 'dart:typed_data';

import 'book.dart';

import 'chapter.dart';

class ParsedBook {
  String title;
  String path;
  Map<String, Uint8List> imagesMap;
  Map<int, ChapterModel> offsetsMap;
  String content;
  Uint8List preview;

  ParsedBook(
    this.title,
    this.path,
    this.imagesMap,
    this.offsetsMap,
    this.content,
    this.preview,
  );

  ParsedBook.fromBook(BookModel book, Map<String, Uint8List> images) {
    this.title = book.title;
    this.path = book.path;
    this.imagesMap = images;
    this.offsetsMap = book.chapters;
    this.content = book.content;
    this.preview = book.preview;
  }
}
