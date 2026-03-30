# Hotel Management Quick Start App using Couchbase Lite JavaScript SDK + React + Capella App Services

> **Note:** Please refer to the [global README.md](../README.md) for the Introduction and Capella Setup instructions before proceeding.

## App Overview

This web sample app demonstrates how to build a simple offline-first application using React, Couchbase Lite for JavaScript, and Capella App Services — the fully managed version of Sync Gateway and Couchbase Server. The app presents a basic hotel listing interface powered by data from the `travel-sample` dataset, which is hosted in Couchbase Capella and synced locally to the browser using IndexedDB.

The project serves as a quickstart for developers building web apps (including Progressive Web Apps) that require embedded database functionality with support for local reads/writes, flexible querying, and real-time synchronization with the cloud.

It covers the essentials of:

- Basics of App Services and configuring it for remote sync
- Couchbase Lite JavaScript database setup using IndexedDB (browser-native storage)
- Performing basic create, read, update, and delete (CRUD) operations
- Hotel name/city/country search using **Fuse.js** (client-side fuzzy search)
- Syncing documents from a remote Capella cluster using App Services
- Connecting a React interface to local database content via live query listeners

> **Note on Full-Text Search (FTS):** The Couchbase Lite JavaScript SDK does **not** currently support the `MATCH()` FTS operator (see [limitations](https://docs.couchbase.com/couchbase-lite-javascript/current/query-n1ql-mobile.html#missing-features)). This app uses [**Fuse.js**](https://www.fusejs.io/) as a client-side fuzzy search alternative, providing an equivalent user experience.

This sample is an ideal example of how developers can build web apps that must remain usable without a network connection and synchronize data reliably once connectivity is restored.

## Setup and Technology Stack

- Capella / Capella App Services
- Couchbase Lite JavaScript SDK (`@couchbase/lite-js`)
- React 19 + Vite
- Fuse.js (client-side fuzzy search / FTS equivalent)
- MVC architecture: `DatabaseManager` + `HotelRepository` (Model), React components (View), `App.jsx` (Controller)

## Features

- Offline-first data access with Couchbase Lite (IndexedDB)
- React interface listing hotels from Capella
- Secure data sync using App Services (BasicAuth)
- Syncs with hotel collection from `travel-sample` dataset
- Hotel search by name, city, country using Fuse.js
- CRUD: add, edit, delete hotel documents
- Live collection change listener updates the UI automatically
- Unit tests with Vitest + Testing Library (mocked CBL JS SDK)

## Project Requirements

- Node.js: 18 or newer
- npm: 9 or newer
- Browser: Chrome, Firefox, Edge, or Safari (IndexedDB required)
- Database: Couchbase Lite JavaScript SDK (`@couchbase/lite-js` 1.0.0)
- UI Framework: React 19
- Build Tool: Vite 8
- Test Framework: Vitest 4

## Installation Instructions

### Clone this repository

Use the terminal to clone the GitHub repository:

```bash
git clone https://github.com/couchbase-examples/hotel-management-quickstart-app.git
```

### Open the project

Navigate to the `web` subfolder:

```bash
cd Hotel_Management_Quickstart_App/web
```

### Install dependencies

```bash
npm install
```

### Configure the app

Inside the `public/` folder, locate the config file:

```
public/config.json
```

Open the file and provide the following configuration values:

```json
{
  "capellaEndpointUrl": "wss://your-endpoint.apps.cloud.couchbase.com/hotels",
  "username": "your-app-user",
  "password": "your-password"
}
```

- **capellaEndpointUrl** – Paste the "Public URL" from the Connect page of App Services (the endpoint you created in the [global README](../README.md))
- **username** – Enter the App User username
- **password** – Enter the App User password

### ⚠️ Caution

If you do not fill out the configuration file, the app **will not sync** with your Capella cluster or endpoint. The app will still work fully offline with a local database.

### Run the app

```bash
npm run dev
```

Then open [http://localhost:5173](http://localhost:5173) in your browser.

You should see the Hotels Management App load, and the travel-sample hotels list will populate after the initial sync completes.

### ⚠️ Warning

Before running the app, ensure that your browser allows IndexedDB storage (not in private/incognito mode by default on some browsers). The Couchbase Lite JS SDK stores all data in IndexedDB.

### Run unit tests

```bash
npm run test
```

All tests use Vitest with a mocked `@couchbase/lite-js` module and do not require a running Capella backend.

## Try it Out

After running the app successfully, explore the following key features. Each feature is powered by the `DatabaseManager.js` and `HotelRepository.js` classes in `src/model/`.

### Database and Replication Operations

**Description:**
On launch, the app initialises a local Couchbase Lite database in the browser's IndexedDB and sets up continuous replication with Capella App Services. The `hotel` collection from the `inventory` scope is synced from the remote cluster.

```js
// DatabaseManager.js
import { Database, Replicator } from '@couchbase/lite-js';

const config = { name: 'travel-sample', version: 1, collections: { hotel: {} } };
this.database = await Database.open(config);
this.collection = this.database.collection['hotel'];

const replicator = new Replicator({
  database: this.database,
  url: config.capellaEndpointUrl,
  collections: { hotel: { pull: {}, push: {} } },
  credentials: { username: config.username, password: config.password },
  continuous: true,
});
await replicator.start();
```

Learn more:
- [Database Initialization](https://docs.couchbase.com/couchbase-lite-javascript/current/database.html#open-db)
- [Replication](https://docs.couchbase.com/couchbase-lite-javascript/current/replication.html)

### Document CRUD Operations

**Description:**
You can add, update, and delete hotel documents from the local database.

**Add a hotel document:**
```js
const doc = this.collection.createDocument({ type: 'hotel', name: 'The Riviera', country: 'Italy' });
await this.collection.save(doc);
```

**Update a hotel document:**
```js
const doc = await this.collection.getDocument(docId);
Object.assign(doc, updatedFields);
await this.collection.save(doc);
```

**Delete a hotel document:**
```js
const doc = await this.collection.getDocument(docId);
await this.collection.delete(doc);
```

Learn more: [Working with Documents](https://docs.couchbase.com/couchbase-lite-javascript/current/document.html)

### Query & Live Query Updates

**Description:**
The app queries the local database using SQL++ syntax. A collection change listener updates the React state whenever documents change.

```js
const query = this.database.createQuery(
  'SELECT hotel.*, META().id AS _docId FROM `hotel` AS hotel ORDER BY hotel.name ASC'
);
const results = await query.execute();

// Live updates
this.collection.addChangeListener(async () => {
  const hotels = await repo.getAllHotels();
  setHotels(hotels);  // React state update
});
```

Learn more:
- [SQL++ Queries](https://docs.couchbase.com/couchbase-lite-javascript/current/query-n1ql-mobile.html)
- [Live Queries](https://docs.couchbase.com/couchbase-lite-javascript/current/query-live.html)

### Full-Text Search (via Fuse.js)

**Description:**
Since `MATCH()` FTS is not available in the Couchbase Lite JavaScript SDK, the app uses **Fuse.js** for client-side fuzzy search on hotel name, city, and country fields.

```js
import Fuse from 'fuse.js';

const fuse = new Fuse(hotels, {
  keys: ['name', 'country', 'city', 'description'],
  threshold: 0.35,
});
const results = fuse.search('Paris').map((r) => r.item);
```

Learn more: [Fuse.js documentation](https://www.fusejs.io/)

### Offline-First Sync

**Description:**
Even if you disconnect from the network or Capella App Services goes offline, the app continues working with the local database in the browser. Any local changes sync automatically when the connection is restored.

**Try this:**

1. Disable your network or pause the Capella App Endpoint.
2. Add, edit, or delete a hotel in the app.
3. Reconnect to the network and watch the changes sync automatically.
4. Or — try modifying a document in the Capella UI and see it appear in the app.

Learn more: [Offline-First Architecture](https://www.couchbase.com/blog/couchbase-offline-first-app-use-cases/)

## Learn more

- [Couchbase Lite JavaScript SDK](https://docs.couchbase.com/couchbase-lite-javascript/current/index.html)
- [App Services](https://docs.couchbase.com/cloud/app-services/index.html)
- [App Services Access Control — Channels](https://docs.couchbase.com/cloud/app-services/channels/channels.html)
- [App Services Access Control & Data Validation](https://docs.couchbase.com/cloud/app-services/deployment/access-control-data-validation.html)
- [Fuse.js fuzzy search](https://www.fusejs.io/)
