package com.strawberryFrappe.sync_companion

import android.content.Context
import android.preference.PreferenceManager
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class CloudManager(private val context: Context) {

    private val prefs = PreferenceManager.getDefaultSharedPreferences(context)
    // Flutter's shared_preferences plugin stores values in a separate file
    // with a "flutter." key prefix. Config is set from Flutter UI, so we must
    // read it from Flutter's prefs file. Queue stays in default prefs.
    private val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    private val QUEUE_KEY = "cloud_event_queue"
    private val executor = Executors.newSingleThreadExecutor()

    companion object {
        private const val MAX_QUEUE_SIZE = 5000
        private const val BATCH_SIZE = 50
        private const val INITIAL_BACKOFF_MS = 1000L
        private const val MAX_BACKOFF_MS = 5 * 60 * 1000L
        private const val LAST_SYNC_KEY = "cloud_last_sync_ts"
        private const val LAST_ERROR_KEY = "cloud_last_error"
    }

    // Persisted so getLastSyncTs/getLastError (MethodChannel) survive process restarts.
    // Named persisted* so their auto-generated getters don't clash on the JVM with
    // the explicit public getLastSyncTs()/getLastError() accessors below.
    private var persistedLastSyncTs: Long
        get() = prefs.getLong(LAST_SYNC_KEY, 0L)
        set(value) { prefs.edit().putLong(LAST_SYNC_KEY, value).apply() }

    private var persistedLastError: String
        get() = prefs.getString(LAST_ERROR_KEY, "") ?: ""
        set(value) { prefs.edit().putString(LAST_ERROR_KEY, value).apply() }

    fun logSyncStatus(synced: Boolean, avgBpm: Int?, avgSpo2: Int?, avgTemp: Double?, windowStartMs: Long) {
        val eventId = "sync_status-$windowStartMs"
        val payload = JSONObject().apply {
            put("eventId", eventId)
            put("eventType", "sync_status")
            put("synced", synced)
            val vitals = JSONObject()
            avgBpm?.let { if (it > 0) vitals.put("avgBpm", it) }
            avgSpo2?.let { if (it > 0) vitals.put("avgSpo2", it) }
            avgTemp?.let { vitals.put("avgTemp", Math.round(it * 10) / 10.0) }
            if (vitals.length() > 0) put("vitals", vitals)
        }
        val values = JSONObject().put("payload", payload)

        logEvent(eventId, windowStartMs, values)
    }

    fun logMissionCompleted(missionId: String) {
        val ts = System.currentTimeMillis()
        val eventId = "mission_completed-$ts-$missionId"
        val payload = JSONObject().apply {
            put("eventId", eventId)
            put("eventType", "mission_completed")
            put("mission_id", missionId)
        }
        val values = JSONObject().put("payload", payload)

        logEvent(eventId, ts, values)
    }

    // Enqueues then opportunistically flushes one bounded batch. Does NOT drain the
    // whole queue here - connectivity-triggered flushes (cluster B) own that.
    private fun logEvent(eventId: String, ts: Long, values: JSONObject) {
        executor.execute {
            enqueueEntry(eventId, ts, values)
            flushQueueSync()
        }
    }

    // Dedup by eventId (a retried event replaces its prior queued copy - keeps
    // re-logging idempotent) then applies the bounded-queue cap.
    private fun enqueueEntry(eventId: String, ts: Long, values: JSONObject) {
        val queue = loadQueue()
        val deduped = JSONArray()
        // Preserve any in-flight backoff state for this eventId: re-logging the same
        // window during an outage must not reset retryCount/nextRetryAt (which would
        // defeat the exponential backoff and hammer the endpoint).
        var carriedRetryCount = 0
        var carriedNextRetryAt = 0L
        for (i in 0 until queue.length()) {
            val existing = queue.getJSONObject(i)
            if (existing.optString("eventId") != eventId) {
                deduped.put(existing)
            } else {
                carriedRetryCount = existing.optInt("retryCount", 0)
                carriedNextRetryAt = existing.optLong("nextRetryAt", 0L)
            }
        }
        val entry = JSONObject().apply {
            put("eventId", eventId)
            put("ts", ts)
            put("values", values)
            put("retryCount", carriedRetryCount)
            put("nextRetryAt", carriedNextRetryAt)
        }
        deduped.put(entry)
        saveQueue(trimQueue(deduped))
    }

    // Parses the persisted queue tolerantly: entries missing the pinned shape
    // (e.g. leftover legacy {eventType, timestamp, payload} entries) are dropped
    // rather than guessed at.
    private fun loadQueue(): JSONArray {
        val queueString = prefs.getString(QUEUE_KEY, "[]")
        val raw = try { JSONArray(queueString) } catch (e: Exception) { JSONArray() }
        val valid = JSONArray()
        for (i in 0 until raw.length()) {
            try {
                val entry = raw.getJSONObject(i)
                if (entry.has("eventId") && entry.has("ts") && entry.has("values")) {
                    valid.put(entry)
                } else {
                    Log.w("CloudManager", "Dropping legacy/invalid queue entry")
                }
            } catch (e: Exception) {
                Log.w("CloudManager", "Dropping unparsable queue entry: ${e.message}")
            }
        }
        return valid
    }

    private fun saveQueue(queue: JSONArray) {
        prefs.edit().putString(QUEUE_KEY, queue.toString()).apply()
    }

    // Caps the queue at MAX_QUEUE_SIZE, dropping the OLDEST non-sync_status entry
    // first. sync_status is only dropped as a last resort (and logged) since it
    // drives the backend usage rule.
    private fun trimQueue(queue: JSONArray): JSONArray {
        if (queue.length() <= MAX_QUEUE_SIZE) return queue

        val entries = mutableListOf<JSONObject>()
        for (i in 0 until queue.length()) entries.add(queue.getJSONObject(i))
        entries.sortBy { it.optLong("ts", 0L) }

        while (entries.size > MAX_QUEUE_SIZE) {
            val idx = entries.indexOfFirst { !isSyncStatus(it) }
            if (idx >= 0) {
                entries.removeAt(idx)
            } else {
                val dropped = entries.removeAt(0)
                Log.w("CloudManager", "Queue overflow: dropping sync_status entry ${dropped.optString("eventId")}")
            }
        }

        val result = JSONArray()
        entries.forEach { result.put(it) }
        return result
    }

    private fun isSyncStatus(entry: JSONObject): Boolean {
        val payload = entry.optJSONObject("values")?.optJSONObject("payload")
        return payload?.optString("eventType") == "sync_status"
    }

    fun flushQueue() {
        executor.execute {
            flushQueueSync()
        }
    }

    // Sends up to BATCH_SIZE due entries in ts order, stopping on the first
    // failure so ordering is preserved on retry. Entries not yet due
    // (nextRetryAt in the future) are skipped without breaking the loop.
    private fun flushQueueSync() {
        val endpointUrl = getEndpointUrl() ?: return

        val queue = loadQueue()
        if (queue.length() == 0) return

        val now = System.currentTimeMillis()
        val entries = mutableListOf<JSONObject>()
        for (i in 0 until queue.length()) entries.add(queue.getJSONObject(i))
        entries.sortBy { it.optLong("ts", 0L) }

        val remaining = mutableListOf<JSONObject>()
        var attempts = 0
        var stopped = false

        for (entry in entries) {
            if (stopped || attempts >= BATCH_SIZE || now < entry.optLong("nextRetryAt", 0L)) {
                remaining.add(entry)
                continue
            }

            attempts++
            val eventId = entry.optString("eventId")
            val body = JSONObject().apply {
                put("ts", entry.optLong("ts"))
                put("values", entry.optJSONObject("values"))
            }
            val success = sendPostRequest(endpointUrl, body, eventId)
            if (success) {
                persistedLastSyncTs = System.currentTimeMillis()
                persistedLastError = ""
            } else {
                bumpRetry(entry)
                remaining.add(entry)
                stopped = true
            }
        }

        saveQueue(JSONArray().apply { remaining.forEach { put(it) } })
    }

    private fun bumpRetry(entry: JSONObject) {
        val retryCount = entry.optInt("retryCount", 0) + 1
        entry.put("retryCount", retryCount)
        entry.put("nextRetryAt", System.currentTimeMillis() + computeBackoffMs(retryCount))
    }

    // Exponential backoff (base 2) off a 1s floor, capped at 5min, +/-20% jitter.
    // Jitter source is System.nanoTime() - deterministic per call, no need for
    // a full RNG here.
    private fun computeBackoffMs(retryCount: Int): Long {
        val exponential = (INITIAL_BACKOFF_MS * Math.pow(2.0, retryCount.toDouble())).toLong()
        val capped = exponential.coerceAtMost(MAX_BACKOFF_MS)
        val nanos = Math.abs(System.nanoTime())
        val jitterFactor = 0.8 + (nanos % 4001) / 10000.0 // 0.80 .. 1.20
        return (capped * jitterFactor).toLong().coerceAtLeast(0L)
    }

    fun getQueueCount(): Int = loadQueue().length()

    fun getLastSyncTs(): Long = persistedLastSyncTs

    fun getLastError(): String = persistedLastError

    private fun sendPostRequest(urlStr: String, body: JSONObject, eventId: String): Boolean {
        try {
            val url = URL(urlStr)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.doOutput = true
            conn.connectTimeout = 5000
            conn.readTimeout = 5000

            OutputStreamWriter(conn.outputStream).use { it.write(body.toString()) }

            val responseCode = conn.responseCode
            val ok = responseCode in 200..299
            if (!ok) {
                val msg = "POST $eventId rejected: HTTP $responseCode"
                Log.w("CloudManager", msg)
                persistedLastError = msg
            }
            return ok
        } catch (e: Exception) {
            val msg = "Failed to POST $eventId: ${e.message}"
            Log.e("CloudManager", msg)
            persistedLastError = msg
            return false
        }
    }

    private fun getEndpointUrl(): String? {
        val baseUrl = flutterPrefs.getString("flutter.cloud_base_url", "http://200.13.5.20:8080") ?: return null
        val token = flutterPrefs.getString("flutter.cloud_device_token", "") ?: return null
        if (token.isEmpty()) return null
        return "$baseUrl/api/v1/$token/telemetry"
    }
}
