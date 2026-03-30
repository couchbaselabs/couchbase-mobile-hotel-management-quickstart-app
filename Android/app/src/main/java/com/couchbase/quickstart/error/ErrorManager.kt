package com.couchbase.quickstart.error

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object ErrorManager {
    private val _errors = MutableStateFlow<List<ErrorModel>>(emptyList())
    val errors: StateFlow<List<ErrorModel>> = _errors.asStateFlow()

    val currentError: ErrorModel? get() = _errors.value.firstOrNull()

    fun showError(error: ErrorModel) {
        _errors.value = _errors.value + error
    }

    fun dismissAndShowNext() {
        val current = _errors.value
        if (current.isNotEmpty()) {
            _errors.value = current.drop(1)
        }
    }
}
