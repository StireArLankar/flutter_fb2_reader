import 'package:flutter/material.dart';

import 'drawer.dart';
import 'fb2_reader.dart';
import 'file_reader.dart';
import 'pages/book_description.dart';
import 'path_provider.dart';
import 'path_provider_v2.dart';
import 'storage_parser.dart';

Route<dynamic> generateRoutes(RouteSettings settings) {
  switch (settings.name) {
    case StorageParser.pathName:
      return MaterialPageRoute(builder: (_) => StorageParser());
    case BookDescription.pathName:
      return MaterialPageRoute(builder: (_) => BookDescription());
    case FileReaderScreen.pathName:
      return MaterialPageRoute(builder: (_) => FileReaderScreen());
    case PathProviderScreen.pathName:
      return MaterialPageRoute(builder: (_) => PathProviderScreen());
    case PathProviderScreenV2.pathName:
      return MaterialPageRoute(builder: (_) => PathProviderScreenV2());
    case FB2ReaderScreen.pathName:
      return MaterialPageRoute(
        builder: (_) => FB2ReaderScreen(settings.arguments),
      );

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
