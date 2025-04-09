enum BardPublicType {
  bard,
  public,
}

extension BardPublicTypeExtension on BardPublicType {
  String get value {
    switch (this) {
      case BardPublicType.bard:
        return "Bard";
      case BardPublicType.public:
        return "Public";
    }
  }

  static BardPublicType? fromString(String cloudType) {
    switch (cloudType) {
      case "Bard":
        return BardPublicType.bard;
      case "Public":
        return BardPublicType.public;
      default:
        return null;
    }
  }
}
