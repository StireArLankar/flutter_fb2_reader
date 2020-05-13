import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  Widget buildLink(BuildContext context, String title, String route) {
    return ListTile(
      leading: const Icon(Icons.panorama_fish_eye),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pushReplacementNamed(route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                child: Column(children: [
                  buildLink(context, 'file-picker', 'file-picker'),
                  buildLink(context, 'path-provider', 'path-provider'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
