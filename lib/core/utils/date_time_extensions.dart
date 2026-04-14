extension DateTimeX on DateTime {
  /// Returns a ISO 8601 date string in the format YYYY-MM-DD.
  /// 
  /// This is used for consistent indexing and storage keys across the app.
  String get toIsoDateString => 
      "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

  /// Returns a [DateTime] with only the date components (Time set to 00:00:00).
  DateTime get dateOnly => DateTime(year, month, day);
}
