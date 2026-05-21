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

import 'package:hotel_quickstart/model/hotel.dart';

class HotelFormModel {
  String? documentId;
  String name;
  String title;
  String description;
  String address;
  String city;
  String state;
  String country;
  String phone;
  String email;
  String url;

  HotelFormModel({
    this.documentId,
    this.name = '',
    this.title = '',
    this.description = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.phone = '',
    this.email = '',
    this.url = '',
  });

  HotelFormModel.fromHotel(Hotel hotel)
      : documentId = hotel.documentId,
        name = hotel.name,
        title = hotel.title,
        description = hotel.description,
        address = hotel.address,
        city = hotel.city,
        state = hotel.state,
        country = hotel.country,
        phone = hotel.phone,
        email = hotel.email,
        url = hotel.url;

  Hotel toHotel() {
    return Hotel(
      documentId: documentId,
      name: name,
      title: title,
      description: description,
      address: address,
      city: city,
      state: state,
      country: country,
      phone: phone,
      email: email,
      url: url,
    );
  }

  HotelFormModel copy() {
    return HotelFormModel(
      documentId: documentId,
      name: name,
      title: title,
      description: description,
      address: address,
      city: city,
      state: state,
      country: country,
      phone: phone,
      email: email,
      url: url,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotelFormModel &&
        documentId == other.documentId &&
        name == other.name &&
        title == other.title &&
        description == other.description &&
        address == other.address &&
        city == other.city &&
        state == other.state &&
        country == other.country &&
        phone == other.phone &&
        email == other.email &&
        url == other.url;
  }

  @override
  int get hashCode {
    return Object.hash(
      documentId, name, title, description, address, city,
      state, country, phone, email, url,
    );
  }
}
