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
import 'package:hotel_quickstart/manager/fts_query.dart';

void main() {
  test('plain text is quoted and prefix-marked', () {
    expect(buildFtsPrefixPattern('Grand'), '"Grand"*');
  });

  test('hyphenated names are treated as literal text, not FTS syntax', () {
    expect(buildFtsPrefixPattern('Saint-Germain'), '"Saint-Germain"*');
  });

  test('boolean-looking keywords are neutralized', () {
    // Unquoted, "AND"/"OR"/"NOT" are FTS5 boolean operators, not search text.
    expect(buildFtsPrefixPattern('AND'), '"AND"*');
    expect(buildFtsPrefixPattern('OR NOT'), '"OR NOT"*');
  });

  test('internal quotes are escaped by doubling, not left unbalanced', () {
    expect(buildFtsPrefixPattern('Say "hi"'), '"Say ""hi"""*');
  });

  test('parentheses do not open an unbalanced FTS group', () {
    expect(buildFtsPrefixPattern('(complex) query'), '"(complex) query"*');
  });

  test('empty input still produces a well-formed pattern', () {
    expect(buildFtsPrefixPattern(''), '""*');
  });
}
