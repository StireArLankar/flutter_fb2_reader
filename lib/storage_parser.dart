import 'dart:async';
import 'package:flutter_observable_state/flutter_observable_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'drawer.dart';
import 'pages/book_description.dart';
import 'store/actions.dart';
import 'store/app_state.dart';
import 'store/services.dart';

const bold = const TextStyle(fontWeight: FontWeight.bold);

class StorageParser extends StatelessWidget {
  static const String pathName = 'storage-parser';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: PathProviderApp()),
      appBar: AppBar(title: const Text('Main screen')),
      drawer: AppDrawer(StorageParser.pathName),
    );
  }
}

class PathProviderApp extends StatefulWidget {
  @override
  _PathProviderAppState createState() => _PathProviderAppState();
}

class _PathProviderAppState extends State<PathProviderApp> {
  String _sharedText = '';
  Future<String> _parsedPath;
  StreamSubscription _subscription;

  final _state = getIt.get<AppState>();
  final _actions = getIt.get<ActionS>();

  void updateState(String str) {
    setState(() {
      _sharedText = str;
      final parsedPath = str != null ? Uri.decodeFull(str).split(':').last : null;
      print(parsedPath);

      if (parsedPath == null) return;

      _parsedPath = Future.value(parsedPath);

      _openDescription(parsedPath);
    });
  }

  @override
  void initState() {
    super.initState();

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

        if (snapshot.hasData && snapshot.data.split('.').last == 'fb2') {
          child = Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(snapshot.data),
                RaisedButton(
                  onPressed: () => _openDescription(snapshot.data),
                  child: Text("Open description"),
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
      _parsedPath = FilePicker.getFilePath().then((value) {
        if (!value.contains('.fb2')) {
          return null;
        }

        _openDescription(value);
        return value;
      });
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }
  }

  void _openDescription(String path) {
    _actions.setOpenedDescription(path);

    Navigator.of(context).pushNamed(BookDescription.pathName);
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
        observe(() => Text('Library length: ${_state.booksList.get().length.toString()}')),
        Text("Saved fb2 files", style: bold),
        Expanded(child: observe(() {
          final books = _state.booksList.get();
          return ListView.builder(
            itemBuilder: (ctx, i) {
              final date = DateFormat('yyyy-MM-dd – kk:mm')
                  .format(DateTime.tryParse(books[i].opened).toLocal());

              return ListTile(
                leading: Image.memory(books[i].preview),
                title: Text(books[i].title),
                onTap: () => _openDescription(books[i].path),
                subtitle: Text(books[i].path),
                isThreeLine: true,
                trailing: Text(date),
              );
            },
            itemCount: books.length,
          );
        })),
      ],
    );
  }
}
