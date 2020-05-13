import 'package:flutter/material.dart';

import 'drawer.dart';
import 'file_reader/file_reader.dart';

Route<dynamic> generateRoutes(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => FileReaderScreen());
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
