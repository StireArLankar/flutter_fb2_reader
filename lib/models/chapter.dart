import 'dart:convert';

class ChapterModel {
  double progress;
  int leadingIndex;
  double leadingOffset;

  ChapterModel({this.progress, this.leadingIndex, this.leadingOffset});

  ChapterModel.fromJson(Map<String, dynamic> json) {
    progress = json['progress'];
    leadingIndex = json['leadingIndex'];
    leadingOffset = json['leadingOffset'];
  }

  String toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['progress'] = this.progress;
    data['leadingIndex'] = this.leadingIndex;
    data['leadingOffset'] = this.leadingOffset;
    return json.encode(data);
  }
}
