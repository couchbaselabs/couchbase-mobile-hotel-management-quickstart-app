package com.couchbase.quickstart

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.couchbase.quickstart.ui.navigation.NavGraph
import com.couchbase.quickstart.ui.theme.QuickstartTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            QuickstartTheme {
                NavGraph()
            }
        }
    }
}
