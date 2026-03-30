package com.couchbase.quickstart.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val CouchbaseRed = Color(0xFFEA2328)

private val DarkColorScheme = darkColorScheme(
    primary = CouchbaseRed,
    secondary = Color(0xFF9E9E9E),
    tertiary = Color(0xFF757575)
)

private val LightColorScheme = lightColorScheme(
    primary = CouchbaseRed,
    secondary = Color(0xFF757575),
    tertiary = Color(0xFF9E9E9E)
)

@Composable
fun QuickstartTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}
