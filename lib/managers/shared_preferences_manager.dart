import 'package:shared_preferences/shared_preferences.dart';

import 'package:bardic_beats/enums/operation_enum.dart';

class SharedPreferencesManager {
  /// Recupera l`istanza delle sharedPreferences
  static Future<SharedPreferences> getSharedPreferencesInstance() async {
    return await SharedPreferences.getInstance();
  }

  /// Aggiorna le coppie di chiave-valore
  static void updateKV(String key, Operation mode, [dynamic value = ""]) async {
    SharedPreferences sharedPreferences = await getSharedPreferencesInstance();
    // Se deve aggiungere un elemento lo imposta in base al tipo
    if (mode == Operation.update) {
      if (value is bool) {
        sharedPreferences.setBool(key, value);
      } else if (value is String) {
        sharedPreferences.setString(key, value);
      } else if (value is int) {
        sharedPreferences.setInt(key, value);
      } else if (value is double) {
        sharedPreferences.setDouble(key, value);
      } else if (value is List<String>) {
        sharedPreferences.setStringList(key, value);
      }
    } else if (mode == Operation.delete) {
      // Altrimenti lo rimuove
      sharedPreferences.remove(key);
    }
  }

  /// Aggiorna la lista di colonne salvate
  static void updateColumnList(String columnId) async {
    SharedPreferences sharedPreferences = await getSharedPreferencesInstance();
    List<String> columns = [];
    // Recupera la lista nelle shared preferences
    if (sharedPreferences.getStringList("ColumnsId") != null) {
      columns = sharedPreferences.getStringList("ColumnsId")!;
    }

    // Se l'id in questione è presente lo elimina, altrimenti lo aggiunge
    if (columns.contains(columnId)) {
      columns.remove(columnId);
    } else {
      columns.add(columnId);
    }

    // Salva la nuova lista nelle shared preferences
    sharedPreferences.setStringList("ColumnsId", columns);
  }
}
