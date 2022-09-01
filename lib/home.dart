import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'classes.dart';
import 'fraud.dart';
import 'settings.dart';
import 'recordings.dart';
import 'global.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifications.dart';

final _record = Record();
bool _isTimer = false;
int time = 0;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future record() async {
    final AudioEncoder codec;
    switch (appSettings.codec) {
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
    switch (appSettings.codec) {
      case 'WAV':
        format = 'wav';
        break;
      case 'OPUS':
        format = 'ogg';
        break;
      default:
        format = 'm4a';
    }
    final String directory;
    if (appSettings.path.isEmpty) {
      final storage = await getExternalStorageDirectory();
      directory = '${storage?.path}/Recordings';
    } else {
      directory = appSettings.path;
    }
    final DateTime dateTime = DateTime.now();
    final String fileName =
        '${DateFormat('dd.MM.yyyy HH-mm-ss').format(dateTime)}.$format';
    final String path;
    final f = NumberFormat('00');
    if (appSettings.sort == SortRecords.year.value) {
      path = '$directory${dateTime.year}';
    } else if (appSettings.sort == SortRecords.yearForMonth.value) {
      path = '$directory${dateTime.year}/${f.format(dateTime.month)}';
    } else if (appSettings.sort == SortRecords.yearForMonthForDay.value) {
      path =
          '$directory${dateTime.year}/${f.format(dateTime.month)}/${f.format(dateTime.day)}';
    } else {
      path = directory;
    }
    final pathFile = '$path/$fileName';
    print(pathFile);
    File(pathFile).createSync(recursive: true);
    await _record.start(
      path: pathFile,
      encoder: codec,
      bitRate: appSettings.bitRate,
      samplingRate: appSettings.samplingRate,
    );
    appSettings.status = RecordingStatus.record;
    if (appSettings.notifications) {
      Notifications.showRecordNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );

    Future startRecording({bool split = false}) async {
      if (!split) {
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }
        if (await Permission.microphone.isDenied) {
          await Permission.microphone.request();
        }
      }
      if (await Permission.storage.isGranted &&
          await Permission.microphone.isGranted) {
        await record();
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('status', 'record');
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Нет прав доступа'),
            content: const Text(
                'Для записи звука необходимо предоставить доступ к микрофону и файловому хранилищу'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ок'),
              ),
            ],
          ),
        );
      }
      setState(() {});
    }

    Future pauseRecording() async {
      await _record.pause();
      setState(() {
        appSettings.status = RecordingStatus.pause;
      });
    }

    Future resumeRecording() async {
      await _record.resume();
      setState(() {
        appSettings.status = RecordingStatus.record;
      });
    }

    void stopRecording() async {
      await _record.stop();
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('status', 'none');
      setState(() {
        appSettings.status = RecordingStatus.none;
        time = 0;
      });
      Notifications.deleteNotification(0);
    }

    Future splitRecording() async {
      await _record.stop();
      await record();
      setState(() {
        time = 0;
      });
    }

    String timeFormat(final int time) {
      final f = NumberFormat('00');
      return '${f.format(time ~/ 3600)}:${f.format(time ~/ 60 % 60)}:${f.format(time % 60)}';
    }

    Future checkRecording() async {
      if (!await _record.isRecording() &&
          appSettings.status == RecordingStatus.record) {
        startRecording();
      }
    }

    if (!_isTimer) {
      _isTimer = true;
      Timer.periodic(const Duration(seconds: 1), (timer) {
        checkRecording();
        if (appSettings.status == RecordingStatus.record) {
          if (appSettings.duration != 0 && time >= appSettings.duration) {
            _record.stop();
            setState(() {
              time = 0;
              record();
            });
          } else {
            setState(() {
              time++;
            });
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Запись звука'),
        leading: IconButton(
          icon: const Icon(Icons.format_list_bulleted_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecordingsPage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.android_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FraudPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
            '${timeFormat(time)}\n'
            '${(appSettings.bitRate * time / 8388608).toStringAsFixed(2)} МБ',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 50)),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${appSettings.codec} / ${appSettings.bitRate ~/ 1000} kbps'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.repeat),
                iconSize: 50,
                onPressed: appSettings.status == RecordingStatus.none
                    ? null
                    : splitRecording,
              ),
              IconButton(
                icon: appSettings.status == RecordingStatus.none
                    ? const Icon(Icons.fiber_manual_record, color: Colors.red)
                    : const Icon(Icons.stop_circle),
                iconSize: 100,
                onPressed: () {
                  if (appSettings.status == RecordingStatus.none) {
                    startRecording();
                  } else {
                    stopRecording();
                  }
                },
              ),
              IconButton(
                iconSize: 50,
                icon: appSettings.status == RecordingStatus.pause
                    ? const Icon(Icons.play_arrow)
                    : const Icon(Icons.pause),
                onPressed: appSettings.status == RecordingStatus.none
                    ? null
                    : appSettings.status == RecordingStatus.pause
                        ? resumeRecording
                        : pauseRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
