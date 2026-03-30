package com.couchbase.quickstart.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.couchbase.quickstart.data.model.Hotel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HotelDetailsScreen(
    hotel: Hotel,
    onBack: () -> Unit,
    onEdit: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(hotel.name ?: hotel.title) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = onEdit) {
                        Icon(Icons.Default.Edit, contentDescription = "Edit")
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
            // Info Section
            DetailSection(title = "Info") {
                hotel.name?.let { DetailRow("Name", it) }
                DetailRow("Title", hotel.title)
                if (hotel.description.isNotBlank()) DetailRow("Description", hotel.description)
            }

            // Address Section
            DetailSection(title = "Address") {
                hotel.address?.let { DetailRow("Address", it) }
                hotel.city?.let { DetailRow("City", it) }
                hotel.state?.let { DetailRow("State", it) }
                if (hotel.country.isNotBlank()) DetailRow("Country", hotel.country)
                if (hotel.geo.lat != 0.0 || hotel.geo.lon != 0.0) {
                    DetailRow("Coordinates", "${hotel.geo.lat}, ${hotel.geo.lon}")
                }
            }

            // Contact Section
            DetailSection(title = "Contact") {
                hotel.phone?.let { DetailRow("Phone", it) }
                hotel.tollfree?.let { DetailRow("Toll Free", it) }
                hotel.fax?.let { DetailRow("Fax", it) }
                hotel.email?.let { DetailRow("Email", it) }
                hotel.url?.let { DetailRow("Website", it) }
                hotel.checkin?.let { DetailRow("Check-in", it) }
                hotel.checkout?.let { DetailRow("Check-out", it) }
                hotel.price?.let { DetailRow("Price", it) }
            }

            // Amenities Section
            DetailSection(title = "Amenities") {
                DetailRow("Vacancy", if (hotel.vacancy) "Yes" else "No")
                DetailRow("Pets OK", if (hotel.petsOk) "Yes" else "No")
                DetailRow("Free Breakfast", if (hotel.freeBreakfast) "Yes" else "No")
                DetailRow("Free Internet", if (hotel.freeInternet) "Yes" else "No")
                DetailRow("Free Parking", if (hotel.freeParking) "Yes" else "No")
            }

            // Reviews Section
            if (hotel.reviews.isNotEmpty()) {
                DetailSection(title = "Reviews") {
                    hotel.reviews.forEach { review ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Text(review.author, fontWeight = FontWeight.Bold)
                                Text(review.date, style = MaterialTheme.typography.bodySmall)
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(review.content)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun DetailSection(title: String, content: @Composable ColumnScope.() -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            content()
        }
    }
}

@Composable
private fun DetailRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.weight(0.4f)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.weight(0.6f)
        )
    }
}
