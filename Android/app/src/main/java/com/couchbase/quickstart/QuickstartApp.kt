package com.couchbase.quickstart

import android.app.Application
import com.couchbase.quickstart.data.database.DatabaseManager
import com.couchbase.quickstart.network.NetworkMonitor

class QuickstartApp : Application() {

    lateinit var networkMonitor: NetworkMonitor
        private set

    override fun onCreate() {
        super.onCreate()
        networkMonitor = NetworkMonitor(this)
        DatabaseManager.getInstance(this).initialize()
    }

    override fun onTerminate() {
        super.onTerminate()
        networkMonitor.unregister()
        DatabaseManager.getInstance(this).close()
    }
}
