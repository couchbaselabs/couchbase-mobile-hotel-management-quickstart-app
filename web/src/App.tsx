/**
 * App.jsx — Controller
 *
 * Root React component. Initialises DatabaseManager and HotelRepository,
 * subscribes to live collection changes, and orchestrates all CRUD/search actions.
 *
 * Architecture: MVC
 *   - Model: DatabaseManager + HotelRepository (src/model/)
 *   - View:  Components in src/components/
 *   - Controller: This file (App.jsx)
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { databaseManager } from './model/DatabaseManager';
import HotelRepository, { type Hotel, type HotelWithId } from './model/HotelRepository';
import HotelList from './components/HotelList';
import SearchBar from './components/SearchBar';
import HotelForm from './components/HotelForm';
import SyncStatus from './components/SyncStatus';
import type { ReplicatorStatus, DocID } from '@couchbase/lite-js';


export default function App() {
  const [hotels, setHotels] = useState<HotelWithId[]>([]);
  const [filteredHotels, setFilteredHotels] = useState<HotelWithId[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(true);
  const [syncStatus, setSyncStatus] = useState<'idle' | 'connecting' | 'syncing' | 'connected' | 'error'>('idle');
  const [showForm, setShowForm] = useState(false);
  const [editingHotel, setEditingHotel] = useState<HotelWithId>();
  const [error, setError] = useState<string>();

  const repoRef = useRef<HotelRepository>(undefined);

  // ─── Initialization ───────────────────────────────────────────────────────

  useEffect(() => {
    let mounted = true;

    async function init() {
      try {
        if (!mounted) return;
        await databaseManager.initialize();
        if (!mounted) return;
        const repo = new HotelRepository(
          databaseManager.getDatabase()!,
          databaseManager.getCollection()!
        );
        repoRef.current = repo;

        // Subscribe to collection changes → re-fetch hotels
        databaseManager.addChangeListener(async () => {
          if (!mounted) return;
          const all = await repo.getAllHotels();
          setHotels(all);
        });

        // Initial fetch
        const all = await repo.getAllHotels();
        if (mounted) {
          setHotels(all);
          setLoading(false);
        }

        // Start sync with Capella (load config from public/config.json)
        try {
          const res = await fetch('/config.json');
          const cfg = await res.json();
          if (!mounted) return;
          
          if (cfg.capellaEndpointUrl && !cfg.capellaEndpointUrl.includes('your-endpoint')) {
            setSyncStatus('connecting');
            const replicator = await databaseManager.setupReplication(cfg);
            if (!mounted) return;
            // Monitor replicator status changes
            replicator.onStatusChange = (status: ReplicatorStatus) => {
              const activity = status.status;
              if (status.error) {
                setSyncStatus('error');
              } else if (activity === 'busy' || activity === 'connecting') {
                setSyncStatus('syncing');
              } else if (activity === 'idle') {
                setSyncStatus('connected');
              } else if (activity === 'stopped') {
                setSyncStatus('idle');
              }
            };
            setSyncStatus('connected');

            replicator.run().catch(console.error);
            console.log('[App] Replication started →', cfg.capellaEndpointUrl);
          }
        } catch (e) {
          console.error(e);
          // Config missing or unconfigured — offline-only mode is fine
          console.info('[App] No Capella config — running offline.');
        }
      } catch (err) {
        console.error('[App] Init error:', err);
        if (mounted) {
          setError(err instanceof Error ? err.message : String(err));
          setLoading(false);
        }
      }
    }

    init();
    return () => {
      mounted = false;
      databaseManager.close();
    };
  }, []);

  // ─── Derived: apply Fuse.js search ────────────────────────────────────────

  useEffect(() => {
    if (!repoRef.current) return;
    if (!searchTerm.trim()) {
      setFilteredHotels(hotels);
    } else {
      setFilteredHotels(repoRef.current.searchHotels(searchTerm, hotels));
    }
  }, [hotels, searchTerm]);

  // ─── CRUD handlers ────────────────────────────────────────────────────────

  const handleAddOrUpdate = useCallback(async (formData: Partial<Hotel>) => {
    const repo = repoRef.current;
    if (!repo) return;
    try {
      const collection = databaseManager.getCollection();
      if (!collection) throw new Error("Collection not available");

      if (editingHotel) {
        const doc = await collection.getDocument(editingHotel.docId as DocID);
        if (!doc) throw new Error(`Hotel not found: ${editingHotel.docId}`);
        Object.assign(doc, formData);
        await collection.save(doc);
        console.log('[App] Hotel updated:', editingHotel.docId);
      } else {
        const doc = collection.createDocument(null, {
          type: 'hotel',
          ...formData,
        } as Hotel);
        await collection.save(doc);
        console.log('[App] Hotel added:', formData.name);
      }
      // Refresh list; change listener may also trigger this
      const all = await repo.getAllHotels();
      setHotels(all);
    } catch (err) {
      console.error('[App] Save error:', err);
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setShowForm(false);
      setEditingHotel(undefined);
    }
  }, [editingHotel]);

  const handleEdit = useCallback((hotel: HotelWithId) => {
    setEditingHotel(hotel);
    setShowForm(true);
  }, []);

  const handleDelete = useCallback(async (docId: string) => {
    const repo = repoRef.current;
    if (!repo) return;
    if (!window.confirm('Delete this hotel?')) return;
    try {
      const collection = databaseManager.getCollection();
      if (!collection) throw new Error("Collection not available");
      const doc = await collection.getDocument(docId as DocID);
      if (!doc) throw new Error(`Hotel not found: ${docId}`);
      await collection.delete(doc);
      console.log('[App] Hotel deleted:', docId);
      const all = await repo.getAllHotels();
      setHotels(all);
    } catch (err) {
      console.error('[App] Delete error:', err);
      setError(err instanceof Error ? err.message : String(err));
    }
  }, []);

  const handleCancelForm = useCallback(() => {
    setShowForm(false);
    setEditingHotel(undefined);
  }, []);

  // ─── Render ───────────────────────────────────────────────────────────────

  return (
    <div className="app">
      {/* Header */}
      <header className="app-header">
        <div className="header-left">
          <div className="logo">
            <span className="logo-icon">🏨</span>
            <div>
              <h1 className="app-title">Hotels</h1>
              <p className="app-subtitle">Quickstart · Couchbase Lite JS</p>
            </div>
          </div>
        </div>
        <div className="header-right">
          <SyncStatus status={syncStatus} />
          <button
            id="add-hotel-btn"
            className="btn btn-primary"
            onClick={() => { setEditingHotel(undefined); setShowForm(true); }}
          >
            + Add Hotel
          </button>
        </div>
      </header>

      {/* Error banner */}
      {error && (
        <div className="error-banner" role="alert">
          <strong>Error:</strong> {error}
          <button onClick={() => setError(undefined)} aria-label="Dismiss error">✕</button>
        </div>
      )}

      {/* Search */}
      <div className="search-section">
        <SearchBar
          value={searchTerm}
          onChange={setSearchTerm}
          onClear={() => setSearchTerm('')}
        />
        <p className="result-count">
          {loading ? 'Loading…' : `${filteredHotels.length} hotel${filteredHotels.length !== 1 ? 's' : ''}`}
          {searchTerm ? ` matching "${searchTerm}"` : ''}
        </p>
      </div>

      {/* Main content */}
      <main className="app-main">
        <HotelList
          hotels={filteredHotels}
          loading={loading}
          onEdit={handleEdit}
          onDelete={handleDelete}
        />
      </main>

      {/* Add/Edit modal */}
      {showForm && (
        <HotelForm
          initialData={editingHotel}
          onSubmit={handleAddOrUpdate}
          onCancel={handleCancelForm}
        />
      )}
    </div>
  );
}
