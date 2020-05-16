import 'package:global_configuration/global_configuration.dart';
import 'package:mobx/mobx.dart';

// Include generated file
part 'counter.g.dart';

// This is the class used by rest of your codebase
class Counter = _Counter with _$Counter;

// The store-class
abstract class _Counter with Store {
  _Counter() {
    final mp = GlobalConfiguration().appConfig;
    print(mp['fontSize'].runtimeType);
    fontSize = mp['fontSize'] ?? 14.0;
  }

  @observable
  int value = 0;

  @observable
  double fontSize;

  @action
  void increment() {
    value++;
  }

  @action
  void setFontSize(double size) {
    fontSize = size;
    GlobalConfiguration().updateValue('fontSize', size);
  }
}
