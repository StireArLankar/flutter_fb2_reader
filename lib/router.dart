import 'package:flutter/material.dart';

import 'drawer.dart';
import 'fb2_reader.dart';
import 'fb2_reader_v2.dart';
import 'file_reader.dart';
import 'file_saver.dart';
import 'path_provider.dart';

Route<dynamic> generateRoutes(RouteSettings settings) {
  switch (settings.name) {
    case FileReaderScreen.pathName:
      return MaterialPageRoute(builder: (_) => FileReaderScreen());
    case PathProviderScreen.pathName:
      return MaterialPageRoute(builder: (_) => PathProviderScreen());
    case FileSaverScreen.pathName:
      return MaterialPageRoute(builder: (_) => FileSaverScreen());
    case FB2ReaderScreen.pathName:
      return MaterialPageRoute(builder: (_) => FB2ReaderScreen());
    case FB2ReaderScreenV2.pathName:
      return MaterialPageRoute(builder: (_) => FB2ReaderScreenV2());
    default:
      return MaterialPageRoute(builder: (_) => DefaultScreen(settings.name));
  }
}

class DefaultScreen extends StatelessWidget {
  final String name;

  DefaultScreen(this.name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('No route defined for $name'),
      ),
      appBar: AppBar(),
      drawer: AppDrawer(''),
    );
  }
}
