import 'dart:async';
import 'dart:io';

import 'package:despresso/gui_app.dart';
import 'package:despresso/web_app.dart';



Future<void> main() async {
  if (Platform.isLinux) {
    return webMain();
  } else {
    return guiMain();
  }
}
