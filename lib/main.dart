import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:provider/provider.dart';

import 'fb2_picker.dart';
import 'router.dart';
import 'store/counter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset("app_settings");
  final mp = GlobalConfiguration().appConfig;

  print(mp);

  runApp(
    MultiProvider(
      providers: [
        Provider<Counter>(create: (_) => Counter()),
      ],
      child: App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<Counter>(context, listen: false);

    return Observer(
      builder: (ctx) {
        return MaterialApp(
          title: 'Flutter file picker',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            accentColor: Colors.red,
            textTheme: TextTheme(
              bodyText2: TextStyle(fontSize: store.fontSize),
            ),
          ),
          initialRoute: FB2PickerScreen.pathName,
          onGenerateRoute: generateRoutes,
        );
      },
    );
  }
}
