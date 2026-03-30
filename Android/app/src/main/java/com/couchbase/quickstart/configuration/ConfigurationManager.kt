package com.couchbase.quickstart.configuration

import android.content.Context
import com.couchbase.quickstart.BuildConfig
import com.google.gson.Gson
import java.io.InputStreamReader

class ConfigurationManager(private val context: Context) {

    private data class ConfigJson(
        val capellaEndpointUrl: String = "",
        val username: String = "",
        val password: String = ""
    )

    fun loadConfiguration(): ConfigurationModel {
        val endpoint = BuildConfig.CAPELLA_ENDPOINT_URL
        val username = BuildConfig.CAPELLA_USERNAME
        val password = BuildConfig.CAPELLA_PASSWORD
        if (endpoint.isNotBlank() && username.isNotBlank() && password.isNotBlank()) {
            return ConfigurationModel(
                capellaEndpointUrl = endpoint,
                username = username,
                password = password
            )
        }

        val rawId = context.resources.getIdentifier("config", "raw", context.packageName)
        check(rawId != 0) { "config.json not found in res/raw" }

        val inputStream = context.resources.openRawResource(rawId)
        val config = Gson().fromJson(InputStreamReader(inputStream), ConfigJson::class.java)
        return ConfigurationModel(
            capellaEndpointUrl = config.capellaEndpointUrl,
            username = config.username,
            password = config.password
        )
    }
}
