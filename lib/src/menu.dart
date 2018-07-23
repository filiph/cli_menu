import 'dart:io' as io;

import 'package:cli_menu/src/result.dart';
import 'package:cli_util/cli_logging.dart';

/// Provides functionality of a command-line menu.
///
/// The type argument [T] is normally inferred from the given list of options.
///
/// The only requirement for [T] is that it has a sane [toString] method. That
/// will be used to list the options.
class Menu<T> {
  static const String _ansiEscape = "\x1b[";

  /// The provided options.
  final List<T> _options;

  /// List of single-char strings that will be recognized as "select" actions
  /// on top of the usual _enter_ and _space_ keys.
  final List<String> _modifierKeys;

  /// Whether or not to use ANSI. By default, ANSI capability is autodetected.
  final bool _useAnsi;

  /// The STD OUT to use. By default, this is the usual stdout.
  final io.Stdout _stdout;

  /// The STD IN to use. By default, this is the usual stdin.
  final io.Stdin _stdin;

  /// Defines a menu with a list of [options].
  ///
  /// For best results, try to provide only as many options as can fit
  /// on a single terminal screen (i.e. less than ~40). Otherwise, the ANSI
  /// rewriting stops working well.
  ///
  /// The terminal's ANSI capabilities are autodetected, but you can
  /// set [useAnsi] to override this.
  ///
  /// Provide own [stdin] and [stdout] for testing or for custom environments.
  /// These default to the system STD IN and STD OUT.
  Menu(
    Iterable<T> options, {
    bool useAnsi,
    io.Stdin stdin,
    io.Stdout stdout,
    List<String> modifierKeys: const [],
  })
      : _options = new List.unmodifiable(options),
        _useAnsi = useAnsi ?? Ansi.terminalSupportsAnsi,
        _stdin = stdin ?? io.stdin,
        _stdout = stdout ?? io.stdout,
        _modifierKeys = modifierKeys {
    _ensureModifierKeysValid();
  }

  /// Lists the options and lets user choose, then returns the result.
  /// This is a blocking operation.
  ///
  /// Returns the [MenuResult].
  MenuResult<T> choose() {
    _SimpleResult result;
    if (_useAnsi) {
      result = _chooseAnsi();
    } else {
      result = _chooseNonAnsi();
    }

    return new MenuResult(
      result.index,
      _options[result.index],
      modifierKey: result.modifierKey,
    );
  }

  _SimpleResult _chooseAnsi() {
    int result;
    String modifierKey;
    int currentIndex = 0;
    final prevLineMode = _stdin.lineMode;
    final prevEchoMode = _stdin.echoMode;
    _stdin.lineMode = false;
    _stdin.echoMode = false;
    for (int i = 0; i < _options.length; i++) {
      // Make room for the options first.
      _stdout.writeln();
    }
    while (result == null) {
      _moveUp(_options.length);
      for (int i = 0; i < _options.length; i += 1) {
        final humanIndex = i + 1;
        _stdout.write(i == currentIndex ? "--> " : "    ");
        _stdout.write("$humanIndex".padLeft(3));
        _stdout.write(") ");
        _stdout.writeln(_sanitizeLength(_options[i].toString()));
      }
      int firstEscape = _stdin.readByteSync();
      if (firstEscape == 10 || firstEscape == 32) {
        // Space or enter was pressed.
        result = currentIndex;
        break;
      }

      for (final key in _modifierKeys) {
        if (firstEscape == key.codeUnitAt(0)) {
          // Choice was selected with a modifier key.
          modifierKey = key;
          result = currentIndex;
          break;
        }
      }
      // Break from outer loop if needed.
      if (modifierKey != null) break;

      // When user presses up or down arrow in the terminal, the program
      // receives a string of bytes: 27, 91, and then 65 (up) or 66 (down).
      if (firstEscape != 27) {
        // Neither enter or space or an arrow. Skipping.
        continue;
      }
      if (_stdin.readByteSync() != 91) continue;

      final input = _stdin.readByteSync();
      switch (input) {
        case 65:
          currentIndex = (currentIndex - 1) % _options.length;
          break;
        case 66:
          currentIndex = (currentIndex + 1) % _options.length;
          break;
      }
    }

    _stdin.lineMode = prevLineMode;
    _stdin.echoMode = prevEchoMode;
    return new _SimpleResult(result, modifierKey);
  }

  _SimpleResult _chooseNonAnsi() {
    for (int i = 0; i < _options.length; i += 1) {
      final humanIndex = i + 1;
      _stdout.write("$humanIndex".padLeft(3));
      _stdout.write(") ");
      _stdout.writeln(_options[i].toString());
    }
    int result;
    String modifierKey;
    while (result == null) {
      String input = _stdin.readLineSync();
      for (final key in _modifierKeys) {
        if (input.startsWith(key)) {
          modifierKey = key;
          input = input.substring(1);
          break;
        }
      }
      result = int.tryParse(input);
      if (result == null) {
        _stdout.writeln("Bad input: '$input'. Expecting a number.");
      } else if (result < 1 || result > _options.length) {
        _stdout.writeln("Bad input: '$input'. "
            "Expecting number from 1 to ${_options.length}.");
        result = null;
      }
    }
    return new _SimpleResult(result - 1, modifierKey);
  }

  void _ensureModifierKeysValid() {
    for (final key in _modifierKeys) {
      if (key.length != 1) {
        throw new ArgumentError("Modifier keys must be provided "
            "as single-char strings.");
      }
      if (key.codeUnitAt(0) > 255) {
        throw new ArgumentError("Modifier keys must be 8-bit ASCII.");
      }
    }
  }

  /// https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
  void _moveUp(int count) {
    _stdout.write("$_ansiEscape${count}A");
  }

  /// Truncates the string to a length that will fit into one line on most
  /// terminals.
  ///
  /// When no truncation is needed, returns the original string. Otherwise,
  /// ends the string with `"..."`.
  String _sanitizeLength(String input) {
    const int maxLength = 60;
    if (input.length <= maxLength) return input;
    return input.substring(0, maxLength - 3) + "...";
  }
}

class _SimpleResult {
  final int index;
  final String modifierKey;

  const _SimpleResult(this.index, this.modifierKey);
}
