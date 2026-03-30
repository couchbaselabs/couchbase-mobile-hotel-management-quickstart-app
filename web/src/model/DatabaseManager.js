/**
 * DatabaseManager.js
 *
 * Model layer — manages the Couchbase Lite database lifecycle, collection
 * access, and replication with Capella App Services.
 *
 * Mirrors the role of DatabaseManager.kt (Android) and DatabaseManager.swift (iOS).
 */

import { Database, Replicator } from '@couchbase/lite-js';

const DB_NAME = 'travel-sample';
const SCOPE_NAME = 'inventory';
const COLLECTION_NAME = 'hotel';

class DatabaseManager {
  constructor() {
    /** @type {import('@couchbase/lite-js').Database|null} */
    this.database = null;
    /** @type {any} Collection reference */
    this.collection = null;
    /** @type {import('@couchbase/lite-js').Replicator|null} */
    this.replicator = null;
    /** @type {Function|null} Unsubscribe function for the collection change listener */
    this._changeListenerToken = null;
  }

  /**
   * Open (or create) the local Couchbase Lite database and obtain the hotel collection.
   */
  async initialize() {
    const config = {
      name: DB_NAME,
      version: 1,
      collections: {
        [COLLECTION_NAME]: {},
      },
    };

    this.database = await Database.open(config);
    // Access the scoped collection: inventory.hotel
    this.collection = this.database.collection[COLLECTION_NAME];
    console.log('[DatabaseManager] Database initialized:', DB_NAME);
  }

  /**
   * Configure and start continuous bi-directional replication with Capella App Services.
   * @param {{ capellaEndpointUrl: string, username: string, password: string }} config
   */
  async setupReplication(config) {
    if (!this.database) throw new Error('Database not initialized.');

    const replicator = new Replicator({
      database: this.database,
      url: config.capellaEndpointUrl,
      collections: {
        [COLLECTION_NAME]: { pull: {}, push: {} },
      },
      credentials: {
        username: config.username,
        password: config.password,
      },
      continuous: true,
    });

    this.replicator = replicator;
    await replicator.start();
    console.log('[DatabaseManager] Replication started →', config.capellaEndpointUrl);
    return replicator;
  }

  /**
   * Subscribe to collection changes (live updates).
   * @param {(event: any) => void} callback
   */
  addChangeListener(callback) {
    if (!this.collection) throw new Error('Collection not available.');
    this._changeListenerToken = this.collection.addChangeListener(callback);
  }

  /**
   * Remove the collection change listener.
   */
  removeChangeListener() {
    if (this._changeListenerToken) {
      this.collection?.removeChangeListener(this._changeListenerToken);
      this._changeListenerToken = null;
    }
  }

  /**
   * Return the hotel collection reference.
   * @returns {any} Collection
   */
  getCollection() {
    return this.collection;
  }

  /**
   * Return the database instance.
   * @returns {import('@couchbase/lite-js').Database|null}
   */
  getDatabase() {
    return this.database;
  }

  /**
   * Close the database and stop replication cleanly.
   */
  async close() {
    this.removeChangeListener();
    if (this.replicator) {
      this.replicator.stop?.();
      this.replicator = null;
    }
    if (this.database) {
      await this.database.close?.();
      this.database = null;
      this.collection = null;
    }
    console.log('[DatabaseManager] Database closed.');
  }
}

// Export a singleton instance
export const databaseManager = new DatabaseManager();
export default DatabaseManager;
