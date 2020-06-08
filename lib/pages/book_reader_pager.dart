import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class BookReaderPages extends StatefulWidget {
  BookReaderPages({Key key}) : super(key: key);

  @override
  _BookReaderPagesState createState() => _BookReaderPagesState();
}

class _BookReaderPagesState extends State<BookReaderPages> {
  void getTotalHeight(double height) {
    print(height);
  }

  @override
  Widget build(BuildContext context) {
    MyPainter(getTotalHeight).paint(
      Canvas(ui.PictureRecorder()),
      Size(
        ui.window.physicalSize.width / ui.window.devicePixelRatio,
        ui.window.physicalSize.height / ui.window.devicePixelRatio,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('TextPainter')),
      body: Container(),
    );
  }
}

final String text = List.filled(100, """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis pharetra lobortis faucibus. Vestibulum efficitur, velit nec accumsan aliquam, lectus elit congue nulla, ac venenatis purus mi vel risus. Ut auctor consequat nibh in sodales. Aenean eget dolor dictum, imperdiet turpis nec, interdum diam. Sed vitae mauris hendrerit, tempus orci sit amet, placerat eros. Nulla dignissim, orci quis congue maximus, eros arcu mattis magna, vitae interdum lacus lorem nec velit. Aliquam a diam at metus pulvinar efficitur. Fusce in augue eget ligula pharetra iaculis. Nunc id dui in magna aliquet hendrerit. Nullam eu enim lacus.

Nullam aliquam elementum velit vel tincidunt. Cras dui ex, lobortis sit amet tortor ut, rutrum maximus tortor. Nulla faucibus tellus nisi, non dapibus nisi aliquam sed. Morbi sed dignissim libero. Fusce dignissim leo nec libero placerat, id consectetur augue interdum. Praesent ut massa nisl. Praesent id pulvinar ex. In egestas nec ligula et blandit.

Cras sed finibus diam. Quisque odio nisl, fermentum et ante vitae, sollicitudin sodales risus. Mauris varius semper lectus, id gravida nibh sodales eget. Pellentesque aliquam, velit quis fringilla rhoncus, neque orci semper tellus, quis interdum odio justo sit amet dui. Nam tristique aliquam purus, in facilisis lacus facilisis sed. Nullam pulvinar ultrices molestie. Cras ac erat porta enim bibendum semper.

Curabitur sed dictum sem, et sollicitudin dolor. Sed semper elit est, at fermentum purus bibendum nec. Donec scelerisque diam sit amet ante cursus cursus in scelerisque tellus. Pellentesque nec nibh id mi euismod efficitur in ac lorem. Pellentesque scelerisque fermentum vestibulum. Cras molestie lobortis dolor vel faucibus. Vivamus hendrerit est vitae tellus commodo accumsan. Phasellus ut finibus nulla. Nam sed massa turpis.

Mauris nec nunc ex. Morbi pellentesque scelerisque ligula, vel accumsan ligula rutrum nec. Pellentesque quis nulla ligula. Duis diam arcu, iaculis nec sem sit amet, malesuada consectetur arcu. Ut a nisi faucibus, pulvinar nisl sit amet, dignissim eros. Ut tortor metus, bibendum a congue fermentum, efficitur sed nisl. Donec vel placerat magna, in placerat ligula. Sed dignissim pulvinar mauris non tristique.
Mauris nec nunc ex. Morbi pellentesque scelerisque ligula, vel accumsan ligula rutrum nec. Pellentesque quis nulla ligula. Duis diam arcu, iaculis nec sem sit amet, malesuada consectetur arcu. Ut a nisi faucibus, pulvinar nisl sit amet, dignissim eros. Ut tortor metus, bibendum a congue fermentum, efficitur sed nisl. Donec vel placerat magna, in placerat ligula. Sed dignissim pulvinar mauris non tristique.
Mauris nec nunc ex. Morbi pellentesque scelerisque ligula, vel accumsan ligula rutrum nec. Pellentesque quis nulla ligula. Duis diam arcu, iaculis nec sem sit amet, malesuada consectetur arcu. Ut a nisi faucibus, pulvinar nisl sit amet, dignissim eros. Ut tortor metus, bibendum a congue fermentum, efficitur sed nisl. Donec vel placerat magna, in placerat ligula. Sed dignissim pulvinar mauris non tristique.
Mauris nec nunc ex. Morbi pellentesque scelerisque ligula, vel accumsan ligula rutrum nec. Pellentesque quis nulla ligula. Duis diam arcu, iaculis nec sem sit amet, malesuada consectetur arcu. Ut a nisi faucibus, pulvinar nisl sit amet, dignissim eros. Ut tortor metus, bibendum a congue fermentum, efficitur sed nisl. Donec vel placerat magna, in placerat ligula. Sed dignissim pulvinar mauris non tristique.
""").join('\n');

class MyPainter extends CustomPainter {
  final void Function(double) getTotalHeight;

  MyPainter(this.getTotalHeight);

  @override
  void paint(canvas, size) {
    canvas.drawRect(Offset(0, 0) & size, Paint());

    // Since text is overflowing, you have two options: cliping before drawing text or/and defining max lines.
    canvas.clipRect(Offset(0, 0) & size);

    final TextStyle style = TextStyle(
      color: Colors.black,
      decorationThickness: 0.25,
    );

    final TextPainter textPainter = TextPainter(
      maxLines: 25,
      text: TextSpan(text: text, style: style),
      // TextSpan could be whole TextSpans tree :)
      textAlign: TextAlign.justify,
      textDirection: TextDirection.ltr,
      // It is necessary for some weird reason... IMO should be LTR for default since well-known international languages (english, esperanto) are written left to right.
    )..layout(maxWidth: size.width - 12.0 - 12.0);
    // TextPainter doesn't need to have specified width (would use infinity if not defined).
    // BTW: using the TextPainter you can check size the text take to be rendered (without `paint`ing it).
    textPainter.paint(canvas, const Offset(12.0, 12.0));

    print('----');
    print('TextPainter');
    print('didExceedMaxLines ${textPainter.height}');
    print(textPainter.getPositionForOffset(Offset(size.width, size.height)));
    getTotalHeight(textPainter.height);
    print('----');
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false; // Just for example, in real environment should be implemented!
  }
}
