import 'package:freecad_launcher/config.dart';

String fmtDateTime(DateTime? value) {
  if (value == null) return '';
  return mainConfig.dateTimeFormat.format(value);
}

String ellipsis(String? value, int width) {
  if (value == null) return "";
  if (value.length <= width) return value;
  return "${value.substring(0, width)}...";
}
