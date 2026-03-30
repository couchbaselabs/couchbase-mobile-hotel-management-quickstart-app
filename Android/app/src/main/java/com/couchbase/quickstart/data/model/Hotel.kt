package com.couchbase.quickstart.data.model

import com.google.gson.annotations.SerializedName

data class Hotel(
    val title: String = "",
    val name: String? = null,
    val description: String = "",
    val address: String? = null,
    val city: String? = null,
    val state: String? = null,
    val country: String = "",
    val phone: String? = null,
    val tollfree: String? = null,
    val email: String? = null,
    val fax: String? = null,
    val url: String? = null,
    val checkin: String? = null,
    val checkout: String? = null,
    val price: String? = null,
    val geo: Geo = Geo(),
    val vacancy: Boolean = false,
    @SerializedName("pets_ok") val petsOk: Boolean = false,
    @SerializedName("free_breakfast") val freeBreakfast: Boolean = false,
    @SerializedName("free_internet") val freeInternet: Boolean = false,
    @SerializedName("free_parking") val freeParking: Boolean = false,
    val type: String = "hotel",
    val id: Int = 0,
    val reviews: List<Review> = emptyList(),
    @SerializedName("public_likes") val publicLikes: List<String> = emptyList(),
    val alias: String? = null
) : java.io.Serializable

data class Geo(
    val lat: Double = 0.0,
    val lon: Double = 0.0,
    val accuracy: String = ""
) : java.io.Serializable

data class Review(
    val content: String = "",
    val ratings: Map<String, Double> = emptyMap(),
    val author: String = "",
    val date: String = ""
) : java.io.Serializable
