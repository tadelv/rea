import 'dart:convert';
import 'dart:ffi';

import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../../../service_locator.dart';

// FrameFlag of zero and pressure of 0 means end of shot, unless we are at the tenth frame, in which case
// it's the end of shot no matter what
// ignore: constant_identifier_names
const int CtrlF = 0x01; // Are we in Pressure or Flow priority mode?
// ignore: constant_identifier_names
const int DoCompare =
    0x02; // Do a compare, early exit current frame if compare true
// ignore: constant_identifier_names
const int DC_GT =
    0x04; // If we are doing a compare, then 0 = less than, 1 = greater than
// ignore: constant_identifier_names
const int DC_CompF = 0x08; // Compare Pressure or Flow?
// ignore: constant_identifier_names
const int TMixTemp =
    0x10; // Disable shower head temperature compensation. Target Mix Temp instead.
// ignore: constant_identifier_names
const int Interpolate = 0x20; // Hard jump to target value, or ramp?
// ignore: constant_identifier_names
const int IgnoreLimit = 0x40; // Ignore minimum pressure and max flow settings

class ProfileService extends ChangeNotifier {
  final log = Logger('ProfileService');

  De1ShotProfile? currentProfile;
  late SettingsService settings;
  List<De1ShotProfile> defaultProfiles = <De1ShotProfile>[];

  List<De1ShotProfile> profiles = <De1ShotProfile>[];

  ProfileService() {
    init();
  }

  void init() async {
    settings = getIt<SettingsService>();

    var profileId = settings.currentProfile;

    await _prepareProfiles();

// Add defaultprofile if not already modified;

    currentProfile = profiles.first;
    if (profileId.isNotEmpty) {
      try {
        currentProfile =
            profiles.where((element) => element.id == profileId).first;
      } catch (_) {}
      log.info("Profile ${currentProfile!.shotHeader.title} loaded");
    }
    notifyListeners();
  }

  Future<void> _prepareProfiles() async {
    profiles = [];
    defaultProfiles = [];
    await loadAllDefaultProfiles();
    log.info('Profiles loaded');

    try {
      var savedProfilesList = await getSavedProfileFiles();

      for (var savedProfile in savedProfilesList) {
        log.info(savedProfile.path);
        var i = savedProfile.path.lastIndexOf('/');
        var file = savedProfile.path.substring(i);
        try {
          var loaded = await loadProfileFromDocuments(file);
          log.info("Saved profile loaded $loaded");
          profiles.add(loaded);
          // var defaultProfile = defaultProfiles.where((element) => element.id == loaded.id);
          // if (defaultProfile.isEmpty) {
          //   profiles.add(loaded);
          // } else {
          //   profiles.add(defaultProfile.first);
          // }
        } catch (ex) {
          log.info("Error loading profile $ex");
        }
      }
      // dirs.forEach((element) => {
      //   loadUserProfile(element.path);
      // });
    } catch (ex) {
      log.info("List files $ex");
    }
    for (var prof in defaultProfiles) {
      if (profiles.where((element) => element.id == prof.id).isEmpty) {
        profiles.add(prof);
      }
    }
  }

  void notify() {
    notifyListeners();
  }

  void setProfileFromId(String profileId) {
    var found = getProfile(profileId);
    if (found != null) {
      setProfile(found);
    }
  }

  De1ShotProfile? getProfile(String profileId) {
    var found = profiles.firstWhereOrNull((element) => profileId == element.id);
    return found;
  }

  void setProfile(De1ShotProfile profile) {
    currentProfile = profile;

    settings.currentProfile = profile.id;
    log.info("Profile selected and saved ${profile.id}");
    notify();
  }

  saveAsNew(De1ShotProfile profile) {
    log.info("Saving as a new profile");
    profile.isDefault = false;
    profile.id = const Uuid().v1().toString();
    save(profile);
  }

