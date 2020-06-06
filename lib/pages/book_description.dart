import 'package:flutter/material.dart';
import '../store/app_state.dart';
import '../store/services.dart';
import 'package:flutter_observable_state/flutter_observable_state.dart';
import 'book_description.utils.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_html/html_parser.dart';

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

        final info = getInfo(content.description);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              content.cover == null
                  ? Image.asset('assets/placeholder.png')
                  : Image.memory(content.cover),
              RaisedButton(
                child: Text('Open reader'),
                onPressed: () {},
              ),
              _buildAuthors(info),
              _buildGenres(info),
              _buildTitle(info),
              _buildAnnotation(info),
              _buildLanguage(info),
              _buildSequence(info),
              SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAuthors(Info info) {
    final authors = info.authors;
    if (authors.length == 0) return Container();

    if (authors.length == 1) {
      final e = authors.first;
      return Text('Author: ${e.firstName} ${e.lastName}');
    }

    return Column(
      children: [
        Text('Authors:'),
        ...authors.map((e) => Text('${e.firstName} ${e.lastName}')),
      ],
    );
  }

  Widget _buildGenres(Info info) {
    if (info.genre.length == 0) return Container();

    return Wrap(
      children: [
        Text('Genres:'),
        ...info.genre.map((e) => Text(e)),
      ],
    );
  }

  Widget _buildTitle(Info info) {
    if (info.title == null) return Container();

    return Text('Title: ${info.title}');
  }

  Widget _buildAnnotation(Info info) {
    if (info.annotation == null) return Container();

    return Html(
      data: info.annotation,
      style: {
        "body ": Style(
          margin: const EdgeInsets.all(0),
          padding: const EdgeInsets.all(0),
        ),
        "p": Style(
          padding: const EdgeInsets.all(0),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          textAlign: TextAlign.justify,
          fontSize: FontSize(17),
          whiteSpace: WhiteSpace.PRE,
        ),
        'i': Style(textAlign: TextAlign.center),
        'strong': Style(textAlign: TextAlign.center),
        "emphasis": Style(fontStyle: FontStyle.italic)
      },
      customRender: {
        "emphasis": (context, child, _, __) {
          return ContainerSpan(newContext: context, child: child);
        }
      },
    );
  }

  Widget _buildLanguage(Info info) {
    if (info.lang == null) return Container();

    return Text('Language: ${info.lang}');
  }

  Widget _buildSequence(Info info) {
    if (info.sequence == null) return Container();

    return Column(
      children: <Widget>[
        Text('Sequence'),
        Text('Sequence name: ${info.sequence.name}'),
        Text('Sequence number: ${info.sequence.number}'),
      ],
    );
  }
}