import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide RefreshIndicator;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';

import 'store/counter.dart';

class FB2ReaderScreenV5 extends StatelessWidget {
  static const String pathName = 'fb2-reader-v5';

  final xml.XmlDocument document;

  const FB2ReaderScreenV5(this.document, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FB2Reader(document),
      ),
      appBar: AppBar(
        title: const Text('FB2 reader V5'),
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
  final Map<int, double> offsetsMap = Map();
  xml.XmlDocument document;

  bool isReady = false;

  setOffset(int chapter, double offset) {
    offsetsMap[chapter] = offset;
  }

  static Future<xml.XmlDocument> replaceImages(xml.XmlDocument document) {
    final binaries = document.findAllElements('binary');

    document.findAllElements('emphasis').forEach((element) {
      final str = element.toXmlString().replaceAll('emphasis', 'i');
      element.replace(xml.XmlDocument.parse(str).findElements('i').first.copy());
    });

    document.findAllElements('img').forEach((element) {
      final id = element.getAttribute('l:href').split('#').last;
      final binary = binaries.firstWhere((element) {
        return element.getAttribute('id') == id;
      });

      if (binary != null) {
        final str = element
            .toXmlString()
            .replaceAll('/>', ' src="data:image/png;base64, ${binary.text}" />');

        final temp = xml.XmlDocument.parse(str).findElements('img').first.copy();

        element.replace(temp);
      }
    });

    return Future.value(document);
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      print('Start: ${DateTime.now()}');
      final doc = await compute(replaceImages, widget.document);
      print('End: ${DateTime.now()}');

      setState(() {
        document = doc;
        isReady = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      final size = MediaQuery.of(context).size;
      final dimension = size.width > size.height ? size.height * 0.8 : size.width * 0.8;

      return Center(
        child: SizedBox(
          child: CircularProgressIndicator(
            strokeWidth: dimension / 10,
          ),
          height: dimension,
          width: dimension,
        ),
      );
    }

    final sections = document.findAllElements('section').where((section) {
      return section.innerText.trim().length > 0;
    }).toList();

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
    print('init offset ${widget.index}: $offset');
    _scrollController = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    final offset = _refreshController.position.pixels;
    widget.setOffset(widget.index, offset);
    print('end offset ${widget.index}: $offset');
    super.dispose();
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
        .where((element) => element.length > 0);

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
              header: ClassicHeader(
                textStyle: TextStyle(fontSize: 0),
              ),
              footer: ClassicFooter(
                loadStyle: LoadStyle.HideAlways,
                canLoadingIcon: Icon(Icons.arrow_upward),
                loadingIcon: Icon(Icons.done),
                idleIcon: Icon(Icons.access_time),
                textStyle: TextStyle(fontSize: 0),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: children.map(buildHtml).toList(),
                ),
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

    // print(data);

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
            height: MediaQuery.of(ctx).size.height / 2,
            backgroundColor: Colors.black12,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          "p": Style(
            padding: const EdgeInsets.all(0),
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            textAlign: TextAlign.justify,
            fontSize: FontSize(store.fontSize),
            whiteSpace: WhiteSpace.PRE,
          ),
          'i': Style(
            textAlign: TextAlign.center,
          ),
          'strong': Style(
            textAlign: TextAlign.center,
          ),
        },
      ),
    );
  }
}
