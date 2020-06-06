import 'dart:typed_data';

import 'package:flutter/material.dart';

class BookDrawer extends StatelessWidget {
  final Uint8List preview;
  final List<String> titles;
  final String title;
  final void Function(BuildContext, int) onTitleClick;

  const BookDrawer(
    this.preview,
    this.titles,
    this.onTitleClick,
    this.title, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Container(child: Image.memory(preview), width: 100),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: titles.length,
                itemBuilder: (_, i) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: InkWell(
                      child: Text(titles[i]),
                      onTap: () => onTitleClick(ctx, i),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
