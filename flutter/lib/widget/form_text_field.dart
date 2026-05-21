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
import 'package:flutter/services.dart';

class FormTextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onValueChange;
  final TextInputType keyboardType;
  final int? maxLines;

  const FormTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onValueChange,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  State<FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<FormTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(FormTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onValueChange,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      inputFormatters: widget.maxLines == 1
          ? [LengthLimitingTextInputFormatter(500)]
          : null,
    );
  }
}
