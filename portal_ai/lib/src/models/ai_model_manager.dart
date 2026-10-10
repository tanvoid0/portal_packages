/// A model a backend can fetch, as offered to the user before it exists on
/// the device.
class AiModelDownload {
  const AiModelDownload({
    required this.id,
    required this.label,
    this.sizeBytes,
    this.note,
    this.minRamBytes,
  });

  /// What [AiModelManager.install] is called with, and what the completion
  /// client is pointed at afterwards -- an Ollama tag, a file name, a repo id.
  final String id;

  final String label;

  /// Download size, when the backend reports one.
  final int? sizeBytes;

  /// One line under the label: quantisation, context window, licence.
  final String? note;

  /// Device memory below which this model will not load. A backend that
  /// cannot know leaves it null and the row is always offered.
  final int? minRamBytes;
}

/// Install, list and remove for a backend that keeps model files of its own.
///
/// Ollama pulls tags into its daemon; an on-device engine downloads weights
/// into app storage. Different transports, same four questions, so the
/// settings UI asks them once and works for both.
abstract class AiModelManager {
  /// Model ids already on the device, newest-first where the backend says so.
  Future<List<String>> installed();

  /// What could be fetched. May be a fixed list -- an on-device engine knows
  /// which builds it can run; Ollama's registry is not enumerable over HTTP.
  Future<List<AiModelDownload>> catalog();

  /// Emits progress in `0.0..1.0` and closes when [id] is installed.
  ///
  /// A backend that cannot report progress emits nothing and closes on
  /// completion, which the UI renders as an indeterminate bar.
  Stream<double> install(String id);

  Future<void> remove(String id);
}

class AiModelManagerException implements Exception {
  const AiModelManagerException(this.message);

  final String message;

  @override
  String toString() => message;
}
