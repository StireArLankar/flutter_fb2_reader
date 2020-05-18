import 'package:flutter/material.dart';

import 'drawer.dart';
import 'fb2_picker.dart';
import 'fb2_reader.dart';
import 'fb2_reader_v2.dart';
import 'fb2_reader_v3.dart';
import 'fb2_reader_v4.dart';
import 'fb2_reader_v5.dart';
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
    case FB2PickerScreen.pathName:
      return MaterialPageRoute(builder: (_) => FB2PickerScreen());
    case FB2ReaderScreen.pathName:
      return MaterialPageRoute(
        builder: (_) => FB2ReaderScreen(settings.arguments),
      );
    case FB2ReaderScreenV2.pathName:
      return MaterialPageRoute(
        builder: (_) => FB2ReaderScreenV2(settings.arguments),
      );
    case FB2ReaderScreenV3.pathName:
      return MaterialPageRoute(
        builder: (_) => FB2ReaderScreenV3(settings.arguments),
      );
    case FB2ReaderScreenV4.pathName:
      return MaterialPageRoute(
        builder: (_) => FB2ReaderScreenV4(settings.arguments),
      );
    case FB2ReaderScreenV5.pathName:
      return MaterialPageRoute(
        builder: (_) => FB2ReaderScreenV5(settings.arguments),
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
