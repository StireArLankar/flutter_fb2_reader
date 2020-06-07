import 'dart:convert';
import 'dart:typed_data';

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
  String title;

  BookModel({
    this.path,
    this.filename,
    this.description,
    this.content,
    this.cover,
    this.preview,
    this.modified,
    this.opened,
    this.chapters,
    this.title,
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
    title = jsn['title'];

    try {
      Map<String, dynamic> newMap = Map<String, num>.from(json.decode(jsn['chapters']));

      newMap.forEach((key, value) {
        chapters[int.parse(key)] = ChapterModel.fromJson(value);
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

    data['title'] = this.title;

    return data;
  }
}
