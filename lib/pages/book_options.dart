import 'package:flutter/material.dart';
import '../store/actions.dart';
import '../store/services.dart';

class BookOptions extends StatefulWidget {
  const BookOptions({Key key, this.val}) : super(key: key);

  final val;

  @override
  _BookOptionsState createState() => _BookOptionsState();
}

class _BookOptionsState extends State<BookOptions> {
  double value = 15;

  final _actions = getIt.get<ActionS>();

  @override
  void initState() {
    super.initState();

    setState(() => value = widget.val);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Font Size'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: 50),
              child: Slider(
                value: value,
                onChanged: (newVal) {
                  setState(() => value = newVal);
                },
                divisions: 10,
                label: '${value.toInt()}',
                min: 10,
                max: 20,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Approve'),
          onPressed: () => _actions.setFontSize(value).then(Navigator.of(context).pop),
        ),
      ],
    );
  }
}
