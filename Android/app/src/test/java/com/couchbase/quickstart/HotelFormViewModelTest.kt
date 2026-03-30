package com.couchbase.quickstart

import android.app.Application
import com.couchbase.quickstart.data.database.DatabaseManagerProvider
import com.couchbase.quickstart.data.database.DatabaseManaging
import com.couchbase.quickstart.data.model.Hotel
import com.couchbase.quickstart.data.model.HotelFormModel
import com.couchbase.quickstart.ui.viewmodels.HotelFormViewModel
import com.couchbase.quickstart.ui.viewmodels.ViewMode
import io.mockk.MockKAnnotations
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.impl.annotations.MockK
import io.mockk.just
import io.mockk.runs
import io.mockk.verify
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class HotelFormViewModelTest {

    @MockK
    private lateinit var mockDb: DatabaseManaging

    @MockK
    private lateinit var app: Application

    @Before
    fun setUp() {
        MockKAnnotations.init(this, relaxed = true)
        every { mockDb.addNewElement(any()) } just runs
        every { mockDb.updateExistingElement(any()) } just runs
        DatabaseManagerProvider.factory = { mockDb }
    }

    @Test
    fun testGetNewHotelTitle() {
        val vm = HotelFormViewModel(app, ViewMode.ADD, null)
        assertEquals("New Hotel", vm.getTitle())
    }

    @Test
    fun testGetEditHotelTitle() {
        val vm = HotelFormViewModel(app, ViewMode.EDIT, Hotel(title = "T", name = "N", country = "US", id = 10))
        assertEquals("Edit Hotel", vm.getTitle())
    }

    @Test
    fun testGetDefaultHotel() {
        val model = HotelFormModel()
        assertEquals("", model.name)
        assertEquals("", model.title)
        assertEquals("hotel", model.type)
        assertFalse(model.vacancy)
        assertFalse(model.petsOk)
    }

    @Test
    fun testModelDidChangeUpdatesWhenEditingFields() {
        val vm = HotelFormViewModel(app, ViewMode.ADD, null)
        assertFalse(vm.modelDidChange.value)
        vm.updateHotel { it.copy(name = "Changed") }
        assertTrue(vm.modelDidChange.value)
    }

    @Test
    fun testAcceptInAddModeCallsAddNewElement() {
        val vm = HotelFormViewModel(app, ViewMode.ADD, null)
        vm.updateHotel { it.copy(name = "My Hotel", country = "US") }
        vm.onAcceptButton()
        verify(exactly = 1) { mockDb.addNewElement(any()) }
        verify(exactly = 0) { mockDb.updateExistingElement(any()) }
    }

    @Test
    fun testAcceptInEditModeCallsUpdateExistingElement() {
        val existing = Hotel(title = "Old", name = "Old Name", country = "US", id = 123)
        val vm = HotelFormViewModel(app, ViewMode.EDIT, existing)
        vm.updateHotel { it.copy(name = "New Name") }
        vm.onAcceptButton()
        verify(exactly = 1) { mockDb.updateExistingElement(match { it.id == 123 }) }
        verify(exactly = 0) { mockDb.addNewElement(any()) }
    }

    @Test
    fun testGetEditHotelData() {
        val hotel = Hotel(
            title = "Test Title",
            name = "Test Hotel",
            description = "Test Description",
            country = "US",
            id = 12345
        )
        val model = HotelFormModel(hotel)
        assertEquals("Test Hotel", model.name)
        assertEquals("Test Title", model.title)
        assertEquals("Test Description", model.description)
        assertEquals("US", model.country)
        assertEquals(12345, model.id)
    }

    @Test
    fun testModelConversionRoundTrip() {
        val original = Hotel(
            title = "Grand Hotel",
            name = "The Grand",
            country = "UK",
            vacancy = true,
            petsOk = false,
            id = 999
        )
        val formModel = HotelFormModel(original)
        val converted = formModel.toHotel()
        assertEquals(original.title, converted.title)
        assertEquals(original.name, converted.name)
        assertEquals(original.country, converted.country)
        assertEquals(original.vacancy, converted.vacancy)
        assertEquals(original.id, converted.id)
    }

    @org.junit.After
    fun tearDown() {
        DatabaseManagerProvider.factory = { context ->
            com.couchbase.quickstart.data.database.DatabaseManager.getInstance(context)
        }
        clearAllMocks()
    }
}
