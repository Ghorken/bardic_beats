enum ColumnCharacteristic {
  directoryPath,
  columnColor,
  columnName,
  fontColor,
  playlistId,
  columnType,
  hasLoop,
  columnVolume,
  hasFading,
  defaultType,
  cloudType,
  repositoryOwner,
  repositoryName,
  urlsList,
  bardPublicType,
  sessionId,
  changed,
  changedState,
}

extension ColumnCharacteristicExtension on ColumnCharacteristic {
  int get position {
    switch (this) {
      case ColumnCharacteristic.directoryPath:
        return 0;
      case ColumnCharacteristic.columnColor:
        return 1;
      case ColumnCharacteristic.columnName:
        return 2;
      case ColumnCharacteristic.fontColor:
        return 3;
      case ColumnCharacteristic.playlistId:
        return 4;
      case ColumnCharacteristic.columnType:
        return 5;
      case ColumnCharacteristic.hasLoop:
        return 6;
      case ColumnCharacteristic.columnVolume:
        return 7;
      case ColumnCharacteristic.hasFading:
        return 8;
      case ColumnCharacteristic.defaultType:
        return 9;
      case ColumnCharacteristic.cloudType:
        return 10;
      case ColumnCharacteristic.repositoryOwner:
        return 11;
      case ColumnCharacteristic.repositoryName:
        return 12;
      case ColumnCharacteristic.urlsList:
        return 13;
      case ColumnCharacteristic.bardPublicType:
        return 14;
      case ColumnCharacteristic.sessionId:
        return 15;
      case ColumnCharacteristic.changed:
        return 16;
      case ColumnCharacteristic.changedState:
        return 17;
    }
  }
}
