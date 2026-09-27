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
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _viewModel = HotelListViewModel();
    _viewModel.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _showSearch = !_showSearch);
    if (!_showSearch && _searchController.text.isNotEmpty) {
      _searchController.clear();
      _viewModel.onSearchTextChanged('');
    }
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
            ValueListenableBuilder<String>(
              valueListenable: _viewModel.replicatorStatusNotifier,
              builder: (context, status, _) {
                final displayStatus =
                    status[0].toUpperCase() + status.substring(1).toLowerCase();
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
            onPressed: _toggleSearch,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _viewModel.descendingNotifier,
            builder: (context, descending, _) {
              return IconButton(
                icon: Icon(
                  descending ? Icons.arrow_downward : Icons.arrow_upward,
                ),
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
              child: TextField(
                controller: _searchController,
                onChanged: (text) => _viewModel.onSearchTextChanged(text),
                decoration: const InputDecoration(
                  hintText: 'Search hotels...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),

          // Hotel list
          Expanded(
            child: ValueListenableBuilder<List<Hotel>?>(
              valueListenable: _viewModel.hotelsNotifier,
              builder: (context, hotels, _) {
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
                          onConfirmDelete: () => _confirmDelete(hotel),
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

  Future<bool> _confirmDelete(Hotel hotel) async {
    final displayName = hotel.name.isEmpty ? hotel.title : hotel.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Hotel'),
          content: Text('Are you sure you want to delete "$displayName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return false;
    await _viewModel.deleteHotel(hotel);
    return true;
  }
}
