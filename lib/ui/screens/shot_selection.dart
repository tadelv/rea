import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:despresso/generated/l10n.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/notification_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/services/state/visualizer_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/objectbox.dart';
import 'package:despresso/objectbox.g.dart';
import 'package:despresso/ui/widgets/progress_overlay.dart';
import 'package:despresso/ui/widgets/shot_graph.dart';
import 'package:logging/logging.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reactive_flutter_rating_bar/reactive_flutter_rating_bar.dart';
import 'package:share_plus/share_plus.dart';

class ShotSelectionTab extends StatefulWidget {
  const ShotSelectionTab({super.key});

  @override
  ShotSelectionTabState createState() => ShotSelectionTabState();
}

enum EditModes { show, add, edit }

class ShotSelectionTabState extends State<ShotSelectionTab> {
  final log = Logger('ShotSelectionTabState');

  late Box<Shot> shotBox;

  int selectedShot = 0;
  final TextEditingController _searchController = TextEditingController();
  late FocusNode _seachFocusNode;

  bool showPressure = true;
  bool showFlow = true;
  bool showWeight = true;
  bool showTemp = true;

  late VisualizerService visualizerService;
  late SettingsService settingsService;

  bool _busy = false;

  double _busyProgress = 0;

  ShotSelectionTabState();

