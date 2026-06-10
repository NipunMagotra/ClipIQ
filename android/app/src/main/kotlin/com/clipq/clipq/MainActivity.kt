package com.clipq.clipq

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        
        var textToCopy: String? = null

        if (Intent.ACTION_PROCESS_TEXT == intent.action && intent.type == "text/plain") {
            textToCopy = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
        } else if (Intent.ACTION_SEND == intent.action && intent.type == "text/plain") {
            textToCopy = intent.getStringExtra(Intent.EXTRA_TEXT)
        }

        if (!textToCopy.isNullOrEmpty()) {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = ClipData.newPlainText("ClipQ Shared Text", textToCopy)
            clipboard.setPrimaryClip(clip)
        }
    }
}
