//
// Copyright (c) 2025 Couchbase, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

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
