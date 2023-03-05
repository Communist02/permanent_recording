import 'package:flutter/material.dart';
import 'package:permanent_recording/state_update.dart';
import 'package:permanent_recording/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global.dart';
import 'home.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  appSettings.change(
    theme: prefs.getString('theme'),
    path: prefs.getString('path'),
    codec: prefs.getString('codec'),
    bitRate: prefs.getInt('bitRate'),
    samplingRate: prefs.getInt('samplingRate'),
    duration: prefs.getInt('duration'),
    endDay: prefs.getBool('endDay'),
    sort: prefs.getString('sort'),
    notifications: prefs.getBool('notifications'),
    status: prefs.getString('status'),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChangeTime()),
        ChangeNotifierProvider(
          create: (context) => ChangeTheme(),
          builder: (BuildContext context, _) {
            return MaterialApp(
              title: 'Permanent recording',
              themeMode: AppTheme.getMode(context.watch<ChangeTheme>().getTheme),
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: const HomePage(),
            );
          },
        ),
      ],
    );
  }
}
