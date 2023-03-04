import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';
import 'package:record/record.dart';
import 'classes.dart';
import 'notifications.dart';

final _record = Record();
int time = 0;

@pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void record() {
  Workmanager().executeTask(
    (taskName, inputData) async {
      switch (taskName) {
        case 'startRecording':
          var appSettings = inputData!;
          final record = Record();
          File(appSettings['path'] + '/sfsf.m4a').createSync(recursive: true);
          if (appSettings['notifications']) {
            await Notifications.showRecordNotification();
          }
          break;
        case 'stopRecording':
          break;
      }
      int n = 0;
      while (n != 100000) {
        print(n);
        n++;
      }
      return Future.value(true);
    },
  );
}

Future startRecording(final Map<String, dynamic> appSettings) async {
  final AudioEncoder codec;
  switch (appSettings['codec']) {
    case 'AAC HE':
      codec = AudioEncoder.aacHe;
      break;
    case 'OPUS':
      codec = AudioEncoder.opus;
      break;
    case 'WAV':
      codec = AudioEncoder.wav;
      break;
    default:
      codec = AudioEncoder.aacLc;
  }
  final String format;
  switch (appSettings['codec']) {
    case 'WAV':
      format = 'wav';
      break;
    case 'OPUS':
      format = 'ogg';
      break;
    default:
      format = 'm4a';
  }
  final String directory = appSettings['path'];
  final DateTime dateTime = DateTime.now();
  final String fileName = '${DateFormat('dd.MM.yyyy HH-mm-ss').format(dateTime)}.$format';
  final String path;
  final f = NumberFormat('00');
  if (appSettings['sort'] == SortRecords.year.value) {
    path = '$directory/${dateTime.year}';
  } else if (appSettings['sort'] == SortRecords.yearForMonth.value) {
    path = '$directory/${dateTime.year}/${f.format(dateTime.month)}';
  } else if (appSettings['sort'] == SortRecords.yearForMonthForDay.value) {
    path = '$directory/${dateTime.year}/${f.format(dateTime.month)}/${f.format(dateTime.day)}';
  } else {
    path = directory;
  }
  final pathFile = '$path/$fileName';
  File(pathFile).createSync(recursive: true);
  await _record.start(
    path: pathFile,
    encoder: codec,
    bitRate: appSettings['bitRate'],
    samplingRate: appSettings['samplingRate'],
  );
  appSettings['status'] = RecordingStatus.record.value;
  if (appSettings['notifications']) {
    Notifications.showRecordNotification();
  }
}
