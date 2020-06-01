import 'package:flutter/material.dart' hide RefreshIndicator;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:xml/xml.dart' as xml;
import 'package:pull_to_refresh/pull_to_refresh.dart';

class FB2ReaderScreenV4 extends StatelessWidget {
  static const String pathName = 'fb2-reader-v4';

  final xml.XmlDocument document;

  const FB2ReaderScreenV4(this.document, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FB2Reader(document),
      ),
      appBar: AppBar(title: const Text('FB2 reader')),
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

  @override
  Widget build(BuildContext context) {
    final sections = widget.document.findAllElements('section').toList();
    final max = sections.length - 1;

    return RefreshConfiguration(
      enableBallisticLoad: false,
      child: PageView.builder(
        controller: _pageCtr,
        scrollDirection: Axis.vertical,
        itemBuilder: (_, i) => Chapter(
          sections[i],
          i,
          max,
          _pageCtr,
        ),
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

  Chapter(this.section, this.index, this.max, this.pageCtr, {Key key}) : super(key: key);
  @override
  _ChapterState createState() => _ChapterState();
}

class _ChapterState extends State<Chapter> {
  final _itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();

  @override
  Widget build(BuildContext context) {
    final title = widget.section.findElements('title').first.text.trim();

    final p = widget.section
        .findElements('p')
        .map((item) => item.text)
        .where((item) => item.trim().length > 0)
        .toList();

    return Column(
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
              itemBuilder: (ctx, i) => buildText(p[i]),
              itemCount: p.length,
              itemScrollController: _itemScrollController,
              itemPositionsListener: itemPositionsListener,
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
          if (index > 0)
            IconButton(
              icon: Icon(Icons.arrow_upward),
              onPressed: () => widget.pageCtr.jumpToPage(index - 1),
            ),
          if (index < max)
            IconButton(
              icon: Icon(Icons.arrow_downward),
              onPressed: () => widget.pageCtr.jumpToPage(index + 1),
            ),
        ],
      ),
    );
  }

  Widget buildText(String item) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        child: Text('\t\t\t$item', textAlign: TextAlign.justify),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
