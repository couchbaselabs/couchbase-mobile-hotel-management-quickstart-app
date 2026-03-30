/**
 * HotelRepository.test.js
 *
 * Unit tests for HotelRepository.
 * CBL JS SDK is mocked; Fuse.js runs normally.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import HotelRepository from '../model/HotelRepository';

// ─── Mock collection and database ─────────────────────────────────────────

const MOCK_HOTELS = [
  { _docId: 'hotel-1', id: 1, name: 'The Grand Plaza', country: 'USA', city: 'New York', type: 'hotel', phone: '+1-555-001', description: 'Luxury hotel in Manhattan' },
  { _docId: 'hotel-2', id: 2, name: 'Eiffel Suites', country: 'France', city: 'Paris', type: 'hotel', phone: '+33-1-001', description: 'Charming suites near the Eiffel Tower' },
  { _docId: 'hotel-3', id: 3, name: 'Tokyo Zen Inn', country: 'Japan', city: 'Tokyo', type: 'hotel', phone: '+81-3-001', description: 'Tranquil inn in Shinjuku' },
];

function makeQueryResult(rows) {
  return rows.map((row) => ({
    hotel: row,
    _docId: row._docId,
  }));
}

const mockCollection = {
  createDocument: vi.fn((data) => ({ ...data, _id: 'new-id-1' })),
  save: vi.fn(async () => {}),
  getDocument: vi.fn(async (id) => MOCK_HOTELS.find((h) => h._docId === id) ?? null),
  delete: vi.fn(async () => {}),
};

const mockQuery = {
  execute: vi.fn(async () => makeQueryResult(MOCK_HOTELS)),
};

const mockDatabase = {
  createQuery: vi.fn(() => mockQuery),
};

// ─── Tests ─────────────────────────────────────────────────────────────────

describe('HotelRepository', () => {
  let repo;

  beforeEach(() => {
    vi.clearAllMocks();
    repo = new HotelRepository(mockDatabase, mockCollection);
  });

  describe('getAllHotels()', () => {
    it('queries the database and returns normalized hotels', async () => {
      const hotels = await repo.getAllHotels();
      expect(mockDatabase.createQuery).toHaveBeenCalledOnce();
      expect(hotels).toHaveLength(3);
      expect(hotels[0]).toHaveProperty('name', 'The Grand Plaza');
    });
  });

  describe('getHotelById()', () => {
    it('retrieves a hotel by document ID', async () => {
      const hotel = await repo.getHotelById('hotel-2');
      expect(mockCollection.getDocument).toHaveBeenCalledWith('hotel-2');
      expect(hotel).toHaveProperty('name', 'Eiffel Suites');
    });

    it('returns null for a missing document', async () => {
      const hotel = await repo.getHotelById('hotel-999');
      expect(hotel).toBeNull();
    });
  });

  describe('addHotel()', () => {
    it('creates and saves a new hotel document', async () => {
      const newHotel = { name: 'The Riviera', country: 'Italy', city: 'Rome', type: 'hotel' };
      const docId = await repo.addHotel(newHotel);
      expect(mockCollection.createDocument).toHaveBeenCalledWith(
        expect.objectContaining({ name: 'The Riviera', type: 'hotel' })
      );
      expect(mockCollection.save).toHaveBeenCalledOnce();
      expect(docId).toBe('new-id-1');
    });
  });

  describe('updateHotel()', () => {
    it('retrieves, mutates, and saves the document', async () => {
      await repo.updateHotel('hotel-1', { name: 'The Grand Plaza (Renovated)' });
      expect(mockCollection.getDocument).toHaveBeenCalledWith('hotel-1');
      expect(mockCollection.save).toHaveBeenCalledOnce();
    });

    it('throws when the hotel is not found', async () => {
      await expect(repo.updateHotel('hotel-999', { name: 'X' })).rejects.toThrow('Hotel not found: hotel-999');
    });
  });

  describe('deleteHotel()', () => {
    it('retrieves and deletes the document', async () => {
      await repo.deleteHotel('hotel-3');
      expect(mockCollection.getDocument).toHaveBeenCalledWith('hotel-3');
      expect(mockCollection.delete).toHaveBeenCalledOnce();
    });

    it('throws when the hotel is not found', async () => {
      await expect(repo.deleteHotel('hotel-999')).rejects.toThrow('Hotel not found: hotel-999');
    });
  });

  describe('searchHotels() — Fuse.js', () => {
    it('returns all hotels when search term is empty', () => {
      const result = repo.searchHotels('', MOCK_HOTELS);
      expect(result).toHaveLength(3);
    });

    it('returns matching hotels for a valid search term', () => {
      const result = repo.searchHotels('Paris', MOCK_HOTELS);
      expect(result.length).toBeGreaterThanOrEqual(1);
      expect(result[0].name).toBe('Eiffel Suites');
    });

    it('returns fuzzy match for partial / typo search', () => {
      const result = repo.searchHotels('Toko', MOCK_HOTELS); // typo for Tokyo
      expect(result.length).toBeGreaterThanOrEqual(1);
      expect(result[0].city).toBe('Tokyo');
    });

    it('returns empty array when no match found', () => {
      const result = repo.searchHotels('zzzznotaplace', MOCK_HOTELS);
      expect(result).toHaveLength(0);
    });

    it('returns all hotels when term is too short (< 2 chars)', () => {
      const result = repo.searchHotels('a', MOCK_HOTELS);
      expect(result).toHaveLength(3);
    });
  });
});
