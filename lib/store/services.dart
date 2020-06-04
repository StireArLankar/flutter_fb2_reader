import 'app_state.dart';
import 'actions.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void initialize() {
  getIt.registerSingleton(AppState());
  getIt.registerSingleton(ActionS());
}
