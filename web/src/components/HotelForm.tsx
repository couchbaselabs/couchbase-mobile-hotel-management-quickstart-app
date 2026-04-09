/**
 * HotelForm.jsx
 * Form for adding or editing a hotel document.
 */

import React, { useState, useEffect } from 'react';
import type { Hotel } from '../model/HotelRepository';

const EMPTY_FORM = {
  name: '',
  country: '',
  city: '',
  address: '',
  phone: '',
  description: '',
};

interface HotelFormProps {
  initialData?: Hotel;
  onSubmit: (data: Partial<Hotel>) => void;
  onCancel: () => void;
}

export default function HotelForm({ initialData, onSubmit, onCancel }: HotelFormProps) {
  const [form, setForm] = useState(EMPTY_FORM);
  const isEditing = Boolean(initialData);

  useEffect(() => {
    if (initialData) {
      setForm({
        name: initialData.name || '',
        country: (initialData.country as string) || '',
        city: (initialData.city as string) || '',
        address: (initialData.address as string) || '',
        phone: (initialData.phone as string) || (Array.isArray(initialData.phones) ? String(initialData.phones[0]) : ''),
        description: (initialData.description as string) || '',
      });
    } else {
      setForm(EMPTY_FORM);
    }
  }, [initialData]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) return;
    onSubmit({ ...form, type: 'hotel' });
  };

  return (
    <div className="modal-overlay" role="dialog" aria-modal="true" aria-label="Hotel form">
      <div className="modal">
        <h2 className="modal-title">{isEditing ? 'Edit Hotel' : 'Add New Hotel'}</h2>
        <form className="hotel-form" onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="hotel-name">Hotel Name *</label>
            <input
              id="hotel-name"
              name="name"
              type="text"
              value={form.name}
              onChange={handleChange}
              required
              placeholder="e.g. The Grand Plaza"
            />
          </div>
          <div className="form-row">
            <div className="form-group">
              <label htmlFor="hotel-city">City</label>
              <input id="hotel-city" name="city" type="text" value={form.city} onChange={handleChange} placeholder="e.g. Paris" />
            </div>
            <div className="form-group">
              <label htmlFor="hotel-country">Country</label>
              <input id="hotel-country" name="country" type="text" value={form.country} onChange={handleChange} placeholder="e.g. France" />
            </div>
          </div>
          <div className="form-group">
            <label htmlFor="hotel-address">Address</label>
            <input id="hotel-address" name="address" type="text" value={form.address} onChange={handleChange} placeholder="e.g. 123 Main Street" />
          </div>
          <div className="form-group">
            <label htmlFor="hotel-phone">Phone</label>
            <input id="hotel-phone" name="phone" type="text" value={form.phone} onChange={handleChange} placeholder="e.g. +33 1 23 45 67 89" />
          </div>
          <div className="form-group">
            <label htmlFor="hotel-description">Description</label>
            <textarea id="hotel-description" name="description" value={form.description} onChange={handleChange} rows={3} placeholder="Short description…" />
          </div>
          <div className="form-actions">
            <button id="hotel-form-cancel" type="button" className="btn btn-secondary" onClick={onCancel}>
              Cancel
            </button>
            <button id="hotel-form-submit" type="submit" className="btn btn-primary">
              {isEditing ? 'Save Changes' : 'Add Hotel'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
