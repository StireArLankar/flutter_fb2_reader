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
  @override
  Widget build(BuildContext context) {
    final sections = widget.document.findAllElements('section').toList();
    final max = sections.length - 1;

    return RefreshConfiguration(
      enableBallisticLoad: false,
      child: Chapter(sections[0], 0, max),
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

  Chapter(this.section, this.index, this.max, {Key key}) : super(key: key);

  @override
  _ChapterState createState() => _ChapterState();
}

class _ChapterState extends State<Chapter> {
  final _scrollController = ScrollController();
  final _itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();

  _scrollListener() {
    print(
      'Offset: ${_scrollController.offset}, max: ${_scrollController.position.maxScrollExtent}',
    );
  }

  @override
  void initState() {
    super.initState();
    // _scrollController.addListener(_scrollListener);
    // Future.microtask(() => print('Start: ${_scrollController.offset}'));
    itemPositionsListener.itemPositions.addListener(() {
      print('---');
      itemPositionsListener.itemPositions.value.forEach(print);
      print('---');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
          child: ScrollablePositionedList.builder(
            itemBuilder: (ctx, i) => buildText(p[i]),
            itemCount: p.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: itemPositionsListener,
          ),
          // child: ListView.builder(
          //   controller: _scrollController,
          //   itemBuilder: (ctx, i) => buildText(p[i]),
          //   itemCount: p.length,
          // ),
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
