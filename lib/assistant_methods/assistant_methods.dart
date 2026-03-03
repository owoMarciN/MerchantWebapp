List<String> separateItemIDs(List<dynamic> userCart) {
  return userCart.map((item) {
    List<String> parts = item.toString().split(':');
    return parts.length >= 3 ? parts[2] : '';
  }).toList();
}

List<int> separateItemQuantities(List<dynamic> userCart) {
  return userCart.map((item) {
    List<String> parts = item.toString().split(':');
    return parts.length >= 4 ? int.parse(parts[3]) : 1;
  }).toList();
}
