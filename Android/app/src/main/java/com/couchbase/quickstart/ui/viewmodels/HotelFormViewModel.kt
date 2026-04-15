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

package com.couchbase.quickstart.ui.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.couchbase.quickstart.data.database.DatabaseManagerProvider
import com.couchbase.quickstart.data.model.Hotel
import com.couchbase.quickstart.data.model.HotelFormModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

enum class ViewMode { ADD, EDIT }

class HotelFormViewModel(
    application: Application,
    val viewMode: ViewMode,
    existingHotel: Hotel? = null
) : AndroidViewModel(application) {

    private val dbManager = DatabaseManagerProvider.factory(application)

    private val _hotel = MutableStateFlow(
        existingHotel?.let { HotelFormModel(it) } ?: HotelFormModel()
    )
    val hotel: StateFlow<HotelFormModel> = _hotel.asStateFlow()

    private var originalModel = _hotel.value.copy()

    private val _modelDidChange = MutableStateFlow(false)
    val modelDidChange: StateFlow<Boolean> = _modelDidChange.asStateFlow()

    fun getTitle(): String = when (viewMode) {
        ViewMode.ADD -> "New Hotel"
        ViewMode.EDIT -> "Edit Hotel"
    }

    fun updateHotel(update: (HotelFormModel) -> HotelFormModel) {
        _hotel.value = update(_hotel.value)
        _modelDidChange.value = _hotel.value != originalModel
    }

    fun onAcceptButton() {
        val hotelData = _hotel.value.toHotel()
        when (viewMode) {
            ViewMode.ADD -> dbManager.addHotel(hotelData)
            ViewMode.EDIT -> dbManager.updateHotel(hotelData)
        }

        originalModel = _hotel.value.copy()
        _modelDidChange.value = false
    }
}
