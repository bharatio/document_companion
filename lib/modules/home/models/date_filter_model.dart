enum DateFilterType {
  all,
  today,
  thisWeek,
  thisMonth,
  customRange,
}

class DateFilter {
  final DateFilterType type;
  final DateTime? startDate;
  final DateTime? endDate;

  const DateFilter({
    required this.type,
    this.startDate,
    this.endDate,
  });

  bool get isActive => type != DateFilterType.all;

  static DateFilter today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return DateFilter(
      type: DateFilterType.today,
      startDate: start,
      endDate: end,
    );
  }

  static DateFilter thisWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(start.year, start.month, start.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return DateFilter(
      type: DateFilterType.thisWeek,
      startDate: startOfWeek,
      endDate: endOfWeek,
    );
  }

  static DateFilter thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return DateFilter(
      type: DateFilterType.thisMonth,
      startDate: start,
      endDate: end,
    );
  }

  static DateFilter customRange(DateTime start, DateTime end) {
    return DateFilter(
      type: DateFilterType.customRange,
      startDate: start,
      endDate: end,
    );
  }

  static DateFilter all() {
    return const DateFilter(type: DateFilterType.all);
  }
}

