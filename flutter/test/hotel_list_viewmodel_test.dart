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

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_quickstart/manager/database_manager.dart';
import 'package:hotel_quickstart/model/hotel.dart';
import 'package:hotel_quickstart/viewmodel/hotel_list_viewmodel.dart';

import 'fakes/fake_database_manager.dart';

void main() {
  const zephyr = Hotel(documentId: '1', name: 'Zephyr Inn');
  const alpine = Hotel(documentId: '2', name: 'Alpine Lodge');

  late FakeDatabaseManager fake;
  late HotelListViewModel viewModel;
  late DatabaseManaging Function() originalFactory;

  setUp(() {
    originalFactory = DatabaseManagerProvider.factory;
    fake = FakeDatabaseManager([zephyr, alpine]);
    DatabaseManagerProvider.factory = () => fake;
    viewModel = HotelListViewModel();
  });

  tearDown(() {
    viewModel.dispose();
    fake.dispose();
    DatabaseManagerProvider.factory = originalFactory;
  });

  test('init loads hotels sorted descending by default', () async {
    final loaded = viewModel.hotels.firstWhere((h) => h != null);
    viewModel.init();

    final hotels = await loaded;
    expect(hotels!.map((h) => h.name), ['Zephyr Inn', 'Alpine Lodge']);
  });

  test('sort button toggles order and notifies descendingList', () async {
    final initialLoad = viewModel.hotels.firstWhere((h) => h != null);
    viewModel.init();
    await initialLoad;

    final descendingUpdates = <bool>[];
    final subscription = viewModel.descendingList.listen(descendingUpdates.add);

    final resorted = viewModel.hotels.firstWhere((h) => h != null);
    viewModel.onSortButtonTapped();
    final hotels = await resorted;

    expect(descendingUpdates, [false]);
    expect(hotels!.map((h) => h.name), ['Alpine Lodge', 'Zephyr Inn']);

    await subscription.cancel();
  });

  test('search is debounced so rapid keystrokes only trigger one re-query', () {
    fakeAsync((async) {
      viewModel.init();
      async.flushMicrotasks();
      expect(fake.queryCallCount, 1);

      viewModel.onSearchTextChanged('a');
      async.elapse(const Duration(milliseconds: 100));
      viewModel.onSearchTextChanged('al');
      async.elapse(const Duration(milliseconds: 100));
      viewModel.onSearchTextChanged('alp');
      async.elapse(const Duration(milliseconds: 100));

      // Still inside the 300ms debounce window since the last keystroke.
      expect(fake.queryCallCount, 1);

      async.elapse(const Duration(milliseconds: 300));

      // Exactly one additional query, for the final search text only.
      expect(fake.queryCallCount, 2);
    });
  });

  test('deleteHotel forwards to the database manager', () async {
    await viewModel.deleteHotel(zephyr);

    expect(fake.deleted, [zephyr]);
    expect(fake.hotels, [alpine]);
  });
}