  @override
  void initState() {
    super.initState();
    _seachFocusNode = FocusNode();
    shotBox = getIt<ObjectBox>().store.box<Shot>();
    visualizerService = getIt<VisualizerService>();
    settingsService = getIt<SettingsService>();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();

    log.info('Disposed coffeeselection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).mainMenuEspressoDiary),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return TextButton.icon(
                onPressed: () => _onShare(context),
                icon: const Icon(Icons.ios_share),
                label: const Text("CSV"),
              );
            },
          ),
          if (settingsService.visualizerUpload)
            TextButton(
                onPressed: () async {
                  var shot = shotBox.get(selectedShot);
                  try {
                    setState(() {
                      _busy = true;
                      _busyProgress = 1;
                    });
                    shot =
                        await visualizerService.syncShotFromVisualizer(shot!);
                    getIt<CoffeeService>().updateShot(shot);
                    setState(() {
                      _busy = false;
                      _busyProgress = 0;
                    });
                  } catch (e) {
                    getIt<SnackbarService>().notify(
                        S.of(context).screenDiaryErrorUploadingShots +
                            e.toString(),
                        SnackbarNotificationType.severe);

                    log.severe("Error syncing shots $e");
                  }
                },
                child: const Icon(Icons.cloud_download)),
          TextButton.icon(
            icon: const Icon(Icons.cloud_upload),
            label: const Text("Visualizer"),
            onPressed: () async {
              if (selectedShot == 0) {
                getIt<SnackbarService>().notify(
                    S.of(context).screenDiaryNoShotsToUploadSelected,
                    SnackbarNotificationType.info);

                return;
              }
              try {
                setState(() {
                  _busy = true;
                });
                setState(() {
                  _busyProgress = 1;
                });
                var shot = shotBox.get(selectedShot);
                var id = await visualizerService.sendShotToVisualizer(shot!);
                shot.visualizerId = id;
                shotBox.put(shot);
                getIt<SnackbarService>()
                    // ignore: use_build_context_synchronously
                    .notify(S.of(context).screenDiarySuccessUploadingYourShots,
                        SnackbarNotificationType.info);
              } catch (e) {
                getIt<SnackbarService>().notify(
                    S.of(context).screenDiaryErrorUploadingShots + e.toString(),
                    SnackbarNotificationType.severe);

                log.severe("Error uploading shots $e");
              }
              setState(() {
                _busy = false;
                _busyProgress = 0;
              });
            },
          ),
        ],
      ),
      body: ModalProgressOverlay(
        inAsyncCall: _busy,
        progressIndicator: CircularProgressIndicator(
          // strokeWidth: 15,
          value: _busyProgress,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 445,
                child: Column(children: [
                  TextField(
                      focusNode: _seachFocusNode,
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(
                          Icons.search,
                        ),
                        suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _seachFocusNode.unfocus();
                            }),
                      )),
                  Flexible(
                      child: StreamBuilder<List<Shot>>(
                          stream: getShots(),
                          builder: (context, snapshot) => ListView.builder(
                              shrinkWrap: true,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              itemCount:
                                  snapshot.hasData ? snapshot.data!.length : 0,
                              itemBuilder:
                                  _shotListBuilder(snapshot.data ?? []))))
                ])),
            Expanded(
              child: selectedShot == 0
                  ? Text(S.of(context).screenDiaryNothingSelected)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: 1,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                  bottomLeft: Radius.circular(32),
                                ),
                                child: ListTile(
                                  title: ShotGraph(
                                      key: UniqueKey(),
                                      id: selectedShot,
                                      overlayIds: null,
                                      showFlow: showFlow,
                                      showPressure: showPressure,
                                      showWeight: showWeight,
                                      showTemp: showTemp),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Shot>> getShots() {
    // Query for all notes, sorted by their date.
    // https://docs.objectbox.io/queries
    final builder = shotBox.query().order(Shot_.date, flags: Order.descending);
    // Build and watch the query,
    // set triggerImmediately to emit the query immediately on listen.
    final String shotSearchFilter = _searchController.text;
    return builder
        .watch(triggerImmediately: true)
        .map((query) => query.find().where((shot) {
              return shot.recipe.target!.name
                      .toLowerCase()
                      .contains(shotSearchFilter) ||
                  shot.coffee.target!.name
                      .toLowerCase()
                      .contains(shotSearchFilter) ||
                  shot.coffee.target!.roaster.target!.name
                      .toLowerCase()
                      .contains(shotSearchFilter) ||
                  shot.recipe.target!.profileName.contains(shotSearchFilter);
              // etc etc
            }).toList());
  }

  Dismissible Function(BuildContext, int) _shotListBuilder(List<Shot> shots) =>
      (BuildContext context, int index) => Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.startToEnd,
            onDismissed: (_) {
              setState(() {
                var id = shots[index].id;
                //selectedShots.removeWhere((element) => element == id);
                if (id == selectedShot) {
                  selectedShot = 0;
                }
                shotBox.remove(id);
              });
            },
            background: Container(
              color: Colors.red,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: ListTile(
                  key: Key('list_item_${shots[index].id}'),
                  title: Text(
                    getIt<ProfileService>()
                            .profiles
                            .firstWhereOrNull(
                                (e) => e.id == shots[index].profileId)
                            ?.title ??
                        shots[index].profileId,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat().format(shots[index].date)),
                      Text(
                        '${shots[index].coffee.target?.name ?? 'no coffee'} (${shots[index].coffee.target?.roaster.target?.name ?? 'no roaster'})',
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${shots[index].pourWeight.toStringAsFixed(1)}g in ${shots[index].pourTime.toStringAsFixed(1)}s ',
                          ),
                          if (shots[index].enjoyment > 0)
                            RatingBarIndicator(
                              rating: shots[index].enjoyment,
                              itemBuilder: (context, index) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 20.0,
                              direction: Axis.horizontal,
                            ),
                        ],
                      ),
                    ],
                  ),
                  // trailing: OutlinedButton(
                  //   onPressed: () {},
                  //   child: Icon(Icons.delete_forever),
                  // ),
                  onTap: () {
                    setSelection(shots[index].id);
                  },
                  selected: shots[index].id == selectedShot),
            ),
          );

  setSelection(int id) {
    selectedShot = id;
    setState(() {});
  }

  _onShare(BuildContext context) async {
    // _onShare method:
    if (selectedShot == 0) return;
    final box = context.findRenderObject() as RenderBox?;
    var shot = shotBox.get(selectedShot);
    var list = shot!.shotstates.toList().map((entry) {
      return [
        shot.date,
        shot.coffee.target!.name,
        shot.pourWeight,
        shot.pourTime,
        shot.profileId,
        entry.sampleTimeCorrected,
        entry.frameNumber,
        entry.weight,
        entry.flowWeight,
        entry.headTemp,
        entry.mixTemp,
        entry.groupFlow,
        entry.groupPressure,
        entry.setGroupFlow,
        entry.setGroupPressure,
        entry.setHeadTemp,
        entry.setMixTemp,
      ];
    }).toList();
    var header = [
      "date",
      "name",
      "pourWeight",
      "pourTime",
      "profileId",
      "sampleTimeCorrected",
      "frameNumber",
      "weight",
      "flowWeight",
      "headTemp",
      "mixTemp",
      "groupFlow",
      "groupPressure",
      "setGroupFlow",
      "setGroupPressure",
      "setHeadTemp",
      "setMixTemp",
    ];
    list.insert(0, header);
    String csv = const ListToCsvConverter().convert(list, fieldDelimiter: ";");

    final List<int> codeUnits = csv.codeUnits;
    final Uint8List unit8List = Uint8List.fromList(codeUnits);
    var xfile = XFile.fromData(unit8List, mimeType: "text/csv");

    await Share.shareXFiles(
      [xfile],
      subject: "text/comma_separated_values/csv",
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }
}