  save(De1ShotProfile profile) async {
    log.info("Saving as a existing profile to documents region");
    profile.isDefault = false;
    try {
      await saveProfileToDocuments(profile, profile.id);
      currentProfile = profile;
      if (profiles.firstWhereOrNull((element) => element.id == profile.id) ==
          null) {
        log.info("New profile saved");
        profiles.add(profile);
      } else {
        var index = profiles.indexWhere((element) => element.id == profile.id);
        profiles[index] = profile;
      }
      log.info("Saving profile done");
    } catch (e) {
      log.severe("Error saving profile $e");
    }

    notify();
  }

  delete(De1ShotProfile profile) async {
    log.info("Delete as a existing profile to documents region");
    profile.isDefault = false;
    currentProfile = profile;
    var toBeDeleted =
        profiles.firstWhereOrNull((element) => element.id == profile.id);

    if (toBeDeleted != null) {
      var i = profiles.indexOf(toBeDeleted);

      await deleteProfileFromDocuments(profile, profile.id);
      await _prepareProfiles();

      if (i < profiles.length) {
        currentProfile = profiles[i];
      } else {
        currentProfile = profiles[0];
      }
      log.info("New profile saved");
    }

    notify();
  }

  Future<List<FileSystemEntity>> getSavedProfileFiles() async {
    final dir = "${(await getApplicationDocumentsDirectory()).path}/profiles";

    final Directory appDocDirFolder = Directory(dir);
    if (!appDocDirFolder.existsSync()) {
      appDocDirFolder.create(recursive: true);
    }
    String pdfDirectory = '$dir/';

    final myDir = Directory(pdfDirectory);

    var dirs = myDir.listSync(recursive: true, followLinks: false);

    return dirs;
  }

  Future<De1ShotProfile> loadProfileFromDocuments(String fileName) async {
    try {
      log.info("Loading shot: $fileName");
      final directory = await getApplicationDocumentsDirectory();
      log.info("LoadingFrom path:${directory.path}");
      var file = File('${directory.path}/profiles/$fileName');
      if (await file.exists()) {
        var json = file.readAsStringSync();

        Map<String, dynamic> map = jsonDecode(json);
        var data = De1ShotProfile.fromJson(map);

        log.info("Loaded Profile: ${data.id} ${data.title}");
        return data;
      } else {
        log.info("File $fileName not existing");
        throw Exception("File not found");
      }
    } catch (ex) {
      log.info("loading error $ex");
      Future.error("Error loading filename $ex");
      rethrow;
    }
  }

  Future deleteProfileFromDocuments(
      De1ShotProfile profile, String filename) async {
    log.info("Storing shot: ${profile.id}");

    final directory = await getApplicationDocumentsDirectory();
    log.info("Storing to path:${directory.path}");
    final Directory appDocDirFolder = Directory('${directory.path}/profiles/');

    if (!appDocDirFolder.existsSync()) {
      appDocDirFolder.create(recursive: true);
    }

    var file = File('${directory.path}/profiles/$filename');
    if (await file.exists()) {
      file.deleteSync();
      log.info("File $filename deleted");
    }
    return Future(() => null);
  }

  Future<File> saveProfileToDocuments(
      De1ShotProfile profile, String filename) async {
    log.info("Storing shot: ${profile.id}");

    final directory = await getApplicationDocumentsDirectory();
    log.info("Storing to path:${directory.path}");
    final Directory appDocDirFolder = Directory('${directory.path}/profiles/');

    if (!appDocDirFolder.existsSync()) {
      appDocDirFolder.create(recursive: true);
    }

    var file = File('${directory.path}/profiles/$filename');
    if (await file.exists()) {
      file.deleteSync();
    }
    await file.create();

    var json = jsonEncode(profile.toJson());
    log.info("Save json $json");

    return file.writeAsString(json, flush: true);
  }

