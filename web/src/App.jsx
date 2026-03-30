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

import React, { useState, useEffect, useCallback, useRef } from 'react';
import { databaseManager } from './model/DatabaseManager';
import HotelRepository from './model/HotelRepository';
import HotelList from './components/HotelList';
import SearchBar from './components/SearchBar';
import HotelForm from './components/HotelForm';
import SyncStatus from './components/SyncStatus';

export default function App() {
  const [hotels, setHotels] = useState([]);
  const [filteredHotels, setFilteredHotels] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(true);
  const [syncStatus, setSyncStatus] = useState('idle');
  const [showForm, setShowForm] = useState(false);
  const [editingHotel, setEditingHotel] = useState(null);
  const [error, setError] = useState(null);

  const repoRef = useRef(null);

  // ─── Initialization ───────────────────────────────────────────────────────

  useEffect(() => {
    let mounted = true;

    async function init() {
      try {
        await databaseManager.initialize();
        const repo = new HotelRepository(
          databaseManager.getDatabase(),
          databaseManager.getCollection()
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
          if (cfg.capellaEndpointUrl && !cfg.capellaEndpointUrl.includes('your-endpoint')) {
            setSyncStatus('connecting');
            const replicator = await databaseManager.setupReplication(cfg);
            // Monitor replicator status changes
            replicator.addChangeListener?.((change) => {
              const activity = change?.status?.activityLevel;
              if (activity === 'BUSY' || activity === 'CONNECTING') setSyncStatus('syncing');
              else if (activity === 'IDLE' || activity === 'STOPPED') setSyncStatus('connected');
              else if (activity === 'OFFLINE') setSyncStatus('idle');
            });
            setSyncStatus('connected');
          }
        } catch {
          // Config missing or unconfigured — offline-only mode is fine
          console.info('[App] No Capella config — running offline.');
        }
      } catch (err) {
        console.error('[App] Init error:', err);
        if (mounted) {
          setError(err.message);
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

  const handleAddOrUpdate = useCallback(async (formData) => {
    const repo = repoRef.current;
    if (!repo) return;
    try {
      if (editingHotel) {
        await repo.updateHotel(editingHotel._docId, formData);
      } else {
        await repo.addHotel(formData);
      }
      // Refresh list; change listener may also trigger this
      const all = await repo.getAllHotels();
      setHotels(all);
    } catch (err) {
      console.error('[App] Save error:', err);
      setError(err.message);
    } finally {
      setShowForm(false);
      setEditingHotel(null);
    }
  }, [editingHotel]);

  const handleEdit = useCallback((hotel) => {
    setEditingHotel(hotel);
    setShowForm(true);
  }, []);

  const handleDelete = useCallback(async (docId) => {
    const repo = repoRef.current;
    if (!repo) return;
    if (!window.confirm('Delete this hotel?')) return;
    try {
      await repo.deleteHotel(docId);
      const all = await repo.getAllHotels();
      setHotels(all);
    } catch (err) {
      console.error('[App] Delete error:', err);
      setError(err.message);
    }
  }, []);

  const handleCancelForm = useCallback(() => {
    setShowForm(false);
    setEditingHotel(null);
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
            onClick={() => { setEditingHotel(null); setShowForm(true); }}
          >
            + Add Hotel
          </button>
        </div>
      </header>

      {/* Error banner */}
      {error && (
        <div className="error-banner" role="alert">
          <strong>Error:</strong> {error}
          <button onClick={() => setError(null)} aria-label="Dismiss error">✕</button>
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
