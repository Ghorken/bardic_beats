enum ColumnType {
  directoryColumn,
  defaultColumn,
  cloudColumn,
  bardPublicColumn,
}

extension ColumnTypeExtension on ColumnType {
  String get value {
    switch (this) {
      case ColumnType.directoryColumn:
        return "directoryColumn";
      case ColumnType.defaultColumn:
        return "defaultColumn";
      case ColumnType.cloudColumn:
        return "cloudColumn";
      case ColumnType.bardPublicColumn:
        return "bardPublicColumn";
    }
  }

  static ColumnType? fromString(String type) {
    switch (type) {
      case "directoryColumn":
        return ColumnType.directoryColumn;
      case "defaultColumn":
        return ColumnType.defaultColumn;
      case "cloudColumn":
        return ColumnType.cloudColumn;
      case "bardPublicColumn":
        return ColumnType.bardPublicColumn;
      default:
        return null;
    }
  }
}
