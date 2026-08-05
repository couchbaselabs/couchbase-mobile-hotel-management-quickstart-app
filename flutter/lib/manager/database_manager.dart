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
import 'package:flutter/foundation.dart';
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

  // This app only ever creates a SyncDatabase, so the query/replicator
  // objects it produces are always the synchronous variants. Keeping the
  // concrete Sync* types (instead of the general Query/Replicator interfaces,
  // which are also implemented by an async/isolate-backed variant) lets the
  // compiler guarantee that, removing the need for runtime `is Future`
  // checks around every call.
  SyncReplicator? _replicator;
  SyncQuery? _liveQuery;
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
      // Expected when the index already exists from a previous run.
      debugPrint('DatabaseManager: createIndex($_ftsIndexName) skipped: $e');
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

        SyncReplicator.create(replConfig).then((replicator) {
          _replicator = replicator;
          _replicator!.addChangeListener((change) {
            if (!_replicatorStatusController.isClosed) {
              _replicatorStatusController.add(change.status.activity.name);
            }
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
          _replicator!.start();
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
        _liveQuery?.removeChangeListener(_queryListenerToken!);
        _queryListenerToken = null;
      }

      final sortOrder = descending ? 'DESC' : 'ASC';
      SyncQuery query;

      if (textSearch.isNotEmpty) {
        final pattern = '$textSearch*';
        query = db.createQuery(
          'SELECT META().id AS documentId, * FROM `$_scopeName`.`$_collectionName` AS hotel '
          'WHERE MATCH($_ftsIndexName, \$searchTerm) '
          'ORDER BY RANK($_ftsIndexName) $sortOrder',
        );
        final params = Parameters();
        params.setString(pattern, name: 'searchTerm');
        query.setParameters(params);
      } else {
        query = db.createQuery(
          'SELECT META().id AS documentId, * FROM `$_scopeName`.`$_collectionName` AS hotel '
          'ORDER BY hotel.name $sortOrder',
        );
      }

      _liveQuery = query;
      _queryListenerToken = query.addChangeListener((change) {
        final hotels = <Hotel>[];
        for (final result in change.results.allResults()) {
          try {
            final hotel = _resultToHotel(result);
            if (hotel != null) hotels.add(hotel);
          } catch (e) {
            debugPrint('DatabaseManager: skipping invalid query result: $e');
          }
        }
        if (!_queryUpdatesController.isClosed) {
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
      col.saveDocument(MutableDocument(hotel.toMap()));
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
      mutableDoc.setData(hotel.toMap());
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
    return Hotel.fromMap(hotelDict.toPlainMap(), documentId);
  }

  void close() {
    if (_queryListenerToken != null && _liveQuery != null) {
      _liveQuery!.removeChangeListener(_queryListenerToken!);
    }
    _replicator?.stop();
    _replicator?.close();
    _database?.close();
    _queryUpdatesController.close();
    _replicatorStatusController.close();
    _instance = null;
  }
}
