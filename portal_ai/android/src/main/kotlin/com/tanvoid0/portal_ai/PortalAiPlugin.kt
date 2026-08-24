package com.tanvoid0.portal_ai

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PortalAiPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "portal_ai/platform")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isPackageInstalled" -> {
                val packageName = call.arguments as? String
                if (packageName.isNullOrBlank()) {
                    result.error("INVALID", "package name required", null)
                    return
                }
                result.success(isPackageInstalled(packageName))
            }
            "launchPackage" -> {
                val packageName = call.arguments as? String
                if (packageName.isNullOrBlank()) {
                    result.error("INVALID", "package name required", null)
                    return
                }
                result.success(launchPackage(packageName))
            }
            else -> result.notImplemented()
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            @Suppress("DEPRECATION")
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun launchPackage(packageName: String): Boolean {
        if (!isPackageInstalled(packageName)) return false
        val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
