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

enum _Screen { list, details, form }

class NavGraph extends StatefulWidget {
  const NavGraph({super.key});

   @override
  State<NavGraph> createState() => _NavGraphState();
}

class _NavGraphState extends State<NavGraph> {
  _Screen _currentScreen = _Screen.list;
  Hotel? _selectedHotel;
  Hotel? _hotelBeingEdited;

  void _navigateToDetails(Hotel hotel) {
    setState(() {
      _selectedHotel = hotel;
      _currentScreen = _Screen.details;
    });
  }

  void _navigateToAddForm() {
    setState(() {
      _selectedHotel = null;
      _hotelBeingEdited = null;
      _currentScreen = _Screen.form;
    });
  }

  void _navigateToEditForm(Hotel hotel) {
    setState(() {
      _hotelBeingEdited = hotel;
      _currentScreen = _Screen.form;
    });
  }

  void _goBack() {
    setState(() {
      if (_currentScreen == _Screen.form) {
          _selectedHotel = _hotelBeingEdited;
          _currentScreen = _Screen.details;
      } else {
        _currentScreen = _Screen.list;
      }
    });
  }

  void _goToRoot() {
    setState(() {
      _selectedHotel = null;
      _hotelBeingEdited = null;
      _currentScreen = _Screen.list;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case _Screen.list:
        return HotelListScreen(
          onHotelClick: _navigateToDetails,
          onAddHotel: _navigateToAddForm,
        );
      case _Screen.details:
        if (_selectedHotel == null) {
          return HotelListScreen(
            onHotelClick: _navigateToDetails,
            onAddHotel: _navigateToAddForm,
          );
        }
        return HotelDetailsScreen(
          hotel: _selectedHotel!,
          onBack: _goBack,
          onEdit: () => _navigateToEditForm(_selectedHotel!),
        );
      case _Screen.form:
        return HotelFormScreen(
          existingHotel: _hotelBeingEdited,
          onBack: _goBack,
          onSaved: _goToRoot,
        );
    }
  }
}
