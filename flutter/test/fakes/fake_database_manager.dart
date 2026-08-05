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

import 'package:hotel_quickstart/manager/database_manager.dart';
import 'package:hotel_quickstart/model/hotel.dart';

/// In-memory [DatabaseManaging] test double, exercising the DI seam
/// ([DatabaseManagerProvider.factory]) that was already in place but unused
/// by any test.
class FakeDatabaseManager implements DatabaseManaging {
  FakeDatabaseManager([List<Hotel> initialHotels = const []])
    : hotels = List.of(initialHotels);

  final List<Hotel> hotels;
  final List<Hotel> added = [];
  final List<Hotel> updated = [];
  final List<Hotel> deleted = [];
  int queryCallCount = 0;
  bool initializeCalled = false;

  final _queryUpdatesController = StreamController<List<Hotel>>.broadcast();
  @override
  Stream<List<Hotel>> get queryUpdates => _queryUpdatesController.stream;

  final _replicatorStatusController = StreamController<String>.broadcast();
  @override
  Stream<String> get replicatorStatus => _replicatorStatusController.stream;

  @override
  Future<void> initialize({
    bool descending = true,
    String textSearch = '',
  }) async {
    initializeCalled = true;
    await queryHotels(descending: descending, textSearch: textSearch);
  }

  @override
  Future<void> queryHotels({
    bool descending = true,
    String textSearch = '',
  }) async {
    queryCallCount++;
    final needle = textSearch.toLowerCase();
    final results =
        hotels
            .where(
              (h) => needle.isEmpty || h.name.toLowerCase().contains(needle),
            )
            .toList()
          ..sort(
            (a, b) => descending
                ? b.name.compareTo(a.name)
                : a.name.compareTo(b.name),
          );
    if (!_queryUpdatesController.isClosed) {
      _queryUpdatesController.add(results);
    }
  }

  @override
  Future<void> addHotel(Hotel hotel) async {
    added.add(hotel);
    hotels.add(hotel);
  }

  @override
  Future<void> updateHotel(Hotel hotel) async {
    updated.add(hotel);
    final index = hotels.indexWhere((h) => h.documentId == hotel.documentId);
    if (index != -1) hotels[index] = hotel;
  }

  @override
  Future<void> deleteHotel(Hotel hotel) async {
    deleted.add(hotel);
    hotels.removeWhere((h) => h.documentId == hotel.documentId);
  }

  void dispose() {
    _queryUpdatesController.close();
    _replicatorStatusController.close();
  }
}
