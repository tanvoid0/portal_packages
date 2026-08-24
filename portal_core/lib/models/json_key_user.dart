import 'package:portal_core/portal_core.dart';

part 'json_key_user.portal.dart';

@ModelGen(keyStrategy: 'snake_case')
class JsonKeyUser {
  @JsonKey('user_id')
  final String id;
  final String firstName;
  final String lastName;
  @JsonKey('is_active')
  final bool active;

  JsonKeyUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.active,
  });
}
