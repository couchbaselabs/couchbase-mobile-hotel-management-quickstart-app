package com.couchbase.quickstart

import android.app.Application
import com.couchbase.quickstart.data.database.DatabaseManagerProvider
import com.couchbase.quickstart.data.database.DatabaseManaging
import com.couchbase.quickstart.data.model.Hotel
import com.couchbase.quickstart.ui.viewmodels.HotelListViewModel
import io.mockk.MockKAnnotations
import io.mockk.clearAllMocks
import io.mockk.every
import io.mockk.impl.annotations.MockK
import io.mockk.just
import io.mockk.runs
import io.mockk.verify
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class HotelListViewModelTest {

    private val testDispatcher = StandardTestDispatcher()

    @MockK
    private lateinit var mockDb: DatabaseManaging

    @MockK
    private lateinit var app: Application

    private val queryUpdates = MutableStateFlow<List<Hotel>>(emptyList())

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        MockKAnnotations.init(this, relaxed = true)

        every { mockDb.queryUpdates } returns queryUpdates
        every { mockDb.queryElements(any(), any()) } just runs
        every { mockDb.deleteElement(any()) } just runs

        DatabaseManagerProvider.factory = { mockDb }
    }

    @Test
    fun testInitialState() = runTest {
        val vm = HotelListViewModel(app)

        assertNull(vm.hotels.value)
        assertTrue(vm.descendingList.value)
        assertEquals("", vm.searchText.value)
        assertFalse(vm.showDeleteAlert.value)

        verify(exactly = 1) { mockDb.queryElements(descending = true, textSearch = "") }
    }

    @Test
    fun testQueryUpdatesPropagateToHotels() = runTest {
        val vm = HotelListViewModel(app)

        val hotels = listOf(
            Hotel(title = "Hotel A", name = "Alpha", country = "US", id = 1),
            Hotel(title = "Hotel B", name = "Beta", country = "UK", id = 2)
        )
        queryUpdates.value = hotels
        testDispatcher.scheduler.advanceUntilIdle()

        assertEquals(hotels, vm.hotels.value)
    }

    @Test
    fun testSearchTextTriggersQuery() = runTest {
        val vm = HotelListViewModel(app)
        vm.onSearchTextChanged("Alpha")

        verify { mockDb.queryElements(descending = true, textSearch = "Alpha") }
    }

    @Test
    fun testSortTogglesAndTriggersQuery() = runTest {
        val vm = HotelListViewModel(app)
        vm.onSortButtonTapped()

        assertFalse(vm.descendingList.value)
        verify { mockDb.queryElements(descending = false, textSearch = "") }
    }

    @Test
    fun testDeleteFlowAcceptedCallsDbAndResetsState() = runTest {
        val vm = HotelListViewModel(app)
        val hotel = Hotel(title = "Test", name = "Alpha", country = "US", id = 1)

        vm.onDeleteRequested(hotel)
        assertTrue(vm.showDeleteAlert.value)

        vm.deleteItemAlertAccepted()
        assertFalse(vm.showDeleteAlert.value)
        verify { mockDb.deleteElement(hotel) }
    }

    @Test
    fun testDeleteFlowDismissedResetsStateWithoutDbCall() = runTest {
        val vm = HotelListViewModel(app)
        val hotel = Hotel(title = "Test", name = "Alpha", country = "US", id = 1)

        vm.onDeleteRequested(hotel)
        assertTrue(vm.showDeleteAlert.value)

        vm.deleteItemAlertDismissed()
        assertFalse(vm.showDeleteAlert.value)
        verify(exactly = 0) { mockDb.deleteElement(any()) }
    }

    @org.junit.After
    fun tearDown() {
        DatabaseManagerProvider.factory = { context ->
            com.couchbase.quickstart.data.database.DatabaseManager.getInstance(context)
        }
        clearAllMocks()
        Dispatchers.resetMain()
    }
}
