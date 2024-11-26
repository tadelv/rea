import 'package:objectbox/objectbox.dart';

@Entity()
class DoseData {
  int id = 0;

  String basket;

  String extra = "";

  DoseData({required this.basket});
}
