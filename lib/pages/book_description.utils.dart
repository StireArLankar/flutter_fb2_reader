import 'package:xml/xml.dart' as xml;

class _Author {
  String firstName;
  String lastName;
}

class _Sequence {
  String name;
  int number;
}

class Info {
  List<String> genre = [];
  List<_Author> authors = [];
  String title;
  String annotation;
  String lang;
  _Sequence sequence;
}

Info getInfo(String desc) {
  final res = Info();

  final doc = xml.XmlDocument.parse(desc);

  final info = doc.findAllElements('title-info').first;

  try {
    info.findElements('genre').forEach((element) => res.genre.add(element.text));
  } catch (e) {}

  try {
    info.findElements('author').forEach((element) {
      final author = _Author();

      try {
        author.firstName = element.getElement('first-name').text;
      } catch (e) {}

      try {
        author.lastName = element.getElement('last-name').text;
      } catch (e) {}

      res.authors.add(author);
    });
  } catch (e) {}

  try {
    res.title = info.getElement('title').text;
  } catch (e) {}

  try {
    res.annotation = info.getElement('annotation').innerXml;
  } catch (e) {}

  try {
    res.lang = info.getElement('lang').text;
  } catch (e) {}

  try {
    final seq = _Sequence();
    final xmlSeq = info.getElement('sequence');
    xmlSeq.attributes.forEach((element) {
      switch (element.name.toString()) {
        case 'name':
          return seq.name = element.value;
        case 'number':
          return seq.number = int.parse(element.value);
        default:
          return null;
      }
    });
    res.sequence = seq;
  } catch (e) {}

  return res;
}
