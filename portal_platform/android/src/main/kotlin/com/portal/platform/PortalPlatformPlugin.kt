package com.portal.platform

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Two PackageManager questions the Portal app list needs and no Flutter plugin
 * answers without asking for QUERY_ALL_PACKAGES: what version of a sibling app
 * is installed, and please uninstall it.
 *
 * Both are scoped by the <queries> block in this package's manifest, so an
 * unlisted package is simply invisible — [installedVersion] reports it as not
 * installed rather than failing.
 */
class PortalPlatformPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "portal_platform/packages")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val packageName = call.argument<String>("package")
        if (packageName.isNullOrBlank()) {
            result.error("bad_args", "package is required", null)
            return
        }
        when (call.method) {
            "installedVersion" -> result.success(installedVersion(packageName))
            "uninstall" -> result.success(uninstall(packageName))
            "launch" -> result.success(launch(packageName))
            else -> result.notImplemented()
        }
    }

    private fun installedVersion(packageName: String): Map<String, Any?>? = try {
        val info = context.packageManager.getPackageInfo(packageName, 0)
        val code =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode
            else @Suppress("DEPRECATION") info.versionCode.toLong()
        mapOf("versionCode" to code, "versionName" to (info.versionName ?: ""))
    } catch (e: PackageManager.NameNotFoundException) {
        null
    }

    /**
     * Opens an installed sibling app by its launch activity.
     *
     * The `portal-x://` scheme is the normal route, but it only works for an
     * app that declared a matching intent filter — portal_launcher declares
     * none, and a future app may forget one. PackageManager already knows how
     * to start anything visible through the <queries> block, so this is the
     * fallback that does not depend on the other app cooperating.
     */
    private fun launch(packageName: String): Boolean {
        val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            ?: return false
        val host = activity
        return try {
            if (host != null) {
                host.startActivity(intent)
            } else {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Opens Android's uninstall confirmation. Returns whether it opened, not
     * whether the user went through with it — that answer only arrives when
     * the app is next resumed and the list re-probes.
     */
    private fun uninstall(packageName: String): Boolean {
        val intent = Intent(Intent.ACTION_DELETE, Uri.parse("package:$packageName"))
        val host = activity
        return try {
            if (host != null) {
                host.startActivity(intent)
            } else {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            }
            true
        } catch (e: Exception) {
            false
        }
    }
}
