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
import { meta, type Database, type Collection, type DocID, type CBLValue } from '@couchbase/lite-js';
import type { AppSchema } from './DatabaseManager';


/** Fuse.js options: search on name, country, and description fields */
const FUSE_OPTIONS = {
  keys: ['name', 'country', 'description', 'city'],
  threshold: 0.35,       // 0 = exact match, 1 = match anything
  includeScore: true,
  minMatchCharLength: 2,
};


export interface Review {
  [key: string]: CBLValue;
  author: string | null;
  content: string | null;
  date: string | null;
  ratings: Record<string, CBLValue> | null;
}

// Define document types for collections
// tag::database-schema[]
interface Geo {
  [key: string]: CBLValue;
  lat: number;
  lon: number;
  accuracy: string;
}

export interface Hotel {
  [key: string]: CBLValue;
  docId: string;
  type: 'hotel';
  title: string | null;
  name: string;
  address: string | null;
  directions: string | null;
  phone: string | null;
  tollfree: string | null;
  email: string | null;
  fax: string | null;
  url: string | null;
  checkin: string | null;
  checkout: string | null;
  price: string | null;
  geo: Geo | null;
  id: number;
  country: string | null;
  city: string | null;
  state: string | null;
  reviews: Review[];
  public_likes: string[];
  vacancy: boolean;
  description: string | null;
  alias: string | null;
  pets_ok: boolean;
  free_breakfast: boolean;
  free_internet: boolean;
  free_parking: boolean;
}


class HotelRepository {
  database: Database<AppSchema>;
  collection: Collection<Hotel>;

  constructor(database: Database<AppSchema>, collection: Collection<Hotel>) {
    this.database = database;
    this.collection = collection;
  }

  /**
   * Return all hotels ordered by name ascending.
   * @returns {Promise<Array>}
   */
  async getAllHotels() {
    const query = this.database.createQuery(
      `SELECT *, META().id AS docId
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
    const doc = await this.collection.getDocument(docId as DocID);
    return doc ? { ...doc, docId: docId } : null;
  }

  /**
   * Add a new hotel document to the collection.
   * @param {object} hotel
   * @returns {Promise<string>} The new document's ID
   */
  async addHotel(hotel: Partial<Hotel>) {
    const doc = this.collection.createDocument(null, {
      type: 'hotel',
      ...hotel,
    } as Hotel);
    await this.collection.save(doc);
    console.log('[HotelRepository] Hotel added:', hotel.name);
    return meta(doc).id;
  }

  /**
   * Update an existing hotel document.
   * @param {string} docId
   * @param {object} data Partial hotel fields to update
   */
  async updateHotel(docId: string, data: Partial<Hotel>) {
    const doc = await this.collection.getDocument(docId as DocID);
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
    const doc = await this.collection.getDocument(docId as DocID);
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
  searchHotels(term: string, hotels: Hotel[]) {
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
function normalizeHotel(row: Record<string, unknown>) {
  // SQL++ SELECT hotel.* returns fields under a 'hotel' key when aliased
  const h = (row.hotel as Record<string, unknown>) || row;
  return {
    docId: String(row.docId || h.docId || h.id),
    id: h.id,
    name: (h.name as string) || '',
    type: (h.type as "hotel") || 'hotel',
    country: (h.country as string) || '',
    city: (h.city as string) || '',
    address: (h.address as string) || '',
    phone: (h.phone as string) || (Array.isArray(h.phones) ? String(h.phones[0]) : ''),
    description: (h.description as string) || '',
    ...h,
  } as Hotel;
}

export default HotelRepository;
