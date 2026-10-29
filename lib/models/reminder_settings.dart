class ReminderSettings {
  const ReminderSettings({this.leadDays = 2, this.hour = 9});
  final int leadDays; // days before expiry
  final int hour; // local hour of day, 0–23

  ReminderSettings copyWith({int? leadDays, int? hour}) =>
      ReminderSettings(leadDays: leadDays ?? this.leadDays, hour: hour ?? this.hour);
}
