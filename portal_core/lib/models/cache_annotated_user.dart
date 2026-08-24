import 'package:portal_core/portal_core.dart';

part 'cache_annotated_user.portal.dart';

// With annotation, default (collection: true)
@ModelGen(cache: CacheConfig())
class CacheUserDefaultCollection {
  final String id;
  final String name;
  CacheUserDefaultCollection({required this.id, required this.name});
}

// With annotation, collection: false (single)
@ModelGen(cache: CacheConfig(collection: false))
class CacheUserSingle {
  final String id;
  final String name;
  CacheUserSingle({required this.id, required this.name});
}

// With annotation, custom key, collection: false
@ModelGen(cache: CacheConfig(key: 'custom_key', collection: false))
class CacheUserCustomKeySingle {
  final String id;
  final String name;
  CacheUserCustomKeySingle({required this.id, required this.name});
}

// Without annotation
@ModelGen()
class CacheUserNoCache {
  final String id;
  final String name;
  CacheUserNoCache({required this.id, required this.name});
}
