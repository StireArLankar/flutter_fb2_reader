import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
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
        itemBuilder: (ctx, i) => Chapter(
          sections[i],
          titles[i],
          i,
          max,
          _pageCtr,
          offsetsMap,
          imagesMap,
        ),
      ),
    );
  }
}

class Chapter extends StatefulWidget {
  final xml.XmlNode section;
  final String title;
  final int index;
  final int max;
  final PageController pageCtr;
  final Map<int, ChapterModel> offsetsMap;
  final Map<String, Uint8List> imagesMap;

  Chapter(
    this.section,
    this.title,
    this.index,
    this.max,
    this.pageCtr,
    this.offsetsMap,
    this.imagesMap, {
    Key key,
  }) : super(key: key);

  @override
  _ChapterState createState() => _ChapterState();
}

class _ChapterState extends State<Chapter> {
  PageController _pageCtr;

  int currentPage = 0;
  int maxPages = 0;

  List<Tuple2<int, String>> imagesPositions = [];
  TextPainter painter;

  @override
  void initState() {
    super.initState();

    _pageCtr = PageController(initialPage: 0)
      ..addListener(() => currentPage = _pageCtr.page.toInt());
  }

  void calculateChapter(
    int _maxPages,
    List<Tuple2<int, String>> _imagesPositions,
    TextPainter _painter,
  ) {
    if (maxPages != _maxPages) {
      Future.microtask(() {
        setState(() {
          maxPages = _maxPages;
          imagesPositions = _imagesPositions;
          painter = _painter;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, cons) {
      MyPainter(calculateChapter, widget.section).paint(
        Canvas(ui.PictureRecorder()),
        Size(cons.maxWidth, cons.maxHeight - 50),
      );

      if (maxPages == 0) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            buildHeader(widget.title, widget.index, widget.max),
            Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      }

      print('MaxPages: $maxPages');
      print(imagesPositions);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          buildHeader(widget.title, widget.index, widget.max),
          Expanded(
            child: NotificationListener<ScrollNotification>(
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
                itemCount: maxPages + imagesPositions.length,
                // physics: BouncingScrollPhysics(),
                physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemBuilder: (ctx, index) {
                  final prevImageIndex =
                      imagesPositions.lastIndexWhere((element) => element.item1 <= index);

                  if (prevImageIndex > -1 && imagesPositions[prevImageIndex].item1 == index) {
                    final key = imagesPositions[prevImageIndex].item2;

                    Widget child;
                    try {
                      if (widget.imagesMap[key] == null) throw Error();
                      child = Image.memory(widget.imagesMap[key]);
                    } catch (e) {
                      child = Image.asset('assets/placeholder.png');
                    }

                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: child,
                    );
                  }

                  final offset = prevImageIndex > -1 ? prevImageIndex + 1 : 0;

                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: CustomPaint(
                      painter: MyPainterChapter(widget.section, index - offset, painter),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Container buildHeader(String title, int index, int max) {
    return Container(
      height: 50.0,
      color: Colors.blueGrey[100],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5, left: 16.0, right: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(
              child: FittedBox(
                child: Text(title),
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
              ),
              width: MediaQuery.of(context).size.width / 2,
            ),
            AnimatedBuilder(
              animation: _pageCtr,
              builder: (context, _) {
                var max = maxPages + imagesPositions.length;

                if (max == 0) {
                  max++;
                }

                if (!_pageCtr.hasClients) {
                  return Text('1 / $max');
                }

                final temp = (_pageCtr.page + 1).round();

                return Text('$temp / $max');
              },
            ),
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: index > 0 ? () => widget.pageCtr.jumpToPage(index - 1) : null,
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: index < max ? () => widget.pageCtr.jumpToPage(index + 1) : null,
                ),
              ],
            ),
          ],
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

TextSpan parse(xml.XmlNode node) {
  if (node.nodeType == xml.XmlNodeType.TEXT) {
    final text = node.toString();
    return TextSpan(text: text);
  }

  if (node.nodeType == xml.XmlNodeType.ELEMENT) {
    final name = (node as xml.XmlElement).name.toString();
    final inner = node.innerText;

    if (inner.length == 0) {
      return null;
    }

    switch (name) {
      case 'img':
        return null;
      case 'strong':
        return TextSpan(
          children: node.children.map(parse).toList(),
          style: TextStyle(fontWeight: FontWeight.bold),
        );
      case 'emphasis':
        return TextSpan(
          children: node.children.map(parse).toList(),
          style: TextStyle(fontStyle: FontStyle.italic),
        );
      default:
        return TextSpan(children: node.children.map(parse).toList());
    }
  }

  return null;
}

PlaceholderDimensions genPlaceholder(_) {
  return PlaceholderDimensions(
    size: Size(20, 1),
    alignment: PlaceholderAlignment.baseline,
  );
}

class MyPainter extends CustomPainter {
  final void Function(int, List<Tuple2<int, String>>, TextPainter) calculateChapter;
  final xml.XmlNode document;

  MyPainter(this.calculateChapter, this.document);

  @override
  void paint(canvas, size) {
    final maxLines = size.height ~/ (style.height * style.fontSize);
    final screenSize = maxLines * style.height * style.fontSize;

    final List<TextSpan> children = [];
    final List<Tuple2<int, String>> imagesPositions = [];
    var offset = 0;

    for (var i = 0; i < document.children.length; i++) {
      final child = document.children[i];

      final imgsHrefs = child.descendants.fold<List<String>>([], (arr, element) {
        // if (element.nodeType == xml.XmlNodeType.ELEMENT) {
        // final name = (element as xml.XmlElement).name.toString();
        if (element is xml.XmlAttribute) {
          final name = element.name.toString();
          final parentName = element.parentElement.name.toString();

          print('Parent name: $parentName, name: $name');

          if (parentName == 'img' && name == 'l:href') {
            arr.add(element.value);
          }
        }

        return arr;
      });

      if (imgsHrefs.length > 0) {
        final textPainter = TextPainter(
          text: TextSpan(style: style, children: children),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.ltr,
        );

        textPainter.setPlaceholderDimensions(
          children.map(genPlaceholder).toList(),
        );

        textPainter.layout(maxWidth: size.width - 12.0 - 12.0);

        final height = textPainter.height;

        imgsHrefs.forEach((element) {
          final pos = (height / screenSize).round();
          imagesPositions.add(Tuple2(offset + pos, element));
          offset++;
        });
      }

      final parsed = parse(child);

      if (parsed != null) {
        children.add(TextSpan(
          children: [
            WidgetSpan(child: Container()),
            parsed,
            if (i < document.children.length - 1) TextSpan(text: '\n'),
          ],
        ));
      }
    }

    final textPainter = TextPainter(
      text: TextSpan(style: style, children: children),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.ltr,
    );

    textPainter.setPlaceholderDimensions(
      children.map(genPlaceholder).toList(),
    );

    textPainter.layout(maxWidth: size.width - 12.0 - 12.0);

    print('TextPainter height: ${textPainter.height}');
    print('Screen size ${maxLines * style.height * style.fontSize}');
    print('Screen size raw ${size.height}');

    final maxPages = (textPainter.height / (maxLines * style.height * style.fontSize)).ceil();

    calculateChapter(maxPages, imagesPositions, textPainter);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class MyPainterChapter extends CustomPainter {
  final xml.XmlNode document;
  final int index;
  final TextPainter textPainter;

  MyPainterChapter(this.document, this.index, this.textPainter);

  @override
  void paint(canvas, size) {
    canvas.drawRect(Offset(0, 0) & Size.fromWidth(size.width), Paint()..color = Colors.white);

    final maxLines = (size.height / (style.height * style.fontSize)).floor();

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, maxLines * style.height * style.fontSize));

    print('Cycle height: ${size.height}');

    if (textPainter != null) {
      textPainter.paint(canvas, Offset(12.0, -index * maxLines * style.height * style.fontSize));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
