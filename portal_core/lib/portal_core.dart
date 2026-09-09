/// Shared model annotations, generated-model support and the local cache.
library;

export 'portal_core_models.dart';
export 'annotations.dart';
// Deliberately not exporting 'builder.dart': it pulls source_gen, which imports
// dart:mirrors and is unavailable on the Flutter VM, so exporting it broke
// compilation for every consumer of this barrel. build.yaml loads the builder
// directly via `package:portal_core/builder.dart`.
//
// ponytail: build/source_gen/analyzer stay in `dependencies` because
// build_runner has to resolve them when portal_core is a dependency of an app.
// Splitting the builder into its own package is the real fix.
export 'package:uuid/uuid.dart';
export 'dart:math'; // For generated model id support
export 'dart:convert';
