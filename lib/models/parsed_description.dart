import 'dart:typed_data';

import 'package:flutter_fb2_reader/models/book.dart';

class ParsedDescription {
  final String path;
  final String description;
  final Uint8List cover;

  ParsedDescription(this.path, this.description, this.cover);

  factory ParsedDescription.fromBook(BookModel book) {
    return ParsedDescription(book.path, book.description, book.cover);
  }
}
