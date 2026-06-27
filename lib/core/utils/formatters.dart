import 'package:intl/intl.dart';

final _yen = NumberFormat('#,##0', 'ja_JP');
final _date = DateFormat('yyyy/MM/dd', 'ja_JP');
final _dateTime = DateFormat('yyyy/MM/dd HH:mm', 'ja_JP');
final _monthLabel = DateFormat('M月', 'ja_JP');
final _md = DateFormat('M/d', 'ja_JP');
final _time = DateFormat('HH:mm', 'ja_JP');

String yen(num v) => '¥${_yen.format(v)}';
String formatDate(DateTime d) => _date.format(d);
String formatDateTime(DateTime d) => _dateTime.format(d);
String formatTime(DateTime d) => _time.format(d);
String monthLabel(DateTime d) => _monthLabel.format(d);
String formatMd(DateTime d) => _md.format(d);
