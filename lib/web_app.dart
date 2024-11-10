import 'package:despresso/model/services/ble/ble_service.dart';
import 'dart:io';
import 'package:logging/logging.dart';
import 'service_locator.dart';
import 'package:flutter/services.dart';

Future<void> initSettings() async {
//await Settings.init(cacheProvider: )
}

Future<void> webMain() async {
  final log = Logger('main');
  log.info("starting web app");

  getIt<BLEService>().startScan();

// serve web?
}
