import 'package:portal_core/portal_core.dart';

part 'test_user.portal.dart';

@ModelGen(immutable: true)
class TestUser {
  @Id()
  final String id;
  final String name;
  final int age;

  TestUser({required this.id, required this.name, required this.age});
}
