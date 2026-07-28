using System.Text.Json;
using Couchbase.Lite;
using Couchbase.Lite.Query;
using Couchbase.Lite.Sync;
using HotelManagement.Core.Configuration;
using HotelManagement.Core.ErrorHandling;
using HotelManagement.Core.Models;
using Couchbase.Lite.Logging;

namespace HotelManagement.Core.Data;

/// <summary>
/// Couchbase Lite-backed data layer for the Hotel Management quickstart app.
/// Mirrors the architecture shared by the Android and Flutter ports: a single
/// "travel-sample" database, the "inventory" scope, the "hotel" collection, a
/// full-text index on "name", and a continuous push-and-pull replicator to a
/// Capella App Services endpoint (skipped entirely when no credentials are configured,
/// in which case the app still works fully offline against the local database).
/// </summary>
public sealed class DatabaseManager : IDatabaseManaging
{
    public const string DatabaseName = "travel-sample";
    public const string ScopeName = "inventory";
    public const string CollectionName = "hotel";
    public const string FtsIndexName = "nameFtsIndex";

    private readonly ErrorManager _errorManager;
    private readonly ConfigurationModel _configuration;
    private readonly string? _databaseDirectory;


    private Database? _database;
    private Collection? _collection;
    private Replicator? _replicator;
    private ListenerToken? _replicatorListenerToken;
    private ListenerToken? _queryListenerToken;
    private IQuery? _liveQuery;

    public event Action<IReadOnlyList<Hotel>>? HotelsChanged;
    public event Action<string>? ReplicatorStatusChanged;

    public string ReplicatorStatus { get; private set; } = "Stopped";

    public DatabaseManager(ErrorManager errorManager, ConfigurationModel configuration, string? databaseDirectory = null)
    {
        _errorManager = errorManager;
        _configuration = configuration;
        _databaseDirectory = databaseDirectory;
    }

    public void Initialize()
    {
        try
        {
            // Establish a safe local directory for log file storage
            var logDirectory = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "HotelManagement",
                "Logs"
            );

            if (!Directory.Exists(logDirectory))
            {
                Directory.CreateDirectory(logDirectory);
            }
            
            LogSinks.Console = new ConsoleLogSink(LogLevel.None);

            // Direct detailed operational data to a rolling file sink
            LogSinks.File = new FileLogSink(LogLevel.Warning, logDirectory)
            {
                MaxKeptFiles = 3,       // Retains 1 active file + 2 rotated archival copies
                MaxSize = 1024 * 512,   // Rolls over automatically when a log file hits 512 KB
                UsePlaintext = true     // Forces standard readable text instead of binary (.cbllog)
            };
        }
        catch (Exception logEx)
        {
            // Fail-safe to ensure tracking configuration errors don't crash core DB startup
            System.Diagnostics.Debug.WriteLine($"Failed to initialize file logger: {logEx.Message}");
        }

        try
        {
            var dbConfig = new DatabaseConfiguration();
            if (!string.IsNullOrWhiteSpace(_databaseDirectory))
            {
                dbConfig.Directory = _databaseDirectory;
            }

            _database = new Database(DatabaseName, dbConfig);
            _collection = _database.CreateCollection(CollectionName, ScopeName);
            Console.WriteLine($"Database location: {_database.Path}");
        }
        catch (Exception ex)
        {
            _errorManager.ShowError(new ErrorModel("Database Error", ex.Message));
            return;
        }

        try
        {
            var ftsConfig = new FullTextIndexConfiguration(new[] { "name" }, false, "en");
            _collection.CreateIndex(FtsIndexName, ftsConfig);
        }
        catch (Exception)
        {
            // Index already exists on a previously-created database - safe to ignore, matching
            // the same defensive try/catch used by the Android and Flutter ports.
        }

