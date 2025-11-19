extension StringExtension on String {
  String get initials {
    return split(' ').map((word) => word[0]).join();
  }

  String get capitalizeFirstLetter {
    return substring(0, 1).toUpperCase() + substring(1);
  }
}