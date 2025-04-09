enum CloudType {
  gitHubRepository,
  urls,
}

extension CloudTypeExtension on CloudType {
  String get value {
    switch (this) {
      case CloudType.gitHubRepository:
        return "GitHub Repository";
      case CloudType.urls:
        return "Urls list";
    }
  }

  static CloudType? fromString(String cloudType) {
    switch (cloudType) {
      case "GitHub Repository":
        return CloudType.gitHubRepository;
      case "Urls list":
        return CloudType.urls;
      default:
        return null;
    }
  }
}