  Future<void> loadAllDefaultProfiles() async {
    var assets = await rootBundle.loadString('AssetManifest.json');
    Map jsondata = json.decode(assets);
    List get =
        jsondata.keys.where((element) => element.endsWith(".json")).toList();

    for (var file in get) {
      var rawJson = await rootBundle.loadString(file);
      try {
        defaultProfiles.add(parseDefaultProfile(rawJson, true));
      } catch (ex) {
        log.info("Profile parse error: $ex");
      }
    }
    log.info('all profiles loaded');
  }

  // TODO: use toJson on profile once migrated to json v2 completely
  De1ShotProfile parseDefaultProfile(String json, bool isDefault) {
    De1ShotHeaderClass header = De1ShotHeaderClass();
    List<De1ShotFrameClass> frames = <De1ShotFrameClass>[];
    var p = De1ShotProfile(header, frames);
    if (!shotJsonParser(json, p)) throw ("Error");

    p.isDefault = isDefault;

    log.fine("$header $frames");

    return p;
  }

  static bool shotJsonParser(String jsonStr, De1ShotProfile profile) {
    var jsonMap = jsonDecode(jsonStr);
    return shotJsonParserAdvanced(jsonMap, profile);

    // return ShotJsonParserAdvanced(json_obj, shot_header, shot_frames, shot_exframes);
  }

  static double dynamic2Double(dynamic dynData) {
    dynamic d = dynData;

    if (d is double || d is int) {
      return d.toDouble();
    } else if (d is String) {
      return double.parse(d);
    } else {
      return double.negativeInfinity;
    }
  }

  static String dynamic2String(dynamic dynData) {
    dynamic d = dynData;

    if (d is String) {
      return d;
    } else {
      return "";
    }
  }

  String createProfileDefaultJson(De1ShotProfile prof) {
    var map = <String, dynamic>{};
    map["title"] = prof.title;
    map["author"] = prof.shotHeader.author;
    map["notes"] = prof.shotHeader.notes;
    map["beverage_type"] = prof.shotHeader.beverageType;
    map["id"] = prof.id;
    map["tank_temperature"] = prof.shotHeader.tankTemperature;
    map["target_weight"] = prof.shotHeader.targetWeight;
    map["target_volume"] = prof.shotHeader.targetVolume;
    map["target_volume_count_start"] = prof.shotHeader.targetVolumeCountStart;
    map["legacy_profile_type"] = prof.shotHeader.legacyProfileType;
    map["type"] = prof.shotHeader.type;
    map["lang"] = prof.shotHeader.lang;
    map["steps"] = prof.shotFrames.map((element) {
      var elementMap = <String, dynamic>{};
      elementMap["name"] = element.name;
      elementMap["temperature"] = element.temp.toString();
      elementMap["weight"] = element.maxWeight.toString();
      elementMap["sensor"] =
          element.sensor == De1SensorType.water ? "water" : "coffee";
      elementMap["pump"] = element.pump.name;
      elementMap["transition"] = element.transition.name;
      elementMap["seconds"] = element.frameLen.toString();
      elementMap["volume"] = element.maxVol.toString();
			elementMap[element.pump == De1PumpMode.pressure ? "pressure" : "flow"] = element.setVal.toString();
      if (element.limiter != null) {
        elementMap["limiter"] = element.limiter;
      }

      if (element.flag & DoCompare == DoCompare) {
        var exitMap = <String, dynamic>{};
        exitMap["condition"] = element.flag & DC_GT == DC_GT ? "over" : "under";
        exitMap["type"] =
            element.flag & DC_CompF == DC_CompF ? "flow" : "pressure";
        exitMap["value"] = element.triggerVal.toString();
				elementMap["exit"] = exitMap;
      }
			return elementMap;
    }).toList();

		return jsonEncode(map);
  }

