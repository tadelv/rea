// ignore_for_file: unused_import

import 'dart:convert';

import 'dart:io';

import 'package:despresso/logger_util.dart';
import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/dose_data.dart';
import 'package:despresso/model/grinder_data.dart';
import 'package:despresso/model/recipe.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/services/state/visualizer_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/objectbox.dart';
import 'package:despresso/objectbox.g.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:objectbox/internal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/extension.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../service_locator.dart';

class CoffeeService extends ChangeNotifier {
  final log = Logger('CoffeeService');
  late ObjectBox objectBox;

  late Box<Coffee> coffeeBox;
  late Box<Roaster> roasterBox;
  late Box<Recipe> recipeBox;
  late Box<Shot> shotBox;
  late Box<GrinderData> grinderDataBox;
  late Box<DoseData> doseDataBox;

  int selectedRoasterId = 0;
  int selectedCoffeeId = 0;
  int selectedShotId = 0;
  int selectedRecipeId = 0;

  late StreamController<List<Recipe>> _controllerRecipe;
  late Stream<List<Recipe>> _streamRecipe;

  late SettingsService settings;

  Stream<List<Recipe>> get streamRecipe => _streamRecipe;

  CoffeeService() {
    init();
  }

  void init() async {
    settings = getIt<SettingsService>();
    _controllerRecipe = StreamController<List<Recipe>>();
    _streamRecipe = _controllerRecipe.stream.asBroadcastStream();

    objectBox = getIt<ObjectBox>();
    coffeeBox = objectBox.store.box<Coffee>();
    roasterBox = objectBox.store.box<Roaster>();
    shotBox = objectBox.store.box<Shot>();
    grinderDataBox = objectBox.store.box<GrinderData>();
    recipeBox = objectBox.store.box<Recipe>();
    doseDataBox = objectBox.store.box<DoseData>();

    await load();
    notifyListeners();
  }

  Shot? getLastShot() {
    final builder =
        shotBox.query().order(Shot_.id, flags: Order.descending).build();
    var found = builder.findFirst();
    // var allshots = shotBox.getAll();
    selectedShotId = found?.id ?? 0;
    // log.info("Number of stored shots: ${allshots.length}");
    if (selectedShotId > 0) {
      return found;
    } else {
      return Shot();
    }
  }

  addRoaster(Roaster newRoaster) async {
    int newId = await roasterBox.putAsync(newRoaster);

    selectedRoasterId = newId;
    // await save();
    notifyListeners();
  }

  deleteRoaster(Roaster r) async {
    final builder = coffeeBox.query(Coffee_.roaster.equals(r.id)).build();
    if (builder.findFirst() != null) {
      throw "Can't delete roaster that has coffees - delete coffees first";
    }
    roasterBox.remove(r.id);
    await save();
    notifyListeners();
  }

  addCoffee(Coffee newCoffee) async {
    var id = coffeeBox.put(newCoffee);

    await save();
    notifyListeners();
    return id;
  }

  deleteCoffee(Coffee r) async {
    coffeeBox.remove(r.id);
    notifyListeners();
  }

  Future load() async {
    selectedRoasterId = settings.selectedRoaster;

    selectedCoffeeId = settings.selectedCoffee;
    selectedRecipeId = settings.selectedRecipe;

    selectedShotId = settings.selectedShot;

    log.info("lastshot $selectedShotId");

    if (settings.startCounter == 0) {
      if (roasterBox.count() == 0) {
        log.info("No roasters available. Creating a default one.");
        var r = Roaster();
        r.name = "Default Roaster";
        selectedRoasterId = roasterBox.put(r);
        settings.selectedRoaster = selectedRoasterId;
      }

      if (coffeeBox.count() == 0) {
        log.info("No roasters available. Creating a default one.");
        var r = Coffee();
        r.roaster.targetId = selectedRoasterId;
        r.name = "Default Beans";
        selectedCoffeeId = coffeeBox.put(r);
        settings.selectedCoffee = selectedCoffeeId;
      }

      if (recipeBox.count() == 0) {
        log.info("No recipe available. Creating a default one.");
        {
          var r = Recipe();
          r.coffee.targetId = selectedCoffeeId;
          r.name = "Americano";
          r.description =
              "The drink consists of a single or double shot of espresso brewed with added water. Typically up to about 40 millilitres of hot water is added to the double espresso.";
          r.weightWater = 40;
          r.profileId = settings.currentProfile;
          recipeBox.put(r);
        }
        {
          var r = Recipe();
          r.coffee.targetId = selectedCoffeeId;
          r.name = "Cappuccino";
          r.description =
              "Cappuccino is traditionally small (180 ml maximum) with a thick layer of foam; cappuccino served mostly in a 150–180 ml cup with a handle. Cappuccino traditionally has a layer of textured milk microfoam exceeding 1 cm in thickness; microfoam is frothed/steamed milk in which the bubbles are so small and so numerous that they are not seen, but it makes the milk lighter and thicker.";
          r.profileId = settings.currentProfile;
          r.useWater = false;
          r.weightMilk = 120;
          r.useSteam = true;
          recipeBox.put(r);
        }
        {
          var r = Recipe();
          r.coffee.targetId = selectedCoffeeId;
          r.name = "Simple Espresso";
          r.description =
              "Espresso is made by forcing very hot water under high pressure through finely ground compacted coffee.";
          r.profileId = settings.currentProfile;
          r.useWater = false;
          r.useSteam = false;
          r.isFavorite = true;
          selectedRecipeId = recipeBox.put(r);
          settings.selectedRecipe = selectedRecipeId;
        }
      }
    }
    Future.delayed(
      const Duration(milliseconds: 199),
      () {
        if (roasterBox.count() == 0) {
          log.info("No roasters available. Creating a default one.");
          var r = Roaster();
          r.name = "Sample Roaster";
          selectedRoasterId = roasterBox.put(r);
          settings.selectedRoaster = selectedRoasterId;
        }

        if (coffeeBox.count() == 0) {
          log.info("No roasters available. Creating a default one.");
          var r = Coffee();
          r.roaster.targetId = selectedRoasterId;
          r.name = "Sample Beans";
          selectedCoffeeId = coffeeBox.put(r);
          settings.selectedCoffee = selectedCoffeeId;
        }
      },
    );
  }

