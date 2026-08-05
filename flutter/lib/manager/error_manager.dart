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

import 'package:flutter/foundation.dart';
import '../model/error_model.dart';

class ErrorManager extends ChangeNotifier {
  static final ErrorManager _instance = ErrorManager._internal();

  factory ErrorManager() => _instance;

  ErrorManager._internal();

  @visibleForTesting
  void resetForTesting() {
    _errors.clear();
  }

  final List<ErrorModel> _errors = [];

  List<ErrorModel> get errors => List.unmodifiable(_errors);

  ErrorModel? get currentError => _errors.isNotEmpty ? _errors.first : null;

  void showError(ErrorModel error) {
    // A continuous replicator retries indefinitely, so a persistent
    // connectivity problem would otherwise queue an identical dialog on
    // every retry. Only queue it if it isn't already pending.
    final alreadyQueued = _errors.any(
      (e) => e.title == error.title && e.message == error.message,
    );
    if (alreadyQueued) return;
    _errors.add(error);
    notifyListeners();
  }

  void dismissAndShowNext() {
    if (_errors.isNotEmpty) {
      _errors.removeAt(0);
      notifyListeners();
    }
  }
}
