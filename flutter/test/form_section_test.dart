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
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_quickstart/widget/form_section.dart';

void main() {
  testWidgets('FormSection inserts a gap between successive children', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormSection(
            title: 'Basic Info',
            children: [
              SizedBox(key: const Key('field1'), height: 50, width: 100),
              SizedBox(key: const Key('field2'), height: 50, width: 100),
            ],
          ),
        ),
      ),
    );

    final rect1 = tester.getRect(find.byKey(const Key('field1')));
    final rect2 = tester.getRect(find.byKey(const Key('field2')));

    // The two fields must not overlap, and the gap between them should
    // match the spacing FormSection inserts (12px), not sit flush.
    expect(rect1.bottom, lessThan(rect2.top));
    expect(rect2.top - rect1.bottom, 12);
  });
}
