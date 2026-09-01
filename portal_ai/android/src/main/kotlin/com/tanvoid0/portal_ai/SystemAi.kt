package com.tanvoid0.portal_ai

import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import kotlinx.coroutines.flow.collect

/**
 * The device's own model, via ML Kit GenAI (AICore / Gemini Nano).
 *
 * Nothing here names a model: [describe] asks the runtime what it will run
 * through `getBaseModelName()`, so a device shipping a different base model
 * reports that instead with no change on either side of the channel.
 *
 * Every entry point catches [Throwable] rather than a specific exception. The
 * ML Kit classes resolve against Google Play services, so a device without it
 * throws `NoClassDefFoundError` on first touch — a linkage error, not an
 * exception the API documents. Letting that escape would crash the settings
 * screen on exactly the devices that have no on-device AI to offer.
 */
class SystemAi {
    private var model: GenerativeModel? = null

    private fun model(): GenerativeModel =
        model ?: Generation.getClient().also { model = it }

    /** Status, plus the model name the runtime reports, for the Dart side. */
    suspend fun describe(): Map<String, Any?> = try {
        val model = model()
        when (model.checkStatus()) {
            FeatureStatus.AVAILABLE -> mapOf(
                "status" to "available",
                "models" to listOf(model.getBaseModelName()),
            )
            FeatureStatus.DOWNLOADABLE -> mapOf(
                "status" to "downloadable",
                "reason" to "The on-device model has not been downloaded yet",
            )
            FeatureStatus.DOWNLOADING -> mapOf(
                "status" to "downloading",
                "reason" to "The on-device model is still downloading",
            )
            else -> mapOf(
                "status" to "unavailable",
                "reason" to "This device cannot run the built-in model",
            )
        }
    } catch (e: Throwable) {
        mapOf(
            "status" to "unavailable",
            "reason" to (e.message ?: "On-device AI is unavailable"),
        )
    }

    /** Fetches the weights. True when the download finished. */
    suspend fun download(): Boolean = try {
        var completed = false
        model().download().collect { status ->
            if (status is DownloadStatus.DownloadCompleted) completed = true
        }
        completed
    } catch (_: Throwable) {
        false
    }

    suspend fun generate(prompt: String): String =
        model().generateContent(prompt).candidates.firstOrNull()?.text.orEmpty()

    suspend fun generateStream(prompt: String, onChunk: suspend (String) -> Unit) {
        model().generateContentStream(prompt).collect { chunk ->
            val text = chunk.candidates.firstOrNull()?.text
            if (!text.isNullOrEmpty()) onChunk(text)
        }
    }

    fun close() {
        try {
            model?.close()
        } catch (_: Throwable) {
            // Nothing useful to do while the engine is going away anyway.
        }
        model = null
    }
}
