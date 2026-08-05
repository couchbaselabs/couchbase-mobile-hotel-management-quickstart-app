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

  static const _searchDebounceDuration = Duration(milliseconds: 300);

  final _hotelsController = StreamController<List<Hotel>?>.broadcast();
  Stream<List<Hotel>?> get hotels => _hotelsController.stream;

  Stream<String> get replicatorStatus => _dbManager.replicatorStatus;

  final _descendingListController = StreamController<bool>.broadcast();
  Stream<bool> get descendingList => _descendingListController.stream;

  bool _descending = true;
  String _searchText = '';
  Timer? _searchDebounce;
  StreamSubscription<List<Hotel>>? _queryUpdatesSubscription;

  void init() {
    _bindListeners();
    query();
  }

  void _bindListeners() {
    _queryUpdatesSubscription = _dbManager.queryUpdates.listen((hotels) {
      if (!_hotelsController.isClosed) {
        _hotelsController.add(hotels);
      }
    });
  }

  void query() {
    _dbManager.queryHotels(descending: _descending, textSearch: _searchText);
  }

  // Debounced so a fast typist doesn't tear down and recompile the live FTS
  // query on every keystroke.
  void onSearchTextChanged(String text) {
    _searchText = text;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, query);
  }

  void onSortButtonTapped() {
    _descending = !_descending;
    query();
    _descendingListController.add(_descending);
  }

  Future<void> deleteHotel(Hotel hotel) => _dbManager.deleteHotel(hotel);

  void dispose() {
    _searchDebounce?.cancel();
    _queryUpdatesSubscription?.cancel();
    _hotelsController.close();
    _descendingListController.close();
  }
}
