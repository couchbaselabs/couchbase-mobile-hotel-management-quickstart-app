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

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_quickstart/manager/database_manager.dart';
import 'package:hotel_quickstart/model/hotel.dart';
import 'package:hotel_quickstart/viewmodel/hotel_form_viewmodel.dart';

import 'fakes/fake_database_manager.dart';

void main() {
  late FakeDatabaseManager fake;
  late DatabaseManaging Function() originalFactory;

  setUp(() {
    originalFactory = DatabaseManagerProvider.factory;
    fake = FakeDatabaseManager();
    DatabaseManagerProvider.factory = () => fake;
  });

  tearDown(() {
    fake.dispose();
    DatabaseManagerProvider.factory = originalFactory;
  });

  test('starts in add mode, clean, with empty fields', () {
    final viewModel = HotelFormViewModel();

    expect(viewModel.viewMode, ViewMode.add);
    expect(viewModel.currentHotel.name, '');

    viewModel.dispose();
  });

  test('starts in edit mode pre-filled from the existing hotel', () {
    const existing = Hotel(documentId: '1', name: 'Old Name', city: 'Austin');
    final viewModel = HotelFormViewModel(existingHotel: existing);

    expect(viewModel.viewMode, ViewMode.edit);
    expect(viewModel.currentHotel.name, 'Old Name');
    expect(viewModel.currentHotel.city, 'Austin');

    viewModel.dispose();
  });

  test('editing a field marks the model dirty, exactly once per change', () {
    final viewModel = HotelFormViewModel();
    final changes = <bool>[];
    void listener() => changes.add(viewModel.modelDidChangeNotifier.value);
    viewModel.modelDidChangeNotifier.addListener(listener);

    // ValueNotifier notifies synchronously, unlike a broadcast stream.
    viewModel.updateName('The Grand');

    expect(changes, [true]);
    expect(viewModel.currentHotel.name, 'The Grand');

    viewModel.modelDidChangeNotifier.removeListener(listener);
    viewModel.dispose();
  });

  test('accepting in add mode saves a new hotel', () async {
    final viewModel = HotelFormViewModel();
    viewModel.updateName('The Grand');

    viewModel.onAcceptButton();

    expect(fake.added, hasLength(1));
    expect(fake.added.single.name, 'The Grand');
    expect(fake.updated, isEmpty);

    viewModel.dispose();
  });

  test(
    'accepting in edit mode updates the existing hotel and clears dirty state',
    () {
      const existing = Hotel(documentId: '1', name: 'Old Name');
      final viewModel = HotelFormViewModel(existingHotel: existing);
      final changes = <bool>[];
      void listener() => changes.add(viewModel.modelDidChangeNotifier.value);
      viewModel.modelDidChangeNotifier.addListener(listener);

      viewModel.updateName('New Name');
      expect(changes, [true]);

      viewModel.onAcceptButton();

      expect(fake.updated, hasLength(1));
      expect(fake.updated.single.name, 'New Name');
      expect(fake.updated.single.documentId, '1');
      expect(changes, [true, false]);

      viewModel.modelDidChangeNotifier.removeListener(listener);
      viewModel.dispose();
    },
  );
}
