import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'drawer.dart';

class FileSaverScreen extends StatelessWidget {
  static const String pathName = 'file-saver';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FileSaverApp(storage: CounterStorage()),
      ),
      appBar: AppBar(title: const Text('File saver example')),
      drawer: AppDrawer(FileSaverScreen.pathName),
    );
  }
}

class CounterStorage {
  Future<String> get _localPath async {
    final directory = await getExternalStorageDirectory();
    var myDir = Directory('/storage/emulated/0');
    myDir.list(recursive: true).forEach((item) {
      final stat = item.statSync();
      if (stat.type == FileSystemEntityType.file) {
        print('${item.path} ${stat.modeString()}');
        final reg = RegExp(r".fb2$");
        if (reg.hasMatch(item.path)) {
          print('match');
          final file = File(item.path);
          final contents = file.readAsStringSync();
          print(contents.split('\n')[0]);
          // _localPath.then((path) => file.copy('$path/counter.txt'));
        }
      }
    });
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/counter.txt');
  }

  Future<int> readCounter() async {
    try {
      final file = await _localFile;

      // Read the file
      String contents = await file.readAsString();

      return int.parse(contents);
    } catch (e) {
      // If encountering an error, return 0
      return 0;
    }
  }

  Future<File> writeCounter(int counter) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsString('$counter');
  }
}

class FileSaverApp extends StatefulWidget {
  final CounterStorage storage;

  FileSaverApp({Key key, @required this.storage}) : super(key: key);

  @override
  _FileSaverAppState createState() => _FileSaverAppState();
}

class _FileSaverAppState extends State<FileSaverApp> {
  int _counter;

  @override
  void initState() {
    super.initState();
    widget.storage.readCounter().then((int value) {
      setState(() {
        _counter = value;
      });
    });
  }

  Future<File> _incrementCounter() {
    setState(() {
      _counter++;
    });

    // Write the variable as a string to the file.
    return widget.storage.writeCounter(_counter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Button tapped $_counter time${_counter == 1 ? '' : 's'}.',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
