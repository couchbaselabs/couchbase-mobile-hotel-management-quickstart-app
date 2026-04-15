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
import { type Database, type Collection, type CBLValue } from '@couchbase/lite-js';
import { COLLECTION_NAME, type AppSchema } from './DatabaseManager';


/** Fuse.js options: search on name, country, and description fields */
const FUSE_OPTIONS = {
  keys: ['name', 'country', 'description', 'city'],
  threshold: 0.35,       // 0 = exact match, 1 = match anything
  includeScore: true,
  minMatchCharLength: 2,
};


export type Review = {
  author?: string;
  content?: string;
  date?: string;
  ratings?: Record<string, CBLValue>;
}

// Define document types for collections
// tag::database-schema[]
type Geo = {
  lat: number;
  lon: number;
  accuracy: string;
}

export type Hotel = {
  type: 'hotel';
  title?: string;
  name: string;
  address?: string;
  directions?: string;
  phone?: string;
  tollfree?: string;
  email?: string;
  fax?: string;
  url?: string;
  checkin?: string;
  checkout?: string;
  price?: string;
  geo?: Geo;
  id: number;
  country?: string;
  city?: string;
  state?: string;
  reviews: Review[];
  public_likes: string[];
  vacancy: boolean;
  description?: string;
  alias?: string;
  pets_ok: boolean;
  free_breakfast: boolean;
  free_internet: boolean;
  free_parking: boolean;
}

export type HotelWithId = Hotel & { docId: string };


class HotelRepository {
  database: Database<AppSchema>;
  collection: Collection<Hotel>;

  constructor(database: Database<AppSchema>, collection: Collection<Hotel>) {
    this.database = database;
    this.collection = collection;
  }

  /**
   * Return all hotels ordered by name ascending.
   */
  async getAllHotels(): Promise<HotelWithId[]> {
    const query = this.database.createQuery(
      `SELECT *, META().id AS docId
       FROM \`${COLLECTION_NAME}\` AS hotel
       ORDER BY hotel.name ASC`
    );
    const results = await query.execute();
    return results.map(row => {
      const h = (row.hotel as Record<string, unknown>) || row;
      return {
        ...h,
        docId: String(row.docId || h.docId || h.id)
      } as HotelWithId;
    });
  }



  /**
   * Search hotels by name / country / city using Fuse.js fuzzy search.
   * Full-Text Search via MATCH() is not available in CBL JS SDK.
   *
   * @param term - Search term
   * @param hotels - Pre-fetched hotel list to search within
   * @returns Matching hotels sorted by relevance score
   */
  searchHotels(term: string, hotels: HotelWithId[]): HotelWithId[] {
    if (!term || term.trim().length < 2) return hotels;
    const fuse = new Fuse(hotels, FUSE_OPTIONS);
    return fuse.search(term).map((result) => result.item);
  }
}



export default HotelRepository;
