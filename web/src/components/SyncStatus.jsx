/**
 * SyncStatus.jsx
 * Shows the current replication / sync state to the user.
 */

import React from 'react';

const STATUS_LABELS = {
  idle: { label: 'Offline', color: '#8b949e' },
  connecting: { label: 'Connecting…', color: '#f0883e' },
  syncing: { label: 'Syncing', color: '#79c0ff' },
  connected: { label: 'Synced', color: '#3fb950' },
  error: { label: 'Sync Error', color: '#f85149' },
};

export default function SyncStatus({ status = 'idle' }) {
  const { label, color } = STATUS_LABELS[status] ?? STATUS_LABELS.idle;
  return (
    <div className="sync-status" style={{ '--status-color': color }}>
      <span className="sync-dot" />
      <span className="sync-label">{label}</span>
    </div>
  );
}
