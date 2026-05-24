package com.strawberryFrappe.sync_companion

import android.content.Context
import android.preference.PreferenceManager
import android.util.Log
import org.json.JSONArray

object MissionManager {
    private const val TAG = "MissionManager"
    private const val COMPLETED_MISSIONS_KEY = "completed_missions_today"
    private const val MISSIONS_CONFIG_KEY = "daily_missions_config"

    fun evaluateMissions(context: Context, cloudManager: CloudManager) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        
        val configString = prefs.getString(MISSIONS_CONFIG_KEY, "[]")
        val completedString = prefs.getString(COMPLETED_MISSIONS_KEY, "[]")
        
        try {
            val missions = JSONArray(configString)
            val completed = JSONArray(completedString)
            val completedSet = mutableSetOf<String>()
            for (i in 0 until completed.length()) {
                completedSet.add(completed.getString(i))
            }
            
            var newCompletions = false

            for (i in 0 until missions.length()) {
                val mission = missions.getJSONObject(i)
                val id = mission.optString("id")
                if (id.isEmpty() || completedSet.contains(id)) continue

                val metric = mission.optString("metric")
                val target = mission.optDouble("target", 0.0)
                
                var currentValue = 0.0
                when (metric) {
                    "synced_minutes_today", "pet_fed_count", "minigames_played_count", "minigame_high_score" -> {
                        currentValue = prefs.getInt(metric, 0).toDouble()
                    }
                    "pet_happiness", "pet_hunger" -> {
                        currentValue = prefs.getFloat(metric, 0f).toDouble()
                    }
                    else -> {
                        currentValue = prefs.getFloat(metric, 0f).toDouble()
                        if (currentValue == 0.0) {
                            currentValue = prefs.getInt(metric, 0).toDouble()
                        }
                    }
                }

                if (currentValue >= target) {
                    Log.i(TAG, "Mission completed: $id")
                    completedSet.add(id)
                    completed.put(id)
                    newCompletions = true
                    cloudManager.logMissionCompleted(id)
                }
            }

            if (newCompletions) {
                prefs.edit().putString(COMPLETED_MISSIONS_KEY, completed.toString()).apply()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to evaluate missions: ${e.message}")
        }
    }
}
