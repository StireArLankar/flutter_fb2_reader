import 'package:flutter/material.dart';
import 'package:flutter_fb2_reader/router.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  const App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter file picker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        accentColor: Colors.red,
      ),
      initialRoute: 'file-picker',
      onGenerateRoute: generateRoutes,
    );
  }
}
