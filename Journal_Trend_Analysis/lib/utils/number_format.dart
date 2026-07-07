import 'package:intl/intl.dart';

String formatCompact(num value) => NumberFormat.compact().format(value);
String formatInt(num value) => NumberFormat.decimalPattern().format(value);
