package com.tanvoid0.portal_ai

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class PortalAiPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var streamChannel: EventChannel
    private lateinit var context: Context

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val systemAi = SystemAi()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "portal_ai/platform")
        channel.setMethodCallHandler(this)
        streamChannel = EventChannel(binding.binaryMessenger, "portal_ai/generate_stream")
        streamChannel.setStreamHandler(GenerateStreamHandler(systemAi))
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
            "describeSystemAi" -> scope.launch {
                result.success(systemAi.describe())
            }
            "downloadSystemAi" -> scope.launch {
                result.success(systemAi.download())
            }
            "generate" -> {
                val prompt = call.argument<String>("prompt")
                if (prompt.isNullOrBlank()) {
                    result.error("INVALID", "prompt required", null)
                    return
                }
                scope.launch {
                    try {
                        result.success(systemAi.generate(prompt))
                    } catch (e: Throwable) {
                        result.error("GENERATE_FAILED", e.message, null)
                    }
                }
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
        streamChannel.setStreamHandler(null)
        systemAi.close()
        scope.cancel()
    }
}

/**
 * Streams one generation. Dart opens the channel with the prompt as arguments
 * and closes it to cancel; the job is cancelled with the listener so a user who
 * backs out of the sheet stops paying for tokens they will never read.
 */
private class GenerateStreamHandler(private val systemAi: SystemAi) :
    EventChannel.StreamHandler {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var job: Job? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val sink = events ?: return
        val prompt = (arguments as? Map<*, *>)?.get("prompt") as? String
        if (prompt.isNullOrBlank()) {
            sink.error("INVALID", "prompt required", null)
            sink.endOfStream()
            return
        }
        job = scope.launch {
            try {
                systemAi.generateStream(prompt) { chunk ->
                    withContext(Dispatchers.Main) { sink.success(chunk) }
                }
                sink.endOfStream()
            } catch (e: Throwable) {
                sink.error("GENERATE_FAILED", e.message, null)
                sink.endOfStream()
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        job?.cancel()
        job = null
    }
}
