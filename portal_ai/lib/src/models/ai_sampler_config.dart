/// Sampling parameters for text generation.
class AiSamplerConfig {
  const AiSamplerConfig({this.temperature = 0.7, this.topP = 0.9, this.topK});

  final double temperature;
  final double topP;
  final int? topK;
}
