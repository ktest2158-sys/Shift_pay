class UserSettings {
  double baseRate;
  double pmLoading;
  double satLoading;
  double sunLoading;
  double leaveLoading; // NEW: Added for Annual Leave
  bool taxFreeThreshold;
  DateTime anchorDate;

  UserSettings({
    this.baseRate = 0.0,
    this.pmLoading = 0.15,
    this.satLoading = 0.50,
    this.sunLoading = 1.00,
    this.leaveLoading = 0.175, // Default to 17.5%
    this.taxFreeThreshold = true,
    required this.anchorDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'baseRate': baseRate,
      'pmLoading': pmLoading,
      'satLoading': satLoading,
      'sunLoading': sunLoading,
      'leaveLoading': leaveLoading, // NEW
      'taxFreeThreshold': taxFreeThreshold,
      'anchorDate': anchorDate.millisecondsSinceEpoch,
    };
  }

  factory UserSettings.fromMap(Map<dynamic, dynamic> map) {
    return UserSettings(
      baseRate: map['baseRate'] ?? 0.0,
      pmLoading: map['pmLoading'] ?? 0.15,
      satLoading: map['satLoading'] ?? 0.50,
      sunLoading: map['sunLoading'] ?? 1.00,
      leaveLoading: map['leaveLoading'] ?? 0.175, // NEW
      taxFreeThreshold: map['taxFreeThreshold'] ?? true,
      anchorDate: DateTime.fromMillisecondsSinceEpoch(map['anchorDate']),
    );
  }
}