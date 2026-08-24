import 'package:google_sign_in/google_sign_in.dart';

/// Mobile/desktop implementation — Web client ID is passed as [serverClientId]
/// so sign-in returns an `id_token` the API can verify.
GoogleSignIn createPortalGoogleSignIn({
  required String webClientId,
  List<String> scopes = const ['email', 'profile'],
}) {
  final id = webClientId.trim();
  if (id.isEmpty) {
    return GoogleSignIn(scopes: scopes);
  }
  return GoogleSignIn(
    scopes: scopes,
    serverClientId: id,
  );
}
