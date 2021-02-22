import 'dart:io' as DartIO;

import 'package:flutter/material.dart';
import 'package:nyrna/linux/linux_process.dart';
import 'package:nyrna/native_process.dart';

class Process extends ChangeNotifier {
  Process(this.pid) {
    _fetchProcess();
  }

  final int pid;

  NativeProcess _process;

  Future<String> get executable async => await _process.executable;

  Future<String> get status async => await _process.status;

  Future<bool> toggle() async {
    bool successful = await _process.toggle();
    notifyListeners();
    return successful;
  }

  void _fetchProcess() {
    switch (DartIO.Platform.operatingSystem) {
      case 'linux':
        _process = LinuxProcess(pid);
        break;
      default:
    }
  }
}
