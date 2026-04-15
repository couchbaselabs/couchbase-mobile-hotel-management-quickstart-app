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
import androidx.lifecycle.viewModelScope
import com.couchbase.quickstart.data.database.DatabaseManagerProvider
import com.couchbase.quickstart.data.model.Hotel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class HotelListViewModel(application: Application) : AndroidViewModel(application) {

    private val dbManager = DatabaseManagerProvider.factory(application)

    private val _hotels = MutableStateFlow<List<Hotel>?>(null)
    val hotels: StateFlow<List<Hotel>?> = _hotels.asStateFlow()

    val replicatorStatus: StateFlow<String> = dbManager.replicatorStatus

    private val _descendingList = MutableStateFlow(true)
    val descendingList: StateFlow<Boolean> = _descendingList.asStateFlow()

    private val _searchText = MutableStateFlow("")
    val searchText: StateFlow<String> = _searchText.asStateFlow()

    private val _showDeleteAlert = MutableStateFlow(false)
    val showDeleteAlert: StateFlow<Boolean> = _showDeleteAlert.asStateFlow()

    private var hotelToDelete: Hotel? = null

    init {
        bindListeners()
        query()
    }

    private fun bindListeners() {
        viewModelScope.launch {
            dbManager.queryUpdates.collect { hotels ->
                _hotels.value = hotels
            }
        }
    }

    private fun query() {
        dbManager.queryHotels(
            descending = _descendingList.value,
            textSearch = _searchText.value
        )
    }

    fun onSearchTextChanged(text: String) {
        _searchText.value = text
        query()
    }

    fun onSortButtonTapped() {
        _descendingList.value = !_descendingList.value
        query()
    }

    fun onDeleteRequested(hotel: Hotel) {
        hotelToDelete = hotel
        _showDeleteAlert.value = true
    }

    fun deleteItemAlertAccepted() {
        hotelToDelete?.let { dbManager.deleteHotel(it) }
        hotelToDelete = null
        _showDeleteAlert.value = false
    }

    fun deleteItemAlertDismissed() {
        hotelToDelete = null
        _showDeleteAlert.value = false
    }
}
