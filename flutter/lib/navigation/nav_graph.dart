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
import '../screen/hotel_details_screen.dart';
import '../screen/hotel_form_screen.dart';
import '../screen/hotel_list_screen.dart';

/// Root of the app's navigation, backed by the framework [Navigator] instead
/// of manual state, so the Android/desktop back button and the browser back
/// button correctly pop the current screen instead of exiting the app.
class NavGraph extends StatelessWidget {
  const NavGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return HotelListScreen(
      onHotelClick: (hotel) => _openDetails(context, hotel),
      onAddHotel: () => _openForm(context, null),
      onEditHotel: (hotel) => _openForm(context, hotel),
    );
  }

  void _openDetails(BuildContext context, Hotel hotel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HotelDetailsScreen(
          hotel: hotel,
          onBack: () => Navigator.of(context).pop(),
          onEdit: () => _openForm(context, hotel),
        ),
      ),
    );
  }

  void _openForm(BuildContext context, Hotel? existingHotel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HotelFormScreen(
          existingHotel: existingHotel,
          onBack: () => Navigator.of(context).pop(),
          // Saving always returns all the way to the hotel list, whether the
          // form was reached via "Add" (from the list) or "Edit" (from the
          // details screen), mirroring the app's original behavior.
          onSaved: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
    );
  }
}
