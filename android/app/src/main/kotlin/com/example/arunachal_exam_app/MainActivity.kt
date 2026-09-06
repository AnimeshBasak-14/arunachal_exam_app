package com.example.arunachal_exam_app

import android.accounts.AccountManager
import android.app.Activity
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.arunachal_exam_app/google_auth"
    private val RC_CHOOSE_ACCOUNT = 9001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickGoogleAccount") {
                try {
                    pendingResult = result
                    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        AccountManager.newChooseAccountIntent(
                            null,
                            null,
                            arrayOf("com.google"),
                            null,
                            null,
                            null,
                            null
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        AccountManager.newChooseAccountIntent(
                            null,
                            null,
                            arrayOf("com.google"),
                            false,
                            null,
                            null,
                            null,
                            null
                        )
                    }
                    startActivityForResult(intent, RC_CHOOSE_ACCOUNT)
                } catch (e: Exception) {
                    pendingResult?.error("PICK_FAILED", e.message, null)
                    pendingResult = null
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == RC_CHOOSE_ACCOUNT) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val accountName = data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME)
                pendingResult?.success(accountName)
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }
}
