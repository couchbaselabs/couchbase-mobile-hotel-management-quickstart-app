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

import android.app.Application
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import com.couchbase.quickstart.data.model.Hotel
import com.couchbase.quickstart.ui.viewmodels.HotelFormViewModel
import com.couchbase.quickstart.ui.viewmodels.ViewMode

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HotelFormScreen(
    existingHotel: Hotel?,
    onBack: () -> Unit,
    onSaved: () -> Unit
) {
    val context = LocalContext.current
    val viewMode = if (existingHotel == null) ViewMode.ADD else ViewMode.EDIT
    val viewModel: HotelFormViewModel = viewModel(
        factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return HotelFormViewModel(
                    context.applicationContext as Application,
                    viewMode,
                    existingHotel
                ) as T
            }
        }
    )

    val hotel by viewModel.hotel.collectAsState()
    val modelDidChange by viewModel.modelDidChange.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(viewModel.getTitle()) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            viewModel.onAcceptButton()
                            onSaved()
                        },
                        enabled = modelDidChange,
                        modifier = Modifier.semantics { contentDescription = "HotelFormViewAcceptButton" }
                    ) {
                        Text("Save")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Basic Info Section
            FormSection(title = "Basic Info") {
                FormTextField(
                    label = "Name",
                    value = hotel.name,
                    onValueChange = { viewModel.updateHotel { h -> h.copy(name = it) } },
                    semanticTag = "NameFormTextField"
                )
                FormTextField(
                    label = "Title",
                    value = hotel.title,
                    onValueChange = { viewModel.updateHotel { h -> h.copy(title = it) } },
                    semanticTag = "TitleFormTextField"
                )
                OutlinedTextField(
                    value = hotel.description,
                    onValueChange = { viewModel.updateHotel { h -> h.copy(description = it) } },
                    label = { Text("Description") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp)
                        .semantics { contentDescription = "DescriptionFormTextField" },
                    maxLines = 5
                )
            }

            // Location Section
            FormSection(title = "Location") {
                FormTextField(
                    label = "Address",
                    value = hotel.address,
                    onValueChange = { viewModel.updateHotel { h -> h.copy(address = it) } },
                    semanticTag = "AddressFormTextField"
                )
                FormTextField(
                    label = "City",
                    value = hotel.city,
                    onValueChange = { viewModel.updateHotel { h -> h.copy(city = it) } },
                    semanticTag = "CityFormTextField"
                )
                FormTextField(
                    label = "State",
                    value = hotel.state,
                    onValueChange = { viewModel.updateHotel { h -> h.copy(state = it) } },
                    semanticTag = "StateFormTextField"
                )
                FormTextField(
                    label = "Country",
                    value = hotel.country,
                    onValueChange = { viewModel.updateHotel { h -> h.copy(country = it) } },
                    semanticTag = "CountryFormTextField"
                )
            }

            // Contact Section
            FormSection(title = "Contact") {
                FormTextField(
                    label = "Phone",
                    value = hotel.phone,
                    onValueChange = { viewModel.updateHotel { h -> h.copy(phone = it) } },
                    keyboardType = KeyboardType.Phone,
                    semanticTag = "PhoneFormTextField"
                )
                FormTextField(
                    label = "Email",
                    value = hotel.email,
                    onValueChange = { viewModel.updateHotel { h -> h.copy(email = it) } },
                    keyboardType = KeyboardType.Email,
                    semanticTag = "EmailFormTextField"
                )
                FormTextField(
                    label = "Website",
                    value = hotel.url,
                    onValueChange = { viewModel.updateHotel { h -> h.copy(url = it) } },
                    keyboardType = KeyboardType.Uri,
                    semanticTag = "UrlFormTextField"
                )
            }
        }
    }
}

@Composable
private fun FormSection(title: String, content: @Composable ColumnScope.() -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium
            )
            content()
        }
    }
}

@Composable
private fun FormTextField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    keyboardType: KeyboardType = KeyboardType.Text,
    semanticTag: String = ""
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label) },
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (semanticTag.isNotBlank())
                    Modifier.semantics { contentDescription = semanticTag }
                else Modifier
            ),
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
        singleLine = true
    )
}

