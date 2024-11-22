import 'package:despresso/model/dose_data.dart';
import 'package:despresso/model/grinder_data.dart';
import 'package:objectbox/objectbox.dart';
import 'package:logging/logging.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/model/recipe.dart';

final log = Logger("migration");
Future<void> performV1Migration(Store store) async {
  log.info("starting v1 migration");
  final shotBox = store.box<Shot>();
  final shots = shotBox.getAll();
  final grinderDataBox = store.box<GrinderData>();
  final doseDataBox = store.box<DoseData>();

  // migrate grinder settings
  for (Shot shot in shots) {
    final doseData = DoseData(basket: "unknown");
    log.fine("have ${doseData}");
    doseDataBox.put(doseData);
    shot.doseData.target = doseData;
    final grindSettings = GrinderData(
        model: shot.grinderName,
        grindSizeSetting: shot.grinderSettings,
        feedRate: "",
        rpm: "");
    log.fine("have ${grindSettings}");
    grinderDataBox.put(grindSettings);
    shot.grinderData.target = grindSettings;
    shotBox.put(shot);
  }
  // migrate dose data
  final recipesBox = store.box<Recipe>();
  final recipes = recipesBox.getAll();
  for (Recipe recipe in recipes) {
    final doseData = DoseData(basket: "unknown");
    log.fine("have ${doseData}");
    doseDataBox.put(doseData);
    final grindSettings = GrinderData(
        model: recipe.grinderModel,
        grindSizeSetting: recipe.grinderSettings,
        feedRate: "",
        rpm: "");
    log.fine("have ${grindSettings}");
    grinderDataBox.put(grindSettings);
    recipe.grinderData.target = grindSettings;
    recipe.doseData.target = doseData;
    recipesBox.put(recipe);
  }
}
