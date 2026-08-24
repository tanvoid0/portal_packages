# Flutter Code Generation Library: Project Plan

## Progress Summary (as of now)
- Monorepo structure established with `portal_core_annotations`, `portal_core_codegen`, and `portal_core_models` packages under `packages/`
- `@ModelGen` annotation defined in `portal_core_annotations`
- Code generation logic implemented in `portal_core_codegen` (outputs `fromJson` and `toJson`)
- Example/test models placed in `portal_core_models/example/`
- Code generation successfully produces `.portal.dart` files for models
- Builder configuration and dependencies set up for modular, maintainable development

## Overview
This project aims to create a Flutter library that leverages code generation (via annotations) to automate the creation of:
- Model serialization/deserialization (`fromJson`, `toJson`) with field-level customization
- State management boilerplate (Riverpod, GetX, etc.)
- Memory management code (local storage integration)
- Customizable CRUD service classes
- Customizable controllers
- Admin dashboard UI for CRUD management

## High-Level Architecture
- **Annotation Package**: Dart annotations for models, services, controllers, etc.
- **Code Generator**: Builder that processes annotations and generates code.
- **Generated Code**: Output files for models, state, services, controllers, and admin UI.
- **Customization**: Configurable via annotation parameters and optional config files.

## Features & Tasks

### 1. Model Serialization/Deserialization
- [x] Define `@ModelGen` annotation
- [ ] Support field-level customization:
  - [x] Custom key names
  - [x] Default values
  - [ ] Mutability/immutability (class, fields, collections)
- [x] Generate `fromJson`, `toJson` methods
- [ ] Support for nested/complex types (including recursive fromJson/toJson)
- [ ] Enum support (serialize/deserialize as string/int, custom mapping)
- [ ] Field exclusion via `@JsonIgnore`
- [ ] Custom converters via `@JsonConverter`
- [ ] Field-level validation annotations (e.g., `@Min`, `@Max`, `@Pattern`)
- [ ] Generate equality/hashCode overrides
- [ ] Copy doc comments into generated code
- [ ] Generate `patchWith` for partial updates
- [ ] Generate builder classes for models
- [ ] Integration with `json_serializable`/`freezed`/Riverpod
- [ ] Robust error handling in `fromJson`
- [ ] Configurable output (file location, naming, code style)

### 2. State Management Code Generation
- [ ] Define `@StateGen` annotation
- [ ] Support Riverpod and GetX (configurable)
- [ ] Generate providers/controllers for models
- [ ] Support for async state, loading, error handling

### 3. Memory Management Code Generation
- [ ] Define `@StorageGen` annotation
- [ ] Generate code for local storage (e.g., Hive, SharedPreferences)
- [ ] Support for custom storage backends

### 4. CRUD Service Generation
- [ ] Define `@CrudServiceGen` annotation
- [ ] Generate service classes for CRUD operations
- [ ] Support for REST, GraphQL, or custom endpoints
- [ ] Customizable hooks (before/after CRUD)

### 5. Controller Generation
- [ ] Define `@ControllerGen` annotation
- [ ] Generate controller classes for business logic
- [ ] Integrate with state and service layers

### 6. Admin Dashboard Generation
- [ ] Define `@AdminDashboardGen` annotation
- [ ] Generate Flutter UI for CRUD management
- [ ] Support for custom field widgets, validation, filtering, sorting
- [ ] Role-based access control (optional)

### 7. Configuration & Customization
- [ ] Support annotation parameters for customization
- [ ] Optional YAML/JSON config file for global settings

### 8. Documentation & Examples
- [ ] Write usage documentation
- [x] Provide example project (models in `portal_core_models/example/`)

## Project Structure (Current)
```
packages/
  portal_core_annotations/
    lib/model_gen.dart
    ...
  portal_core_codegen/
    lib/src/model_gen.dart
    lib/builder.dart
    build.yaml
    ...
  portal_core_models/
    example/user.dart
    example/test_user.dart
    build.yaml
    ...
plan.md
README.md
```

## Milestones
1. **MVP**: Model serialization, basic state management, CRUD service
2. **Advanced Features**: Storage, controllers, admin dashboard
3. **Customization & Extensibility**: Config files, hooks, advanced UI
4. **Docs & Examples**

## Next Steps
- Add support for nested/complex types (including recursive fromJson/toJson)
- Add enum support (serialize/deserialize as string/int, custom mapping)
- Add field exclusion via @JsonIgnore
- Add custom converters via @JsonConverter
- Add field-level validation annotations (e.g., @Min, @Max, @Pattern)
- Add equality/hashCode generation
- Add doc comment copying
- Add patchWith and builder generation
- Add integration with json_serializable/freezed/Riverpod
- Add robust error handling in fromJson
- Add configurable output options
- Continue incremental feature development as per plan 