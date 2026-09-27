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

import 'package:flutter/foundation.dart';
import '../model/hotel.dart';
import '../model/hotel_form_model.dart';
import '../manager/database_manager.dart';

enum ViewMode { add, edit }

class HotelFormViewModel {
  final DatabaseManaging _dbManager;
  final ViewMode viewMode;

  // Individual ValueNotifiers for fine-grained UI updates. Unlike a
  // broadcast StreamController, a ValueNotifier always holds and exposes its
  // current value, so a ValueListenableBuilder built on a later frame still
  // sees the right starting value with no separate "initialData" needed.
  final ValueNotifier<String> nameNotifier;
  final ValueNotifier<String> titleNotifier;
  final ValueNotifier<String> descriptionNotifier;
  final ValueNotifier<String> addressNotifier;
  final ValueNotifier<String> cityNotifier;
  final ValueNotifier<String> stateNotifier;
  final ValueNotifier<String> countryNotifier;
  final ValueNotifier<String> phoneNotifier;
  final ValueNotifier<String> emailNotifier;
  final ValueNotifier<String> urlNotifier;

  // Model change detection
  final ValueNotifier<bool> modelDidChangeNotifier = ValueNotifier(false);

  late HotelFormModel _currentHotel;
  late HotelFormModel _originalModel;

  HotelFormModel get currentHotel => _currentHotel;

  HotelFormViewModel({Hotel? existingHotel})
    : _dbManager = DatabaseManagerProvider.factory(),
      viewMode = existingHotel == null ? ViewMode.add : ViewMode.edit,
      nameNotifier = ValueNotifier(existingHotel?.name ?? ''),
      titleNotifier = ValueNotifier(existingHotel?.title ?? ''),
      descriptionNotifier = ValueNotifier(existingHotel?.description ?? ''),
      addressNotifier = ValueNotifier(existingHotel?.address ?? ''),
      cityNotifier = ValueNotifier(existingHotel?.city ?? ''),
      stateNotifier = ValueNotifier(existingHotel?.state ?? ''),
      countryNotifier = ValueNotifier(existingHotel?.country ?? ''),
      phoneNotifier = ValueNotifier(existingHotel?.phone ?? ''),
      emailNotifier = ValueNotifier(existingHotel?.email ?? ''),
      urlNotifier = ValueNotifier(existingHotel?.url ?? '') {
    _currentHotel = existingHotel != null
        ? HotelFormModel.fromHotel(existingHotel)
        : HotelFormModel();
    _originalModel = _currentHotel.copy();
  }

  void updateName(String value) {
    _currentHotel.name = value;
    nameNotifier.value = value;
    _checkDidChange();
  }

  void updateTitle(String value) {
    _currentHotel.title = value;
    titleNotifier.value = value;
    _checkDidChange();
  }

  void updateDescription(String value) {
    _currentHotel.description = value;
    descriptionNotifier.value = value;
    _checkDidChange();
  }

  void updateAddress(String value) {
    _currentHotel.address = value;
    addressNotifier.value = value;
    _checkDidChange();
  }

  void updateCity(String value) {
    _currentHotel.city = value;
    cityNotifier.value = value;
    _checkDidChange();
  }

  void updateState(String value) {
    _currentHotel.state = value;
    stateNotifier.value = value;
    _checkDidChange();
  }

  void updateCountry(String value) {
    _currentHotel.country = value;
    countryNotifier.value = value;
    _checkDidChange();
  }

  void updatePhone(String value) {
    _currentHotel.phone = value;
    phoneNotifier.value = value;
    _checkDidChange();
  }

  void updateEmail(String value) {
    _currentHotel.email = value;
    emailNotifier.value = value;
    _checkDidChange();
  }

  void updateUrl(String value) {
    _currentHotel.url = value;
    urlNotifier.value = value;
    _checkDidChange();
  }

  void _checkDidChange() {
    modelDidChangeNotifier.value = _currentHotel != _originalModel;
  }

  void onAcceptButton() {
    final hotelData = _currentHotel.toHotel();
    if (viewMode == ViewMode.add) {
      _dbManager.addHotel(hotelData);
    } else {
      _dbManager.updateHotel(hotelData);
    }
    _originalModel = _currentHotel.copy();
    modelDidChangeNotifier.value = false;
  }

  void dispose() {
    nameNotifier.dispose();
    titleNotifier.dispose();
    descriptionNotifier.dispose();
    addressNotifier.dispose();
    cityNotifier.dispose();
    stateNotifier.dispose();
    countryNotifier.dispose();
    phoneNotifier.dispose();
    emailNotifier.dispose();
    urlNotifier.dispose();
    modelDidChangeNotifier.dispose();
  }
}
