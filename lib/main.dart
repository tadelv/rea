import 'dart:async';
import 'dart:io';

import 'package:despresso/gui_app.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:logging/logging.dart';

import 'package:despresso/service_locator.dart';

import 'logger_util.dart';



Future<void> main() async {
  initLogger();

  final log = Logger("main");

if (Platform.isLinux) {
 //
} else {
 return guiMain(log);
}
}


