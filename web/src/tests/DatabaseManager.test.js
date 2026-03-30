/**
 * DatabaseManager.test.js
 *
 * Unit tests for DatabaseManager using a mocked @couchbase/lite-js module.
 * Since the CBL JS SDK requires a browser IndexedDB environment, the module
 * is fully mocked for Node/Vitest.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';

// ─── Mock @couchbase/lite-js ───────────────────────────────────────────────

const mockCollection = {
  addChangeListener: vi.fn(() => 'token-123'),
  removeChangeListener: vi.fn(),
};

const mockDatabase = {
  collection: { hotel: mockCollection },
  close: vi.fn(),
  createQuery: vi.fn(() => ({
    execute: vi.fn(async () => []),
  })),
};

const mockReplicator = {
  start: vi.fn(async () => {}),
  stop: vi.fn(),
  addChangeListener: vi.fn(),
};

vi.mock('@couchbase/lite-js', () => ({
  Database: {
    open: vi.fn(async () => mockDatabase),
  },
  Replicator: vi.fn(function (config) {
    Object.assign(this, mockReplicator);
    this._config = config;
  }),
}));


// ─── Re-import after mock ─────────────────────────────────────────────────

import DatabaseManager from '../model/DatabaseManager';
import { Database, Replicator } from '@couchbase/lite-js';

describe('DatabaseManager', () => {
  let manager;

  beforeEach(() => {
    vi.clearAllMocks();
    manager = new DatabaseManager();
  });

  it('opens the database with the correct name on initialize()', async () => {
    await manager.initialize();
    expect(Database.open).toHaveBeenCalledOnce();
    expect(Database.open).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'travel-sample' })
    );
  });

  it('exposes the hotel collection after initialize()', async () => {
    await manager.initialize();
    expect(manager.getCollection()).toBe(mockCollection);
  });

  it('creates a Replicator with correct config on setupReplication()', async () => {
    await manager.initialize();
    const cfg = {
      capellaEndpointUrl: 'wss://test.apps.cloud.couchbase.com/hotels',
      username: 'alice',
      password: 'secret',
    };
    await manager.setupReplication(cfg);

    expect(Replicator).toHaveBeenCalledWith(
      expect.objectContaining({
        url: cfg.capellaEndpointUrl,
        credentials: { username: 'alice', password: 'secret' },
        continuous: true,
      })
    );
    expect(mockReplicator.start).toHaveBeenCalledOnce();
  });

  it('registers a collection change listener', async () => {
    await manager.initialize();
    const cb = vi.fn();
    manager.addChangeListener(cb);
    expect(mockCollection.addChangeListener).toHaveBeenCalledWith(cb);
  });

  it('removes the change listener on close()', async () => {
    await manager.initialize();
    manager.addChangeListener(vi.fn());
    await manager.close();
    expect(mockCollection.removeChangeListener).toHaveBeenCalledWith('token-123');
    expect(mockDatabase.close).toHaveBeenCalledOnce();
  });

  it('throws if setupReplication() called before initialize()', async () => {
    await expect(
      manager.setupReplication({ capellaEndpointUrl: '', username: '', password: '' })
    ).rejects.toThrow('Database not initialized');
  });
});
