import 'package:flutter_observable_state/flutter_observable_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  final isInitialized = Observable(false);

  final fontSize = Observable(14.0);

  AppState() {
    SharedPreferences.getInstance().then((prefs) {
      try {
        fontSize.change((_) => prefs.getDouble('fontSize'));
        if (fontSize == null) throw Error();
      } catch (e) {
        fontSize.change((_) => 14.0);
        prefs.setDouble('fontSize', 14.0);
      }

      isInitialized.change((_) => true);
    });
  }
}
