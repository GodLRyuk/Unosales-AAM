package com.UnoSales.unosfa

import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.UnoSales.unosfa"

    // ═══════════════════════════════════════════════════
    //  onCreate — Runs BEFORE Flutter and BEFORE Firebase
    // ═══════════════════════════════════════════════════
    override fun onCreate(savedInstanceState: Bundle?) {

        // ── Runs before everything — Flutter, Firebase, all ──
        if (isDeviceRooted()) {
            wipeAndExit()
            return
        }

        super.onCreate(savedInstanceState)
    }

    // ═══════════════════════════════════════════════════
    //  Wipe All Data and Force Exit
    // ═══════════════════════════════════════════════════
    private fun wipeAndExit() {
        try {
            android.util.Log.d("Security", "🚨 Rooted device — wiping and exiting")

            filesDir.listFiles()?.forEach { it.delete() }
            cacheDir.listFiles()?.forEach { it.delete() }
            File(applicationInfo.dataDir, "shared_prefs")
                .listFiles()?.forEach { it.delete() }
            File(applicationInfo.dataDir, "databases")
                .listFiles()?.forEach { it.delete() }

        } catch (e: Exception) {
            android.util.Log.e("Security", "Wipe error: ${e.message}")
        } finally {
            finishAffinity()
            System.exit(0)
        }
    }

    // ═══════════════════════════════════════════════════
    //  MethodChannel
    // ═══════════════════════════════════════════════════
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isRooted"    -> result.success(isDeviceRooted())
                "isEmulator"  -> result.success(isEmulator())
                "isDevMode"   -> result.success(isDevMode())
                "isMultiUser" -> result.success(isMultiUserEnabled())
                else          -> result.notImplemented()
            }
        }
    }

    // ═══════════════════════════════════════════════════
    //  MAIN ROOT DETECTION — All 7 layers
    // ═══════════════════════════════════════════════════
    fun isDeviceRooted(): Boolean {
        return checkSuPaths()
            || checkBuildTags()
            || trySuExecution()
            || checkMagiskInProcMaps()
            || checkDangerousPackages()
            || checkNativeLibraryHooks()
            || checkRootFolderAccess()
    }

    fun checkSuPaths(): Boolean {
        return checkSuViaShell() || checkSuViaWhich() || checkSuViaEnvPath()
    }

    fun checkSuViaShell(): Boolean {
        val paths = listOf(
            "/system/bin/su", "/system/xbin/su", "/sbin/su",
            "/su/bin/su", "/magisk/.core/bin/su",
            "/data/adb/magisk", "/data/local/su"
        )
        return try {
            for (path in paths) {
                val process = Runtime.getRuntime().exec(arrayOf("ls", path))
                process.waitFor()
                if (process.exitValue() == 0) {
                    android.util.Log.d("RootCheck", "Shell found su at: $path")
                    return true
                }
            }
            false
        } catch (e: Exception) { false }
    }

    fun checkSuViaWhich(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("which", "su"))
            val output  = process.inputStream.bufferedReader().readLine()
            process.waitFor()
            (!output.isNullOrBlank()).also {
                if (it) android.util.Log.d("RootCheck", "which su found: $output")
            }
        } catch (e: Exception) { false }
    }

    fun checkSuViaEnvPath(): Boolean {
        return try {
            val path    = System.getenv("PATH") ?: return false
            val process = Runtime.getRuntime()
                .exec(arrayOf("sh", "-c", "ls ${path.replace(":", " ")}"))
            val output  = process.inputStream.bufferedReader().readText()
            process.waitFor()
            output.lines().any { it.trim() == "su" }.also {
                if (it) android.util.Log.d("RootCheck", "su found in PATH")
            }
        } catch (e: Exception) { false }
    }

    fun checkBuildTags(): Boolean {
        val tags = Build.TAGS ?: return false
        return tags.contains("test-keys").also {
            if (it) android.util.Log.d("RootCheck", "test-keys found in build tags")
        }
    }

    fun trySuExecution(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
            val output  = BufferedReader(
                InputStreamReader(process.inputStream)
            ).readLine() ?: ""
            process.destroy()
            output.contains("uid=0").also {
                if (it) android.util.Log.d("RootCheck", "su execution returned uid=0")
            }
        } catch (e: Exception) { false }
    }

    fun checkMagiskInProcMaps(): Boolean {
        return try {
            File("/proc/self/maps").readLines().any { line ->
                line.contains("magisk", ignoreCase = true) ||
                line.contains("zygisk", ignoreCase = true) ||
                line.contains("riru",   ignoreCase = true) ||
                line.contains("frida",  ignoreCase = true)
            }.also {
                if (it) android.util.Log.d("RootCheck", "Magisk/Zygisk found in proc maps")
            }
        } catch (e: Exception) { false }
    }

    fun checkDangerousPackages(): Boolean {
        val dangerousPackages = listOf(
            "com.topjohnwu.magisk",
            "io.github.huskydg.magisk",
            "com.tsng.hidemyapplist",
            "com.noshufou.android.su",
            "com.thirdparty.superuser",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.zachspong.temprootremovejb",
            "com.ramdroid.appquarantine",
            "com.formyhm.hideapps",
            "me.weishu.exp"
        )
        return dangerousPackages.any { pkg ->
            try {
                packageManager.getPackageInfo(
                    pkg,
                    PackageManager.MATCH_UNINSTALLED_PACKAGES
                )
                android.util.Log.d("RootCheck", "Dangerous package found: $pkg")
                true
            } catch (e: PackageManager.NameNotFoundException) { false }
        }
    }

    fun checkNativeLibraryHooks(): Boolean {
        return try {
            File("/proc/self/maps").readLines().any { line ->
                line.contains("frida-agent", ignoreCase = true) ||
                line.contains("xposed",      ignoreCase = true) ||
                line.contains("substrate",   ignoreCase = true)
            }.also {
                if (it) android.util.Log.d("RootCheck", "Native hook found in proc maps")
            }
        } catch (e: Exception) { false }
    }

    fun checkRootFolderAccess(): Boolean {
        val rootPaths = listOf(
            "/home/root", "/var/lib/cydia",
            "/private/var/lib/apt", "/data/adb/magisk",
            "/data/adb/su", "/data/su.img"
        )
        for (path in rootPaths) {
            try {
                val file = File(path)
                if (file.exists() || file.canRead()) {
                    android.util.Log.d("RootCheck", "Root folder accessible: $path")
                    return true
                }
                val testFile = File(path, "root_test_${System.currentTimeMillis()}.tmp")
                if (testFile.createNewFile()) {
                    testFile.delete()
                    android.util.Log.d("RootCheck", "Root folder writable: $path")
                    return true
                }
            } catch (e: SecurityException) {
                android.util.Log.d("RootCheck", "SecurityException on $path — clean")
            } catch (e: java.io.IOException) {
                android.util.Log.d("RootCheck", "IOException on $path — clean")
            } catch (e: Exception) {
                android.util.Log.d("RootCheck", "Exception: ${e.message}")
            }
        }
        return false
    }

    fun isEmulator(): Boolean {
        return Build.FINGERPRINT.contains("generic")     ||
               Build.MODEL.contains("Emulator")          ||
               Build.MANUFACTURER.contains("Genymotion") ||
               Build.BRAND.startsWith("generic")         ||
               Build.DEVICE.startsWith("generic")        ||
               Build.PRODUCT.contains("sdk")             ||
               Build.HARDWARE.contains("goldfish")       ||
               Build.HARDWARE.contains("ranchu")
    }

    fun isDevMode(): Boolean {
        return try {
            android.provider.Settings.Global.getInt(
                contentResolver,
                android.provider.Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                0
            ) == 1
        } catch (e: Exception) { false }
    }

    fun isMultiUserEnabled(): Boolean {
        return try {
            val um = getSystemService(USER_SERVICE) as android.os.UserManager
            um.userProfiles.size > 1
        } catch (e: Exception) { false }
    }
}