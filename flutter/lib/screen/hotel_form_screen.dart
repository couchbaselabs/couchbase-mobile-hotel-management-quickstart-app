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
import '../model/hotel.dart';
import '../viewmodel/hotel_form_viewmodel.dart';
import '../widget/form_section.dart';
import '../widget/form_text_field.dart';

class HotelFormScreen extends StatefulWidget {
  final Hotel? existingHotel;
  final void Function() onBack;
  final void Function() onSaved;

  const HotelFormScreen({
    super.key,
    this.existingHotel,
    required this.onBack,
    required this.onSaved,
  });

  @override
  State<HotelFormScreen> createState() => _HotelFormScreenState();
}

class _HotelFormScreenState extends State<HotelFormScreen> {
  late final HotelFormViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HotelFormViewModel(existingHotel: widget.existingHotel);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
          valueListenable: _viewModel.titleNotifier,
          builder: (context, title, _) =>
              Text(title.isEmpty ? 'New Hotel' : title),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: widget.onBack,
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _viewModel.modelDidChangeNotifier,
            builder: (context, didChange, _) {
              return TextButton(
                onPressed: didChange
                    ? () {
                        _viewModel.onAcceptButton();
                        widget.onSaved();
                      }
                    : null,
                child: const Text('Save'),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Info Section
          FormSection(
            title: 'Basic Info',
            children: [
              ValueListenableBuilder<String>(
                valueListenable: _viewModel.nameNotifier,
                builder: (context, name, _) {
                  return FormTextField(
                    label: 'Name',
                    value: name,
                    onValueChange: (text) => _viewModel.updateName(text),
                  );
                },
              ),
              ValueListenableBuilder<String>(
                valueListenable: _viewModel.titleNotifier,
                builder: (context, title, _) {
                  return FormTextField(
                    label: 'Title',
                    value: title,
                    onValueChange: (text) => _viewModel.updateTitle(text),
                  );
                },
              ),
              ValueListenableBuilder<String>(
                valueListenable: _viewModel.descriptionNotifier,
                builder: (context, description, _) {
                  return FormTextField(
                    label: 'Description',
                    value: description,
                    onValueChange: (text) => _viewModel.updateDescription(text),
                    maxLines: 5,
                  );
                },
              ),
            ],
          ),

          // Location Section
          FormSection(
            title: 'Location',
            children: [
              ValueListenableBuilder<String>(
                valueListenable: _viewModel.addressNotifier,
                builder: (context, address, _) {
                  return FormTextField(
                    label: 'Address',
                    value: address,
                    onValueChange: (text) => _viewModel.updateAddress(text),
                  );
                },
              ),
              ValueListenableBuilder<String>(
                valueListenable: _viewModel.cityNotifier,
                builder: (context, city, _) {
                  return FormTextField(
                    label: 'City',
                    value: city,
                    onValueChange: (text) => _viewModel.updateCity(text),
                  );
                },
              ),
              ValueListenableBuilder<String>(
                valueListenable: _viewModel.stateNotifier,
                builder: (context, state, _) {
                  return FormTextField(
                    label: 'State',
                    value: state,
                    onValueChange: (text) => _viewModel.updateState(text),
                  );
                },
              ),
              ValueListenableBuilder<String>(
                valueListenable: _viewModel.countryNotifier,
                builder: (context, country, _) {
                  return FormTextField(
                    label: 'Country',
                    value: country,
                    onValueChange: (text) => _viewModel.updateCountry(text),
                  );
                },
              ),
            ],
          ),

          // Contact Section
          FormSection(
            title: 'Contact',
            children: [
              ValueListenableBuilder<String>(
                valueListenable: _viewModel.phoneNotifier,
                builder: (context, phone, _) {
                  return FormTextField(
                    label: 'Phone',
                    value: phone,
                    onValueChange: (text) => _viewModel.updatePhone(text),
                    keyboardType: TextInputType.phone,
                  );
                },
              ),
              ValueListenableBuilder<String>(
                valueListenable: _viewModel.emailNotifier,
                builder: (context, email, _) {
                  return FormTextField(
                    label: 'Email',
                    value: email,
                    onValueChange: (text) => _viewModel.updateEmail(text),
                    keyboardType: TextInputType.emailAddress,
                  );
                },
              ),
              ValueListenableBuilder<String>(
                valueListenable: _viewModel.urlNotifier,
                builder: (context, url, _) {
                  return FormTextField(
                    label: 'Website',
                    value: url,
                    onValueChange: (text) => _viewModel.updateUrl(text),
                    keyboardType: TextInputType.url,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
