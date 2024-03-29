import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String toShortTimestampString({DateTime? currentTime}) {
    currentTime ??= DateTime.now();

    late DateFormat format;

    if (year == currentTime.year) {
      format = month == currentTime.month && day == currentTime.day
          ? DateFormat.Hm()
          : DateFormat.Md().add_Hm();
    } else {
      format = DateFormat.yMd().add_Hm();
    }

    return format.format(this);
  }

  String toLongTimestampString() {
    DateFormat format = DateFormat.yMd().add_Hm();
    return format.format(this);
  }
}
