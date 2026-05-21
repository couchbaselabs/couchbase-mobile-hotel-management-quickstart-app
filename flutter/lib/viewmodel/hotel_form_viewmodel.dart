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

import 'dart:async';
import '../model/hotel.dart';
import '../model/hotel_form_model.dart';
import '../manager/database_manager.dart';

enum ViewMode { add, edit }

class HotelFormViewModel {
  final DatabaseManaging _dbManager;
  final ViewMode viewMode;

  // Individual field streams for fine-grained UI updates
  final _nameController = StreamController<String>.broadcast();
  final _titleController = StreamController<String>.broadcast();
  final _descriptionController = StreamController<String>.broadcast();
  final _addressController = StreamController<String>.broadcast();
  final _cityController = StreamController<String>.broadcast();
  final _stateController = StreamController<String>.broadcast();
  final _countryController = StreamController<String>.broadcast();
  final _phoneController = StreamController<String>.broadcast();
  final _emailController = StreamController<String>.broadcast();
  final _urlController = StreamController<String>.broadcast();

  Stream<String> get nameStream => _nameController.stream;
  Stream<String> get titleStream => _titleController.stream;
  Stream<String> get descriptionStream => _descriptionController.stream;
  Stream<String> get addressStream => _addressController.stream;
  Stream<String> get cityStream => _cityController.stream;
  Stream<String> get stateStream => _stateController.stream;
  Stream<String> get countryStream => _countryController.stream;
  Stream<String> get phoneStream => _phoneController.stream;
  Stream<String> get emailStream => _emailController.stream;
  Stream<String> get urlStream => _urlController.stream;

  // Model change detection
  final _modelDidChangeController = StreamController<bool>.broadcast();
  Stream<bool> get modelDidChange => _modelDidChangeController.stream;

  late HotelFormModel _currentHotel;
  late HotelFormModel _originalModel;

  HotelFormModel get currentHotel => _currentHotel;

  HotelFormViewModel({Hotel? existingHotel})
       : _dbManager = DatabaseManagerProvider.factory(),
        viewMode = existingHotel == null ? ViewMode.add : ViewMode.edit {
    final initial = existingHotel != null
        ? HotelFormModel.fromHotel(existingHotel)
        : HotelFormModel();
    _initializeFromModel(initial);
    _originalModel = _currentHotel.copy();
    _modelDidChangeController.add(false);
  }

  void _initializeFromModel(HotelFormModel model) {
    _currentHotel = model;
    _nameController.add(model.name);
    _titleController.add(model.title);
    _descriptionController.add(model.description);
    _addressController.add(model.address);
    _cityController.add(model.city);
    _stateController.add(model.state);
    _countryController.add(model.country);
    _phoneController.add(model.phone);
    _emailController.add(model.email);
    _urlController.add(model.url);
  }

  void updateName(String value) {
    _currentHotel.name = value;
    _nameController.add(value);
    _checkDidChange();
  }

  void updateTitle(String value) {
    _currentHotel.title = value;
    _titleController.add(value);
    _checkDidChange();
  }

  void updateDescription(String value) {
    _currentHotel.description = value;
    _descriptionController.add(value);
    _checkDidChange();
  }

  void updateAddress(String value) {
    _currentHotel.address = value;
    _addressController.add(value);
    _checkDidChange();
  }

  void updateCity(String value) {
    _currentHotel.city = value;
    _cityController.add(value);
    _checkDidChange();
  }

  void updateState(String value) {
    _currentHotel.state = value;
    _stateController.add(value);
    _checkDidChange();
  }

  void updateCountry(String value) {
    _currentHotel.country = value;
    _countryController.add(value);
    _checkDidChange();
  }

  void updatePhone(String value) {
    _currentHotel.phone = value;
    _phoneController.add(value);
    _checkDidChange();
  }

  void updateEmail(String value) {
    _currentHotel.email = value;
    _emailController.add(value);
    _checkDidChange();
  }

  void updateUrl(String value) {
    _currentHotel.url = value;
    _urlController.add(value);
    _checkDidChange();
  }

  void _checkDidChange() {
    _modelDidChangeController.add(_currentHotel != _originalModel);
  }

  void onAcceptButton() {
    final hotelData = _currentHotel.toHotel();
    if (viewMode == ViewMode.add) {
      _dbManager.addHotel(hotelData);
    } else {
      _dbManager.updateHotel(hotelData);
    }
    _originalModel = _currentHotel.copy();
    _modelDidChangeController.add(false);
  }

  void init() {}

  void dispose() {
    _nameController.close();
    _titleController.close();
    _descriptionController.close();
    _addressController.close();
    _cityController.close();
    _stateController.close();
    _countryController.close();
    _phoneController.close();
    _emailController.close();
    _urlController.close();
    _modelDidChangeController.close();
  }
}
