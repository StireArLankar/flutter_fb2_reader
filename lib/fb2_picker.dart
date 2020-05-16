import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart' as xml;

import 'drawer.dart';
import 'fb2_reader.dart';
import 'fb2_reader_v2.dart';

class FB2PickerScreen extends StatelessWidget {
  static const String pathName = 'fb2-picker';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FB2Picker(),
      ),
      appBar: AppBar(title: const Text('FB2 picker')),
      drawer: AppDrawer(FB2PickerScreen.pathName),
    );
  }
}

class FB2Picker extends StatefulWidget {
  @override
  _FB2PickerState createState() => _FB2PickerState();
}

class _FB2PickerState extends State<FB2Picker> {
  String _path;
  bool _loadingPath = false;

  Future<xml.XmlDocument> _openFile() async {
    final file = File(_path);
    final contents = await file.readAsString();

    return xml.parse(contents);
  }

  void _openReaderV1() async {
    final document = await _openFile();
    Navigator.of(context).pushNamed(
      FB2ReaderScreen.pathName,
      arguments: document,
    );
  }

  void _openReaderV2() async {
    final document = await _openFile();
    Navigator.of(context).pushNamed(
      FB2ReaderScreenV2.pathName,
      arguments: document,
    );
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
              onPressed: _openReaderV1,
              child: Text("Open file in readerV1"),
            ),
          ),
        if (_path != null)
          Container(
            child: RaisedButton(
              onPressed: _openReaderV2,
              child: Text("Open file in readerV2"),
            ),
          ),
      ],
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
