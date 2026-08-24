import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied()
abstract class Env {
  @EnviedField(varName: 'GEMINI_API_KEY', optional: false)
  static const String geminiApiKey = _Env.geminiApiKey;

  @EnviedField(varName: 'OLLAMA_API_KEY', optional: false)
  static const String ollamaApiKey = _Env.ollamaApiKey;

  @EnviedField(varName: 'CHATGPT_API_KEY', optional: false)
  static const String chatgptApiKey = _Env.chatgptApiKey;
}
