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

package com.couchbase.quickstart.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.couchbase.quickstart.data.model.Hotel
import com.couchbase.quickstart.error.ErrorManager
import com.couchbase.quickstart.ui.components.ErrorDialog
import com.couchbase.quickstart.ui.viewmodels.HotelListViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HotelListScreen(
    onHotelClick: (Hotel) -> Unit,
    onAddHotel: () -> Unit,
    viewModel: HotelListViewModel = viewModel()
) {
    val hotels by viewModel.hotels.collectAsState()
    val descending by viewModel.descendingList.collectAsState()
    val searchText by viewModel.searchText.collectAsState()
    val showDeleteAlert by viewModel.showDeleteAlert.collectAsState()
    val replicatorStatus by viewModel.replicatorStatus.collectAsState()
    val errors by ErrorManager.errors.collectAsState()

    var showSearch by remember { mutableStateOf(false) }
    var hotelToEdit by remember { mutableStateOf<Hotel?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Hotels")
                        Text(
                            text = "Sync: ${replicatorStatus.lowercase().replaceFirstChar { it.uppercase() }}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                actions = {
                    IconButton(onClick = { showSearch = !showSearch }) {
                        Icon(Icons.Default.Search, contentDescription = "Search")
                    }
                    IconButton(onClick = { viewModel.onSortButtonTapped() }) {
                        Icon(
                            if (descending) Icons.Default.KeyboardArrowDown else Icons.Default.KeyboardArrowUp,
                            contentDescription = "Sort"
                        )
                    }
                    IconButton(
                        onClick = onAddHotel,
                        modifier = Modifier.semantics { contentDescription = "addHotelButton" }
                    ) {
                        Icon(Icons.Default.Add, contentDescription = "Add Hotel")
                    }
                }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            if (showSearch) {
                OutlinedTextField(
                    value = searchText,
                    onValueChange = { viewModel.onSearchTextChanged(it) },
                    placeholder = { Text("Search hotels...") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    singleLine = true,
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) }
                )
            }

            when {
                hotels == null -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
                hotels!!.isEmpty() -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("No hotels found", style = MaterialTheme.typography.bodyLarge)
                    }
                }
                else -> {
                    LazyColumn(modifier = Modifier.fillMaxSize()) {
                        items(hotels!!, key = { it.documentId ?: it.hashCode() }) { hotel ->
                            HotelListItem(
                                hotel = hotel,
                                onClick = { onHotelClick(hotel) },
                                onDelete = { viewModel.onDeleteRequested(hotel) },
                                onEdit = {
                                    hotelToEdit = hotel
                                }
                            )
                            HorizontalDivider()
                        }
                    }
                }
            }
        }
    }

    // Handle edit navigation
    hotelToEdit?.let { hotel ->
        LaunchedEffect(hotel) {
            onHotelClick(hotel)
            hotelToEdit = null
        }
    }

    if (showDeleteAlert) {
        AlertDialog(
            onDismissRequest = { viewModel.deleteItemAlertDismissed() },
            title = { Text("Delete Hotel") },
            text = { Text("Are you sure you want to delete this hotel?") },
            confirmButton = {
                TextButton(onClick = { viewModel.deleteItemAlertAccepted() }) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { viewModel.deleteItemAlertDismissed() }) {
                    Text("Cancel")
                }
            }
        )
    }

    errors.firstOrNull()?.let { error ->
        ErrorDialog(
            error = error,
            onDismiss = { ErrorManager.dismissAndShowNext() }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun HotelListItem(
    hotel: Hotel,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    onEdit: () -> Unit
) {
    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = { value ->
            when (value) {
                SwipeToDismissBoxValue.EndToStart -> {
                    onDelete()
                    false
                }
                SwipeToDismissBoxValue.StartToEnd -> {
                    onEdit()
                    false
                }
                else -> false
            }
        }
    )

    SwipeToDismissBox(
        state = dismissState,
        backgroundContent = {
            val direction = dismissState.dismissDirection
            val color = when (direction) {
                SwipeToDismissBoxValue.StartToEnd -> Color(0xFF2196F3)
                SwipeToDismissBoxValue.EndToStart -> Color(0xFFF44336)
                else -> Color.Transparent
            }
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
                contentAlignment = when (direction) {
                    SwipeToDismissBoxValue.StartToEnd -> Alignment.CenterStart
                    SwipeToDismissBoxValue.EndToStart -> Alignment.CenterEnd
                    else -> Alignment.Center
                }
            ) {
                when (direction) {
                    SwipeToDismissBoxValue.StartToEnd -> Icon(
                        Icons.Default.Edit,
                        contentDescription = "Edit",
                        tint = Color.White
                    )
                    SwipeToDismissBoxValue.EndToStart -> Icon(
                        Icons.Default.Delete,
                        contentDescription = "Delete",
                        tint = Color.White
                    )
                    else -> {}
                }
            }
        }
    ) {
        Surface(
            modifier = Modifier.clickable(onClick = onClick)
        ) {
            ListItem(
                headlineContent = {
                    Text(
                        text = hotel.name.ifBlank { hotel.title },
                        fontWeight = FontWeight.Bold
                    )
                },
                supportingContent = {
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        val location = listOf(hotel.address, hotel.city, hotel.country)
                            .filter { it.isNotBlank() }
                            .joinToString(", ")
                        if (location.isNotBlank()) {
                            Text(location, style = MaterialTheme.typography.bodySmall)
                        }
                        if (hotel.phone.isNotBlank()) {
                            Text(hotel.phone, style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }
            )
        }
    }
}
