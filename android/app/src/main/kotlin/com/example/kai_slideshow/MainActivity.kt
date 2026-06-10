package com.example.kai_slideshow

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "kai_slideshow/intents"
    private var initialUris: List<String> = emptyList()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(
            object : MethodCallHandler {
                override fun onMethodCall(call: MethodChannel.MethodCall, result: Result) {
                    when (call.method) {
                        "getInitialUris" -> {
                            result.success(initialUris)
                        }
                        "getFilePathFromUri" -> {
                            val uriString = call.argument<String>("uri")
                            if (uriString != null) {
                                val filePath = getFilePathFromUri(Uri.parse(uriString))
                                result.success(filePath)
                            } else {
                                result.success(null)
                            }
                        }
                        "getImageBytesFromUri" -> {
                            val uriString = call.argument<String>("uri")
                            if (uriString != null) {
                                val bytes = getImageBytesFromUri(Uri.parse(uriString))
                                result.success(bytes)
                            } else {
                                result.success(null)
                            }
                        }
                        else -> {
                            result.notImplemented()
                        }
                    }
                }
            }
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIncomingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIncomingIntent(intent)
    }

    private fun handleIncomingIntent(intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SEND -> {
                // Single image
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                uri?.let {
                    initialUris = listOf(it.toString())
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                // Multiple images
                val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                uris?.let {
                    initialUris = it.map { uri -> uri.toString() }
                }
            }
        }
    }

    /**
     * Get file path from content URI
     * This works for most Android versions
     */
    private fun getFilePathFromUri(uri: Uri): String? {
        return try {
            val projection = arrayOf(OpenableColumns.DISPLAY_NAME)
            val cursor = contentResolver.query(uri, projection, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val displayNameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (displayNameIndex != -1) {
                        val displayName = it.getString(displayNameIndex)
                        // For content URIs, we'll use the URI directly in Dart
                        // as we can't always get a file path
                        return uri.toString()
                    }
                }
            }
            uri.toString()
        } catch (e: Exception) {
            Log.e("KaiSlideshow", "Error getting file path from URI", e)
            uri.toString()
        }
    }

    /**
     * Get image bytes from content URI
     * This is the most reliable way to handle content URIs from Share intent
     */
    private fun getImageBytesFromUri(uri: Uri): ByteArray? {
        return try {
            val inputStream: InputStream? = contentResolver.openInputStream(uri)
            inputStream?.use {
                val byteArrayOutputStream = ByteArrayOutputStream()
                val buffer = ByteArray(1024)
                var bytesRead: Int
                while (it.read(buffer).also { bytesRead = it } != -1) {
                    byteArrayOutputStream.write(buffer, 0, bytesRead)
                }
                byteArrayOutputStream.toByteArray()
            }
        } catch (e: Exception) {
            Log.e("KaiSlideshow", "Error reading image bytes from URI", e)
            null
        }
    }
}
