import 'package:portal_core/portal_core.dart';

part 'repo_user.portal.dart';

@ModelGen(repository: Repository(endpoint: '/repo_users'))
class RepoUser {
  final String id;
  final String name;
  RepoUser({required this.id, required this.name});
}
