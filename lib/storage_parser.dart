import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider_ex/path_provider_ex.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:xml/xml.dart' as xml;

import 'drawer.dart';
import 'fb2_reader_v5.dart';

const bold = const TextStyle(fontWeight: FontWeight.bold);

class StorageParser extends StatelessWidget {
  static const String pathName = 'storage-parser';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: PathProviderApp()),
      appBar: AppBar(title: const Text('Path provider example')),
      drawer: AppDrawer(StorageParser.pathName),
    );
  }
}

class PathProviderApp extends StatefulWidget {
  @override
  _PathProviderAppState createState() => _PathProviderAppState();
}

class _PathProviderAppState extends State<PathProviderApp> {
  List<StorageInfo> _storageInfo = [];
  List<String> _filesPaths = [];
  String _sharedText = '';
  Future<String> _parsedPath;
  StreamSubscription _subscription;

  void updateState(String str) {
    setState(() {
      _sharedText = str;
      final parsedPath = str != null ? Uri.decodeFull(str).split(':').last : null;
      print(parsedPath);

      if (parsedPath == null) return;

      _parsedPath = Future.value(parsedPath);
    });
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();

    _subscription = ReceiveSharingIntent.getTextStream().listen((value) {
      updateState(value);
      print("Mounted: $_sharedText");
    }, onError: (err) => print("getLinkStream error: $err"));

    ReceiveSharingIntent.getInitialText().then((value) {
      updateState(value);
      print("Initial: $_sharedText");
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  FutureBuilder<String> buildLoader() {
    return FutureBuilder<String>(
      future: _parsedPath,
      builder: (ctx, snapshot) {
        Widget child;

        if (snapshot.hasData) {
          child = Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(snapshot.data),
                RaisedButton(
                  onPressed: () => _openReaderV5(snapshot.data),
                  child: Text("Open file"),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          child = Text('Error: ${snapshot.error}');
        } else {
          child = CircularProgressIndicator();
        }

        return Padding(
          child: child,
          padding: EdgeInsets.all(5.0),
        );
      },
    );
  }

  void _openFileExplorer() async {
    try {
      setState(() => _parsedPath = null);
      _parsedPath = FilePicker.getFilePath();
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }
  }

  Future<void> initPlatformState() async {
    List<StorageInfo> storageInfo;
    try {
      storageInfo = await PathProviderEx.getStorageInfo();
    } on PlatformException {}

    if (!mounted) return;

    storageInfo.forEach((element) {
      final rootPath = element.rootDir;
      final files = Directory(rootPath).listSync(recursive: true);
      files.forEach((element) {
        if (element is File) {
          final name = element.path.split("/")?.last;
          print('FileName: $name');
          if (name.split('.').last == 'fb2') {
            _filesPaths.add(element.path);
          }
        }
      });
    });

    setState(() {
      _storageInfo = storageInfo;
    });
  }

  static xml.XmlDocument parseXML(String contents) {
    return xml.XmlDocument.parse(contents.replaceAll('<image', '<img'));
  }

  Future<xml.XmlDocument> _openFile(String path) async {
    final file = File(path);
    final contents = await file.readAsString();
    print('Start: ${DateTime.now()}');
    final res = await compute(parseXML, contents);
    print('End: ${DateTime.now()}');
    return res;
  }

  void _openReaderV5(String path) async {
    final document = await _openFile(path);
    Navigator.of(context).pushNamed(
      FB2ReaderScreenV5.pathName,
      arguments: document,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        RaisedButton(
          onPressed: _openFileExplorer,
          child: Text("Open file picker", style: bold),
        ),
        SizedBox(height: 10),
        buildLoader(),
        SizedBox(height: 10),
        Text("File storages (device and SD)", style: bold),
        SizedBox(height: 10),
        ..._storageInfo.map((e) => Text(e.rootDir)),
        SizedBox(height: 10),
        Text("Found fb2 files", style: bold),
        Expanded(
          child: ListView.builder(
            itemBuilder: (ctx, i) {
              return ListTile(
                leading: CircleAvatar(
                  child: Text('$i'),
                ),
                onTap: () => _openReaderV5(_filesPaths[i]),
                title: Text(_filesPaths[i]),
              );
            },
            itemCount: _filesPaths.length,
          ),
        ),
      ],
    );
  }
}
