package com.distribuidora.paucara.distribuidora

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import android.util.Log

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.distribuidora.paucara/files"
    private val TAG = "FileProvider_PDF"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        try {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "openFile" -> {
                            val filePath = call.argument<String>("path")
                            Log.d(TAG, "openFile called with path: $filePath")

                            if (filePath != null) {
                                val success = openFilePDF(filePath)
                                result.success(success)
                            } else {
                                result.error("INVALID_PATH", "Path is null", null)
                            }
                        }
                        else -> {
                            Log.w(TAG, "Unknown method: ${call.method}")
                            result.notImplemented()
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error handling method call: ${e.message}", e)
                    result.error("ERROR", e.message, null)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up MethodChannel: ${e.message}", e)
        }
    }

    private fun openFilePDF(filePath: String): Boolean {
        return try {
            Log.d(TAG, "openFilePDF: $filePath")

            val file = File(filePath)
            if (!file.exists()) {
                Log.w(TAG, "File does not exist: $filePath")
                return false
            }

            // ✅ Usar FileProvider para obtener URI seguro
            val uri: Uri = FileProvider.getUriForFile(
                this,
                "${packageName}.fileprovider",
                file
            )
            Log.d(TAG, "FileProvider URI: $uri")

            // Crear Intent para abrir el PDF
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/pdf")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }

            // Verificar que existe una app que pueda abrir PDFs
            val componentName = intent.resolveActivity(packageManager)
            if (componentName != null) {
                Log.d(TAG, "Opening file with: ${componentName.packageName}")
                startActivity(intent)
                true
            } else {
                Log.w(TAG, "No app found to open PDF")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error opening PDF: ${e.message}", e)
            e.printStackTrace()
            false
        }
    }
}
