/**
 * DatabaseManager.js
 *
 * Model layer — manages the Couchbase Lite database lifecycle, collection
 * access, and replication with Capella App Services.
 *
 * Mirrors the role of DatabaseManager.kt (Android) and DatabaseManager.swift (iOS).
 */

import { Database, Replicator, type ReplicatorConfig, type DatabaseConfig } from '@couchbase/lite-js';

const DB_NAME = 'travel-sample';
const COLLECTION_NAME = 'inventory.hotel';

// Define document types for collections
// tag::database-schema[]
interface Geo {
  [key: string]: any;
  lat: number;
  lon: number;
  accuracy: string;
}

interface Hotel {
  [key: string]: any;
  type: 'hotel';
  title: string | null;
  name: string;
  address: string | null;
  directions: string | null;
  phone: string | null;
  tollfree: string | null;
  email: string | null;
  fax: string | null;
  url: string | null;
  checkin: string | null;
  checkout: string | null;
  price: string | null;
  geo: Geo | null;
  id: number;
  country: string | null;
  city: string | null;
  state: string | null;
  reviews: any[];
  public_likes: string[];
  vacancy: boolean;
  description: string | null;
  alias: string | null;
  pets_ok: boolean;
  free_breakfast: boolean;
  free_internet: boolean;
  free_parking: boolean;
}

// Declare collection with custom scopes
// tag::declare-custom-scope[]
interface AppSchema {
  'inventory.hotel': Hotel;
}


class DatabaseManager {
  database: Database<AppSchema> | null = null;
  collection: any = null;
  replicator: Replicator | null = null;
  _changeListenerToken: any = null;

  constructor() { }

  /**
   * Open (or create) the local Couchbase Lite database and obtain the hotel collection.
   */
  async initialize() {

    // end::database-schema[]

    const config: DatabaseConfig<AppSchema> = {
      name: 'travel-sample',
      version: 1,
      collections: {
        'inventory.hotel': {}
      }
    };
    this.database = await Database.open(config);
    // Access the scoped collection: inventory.hotel
    this.collection = (this.database as any).collections[COLLECTION_NAME];
    console.log('[DatabaseManager] Database initialized:', DB_NAME);
  }

  /**
   * Configure and start continuous bi-directional replication with Capella App Services.
   * @param {{ capellaEndpointUrl: string, username: string, password: string }} config
   */
  async setupReplication(config: any) {
    if (!this.database) throw new Error('Database not initialized.');

    const replicatorConfig = {
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
    } as any;

    this.replicator = new Replicator(replicatorConfig);
    await (this.replicator as any).run();
    console.log('[DatabaseManager] Replication started →', config.capellaEndpointUrl);
    return this.replicator;
  }

  /**
   * Subscribe to collection changes (live updates).
   * @param {(event: any) => void} callback
   */
  addChangeListener(callback: (event: any) => void) {
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
