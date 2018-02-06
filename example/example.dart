import 'package:cli_menu/cli_menu.dart';

void main() {
  final menu = new Menu(["Red", "Green", "Orange"]);
  final result = menu.choose();
  print('Chosen: $result');
}
