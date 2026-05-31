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

import 'dart:async';
import 'package:flutter/material.dart';
import '../model/hotel.dart';
import '../viewmodel/hotel_list_viewmodel.dart';
import '../widget/hotel_list_tile.dart';

class HotelListScreen extends StatefulWidget {
  final void Function(Hotel) onHotelClick;
  final void Function() onAddHotel;
  final void Function(Hotel) onEditHotel;

  const HotelListScreen({
    super.key,
    required this.onHotelClick,
    required this.onAddHotel,
    required this.onEditHotel,
  });

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {
  late final HotelListViewModel _viewModel;
  bool _showSearch = false;
  StreamSubscription<bool>? _deleteAlertSubscription;

  @override
  void initState() {
    super.initState();
    _viewModel = HotelListViewModel();
    _viewModel.init();

    _deleteAlertSubscription = _viewModel.showDeleteAlert.listen((show) {
      if (show && mounted) {
        _showDeleteDialog();
      }
    });
  }

  @override
  void dispose() {
    _deleteAlertSubscription?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hotels'),
            StreamBuilder<String>(
              stream: _viewModel.replicatorStatus,
              initialData: 'Stopped',
              builder: (context, snapshot) {
                final status = snapshot.data ?? 'Stopped';
                final displayStatus = status[0].toUpperCase() + status.substring(1).toLowerCase();
                return Text(
                  'Sync: $displayStatus',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
          StreamBuilder<bool>(
            stream: _viewModel.descendingList,
            initialData: true,
            builder: (context, snapshot) {
              final descending = snapshot.data ?? true;
              return IconButton(
                icon: Icon(descending ? Icons.arrow_downward : Icons.arrow_upward),
                tooltip: 'Sort',
                onPressed: () => _viewModel.onSortButtonTapped(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Hotel',
            onPressed: widget.onAddHotel,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: StreamBuilder<String>(
                stream: _viewModel.searchText,
                initialData: '',
                builder: (context, snapshot) {
                  return TextField(
                    onChanged: (text) => _viewModel.onSearchTextChanged(text),
                    decoration: const InputDecoration(
                      hintText: 'Search hotels...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
            ),

          // Hotel list
          Expanded(
            child: StreamBuilder<List<Hotel>?>(
              stream: _viewModel.hotels,
              initialData: null,
              builder: (context, snapshot) {
                final hotels = snapshot.data;

                if (hotels == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (hotels.isEmpty) {
                  return const Center(child: Text('No hotels found'));
                }

                return ListView.builder(
                  itemCount: hotels.length,
                  itemBuilder: (context, index) {
                    final hotel = hotels[index];
                    return Column(
                      children: [
                        HotelListTile(
                          hotel: hotel,
                          onClick: () => widget.onHotelClick(hotel),
                          onDelete: () => _viewModel.onDeleteRequested(hotel),
                          onEdit: () {
                            widget.onEditHotel(hotel);
                          },
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Hotel'),
          content: const Text('Are you sure you want to delete this hotel?'),
          actions: [
            TextButton(
              onPressed: () {
                _viewModel.deleteItemAlertDismissed();
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _viewModel.deleteItemAlertAccepted();
                Navigator.of(ctx).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

}
