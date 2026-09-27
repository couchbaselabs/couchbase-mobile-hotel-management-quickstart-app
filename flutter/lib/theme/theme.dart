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

const Color couchbaseRed = Color(0xFFEA2328);

ColorScheme get lightColorScheme => const ColorScheme.light(
  primary: couchbaseRed,
  secondary: Color(0xFF757575),
  tertiary: Color(0xFF9E9E9E),
);

ColorScheme get darkColorScheme => const ColorScheme.dark(
  primary: couchbaseRed,
  secondary: Color(0xFF9E9E9E),
  tertiary: Color(0xFF757575),
);

class QuickstartTheme extends StatelessWidget {
  final Widget child;

  const QuickstartTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Theme.of(context) here would resolve above the MaterialApp this widget
    // is about to create (no ancestor Theme exists yet), always falling back
    // to Brightness.light -- so brightness must be left to MaterialApp
    // itself via themeMode/theme/darkTheme, not detected manually.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: couchbaseRed,
      theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
      darkTheme: ThemeData(colorScheme: darkColorScheme, useMaterial3: true),
      themeMode: ThemeMode.system,
      home: child,
    );
  }
}
