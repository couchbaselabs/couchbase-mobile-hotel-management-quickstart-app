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

/// Builds a safe FTS5 MATCH pattern for a prefix search on [term].
///
/// SQL++ query parameters bind the value safely (no SQL injection), but the
/// bound value is itself parsed as an FTS5 query expression, not literal
/// text -- `AND`/`OR`/`NOT`, unbalanced quotes, hyphens, and parentheses are
/// all FTS5 syntax and can throw a query error or silently change what
/// matches (e.g. searching for "Saint-Germain" or a name containing `"`).
///
/// Wrapping the term as a quoted phrase makes FTS5 treat it as literal text;
/// a trailing `*` outside the closing quote still allows prefix matching.
/// Internal `"` characters are escaped by doubling, per FTS5's own quoting
/// convention.
String buildFtsPrefixPattern(String term) {
  final escaped = term.replaceAll('"', '""');
  return '"$escaped"*';
}
