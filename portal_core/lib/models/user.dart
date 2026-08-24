import 'package:portal_core/portal_core.dart';

part 'user.portal.dart';

@ModelGen(immutable: true)
class User {
  @Id()
  final String id;
  final String name;
  @Default(18)
  final int age;
  @Default([])
  final List<String> tags;

  final Set<int> scores;

  @Default({'role': 'user'})
  final Map<String, String> metadata;

  @Default({'a', 'b'})
  final Set<String> tagsSet;

  @Default({'count': 1})
  final Map<String, int> stats;

  User({
    required this.id,
    required this.name,
    @Default(18) this.age = 18,
    this.tags = const [],
    required this.scores,
    this.metadata = const {'role': 'user'},
    this.tagsSet = const {'a', 'b'},
    this.stats = const {'count': 1},
  });
}
