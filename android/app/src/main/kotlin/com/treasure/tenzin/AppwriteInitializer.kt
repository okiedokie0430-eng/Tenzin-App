package com.treasure.tenzin

import android.content.Context
import io.appwrite.Client
import io.appwrite.services.Account
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

object AppwriteInitializer {
    private var initialized = false

    fun init(context: Context) {
        if (initialized) return
        initialized = true

        val client = Client(context)
            .setEndpoint("https://sgp.cloud.appwrite.io/v1")
            .setProject("69536e3f003c0ac930bd")

        // Run a ping in background to verify connectivity
        CoroutineScope(Dispatchers.IO).launch {
            try {
                client.ping()
            } catch (e: Exception) {
                // Ignore; this is only for a quick connectivity check
            }
        }
    }
}
