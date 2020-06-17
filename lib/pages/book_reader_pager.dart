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

  @override
  Widget build(BuildContext context) {
    final max = sections.length - 1;

    return Scaffold(
      appBar: AppBar(title: const Text('TextPainter')),
      body: PageView.builder(
        controller: _pageCtr,
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        itemBuilder: (ctx, index) => Chapter(
          sections[index],
          index,
          max,
          _pageCtr,
        ),
      ),
    );
  }
}

class Chapter extends StatefulWidget {
  final xml.XmlNode section;
  final int index;
  final int max;
  final PageController pageCtr;

  const Chapter(
    this.section,
    this.index,
    this.max,
    this.pageCtr, {
    Key key,
  }) : super(key: key);

  @override
  _ChapterState createState() => _ChapterState();
}

class _ChapterState extends State<Chapter> {
  PageController _pageCtr;

  int currentPage = 0;
  int maxPages = 0;

  @override
  void initState() {
    super.initState();

    _pageCtr = PageController(initialPage: 0)
      ..addListener(() => currentPage = _pageCtr.page.toInt());
  }

  void getMaxPages(int _maxPages) {
    if (maxPages != _maxPages) {
      setState(() => maxPages = _maxPages);
    }
  }

  @override
  Widget build(BuildContext context) {
    MyPainter(getMaxPages, widget.section.innerText).paint(
      Canvas(ui.PictureRecorder()),
      Size(
        ui.window.physicalSize.width / ui.window.devicePixelRatio,
        ui.window.physicalSize.height / ui.window.devicePixelRatio - 105,
      ),
    );

    print('MaxPages: $maxPages');

    return NotificationListener<ScrollNotification>(
      onNotification: (not) {
        if (not.metrics.pixels + 100 < not.metrics.minScrollExtent) {
          if (widget.index > 0) {
            widget.pageCtr.jumpToPage(widget.index - 1);
          }
        }

        if (not.metrics.pixels - 100 > not.metrics.maxScrollExtent) {
          if (widget.index < widget.max) {
            widget.pageCtr.jumpToPage(widget.index + 1);
          }
        }

        return true;
      },
      child: PageView.builder(
        controller: _pageCtr,
        scrollDirection: Axis.horizontal,
        itemCount: maxPages,
        physics: BouncingScrollPhysics(),
        itemBuilder: (ctx, index) => Container(
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: MyPainterChapter(widget.section.innerText, index),
          ),
        ),
      ),
    );
  }
}

final TextStyle style = TextStyle(
  color: Colors.black,
  fontSize: 16,
  height: 1.5,
);

class MyPainter extends CustomPainter {
  final void Function(int) getMaxPages;
  final String text;

  MyPainter(this.getMaxPages, this.text);

  @override
  void paint(canvas, size) {
    final maxLines = size.height ~/ (style.height * style.fontSize);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 12.0 - 12.0);

    print('TextPainter height: ${textPainter.height}');
    print('Screen size ${maxLines * style.height * style.fontSize}');
    print('Screen size raw ${size.height}');

    final maxPages = (textPainter.height / (maxLines * style.height * style.fontSize)).ceil();

    // print('----');
    // print('TextPainter');
    // print('MaxLines: $maxLines');
    // print('didExceedMaxLines ${textPainter.height}');
    // print(textPainter.getPositionForOffset(Offset(size.width, size.height)));
    getMaxPages(maxPages);
    // print('----');
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class MyPainterChapter extends CustomPainter {
  final String text;
  final int index;

  MyPainterChapter(this.text, this.index);

  @override
  void paint(canvas, size) {
    canvas.drawRect(Offset(0, 0) & Size.fromWidth(size.width), Paint()..color = Colors.white);

    final TextStyle style = TextStyle(
      color: Colors.black,
      fontSize: 16,
      height: 1.5,
    );

    final maxLines = (size.height / (style.height * style.fontSize)).floor();

    // print('${size.height} ${(style.height * style.fontSize)} $maxLines');

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 12.0 - 12.0);

    // print(maxLines * style.height * style.fontSize);

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, maxLines * style.height * style.fontSize));

    textPainter.paint(canvas, Offset(12.0, -index * maxLines * style.height * style.fontSize));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
