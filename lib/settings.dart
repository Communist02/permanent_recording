import 'package:flutter/material.dart';
import 'package:permanent_recording/state_update.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global.dart';
import 'classes.dart';

const Map<String, List<int>> bitRates = {
  'AAC LC': [32, 48, 64, 80, 96, 128, 160, 192, 256],
  'AAC HE': [16, 24, 32, 48, 64, 80, 96],
  'OPUS': [6, 8, 12, 16, 24, 32, 48, 64, 80, 96, 128, 160, 192, 256],
  'WAV': [64, 96, 128, 160, 192, 256, 320],
};

const Map<String, int> defaultBitRates = {
  'AAC LC': 64,
  'AAC HE': 64,
  'OPUS': 32,
  'WAV': 128,
};

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> changePrefs(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value.runtimeType == String) {
      prefs.setString(key, value);
    }
    if (value.runtimeType == int) {
      prefs.setInt(key, value);
    }
    if (value.runtimeType == double) {
      prefs.setDouble(key, value);
    }
  }

  int duration = 0;
  double bitRate = bitRates[appSettings.codec]!
      .indexOf(appSettings.bitRate ~/ 1000)
      .toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: ListTile(
              leading: const Icon(Icons.color_lens_outlined, size: 40),
              title: const Text('Тема приложения'),
              subtitle: Text(appSettings.theme == 'light'
                  ? 'Светлая тема'
                  : appSettings.theme == 'dark'
                      ? 'Темная тема'
                      : 'Системная тема'),
              onTap: () {
                showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Тема приложения'),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.wb_sunny_outlined),
                        title: const Text('Светлая тема'),
                        onTap: () => Navigator.pop(context, 'light'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.nights_stay_outlined),
                        title: const Text('Темная тема'),
                        onTap: () => Navigator.pop(context, 'dark'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone_android_outlined),
                        title: const Text('Системная тема'),
                        onTap: () => Navigator.pop(context, 'system'),
                      ),
                    ],
                  ),
                ).then((value) {
                  if (value != null) {
                    setState(() {
                      appSettings.theme = value;
                      changePrefs('theme', value);
                      context.read<ChangeTheme>().change();
                    });
                  }
                });
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.audio_file_outlined, size: 40),
                  title: const Text('Формат записи'),
                  subtitle: Text(
                    appSettings.codec == 'AAC LC'
                        ? 'AAC LC (m4a)'
                        : appSettings.codec == 'AAC HE'
                            ? 'AAC HE (m4a)'
                            : appSettings.codec == 'OPUS'
                                ? 'OPUS (ogg)'
                                : 'WAV (wav)',
                  ),
                  onTap: () {
                    showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Формат записи'),
                        children: [
                          ListTile(
                            title: const Text('AAC LC (m4a)'),
                            onTap: () => Navigator.pop(context, 'AAC LC'),
                          ),
                          ListTile(
                            title: const Text('AAC HE (m4a)'),
                            onTap: () => Navigator.pop(context, 'AAC HE'),
                          ),
                          ListTile(
                            title: const Text('OPUS (ogg)'),
                            onTap: () => Navigator.pop(context, 'OPUS'),
                          ),
                          ListTile(
                            title: const Text('WAV (wav)'),
                            onTap: () => Navigator.pop(context, 'WAV'),
                          ),
                        ],
                      ),
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          appSettings.codec = value;
                          appSettings.bitRate = defaultBitRates[value]! * 1000;
                          bitRate = bitRates[appSettings.codec]!
                              .indexOf(appSettings.bitRate ~/ 1000)
                              .toDouble();
                          changePrefs('codec', appSettings.codec);
                          changePrefs('bitRates', appSettings.bitRate);
                        });
                      }
                    });
                  },
                ),
                ListTile(
                  leading: Text(
                    '${appSettings.bitRate ~/ 1000}\nkbps',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  title: const Text('Битрейт'),
                  subtitle: Slider(
                    value: bitRate,
                    max: bitRates[appSettings.codec]!.length.toDouble() - 1,
                    divisions: bitRates[appSettings.codec]!.length - 1,
                    label:
                        '${bitRates[appSettings.codec]![bitRate.toInt()]} kbps',
                    onChanged: (double value) {
                      setState(() {
                        bitRate = value;
                        appSettings.bitRate =
                            bitRates[appSettings.codec]![bitRate.toInt()] *
                                1000;
                        changePrefs(
                          'bitRate',
                          bitRates[appSettings.codec]![bitRate.toInt()] * 1000,
                        );
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Справка'),
                  subtitle: Text(
                    'Потребление памяти\n'
                    'Минута: ${(appSettings.bitRate / 8192 * 60).toStringAsFixed(2)} КБ\n'
                    'Час: ${(appSettings.bitRate / 8388608 * 3600).toStringAsFixed(2)} МБ\n'
                    'День: ${(appSettings.bitRate / 8388608 * 86400).toStringAsFixed(2)} МБ\n'
                    'Неделя: ${(appSettings.bitRate / 8388608 * 604800).toStringAsFixed(2)} МБ\n'
                    'Месяц: ${(appSettings.bitRate / 8589934592 * 2592000).toStringAsFixed(2)} ГБ\n'
                    'Год: ${(appSettings.bitRate / 8589934592 * 31536000).toStringAsFixed(2)} ГБ',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.sort_outlined, size: 40),
                  title: const Text('Сортировка по папкам'),
                  subtitle: Text(
                    appSettings.sort == SortRecords.none.value
                        ? 'Нет'
                        : appSettings.sort == SortRecords.year.value
                            ? 'По годам'
                            : appSettings.sort == SortRecords.yearForMonth.value
                                ? 'По годам и месяцам'
                                : 'По годам, месяцам и дням',
                  ),
                  onTap: () {
                    showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Сортировка по папкам'),
                        children: [
                          ListTile(
                            title: const Text('Нет'),
                            onTap: () =>
                                Navigator.pop(context, SortRecords.none.value),
                          ),
                          ListTile(
                            title: const Text('По годам'),
                            onTap: () =>
                                Navigator.pop(context, SortRecords.year.value),
                          ),
                          ListTile(
                            title: const Text('По годам и месяцам'),
                            onTap: () => Navigator.pop(
                                context, SortRecords.yearForMonth.value),
                          ),
                          ListTile(
                            title: const Text('По годам, месяцам и дням'),
                            onTap: () => Navigator.pop(
                                context, SortRecords.yearForMonthForDay.value),
                          ),
                        ],
                      ),
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          appSettings.sort = value;
                          changePrefs('sort', value);
                        });
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: ListTile(
              leading: const Icon(Icons.timer_outlined, size: 40),
              title: const Text('Максимальное время записи в один файл (мин.)'),
              subtitle: Text('${appSettings.duration ~/ 60} мин.'),
              onTap: () {
                showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Максимальное время'),
                    children: [
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            duration = int.parse(value);
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            appSettings.duration = duration * 60;
                            changePrefs('duration', appSettings.duration);
                            Navigator.pop(context);
                          });
                        },
                        child: const Text('Задать время'),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          const Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: ListTile(
              leading: Icon(Icons.info_outline, size: 40),
              title: Text('Постоянная запись звука'),
              subtitle: Text('Версия 0.5 Alpha'),
            ),
          ),
        ],
      ),
    );
  }
}
