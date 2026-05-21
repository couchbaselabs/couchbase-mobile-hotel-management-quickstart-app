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
import '../manager/database_manager.dart';

class HotelListViewModel {
  final DatabaseManaging _dbManager;

  HotelListViewModel() : _dbManager = DatabaseManagerProvider.factory();

  final _hotelsController = StreamController<List<Hotel>?>.broadcast();
  Stream<List<Hotel>?> get hotels => _hotelsController.stream;

  Stream<String> get replicatorStatus => _dbManager.replicatorStatus;

  final _descendingListController = StreamController<bool>.broadcast();
  late final Stream<bool> descendingList;

  final _searchTextController = StreamController<String>.broadcast();
  late final Stream<String> searchText;

  final _showDeleteAlertController = StreamController<bool>.broadcast();
  Stream<bool> get showDeleteAlert => _showDeleteAlertController.stream;

  final _hotelToDeleteController = StreamController<Hotel?>.broadcast();
  Stream<Hotel?> get hotelToDelete => _hotelToDeleteController.stream;

  Hotel? _hotelToDelete;
  bool _descending = true;
  String _searchText = '';

  void init() {
    descendingList = _descendingListController.stream;
    searchText = _searchTextController.stream;
    _bindListeners();
    query();
  }

  void _bindListeners() {
    _dbManager.queryUpdates.listen((hotels) {
      _hotelsController.add(hotels);
    });
  }

  void query() {
    _dbManager.queryHotels(descending: _descending, textSearch: _searchText);
  }

  void onSearchTextChanged(String text) {
    _searchText = text;
    query();
  }

  void onSortButtonTapped() {
    _descending = !_descending;
    query();
    _descendingListController.add(_descending);
  }

  void onDeleteRequested(Hotel hotel) {
    _hotelToDelete = hotel;
    _hotelToDeleteController.add(hotel);
    _showDeleteAlertController.add(true);
  }

  void deleteItemAlertAccepted() {
    if (_hotelToDelete != null) {
      _dbManager.deleteHotel(_hotelToDelete!);
    }
    _hotelToDelete = null;
    _hotelToDeleteController.add(null);
    _showDeleteAlertController.add(false);
  }

  void deleteItemAlertDismissed() {
    _hotelToDelete = null;
    _hotelToDeleteController.add(null);
    _showDeleteAlertController.add(false);
  }

  void dispose() {
    _hotelsController.close();
    _descendingListController.close();
    _searchTextController.close();
    _showDeleteAlertController.close();
    _hotelToDeleteController.close();
  }
}
