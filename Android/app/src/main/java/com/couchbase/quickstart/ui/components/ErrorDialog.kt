package com.couchbase.quickstart.ui.components

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import com.couchbase.quickstart.error.ErrorModel

@Composable
fun ErrorDialog(
    error: ErrorModel,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = { if (error.closable) onDismiss() },
        title = { Text(text = error.title) },
        text = { Text(text = error.message) },
        confirmButton = {
            if (error.closable) {
                TextButton(onClick = onDismiss) {
                    Text("OK")
                }
            }
        }
    )
}
