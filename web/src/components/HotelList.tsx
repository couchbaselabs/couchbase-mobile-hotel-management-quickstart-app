/**
 * HotelList.jsx
 * Renders the full list of hotels as HotelCard components.
 */


import HotelCard from './HotelCard';
import type { HotelWithId } from '../model/HotelRepository';

interface HotelListProps {
  hotels: HotelWithId[];
  loading: boolean;
  onEdit: (hotel: HotelWithId) => void;
  onDelete: (docId: string) => void;
}

export default function HotelList({ hotels, loading, onEdit, onDelete }: HotelListProps) {
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
          key={hotel.docId || hotel.id}
          hotel={hotel}
          onEdit={onEdit}
          onDelete={onDelete}
        />
      ))}
    </div>
  );
}
