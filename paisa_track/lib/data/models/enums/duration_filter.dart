enum DurationFilter {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom
}

extension DurationFilterExtension on DurationFilter {
  String get label {
    switch (this) {
      case DurationFilter.daily:
        return 'Daily';
      case DurationFilter.weekly:
        return 'Weekly';
      case DurationFilter.monthly:
        return 'Monthly';
      case DurationFilter.quarterly:
        return 'Quarterly';
      case DurationFilter.yearly:
        return 'Yearly';
      case DurationFilter.custom:
        return 'Custom';
    }
  }

  int get days {
    switch (this) {
      case DurationFilter.daily:
        return 1;
      case DurationFilter.weekly:
        return 7;
      case DurationFilter.monthly:
        return 30;
      case DurationFilter.quarterly:
        return 90;
      case DurationFilter.yearly:
        return 365;
      case DurationFilter.custom:
        return 0; // Custom doesn't have fixed days
    }
  }
} 