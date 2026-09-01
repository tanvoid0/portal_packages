library;

class JsonKey {
  final String name;
  const JsonKey(this.name);
}

class Repository {
  final String endpoint;
  const Repository({required this.endpoint});
}

class CacheConfig {
  final String? key;
  final bool collection;
  const CacheConfig({this.key, this.collection = true});
}

class ModelGen {
  final bool immutable;
  final Map<String, dynamic>? fieldOptions;
  final String? keyStrategy;
  final Repository? repository;
  final CacheConfig? cache;
  const ModelGen({
    this.immutable = false,
    this.fieldOptions,
    this.keyStrategy,
    this.repository,
    this.cache,
  });
}

class Id {
  const Id();
}

class Default {
  final Object value;
  const Default(this.value);
}
