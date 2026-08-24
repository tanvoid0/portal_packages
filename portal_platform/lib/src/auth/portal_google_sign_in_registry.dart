import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'portal_google_sign_in.dart';

/// Shared [GoogleSignIn] for Portal login and Google Drive vault.
///
/// Web requires a single GIS client with all scopes up front; separate
/// [GoogleSignIn] instances do not share the authenticated session.
class PortalGoogleSignInRegistry extends GetxService {
  PortalGoogleSignInRegistry({
    required String webClientId,
    List<String> extraScopes = const [],
  })  : _webClientId = webClientId.trim(),
        _extraScopes = List.unmodifiable(extraScopes);

  static const defaultScopes = ['email', 'profile'];

  final String _webClientId;
  final List<String> _extraScopes;
  GoogleSignIn? _instance;

  GoogleSignIn get instance {
    return _instance ??= createPortalGoogleSignIn(
      webClientId: _webClientId,
      scopes: [...defaultScopes, ..._extraScopes],
    );
  }

  Future<void> signOut() async {
    await _instance?.signOut();
    _instance = null;
  }
}
