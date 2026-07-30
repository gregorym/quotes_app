package com.mars6.noexcuse

import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.mars6.noexcuse/share"
        ).setMethodCallHandler { call, result ->
            if (call.method != "share") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val text = call.argument<String>("text")
            val path = call.argument<String>("filePath")
            val file = path?.let(::File)
            if (text == null || file == null || !file.isFile) {
                result.error("invalid_share", "The quote image is unavailable.", null)
                return@setMethodCallHandler
            }

            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.provider",
                file
            )
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "image/png"
                putExtra(Intent.EXTRA_TEXT, text)
                putExtra(Intent.EXTRA_STREAM, uri)
                clipData = ClipData.newRawUri("No Excuses quote", uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(shareIntent, "Share quote"))
            result.success(null)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.mars6.noexcuse/settings"
        ).setMethodCallHandler { call, result ->
            if (call.method != "openSystemSettings") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:$packageName")
                )
            )
            result.success(true)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.mars6.noexcuse/links"
        ).setMethodCallHandler { call, result ->
            val url = call.arguments as? String
            val uri = url?.let(Uri::parse)
            if (call.method != "openURL" || uri?.scheme != "https") {
                result.error("invalid_url", "Only secure links can be opened.", null)
                return@setMethodCallHandler
            }
            startActivity(Intent(Intent.ACTION_VIEW, uri))
            result.success(true)
        }
    }
}
