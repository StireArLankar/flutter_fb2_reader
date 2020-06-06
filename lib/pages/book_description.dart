import 'package:flutter/material.dart';
import '../store/app_state.dart';
import '../store/services.dart';
import 'package:flutter_observable_state/flutter_observable_state.dart';
import 'package:xml/xml.dart' as xml;

class BookDescription extends StatelessWidget {
  static const String pathName = 'book_description';

  final _state = getIt.get<AppState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book description')),
      body: observe(() {
        final content = _state.openedDescription.get();

        if (content == null) {
          return Center(child: CircularProgressIndicator());
        }

        final doc = xml.XmlDocument.parse(content.description);

        final info = doc.getElement('title-info');

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              content.cover == null
                  ? Image.asset('assets/placeholder.png')
                  : Image.memory(content.cover),
              Text(content.description)
            ],
          ),
        );
      }),
    );
  }
}
