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

package com.couchbase.quickstart.data.model

data class HotelFormModel(
    var documentId: String? = null,
    var name: String = "",
    var title: String = "",
    var description: String = "",
    var address: String = "",
    var city: String = "",
    var state: String = "",
    var country: String = "",
    var phone: String = "",
    var email: String = "",
    var url: String = ""
) {
    constructor(hotel: Hotel) : this(
        documentId = hotel.documentId,
        name = hotel.name,
        title = hotel.title,
        description = hotel.description,
        address = hotel.address,
        city = hotel.city,
        state = hotel.state,
        country = hotel.country,
        phone = hotel.phone,
        email = hotel.email,
        url = hotel.url
    )

    fun toHotel(): Hotel = Hotel(
        documentId = documentId,
        name = name,
        title = title,
        description = description,
        address = address,
        city = city,
        state = state,
        country = country,
        phone = phone,
        email = email,
        url = url
    )
}
