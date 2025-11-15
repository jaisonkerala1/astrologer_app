enum ServiceType {
  live, // Audio/Video/Chat consultation
  report, // Written analysis/report
}

extension ServiceTypeExtension on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.live:
        return 'Live Consultation';
      case ServiceType.report:
        return 'Report Based';
    }
  }

  String get description {
    switch (this) {
      case ServiceType.live:
        return 'Real-time consultation via call or video';
      case ServiceType.report:
        return 'Detailed written analysis delivered as PDF';
    }
  }
}