  save() async {}

  Future<void> setSelectedRoaster(int id) async {
    if (id == 0) return;

    log.info('Roaster Saving');
    settings.selectedRoaster = id;
    log.info('Roaster Set $id');
    selectedRoasterId = id;
    log.info('Roaster Saved');
    notifyListeners();
  }

  Future<int> copyRecipeFromId(int id) async {
    if (id == 0) return 0;

    var recipe = recipeBox.get(id);
    if (recipe == null) return 0;

    recipe.name = "${recipe.name} Copy";
    recipe.id = 0;
    var idNew = updateRecipe(recipe);

    selectedRecipeId = idNew;
    settings.selectedRecipe = idNew;
    return idNew;
  }

  Future<void> setSelectedRecipe(int id) async {
    if (id == 0) return;

    selectedRecipeId = id;
    settings.selectedRecipe = id;
    var recipe = recipeBox.get(id);
    if (recipe == null) {
      return;
    }

    setSelectedCoffee(recipe.coffee.targetId);

    var profileService = getIt<ProfileService>();
    var machineService = getIt<EspressoMachineService>();
    settings.targetEspressoWeight = recipe.adjustedWeight;
    settings.targetTempCorrection = recipe.adjustedTemp;
    settings.targetHotWaterWeight = recipe.weightWater.toInt();
    settings.targetHotWaterVol = recipe.weightWater.toInt();
    settings.useSteam = recipe.useSteam;
    settings.useWater = recipe.useWater;
    settings.shotStopOnWeight = !recipe.disableStopOnWeight;
    settings.steamHeaterOff = !recipe.useSteam;
    profileService.setProfileFromId(recipe.profileId);
    try {
      if (profileService.currentProfile != null) {
        await machineService.uploadProfile(profileService.currentProfile!);
      }
      await machineService.updateSettings();
    } catch (e) {
      log.severe("Profile could not be sent: $e");
    }

    settings.notifyListeners();
    notifyListeners();
  }

  void setSelectedCoffee(int id) {
    if (id == 0) return;

    settings.selectedCoffee = id;
    selectedCoffeeId = id;

    notifyListeners();
    log.info('Coffee Saved');
  }

  setLastShotId(int id) async {
    selectedShotId = id;
    settings.selectedShot = id;
  }

  Coffee? get currentCoffee {
    if (selectedCoffeeId > 0) {
      return coffeeBox.get(selectedCoffeeId);
    }
    return null;
// code to return members
  }

  // TODO: this is getting called multiple times during shot
  Recipe? get currentRecipe {
    if (selectedRecipeId > 0) {
      return recipeBox.get(selectedRecipeId);
    }
    return null;
// code to return members
  }

  Shot? get currentShot {
    if (selectedShotId > 0) {
      return shotBox.get(selectedShotId);
    }
    return null;
// code to return members
  }

  int addRecipe(
      {required String name,
      required int coffeeId,
      required String profileId,
      required String profileName}) {
    var recipe = Recipe();
    recipe.name = name;
    recipe.coffee.targetId = coffeeId;
    recipe.profileId = profileId;
    recipe.profileName = profileName;
    recipe.adjustedWeight = settings.targetEspressoWeight;
    var id = recipeBox.put(recipe);

    settings.selectedRecipe = id;
    selectedRecipeId = id;
    settings.notifyListeners();
    notifyListeners();
    _controllerRecipe.add(getRecipes());
    return id;
  }

