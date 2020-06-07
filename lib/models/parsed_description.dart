import 'dart:typed_data';

import 'package:flutter_fb2_reader/models/book.dart';

class ParsedDescription {
  final String path;
  final String description;
  final Uint8List cover;
  final String title;
  final bool isInLibrary;

  ParsedDescription(
    this.path,
    this.description,
    this.cover,
    this.title,
    this.isInLibrary,
  );

  factory ParsedDescription.fromBook(BookModel book, bool isInLibrary) {
    return ParsedDescription(
      book.path,
      book.description,
      book.cover,
      book.title,
      isInLibrary,
    );
  }
}
