import 'package:despresso/model/services/ble/ble_service.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:logging/logging.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'service_locator.dart';
import 'package:flutter/services.dart';

Future<void> initSettings() async {
//await Settings.init(cacheProvider: )
}

Future<void> webMain(Logger log) async {
log.info("starting web app");

getIt<BLEService>().startScan();

// serve web?
}
