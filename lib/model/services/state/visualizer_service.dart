import 'dart:async';
import 'dart:convert';
import 'package:despresso/model/services/state/notification_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:logging/logging.dart';
import '../../../service_locator.dart';

import 'package:http/http.dart' as http;

import '../ble/machine_service.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

class VisualizerService extends ChangeNotifier {
  late SettingsService settingsService;
  late ProfileService profileService;

  late StreamSubscription<EspressoMachineFullState> streamStateSubscription;

  final log = Logger('VisualizerAuthService');

  String _accessToken = "";

  String _idToken = "";

  String _refreshToken = "";

  String _accessTokenExpiration = "";

  Timer? _timer = null;

  VisualizerService() {
    log.info('VisualizerAuth:start');
    settingsService = getIt<SettingsService>();
    profileService = getIt<ProfileService>();
    setRefreshTimer();
  }

// These URLs are endpoints that are provided by the authorization
// server. They're usually included in the server's documentation of its
// OAuth2 API.
  final authorizationEndpoint = 'https://visualizer.coffee/oauth/authorize';
  final tokenEndpoint = 'https://visualizer.coffee/oauth/token';
  final identifier = const String.fromEnvironment('VIS_ID');
  final secret = const String.fromEnvironment('VIS_SECRET');
// This is a URL on your application's server. The authorization server
// will redirect the resource owner here once they've authorized the
// client. The redirection will include the authorization code in the
// query parameters.
  final redirectUrl = 'net.tadel.rea:/oauthredirect';

  /// A file in which the users credentials are stored persistently. If the server
  /// issues a refresh token allowing the client to refresh outdated credentials,
  /// these may be valid indefinitely, meaning the user never has to
  /// re-authenticate.

  final FlutterAppAuth appAuth = FlutterAppAuth();

  final AuthorizationServiceConfiguration _serviceConfiguration =
      const AuthorizationServiceConfiguration(
          authorizationEndpoint: 'https://visualizer.coffee/oauth/authorize',
          tokenEndpoint: 'https://visualizer.coffee/oauth/token',
          endSessionEndpoint: null);

  setRefreshTimer() {
    if (settingsService.visualizerRefreshToken.isEmpty) {
      return;
    }
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
    if (settingsService.visualizerExpiring.isEmpty) return;

    DateTime tExpire = DateTime.parse(settingsService.visualizerExpiring);

    var t = tExpire.subtract(Duration(minutes: 15)).difference(DateTime.now());
    log.info("Refreshing in $t");

    if (t.inSeconds < 0) {
      log.info("Refreshing immediately");
      refreshToken();
    } else {
      _timer = Timer(
        t,
        () {
          refreshToken();
        },
      );
    }
  }

