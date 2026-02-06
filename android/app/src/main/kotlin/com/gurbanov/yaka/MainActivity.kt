package com.gurbanov.yaka

import android.os.Bundle
import android.content.Context
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.usb_storage"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getUSBPath") {
                val usbPath = getUSBStoragePath()
                result.success(usbPath)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getUSBStoragePath(): String? {
        val storageManager = getSystemService(Context.STORAGE_SERVICE) as StorageManager
        val volumes = storageManager.storageVolumes

        for (volume in volumes) {
            val file = volume.directory
            if (file != null && file.exists()) {
                return file.absolutePath
            }
        }
        return null
    }
}

