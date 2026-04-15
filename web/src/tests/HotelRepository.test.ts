/**
 * HotelRepository.test.js
 *
 * Unit tests for HotelRepository.
 * CBL JS SDK is mocked; Fuse.js runs normally.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import HotelRepository, { type HotelWithId } from '../model/HotelRepository';

// ─── Mock collection and database ─────────────────────────────────────────

vi.mock('@couchbase/lite-js', () => ({
  meta: vi.fn((doc) => ({ id: doc._id })),
}));

const MOCK_HOTELS = [
  { docId: 'hotel-1', id: 1, name: 'The Grand Plaza', country: 'USA', city: 'New York', type: 'hotel' as const, phone: '+1-555-001', description: 'Luxury hotel in Manhattan' },
  { docId: 'hotel-2', id: 2, name: 'Eiffel Suites', country: 'France', city: 'Paris', type: 'hotel' as const, phone: '+33-1-001', description: 'Charming suites near the Eiffel Tower' },
  { docId: 'hotel-3', id: 3, name: 'Tokyo Zen Inn', country: 'Japan', city: 'Tokyo', type: 'hotel' as const, phone: '+81-3-001', description: 'Tranquil inn in Shinjuku' },
];

function makeQueryResult(rows: HotelWithId[]) {
  return rows.map((row: HotelWithId) => ({
    hotel: row,
    docId: row.docId,
  }));
}

const mockCollection = {
  createDocument: vi.fn((data) => ({ ...data, _id: 'new-id-1' })),
  save: vi.fn(async () => { }),
  getDocument: vi.fn(async (id) => MOCK_HOTELS.find((h) => h.docId === id) ?? null),
  delete: vi.fn(async () => { }),
};

const mockQuery = {
  execute: vi.fn(async () => makeQueryResult(MOCK_HOTELS as unknown as HotelWithId[])),
};

const mockDatabase = {
  createQuery: vi.fn(() => mockQuery),
};

// ─── Tests ─────────────────────────────────────────────────────────────────

describe('HotelRepository', () => {
  let repo: HotelRepository;

  beforeEach(() => {
    vi.clearAllMocks();
    // @ts-ignore: Mock objects do not implement the full interface
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


  describe('searchHotels() — Fuse.js', () => {
    it('returns all hotels when search term is empty', () => {
      const result = repo.searchHotels('', MOCK_HOTELS as unknown as HotelWithId[]);
      expect(result).toHaveLength(3);
    });

    it('returns matching hotels for a valid search term', () => {
      const result = repo.searchHotels('Paris', MOCK_HOTELS as unknown as HotelWithId[]);
      expect(result.length).toBeGreaterThanOrEqual(1);
      expect(result[0].name).toBe('Eiffel Suites');
    });

    it('returns fuzzy match for partial / typo search', () => {
      const result = repo.searchHotels('Toko', MOCK_HOTELS as unknown as HotelWithId[]); // typo for Tokyo
      expect(result.length).toBeGreaterThanOrEqual(1);
      expect(result[0].city).toBe('Tokyo');
    });

    it('returns empty array when no match found', () => {
      const result = repo.searchHotels('zzzznotaplace', MOCK_HOTELS as unknown as HotelWithId[]);
      expect(result).toHaveLength(0);
    });

    it('returns all hotels when term is too short (< 2 chars)', () => {
      const result = repo.searchHotels('a', MOCK_HOTELS as unknown as HotelWithId[]);
      expect(result).toHaveLength(3);
    });
  });
});