  static bool shotJsonParserAdvanced(
    Map<String, dynamic> json,
    De1ShotProfile profile,
  ) {
    Logger log = Logger("shotjsonparser");

    De1ShotHeaderClass shotHeader = profile.shotHeader;
    List<De1ShotFrameClass> shotFrames = profile.shotFrames;
    if (!json.containsKey("version")) return false;
    if (dynamic2Double(json["version"]) != 2.0) return false;

    profile.id = dynamic2String(json["id"]);
    shotHeader.version = dynamic2String(json["version"]);

    shotHeader.hidden = dynamic2Double(json["hidden"]).toInt();
    shotHeader.type = dynamic2String(json["type"]);
    shotHeader.type = dynamic2String(json["type"]);
    shotHeader.lang = dynamic2String(json["lang"]);
    shotHeader.legacyProfileType = dynamic2String(json["legacy_profile_type"]);
    shotHeader.targetWeight = dynamic2Double(json["target_weight"]);
    shotHeader.targetVolume = dynamic2Double(json["target_volume"]);
    shotHeader.targetVolumeCountStart =
        dynamic2Double(json["target_volume_count_start"]);
    shotHeader.tankTemperature = dynamic2Double(json["tank_temperature"]);
    shotHeader.title = dynamic2String(json["title"]);
    shotHeader.author = dynamic2String(json["author"]);
    shotHeader.notes = dynamic2String(json["notes"]);
    shotHeader.beverageType = dynamic2String(json["beverage_type"]);
    if (profile.id.isEmpty) {
      profile.id = shotHeader.title
          .replaceAll("\\/", "")
          .replaceAll(" ", "")
          .replaceAll("´", "")
          .replaceAll("/", "")
          .replaceAll("'", "")
          .replaceAll(",", "");
      log.info("Saving new profile id as ${profile.id}");
    }
    if (!json.containsKey("steps")) return false;
    for (Map<String, dynamic> frameData in json["steps"]) {
      if (!frameData.containsKey("name")) return false;

      De1ShotFrameClass frame = De1ShotFrameClass();
      var features = IgnoreLimit;

      frame.pump = dynamic2String(frameData["pump"]) == "flow"
          ? De1PumpMode.flow
          : De1PumpMode.pressure;
      frame.name = dynamic2String(frameData["name"]);
      frame.maxWeight = dynamic2Double(frameData["weight"]);

      // flow control

      if (frame.pump == De1PumpMode.flow) {
        features |= CtrlF;
        if (!frameData.containsKey("flow")) return false;
        var flow = dynamic2Double(frameData["flow"]);
        if (flow == double.negativeInfinity) return false;
        frame.setVal = flow;
      } else {
        if (!frameData.containsKey("pressure")) return false;
        var pressure = dynamic2Double(frameData["pressure"]);
        if (pressure == double.negativeInfinity) return false;
        frame.setVal = pressure;
      }

      // use boiler water temperature as the goal
      if (!frameData.containsKey("sensor")) return false;
      var sensor = dynamic2String(frameData["sensor"]);
      if (sensor == "") return false;
      if (sensor == "water") features |= TMixTemp;
      frame.sensor =
          sensor == 'water' ? De1SensorType.water : De1SensorType.coffee;

      if (!frameData.containsKey("transition")) return false;
      var transition = dynamic2String(frameData["transition"]);
      if (transition == "") return false;

      if (transition == "smooth") features |= Interpolate;
      frame.transition =
          transition == 'smooth' ? De1Transition.smooth : De1Transition.fast;
      // "move on if...."
      if (frameData.containsKey("exit")) {
        var exitData = frameData["exit"];

        if (!exitData.containsKey("type")) return false;
        if (!exitData.containsKey("condition")) return false;
        if (!exitData.containsKey("value")) return false;

        var exitType = dynamic2String(exitData["type"]);
        var exitCondition = dynamic2String(exitData["condition"]);
        var exitValue = dynamic2Double(exitData["value"]);

        if (exitType == "pressure" && exitCondition == "under") {
          features |= DoCompare;
          frame.triggerVal = exitValue;
        } else if (exitType == "pressure" && exitCondition == "over") {
          features |= DoCompare | DC_GT;
          frame.triggerVal = exitValue;
        } else if (exitType == "flow" && exitCondition == "under") {
          features |= DoCompare | DC_CompF;
          frame.triggerVal = exitValue;
        } else if (exitType == "flow" && exitCondition == "over") {
          features |= DoCompare | DC_GT | DC_CompF;
          frame.triggerVal = exitValue;
        } else {
          return false;
        }
      } else {
        frame.triggerVal = 0;
      } // no exit condition was checked

      // "limiter"
      var limiterValue = double.negativeInfinity;
      var limiterRange = double.negativeInfinity;

      if (frameData.containsKey("limiter")) {
        var limiterData = frameData["limiter"];

        if (!limiterData.containsKey("value")) return false;
        if (!limiterData.containsKey("range")) return false;

        limiterValue = dynamic2Double(limiterData["value"]);
        limiterRange = dynamic2Double(limiterData["range"]);
        frame.limiterValue = limiterValue;
        frame.limiterRange = limiterRange;
      }

      if (!frameData.containsKey("temperature")) return false;
      if (!frameData.containsKey("seconds")) return false;

      var temperature = dynamic2Double(frameData["temperature"]);
      if (temperature == double.negativeInfinity) return false;
      var seconds = dynamic2Double(frameData["seconds"]);
      if (seconds == double.negativeInfinity) return false;

      // MaxVol for the first frame only
      double inputMaxVol = 0.0;
      if (frameData.containsKey("volume")) {
        inputMaxVol = dynamic2Double(frameData["volume"]);
        if (inputMaxVol == double.negativeInfinity) inputMaxVol = 0.0;
      }

      frame.flag = features;
      frame.temp = temperature;
      frame.frameLen = seconds;
      frame.maxVol = inputMaxVol;
      shotFrames.add(frame);
    }

    // header
    shotHeader.numberOfFrames = shotFrames.length;
    shotHeader.numberOfPreinfuseFrames =
        shotHeader.targetVolumeCountStart.toInt();

    return true;
  }

