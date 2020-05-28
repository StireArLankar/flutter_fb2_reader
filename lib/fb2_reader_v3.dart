import 'dart:async';

import 'package:flutter/material.dart' hide RefreshIndicator;
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'store/counter.dart';

class FB2ReaderScreenV3 extends StatelessWidget {
  static const String pathName = 'fb2-reader-v3';

  final xml.XmlDocument document;

  const FB2ReaderScreenV3(this.document, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: FB2Reader(document)),
      appBar: AppBar(
        title: const Text('FB2 reader V3'),
        actions: <Widget>[
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.network_cell),
              onPressed: () => _showMyDialog(ctx),
            ),
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
    setState(() => value = widget.val);
  }

  void onSliderChange(double newVal) => setState(() => value = newVal);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('AlertDialog Title'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Hello World'),
            Container(
              child: Slider(
                value: value,
                onChanged: onSliderChange,
                divisions: 10,
                label: '$value',
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
            Provider.of<Counter>(context, listen: false).setFontSize(value);
            Navigator.of(context).pop();
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
  final Map<int, double> offsetsMap = Map();

  setOffset(int chapter, double offset) {
    offsetsMap[chapter] = offset;
  }

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
          setOffset,
          offsetsMap,
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
  final void Function(int, double) setOffset;
  final Map<int, double> offsetsMap;

  Chapter(
    this.section,
    this.index,
    this.max,
    this.pageCtr,
    this.setOffset,
    this.offsetsMap, {
    Key key,
  }) : super(key: key);

  @override
  _ChapterState createState() => _ChapterState();
}

class _ChapterState extends State<Chapter> {
  final _refreshController = RefreshController();
  ScrollController _scrollController;

  _onRefresh() {
    widget.pageCtr.previousPage(
      duration: Duration(milliseconds: 1000),
      curve: Curves.ease,
    );
    _refreshController.refreshCompleted();
  }

  _onLoading() {
    widget.pageCtr.nextPage(
      duration: Duration(milliseconds: 1000),
      curve: Curves.ease,
    );
    _refreshController.loadComplete();
  }

  @override
  void initState() {
    super.initState();
    final offset = widget.offsetsMap[widget.index] ?? 0.0;
    print('Offset of ${widget.index}: $offset');
    _scrollController = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    final offset = _refreshController.position.pixels;
    widget.setOffset(widget.index, offset);
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        buildHeader(title, widget.index, widget.max),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: SmartRefresher(
              controller: _refreshController,
              header: ClassicHeader(),
              footer: ClassicFooter(
                loadStyle: LoadStyle.HideAlways,
                textStyle: TextStyle(fontSize: 0),
              ),
              child: SingleChildScrollView(
                child: Column(children: p.map(buildText).toList()),
              ),
              scrollController: _scrollController,
              enablePullDown: widget.index > 0,
              enablePullUp: widget.index < widget.max,
              onLoading: _onLoading,
              onRefresh: _onRefresh,
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
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.arrow_upward),
                onPressed: index > 0
                    ? () => widget.pageCtr.jumpToPage(index - 1)
                    : null,
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward),
                onPressed: index < max
                    ? () => widget.pageCtr.jumpToPage(index + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildText(String item) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        child: Text(
          '\t\t\t$item',
          textAlign: TextAlign.justify,
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
