import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:collection/collection.dart';

String _toLowerCamel(String name) {
  if (name.isEmpty) return name;
  return name[0].toLowerCase() + name.substring(1);
}

class ModelGenLibraryGenerator extends Generator {
  @override
  Future<String?> generate(LibraryReader library, BuildStep buildStep) async {
    final sourceFileName = buildStep.inputId.uri.pathSegments.last;
    final partOfDirective = "part of '$sourceFileName';\n";
    final output = StringBuffer();
    bool found = false;

    // Write the partOf directive at the top
    output.writeln(partOfDirective);

    for (final element in library.allElements) {
      if (element is! ClassElement) continue;
      final annotation = _getModelGenAnnotation(element);
      if (annotation == null) continue;
      found = true;
      output.writeln(_generateForClass(element, annotation, buildStep));
    }
    if (!found) return null;
    return output.toString();
  }

  ConstantReader? _getModelGenAnnotation(ClassElement element) {
    for (final meta in element.metadata) {
      final obj = meta.computeConstantValue();
      if (obj != null && obj.type?.getDisplayString(withNullability: false) == 'ModelGen') {
        return ConstantReader(obj);
      }
    }
    return null;
  }

  String _generateForClass(
    ClassElement classElement,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final className = classElement.name;
    final fields = classElement.fields.where((f) => !f.isStatic);
    final cacheConfig = annotation.peek('cache');
    final cacheEnabled = cacheConfig != null && !cacheConfig.isNull;
    if (cacheEnabled) {
      final keyValue = cacheConfig.read('key');
      if (!keyValue.isNull) {
        // cacheKey = keyValue.stringValue ?? className; // unused
      }
      final collectionValue = cacheConfig.read('collection');
      if (!collectionValue.isNull) {
        // cacheCollection = collectionValue.boolValue ?? true; // unused
      }
    }
    // String cacheType = cacheCollection ? 'collection' : 'single'; // unused

    // Detect the ID field
    FieldElement? idField;
    for (final field in fields) {
      for (final meta in field.metadata) {
        final obj = meta.computeConstantValue();
        if (obj != null && obj.type?.getDisplayString(withNullability: false) == 'Id') {
          idField = field;
          break;
        }
      }
      if (idField != null) break;
    }
    // Fallback: field named 'id' of type String or int
    idField ??= fields
        .where(
          (f) =>
              f.name == 'id' &&
              (f.type.getDisplayString(withNullability: false) == 'String' ||
                  f.type.getDisplayString(withNullability: false) == 'int'),
        )
        .cast<FieldElement?>()
        .firstOrNull;
    final idFieldName = idField?.name;

    final fromJsonName = _toLowerCamel('${className}FromJson');
    final keyStrategy = annotation.peek('keyStrategy')?.stringValue;

    // Generate fromJson as a top-level function
    final fromJsonBuffer = StringBuffer();
    fromJsonBuffer.writeln('/// Generated fromJson for $className');
    fromJsonBuffer.writeln(
      '$className $fromJsonName(Map<String, dynamic> json) {',
    );
    fromJsonBuffer.writeln('  return $className(');
    for (final field in fields) {
      final fieldName = field.name;
      final type = field.type;
      final typeStr = type.getDisplayString(withNullability: false);
      final jsonKey = getJsonKey(field, keyStrategy);
      fromJsonBuffer.writeln('    $fieldName: json[\'$jsonKey\'] as $typeStr,');
    }
    fromJsonBuffer.writeln('  );');
    fromJsonBuffer.writeln('}');

    // Generate toJson as an extension
    final toJsonBuffer = StringBuffer();
    toJsonBuffer.writeln('extension ${className}JsonExtension on $className {');
    toJsonBuffer.writeln('  Map<String, dynamic> toJson() {');
    toJsonBuffer.writeln('    return {');
    for (final field in fields) {
      final fieldName = field.name;
      final jsonKey = getJsonKey(field, keyStrategy);
      toJsonBuffer.writeln("      '$jsonKey': $fieldName,");
    }
    toJsonBuffer.writeln('    };');
    toJsonBuffer.writeln('  }');
    // Add getId method
    if (idFieldName != null) {
      toJsonBuffer.writeln('  Object? getId() => $idFieldName;');
    } else {
      toJsonBuffer.writeln('  Object? getId() => null;');
    }
    // Add copyWith method
    toJsonBuffer.writeln('  $className copyWith({');
    for (final field in fields) {
      final typeStr = field.type.getDisplayString(withNullability: false);
      toJsonBuffer.writeln('    $typeStr? ${field.name},');
    }
    toJsonBuffer.writeln('  }) {');
    toJsonBuffer.writeln('    return $className(');
    for (final field in fields) {
      final name = field.name;
      toJsonBuffer.writeln('      $name: $name ?? this.$name,');
    }
    toJsonBuffer.writeln('    );');
    toJsonBuffer.writeln('  }');
    // Add cache helpers if cache is enabled
    // if (cacheEnabled) {
    //   toJsonBuffer.writeln('  static String get cacheKey => "$cacheKey";');
    //   toJsonBuffer.writeln('  static String get cacheType => "$cacheType";');
    // }
    toJsonBuffer.writeln('}');

    // Emit a static getter for the ID field name
    final idGetterBuffer = StringBuffer();
    idGetterBuffer.writeln('extension ${className}IdField on $className {');
    idGetterBuffer.writeln(
      '  static String get idFieldName => ${idFieldName != null ? "'$idFieldName'" : 'null'};',
    );
    idGetterBuffer.writeln('}');

    // Generate factory constructor for auto id
    final factoryBuffer = StringBuffer();
    if (idField != null) {
      final idType = idField.type.getDisplayString(withNullability: false);
      factoryBuffer.writeln(
        '// If you use the auto() factory, ensure you import:',
      );
      factoryBuffer.writeln('//   import "package:uuid/uuid.dart";');
      factoryBuffer.writeln('//   import "dart:math";');
      factoryBuffer.writeln('extension ${className}Factory on $className {');
      factoryBuffer.writeln('  static $className auto({');
      // id is optional
      factoryBuffer.writeln('    $idType? $idFieldName,');
      // other fields
      for (final field in fields) {
        if (field.name == idFieldName) continue;
        final typeStr = field.type.getDisplayString(withNullability: false);
        final hasDefault = hasDefaultAnnotation(field);
        final isNullable = field.type.nullabilitySuffix.toString().contains(
          'question',
        );
        if (hasDefault || isNullable) {
          factoryBuffer.writeln('    $typeStr? ${field.name},');
        } else {
          factoryBuffer.writeln('    required $typeStr ${field.name},');
        }
      }
      factoryBuffer.writeln('  }) {');
      if (idType == 'String') {
        factoryBuffer.writeln(
          '    final generatedId = $idFieldName ?? const Uuid().v4();',
        );
      } else if (idType == 'int') {
        factoryBuffer.writeln(
          '    final generatedId = $idFieldName ?? Random().nextInt(1 << 31);',
        );
      } else {
        factoryBuffer.writeln('    final generatedId = $idFieldName;');
      }
      // Handle defaults for other fields - removed unused variable assignments
      factoryBuffer.writeln('    return $className(');
      for (final field in fields) {
        if (field.name == idFieldName) {
          factoryBuffer.writeln('      $idFieldName: generatedId,');
        } else {
          final hasDefault = hasDefaultAnnotation(field);
          if (hasDefault) {
            final defaultObj = field.metadata
                .map((m) => m.computeConstantValue())
                .firstWhere(
                  (v) => v != null && v.type?.getDisplayString(withNullability: false) == 'Default',
                  orElse: () => null,
                );
            String valueStr = defaultObj != null
                ? getDartLiteral(defaultObj.getField('value'))
                : 'null';
            factoryBuffer.writeln(
              '      ${field.name}: ${field.name} ?? $valueStr, // If you change the default, update the constructor default too',
            );
          } else {
            factoryBuffer.writeln('      ${field.name}: ${field.name},');
          }
        }
      }
      factoryBuffer.writeln('    );');
      factoryBuffer.writeln('  }');
      factoryBuffer.writeln('}');
    }

    // Only generate model, JSON, and utility code. No repository or cache logic.
    // (repoBuffer, cacheRepo, cacheMeta, and related code are removed)
    return '''
${factoryBuffer.toString()}
${idGetterBuffer.toString()}
${fromJsonBuffer.toString()}
${toJsonBuffer.toString()}
''';
  }

