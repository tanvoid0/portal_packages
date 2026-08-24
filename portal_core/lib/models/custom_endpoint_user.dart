import 'package:portal_core/portal_core.dart';

part 'custom_endpoint_user.portal.dart';

@ModelGen(repository: Repository(endpoint: '/api/v1/custom-users'))
class CustomEndpointUser {
  final String id;
  final String name;
  final String email;

  CustomEndpointUser({
    required this.id,
    required this.name,
    required this.email,
  });
}
