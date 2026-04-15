/**
 * HotelCard.jsx
 * Displays a single hotel's summary: name, location, phone.
 * Provides Edit and Delete actions.
 */

import type { HotelWithId } from '../model/HotelRepository';

interface HotelCardProps {
  hotel: HotelWithId;
  onEdit: (hotel: HotelWithId) => void;
  onDelete: (docId: string) => void;
}

export default function HotelCard({ hotel, onEdit, onDelete }: HotelCardProps) {
  return (
    <div className="hotel-card" data-testid="hotel-card">
      <div className="hotel-card-body">
        <h3 className="hotel-name">{hotel.name}</h3>
        <div className="hotel-meta">
          {hotel.city && <span className="hotel-location">{hotel.city}{hotel.country ? `, ${hotel.country}` : ''}</span>}
          {hotel.phone && (
            <a className="hotel-phone" href={`tel:${hotel.phone}`}>{hotel.phone}</a>
          )}
        </div>
        {hotel.description && (
          <p className="hotel-description">{hotel.description}</p>
        )}
      </div>
      <div className="hotel-card-actions">
        <button
          id={`edit-hotel-${hotel.docId}`}
          className="btn btn-secondary"
          onClick={() => onEdit(hotel)}
          aria-label={`Edit ${hotel.name}`}
        >
          Edit
        </button>
        <button
          id={`delete-hotel-${hotel.docId}`}
          className="btn btn-danger"
          onClick={() => onDelete(hotel.docId)}
          aria-label={`Delete ${hotel.name}`}
        >
          Delete
        </button>
      </div>
    </div>
  );
}
