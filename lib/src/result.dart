/// A result provided by a menu. Includes the [value] and also the [index]
/// at which the value was provided in the original list of options.
class MenuResult<T> {
  final int index;

  final T value;

  MenuResult(this.index, this.value);

  @override
  String toString() => "$value";
}
