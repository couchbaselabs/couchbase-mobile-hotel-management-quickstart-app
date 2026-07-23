# Hotel Management Quick Start App using Couchbase Lite .NET SDK + Capella App Services

> See the [top-level README](../README.md) for how to create your free-tier Capella cluster, App Service, App Endpoint, and App User. Come back here once you have your App Endpoint URL, username, and password.

## App Overview
This is a .NET console application that mirrors the Android, Flutter, and iOS quickstarts: an offline-first hotel management app backed by [Couchbase Lite](https://docs.couchbase.com/couchbase-lite/current/csharp/gs-install.html), syncing the `hotel` collection of the `travel-sample` bucket with a Capella App Services endpoint.

It intentionally uses a text UI instead of a graphical one (no MAUI/WPF) so the full CRUD + sync + full-text-search feature set can be exercised and unit/integration tested from the terminal on Windows, macOS, or Linux without any mobile tooling. All of the interesting logic — the Couchbase Lite data layer, configuration loading, and the hotel model — lives in a plain, cross-platform, fully-tested class library (`HotelManagement.Core`); the console app itself is a thin presentation layer over that library.

### A note on the data model
The Android and Flutter ports use a reduced, flat 10-field `Hotel` schema. The iOS port uses the full `travel-sample` hotel schema (geo-coordinates, reviews, amenities, pricing, check-in/check-out, etc). This .NET port matches the **iOS (full schema)** version, so it has feature parity with the richest of the three native examples. See [`HotelManagement.Core/Models/Hotel.cs`](src/HotelManagement.Core/Models/Hotel.cs) for the full field list.

Unlike the iOS app (which looks up documents by a random numeric `id` field, using non-parameterized SQL string interpolation to do it), this port looks up documents by Couchbase Lite's own document ID (`META().id`), the same approach the Android and Flutter ports use. The numeric `id` field is still present on the model for schema parity with synced `travel-sample` data, but it is never used for lookups.

## Setup and Technology Stack
- [Capella App Services](https://docs.couchbase.com/cloud/index.html) for backend data storage and sync (see the [top-level README](../README.md))
- [Couchbase Lite .NET SDK](https://docs.couchbase.com/couchbase-lite/current/csharp/gs-install.html) (`Couchbase.Lite` NuGet package) for the local database, live queries, full-text search, and replication
- .NET 10 console application (C#), split into a testable class library (`HotelManagement.Core`) and a console front-end (`HotelManagement.App`)
- [xUnit](https://xunit.net/) for unit and integration tests

> **Why not the Couchbase .NET SDK (`CouchbaseNetClient`)?** That SDK connects a server-side application directly to a Capella cluster over the Data/Query/Search services. This app follows the same architecture as the Android, Flutter, and iOS ports: a local-first mobile/embedded app that syncs through App Services via Couchbase Lite's replicator. That's the SDK covered here.

## Features
- Offline-first: fully usable with no network connection or Capella credentials configured
- Continuous, bidirectional (push-and-pull) sync of the `hotel` collection via Couchbase Lite's replicator
- Live queries: the hotel list updates automatically as local edits or incoming synced changes land
- Full-text search on hotel name, sorting by name (ascending/descending)
- Full CRUD: add, view, edit, and delete hotels
- Centralized error handling surfaced to the console (database, sync, query, and save/update/delete errors)
- 13 automated tests: configuration loading, hotel model (de)serialization, and full CRUD/search/sort integration tests against a real local Couchbase Lite database

## Project Requirements
- [.NET SDK 10.0](https://dotnet.microsoft.com/download) or later
- Works on Windows, macOS, and Linux (Couchbase Lite's desktop native library supports all three)
- No IDE required — everything here uses the `dotnet` CLI, though the solution (`HotelManagement.slnx`) opens fine in Visual Studio, VS Code, or Rider

## Installation Instructions

1. Clone the repo:
   ```
   git clone git@github.com:couchbaselabs/couchbase-mobile-hotel-management-quickstart-app.git
   cd couchbase-mobile-hotel-management-quickstart-app/dotnet
   ```

2. Restore and build:
   ```
   dotnet build
   ```

3. **Configure the app.** Edit [`src/HotelManagement.App/config.json`](src/HotelManagement.App/config.json):
   ```json
   {
     "capellaEndpointUrl": "wss://your-endpoint.apps.cloud.couchbase.com/hotels",
     "username": "your-app-user",
     "password": "your-password"
   }
   ```
   - `capellaEndpointUrl` is the Public Connection string from your App Endpoint's **Connect** tab.
   - `username` / `password` are the App User credentials you created for the `hotel` channel.

   > **Caution:** if you leave these fields blank, the app runs — fully functional — against a local-only database with no sync. This is the same fallback behavior as the Android and Flutter ports.

4. **Run the app:**
   ```
   dotnet run --project src/HotelManagement.App
   ```
   You'll see a text menu. As hotels sync down from Capella (or as you add your own), they'll appear in the numbered list.

5. **Run the tests:**
   ```
   dotnet test
   ```
   This runs all 13 tests (configuration loading, hotel model serialization, and CRUD/search/sort integration tests against a real, temporary, local-only Couchbase Lite database — no Capella credentials needed for the test suite to pass).

## Try it Out

### The main menu
```
=====================================================
 Hotels        Sync: Idle
 Sort: name ASC
=====================================================
   1. Old Faithful Inn
      Yellowstone National Park, USA
      307-344-7311
   2. The Plaza
      768 5th Ave, New York, USA
      212-759-3000

Enter a hotel number to view/edit/delete, or a command:
  [n] New hotel   [f] Search   [c] Clear search   [o] Toggle sort   [q] Quit
>
```
- Enter a hotel's number to view its details, edit it, or delete it.
- `n` adds a new hotel (prompts for every field; press Enter to accept the default).
- `f` runs a full-text search on hotel name; `c` clears it.
- `o` toggles ascending/descending sort by name.

### Database & replication setup ([`DatabaseManager.cs`](src/HotelManagement.Core/Data/DatabaseManager.cs))
```csharp
_database = new Database(DatabaseName, dbConfig);
_collection = _database.CreateCollection(CollectionName, ScopeName);

var ftsConfig = new FullTextIndexConfiguration(new[] { "name" }, false, "en");
_collection.CreateIndex(FtsIndexName, ftsConfig);

var target = new URLEndpoint(new Uri(_configuration.CapellaEndpointUrl));
var replConfig = new ReplicatorConfiguration(target)
{
    ReplicatorType = ReplicatorType.PushAndPull,
    Continuous = true,
    Authenticator = new BasicAuthenticator(_configuration.Username, _configuration.Password)
};
replConfig.AddCollection(_collection);
_replicator = new Replicator(replConfig);
_replicator.Start();
```

### Live query + full-text search
```csharp
var sql = "SELECT META().id AS documentId, hotel.* FROM inventory.hotel AS hotel " +
          "WHERE hotel.type = $type AND MATCH(nameFtsIndex, $match) " +
          "ORDER BY RANK(nameFtsIndex) ASC";

var query = _collection.CreateQuery(sql);
query.Parameters = new Parameters().SetString("type", "hotel").SetString("match", searchText + "*");
query.AddChangeListener((_, args) => HotelsChanged?.Invoke(args.Results.Select(MapResultToHotel).ToList()));
```

### Offline-first sync
1. Run the app with valid Capella credentials in `config.json` and let it sync.
2. Disconnect your network, add or edit a hotel — the change saves locally immediately, and the header shows `Sync: Offline`.
3. Reconnect — the replicator automatically resumes and pushes your change to Capella.
4. Edit the same `hotel` collection from another synced client (or the Capella UI) and watch it appear here without restarting the app, thanks to the live query.

## Learn more
- [Couchbase Lite .NET SDK documentation](https://docs.couchbase.com/couchbase-lite/current/csharp/gs-install.html)
- [Database & Collections](https://docs.couchbase.com/couchbase-lite/current/csharp/database.html)
- [Replication](https://docs.couchbase.com/couchbase-lite/current/csharp/replication.html)
- [Querying (SQL++/N1QL)](https://docs.couchbase.com/couchbase-lite/current/csharp/query-n1ql-mobile.html)
- [Full-Text Search](https://docs.couchbase.com/couchbase-lite/current/csharp/fts.html)
- [App Services channels](https://docs.couchbase.com/cloud/app-services/channels/channels.html)
- [App Services access control and data validation](https://docs.couchbase.com/cloud/app-services/deployment/access-control-data-validation.html)
