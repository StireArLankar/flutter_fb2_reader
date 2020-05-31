import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'storage_parser.dart';
import 'store/counter.dart';

void main() {
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
        if (!store.isInitialized) {
          return MaterialApp(
            builder: (ctx, _) {
              final size = MediaQuery.of(ctx).size;
              final dimension = size.width > size.height ? size.height * 0.8 : size.width * 0.8;

              return Scaffold(
                body: Center(
                  child: SizedBox(
                    child: CircularProgressIndicator(
                      strokeWidth: dimension / 10,
                    ),
                    height: dimension,
                    width: dimension,
                  ),
                ),
              );
            },
          );
        }

        print('___');
        print('main.dart');
        print('---');

        return MaterialApp(
          title: 'Flutter file picker',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            accentColor: Colors.red,
          ),
          initialRoute: StorageParser.pathName,
          onGenerateRoute: generateRoutes,
        );
      },
    );
  }
}
