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
            ViewMode.ADD -> dbManager.addNewElement(hotelData)
            ViewMode.EDIT -> dbManager.updateExistingElement(hotelData)
        }

        originalModel = _hotel.value.copy()
        _modelDidChange.value = false
    }
}
