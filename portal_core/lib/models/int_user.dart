import 'package:portal_core/portal_core.dart';

part 'int_user.portal.dart';

@ModelGen(immutable: true)
class IntUser {
  @Id()
  final int id;
  final String name;
  @Default(21)
  final int age;

  IntUser({required this.id, required this.name, required this.age});
}
