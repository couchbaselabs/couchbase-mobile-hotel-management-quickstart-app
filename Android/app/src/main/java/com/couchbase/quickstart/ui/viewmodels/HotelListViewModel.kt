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
        dbManager.queryElements(
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
        hotelToDelete?.let { dbManager.deleteElement(it) }
        hotelToDelete = null
        _showDeleteAlert.value = false
    }

    fun deleteItemAlertDismissed() {
        hotelToDelete = null
        _showDeleteAlert.value = false
    }
}
