package com.couchbase.quickstart.error

data class ErrorModel(
    val title: String,
    val message: String,
    val closable: Boolean = true
)
