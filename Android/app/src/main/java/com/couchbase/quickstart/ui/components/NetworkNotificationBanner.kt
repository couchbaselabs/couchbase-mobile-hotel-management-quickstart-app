package com.couchbase.quickstart.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay

@Composable
fun NetworkNotificationBanner(isConnected: Boolean) {
    var visible by remember { mutableStateOf(false) }
    var previousState by remember { mutableStateOf<Boolean?>(null) }

    LaunchedEffect(isConnected) {
        if (previousState != null && previousState != isConnected) {
            visible = true
            delay(3000)
            visible = false
        }
        previousState = isConnected
    }

    AnimatedVisibility(
        visible = visible,
        enter = fadeIn(),
        exit = fadeOut()
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(if (isConnected) Color(0xFF4CAF50) else Color(0xFFF44336))
                .padding(8.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = if (isConnected) "You are online" else "You are offline",
                color = Color.White,
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center
            )
        }
    }
}
