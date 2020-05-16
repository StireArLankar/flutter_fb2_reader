class Config {
  String key1;
  String key2;

  Config({this.key1, this.key2});

  Config.fromJson(Map<String, dynamic> json) {
    key1 = json['key1'];
    key2 = json['key2'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['key1'] = this.key1;
    data['key2'] = this.key2;
    return data;
  }
}
