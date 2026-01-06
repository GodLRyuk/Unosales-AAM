package com.UnoSales.unosfa

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.UnoSales.unosfa"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "isRooted" -> result.success(isDeviceRooted())
                "isEmulator" -> result.success(isEmulator())
                "isDevMode" -> result.success(isDevMode())
                "isMultiUser" -> result.success(isMultiUserEnabled())
                else -> result.notImplemented()
            }
        }
    }

    private fun isDeviceRooted(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk", "/sbin/su", "/system/bin/su",
            "/system/xbin/su", "/data/local/xbin/su", "/data/local/bin/su",
            "/system/sd/xbin/su", "/system/bin/failsafe/su", "/data/local/su"
        )
        return paths.any { File(it).exists() }
    }

    private fun isEmulator(): Boolean {
        return Build.FINGERPRINT.contains("generic") ||
               Build.MODEL.contains("Emulator") ||
               Build.MANUFACTURER.contains("Genymotion") ||
               Build.BRAND.startsWith("generic") ||
               Build.DEVICE.startsWith("generic") ||
               Build.PRODUCT.contains("sdk")
    }

    private fun isDevMode(): Boolean {
        return try {
            android.provider.Settings.Secure.getInt(
                contentResolver,
                android.provider.Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                0
            ) == 1
        } catch (e: Exception) {
            false
        }
    }

    private fun isMultiUserEnabled(): Boolean {
        return try {
            android.os.UserManager::class.java.getMethod("isMultipleUsersSupported")
                .invoke(null) as Boolean
        } catch (e: Exception) {
            false
        }
    }
}
