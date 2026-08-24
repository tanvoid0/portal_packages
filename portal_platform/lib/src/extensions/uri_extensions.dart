/// Collapses duplicate slashes in URI paths for HTTP requests.
///
/// Named to avoid `Uri.normalizePath`, which exists in dart:core and silently
/// shadowed this extension — every call site was getting the built-in
/// (which resolves `.`/`..` segments) and never collapsed a single slash.
extension PortalUriNormalize on Uri {
  Uri collapseSlashes() {
    var p = path;
    if (p.isEmpty) return this;
    while (p.contains('//')) {
      p = p.replaceAll('//', '/');
    }
    if (p == path) return this;
    return replace(path: p);
  }
}
