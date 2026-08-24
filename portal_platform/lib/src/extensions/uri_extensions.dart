/// Normalizes URI paths for HTTP requests (collapses duplicate slashes).
extension PortalUriNormalize on Uri {
  Uri normalizePath() {
    var p = path;
    if (p.isEmpty) return this;
    while (p.contains('//')) {
      p = p.replaceAll('//', '/');
    }
    if (p == path) return this;
    return replace(path: p);
  }
}
