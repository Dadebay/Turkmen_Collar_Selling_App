package com.gurbanov.yaka

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.usb_storage"
    private val systemUiChannelName = "com.gurbanov.yaka/system_ui"
    private val smsConsentChannelName = "com.gurbanov.yaka/sms_consent"
    private val smsConsentRequestCode = 7172
    private lateinit var usbStorageBridge: UsbStorageBridge
    private var usbStorageChannel: MethodChannel? = null
    private var smsConsentChannel: MethodChannel? = null
    private var smsConsentReceiver: BroadcastReceiver? = null

    private fun smsDiagnostic(event: String) {
        if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) == 0) return
        smsConsentChannel?.invokeMethod("diagnostic", event)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usbStorageBridge = UsbStorageBridge(this)
        usbStorageChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also { channel ->
            channel.setMethodCallHandler(usbStorageBridge::handle)
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, systemUiChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "showNavigationBar") {
                    showNavigationBar()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        smsConsentChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            smsConsentChannelName
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> startSmsConsent(result)
                    "stop" -> {
                        stopSmsConsent()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        notifyUsbIntent(intent)
        window.decorView.post { showNavigationBar() }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            window.decorView.post { showNavigationBar() }
        }
    }

    private fun showNavigationBar() {
        @Suppress("DEPRECATION")
        val hiddenNavigationFlags =
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_IMMERSIVE or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        @Suppress("DEPRECATION")
        val currentFlags = window.decorView.systemUiVisibility
        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility = currentFlags and hiddenNavigationFlags.inv()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.show(WindowInsets.Type.navigationBars())
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        notifyUsbIntent(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == smsConsentRequestCode) {
            smsDiagnostic("consent result; approved=${resultCode == Activity.RESULT_OK}; hasMessage=${data?.hasExtra(SmsRetriever.EXTRA_SMS_MESSAGE) == true}")
            if (resultCode == Activity.RESULT_OK) {
                data?.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE)?.let { message ->
                    smsConsentChannel?.invokeMethod("smsMessage", message)
                }
            }
            return
        }
        if (::usbStorageBridge.isInitialized && usbStorageBridge.onActivityResult(requestCode, resultCode, data)) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun startSmsConsent(result: MethodChannel.Result) {
        smsDiagnostic("consent start requested")
        stopSmsConsent()
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action != SmsRetriever.SMS_RETRIEVED_ACTION) return
                val status = intent.getParcelableExtra<Status>(SmsRetriever.EXTRA_STATUS)
                smsDiagnostic("consent broadcast; status=${status?.statusCode}")
                when (status?.statusCode) {
                    CommonStatusCodes.SUCCESS -> {
                        val consentIntent = intent.getParcelableExtra<Intent>(
                            SmsRetriever.EXTRA_CONSENT_INTENT
                        )
                        smsDiagnostic("consent intent available=${consentIntent != null}")
                        stopSmsConsent()
                        if (consentIntent != null) {
                            try {
                                startActivityForResult(consentIntent, smsConsentRequestCode)
                                smsDiagnostic("consent prompt opened")
                            } catch (error: Exception) {
                                smsDiagnostic("consent prompt failed: ${error.javaClass.simpleName}")
                                // Manual code entry remains available.
                            }
                        }
                    }
                    CommonStatusCodes.TIMEOUT -> {
                        smsDiagnostic("consent timed out")
                        stopSmsConsent()
                    }
                }
            }
        }
        try {
            val filter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(
                    receiver,
                    filter,
                    SmsRetriever.SEND_PERMISSION,
                    null,
                    Context.RECEIVER_EXPORTED
                )
            } else {
                registerReceiver(receiver, filter, SmsRetriever.SEND_PERMISSION, null)
            }
            smsConsentReceiver = receiver
            smsDiagnostic("consent receiver registered")
            SmsRetriever.getClient(this).startSmsUserConsent(null)
                .addOnSuccessListener {
                    smsDiagnostic("consent listener started")
                    result.success(null)
                }
                .addOnFailureListener { error ->
                    smsDiagnostic("consent listener failed: ${error.javaClass.simpleName}")
                    stopSmsConsent()
                    result.error("SMS_CONSENT", error.message, null)
                }
        } catch (error: Exception) {
            smsDiagnostic("consent setup failed: ${error.javaClass.simpleName}")
            stopSmsConsent()
            result.error("SMS_CONSENT", error.message, null)
        }
    }

    private fun stopSmsConsent() {
        smsConsentReceiver?.let { receiver ->
            smsDiagnostic("consent receiver stopped")
            try {
                unregisterReceiver(receiver)
            } catch (_: IllegalArgumentException) {
                // Already unregistered after a completed SMS flow.
            }
        }
        smsConsentReceiver = null
    }

    override fun onDestroy() {
        stopSmsConsent()
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (::usbStorageBridge.isInitialized &&
            usbStorageBridge.onRequestPermissionsResult(requestCode, grantResults)
        ) {
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private fun notifyUsbIntent(intent: Intent?) {
        if (intent?.action != UsbManager.ACTION_USB_DEVICE_ATTACHED || !::usbStorageBridge.isInitialized) {
            return
        }

        usbStorageChannel?.invokeMethod(
            "onUsbPermissionGranted",
            usbStorageBridge.detectUsbPath()
        )
    }
}
