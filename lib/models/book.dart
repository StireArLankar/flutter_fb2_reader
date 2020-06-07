import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'chapter.dart';

class BookModel {
  String path;
  String filename;
  String description;
  String content;
  Uint8List cover;
  Uint8List preview;
  String modified;
  String opened;
  Map<int, ChapterModel> chapters;
  int currentChapter;
  String title;

  BookModel({
    @required this.path,
    @required this.filename,
    @required this.description,
    @required this.content,
    @required this.cover,
    @required this.preview,
    @required this.modified,
    @required this.opened,
    @required this.chapters,
    @required this.currentChapter,
    @required this.title,
  });

  BookModel.fromJson(Map<String, dynamic> jsn) {
    path = jsn['path'];
    filename = jsn['filename'];
    description = jsn['description'];
    content = jsn['content'];
    cover = jsn['cover'];
    preview = jsn['preview'];
    modified = jsn['modified'];
    opened = jsn['opened'];
    chapters = {};
    currentChapter = jsn['currentChapter'];
    title = jsn['title'];

    try {
      final temp = json.decode(jsn['chapters']);

      temp.forEach((key, value) {
        chapters[int.parse(key)] = ChapterModel.fromJson(json.decode(value));
      });

      print('Decoding chapters: $chapters');
    } catch (e) {
      print('Decoding chapters error');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['path'] = this.path;
    data['filename'] = this.filename;
    data['description'] = this.description;
    data['content'] = this.content;
    data['cover'] = this.cover;
    data['preview'] = this.preview;
    data['modified'] = this.modified;
    data['opened'] = this.opened;

    final temp = this.chapters.map<int, String>((key, value) {
      return MapEntry(key, json.encode(value.toJson()));
    });
    data['chapters'] = json.encode(temp);
    print('Encoding chapters: ${data['chapters']}');

    data['currentChapter'] = this.currentChapter;
    data['title'] = this.title;

    return data;
  }
}
