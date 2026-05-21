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

class HotelListTile extends StatelessWidget {
  final Hotel hotel;
  final VoidCallback onClick;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const HotelListTile({
    super.key,
    required this.hotel,
    required this.onClick,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = hotel.name.isEmpty ? hotel.title : hotel.name;
    final locationParts = [
      hotel.address,
      hotel.city,
      hotel.country,
    ].where((s) => s.isNotEmpty).join(', ');

    return Dismissible(
      key: Key(hotel.documentId ?? hotel.hashCode.toString()),
      direction: hotel.documentId != null
          ? DismissDirection.startToEnd // Only swipe for edit
          : DismissDirection.endToStart, // Only swipe for delete
      background: Container(
        color: const Color(0xFF2196F3),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: const Color(0xFFF44336),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
        } else {
          onDelete();
        }
      },
      child: ListTile(
        title: Text(
          displayName,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (locationParts.isNotEmpty)
              Text(locationParts, style: theme.textTheme.bodySmall),
            if (hotel.phone.isNotEmpty)
              Text(hotel.phone, style: theme.textTheme.bodySmall),
          ],
        ),
        onTap: onClick,
      ),
    );
  }
}
