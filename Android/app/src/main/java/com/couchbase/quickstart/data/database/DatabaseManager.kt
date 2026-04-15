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

package com.couchbase.quickstart.data.database

import android.content.Context
import com.couchbase.lite.BasicAuthenticator
import com.couchbase.lite.Collection
import com.couchbase.lite.CouchbaseLite
import com.couchbase.lite.Database
import com.couchbase.lite.FullTextIndexConfiguration
import com.couchbase.lite.ListenerToken
import com.couchbase.lite.LogDomain
import com.couchbase.lite.LogLevel
import com.couchbase.lite.MutableDocument
import com.couchbase.lite.Parameters
import com.couchbase.lite.Query
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorConfigurationFactory
import com.couchbase.lite.ReplicatorType
import com.couchbase.lite.Result
import com.couchbase.lite.URLEndpoint
import com.couchbase.lite.newConfig
import com.couchbase.quickstart.configuration.ConfigurationManager
import com.couchbase.quickstart.data.model.Hotel
import com.couchbase.quickstart.error.ErrorManager
import com.couchbase.quickstart.error.ErrorModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

interface DatabaseManaging {
    val queryUpdates: StateFlow<List<Hotel>>
    val replicatorStatus: StateFlow<String>

    fun initialize(descending: Boolean = true, textSearch: String = "")
    fun queryHotels(descending: Boolean, textSearch: String)
    fun addHotel(hotel: Hotel)
    fun updateHotel(hotel: Hotel)
    fun deleteHotel(hotel: Hotel)
}

object DatabaseManagerProvider {
    @Volatile
    var factory: (Context) -> DatabaseManaging = { context -> DatabaseManager.getInstance(context) }
}

class DatabaseManager private constructor(context: Context) : DatabaseManaging {

    private val appContext = context.applicationContext
    private var database: Database? = null
    private var collection: Collection? = null
    private var replicator: Replicator? = null
    private var queryListenerToken: ListenerToken? = null

    private val _queryUpdates = MutableStateFlow<List<Hotel>>(emptyList())
    override val queryUpdates: StateFlow<List<Hotel>> = _queryUpdates.asStateFlow()

    private val _replicatorStatus = MutableStateFlow("Stopped")
    override val replicatorStatus: StateFlow<String> = _replicatorStatus.asStateFlow()

    companion object {
        @Volatile
        private var instance: DatabaseManager? = null

        fun getInstance(context: Context): DatabaseManager {
            return instance ?: synchronized(this) {
                instance ?: DatabaseManager(context).also { instance = it }
            }
        }

        private const val DATABASE_NAME = "travel-sample"
        private const val SCOPE_NAME = "inventory"
        private const val COLLECTION_NAME = "hotel"
        private const val FTS_INDEX_NAME = "nameFtsIndex"
    }

    // Initializes the Couchbase Lite SDK, opens the database, creates the collection,
    // sets up the full-text index, configures replication, and starts the live query.
    override fun initialize(descending: Boolean, textSearch: String) {
        try {
            CouchbaseLite.init(appContext)
            enableLogging()
            database = Database(DATABASE_NAME)
            collection = database!!.createCollection(COLLECTION_NAME, SCOPE_NAME)

            createFtsIndex()
            setupReplication()
            setupLiveQuery(descending, textSearch)
        } catch (e: Exception) {
            ErrorManager.showError(
                ErrorModel("Database Error", "Failed to initialize database: ${e.message}")
            )
        }
    }

    // Enables verbose console logging for Couchbase Lite to aid debugging.
    private fun enableLogging() {
        Database.log.console.domains = LogDomain.ALL_DOMAINS
        Database.log.console.level = LogLevel.VERBOSE
    }

    // Creates a full-text search index on the hotel "name" property using FullTextIndexConfiguration.
    private fun createFtsIndex() {
        try {
            val col = collection ?: return
            val ftsIndex = FullTextIndexConfiguration("name").ignoreAccents(false)
            col.createIndex(FTS_INDEX_NAME, ftsIndex)
        } catch (e: Exception) {
            // Index may already exist
        }
    }

    // Configures and starts a continuous push-and-pull replicator with Capella App Services.
    // Listens for replicator status changes and surfaces them via replicatorStatus flow.
    private fun setupReplication() {
        try {
            val config = ConfigurationManager(appContext).loadConfiguration()
            if (config.capellaEndpointUrl.isBlank()) return

            val col = collection ?: return

            val targetEndpoint = URLEndpoint(java.net.URI(config.capellaEndpointUrl))
            val replConfig = ReplicatorConfigurationFactory.newConfig(
                target = targetEndpoint,
                collections = mapOf(listOf(col) to null),
                type = ReplicatorType.PUSH_AND_PULL,
                continuous = true,
                authenticator = BasicAuthenticator(config.username, config.password.toCharArray())
            )

            replicator = Replicator(replConfig).apply {
                // Listen for replicator status changes and update the status flow.
                addChangeListener { change ->
                    _replicatorStatus.value = change.status.activityLevel.name
                    change.status.error?.let { error ->
                        ErrorManager.showError(
                            ErrorModel("Sync Error", "Replication error: ${error.message}")
                        )
                    }
                }
                start()
            }
        } catch (e: Exception) {
            ErrorManager.showError(
                ErrorModel("Sync Error", "Failed to setup replication: ${e.message}")
            )
        }
    }