        SetupReplication();
        QueryHotels(descending: false, searchText: "");
    }

    private void SetupReplication()
    {
        if (!_configuration.HasSyncCredentials || _database is null || _collection is null)
        {
            return;
        }

        try
        {
            var target = new URLEndpoint(new Uri(_configuration.CapellaEndpointUrl));
            var replConfig = new ReplicatorConfiguration(target)
            {
                ReplicatorType = ReplicatorType.PushAndPull,
                Continuous = true,
                Authenticator = new BasicAuthenticator(_configuration.Username, _configuration.Password)
            };
            replConfig.AddCollection(_collection);

            _replicator = new Replicator(replConfig);
            _replicatorListenerToken = _replicator.AddChangeListener((_, args) =>
            {
                ReplicatorStatus = args.Status.Activity.ToString();
                ReplicatorStatusChanged?.Invoke(ReplicatorStatus);

                if (args.Status.Error is { } error)
                {
                    _errorManager.ShowError(new ErrorModel("Sync Error", error.Message));
                }
            });
            _replicator.Start();
        }
        catch (Exception ex)
        {
            _errorManager.ShowError(new ErrorModel("Sync Error", ex.Message));
        }
    }

    public void QueryHotels(bool descending, string searchText)
    {
        if (_collection is null)
        {
            return;
        }

        try
        {
            var direction = descending ? "DESC" : "ASC";
            var hasSearch = !string.IsNullOrWhiteSpace(searchText);

            var sql = hasSearch
                ? $"SELECT META().id AS documentId, hotel.* FROM {ScopeName}.{CollectionName} AS hotel " +
                  $"WHERE hotel.type = $type AND MATCH({FtsIndexName}, $match) " +
                  $"ORDER BY RANK({FtsIndexName}) {direction}"
                : $"SELECT META().id AS documentId, hotel.* FROM {ScopeName}.{CollectionName} AS hotel " +
                  "WHERE hotel.type = $type " +
                  $"ORDER BY hotel.name {direction}";

            var query = _collection.CreateQuery(sql);
            var parameters = new Parameters().SetString("type", "hotel");
            if (hasSearch)
            {
                parameters.SetString("match", searchText.Trim() + "*");
            }
            query.Parameters = parameters;

            _queryListenerToken?.Remove();
            _liveQuery?.Dispose();
            _liveQuery = query;
            _queryListenerToken = query.AddChangeListener((_, args) =>
            {
                var hotels = args.Results.Select(MapResultToHotel).ToList();
                HotelsChanged?.Invoke(hotels);
            });
        }
        catch (Exception ex)
        {
            _errorManager.ShowError(new ErrorModel("Query Error", ex.Message));
        }
    }

    private static Hotel MapResultToHotel(Result result)
    {
        // "hotel.*" nests the collection's fields under the "hotel" key in each row rather than
        // flattening them to the top level, so the Hotel model is deserialized from that nested
        // dictionary's JSON, not the row's own JSON.
        var json = result.GetDictionary("hotel")?.ToJSON() ?? "{}";     
        var hotel = JsonSerializer.Deserialize<Hotel>(json) ?? new Hotel();
        hotel.DocumentId = result.GetString("documentId");
        return hotel;
    }

    public void AddHotel(Hotel hotel)
    {
        if (_collection is null)
        {
            return;
        }

        try
        {
            hotel.Type = "hotel";
            using var doc = new MutableDocument();
            doc.SetJSON(JsonSerializer.Serialize(hotel));
            _collection.Save(doc);
            hotel.DocumentId = doc.Id;
        }
        catch (Exception ex)
        {
            _errorManager.ShowError(new ErrorModel("Save Error", ex.Message));
        }
    }

    public void UpdateHotel(Hotel hotel)
    {
        if (_collection is null)
        {
            return;
        }

        if (string.IsNullOrEmpty(hotel.DocumentId))
        {
            AddHotel(hotel);
            return;
        }

        try
        {
            using var existing = _collection.GetDocument(hotel.DocumentId);
            if (existing is null)
            {
                AddHotel(hotel);
                return;
            }

            hotel.Type = "hotel";
            using var mutable = existing.ToMutable();
            mutable.SetJSON(JsonSerializer.Serialize(hotel));
            _collection.Save(mutable);
        }
        catch (Exception ex)
        {
            _errorManager.ShowError(new ErrorModel("Update Error", ex.Message));
        }
    }

    public void DeleteHotel(Hotel hotel)
    {
        if (_collection is null || string.IsNullOrEmpty(hotel.DocumentId))
        {
            return;
        }

        try
        {
            using var existing = _collection.GetDocument(hotel.DocumentId);
            if (existing is not null)
            {
                _collection.Delete(existing);
            }
        }
        catch (Exception ex)
        {
            _errorManager.ShowError(new ErrorModel("Delete Error", ex.Message));
        }
    }

    public void Dispose()
    {
        _queryListenerToken?.Remove();
        _liveQuery?.Dispose();
        _replicatorListenerToken?.Remove();
        _replicator?.Dispose();
        _collection?.Dispose();
        _database?.Close();
        _database?.Dispose();
    }
}
