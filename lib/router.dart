import 'package:flutter/material.dart';
import 'package:flutter_fb2_reader/path_provider.dart';

import 'drawer.dart';
import 'file_reader/file_reader.dart';

Route<dynamic> generateRoutes(RouteSettings settings) {
  switch (settings.name) {
    case 'file-picker':
      return MaterialPageRoute(builder: (_) => FileReaderScreen());
    case 'path-provider':
      return MaterialPageRoute(builder: (_) => PathProviderScreen());
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
      drawer: AppDrawer(),
    );
  }
}
