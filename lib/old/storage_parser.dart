// import 'dart:async';
// import 'dart:io';
// import 'package:flutter_observable_state/flutter_observable_state.dart';
// import 'package:path/path.dart' as p;
// import 'package:archive/archive.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path_provider_ex/path_provider_ex.dart';
// import 'package:receive_sharing_intent/receive_sharing_intent.dart';
// import 'package:xml/xml.dart' as xml;

// import 'drawer.dart';
// import 'fb2_reader.dart';
// import 'pages/book_description.dart';
// import 'store/actions.dart';
// import 'store/app_state.dart';
// import 'store/services.dart';

// const bold = const TextStyle(fontWeight: FontWeight.bold);

// class StorageParser extends StatelessWidget {
//   static const String pathName = 'storage-parser';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(child: PathProviderApp()),
//       appBar: AppBar(title: const Text('Main screen')),
//       drawer: AppDrawer(StorageParser.pathName),
//     );
//   }
// }

// class PathProviderApp extends StatefulWidget {
//   @override
//   _PathProviderAppState createState() => _PathProviderAppState();
// }

// class _PathProviderAppState extends State<PathProviderApp> {
//   List<StorageInfo> _storageInfo = [];
//   List<String> _filesPaths = [];
//   String _sharedText = '';
//   Future<String> _parsedPath;
//   StreamSubscription _subscription;

//   final _state = getIt.get<AppState>();
//   final _actions = getIt.get<ActionS>();

//   void updateState(String str) {
//     setState(() {
//       _sharedText = str;
//       final parsedPath = str != null ? Uri.decodeFull(str).split(':').last : null;
//       print(parsedPath);

//       if (parsedPath == null) return;

//       _parsedPath = Future.value(parsedPath);
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     initPlatformState();

//     _subscription = ReceiveSharingIntent.getTextStream().listen((value) {
//       updateState(value);
//       print("Mounted: $_sharedText");
//     }, onError: (err) => print("getLinkStream error: $err"));

//     ReceiveSharingIntent.getInitialText().then((value) {
//       updateState(value);
//       print("Initial: $_sharedText");
//     });
//   }

//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }

//   FutureBuilder<String> buildLoader() {
//     return FutureBuilder<String>(
//       future: _parsedPath,
//       builder: (ctx, snapshot) {
//         Widget child;

//         if (snapshot.hasData && snapshot.data.split('.').last == 'fb2') {
//           child = Container(
//             width: double.infinity,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: <Widget>[
//                 Text(snapshot.data),
//                 RaisedButton(
//                   onPressed: () => _openReader(snapshot.data),
//                   child: Text("Open file"),
//                 ),
//                 RaisedButton(
//                   onPressed: () => _openDescription(snapshot.data),
//                   child: Text("Open description"),
//                 ),
//               ],
//             ),
//           );
//         } else if (snapshot.hasError) {
//           child = Text('Error: ${snapshot.error}');
//         } else {
//           child = CircularProgressIndicator();
//         }

//         return Padding(
//           child: child,
//           padding: EdgeInsets.all(5.0),
//         );
//       },
//     );
//   }

//   void _openFileExplorer() async {
//     try {
//       setState(() => _parsedPath = null);
//       _parsedPath = FilePicker.getFilePath().then((value) {
//         if (value.contains('.fb2.zip')) {
//           return _prepareZip(value);
//         }

//         return value;
//       });
//     } on PlatformException catch (e) {
//       print("Unsupported operation" + e.toString());
//     }
//   }

//   Future<String> _prepareZip(String path) async {
//     try {
//       final bytes = File(path).readAsBytesSync();

//       final archive = ZipDecoder().decodeBytes(bytes);

//       final tempDirectory = await getTemporaryDirectory();

//       for (final file in archive) {
//         final filename = file.name;

//         if (file.isFile && filename.split('.').last == 'fb2') {
//           final data = file.content;

//           final path = p.join(tempDirectory.path, filename);

//           if (!await File(path).exists()) {
//             File(path)
//               ..createSync(recursive: true)
//               ..writeAsBytesSync(data);
//           }

//           if (!_filesPaths.contains(path)) {
//             _filesPaths.add(path);
//           }

//           setState(() {});
//           return Future.value(path);
//         }
//       }
//     } catch (e) {}

//     return Future.value(null);
//   }

//   Future<void> initPlatformState() async {
//     List<StorageInfo> storageInfo;
//     try {
//       storageInfo = await PathProviderEx.getStorageInfo();
//     } on PlatformException {}

//     if (!mounted) return;

//     storageInfo.forEach((element) {
//       final rootPath = element.rootDir;
//       final files = Directory(rootPath).listSync(recursive: true);
//       files.forEach((element) async {
//         if (element is File) {
//           final name = element.path.split("/")?.last;

//           print('FileName: $name');

//           if (name.split('.').last == 'fb2') {
//             _filesPaths.add(element.path);
//           }

//           if (name.split('.').reversed.take(2).last == 'fb2') {
//             await _prepareZip(element.path);
//           }
//         }
//       });
//     });

//     setState(() {
//       _storageInfo = storageInfo;
//     });
//   }

//   static xml.XmlDocument parseXML(String contents) {
//     return xml.XmlDocument.parse(contents.replaceAll('<image', '<img'));
//   }

//   Future<xml.XmlDocument> _openFile(String path) async {
//     final file = File(path);
//     final contents = await file.readAsString();
//     print('Start: ${DateTime.now()}');
//     final res = await compute(parseXML, contents);
//     print('End: ${DateTime.now()}');
//     return res;
//   }

//   void _openReader(String path) async {
//     final document = await _openFile(path);
//     Navigator.of(context).pushNamed(
//       FB2ReaderScreen.pathName,
//       arguments: document,
//     );
//   }

//   void _openDescription(String path) {
//     _actions.setOpenedDescription(path);

//     Navigator.of(context).pushNamed(BookDescription.pathName);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: <Widget>[
//         RaisedButton(
//           onPressed: _openFileExplorer,
//           child: Text("Open file picker", style: bold),
//         ),
//         SizedBox(height: 10),
//         buildLoader(),
//         SizedBox(height: 10),
//         Text("File storages (device and SD)", style: bold),
//         SizedBox(height: 10),
//         ..._storageInfo.map((e) => Text(e.rootDir)),
//         SizedBox(height: 10),
//         observe(() => Text('Library length: ${_state.booksList.get().length.toString()}')),
//         Text("Saved fb2 files", style: bold),
//         Expanded(child: observe(() {
//           final books = _state.booksList.get();
//           return ListView.builder(
//             itemBuilder: (ctx, i) {
//               return ListTile(
//                 leading: Image.memory(books[i].preview),
//                 title: Text(books[i].title),
//                 onTap: () => _openDescription(books[i].path),
//               );
//             },
//             itemCount: books.length,
//           );
//         })
//             // child: ListView.builder(
//             //   itemBuilder: (ctx, i) {
//             //     return ListTile(
//             //       leading: CircleAvatar(
//             //         child: Text('$i'),
//             //       ),
//             //       onTap: () => _openReader(_filesPaths[i]),
//             //       title: Text(_filesPaths[i]),
//             //     );
//             //   },
//             //   itemCount: _filesPaths.length,
//             // ),
//             ),
//       ],
//     );
//   }
// }
