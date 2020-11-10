/// A result provided by a menu. Includes the [value] and also the [index]
/// at which the value was provided in the original list of options.
///
/// Can also provide a [modifierKey], when the option was selected with
/// something other than enter or space.
class MenuResult<T> {
  final int index;

  final T value;

  final String? modifierKey;

  MenuResult(this.index, this.value, {this.modifierKey});

  @override
  String toString() {
    if (modifierKey != null) {
      return '$value (with $modifierKey)';
    }
    return '$value';
  }
}
