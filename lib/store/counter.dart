import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Include generated file
part 'counter.g.dart';

// This is the class used by rest of your codebase
class Counter = _Counter with _$Counter;

// The store-class
abstract class _Counter with Store {
  _Counter() {
    SharedPreferences.getInstance().then((prefs) {
      try {
        fontSize = prefs.getDouble('fontSize');
        if (fontSize == null) throw Error();
      } catch (e) {
        fontSize = 14.0;
        prefs.setDouble('fontSize', 14.0);
      }
      isInitialized = true;
    });
  }

  @observable
  int value = 0;

  @observable
  bool isInitialized = false;

  @observable
  double fontSize;

  @action
  void increment() {
    value++;
  }

  @action
  Future<void> setFontSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setDouble('fontSize', size);
      fontSize = size;
    } catch (e) {}
  }
}
