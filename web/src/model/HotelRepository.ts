/**
 * HotelRepository.js
 *
 * Model layer — data access for hotel documents.
 * Uses SQL++ queries for listing/filtering and Fuse.js for Full-Text Search
 * (FTS via MATCH() is not supported in Couchbase Lite JavaScript).
 *
 * Mirrors HotelRepository / DatabaseManager CRUD logic in Android and iOS apps.
 */

import Fuse from 'fuse.js';
import { meta } from '@couchbase/lite-js';

/** Fuse.js options: search on name, country, and description fields */
const FUSE_OPTIONS = {
  keys: ['name', 'country', 'description', 'city'],
  threshold: 0.35,       // 0 = exact match, 1 = match anything
  includeScore: true,
  minMatchCharLength: 2,
};

class HotelRepository {
  database: any;
  collection: any;

  constructor(database: any, collection: any) {
    this.database = database;
    this.collection = collection;
  }

  /**
   * Return all hotels ordered by name ascending.
   * @returns {Promise<Array>}
   */
  async getAllHotels() {
    const query = this.database.createQuery(
      `SELECT *, META().id AS _docId
       FROM \`${COLLECTION_NAME}\` AS hotel
       ORDER BY hotel.name ASC`
    );
    const results = await query.execute();
    return results.map(normalizeHotel);
  }

  /**
   * Retrieve a single hotel by its document ID.
   * @param {string} docId
   * @returns {Promise<object|null>}
   */
  async getHotelById(docId: string) {
    const doc = await this.collection.getDocument(docId);
    return doc ? { ...doc, _docId: docId } : null;
  }

  /**
   * Add a new hotel document to the collection.
   * @param {object} hotel
   * @returns {Promise<string>} The new document's ID
   */
  async addHotel(hotel: any) {
    const doc = this.collection.createDocument(null, {
      type: 'hotel',
      ...hotel,
    });
    await this.collection.save(doc);
    console.log('[HotelRepository] Hotel added:', hotel.name);
    return meta(doc).id;
  }

  /**
   * Update an existing hotel document.
   * @param {string} docId
   * @param {object} data Partial hotel fields to update
   */
  async updateHotel(docId: string, data: any) {
    const doc = await this.collection.getDocument(docId);
    if (!doc) throw new Error(`Hotel not found: ${docId}`);
    Object.assign(doc, data);
    await this.collection.save(doc);
    console.log('[HotelRepository] Hotel updated:', docId);
  }

  /**
   * Delete a hotel document by its ID.
   * @param {string} docId
   */
  async deleteHotel(docId: string) {
    const doc = await this.collection.getDocument(docId);
    if (!doc) throw new Error(`Hotel not found: ${docId}`);
    await this.collection.delete(doc);
    console.log('[HotelRepository] Hotel deleted:', docId);
  }

  /**
   * Search hotels by name / country / city using Fuse.js fuzzy search.
   * Full-Text Search via MATCH() is not available in CBL JS SDK.
   *
   * @param {string} term - Search term
   * @param {Array} hotels - Pre-fetched hotel list to search within
   * @returns {Array} Matching hotels sorted by relevance score
   */
  searchHotels(term: string, hotels: any[]) {
    if (!term || term.trim().length < 2) return hotels;
    const fuse = new Fuse(hotels, FUSE_OPTIONS);
    return fuse.search(term).map((result) => result.item);
  }
}

// Collection name constant (scoped by Couchbase schema)
const COLLECTION_NAME = 'inventory.hotel';

/**
 * Normalize a raw CBL JS query result row into a plain hotel object.
 */
function normalizeHotel(row: any) {
  // SQL++ SELECT hotel.* returns fields under a 'hotel' key when aliased
  const h = row.hotel || row;
  return {
    _docId: row._docId || h._docId || h.id,
    id: h.id,
    name: h.name || '',
    type: h.type || 'hotel',
    country: h.country || '',
    city: h.city || '',
    address: h.address || '',
    phone: h.phone || h.phones?.[0] || '',
    description: h.description || '',
    ...h,
  };
}

export default HotelRepository;
