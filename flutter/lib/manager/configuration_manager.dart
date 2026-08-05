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

import 'dart:convert';

import 'package:flutter/services.dart';
import '../model/configuration_model.dart';

class ConfigurationManager {
  Future<ConfigurationModel> loadConfiguration() async {
    final jsonStr = await rootBundle.loadString('assets/config.json');
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return ConfigurationModel.fromJson(map);
  }
}
