/**
 * DatabaseManager.js
 *
 * Model layer — manages the Couchbase Lite database lifecycle, collection
 * access, and replication with Capella App Services.
 *
 * Mirrors the role of DatabaseManager.kt (Android) and DatabaseManager.swift (iOS).
 */

import { Database, Replicator, Collection, type ListenerToken, type CollectionChange, type ReplicatorConfig, type DatabaseConfig } from '@couchbase/lite-js';
import type { Hotel } from './HotelRepository';

const DB_NAME = 'travel-sample';
export const COLLECTION_NAME = 'inventory.hotel';

export interface SyncConfig {
  capellaEndpointUrl: string;
  username: string;
  password: string;
}

// Declare collection with custom scopes
// tag::declare-custom-scope[]
export interface AppSchema {
  'inventory.hotel': Hotel;
}


class DatabaseManager {
  database?: Database<AppSchema>;
  collection?: Collection<Hotel>;
  replicator?: Replicator;
  _changeListenerToken?: ListenerToken;

  constructor() { }

  /**
   * Open (or create) the local Couchbase Lite database and obtain the hotel collection.
   */
  async initialize(): Promise<void> {

    // end::database-schema[]

    const config: DatabaseConfig<AppSchema> = {
      name: 'travel-sample',
      version: 1,
      collections: {
        'inventory.hotel': {}
      }
    };
    const db = await Database.open(config);
    this.database = db;
    // Access the scoped collection: inventory.hotel
    this.collection = db.collections[COLLECTION_NAME];
    console.log('[DatabaseManager] Database initialized:', DB_NAME);
  }

  /**
   * Configure and start continuous bi-directional replication with Capella App Services.
   * @param config
   */
  async setupReplication(config: SyncConfig): Promise<Replicator> {
    if (!this.database) throw new Error('Database not initialized.');

    const replicatorConfig: ReplicatorConfig = {
      database: this.database as unknown as Database,
      url: config.capellaEndpointUrl,
      collections: {
        [COLLECTION_NAME]: {
          pull: { continuous: true },
          push: { continuous: true }
        },
      },
      credentials: {
        username: config.username,
        password: config.password,
      },
    };

    this.replicator = new Replicator(replicatorConfig);
    return this.replicator;
  }


  /**
   * Subscribe to collection changes (live updates).
   * @param callback
   */
  addChangeListener(callback: (event: CollectionChange) => void): void {
    if (!this.collection) throw new Error('Collection not available.');
    this._changeListenerToken = this.collection.addChangeListener(callback);
  }

  /**
   * Remove the collection change listener.
   */
  removeChangeListener(): void {
    if (this._changeListenerToken) {
      this._changeListenerToken.remove();
      this._changeListenerToken = undefined;
    }
  }

  /**
   * Return the hotel collection reference.
   */
  getCollection(): Collection<Hotel> | undefined {
    return this.collection;
  }

  /**
   * Return the database instance.
   */
  getDatabase(): Database<AppSchema> | undefined {
    return this.database;
  }

  /**
   * Close the database and stop replication cleanly.
   */
  async close(): Promise<void> {
    this.removeChangeListener();
    if (this.replicator) {
      this.replicator.stop();
      this.replicator = undefined;
    }
    if (this.database) {
      await this.database.close();
      this.database = undefined;
      this.collection = undefined;
    }
    console.log('[DatabaseManager] Database closed.');
  }
}

// Export a singleton instance
export const databaseManager = new DatabaseManager();
export default DatabaseManager;
