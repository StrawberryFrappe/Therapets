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

    fun logSyncStatus(synced: Boolean, avgBpm: Int?, avgSpo2: Int?, avgTemp: Double?) {
        val payload = JSONObject().apply {
            put("synced", synced)
            val vitals = JSONObject()
            avgBpm?.let { if (it > 0) vitals.put("avgBpm", it) }
            avgSpo2?.let { if (it > 0) vitals.put("avgSpo2", it) }
            avgTemp?.let { vitals.put("avgTemp", Math.round(it * 10) / 10.0) }
            if (vitals.length() > 0) put("vitals", vitals)
        }

        val event = JSONObject().apply {
            put("eventType", "sync_status")
            put("timestamp", System.currentTimeMillis())
            put("payload", payload)
        }

        logEvent(event)
    }

    fun logMissionCompleted(missionId: String) {
        val payload = JSONObject().apply {
            put("mission_id", missionId)
        }

        val event = JSONObject().apply {
            put("eventType", "mission_completed")
            put("timestamp", System.currentTimeMillis())
            put("payload", payload)
        }

        logEvent(event)
    }

    fun logEvent(event: JSONObject) {
        executor.execute {
            queueEvent(event)
            flushQueueSync()
        }
    }

    private fun queueEvent(event: JSONObject) {
        val queueString = prefs.getString(QUEUE_KEY, "[]")
        val queue = try { JSONArray(queueString) } catch (e: Exception) { JSONArray() }
        queue.put(event)
        prefs.edit().putString(QUEUE_KEY, queue.toString()).apply()
    }

    fun flushQueue() {
        executor.execute {
            flushQueueSync()
        }
    }

    private fun flushQueueSync() {
        val endpointUrl = getEndpointUrl() ?: return
        
        val queueString = prefs.getString(QUEUE_KEY, "[]")
        val currentQueue = try { JSONArray(queueString) } catch (e: Exception) { JSONArray() }
        if (currentQueue.length() == 0) return

        val remainingQueue = JSONArray()

        for (i in 0 until currentQueue.length()) {
            val event = currentQueue.getJSONObject(i)
            val success = sendPostRequest(endpointUrl, event)
            if (!success) {
                remainingQueue.put(event)
            }
        }

        prefs.edit().putString(QUEUE_KEY, remainingQueue.toString()).apply()
    }

    private fun sendPostRequest(urlStr: String, event: JSONObject): Boolean {
        try {
            val url = URL(urlStr)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.doOutput = true
            conn.connectTimeout = 5000
            conn.readTimeout = 5000

            OutputStreamWriter(conn.outputStream).use { it.write(event.toString()) }

            val responseCode = conn.responseCode
            val ok = responseCode in 200..299
            if (!ok) Log.w("CloudManager", "POST ${event.optString("eventType")} rejected: HTTP $responseCode")
            return ok
        } catch (e: Exception) {
            Log.e("CloudManager", "Failed to POST ${event.optString("eventType")}: ${e.message}")
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
