import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/model_gen.dart';

Builder modelGenBuilder(BuilderOptions options) => LibraryBuilder(
  ModelGenLibraryGenerator(),
  generatedExtension: '.portal.dart',
);
