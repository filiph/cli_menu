import 'package:cli_menu/cli_menu.dart';

void main() {
  print("Pick favorite color:");
  final menu = new Menu(["Red", "Green", "Orange", "Fuchsia"]);
  final result = menu.choose();
  print("You picked: $result");
}
