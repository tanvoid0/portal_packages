class VaultBlobMeta {
  const VaultBlobMeta({
    required this.path,
    required this.version,
    required this.updatedAt,
    this.sizeBytes = 0,
    this.contentType = 'application/octet-stream',
  });

  final String path;
  final int version;
  final DateTime updatedAt;
  final int sizeBytes;
  final String contentType;

  Map<String, dynamic> toJson() => {
        'path': path,
        'version': version,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'size_bytes': sizeBytes,
        'content_type': contentType,
      };

  factory VaultBlobMeta.fromJson(Map<String, dynamic> json) {
    return VaultBlobMeta(
      path: json['path'] as String,
      version: json['version'] as int? ?? 1,
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      sizeBytes: json['size_bytes'] as int? ?? 0,
      contentType: json['content_type'] as String? ?? 'application/octet-stream',
    );
  }
}
