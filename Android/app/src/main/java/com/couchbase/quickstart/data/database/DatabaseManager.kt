package com.couchbase.quickstart.data.database

import android.content.Context
import com.couchbase.lite.BasicAuthenticator
import com.couchbase.lite.Collection
import com.couchbase.lite.CouchbaseLite
import com.couchbase.lite.Database
import com.couchbase.lite.FullTextIndexItem
import com.couchbase.lite.IndexBuilder
import com.couchbase.lite.ListenerToken
import com.couchbase.lite.MutableArray
import com.couchbase.lite.MutableDictionary
import com.couchbase.lite.MutableDocument
import com.couchbase.lite.Parameters
import com.couchbase.lite.Query
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorConfiguration
import com.couchbase.lite.ReplicatorType
import com.couchbase.lite.Result
import com.couchbase.lite.URLEndpoint
import com.couchbase.quickstart.configuration.ConfigurationManager
import com.couchbase.quickstart.data.model.Geo
import com.couchbase.quickstart.data.model.Hotel
import com.couchbase.quickstart.data.model.Review
import com.couchbase.quickstart.error.ErrorManager
import com.couchbase.quickstart.error.ErrorModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

interface DatabaseManaging {
    val queryUpdates: StateFlow<List<Hotel>>

    fun initialize(descending: Boolean = true, textSearch: String = "")
    fun queryElements(descending: Boolean, textSearch: String)
    fun addNewElement(hotel: Hotel)
    fun updateExistingElement(hotel: Hotel)
    fun deleteElement(hotel: Hotel)
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

