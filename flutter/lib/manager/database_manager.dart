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
import 'package:cbl/cbl.dart';
import '../model/error_model.dart';
import '../model/hotel.dart';
import 'configuration_manager.dart';
import 'error_manager.dart';

abstract class DatabaseManaging {
  Stream<List<Hotel>> get queryUpdates;
  Stream<String> get replicatorStatus;
  Future<void> initialize({bool descending = true, String textSearch = ''});
  Future<void> queryHotels({bool descending = true, String textSearch = ''});
  Future<void> addHotel(Hotel hotel);
  Future<void> updateHotel(Hotel hotel);
  Future<void> deleteHotel(Hotel hotel);
}

class DatabaseManagerProvider {
  static DatabaseManaging Function() factory = () =>
      DatabaseManager.getInstance();
}

class DatabaseManager implements DatabaseManaging {
  static DatabaseManager? _instance;

  factory DatabaseManager.getInstance() {
    _instance ??= DatabaseManager._internal();
    return _instance!;
  }

  DatabaseManager._internal();

  static void resetForTesting() {
    _instance = null;
  }

  static const String _databaseName = 'travel-sample';
  static const String _scopeName = 'inventory';
  static const String _collectionName = 'hotel';
  static const String _ftsIndexName = 'nameFtsIndex';

  SyncDatabase? _database;
  SyncCollection? _collection;
  Replicator? _replicator;
  ListenerToken? _queryListenerToken;

  final _queryUpdatesController = StreamController<List<Hotel>>.broadcast();
  @override
  Stream<List<Hotel>> get queryUpdates => _queryUpdatesController.stream;

  final _replicatorStatusController = StreamController<String>.broadcast();
  @override
  Stream<String> get replicatorStatus => _replicatorStatusController.stream;

  @override
  Future<void> initialize({
    bool descending = true,
    String textSearch = '',
  }) async {
    try {
      Database.log.console.level = LogLevel.verbose;
      _database = SyncDatabase(_databaseName);
      _collection = _database!.createCollection(_collectionName, _scopeName);
      await _createFtsIndex();
      _setupReplication();
      await _setupLiveQuery(descending, textSearch);
    } catch (e) {
      ErrorManager().showError(
        ErrorModel(
          title: 'Database Error',
          message: 'Failed to initialize database: $e',
        ),
      );
    }
  }

  Future<void> _createFtsIndex() async {
    try {
      final col = _collection;
      if (col == null) return;
      final ftsIndex = FullTextIndexConfiguration([
        'name',
      ], ignoreAccents: false);
      col.createIndex(_ftsIndexName, ftsIndex);
    } catch (e) {
      // Index may already exist
    }
  }

  void _setupReplication() {
    try {
      final configManager = ConfigurationManager();
      configManager.loadConfiguration().then((config) {
        if (config.capellaEndpointUrl.isEmpty) return;

        final col = _collection;
        if (col == null) return;

        final targetEndpoint = UrlEndpoint(
          Uri.parse(config.capellaEndpointUrl),
        );
        final replConfig = ReplicatorConfiguration(
          target: targetEndpoint,
          replicatorType: ReplicatorType.pushAndPull,
          continuous: true,
          authenticator: BasicAuthenticator(
            username: config.username,
            password: config.password,
          ),
        );
        replConfig.addCollection(col);

        Replicator.create(replConfig).then((replicator) {
          _replicator = replicator;
          final tokenResult = _replicator!.addChangeListener((change) {
            _replicatorStatusController.add(change.status.activity.name);
            if (change.status.error != null) {
              final error = change.status.error!;
              ErrorManager().showError(
                ErrorModel(
                  title: 'Sync Error',
                  message: 'Replication error: $error',
                ),
              );
            }
          });
          // Handle both sync (ListenerToken) and async (Future<ListenerToken>) cases
          if (tokenResult is Future) {
            (tokenResult as Future<ListenerToken>).then((_) {
              _replicator!.start();
            });
          } else {
            _replicator!.start();
          }
        });
      });
    } catch (e) {
      ErrorManager().showError(
        ErrorModel(
          title: 'Sync Error',
          message: 'Failed to setup replication: $e',
        ),
      );
    }
  }

