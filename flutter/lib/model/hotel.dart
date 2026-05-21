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

class Hotel {
  final String? documentId;
  final String name;
  final String title;
  final String description;
  final String address;
  final String city;
  final String state;
  final String country;
  final String phone;
  final String email;
  final String url;

  const Hotel({
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

  Map<String, dynamic> toMap() {
    return {
      'type': 'hotel',
      'name': name,
      'title': title,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'phone': phone,
      'email': email,
      'url': url,
    };
  }

  factory Hotel.fromMap(Map<String, dynamic>? map, String? documentId) {
    if (map == null) return Hotel(documentId: documentId);
    return Hotel(
      documentId: documentId,
      name: map['name'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      country: map['country'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      url: map['url'] as String? ?? '',
    );
  }

  Hotel copyWith({
    String? documentId,
    String? name,
    String? title,
    String? description,
    String? address,
    String? city,
    String? state,
    String? country,
    String? phone,
    String? email,
    String? url,
  }) {
    return Hotel(
      documentId: documentId ?? this.documentId,
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      url: url ?? this.url,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Hotel && other.documentId == documentId;
  }

  @override
  int get hashCode => documentId.hashCode;
}
