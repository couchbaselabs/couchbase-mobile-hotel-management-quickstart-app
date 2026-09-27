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
import 'package:flutter/foundation.dart';
import '../model/hotel.dart';
import '../manager/database_manager.dart';

class HotelListViewModel {
  final DatabaseManaging _dbManager;

  HotelListViewModel() : _dbManager = DatabaseManagerProvider.factory();

  static const _searchDebounceDuration = Duration(milliseconds: 300);

  // ValueNotifier (unlike a broadcast StreamController) always holds and
  // immediately exposes its current value, so a listener attached after
  // construction -- e.g. a widget built on a later frame -- still sees the
  // current state instead of only future updates.
  final ValueNotifier<List<Hotel>?> hotelsNotifier = ValueNotifier(null);
  final ValueNotifier<String> replicatorStatusNotifier = ValueNotifier(
    'Stopped',
  );
  final ValueNotifier<bool> descendingNotifier = ValueNotifier(true);

  bool _descending = true;
  String _searchText = '';
  Timer? _searchDebounce;
  StreamSubscription<List<Hotel>>? _queryUpdatesSubscription;
  StreamSubscription<String>? _replicatorStatusSubscription;

  void init() {
    _bindListeners();
    query();
  }

  void _bindListeners() {
    _queryUpdatesSubscription = _dbManager.queryUpdates.listen((hotels) {
      hotelsNotifier.value = hotels;
    });
    _replicatorStatusSubscription = _dbManager.replicatorStatus.listen((
      status,
    ) {
      replicatorStatusNotifier.value = status;
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
    descendingNotifier.value = _descending;
  }

  Future<void> deleteHotel(Hotel hotel) => _dbManager.deleteHotel(hotel);

  void dispose() {
    _searchDebounce?.cancel();
    _queryUpdatesSubscription?.cancel();
    _replicatorStatusSubscription?.cancel();
    hotelsNotifier.dispose();
    replicatorStatusNotifier.dispose();
    descendingNotifier.dispose();
  }
}
