import 'package:objectbox/objectbox.dart';

@Entity()
class DbVersion {
  int id = 0;

  int version;

  DbVersion({required this.version});
}