    // Sets up a live SQL++ query that listens for changes to hotel documents.
    // The query includes META().id so each Hotel carries its document ID.
    private fun setupLiveQuery(descending: Boolean, textSearch: String) {
        try {
            val db = database ?: return

            queryListenerToken?.remove()

            val sortOrder = if (descending) "DESC" else "ASC"
            val query: Query = if (textSearch.isNotBlank()) {
                val pattern = "$textSearch*"
                db.createQuery(
                    "SELECT META().id AS documentId, * FROM `$SCOPE_NAME`.`$COLLECTION_NAME` AS hotel " +
                    "WHERE MATCH($FTS_INDEX_NAME, \$searchTerm) " +
                    "ORDER BY RANK($FTS_INDEX_NAME) $sortOrder"
                ).also {
                    it.parameters = Parameters().apply { setString("searchTerm", pattern) }
                }
            } else {
                db.createQuery(
                    "SELECT META().id AS documentId, * FROM `$SCOPE_NAME`.`$COLLECTION_NAME` AS hotel " +
                    "ORDER BY hotel.name $sortOrder"
                )
            }

            queryListenerToken = query.addChangeListener { change ->
                change.results?.let { results ->
                    val hotels = results.allResults().mapNotNull { result ->
                        resultToHotel(result)
                    }
                    _queryUpdates.value = hotels
                }
            }
        } catch (e: Exception) {
            ErrorManager.showError(
                ErrorModel("Query Error", "Failed to run query: ${e.message}")
            )
        }
    }

    // Re-runs the live query with updated sort order or search text.
    override fun queryHotels(descending: Boolean, textSearch: String) {
        setupLiveQuery(descending, textSearch)
    }

    // Creates and saves a new hotel document to the collection.
    override fun addHotel(hotel: Hotel) {
        try {
            val col = collection ?: return
            val doc = MutableDocument().apply {
                setString("type", "hotel")
                setString("name", hotel.name)
                setString("title", hotel.title)
                setString("description", hotel.description)
                setString("address", hotel.address)
                setString("city", hotel.city)
                setString("state", hotel.state)
                setString("country", hotel.country)
                setString("phone", hotel.phone)
                setString("email", hotel.email)
                setString("url", hotel.url)
            }
            col.save(doc)
        } catch (e: Exception) {
            ErrorManager.showError(
                ErrorModel("Save Error", "Failed to save hotel: ${e.message}")
            )
        }
    }

    // Updates an existing hotel document using its document ID.
    // Falls back to addHotel() if the document ID is not available.
    override fun updateHotel(hotel: Hotel) {
        try {
            val col = collection ?: return
            val docId = hotel.documentId ?: run {
                addHotel(hotel)
                return
            }
            val existingDoc = col.getDocument(docId) ?: return
            val mutableDoc = existingDoc.toMutable().apply {
                setString("name", hotel.name)
                setString("title", hotel.title)
                setString("description", hotel.description)
                setString("address", hotel.address)
                setString("city", hotel.city)
                setString("state", hotel.state)
                setString("country", hotel.country)
                setString("phone", hotel.phone)
                setString("email", hotel.email)
                setString("url", hotel.url)
            }
            col.save(mutableDoc)
        } catch (e: Exception) {
            ErrorManager.showError(
                ErrorModel("Update Error", "Failed to update hotel: ${e.message}")
            )
        }
    }

    // Deletes a hotel document using its document ID.
    override fun deleteHotel(hotel: Hotel) {
        try {
            val col = collection ?: return
            val docId = hotel.documentId ?: return
            col.getDocument(docId)?.let { doc -> col.delete(doc) }
        } catch (e: Exception) {
            ErrorManager.showError(
                ErrorModel("Delete Error", "Failed to delete hotel: ${e.message}")
            )
        }
    }

    // Converts a query result row into a Hotel object, including the document ID.
    private fun resultToHotel(result: Result): Hotel? {
        return try {
            val documentId = result.getString("documentId")
            val hotelDict = result.getDictionary("hotel") ?: return null

            Hotel(
                documentId = documentId,
                name = hotelDict.getString("name") ?: "",
                title = hotelDict.getString("title") ?: "",
                description = hotelDict.getString("description") ?: "",
                address = hotelDict.getString("address") ?: "",
                city = hotelDict.getString("city") ?: "",
                state = hotelDict.getString("state") ?: "",
                country = hotelDict.getString("country") ?: "",
                phone = hotelDict.getString("phone") ?: "",
                email = hotelDict.getString("email") ?: "",
                url = hotelDict.getString("url") ?: ""
            )
        } catch (e: Exception) {
            null
        }
    }

    // Stops the replicator, removes query listeners, and closes the database.
    fun close() {
        queryListenerToken?.remove()
        replicator?.stop()
        database?.close()
    }
}
