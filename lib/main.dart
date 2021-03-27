import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nyrna/config.dart';
import 'package:nyrna/logger/log_file.dart';
import 'package:nyrna/nyrna.dart';
import 'package:nyrna/arguments/argument_parser.dart';
import 'package:nyrna/screens/apps_screen.dart';
import 'package:nyrna/screens/loading_screen.dart';
import 'package:nyrna/settings/screens/settings_screen.dart';
import 'package:nyrna/settings/settings.dart';
import 'package:nyrna/theme.dart';
import 'package:nyrna/window/active_window.dart';
import 'package:provider/provider.dart';

Future<void> main(List<String> args) async {
  await parseArgs(args);
  await initSettings();

  // `-t` or `--toggle` flag detected.
  if (Config.toggle) await toggleActiveWindow();

  // If not doing toggle, initialize the regular logger.
  initLogger();

  // Run main GUI interface.
  runApp(MyApp());
}

/// Parse command-line arguments.
Future<void> parseArgs(List<String> args) async {
  final parser = ArgumentParser(args);
  await parser.init();
}

/// Initialize the singleton Settings instance in settings.dart
///
/// Needed early both because it runs syncronously and would block UI,
/// as well as because the toggle feature checks for a saved process.
Future<void> initSettings() async {
  final settings = Settings.instance;
  await settings.initialize();
}

void initLogger() {
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

/// Toggle suspend / resume for the active, foreground window.
Future<void> toggleActiveWindow() async {
  Logger.root.onRecord.listen((record) {
    var msg = '${record.level.name}: ${record.time}: ${record.message}';
    final logQueue = LogFile.logs;
    logQueue.addLast(msg);
    // In case the log grows too crazy, prune for sanity.
    while (logQueue.length > 100) {
      logQueue.removeFirst();
    }
  });
  final _log = Logger('toggleActiveWindow');
  _log.info('toggleActiveWindow beginning');
  final activeWindow = ActiveWindow();
  await activeWindow.hideNyrna();
  await activeWindow.initialize();
  final successful = await activeWindow.toggle();
  if (!successful) {
    await activeWindow.removeSavedProcess();
    _log.warning('Failed to toggle active window. Cleared saved pid.');
  }
  _log.info('Finished toggle window, exiting.');
  if (Config.log) await LogFile.instance.write();
  // Not yet possible to run without GUI, so we just exit after toggling.
  exit(0);
}

/// The entrance to the main Nyrna app.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Nyrna>(create: (_) => Nyrna()),
      ],
      child: MaterialApp(
        title: 'Nyrna',
        theme: NyrnaTheme.dark,
        routes: {
          LoadingScreen.id: (context) => LoadingScreen(),
          RunningAppsScreen.id: (context) => RunningAppsScreen(),
          SettingsScreen.id: (conext) => SettingsScreen(),
        },
        home: LoadingScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
