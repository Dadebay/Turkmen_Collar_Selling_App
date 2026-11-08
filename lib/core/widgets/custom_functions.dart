class CustomFunctions {
  static String findPrice(String price) {
    final cents = double.tryParse(price) ?? 0;
    return (cents / 100).toStringAsFixed(2);
  }
}
