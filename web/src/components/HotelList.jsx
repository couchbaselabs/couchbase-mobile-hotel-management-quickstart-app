/**
 * HotelList.jsx
 * Renders the full list of hotels as HotelCard components.
 */

import React from 'react';
import HotelCard from './HotelCard';

export default function HotelList({ hotels, loading, onEdit, onDelete }) {
  if (loading) {
    return (
      <div className="hotel-list-empty">
        <div className="spinner" aria-label="Loading hotels" />
      </div>
    );
  }

  if (hotels.length === 0) {
    return (
      <div className="hotel-list-empty">
        <p>No hotels found. Add one or wait for sync to complete.</p>
      </div>
    );
  }

  return (
    <div className="hotel-list" data-testid="hotel-list">
      {hotels.map((hotel) => (
        <HotelCard
          key={hotel._docId || hotel.id}
          hotel={hotel}
          onEdit={onEdit}
          onDelete={onDelete}
        />
      ))}
    </div>
  );
}
