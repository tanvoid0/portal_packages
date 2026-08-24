import 'package:google_sign_in/google_sign_in.dart';

import 'portal_google_sign_in_mobile.dart'
    if (dart.library.html) 'portal_google_sign_in_web.dart' as impl;

/// Creates [GoogleSignIn] using the GCP **Web application** OAuth client ID.
///
/// Platform-specific constructors are used so web never receives
/// [serverClientId] (unsupported by `google_sign_in_web`).
GoogleSignIn createPortalGoogleSignIn({
  required String webClientId,
  List<String> scopes = const ['email', 'profile'],
}) {
  return impl.createPortalGoogleSignIn(
    webClientId: webClientId,
    scopes: scopes,
  );
}
