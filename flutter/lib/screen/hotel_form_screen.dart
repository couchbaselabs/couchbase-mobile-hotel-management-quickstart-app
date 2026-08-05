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
        title: StreamBuilder<String>(
          stream: _viewModel.titleStream,
          initialData: 'New Hotel',
          builder: (context, snapshot) => Text(snapshot.data!),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: widget.onBack,
        ),
        actions: [
          StreamBuilder<bool>(
            stream: _viewModel.modelDidChange,
            initialData: false,
            builder: (context, snapshot) {
              return TextButton(
                onPressed: snapshot.data! == true
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
              StreamBuilder<String>(
                stream: _viewModel.nameStream,
                initialData: _viewModel.currentHotel.name,
                builder: (context, snapshot) {
                  return FormTextField(
                    label: 'Name',
                    value: snapshot.data!,
                    onValueChange: (text) => _viewModel.updateName(text),
                  );
                },
              ),
              StreamBuilder<String>(
                stream: _viewModel.titleStream,
                initialData: _viewModel.currentHotel.title,
                builder: (context, snapshot) {
                  return FormTextField(
                    label: 'Title',
                    value: snapshot.data!,
                    onValueChange: (text) => _viewModel.updateTitle(text),
                  );
                },
              ),
              StreamBuilder<String>(
                stream: _viewModel.descriptionStream,
                initialData: _viewModel.currentHotel.description,
                builder: (context, snapshot) {
                  return FormTextField(
                    label: 'Description',
                    value: snapshot.data!,
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
              StreamBuilder<String>(
                stream: _viewModel.addressStream,
                initialData: _viewModel.currentHotel.address,
                builder: (context, snapshot) {
                  return FormTextField(
                    label: 'Address',
                    value: snapshot.data!,
                    onValueChange: (text) => _viewModel.updateAddress(text),
                  );
                },
              ),
              StreamBuilder<String>(
                stream: _viewModel.cityStream,
                initialData: _viewModel.currentHotel.city,
                builder: (context, snapshot) {
                  return FormTextField(
                    label: 'City',
                    value: snapshot.data!,
                    onValueChange: (text) => _viewModel.updateCity(text),
                  );
                },
              ),
              StreamBuilder<String>(
                stream: _viewModel.stateStream,
                initialData: _viewModel.currentHotel.state,
                builder: (context, snapshot) {
                  return FormTextField(
                    label: 'State',
                    value: snapshot.data!,
                    onValueChange: (text) => _viewModel.updateState(text),
                  );
                },
              ),
              StreamBuilder<String>(
                stream: _viewModel.countryStream,
                initialData: _viewModel.currentHotel.country,
                builder: (context, snapshot) {
                  return FormTextField(
                    label: 'Country',
                    value: snapshot.data!,
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
              StreamBuilder<String>(
                stream: _viewModel.phoneStream,
                initialData: _viewModel.currentHotel.phone,
                builder: (context, snapshot) {
                  return FormTextField(
                    label: 'Phone',
                    value: snapshot.data!,
                    onValueChange: (text) => _viewModel.updatePhone(text),
                    keyboardType: TextInputType.phone,
                  );
                },
              ),
              StreamBuilder<String>(
                stream: _viewModel.emailStream,
                initialData: _viewModel.currentHotel.email,
                builder: (context, snapshot) {
                  return FormTextField(
                    label: 'Email',
                    value: snapshot.data!,
                    onValueChange: (text) => _viewModel.updateEmail(text),
                    keyboardType: TextInputType.emailAddress,
                  );
                },
              ),
              StreamBuilder<String>(
                stream: _viewModel.urlStream,
                initialData: _viewModel.currentHotel.url,
                builder: (context, snapshot) {
                  return FormTextField(
                    label: 'Website',
                    value: snapshot.data!,
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
