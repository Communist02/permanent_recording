enum RecordingStatus {
  none,
  record,
  pause,
  split;
}

enum SortRecords {
  none('none'),
  year('year'),
  yearForMonth('yearForMonth'), //Default
  yearForMonthForDay('yearForMonthForDay'),
  yearMonth('yearMonth'),
  yearMonthForDay('yearMonthForDay'),
  yearMonthDay('yearMonthDay');

  final String value;

  const SortRecords(this.value);
}

class Settings {
  String theme = 'system';
  String path = '/Permanent recording/';
  String codec = 'AAC LC';
  int bitRate = 64000;
  int samplingRate = 48000;
  int duration = 0;
  bool endDay = false;
  String sort = 'none';
  RecordingStatus status = RecordingStatus.none;

  void change({
    String? theme,
    String? path,
    String? codec,
    int? bitRate,
    int? samplingRate,
    int? duration,
    bool? endDay,
    String? sort,
    dynamic status,
  }) {
    if (theme != null) {
      this.theme = theme;
    }
    if (path != null) {
      this.path = path;
    }
    if (codec != null) {
      this.codec = codec;
    }
    if (bitRate != null) {
      this.bitRate = bitRate;
    }
    if (samplingRate != null) {
      this.samplingRate = samplingRate;
    }
    if (duration != null) {
      this.duration = duration;
    }
    if (endDay != null) {
      this.endDay = endDay;
    }
    if (sort != null) {
      this.sort = sort;
    }
    if (status != null) {
      if (status.runtimeType == String) {
        switch (status) {
          case 'record':
            this.status = RecordingStatus.record;
            break;
          default:
            this.status = RecordingStatus.none;
            break;
        }
      } else {
        this.status = status;
      }
    }
  }
}
