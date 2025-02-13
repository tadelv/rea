import 'package:despresso/model/coffee.dart';
import 'package:objectbox/objectbox.dart';
import 'package:despresso/model/dose_data.dart';
import 'package:despresso/model/grinder_data.dart';

@Entity()
class Recipe {
  Recipe();

  int id = 0;

  final coffee = ToOne<Coffee>();
  String profileId = "Default";
  String profileName = "Default";

  double adjustedWeight = 36;
  double adjustedPressure = 0;
  double adjustedTemp = 0;
  double grinderDoseWeight = 18;
	@Deprecated("Use grinderData")
  double grinderSettings = 0;
	@Deprecated("Use grinderData")
  String grinderModel = "";

  final doseData = ToOne<DoseData>();

  final grinderData = ToOne<GrinderData>();

  double ratio1 = 1;
  double ratio2 = 2;

  bool isDeleted = false;
  bool isFavorite = false;
  // This Recipe is only used in shot database and should be not visible if true
  bool isShot = false;

  String name = "Espresso";
  String description = "";

  /// For added water
  double weightWater = 120;
  bool useWater = true;
  bool disableStopOnWeight = false;
  double tempWater = 85;
  double timeWater = 20;

  // Steaming milk for recipe
  double tempSteam = 120;
  double flowSteam = 1;
  double timeSteam = 30;
  double weightMilk = 120;
  bool useSteam = false;

	bool showAdvancedMetaData = true;
}