    override fun initialize(descending: Boolean, textSearch: String) {
        try {
            CouchbaseLite.init(appContext)
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

    private fun createFtsIndex() {
        try {
            val col = collection ?: return
            val ftsIndex = IndexBuilder.fullTextIndex(FullTextIndexItem.property("name"))
                .ignoreAccents(false)
            col.createIndex(FTS_INDEX_NAME, ftsIndex)
        } catch (e: Exception) {
            // Index may already exist
        }
    }

    private fun setupReplication() {
        try {
            val config = ConfigurationManager(appContext).loadConfiguration()
            if (config.capellaEndpointUrl.isBlank()) return

            val col = collection ?: return

            val targetEndpoint = URLEndpoint(java.net.URI(config.capellaEndpointUrl))
            val replConfig = ReplicatorConfiguration(targetEndpoint).apply {
                addCollection(col, null)
                type = ReplicatorType.PUSH_AND_PULL
                isContinuous = true
                authenticator = BasicAuthenticator(config.username, config.password.toCharArray())
            }

            replicator = Replicator(replConfig).apply { start() }
        } catch (e: Exception) {
            ErrorManager.showError(
                ErrorModel("Sync Error", "Failed to setup replication: ${e.message}")
            )
        }
    }

    private fun setupLiveQuery(descending: Boolean, textSearch: String) {
        try {
            val db = database ?: return

            queryListenerToken?.remove()

            val sortOrder = if (descending) "DESC" else "ASC"
            val query: Query = if (textSearch.isNotBlank()) {
                val pattern = "$textSearch*"
                db.createQuery(
                    "SELECT * FROM `$SCOPE_NAME`.`$COLLECTION_NAME` AS hotel " +
                    "WHERE MATCH($FTS_INDEX_NAME, \$searchTerm) " +
                    "ORDER BY RANK($FTS_INDEX_NAME) $sortOrder"
                ).also {
                    it.parameters = Parameters().apply { setString("searchTerm", pattern) }
                }
            } else {
                db.createQuery(
                    "SELECT * FROM `$SCOPE_NAME`.`$COLLECTION_NAME` AS hotel " +
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

    override fun queryElements(descending: Boolean, textSearch: String) {
        setupLiveQuery(descending, textSearch)
    }

    override fun addNewElement(hotel: Hotel) {
        try {
            val col = collection ?: return
            val doc = MutableDocument().apply {
                setString("type", hotel.type)
                setInt("id", hotel.id)
                setString("title", hotel.title)
                setString("name", hotel.name)
                setString("description", hotel.description)
                setString("address", hotel.address)
                setString("city", hotel.city)
                setString("state", hotel.state)
                setString("country", hotel.country)
                setString("phone", hotel.phone)
                setString("tollfree", hotel.tollfree)
                setString("email", hotel.email)
                setString("fax", hotel.fax)
                setString("url", hotel.url)
                setString("checkin", hotel.checkin)
                setString("checkout", hotel.checkout)
                setString("price", hotel.price)
                setBoolean("vacancy", hotel.vacancy)
                setBoolean("pets_ok", hotel.petsOk)
                setBoolean("free_breakfast", hotel.freeBreakfast)
                setBoolean("free_internet", hotel.freeInternet)
                setBoolean("free_parking", hotel.freeParking)
                setString("alias", hotel.alias)
                setDictionary("geo", MutableDictionary().apply {
                    setDouble("lat", hotel.geo.lat)
                    setDouble("lon", hotel.geo.lon)
                    setString("accuracy", hotel.geo.accuracy)
                })
                setArray("reviews", MutableArray().apply {
                    hotel.reviews.forEach { review ->
                        addDictionary(MutableDictionary().apply {
                            setString("content", review.content)
                            setString("author", review.author)
                            setString("date", review.date)
                        })
                    }
                })
                setArray("public_likes", MutableArray().apply {
                    hotel.publicLikes.forEach { addString(it) }
                })
            }
            col.save(doc)
        } catch (e: Exception) {
            ErrorManager.showError(
                ErrorModel("Save Error", "Failed to save hotel: ${e.message}")
            )
        }
    }

    override fun updateExistingElement(hotel: Hotel) {
        try {
            val col = collection ?: return
            val db = database ?: return

            val query = db.createQuery(
                "SELECT META().id FROM `$SCOPE_NAME`.`$COLLECTION_NAME` AS hotel WHERE hotel.id = \$hotelId"
            ).also {
                it.parameters = Parameters().apply { setInt("hotelId", hotel.id) }
            }

            val result = query.execute().allResults().firstOrNull() ?: run {
                addNewElement(hotel)
                return
            }

            val docId = result.getString("id") ?: return
            val existingDoc = col.getDocument(docId) ?: return
            val mutableDoc = existingDoc.toMutable().apply {
                setString("title", hotel.title)
                setString("name", hotel.name)
                setString("description", hotel.description)
                setString("address", hotel.address)
                setString("city", hotel.city)
                setString("state", hotel.state)
                setString("country", hotel.country)
                setString("phone", hotel.phone)
                setString("tollfree", hotel.tollfree)
                setString("email", hotel.email)
                setString("fax", hotel.fax)
                setString("url", hotel.url)
                setString("checkin", hotel.checkin)
                setString("checkout", hotel.checkout)
                setString("price", hotel.price)
                setBoolean("vacancy", hotel.vacancy)
                setBoolean("pets_ok", hotel.petsOk)
                setBoolean("free_breakfast", hotel.freeBreakfast)
                setBoolean("free_internet", hotel.freeInternet)
                setBoolean("free_parking", hotel.freeParking)
                setString("alias", hotel.alias)
                setDictionary("geo", MutableDictionary().apply {
                    setDouble("lat", hotel.geo.lat)
                    setDouble("lon", hotel.geo.lon)
                    setString("accuracy", hotel.geo.accuracy)
                })
            }
            col.save(mutableDoc)
        } catch (e: Exception) {
            ErrorManager.showError(
                ErrorModel("Update Error", "Failed to update hotel: ${e.message}")
            )
        }
    }

    override fun deleteElement(hotel: Hotel) {
        try {
            val col = collection ?: return
            val db = database ?: return

            val query = db.createQuery(
                "SELECT META().id FROM `$SCOPE_NAME`.`$COLLECTION_NAME` AS hotel WHERE hotel.id = \$hotelId"
            ).also {
                it.parameters = Parameters().apply { setInt("hotelId", hotel.id) }
            }

            query.execute().allResults().forEach { result ->
                val docId = result.getString("id") ?: return@forEach
                col.getDocument(docId)?.let { doc -> col.delete(doc) }
            }
        } catch (e: Exception) {
            ErrorManager.showError(
                ErrorModel("Delete Error", "Failed to delete hotel: ${e.message}")
            )
        }
    }

    fun deleteElementWithName(name: String) {
        try {
            val col = collection ?: return
            val db = database ?: return

            val query = db.createQuery(
                "SELECT META().id FROM `$SCOPE_NAME`.`$COLLECTION_NAME` AS hotel WHERE hotel.name = \$name"
            ).also {
                it.parameters = Parameters().apply { setString("name", name) }
            }

            query.execute().allResults().forEach { result ->
                val docId = result.getString("id") ?: return@forEach
                col.getDocument(docId)?.let { doc -> col.delete(doc) }
            }
        } catch (e: Exception) {
            ErrorManager.showError(
                ErrorModel("Delete Error", "Failed to delete hotel: ${e.message}")
            )
        }
    }

    private fun resultToHotel(result: Result): Hotel? {
        return try {
            val hotelDict = result.getDictionary("hotel") ?: return null
            val geoDict = hotelDict.getDictionary("geo")
            val reviewsArray = hotelDict.getArray("reviews")
            val publicLikesArray = hotelDict.getArray("public_likes")

            Hotel(
                title = hotelDict.getString("title") ?: "",
                name = hotelDict.getString("name"),
                description = hotelDict.getString("description") ?: "",
                address = hotelDict.getString("address"),
                city = hotelDict.getString("city"),
                state = hotelDict.getString("state"),
                country = hotelDict.getString("country") ?: "",
                phone = hotelDict.getString("phone"),
                tollfree = hotelDict.getString("tollfree"),
                email = hotelDict.getString("email"),
                fax = hotelDict.getString("fax"),
                url = hotelDict.getString("url"),
                checkin = hotelDict.getString("checkin"),
                checkout = hotelDict.getString("checkout"),
                price = hotelDict.getString("price"),
                geo = Geo(
                    lat = geoDict?.getDouble("lat") ?: 0.0,
                    lon = geoDict?.getDouble("lon") ?: 0.0,
                    accuracy = geoDict?.getString("accuracy") ?: ""
                ),
                vacancy = hotelDict.getBoolean("vacancy"),
                petsOk = hotelDict.getBoolean("pets_ok"),
                freeBreakfast = hotelDict.getBoolean("free_breakfast"),
                freeInternet = hotelDict.getBoolean("free_internet"),
                freeParking = hotelDict.getBoolean("free_parking"),
                type = hotelDict.getString("type") ?: "hotel",
                id = hotelDict.getInt("id"),
                reviews = (0 until (reviewsArray?.count() ?: 0)).mapNotNull { i ->
                    reviewsArray?.getDictionary(i)?.let { r ->
                        Review(
                            content = r.getString("content") ?: "",
                            author = r.getString("author") ?: "",
                            date = r.getString("date") ?: ""
                        )
                    }
                },
                publicLikes = (0 until (publicLikesArray?.count() ?: 0)).mapNotNull { i ->
                    publicLikesArray?.getString(i)
                },
                alias = hotelDict.getString("alias")
            )
        } catch (e: Exception) {
            null
        }
    }

    fun close() {
        queryListenerToken?.remove()
        replicator?.stop()
        database?.close()
    }
}