  Future<Recipe> addRecipeFromRecipe(Recipe r) async {
    var cloned = await compute((e) => e, r);
    cloned.id = 0;
    recipeBox.put(cloned, mode: PutMode.insert);
    if (r.grinderData.target != null) {
      var gData = await compute((e) => e, cloned.grinderData.target!);
      gData.id = 0;
      cloned.grinderData.target = gData;
      grinderDataBox.put(cloned.grinderData.target!, mode: PutMode.insert);
    }
    if (r.doseData.target != null) {
      var dData = await compute((e) => e, cloned.doseData.target!);
      dData.id = 0;
      cloned.doseData.target = dData;
      doseDataBox.put(cloned.doseData.target!, mode: PutMode.insert);
    }
    recipeBox.put(cloned);
    return cloned;
  }

  List<Recipe> getRecipes() {
    final builder = recipeBox
        .query((Recipe_.isDeleted.isNull() | Recipe_.isDeleted.equals(false)) &
            (Recipe_.isShot.equals(false) | Recipe_.isShot.isNull()))
        .order(Recipe_.isFavorite, flags: Order.descending)
        .order(Recipe_.name)
        .build();

    //
    var d = builder.find();
    builder.close();

    return d;
  }

  Recipe? getRecipe(int id) {
    return recipeBox.get(id);
  }

  Shot? getShot(int id) {
    return shotBox.get(id);
  }

  void updateShot(Shot shot) {
    shot.grinderData.targetId = grinderDataBox.put(shot.grinderData.target!);
    shot.doseData.targetId = doseDataBox.put(shot.doseData.target!);
    final coffee = coffeeBox.get(shot.coffee.targetId);
    if (coffee != null) {
      coffee.name = shot.coffee.target!.name;
			coffee.roastDate = shot.coffee.target!.roastDate;
      coffeeBox.put(coffee);
    }
    shotBox.put(shot);
    notifyListeners();
  }

  int updateRecipe(Recipe recipe) {
    recipe.grinderData.targetId =
        grinderDataBox.put(recipe.grinderData.target!);
    recipe.doseData.targetId = doseDataBox.put(recipe.doseData.target!);
    int id = recipeBox.put(recipe);
    settings.targetEspressoWeight = recipe.adjustedWeight;
    settings.targetTempCorrection = recipe.adjustedTemp;
    // recalculate temp and update de1 if needed
    setSelectedRecipe(id);
    notifyListeners();
    _controllerRecipe.add(getRecipes());
    return id;
  }

  void removeRecipe(int id) {
    var r = recipeBox.get(id);
    if (r != null) {
      r.isDeleted = true;
      recipeBox.put(r);
    }
    var remaining = getRecipes();

    notifyListeners();
    _controllerRecipe.add(getRecipes());
    setSelectedRecipe(remaining.first.id);
  }

  getBackupData() {
    String file = "${objectBox.store.directoryPath}/data.mdb";
    var f = File(file);

    Uint8List data = f.readAsBytesSync();
    log.info("Data read ${data.length}");
    return data;
  }

  void setSelectedRecipeProfile(String profileId, String profileName) {
    var res = currentRecipe;
    if (res != null) {
      res.profileId = profileId;
      res.profileName = profileName;
      updateRecipe(res);
      notifyListeners();
    }
  }

  void setSelectedRecipeCoffee(int coffeeId) {
    var res = currentRecipe;
    if (res != null) {
      res.coffee.targetId = coffeeId;
      updateRecipe(res);
      notifyListeners();
    }
  }

  void recipeFavoriteToggle(Recipe data) {
    data.isFavorite = !data.isFavorite;
    updateRecipe(data);
  }

  /// Shot is added to database and
  /// to visualizer if enabled in settings
  Future<int> addNewShot(Shot currentShot) async {
    doseDataBox.put(currentShot.doseData.target!);
    grinderDataBox.put(currentShot.grinderData.target!);
    var id = shotBox.put(currentShot);
    await setLastShotId(id);
    if (settings.visualizerUpload) {
      try {
        VisualizerService vis = getIt<VisualizerService>();
        currentShot.visualizerId = await vis.sendShotToVisualizer(currentShot);
        shotBox.put(currentShot);
      } catch (e) {
        log.severe("Visualizer uploading error $e");
      }
    }
    notifyListeners();
    return id;
  }

  List<String> availableGrinderRPM() {
    final dataBox = objectBox.store.box<GrinderData>();
    return dataBox.getAll().map((e) => e.rpm).fold([], (c, e) {
      if (c.contains(e)) {
        return c;
      }
      c.add(e);
      return c;
    });
  }

  List<String> availableGrinderFeedRates() {
    final dataBox = objectBox.store.box<GrinderData>();
    return dataBox.getAll().map((e) => e.feedRate).fold([], (c, e) {
      if (c.contains(e)) {
        return c;
      }
      c.add(e);
      return c;
    });
  }

  List<String> availableBasketInfos() {
    final dataBox = objectBox.store.box<DoseData>();

    return dataBox.getAll().map((e) => e.basket).fold([], (c, e) {
      if (c.contains(e)) {
        return c;
      }
      c.add(e);
      return c;
    });
  }
}
