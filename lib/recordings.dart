import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_manager/file_manager.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'global.dart';

final player = AudioPlayer();
String filePath = '';
final List<String> audioFiles = [];

class RecordingsPage extends StatefulWidget {
  const RecordingsPage({Key? key}) : super(key: key);

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  @override
  Widget build(BuildContext context) {
    Future<List<FileSystemEntity>> load() async {
      final storage = await getExternalStorageDirectory();
      final directory = Directory('${storage?.path}${appSettings.path}');
      List<FileSystemEntity> folders =
          directory.listSync(recursive: true, followLinks: false);
      folders = folders.reversed.toList();
      return folders;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Записи'),
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: load(),
        builder: (context, folders) {
          if (folders.hasData) {
            final List<FileSystemEntity> entities = folders.data!;
            audioFiles.clear();
            for (final FileSystemEntity entity in entities) {
              if (FileManager.isFile(entity)) {
                if (['m4a', 'ogg', 'wav']
                    .contains(entity.path.split('/').last.split('.').last)) {
                  audioFiles.add(entity.path);
                }
              }
            }

            return ListView.builder(
              itemCount: entities.length,
              itemBuilder: (context, index) {
                if (FileManager.isDirectory(entities[index])) {
                  return Container();
                }
                final element = entities[index];
                final String name = element.path.split('/').last;
                return ListTile(
                  selected: filePath == entities[index].path,
                  leading: FileManager.isFile(element)
                      ? const Icon(Icons.audiotrack_outlined, size: 30)
                      : const Icon(Icons.folder_outlined, size: 30),
                  title: Text(name),
                  onTap: () {
                    if (FileManager.isDirectory(element)) {
                    } else {
                      setState(() {
                        player.setFilePath(element.path);
                        filePath = entities[index].path;
                      });
                    }
                  },
                );
              },
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
      bottomNavigationBar: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(filePath.split('/').last,
                  style: const TextStyle(fontSize: 20)),
            ),
            StreamBuilder(
                stream: player.durationStream,
                builder: (context, AsyncSnapshot<Duration?> durationSnapshot) {
                  return StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder:
                        (context, AsyncSnapshot<Duration> positionSnapshot) {
                      final int position =
                          positionSnapshot.data?.inSeconds ?? 0;
                      final int duration =
                          durationSnapshot.data?.inSeconds ?? 0;
                      return Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${position ~/ 60}:${NumberFormat('00').format(position % 60)}',
                              textAlign: TextAlign.end,
                            ),
                          ),
                          Flexible(
                            child: Slider(
                                value: position.toDouble(),
                                max: duration.toDouble(),
                                onChanged: (value) {
                                  player.seek(Duration(seconds: value.toInt()));
                                }),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${duration ~/ 60}:${NumberFormat('00').format(duration % 60)}',
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      iconSize: 30,
                      onPressed: () {
                        if (player.speed > 0.25) {
                          setState(() {
                            player.setSpeed(player.speed - 0.25);
                          });
                        }
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          player.setSpeed(1);
                        });
                      },
                      child: Text(player.speed.toString()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      iconSize: 30,
                      onPressed: () {
                        if (player.speed < 5) {
                          setState(() {
                            player.setSpeed(player.speed + 0.25);
                          });
                        }
                      },
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_outlined),
                  iconSize: 50,
                  onPressed: () {
                    setState(() {
                      final index = audioFiles.indexOf(filePath);
                      if (index != -1 && audioFiles.length > 1 && index > 0) {
                        player.setFilePath(audioFiles[index - 1]);
                        filePath = audioFiles[index - 1];
                      } else if (index != -1 && audioFiles.length > 1) {
                        player.setFilePath(audioFiles[audioFiles.length - 1]);
                        filePath = audioFiles[audioFiles.length - 1];
                      } else if (audioFiles.isNotEmpty) {
                        player.setFilePath(audioFiles[0]);
                        filePath = audioFiles[0];
                      }
                    });
                  },
                ),
                IconButton(
                  icon: player.playing
                      ? const Icon(Icons.pause_circle)
                      : const Icon(Icons.play_circle),
                  iconSize: 80,
                  onPressed: () {
                    setState(() {
                      if (player.playing) {
                        player.pause();
                      } else {
                        player.play();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_outlined),
                  iconSize: 50,
                  onPressed: () {
                    setState(
                      () {
                        final index = audioFiles.indexOf(filePath);
                        if (index != -1 &&
                            audioFiles.length > 1 &&
                            index < audioFiles.length - 1) {
                          player.setFilePath(audioFiles[index + 1]);
                          filePath = audioFiles[index + 1];
                        } else if (index != -1 && audioFiles.length > 1) {
                          player.setFilePath(audioFiles[0]);
                          filePath = audioFiles[0];
                        } else if (audioFiles.isNotEmpty) {
                          player.setFilePath(audioFiles[0]);
                          filePath = audioFiles[0];
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