  // Helper: get @Default value for a field
  Object? getDefaultValue(FieldElement field) {
    for (final meta in field.metadata) {
      final obj = meta.computeConstantValue();
      if (obj != null && obj.type?.getDisplayString(withNullability: false) == 'Default') {
        return obj.getField('value')?.toStringValue() ??
            obj.getField('value')?.toIntValue() ??
            obj.getField('value')?.toDoubleValue() ??
            obj.getField('value')?.toBoolValue();
      }
    }
    return null;
  }

  // Helper: check if a field has @Default annotation
  bool hasDefaultAnnotation(FieldElement field) {
    for (final meta in field.metadata) {
      final obj = meta.computeConstantValue();
      if (obj != null && obj.type?.getDisplayString(withNullability: false) == 'Default') {
        return true;
      }
    }
    return false;
  }

  // Helper: get Dart literal for a default value
  String getDartLiteral(DartObject? obj) {
    if (obj == null) return 'null';
    if (obj.type?.isDartCoreString ?? false) {
      return "'${obj.toStringValue()!.replaceAll("'", "\\'")}'";
    } else if (obj.type?.isDartCoreInt ?? false) {
      return obj.toIntValue().toString();
    } else if (obj.type?.isDartCoreDouble ?? false) {
      return obj.toDoubleValue().toString();
    } else if (obj.type?.isDartCoreBool ?? false) {
      return obj.toBoolValue().toString();
    } else if (obj.type?.isDartCoreList ?? false) {
      final elements = obj.toListValue()!.map(getDartLiteral).join(', ');
      return 'const [$elements]';
    } else if (obj.type?.isDartCoreSet ?? false) {
      final elements = obj.toSetValue()!.map(getDartLiteral).join(', ');
      return 'const {$elements}';
    } else if (obj.type?.isDartCoreMap ?? false) {
      final map = obj.toMapValue()!;
      final entries = map.entries
          .map((e) => '${getDartLiteral(e.key)}: ${getDartLiteral(e.value)}')
          .join(', ');
      return 'const {$entries}';
    }
    return obj.toString();
  }

  // Helper: get the JSON key for a field
  String getJsonKey(FieldElement field, String? keyStrategy) {
    for (final meta in field.metadata) {
      final obj = meta.computeConstantValue();
      if (obj != null &&
          obj.type?.getDisplayString(withNullability: false) == 'JsonKey') {
        return obj.getField('name')?.toStringValue() ?? field.name;
      }
    }
    // Apply keyStrategy if present
    if (keyStrategy != null) {
      switch (keyStrategy) {
        case 'snake_case':
          return _toSnakeCase(field.name);
        case 'camelCase':
          return _toCamelCase(field.name);
        case 'PascalCase':
          return _toPascalCase(field.name);
      }
    }
    return field.name;
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]}_${m[2]}',
        )
        .toLowerCase();
  }

  String _toCamelCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toLowerCase() + input.substring(1);
  }

  String _toPascalCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}
