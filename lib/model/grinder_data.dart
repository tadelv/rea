import 'package:objectbox/objectbox.dart';

@Entity()
class GrinderData {
  int id = 0;

  @Index()
  String model;

  double grindSizeSetting;

  @Index()
  String feedRate;
  String rpm;

  GrinderData(
      {required this.model,
      required this.grindSizeSetting,
      required this.feedRate,
      required this.rpm});
}
