import '../clients/ai_completion_client.dart';
import '../models/ai_model_manager.dart';

/// An in-process inference engine: weights on this device, no daemon and no
/// second app.
///
/// portal_ai declares the seam but ships no engine. The native runtime for
/// on-device inference is tens of megabytes per ABI, and most Portal apps
/// will never run a local model -- an app that wants one depends on the
/// engine package itself and hands the implementation to
/// [AiCompletionClientFactory] and [AiBackendDiscovery]. Apps that do not
/// pass one never see [AiBackendKind.localLlm] offered, and carry none of
/// its weight.
abstract class LocalLlmEngine implements AiModelManager {
  /// Null when this device can run the engine, otherwise why it cannot --
  /// shown on the disabled row. Checked before any model is downloaded, so a
  /// phone that cannot run the runtime never fetches two gigabytes to find
  /// out.
  Future<String?> unsupportedReason();

  /// A client bound to an already-installed [model] id.
  AiCompletionClient clientFor(String model);
}
