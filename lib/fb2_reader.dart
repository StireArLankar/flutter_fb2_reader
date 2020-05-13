import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:xml/xml.dart' as xml;
import 'package:sticky_headers/sticky_headers.dart';

import 'drawer.dart';

class FB2ReaderScreen extends StatelessWidget {
  static const String pathName = 'fb2-reader';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FB2Reader(),
      ),
      appBar: AppBar(title: const Text('FB2 reader')),
      drawer: AppDrawer(),
    );
  }
}

class FB2Reader extends StatefulWidget {
  @override
  _FB2ReaderState createState() => _FB2ReaderState();
}

class _FB2ReaderState extends State<FB2Reader> {
  String _path;
  bool _loadingPath = false;
  String _file;
  xml.XmlDocument _document;
  ItemScrollController _scrollController = ItemScrollController();

  void _openFile() async {
    final file = File(_path);
    final contents = await file.readAsString();
    setState(() {
      _document = xml.parse(contents);
      _file = contents.split('\n')[0];
    });
  }

  void _openFileExplorer() async {
    setState(() => _loadingPath = true);

    try {
      _path = await FilePicker.getFilePath();
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }

    if (!mounted) return;

    setState(() => _loadingPath = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          child: RaisedButton(
            onPressed: _openFileExplorer,
            child: Text("Open file picker"),
          ),
        ),
        Container(
          child: _loadingPath ? buildLoader() : buildContainer(context),
        ),
        if (_path != null)
          Container(
            child: RaisedButton(
              onPressed: _openFile,
              child: Text("Open file"),
            ),
          ),
        if (_file != null) Container(child: Text(_file)),
        if (_document != null) buildReader(),
      ],
    );
  }

  Widget buildReader() {
    final sections = _document.findAllElements('section').toList();

    return Expanded(
      child: Padding(
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

            return StickyHeader(
              header: Container(
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
                    if (index < sections.length - 1)
                      IconButton(
                        icon: Icon(Icons.arrow_downward),
                        onPressed: () => _scrollController.jumpTo(
                          index: index + 1,
                        ),
                      ),
                  ],
                ),
              ),
              content: Column(children: p.map(buildText).toList()),
            );
          }),
        ),
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

  Widget buildContainer(BuildContext context) {
    if (_path == null) {
      return Container(padding: const EdgeInsets.symmetric(vertical: 10.0));
    }

    final String name = _path.split('/').last;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      color: Colors.lightBlue[100],
      child: ListTile(title: Text(name), subtitle: Text(_path)),
    );
  }

  Widget buildLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: const CircularProgressIndicator(),
    );
  }
}
