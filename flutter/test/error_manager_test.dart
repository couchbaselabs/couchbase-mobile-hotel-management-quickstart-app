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
import 'package:hotel_quickstart/manager/error_manager.dart';
import 'package:hotel_quickstart/model/error_model.dart';

void main() {
  setUp(() => ErrorManager().resetForTesting());
  tearDown(() => ErrorManager().resetForTesting());

  test('repeated identical errors are only queued once', () {
    final manager = ErrorManager();
    const error = ErrorModel(title: 'Sync Error', message: 'Connection reset');

    // Simulates a continuous replicator retrying against the same failure.
    manager.showError(error);
    manager.showError(error);
    manager.showError(error);

    expect(manager.errors, hasLength(1));
  });

  test('distinct errors are all queued', () {
    final manager = ErrorManager();

    manager.showError(
      const ErrorModel(title: 'Sync Error', message: 'DNS failure'),
    );
    manager.showError(
      const ErrorModel(title: 'Sync Error', message: 'Connection reset'),
    );

    expect(manager.errors, hasLength(2));
  });

  test('dismissing shows the next queued error', () {
    final manager = ErrorManager();
    manager.showError(const ErrorModel(title: 'A', message: '1'));
    manager.showError(const ErrorModel(title: 'B', message: '2'));

    expect(manager.currentError!.title, 'A');
    manager.dismissAndShowNext();
    expect(manager.currentError!.title, 'B');
  });
}
