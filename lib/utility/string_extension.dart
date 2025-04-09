extension StringExtension on String {
  /// Restituisce la stringa con la prima lettera maiuscola
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  /// Converte una stringa in boolean
  bool toBoolean() {
    return (toLowerCase() == "true") ? true : false;
  }
}
