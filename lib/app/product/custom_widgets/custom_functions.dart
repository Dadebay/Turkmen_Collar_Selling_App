class CustomFunctions {
  static String findPrice(String price) {
    final double sum = double.parse(price) / 100.0;
    return sum.toStringAsFixed(sum > 1000 ? 0 : 2).toString();
  }
}
