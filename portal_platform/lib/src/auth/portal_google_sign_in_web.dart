import 'package:google_sign_in/google_sign_in.dart';

/// Web implementation — [serverClientId] must not be passed to [GoogleSignIn].
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
    clientId: id,
  );
}
