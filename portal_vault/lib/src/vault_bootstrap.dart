import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:portal_platform/portal_platform.dart';

import 'backup/backup_orchestrator.dart';
import 'remote/vault_api_client.dart';
import 'storage/device_vault_backend.dart';
import 'storage/google_drive_vault_backend.dart';
import 'storage/portal_cloud_vault_backend.dart';
import 'local/local_vault_dek_store.dart';
import 'vault_service.dart';

/// Registers vault services after [ApiClient] is available.
abstract final class VaultBootstrap {
  static Future<void> register({bool isLoggedIn = false}) async {
    if (!Get.isRegistered<ApiClient>()) return;

    final serverClientId =
        dotenv.env['GOOGLE_SIGN_IN_SERVER_CLIENT_ID']?.trim();
    final api = VaultApiClient();

    GoogleDriveVaultBackend google;
    if (serverClientId != null && serverClientId.isNotEmpty) {
      if (!Get.isRegistered<PortalGoogleSignInRegistry>()) {
        Get.put(
          PortalGoogleSignInRegistry(
            webClientId: serverClientId,
            extraScopes: [drive.DriveApi.driveAppdataScope],
          ),
          permanent: true,
        );
      }
      google = GoogleDriveVaultBackend(
        signIn: Get.find<PortalGoogleSignInRegistry>().instance,
      );
    } else {
      google = GoogleDriveVaultBackend();
    }
    final device = DeviceVaultBackend();
    final portalCloud = PortalCloudVaultBackend(api);

    final vault = VaultService(api: api, googleDrive: google);
    await Get.putAsync(() => vault.init(), permanent: true);

    Get.put(LocalVaultDekStore(), permanent: true);

    Get.put(device, permanent: true);
    Get.put(portalCloud, permanent: true);
    Get.put(google, permanent: true);
    Get.put(api, permanent: true);

    Get.put(
      BackupOrchestrator(
        vault: vault,
        device: device,
        portalCloud: portalCloud,
        googleDrive: google,
      ),
      permanent: true,
    );

    if (isLoggedIn) {
      // Vault unlock happens after login with password (see VaultSessionBinder).
    }
  }

  static void lockVault() {
    if (Get.isRegistered<VaultService>()) {
      Get.find<VaultService>().lock();
    }
  }

  static Future<void> clearLocalDekForUser(String userId) async {
    if (Get.isRegistered<LocalVaultDekStore>()) {
      await Get.find<LocalVaultDekStore>().clear(userId: userId);
    }
  }
}
