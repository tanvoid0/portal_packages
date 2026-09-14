package com.tanvoid0.portal_ai

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.EventChannel
import java.util.Locale
import kotlin.coroutines.resume
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * Speech in and out, on the device only.
 *
 * Recognition goes through [SpeechRecognizer.createOnDeviceSpeechRecognizer]
 * (API 31+), which has no server to fall back to — unlike `EXTRA_PREFER_OFFLINE`,
 * which is a preference the service may ignore. Synthesis picks a TTS voice
 * that reports no network requirement, and reports nothing usable when the
 * engine has none, so a device whose only voices are cloud-backed says voice
 * is unavailable rather than quietly uploading the reply.
 */
class Voice(private val context: Context) {
    private var tts: TextToSpeech? = null
    private var ttsReady: Boolean? = null
    private var recognizer: SpeechRecognizer? = null

    /** Utterances in the engine's queue, by id, each awaiting its finish. */
    private val pending = HashMap<String, CancellableContinuation<Boolean>>()
    private var rate = 1f

    private val canListen: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            SpeechRecognizer.isOnDeviceRecognitionAvailable(context)

    /** `{stt: Boolean, tts: Boolean}` for the Dart side. */
    suspend fun describe(): Map<String, Any?> =
        mapOf("stt" to canListen, "tts" to initTts())

    private suspend fun initTts(): Boolean {
        ttsReady?.let { return it }
        return suspendCancellableCoroutine { cont ->
            var engine: TextToSpeech? = null
            engine = TextToSpeech(context) { status ->
                val ready = engine
                val ok = status == TextToSpeech.SUCCESS && ready != null &&
                    pickOfflineVoice(ready)
                ttsReady = ok
                if (ok && ready != null) {
                    ready.setSpeechRate(rate)
                    ready.setOnUtteranceProgressListener(progress)
                    tts = ready
                } else {
                    ready?.shutdown()
                }
                if (cont.isActive) cont.resume(ok)
            }
        }
    }

    /** One listener for the life of the engine; each queued chunk finds its own waiter by id. */
    private val progress = object : UtteranceProgressListener() {
        override fun onStart(utteranceId: String?) {}
        override fun onDone(utteranceId: String?) = finish(utteranceId, true)
        @Deprecated("Deprecated in Java")
        override fun onError(utteranceId: String?) = finish(utteranceId, false)
        override fun onStop(utteranceId: String?, interrupted: Boolean) = finish(utteranceId, false)

        private fun finish(utteranceId: String?, ok: Boolean) {
            val cont = synchronized(pending) { pending.remove(utteranceId) } ?: return
            if (cont.isActive) cont.resume(ok)
        }
    }

    /** Speed as a multiple of the voice's normal; clamped to what engines accept. */
    fun setRate(value: Double) {
        rate = value.toFloat().coerceIn(0.5f, 2f)
        tts?.setSpeechRate(rate)
    }

    /** Selects a voice that never touches the network; false when there is none. */
    private fun pickOfflineVoice(engine: TextToSpeech): Boolean {
        val voices = try {
            engine.voices
        } catch (_: Throwable) {
            null
        } ?: return false
        val wanted = Locale.getDefault()
        val offline = voices.filter {
            !it.isNetworkConnectionRequired &&
                !it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED)
        }
        val voice = offline.firstOrNull { it.locale == wanted }
            ?: offline.firstOrNull { it.locale.language == wanted.language }
            ?: return false
        return engine.setVoice(voice) == TextToSpeech.SUCCESS
    }

    /**
     * Reads [text] aloud, after whatever is already queued unless [flush].
     * Returns once this chunk has been spoken: a streaming reply queues each
     * sentence as it arrives and awaits only the last.
     */
    suspend fun speak(text: String, flush: Boolean): Boolean {
        if (!initTts()) return false
        val engine = tts ?: return false
        val id = "portal_ai_${System.nanoTime()}"
        return suspendCancellableCoroutine { cont ->
            synchronized(pending) { pending[id] = cont }
            cont.invokeOnCancellation { synchronized(pending) { pending.remove(id) } }
            // The engine caps one utterance; a long chunk goes in as several,
            // and only the last one carries the id the waiter is keyed on.
            val parts = text.chunked(TextToSpeech.getMaxSpeechInputLength())
            var queued = TextToSpeech.SUCCESS
            parts.forEachIndexed { i, part ->
                val mode = if (i == 0 && flush) TextToSpeech.QUEUE_FLUSH else TextToSpeech.QUEUE_ADD
                val partId = if (i == parts.lastIndex) id else "$id-$i"
                if (engine.speak(part, mode, null, partId) != TextToSpeech.SUCCESS) {
                    queued = TextToSpeech.ERROR
                }
            }
            if (queued != TextToSpeech.SUCCESS) {
                synchronized(pending) { pending.remove(id) }
                if (cont.isActive) cont.resume(false)
            }
        }
    }

    /** Drops everything queued. Each waiter hears onStop and resumes false. */
    fun stopSpeaking() {
        tts?.stop()
        val dropped = synchronized(pending) { pending.values.toList().also { pending.clear() } }
        dropped.forEach { if (it.isActive) it.resume(false) }
    }

    /**
     * Hears one utterance. Events are `{text, final}` as the reading is
     * refined, and `{level}` for the meter; the stream ends after the final
     * reading, or with no final at all when nothing was said.
     */
    fun listen(sink: EventChannel.EventSink, locale: String?) {
        stopListening()
        if (!canListen) {
            sink.error("UNAVAILABLE", "On-device speech recognition is not available", null)
            sink.endOfStream()
            return
        }
        val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
        this.recognizer = recognizer
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            if (!locale.isNullOrBlank()) putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
        }
        recognizer.setRecognitionListener(object : RecognitionListener {
            override fun onPartialResults(partialResults: Bundle?) {
                val text = partialResults?.firstResult()
                if (!text.isNullOrBlank()) sink.success(mapOf("text" to text, "final" to false))
            }

            override fun onResults(results: Bundle?) {
                sink.success(mapOf("text" to results?.firstResult().orEmpty(), "final" to true))
                sink.endOfStream()
                stopListening()
            }

            override fun onError(error: Int) {
                // Silence is not a failure worth a message: the stream ends
                // with no final event and the page drops out of voice mode.
                when (error) {
                    SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> {}
                    // The recognizer is installed but this language's pack
                    // was never downloaded: a fresh phone, or a locale added
                    // later. `isOnDeviceRecognitionAvailable` says yes either
                    // way. Ask for the pack so the next tap works, and say
                    // what happened this time instead of a bare code.
                    SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            recognizer.triggerModelDownload(intent)
                        }
                        sink.error(
                            "LANGUAGE_UNAVAILABLE",
                            "Speech language pack not downloaded yet; download started",
                            null,
                        )
                    }
                    else -> sink.error("LISTEN_FAILED", "Speech recognizer error $error", null)
                }
                sink.endOfStream()
                stopListening()
            }

            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {
                // The recognizer reports roughly -2..10 dB; 0..1 for the meter.
                sink.success(mapOf("level" to ((rmsDb(rmsdB))).toDouble()))
            }
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
        recognizer.startListening(intent)
    }

    fun stopListening() {
        recognizer?.destroy()
        recognizer = null
    }

    fun close() {
        stopListening()
        tts?.shutdown()
        tts = null
        ttsReady = null
    }

    private fun rmsDb(db: Float): Float = ((db + 2f) / 12f).coerceIn(0f, 1f)

    private fun Bundle.firstResult(): String? =
        getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
}
