import 'dart:async';
// import 'package:collection/collection.dart';
import 'package:despresso/devices/abstract_comm.dart';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
// import 'package:convert/convert.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class DifluidScale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('DifluidScale');

  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID = useLongCharacteristics()
      ? Uuid.parse('000000ee-0000-1000-8000-00805f9b34fb')
      : Uuid.parse('00ee');
  // ignore: non_constant_identifier_names
  static Uuid DataUUID = useLongCharacteristics()
      ? Uuid.parse('0000aa01-0000-1000-8000-00805f9b34fb')
      : Uuid.parse('aa01');

  late ScaleService scaleService;

  final DiscoveredDevice device;

  List<int> commandBuffer = [];

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;
  DeviceCommunication connection;

  int index = 0;
  DifluidScale(this.device, this.connection) {
    scaleService = getIt<ScaleService>();
    index = getScaleIndex(device.id);
    scaleService.setScaleInstance(this, index);
    _deviceListener =
        connection.connectToDevice(id: device.id).listen((connectionState) {
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }

  void _notificationCallback(List<int> data) {
    if (data.length < 19 && data[3] != 0) return;
    if (data[17] != 0) {
      setScaleUnitToGram();
      log.info('changing scale to grams!');
    }
    var weight = getInt(data.sublist(5, 9));
    scaleService.setWeight(weight / 10, index);
  }

  int getInt(List<int> buffer) {
    ByteData bytes = ByteData(buffer.length);
    var i = 0;
    var list = bytes.buffer.asUint8List();
    for (var _ in buffer) {
      list[i] = buffer[i];
      i++;
    }
    return bytes.getInt32(0, Endian.big);
  }

  @override
  writeTare() {
    var payload = [0xDF, 0xDF, 0x03, 0x02, 0x01, 0x01, 0xC5];
    return writeToDifluidScale(payload);
  }

  startWeightNotifications() {
    log.info('enabling weight notifications');
    return writeToDifluidScale([0xDF, 0xDF, 0x01, 0x00, 0x01, 0x01, 0xC1]);
  }

  setScaleUnitToGram() {
    return writeToDifluidScale([0xDF, 0xDF, 0x01, 0x04, 0x01, 0x00, 0xC4]);
  }

  Future<void> startTimer() {
    return writeToDifluidScale([0xDF, 0xDF, 0x03, 0x02, 0x01, 0x00, 0xC4]);
  }

  Future<void> stopTimer() {
    return writeToDifluidScale([0xDF, 0xDF, 0x03, 0x01, 0x01, 0x00, 0xC3]);
  }

  Future<void> resetTimer() {
    return writeToDifluidScale([0xDF, 0xDF, 0x03, 0x02, 0x01, 0x00, 0xC4]);
  }

  Future<void> writeToDifluidScale(List<int> payload) async {
    log.info("Sending to Difluid Scale");
    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID,
        characteristicId: DataUUID,
        deviceId: device.id);
    return await connection.writeCharacteristicWithResponse(characteristic,
        value: Uint8List.fromList(payload));
  }

  void _onStateChange(DeviceConnectionState state) async {
    log.info('SCALE State changed to $state');

    switch (state) {
      case DeviceConnectionState.connecting:
        log.info('Connecting');
        scaleService.setState(ScaleState.connecting, index);
        break;

      case DeviceConnectionState.connected:
        log.info('Connected');
        scaleService.setState(ScaleState.connected, index);
        // await device.discoverAllServicesAndCharacteristics();

        final characteristic = QualifiedCharacteristic(
            serviceId: ServiceUUID,
            characteristicId: DataUUID,
            deviceId: device.id);

        _characteristicsSubscription =
            connection.subscribeToCharacteristic(characteristic).listen((data) {
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe("Subscribe to $characteristic failed: $error");
        });
        startWeightNotifications();
        setScaleUnitToGram();
        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected, index);
        scaleService.setBattery(0, index);
        log.info('Difluid Scale disconnected. Destroying');
        // await device.disconnectOrCancelConnection();
        _characteristicsSubscription.cancel();

        _deviceListener.cancel();
        notifyListeners();
        return;
      default:
        return;
    }
  }

  @override
  Future<void> timer(TimerMode start) async {
    try {
      switch (start) {
        case TimerMode.reset:
          await resetTimer();
          break;
        case TimerMode.start:
          await resetTimer();
          await startTimer();
          break;
        case TimerMode.stop:
          await stopTimer();
          break;
      }
    } catch (e) {
      log.severe("timer failed $e");
    }
  }

  @override
  Future<void> beep() {
    return Future(() => null);
  }

  @override
  Future<void> display(DisplayMode start) {
    return Future(() => null);
  }

  @override
  Future<void> power(PowerMode start) {
    return Future(() => null);
  }

  @override
  double sensorLag() {
    return 0.50;
  }
}
