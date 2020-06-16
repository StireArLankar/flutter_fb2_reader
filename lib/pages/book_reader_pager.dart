import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../store/app_state.dart';
import '../store/services.dart';
import 'dart:ui' as ui;
import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:ui';

import '../store/actions.dart';
import 'package:xml/xml.dart' as xml;

class BookReaderPager extends StatefulWidget {
  BookReaderPager({Key key}) : super(key: key);

  static const String pathName = 'book_reader_pager';

  @override
  _BookReaderPagerState createState() => _BookReaderPagerState();
}

class _BookReaderPagerState extends State<BookReaderPager> {
  final _state = getIt.get<AppState>();
  final _actions = getIt.get<ActionS>();
  PageController _pageCtr;

  String title;
  Map<String, Uint8List> imagesMap;
  Uint8List preview;
  Map<int, ChapterModel> offsetsMap;
  int currentChapter;
  List<xml.XmlNode> sections;
  List<String> titles;

  @override
  void dispose() {
    _actions.updateBookChapters(currentChapter);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final book = _state.openedBook.get();

    title = book.title;
    imagesMap = book.imagesMap;
    preview = book.preview;
    offsetsMap = book.offsetsMap;
    currentChapter = book.currentChapter;

    _pageCtr = PageController(initialPage: currentChapter)
      ..addListener(() => currentChapter = _pageCtr.page.toInt());

    final parsed = xml.XmlDocument.parse(book.content);

    sections = parsed.firstChild.children.where((child) {
      if (child.nodeType == xml.XmlNodeType.ELEMENT) {
        final name = (child as xml.XmlElement).name;
        if (name.toString() == 'title') {
          return false;
        }
      }

      return true;
    }).toList();

    titles = sections.map((section) {
      String title;

      try {
        title = section.findElements('title').first.text.trim();
        if (title == null || title.length == 0) throw Error();
      } catch (e) {
        title = section.text.substring(0, Math.min(40, section.text.length)) + '...';
      }

      return title;
    }).toList();
  }

  void onTitleClick(BuildContext ctx, int index) {
    _pageCtr.jumpToPage(index);
    Navigator.of(ctx).pop();
  }

  void getTotalHeight(double height) {
    print(height);
  }

  @override
  Widget build(BuildContext context) {
    MyPainter(getTotalHeight, sections[0].innerText).paint(
      Canvas(ui.PictureRecorder()),
      Size(
        ui.window.physicalSize.width / ui.window.devicePixelRatio,
        ui.window.physicalSize.height / ui.window.devicePixelRatio - 105,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('TextPainter')),
      body: PageView.builder(
        controller: _pageCtr,
        scrollDirection: Axis.horizontal,
        itemCount: 20,
        itemBuilder: (ctx, index) => Container(
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(painter: MyPainterChapter(sections[0].innerText, index)),
        ),
      ),
    );
  }
}

final TextStyle style = TextStyle(
  color: Colors.black,
  backgroundColor: Colors.blue[100],
  decorationStyle: TextDecorationStyle.dotted,
  decorationColor: Colors.green,
  decorationThickness: 0.25,
  fontSize: 15,
  height: 1.5,
);

class MyPainter extends CustomPainter {
  final void Function(double) getTotalHeight;
  final String text;

  MyPainter(this.getTotalHeight, this.text);

  @override
  void paint(canvas, size) {
    canvas.drawRect(Offset(0, 0) & Size.fromWidth(size.width), Paint()..color = Colors.red[100]);

    // Since text is overflowing, you have two options: cliping before drawing text or/and defining max lines.
    canvas.clipRect(Offset(0, 0) & size);

    final maxLines = ((size.height) / (style.height * style.fontSize)).floor();

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 12.0 - 12.0);

    print('----');
    print('TextPainter');
    print('MaxLines: $maxLines');
    print('didExceedMaxLines ${textPainter.height}');
    print(textPainter.getPositionForOffset(Offset(size.width, size.height)));
    getTotalHeight(textPainter.height);
    print('----');
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false; // Just for example, in real environment should be implemented!
  }
}

class MyPainterChapter extends CustomPainter {
  final String text;
  final int index;

  MyPainterChapter(this.text, this.index);

  @override
  void paint(canvas, size) {
    canvas.drawRect(Offset(0, 0) & Size.fromWidth(size.width), Paint()..color = Colors.red[100]);

    final TextStyle style = TextStyle(
      color: Colors.black,
      backgroundColor: Colors.blue[100],
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: Colors.green,
      decorationThickness: 0.25,
      fontSize: 15,
      height: 4,
    );

    final maxLines = ((size.height) / (style.height * style.fontSize)).floor();
    final maxLines2 = ((size.height) / (style.height * style.fontSize)).round();

    print('${size.height} ${(style.height * style.fontSize)} $maxLines');

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 12.0 - 12.0);

    // final tmp = style.height - 2; // 2
    // final tmp = style.height - 2.25; // 2.5
    // final tmp = style.height - 3; // 3
    final tmp = style.height - 3; // 4
    // final tmp = style.height - 3.63; // 3.5
    // final tmp = style.height - 0.8; // 1.8
    print(tmp);

    // canvas.clipRect(Rect.fromLTWH(0, 0, size.width, maxLines * style.height * style.fontSize));

    textPainter.paint(
        canvas, Offset(12.0, -index * (maxLines + tmp) * style.height * style.fontSize));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
