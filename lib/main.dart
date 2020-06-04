import 'package:flutter/material.dart';
import 'package:flutter_observable_state/flutter_observable_state.dart';
import 'store/app_state.dart';
import 'store/services.dart';
import 'router.dart';
import 'storage_parser.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  initialize();

  runApp(App());
}

class App extends StatelessWidget {
  App({Key key}) : super(key: key);

  final _state = getIt.get<AppState>();

  @override
  Widget build(BuildContext context) {
    return observe(() {
      if (!_state.isInitialized.get()) {
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

      return MaterialApp(
        title: 'Flutter file picker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          accentColor: Colors.red,
        ),
        initialRoute: StorageParser.pathName,
        onGenerateRoute: generateRoutes,
      );
    });
  }
}