  Future<void> _setupLiveQuery(bool descending, String textSearch) async {
    try {
      final db = _database;
      if (db == null) return;

      // Remove previous query listener
      if (_queryListenerToken != null) {
        // db.createQuery('SELECT 1').removeChangeListener(_queryListenerToken!);
      }

      final sortOrder = descending ? 'DESC' : 'ASC';
      Query query;

      if (textSearch.isNotEmpty) {
        final pattern = '$textSearch*';
        query = db.createQuery(
          'SELECT META().id AS documentId, * FROM `$_scopeName`.`$_collectionName` AS hotel '
          'WHERE MATCH($_ftsIndexName, \$searchTerm) '
          'ORDER BY RANK($_ftsIndexName) $sortOrder',
        );
        final params = Parameters();
        params.setString(pattern, name: 'searchTerm');
        await query.setParameters(params);
      } else {
        query = db.createQuery(
          'SELECT META().id AS documentId, * FROM `$_scopeName`.`$_collectionName` AS hotel '
          'ORDER BY hotel.name $sortOrder',
        );
      }

      _queryListenerToken = await query.addChangeListener((change) {
        final hotels = <Hotel>[];
        final allResults = change.results.allResults();
        if (allResults is Future) {
          (allResults as Future<List<Result>>).then((list) {
            for (final result in list) {
              try {
                final hotel = _resultToHotel(result);
                if (hotel != null) hotels.add(hotel);
              } catch (e) {
                // Skip invalid results
              }
            }
            _queryUpdatesController.add(hotels);
          });
        } else {
          for (final result in allResults) {
            try {
              final hotel = _resultToHotel(result);
              if (hotel != null) hotels.add(hotel);
            } catch (e) {
              // Skip invalid results
            }
          }
          _queryUpdatesController.add(hotels);
        }
      });
    } catch (e) {
      ErrorManager().showError(
        ErrorModel(title: 'Query Error', message: 'Failed to run query: $e'),
      );
    }
  }

  @override
  Future<void> queryHotels({
    bool descending = true,
    String textSearch = '',
  }) async {
    await _setupLiveQuery(descending, textSearch);
  }

  @override
  Future<void> addHotel(Hotel hotel) async {
    try {
      final col = _collection;
      if (col == null) return;
      final doc = MutableDocument({});
      doc.setString('hotel', key: 'type');
      doc.setString(hotel.name, key: 'name');
      doc.setString(hotel.title, key: 'title');
      doc.setString(hotel.description, key: 'description');
      doc.setString(hotel.address, key: 'address');
      doc.setString(hotel.city, key: 'city');
      doc.setString(hotel.state, key: 'state');
      doc.setString(hotel.country, key: 'country');
      doc.setString(hotel.phone, key: 'phone');
      doc.setString(hotel.email, key: 'email');
      doc.setString(hotel.url, key: 'url');
      col.saveDocument(doc);
    } catch (e) {
      ErrorManager().showError(
        ErrorModel(title: 'Save Error', message: 'Failed to save hotel: $e'),
      );
    }
  }

  @override
  Future<void> updateHotel(Hotel hotel) async {
    try {
      final col = _collection;
      if (col == null) return;

      final docId = hotel.documentId;
      if (docId == null) {
        await addHotel(hotel);
        return;
      }

      final existingDoc = col.document(docId);
      if (existingDoc == null) return;

      final mutableDoc = existingDoc.toMutable();
      mutableDoc.setString(hotel.name, key: 'name');
      mutableDoc.setString(hotel.title, key: 'title');
      mutableDoc.setString(hotel.description, key: 'description');
      mutableDoc.setString(hotel.address, key: 'address');
      mutableDoc.setString(hotel.city, key: 'city');
      mutableDoc.setString(hotel.state, key: 'state');
      mutableDoc.setString(hotel.country, key: 'country');
      mutableDoc.setString(hotel.phone, key: 'phone');
      mutableDoc.setString(hotel.email, key: 'email');
      mutableDoc.setString(hotel.url, key: 'url');
      col.saveDocument(mutableDoc);
    } catch (e) {
      ErrorManager().showError(
        ErrorModel(
          title: 'Update Error',
          message: 'Failed to update hotel: $e',
        ),
      );
    }
  }

  @override
  Future<void> deleteHotel(Hotel hotel) async {
    try {
      final col = _collection;
      if (col == null) return;
      final docId = hotel.documentId;
      if (docId == null) return;
      final doc = col.document(docId);
      if (doc != null) {
        col.deleteDocument(doc);
      }
    } catch (e) {
      ErrorManager().showError(
        ErrorModel(
          title: 'Delete Error',
          message: 'Failed to delete hotel: $e',
        ),
      );
    }
  }

  Hotel? _resultToHotel(Result result) {
    final documentId = result.string('documentId');
    final hotelDict = result.dictionary('hotel');
    if (hotelDict == null) return null;

    return Hotel(
      documentId: documentId,
      name: hotelDict.string('name') ?? '',
      title: hotelDict.string('title') ?? '',
      description: hotelDict.string('description') ?? '',
      address: hotelDict.string('address') ?? '',
      city: hotelDict.string('city') ?? '',
      state: hotelDict.string('state') ?? '',
      country: hotelDict.string('country') ?? '',
      phone: hotelDict.string('phone') ?? '',
      email: hotelDict.string('email') ?? '',
      url: hotelDict.string('url') ?? '',
    );
  }

  void close() {
    if (_queryListenerToken != null && _database != null) {
      // _database!.createQuery('SELECT 1').removeChangeListener(_queryListenerToken!);
    }
    _replicator?.stop();
    _replicator?.close();
    _database?.close();
    _queryUpdatesController.close();
    _replicatorStatusController.close();
  }
}
