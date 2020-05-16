import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:xml/xml.dart' as xml;
import 'package:sticky_headers/sticky_headers.dart';

class FB2ReaderScreen extends StatelessWidget {
  static const String pathName = 'fb2-reader';

  final xml.XmlDocument document;

  const FB2ReaderScreen(this.document, {Key key}) : super(key: key);

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
  final _scrollController = ItemScrollController();

  @override
  Widget build(BuildContext context) {
    final sections = widget.document.findAllElements('section').toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ScrollablePositionedList.builder(
        itemScrollController: _scrollController,
        itemCount: sections.length,
        itemBuilder: ((ctx, index) {
          final section = sections[index];
          final title = section.findElements('title').first.text.trim();
          final p = section
              .findElements('p')
              .map((item) => item.text)
              .where((item) => item.trim().length > 0);
          final max = sections.length - 1;

          print('rebuild $index');

          return StickyHeader(
            header: buildHeader(title, index, max),
            content: Column(children: p.map(buildText).toList()),
          );
        }),
      ),
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
              onPressed: () => _scrollController.jumpTo(
                index: index - 1,
              ),
            ),
          if (index < max)
            IconButton(
              icon: Icon(Icons.arrow_downward),
              onPressed: () => _scrollController.jumpTo(
                index: index + 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildText(String item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        child: Text('\t\t\t$item', textAlign: TextAlign.justify),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
