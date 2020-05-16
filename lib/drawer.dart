import 'package:flutter/material.dart';

import 'fb2_reader.dart';
import 'fb2_reader_v2.dart';
import 'file_reader.dart';
import 'file_saver.dart';
import 'path_provider.dart';

final routesArray = const [
  FileReaderScreen.pathName,
  PathProviderScreen.pathName,
  FileSaverScreen.pathName,
  FB2ReaderScreen.pathName,
  FB2ReaderScreenV2.pathName
];

class AppDrawer extends StatelessWidget {
  final List<String> routes;

  factory AppDrawer(String currentRoute) {
    final routes = routesArray.where((item) => item != currentRoute).toList();
    return AppDrawer._internal(routes);
  }

  AppDrawer._internal(this.routes);

  Widget buildLink(BuildContext context, String title, String route) {
    return ListTile(
      leading: const Icon(Icons.panorama_fish_eye),
      title: Text(title),
      onTap: () => Navigator.of(context).pushReplacementNamed(route),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(height: 5),
            Text(
              'Menu!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children:
                      routes.map((item) => buildLink(ctx, item, item)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