  Future<De1ShotProfile> getJsonProfileFromVisualizerShortCode(
      String shortCode) async {
    if (shortCode.length == 4) {
      try {
        var url = Uri.https(
            'visualizer.coffee', '/api/shots/shared', {'code': shortCode});
        var response = await http.get(url);
        if (response.statusCode != 200) {
          throw ("Shot not found");
        }
        var profileUrl = jsonDecode(response.body)['profile_url'] + '.json';
        var profileResponse = await http.get(Uri.parse(profileUrl));

        return parseDefaultProfile(profileResponse.body, false);
      } catch (e) {
        log.warning(e);
        rethrow;
      }
    } else {
      throw ("Error in code");
    }
  }

  Future<Uint8List> getProfilesBackup() async {
    final files = await getSavedProfileFiles();
    // build json array
    Map<String, String> jsonMap = files.fold({}, (json, file) {
      if (!file.existsSync()) {
        return json;
      }
      File f = File(file.path);
      json[file.uri.toString()] = f.readAsStringSync();
      return json;
    });
    final jsonData = jsonEncode(jsonMap);
    return Uint8List.fromList(utf8.encode(jsonData));
  }

  Future<void> setProfilesFromBackup(Uint8List dataList) async {

    String profileList = utf8.decode(dataList, allowMalformed: true);
    Map<String, dynamic> jsonMap = jsonDecode(profileList);
    log.fine("got list: $jsonMap");

    final directory = await getApplicationDocumentsDirectory();
    log.info("Storing to path:${directory.path}");
    final Directory appDocDirFolder = Directory('${directory.path}/profiles/');

    if (!appDocDirFolder.existsSync()) {
      appDocDirFolder.create(recursive: true);
    }
    for (var key in jsonMap.keys) {
      String filename = key.substring(key.lastIndexOf("/"));
      File f = File("${appDocDirFolder.path}/$filename");
      await f.writeAsString(jsonMap[key]!, encoding: utf8);
    }
  }
}
