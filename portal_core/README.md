# Portal Core

A Dart library for model generation with JSON serialization, caching, and repository patterns.

## Project Structure

This project has been simplified to use a single package structure instead of the previous split packages approach. The code generation logic is now directly integrated into the main package.

### Key Files:
- `lib/builder.dart` - The build system entry point
- `lib/src/model_gen.dart` - The code generation logic
- `lib/annotations.dart` - Annotation definitions for models
- `build.yaml` - Build system configuration

## Usage

### 1. Define your model with annotations:

```dart
import 'package:portal_core/portal_core.dart';

@ModelGen(
  cache: CacheConfig(key: 'users', collection: true),
  repository: RepositoryConfig(endpoint: '/users'),
)
class User {
  @Id
  final String id;
  
  final String name;
  
  @Default(18)
  final int age;
  
  @Default([])
  final List<String> tags;
  
  final Set<int> scores;
  
  @Default({'role': 'user'})
  final Map<String, String> metadata;
  
  User({
    required this.id,
    required this.name,
    required this.age,
    required this.tags,
    required this.scores,
    required this.metadata,
  });
}
```

### 2. Run code generation:

```bash
dart run build_runner build
```

### 3. Use the generated code:

```dart
// The generated file will be user.portal.dart
import 'user.dart';

void main() async {
  // Create a user with auto-generated ID
  final user = UserFactory.auto(
    name: 'John Doe',
    scores: {85, 92, 78},
  );
  
  // JSON serialization
  final json = user.toJson();
  final fromJson = userFromJson(json);
  
  // Use the cache repository
  final cacheRepo = UserCacheRepository();
  await cacheRepo.create(user);
  final allUsers = await cacheRepo.getAll();
}
```

## Features

- **JSON Serialization**: Automatic `toJson()` and `fromJson()` generation
- **Caching**: Local storage using SharedPreferences
- **Repository Pattern**: Abstract repository interfaces and concrete implementations
- **Auto ID Generation**: UUID for strings, random integers for int IDs
- **Default Values**: Support for field defaults with `@Default` annotation
- **Copy With**: Automatic `copyWith()` method generation
- **ID Field Detection**: Automatic detection of ID fields or manual `@Id` annotation

## Annotations

- `@ModelGen` - Main annotation for model generation
- `@Id` - Marks a field as the primary identifier
- `@Default(value)` - Sets a default value for a field
- `@JsonKey(name: 'custom_name')` - Custom JSON key mapping

## Build Configuration

The build system is configured in `build.yaml` and `pubspec.yaml` to automatically generate `.portal.dart` files for all Dart files in `lib/`, `example/`, and `test/` directories.

## Why This Structure?

The previous split-package approach was unnecessarily complex for a single project. This simplified structure:

1. **Eliminates circular dependencies** between packages
2. **Reduces complexity** in build configuration
3. **Makes the codebase easier to understand** and maintain
4. **Simplifies dependency management**

All code generation logic is now contained within the main package, making it self-contained and easier to work with.
