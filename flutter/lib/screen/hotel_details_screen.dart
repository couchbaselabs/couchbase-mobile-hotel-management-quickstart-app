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

import 'package:flutter/material.dart';
import '../model/hotel.dart';
import '../widget/detail_section.dart';
import '../widget/detail_row.dart';

class HotelDetailsScreen extends StatelessWidget {
  final Hotel hotel;
  final void Function() onBack;
  final void Function() onEdit;

  const HotelDetailsScreen({
    super.key,
    required this.hotel,
    required this.onBack,
    required this.onEdit,
   });

   String _displayName() => hotel.name.isEmpty ? hotel.title : hotel.name;

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_displayName()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: onBack,
         ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: onEdit,
           ),
         ],
       ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
           // Info Section
          DetailSection(
            title: 'Info',
            children: [
              if (hotel.name.isNotEmpty) DetailRow(label: 'Name', value: hotel.name),
              if (hotel.title.isNotEmpty) DetailRow(label: 'Title', value: hotel.title),
              if (hotel.description.isNotEmpty) DetailRow(label: 'Description', value: hotel.description),
            ],
          ),

           // Address Section
          DetailSection(
            title: 'Address',
            children: [
              if (hotel.address.isNotEmpty) DetailRow(label: 'Address', value: hotel.address),
              if (hotel.city.isNotEmpty) DetailRow(label: 'City', value: hotel.city),
              if (hotel.state.isNotEmpty) DetailRow(label: 'State', value: hotel.state),
              if (hotel.country.isNotEmpty) DetailRow(label: 'Country', value: hotel.country),
            ],
          ),

           // Contact Section
          DetailSection(
            title: 'Contact',
            children: [
              if (hotel.phone.isNotEmpty) DetailRow(label: 'Phone', value: hotel.phone),
              if (hotel.email.isNotEmpty) DetailRow(label: 'Email', value: hotel.email),
              if (hotel.url.isNotEmpty) DetailRow(label: 'Website', value: hotel.url),
            ],
          ),
        ],
      ),
    );
   }
}
