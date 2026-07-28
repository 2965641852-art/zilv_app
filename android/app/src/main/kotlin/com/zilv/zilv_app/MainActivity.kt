package com.zilv.zilv_app

import android.app.usage.UsageStatsManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.zilv.zilv_app/usage_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> {
                    result.success(isUsageStatsPermissionGranted())
                }
                "openPermissionSettings" -> {
                    openUsageStatsSettings()
                    result.success(true)
                }
                "getAppUsageStats" -> {
                    val startTime = call.argument<Long>("startTime") ?: 0L
                    val endTime = call.argument<Long>("endTime") ?: 0L
                    val stats = getAppUsageStats(startTime, endTime)
                    result.success(stats)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isUsageStatsPermissionGranted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return false
        val appOps = getSystemService(APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = appOps.checkOpNoThrow(
            android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageStatsSettings() {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    private fun getAppUsageStats(startTime: Long, endTime: Long): List<Map<String, Any>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return emptyList()
        if (!isUsageStatsPermissionGranted()) return emptyList()

        val usm = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
        val usageStatsList = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        val pm = packageManager
        val resultList = mutableListOf<Map<String, Any>>()

        // 按包名聚合总时间
        val aggregated = mutableMapOf<String, Long>()
        for (stats in usageStatsList) {
            val totalTime = stats.totalTimeInForeground
            if (totalTime > 0) {
                aggregated[stats.packageName] =
                    (aggregated[stats.packageName] ?: 0L) + totalTime
            }
        }

        // 转换为列表并按使用时间排序
        val sorted = aggregated.entries
            .filter { it.value > 1000 } // 过滤掉少于1秒的
            .sortedByDescending { it.value }

        for (entry in sorted) {
            val appName = try {
                val appInfo = pm.getApplicationInfo(entry.key, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: PackageManager.NameNotFoundException) {
                entry.key
            }

            resultList.add(
                mapOf(
                    "packageName" to entry.key,
                    "appName" to appName,
                    "totalTimeInForeground" to (entry.value / 1000) // 转换为秒
                )
            )
        }

        return resultList
    }
}
