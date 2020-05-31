import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:path_provider_ex/path_provider_ex.dart';

import 'drawer.dart';

class StorageParserV2 extends StatelessWidget {
  static const String pathName = 'storage-parser';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: PathProviderApp()),
      appBar: AppBar(title: const Text('Path provider example')),
      drawer: AppDrawer(StorageParserV2.pathName),
    );
  }
}

class PathProviderApp extends StatefulWidget {
  @override
  _PathProviderAppState createState() => _PathProviderAppState();
}

class _PathProviderAppState extends State<PathProviderApp> {
  List<StorageInfo> _storageInfo = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    List<StorageInfo> storageInfo;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      storageInfo = await PathProviderEx.getStorageInfo();
    } on PlatformException {}

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _storageInfo = storageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[],
        ),
      ),
    );
  }
}
