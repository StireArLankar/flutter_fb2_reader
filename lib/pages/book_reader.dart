import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter_fb2_reader/pages/book_drawer.dart';
import 'package:flutter_observable_state/flutter_observable_state.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/style.dart';

import '../store/app_state.dart';
import '../store/services.dart';
import 'book_options.dart';

class BookReader extends StatefulWidget {
  static const String pathName = 'book_reader';

  @override
  _BookReaderState createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  final _state = getIt.get<AppState>();
  final _pageCtr = PageController();

  String title;
  Map<String, Uint8List> imagesMap;
  Uint8List preview;
  Map<int, int> offsetsMap;
  List<xml.XmlNode> sections;
  List<String> titles;

  @override
  void initState() {
    super.initState();
    final book = _state.openedBook.get();

    title = book.title;
    imagesMap = book.imagesMap;
    preview = book.preview;
    offsetsMap = book.offsetsMap;

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
    return Scaffold(
      body: buildReader(),
      drawer: BookDrawer(preview, titles, onTitleClick, title),
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => _showMyDialog(ctx),
            ),
          ),
        ],
      ),
    );
  }

  void setOffset(int chapter, int offset) {
    offsetsMap[chapter] = offset;
  }

  Widget buildReader() {
    final max = sections.length - 1;

    return PageView.builder(
      controller: _pageCtr,
      scrollDirection: Axis.vertical,
      itemCount: sections.length,
      itemBuilder: (_, i) => Chapter(
        sections[i],
        titles[i],
        i,
        max,
        _pageCtr,
        setOffset,
        offsetsMap,
        imagesMap,
      ),
    );
  }

  Future<void> _showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BookOptions(val: _state.fontSize.get()),
    );
  }
}

class Chapter extends StatefulWidget {
  final xml.XmlNode section;
  final String title;
  final int index;
  final int max;
  final PageController pageCtr;
  final void Function(int, int) setOffset;
  final Map<int, int> offsetsMap;
  final Map<String, Uint8List> imagesMap;

  Chapter(
    this.section,
    this.title,
    this.index,
    this.max,
    this.pageCtr,
    this.setOffset,
    this.offsetsMap,
    this.imagesMap, {
    Key key,
  }) : super(key: key);

  @override
  _ChapterState createState() => _ChapterState();
}

class _ChapterState extends State<Chapter> {
  final _state = getIt.get<AppState>();

  final _itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();
  final temp = StreamController<int>();
  int length = 0;

  @override
  void initState() {
    super.initState();
    itemPositionsListener.itemPositions.addListener(() {
      final values = itemPositionsListener.itemPositions.value.map((el) => el.index).toList();
      // TODO send leading edge position
      // print('---');
      // print(itemPositionsListener.itemPositions.value.last);
      // print('---');

      if (values.indexOf(0) > -1) {
        return temp.add(0);
      }

      if (length > 0 && values.indexOf(length - 1) > -1) {
        return temp.add(length - 1);
      }

      values.sort();

      int tmp = 0;

      for (var val in values) {
        tmp += val;
      }

      tmp = Math.min((tmp / length).round(), values.length - 1);

      temp.add(values[tmp]);
    });
  }

  @override
  void dispose() {
    super.dispose();
    temp.close();

    final values = itemPositionsListener.itemPositions.value;
    final list = values.map((el) => el.index).toList();

    if (list.indexOf(0) > -1) {
      return widget.setOffset(widget.index, 0);
    }

    if (length > 0 && list.indexOf(length - 1) > -1) {
      return widget.setOffset(widget.index, length - 1);
    }

    final val = values.fold<int>(
      length,
      (previousValue, element) => element.index < previousValue ? element.index : previousValue,
    );

    widget.setOffset(widget.index, val);
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.section.children
        .where((child) {
          if (child.nodeType == xml.XmlNodeType.ELEMENT) {
            final name = (child as xml.XmlElement).name;

            if (name.toString() == 'img') {
              return true;
            } else {
              return child.text.trim().length > 0;
            }
          }

          return true;
        })
        .map((child) => child.toXmlString().trim())
        .where((element) => element.length > 0)
        .toList();

    int offset = 0;
    length = children.length;

    try {
      offset = widget.offsetsMap[widget.index] ?? 0;
    } catch (e) {}

    print('Length: $length, Offset: $offset, ${offset == length - 1}');

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
            child: ScrollablePositionedList.builder(
              itemBuilder: (ctx, i) => buildHtml(children[i]),
              itemCount: children.length,
              itemScrollController: _itemScrollController,
              itemPositionsListener: itemPositionsListener,
              initialScrollIndex: offset,
              initialAlignment: offset == length - 1 ? 0.9 : 0,
              physics: BouncingScrollPhysics(),
            ),
          ),
        ),
      ],
    );
  }

  Container buildHeader(String title, int index, int max) {
    return Container(
      height: 50.0,
      color: Colors.blueGrey[100],
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.centerLeft,
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
          StreamBuilder<int>(
            stream: temp.stream,
            builder: (ctx, snap) {
              if (snap.hasData) {
                final num = length > 1 ? snap.data / (length - 1) : 1;
                return Text(num.toStringAsFixed(3));
              }

              return Text('0');
            },
          ),
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.arrow_upward),
                onPressed: index > 0 ? () => widget.pageCtr.jumpToPage(index - 1) : null,
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward),
                onPressed: index < max ? () => widget.pageCtr.jumpToPage(index + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildHtml(String data) {
    return observe(() {
      return Html(
        data: data,
        style: {
          "body ": Style(
            margin: const EdgeInsets.all(0),
            padding: const EdgeInsets.all(0),
          ),
          "img": Style(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          "p": Style(
            padding: const EdgeInsets.all(0),
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            textAlign: TextAlign.justify,
            fontSize: FontSize(_state.fontSize.get()),
            whiteSpace: WhiteSpace.PRE,
          ),
          'i': Style(textAlign: TextAlign.center),
          'strong': Style(textAlign: TextAlign.center),
          "emphasis": Style(fontStyle: FontStyle.italic)
        },
        customRender: {
          "emphasis": (context, child, _, __) {
            return ContainerSpan(newContext: context, child: child);
          },
          'img': (context, child, attributes, __) {
            final key = attributes['l:href'];
            try {
              if (widget.imagesMap[key] == null) throw Error();
              return Image.memory(widget.imagesMap[key]);
            } catch (e) {
              return Image.asset('assets/placeholder.png');
            }
          }
        },
      );
    });
  }
}
