import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'drawer.dart';

class PathProviderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: PathProviderApp()),
      appBar: AppBar(title: const Text('Path provider example')),
      drawer: AppDrawer(),
    );
  }
}

class PathProviderApp extends StatefulWidget {
  PathProviderApp({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _PathProviderAppState createState() => _PathProviderAppState();
}

class _PathProviderAppState extends State<PathProviderApp> {
  Future<Directory> _tempDirectory;
  Future<Directory> _appSupportDirectory;
  Future<Directory> _appLibraryDirectory;
  Future<Directory> _appDocumentsDirectory;
  Future<Directory> _externalDocumentsDirectory;
  Future<List<Directory>> _externalStorageDirectories;
  Future<List<Directory>> _externalCacheDirectories;

  Widget _buildDirectory(
    BuildContext context,
    AsyncSnapshot<Directory> snapshot,
  ) {
    var text = const Text('');

    if (snapshot.connectionState == ConnectionState.done) {
      if (snapshot.hasError) {
        text = Text('Error: ${snapshot.error}');
      } else if (snapshot.hasData) {
        text = Text('path: ${snapshot.data.path}');
        snapshot.data.list(recursive: true).forEach((item) {
          print(item.path);
        });
      } else {
        text = const Text('path unavailable');
      }
    }

    return Padding(padding: const EdgeInsets.all(16.0), child: text);
  }

  Widget _buildDirectories(
    BuildContext context,
    AsyncSnapshot<List<Directory>> snapshot,
  ) {
    var text = const Text('');

    if (snapshot.connectionState == ConnectionState.done) {
      if (snapshot.hasError) {
        text = Text('Error: ${snapshot.error}');
      } else if (snapshot.hasData) {
        final combined = snapshot.data.map((d) => d.path).join('\n\n');
        text = Text('paths: $combined');
      } else {
        text = const Text('path unavailable');
      }
    }

    return Padding(padding: const EdgeInsets.all(16.0), child: text);
  }

  void _requestTempDirectory() {
    setState(() {
      _tempDirectory = getTemporaryDirectory();
    });
  }

  void _requestAppDocumentsDirectory() {
    setState(() {
      _appDocumentsDirectory = getApplicationDocumentsDirectory();
    });
  }

  void _requestAppSupportDirectory() {
    setState(() {
      _appSupportDirectory = getApplicationSupportDirectory();
    });
  }

  void _requestAppLibraryDirectory() {
    setState(() {
      _appLibraryDirectory = getLibraryDirectory();
    });
  }

  void _requestExternalStorageDirectory() {
    setState(() {
      _externalDocumentsDirectory = getExternalStorageDirectory();
    });
  }

  void _requestExternalStorageDirectories(StorageDirectory type) {
    setState(() {
      _externalStorageDirectories = getExternalStorageDirectories(type: type);
    });
  }

  void _requestExternalCacheDirectories() {
    setState(() {
      _externalCacheDirectories = getExternalCacheDirectories();
    });
  }

  List<Widget> buidSomething(
    Widget label,
    void Function() onPressed,
    Future<Directory> future,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: RaisedButton(child: label, onPressed: onPressed),
      ),
      FutureBuilder<Directory>(
        future: future,
        builder: _buildDirectory,
      )
    ];
  }

  List<Widget> buidSomethingMore(
    Widget label,
    void Function() onPressed,
    Future<List<Directory>> future,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: RaisedButton(child: label, onPressed: onPressed),
      ),
      FutureBuilder<List<Directory>>(
        future: future,
        builder: _buildDirectories,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        children: <Widget>[
          ...buidSomething(
            const Text('Get Temporary Directory'),
            _requestTempDirectory,
            _tempDirectory,
          ),
          ...buidSomething(
            const Text('Get Application Documents Directory'),
            _requestAppDocumentsDirectory,
            _appDocumentsDirectory,
          ),
          ...buidSomething(
            const Text('Get Application Support Directory'),
            _requestAppSupportDirectory,
            _appSupportDirectory,
          ),
          ...buidSomething(
            const Text('Get Application Library Directory'),
            _requestAppLibraryDirectory,
            _appLibraryDirectory,
          ),
          ...buidSomething(
            const Text("Get External Storage Directory"),
            _requestExternalStorageDirectory,
            _externalDocumentsDirectory,
          ),
          ...buidSomethingMore(
            const Text("Get External Storage Directories"),
            () => _requestExternalStorageDirectories(StorageDirectory.music),
            _externalStorageDirectories,
          ),
          ...buidSomethingMore(
            const Text("Get External Cache Directories"),
            _requestExternalCacheDirectories,
            _externalCacheDirectories,
          ),
        ],
      ),
    );
  }
}
