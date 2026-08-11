class Formatters {
  const Formatters._();

  static const List<String> _units = <String>['B', 'KB', 'MB', 'GB', 'TB'];

  static String bytes(int value) {
    if (value <= 0) return '0 B';

    var size = value.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < _units.length - 1) {
      size /= 1024;
      unit++;
    }

    final digits = size >= 100 || unit == 0 ? 0 : 1;
    return '${size.toStringAsFixed(digits)} ${_units[unit]}';
  }

  static String bytesValue(int value) => bytes(value).split(' ').first;

  static String bytesUnit(int value) => bytes(value).split(' ').last;

  static String clock(Duration value) {
    final safe = value < Duration.zero ? Duration.zero : value;
    final hours = safe.inHours.toString().padLeft(2, '0');
    final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  static String timeOfDay(DateTime value) {
    final local = value.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  static String duration(Duration value) {
    if (value <= Duration.zero) return '00:00';

    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