  Future<void> createClient(String username, String password) async {
    try {
      final AuthorizationTokenResponse? response =
          await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          identifier,
          redirectUrl,
          clientSecret: secret,
          serviceConfiguration: _serviceConfiguration,
          scopes: ['write', 'upload', 'read'],
        ),
      );
      if (response != null) {
        _accessToken = response.accessToken!;
        _refreshToken = response.refreshToken!;
        _accessTokenExpiration =
            response.accessTokenExpirationDateTime!.toIso8601String();
        settingsService.visualizerAccessToken = _accessToken;
        settingsService.visualizerRefreshToken = response.refreshToken!;
        settingsService.visualizerExpiring =
            response.accessTokenExpirationDateTime!.toIso8601String();

        setRefreshTimer();
      }
    } catch (e) {
      rethrow;
    }

    return;
  }

  refreshToken() async {
    log.info("Requesting visualizer refresh token");
    final TokenResponse? response = await appAuth.token(TokenRequest(
        identifier, redirectUrl,
        clientSecret: secret,
        serviceConfiguration: _serviceConfiguration,
        refreshToken: settingsService.visualizerRefreshToken,
        scopes: ['write', 'upload', 'read']));

    if (response != null) {
      _accessToken = response.accessToken!;
      _refreshToken = response.refreshToken!;
      _accessTokenExpiration =
          response.accessTokenExpirationDateTime!.toIso8601String();
      settingsService.visualizerAccessToken = _accessToken;
      settingsService.visualizerRefreshToken = response.refreshToken!;
      settingsService.visualizerExpiring =
          response.accessTokenExpirationDateTime!.toIso8601String();
      setRefreshTimer();
    }
  }

  Future<String> sendShotToVisualizer(Shot shot) async {
    String id = '';
    try {
      if (settingsService.visualizerUpload &&
          settingsService.visualizerAccessToken.isNotEmpty) {
        String url = 'https://visualizer.coffee/api/shots/upload';
        id = await uploadShot(url, null, null, shot);
        getIt<SnackbarService>()
            .notify("Uploaded shot to Visualizer", SnackbarNotificationType.ok);
      } else {
        throw ("No visualizer access configured configured in settings");
      }
    } catch (e) {
      getIt<SnackbarService>().notify("Error uploading shot to Visualizer: $e",
          SnackbarNotificationType.severe);
    }

    try {
      if (settingsService.visualizerExtendedUpload) {
        String url = settingsService.visualizerExtendedUrl;
        String username = settingsService.visualizerExtendedUser;
        String password = settingsService.visualizerExtendedPwd;
        var id2 = await uploadShot(url, username, password, shot);
        if (id.isEmpty) {
          id = id2;
        }
      }
    } catch (e) {
      getIt<SnackbarService>().notify("Error uploading shot to custom site: $e",
          SnackbarNotificationType.severe);
    }

    return id;
  }

  Future<dynamic> uploadShot(
      String url, String? username, String? password, Shot shot) async {
    String auth = username != null
        ? 'Basic ${base64.encode(utf8.encode('$username:$password'))}'
        : 'Bearer ${settingsService.visualizerAccessToken}';

    var headers = <String, String>{
      'authorization': auth,
      'Content-Type': 'application/json',
    };

    var body = createShotJson(shot);
    log.shout(body);

    var request = http.MultipartRequest("POST", Uri.parse(url));
    request.files.add(
        http.MultipartFile.fromString("file", body, filename: "shot.json"));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode != 200) {
      var resBody = await response.stream.bytesToString();
      if (resBody.isNotEmpty && response.statusCode != 404) {
        var err = jsonDecode(resBody);
        throw ("Error in uploading: ${err['error']}");
      } else {
        log.severe("${response}");
        throw ("Error in uploading: ${response.statusCode}");
      }
    }
    var resBody = await response.stream.bytesToString();
    if (resBody.isNotEmpty) {
      var ret = jsonDecode(resBody);
      return ret["id"];
    }
    return "";
  }

  // get espresso_state_change list for Visualizer
  // N.B. I have no idea why it's formatted like this - anyone know if the
  // "shot" TCL schema is documented anywhere?
  List<double> getStateChanges(List<ShotState> states) {
    const sentinelValue = 10000000.0;
    int currentFrameNumber = states.isEmpty ? 0 : states.first.frameNumber;
    bool isPositive = true;

    return [
      0.0,
      ...states.skip(1).map((instance) {
        if (instance.frameNumber != currentFrameNumber) {
          isPositive = !isPositive;
          currentFrameNumber = instance.frameNumber;
        }

        return isPositive ? sentinelValue : sentinelValue * -1;
      })
    ];
  }

  String createShotJson(Shot shot) {
    var prof = profileService.getProfile(shot.profileId);

    var data = <String, dynamic>{
      "timestamp": (shot.date.millisecondsSinceEpoch / 1000).toStringAsFixed(0),
    };
    var settings = <String, dynamic>{
      'profile_title': prof!.title,
      "drink_tds": shot.totalDissolvedSolids,
      "drink_ey": shot.extractionYield,
      "espresso_enjoyment": shot.enjoyment * 20,
      "bean_weight": shot.doseWeight,
      "drink_weight": shot.pourWeight,
      "grinder_model": '${shot.grinderData.target?.model ?? ""} '
          '${shot.doseData.target?.basket != "unknown" ? "with ${shot.doseData.target?.basket}" : ""} ',
      "grinder_setting": '${shot.grinderData.target?.grindSizeSetting ?? ""}'
          '${shot.grinderData.target?.rpm.isEmpty == false ? " - ${shot.grinderData.target!.rpm}RPM" : ""}'
          '${shot.grinderData.target?.feedRate.isEmpty == false ? ", feed:${shot.grinderData.target!.feedRate}" : ""}',
      "bean_brand": shot.coffee.target?.roaster.target?.name ?? "unknown",
      "bean_type": shot.coffee.target?.name ?? "unknown",
      "roast_date": null,
      "espresso_notes": shot.description,
      "roast_level": shot.coffee.target?.roastLevel ?? 0,
      "bean_notes": shot.coffee.target?.description ?? "",
      "start_time": shot.date.toIso8601String(),
      "duration": shot.shotstates.last.sampleTimeCorrected,
    };
    data["app"] = <String, dynamic>{
      "app_name": "REA",
      "data": <String, dynamic>{"settings": settings}
    };

    var times = shot.shotstates
        .map((e) => e.sampleTimeCorrected.abs().toStringAsFixed(4))
        .toList();
    var stateChanges =
        getStateChanges(shot.shotstates).map((e) => e.toString()).toList();
    data["state_change"] = stateChanges;

    data["elapsed"] = times;
    data["pressure"] = <String, dynamic>{
      "pressure": shot.shotstates
          .map((e) => e.groupPressure.toStringAsFixed(2))
          .toList(),
      "goal": shot.shotstates
          .map((e) => e.setGroupPressure.toStringAsFixed(2))
          .toList()
    };
    data["flow"] = <String, dynamic>{
      "flow":
          shot.shotstates.map((e) => e.groupFlow.toStringAsFixed(2)).toList(),
      "goal": shot.shotstates
          .map((e) => e.setGroupFlow.toStringAsFixed(2))
          .toList(),
      "by_weight":
          shot.shotstates.map((e) => e.flowWeight.toStringAsFixed(2)).toList()
    };

    data["temperature"] = <String, dynamic>{
      "basket":
          shot.shotstates.map((e) => e.headTemp.toStringAsFixed(2)).toList(),
      "mix": shot.shotstates.map((e) => e.mixTemp.toStringAsFixed(2)).toList(),
      "goal":
          shot.shotstates.map((e) => e.setMixTemp.toStringAsFixed(2)).toList()
    };

    data["totals"] = <String, dynamic>{
      "weight": shot.shotstates.map((e) => e.weight.toStringAsFixed(2)).toList()
    };

    data["profile"] = jsonDecode(profileService.createProfileDefaultJson(prof));
    return jsonEncode(data);
  }

  Future<Shot> syncShotFromVisualizer(Shot shot) async {
    if (shot.visualizerId.isEmpty) {
      return shot;
    }

    String url = 'https://visualizer.coffee/api/shots/${shot.visualizerId}';

    final response = await http.get(Uri.parse(url));
    throwIf(response.statusCode != 200, response);

    final json = jsonDecode(response.body);

		final enjoyment = json["espresso_enjoyment"] as int?;
		if (enjoyment != null) {
		log.shout("enj: $enjoyment");
    shot.enjoyment = enjoyment.toDouble() / 20;
		log.shout("a: ${shot.enjoyment}");
		}


    shot.description = json["espresso_notes"] as String? ?? shot.description;

    return shot;
  }
}
