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
import 'manager/database_manager.dart';
import 'manager/error_manager.dart';
import 'navigation/nav_graph.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

   // Initialize Couchbase Lite and database (mirrors QuickstartApp.onCreate)
  try {
    await DatabaseManager.getInstance().initialize();
   } catch (e) {
     // Error already surfaced via ErrorManager in DatabaseManager
   }

  runApp(const QuickstartApp());
}

class QuickstartApp extends StatelessWidget {
  const QuickstartApp({super.key});

   @override
  Widget build(BuildContext context) {
    return QuickstartTheme(
      child: ErrorManagerProvider(
        child: NavGraph(),
       ),
     );
   }
}

class ErrorManagerProvider extends StatefulWidget {
  final Widget child;

  const ErrorManagerProvider({super.key, required this.child});

   @override
  State<ErrorManagerProvider> createState() => _ErrorManagerProviderState();
}

class _ErrorManagerProviderState extends State<ErrorManagerProvider> {
  final ErrorManager _errorManager = ErrorManager();

   @override
  void initState() {
    super.initState();
     _errorManager.addListener(_showLastError);
   }

  void _showLastError() {
    final error = _errorManager.currentError;
    if (error != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: error.closable,
            builder: (ctx) {
              return AlertDialog(
                title: Text(error.title),
                content: Text(error.message),
                actions: [
                  if (error.closable)
                    TextButton(
                      onPressed: () {
                         _errorManager.dismissAndShowNext();
                        Navigator.of(ctx).pop();
                       },
                      child: const Text('OK'),
                     ),
                 ],
               );
             },
           );
         }
       });
     }
   }

   @override
  void dispose() {
     _errorManager.removeListener(_showLastError);
    super.dispose();
   }

   @override
  Widget build(BuildContext context) {
    return widget.child;
   }
}
