import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert';
import 'dart:math' as Math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide RefreshIndicator;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:xml/xml.dart' as xml;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/style.dart';

import 'store/counter.dart';

class FB2ReaderScreenV6 extends StatelessWidget {
  static const String pathName = 'fb2-reader-v6';

  final xml.XmlDocument document;

  const FB2ReaderScreenV6(this.document, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FB2Reader(document),
      ),
      appBar: AppBar(
        title: const Text('FB2 reader V6'),
        actions: <Widget>[
          Builder(
            builder: (ctx) {
              return IconButton(
                icon: Icon(Icons.network_cell),
                onPressed: () {
                  _showMyDialog(ctx);
                },
              );
            },
          )
        ],
      ),
    );
  }

  Future<void> _showMyDialog(context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (ctx) => Dia(
        val: Provider.of<Counter>(context, listen: false).fontSize,
      ),
    );
  }
}

class Dia extends StatefulWidget {
  const Dia({Key key, this.val}) : super(key: key);

  final val;

  @override
  _DiaState createState() => _DiaState();
}

class _DiaState extends State<Dia> {
  double value = 15;

  @override
  void initState() {
    super.initState();
    print(widget.val);
    setState(() {
      value = widget.val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Font Size'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: 50),
              child: Slider(
                value: value,
                onChanged: (newVal) {
                  setState(() => value = newVal);
                },
                divisions: 10,
                label: '${value.toInt()}',
                min: 10,
                max: 20,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Approve'),
          onPressed: () {
            Provider.of<Counter>(context, listen: false)
                .setFontSize(value)
                .then((_) => Navigator.of(context).pop());
          },
        ),
      ],
    );
  }
}

class FB2Reader extends StatefulWidget {
  final xml.XmlDocument document;

  const FB2Reader(this.document, {Key key}) : super(key: key);

  @override
  _FB2ReaderState createState() => _FB2ReaderState();
}

class _FB2ReaderState extends State<FB2Reader> {
  final _pageCtr = PageController();
  final Map<int, int> offsetsMap = Map();
  final Map<String, Uint8List> imagesMap = Map();

  bool isReady = false;

  setOffset(int chapter, int offset) {
    offsetsMap[chapter] = offset;
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      print('Start: ${DateTime.now()}');
      final binaries = widget.document.findAllElements('binary').toList().asMap();

      binaries.forEach((index, element) {
        String id;
        try {
          id = element.attributes.firstWhere((element) => element.name.toString() == 'id').value;
        } catch (e) {
          id = index.toString();
        }

        imagesMap[id] = base64Decode(element.text);
      });

      print('End: ${DateTime.now()}');

      setState(() {
        isReady = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      final size = MediaQuery.of(context).size;
      final dimension = size.width > size.height ? size.height * 0.7 : size.width * 0.7;

      return Center(
        child: SizedBox(
          child: CircularProgressIndicator(strokeWidth: dimension / 10),
          height: dimension,
          width: dimension,
        ),
      );
    }

    final sections = widget.document.findAllElements('section').where((section) {
      return section.innerText.trim().length > 0;
    }).toList();

    final max = sections.length - 1;

    return RefreshConfiguration(
      enableBallisticLoad: false,
      child: PageView.builder(
        controller: _pageCtr,
        scrollDirection: Axis.vertical,
        itemBuilder: (_, i) =>
            Chapter(sections[i], i, max, _pageCtr, setOffset, offsetsMap, imagesMap),
      ),
    );
  }

  Widget buildLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: const CircularProgressIndicator(),
    );
  }
}

class Chapter extends StatefulWidget {
  final xml.XmlElement section;
  final int index;
  final int max;
  final PageController pageCtr;
  final void Function(int, int) setOffset;
  final Map<int, int> offsetsMap;
  final Map<String, Uint8List> imagesMap;

  Chapter(
    this.section,
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
  final _itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();
  final temp = StreamController<int>();
  int length = 0;

  @override
  void initState() {
    super.initState();
    itemPositionsListener.itemPositions.addListener(() {
      // print('---');
      // itemPositionsListener.itemPositions.value.forEach(print);
      // print('---');

      final values = itemPositionsListener.itemPositions.value.map((el) => el.index).toList();
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

    final val = itemPositionsListener.itemPositions.value.fold<int>(
      length,
      (previousValue, element) => element.index < previousValue ? element.index : previousValue,
    );

    widget.setOffset(widget.index, val);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.section.findElements('title').first.text.trim();

    final children = widget.section.children
        .where((child) {
          if (child.nodeType == xml.XmlNodeType.ELEMENT) {
            final name = (child as xml.XmlElement).name;

            if (name.toString() == 'img') {
              return true;
            } else if (child.toXmlString().contains('<title>')) {
              return false;
            } else {
              return child.text.trim().length > 0;
            }
          }

          return true;
        })
        .map((child) => child.toXmlString().trim().replaceAll(RegExp(r">\s+<"), '><'))
        .where((element) => element.length > 0)
        .toList();

    int offset = 0;
    length = children.length;
    print(length);

    try {
      offset = widget.offsetsMap[widget.index] ?? 0;
    } catch (e) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        buildHeader(title, widget.index, widget.max),
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
          Text(title),
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
    final store = Provider.of<Counter>(context, listen: false);

    return Observer(
      builder: (ctx) => Html(
        data: data,
        blacklistedElements: ["title"],
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
            fontSize: FontSize(store.fontSize),
            whiteSpace: WhiteSpace.PRE,
          ),
          'i': Style(textAlign: TextAlign.center),
          'strong': Style(textAlign: TextAlign.center),
          "emphasis": Style(fontStyle: FontStyle.italic)
        },
        customRender: {
          "emphasis": (context, child, _, __) {
            return ContainerSpan(
              newContext: context,
              child: child,
            );
          },
          'img': (context, child, attributes, __) {
            final key = attributes['id'];

            return Image.memory(widget.imagesMap[key]);
          }
        },
      ),
    );
  }
}
