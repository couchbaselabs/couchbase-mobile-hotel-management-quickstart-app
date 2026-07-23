using HotelManagement.Core.Configuration;
using HotelManagement.Core.Data;
using HotelManagement.Core.ErrorHandling;
using HotelManagement.Core.Models;
using Xunit;

namespace HotelManagement.Tests;

/// <summary>
/// Integration tests against a real, local-only Couchbase Lite database (no Capella
/// credentials configured, so replication is never attempted) - equivalent in spirit to
/// the iOS port's DatabaseManagerTests, but driven by the live-query change events instead
/// of a fixed sleep().
/// </summary>
public sealed class DatabaseManagerTests : IDisposable
{
    private readonly string _tempDir;
    private readonly ErrorManager _errorManager = new();
    private readonly DatabaseManager _db;

    public DatabaseManagerTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), "hotel-mgmt-tests-" + Guid.NewGuid());
        Directory.CreateDirectory(_tempDir);

        _db = new DatabaseManager(_errorManager, new ConfigurationModel(), _tempDir);
        _db.Initialize();
    }

    [Fact]
    public void AddHotel_AppearsInLiveQueryResults()
    {
        var hotel = new Hotel { Name = "Add Test " + Guid.NewGuid(), City = "Springfield" };

        var results = WaitForHotels(
            () => _db.AddHotel(hotel),
            list => list.Any(h => h.Name == hotel.Name));

        var found = Assert.Single(results, h => h.Name == hotel.Name);
        Assert.Equal("Springfield", found.City);
        Assert.NotNull(hotel.DocumentId);
        Assert.Empty(_errorManager.Errors);
    }

    [Fact]
    public void UpdateHotel_ChangesReflectedInLiveQueryResults()
    {
        var hotel = new Hotel { Name = "Update Test " + Guid.NewGuid(), City = "Old City" };
        WaitForHotels(() => _db.AddHotel(hotel), list => list.Any(h => h.Name == hotel.Name));

        var edited = hotel.Clone();
        edited.City = "New City";

        var results = WaitForHotels(
            () => _db.UpdateHotel(edited),
            list => list.Any(h => h.Name == hotel.Name && h.City == "New City"));

        var found = Assert.Single(results, h => h.Name == hotel.Name);
        Assert.Equal("New City", found.City);
    }

    [Fact]
    public void DeleteHotel_RemovedFromLiveQueryResults()
    {
        var hotel = new Hotel { Name = "Delete Test " + Guid.NewGuid() };
        WaitForHotels(() => _db.AddHotel(hotel), list => list.Any(h => h.Name == hotel.Name));

        var results = WaitForHotels(
            () => _db.DeleteHotel(hotel),
            list => list.All(h => h.Name != hotel.Name));

        Assert.DoesNotContain(results, h => h.Name == hotel.Name);
    }

    [Fact]
    public void QueryHotels_FullTextSearch_MatchesOnlyNamePrefix()
    {
        var unique = Guid.NewGuid().ToString("N")[..8];
        var match1 = new Hotel { Name = $"Zephyr{unique} Grand" };
        var match2 = new Hotel { Name = $"Zephyr{unique} Suites" };
        var nonMatch = new Hotel { Name = $"Different{unique} Place" };

        WaitForHotels(() => _db.AddHotel(match1), list => list.Any(h => h.Name == match1.Name));
        WaitForHotels(() => _db.AddHotel(match2), list => list.Any(h => h.Name == match2.Name));
        WaitForHotels(() => _db.AddHotel(nonMatch), list => list.Any(h => h.Name == nonMatch.Name));

        var results = WaitForHotels(
            () => _db.QueryHotels(descending: false, searchText: $"Zephyr{unique}"),
            list => list.Count == 2);

        Assert.Contains(results, h => h.Name == match1.Name);
        Assert.Contains(results, h => h.Name == match2.Name);
        Assert.DoesNotContain(results, h => h.Name == nonMatch.Name);
    }

    [Fact]
    public void QueryHotels_SortDescending_OrdersByNameDescending()
    {
        var unique = Guid.NewGuid().ToString("N")[..8];
        var a = new Hotel { Name = $"Alpha{unique}" };
        var z = new Hotel { Name = $"Zulu{unique}" };

        WaitForHotels(() => _db.AddHotel(a), list => list.Any(h => h.Name == a.Name));
        WaitForHotels(() => _db.AddHotel(z), list => list.Any(h => h.Name == z.Name));

        // No search text here on purpose: when searchText is set, QueryHotels orders by FTS
        // RANK (matching the Android/Flutter ports), not by name, so name-sort is only
        // observable on the unfiltered query.
        var results = WaitForHotels(
            () => _db.QueryHotels(descending: true, searchText: ""),
            list => list.Count(h => h.Name.Contains(unique)) >= 2);

        var filtered = results.Where(h => h.Name.Contains(unique)).ToList();
        Assert.Equal(z.Name, filtered.First().Name);
        Assert.Equal(a.Name, filtered.Last().Name);
    }

    /// <summary>
    /// Runs <paramref name="trigger"/> and blocks until a live-query callback whose result
    /// set satisfies <paramref name="predicate"/> arrives, or the timeout elapses.
    /// </summary>
    private List<Hotel> WaitForHotels(Action trigger, Func<List<Hotel>, bool> predicate, int timeoutMs = 10000)
    {
        var tcs = new TaskCompletionSource<List<Hotel>>();

        void Handler(IReadOnlyList<Hotel> hotels)
        {
            var list = hotels.ToList();
            if (predicate(list))
            {
                tcs.TrySetResult(list);
            }
        }

        _db.HotelsChanged += Handler;
        try
        {
            trigger();

            if (!tcs.Task.Wait(timeoutMs))
            {
                throw new TimeoutException("Timed out waiting for the expected live query result.");
            }

            return tcs.Task.Result;
        }
        finally
        {
            _db.HotelsChanged -= Handler;
        }
    }

    public void Dispose()
    {
        _db.Dispose();
        try
        {
            Directory.Delete(_tempDir, recursive: true);
        }
        catch (IOException)
        {
            // Best-effort cleanup; leftover temp folders don't affect subsequent test runs.
        }
    }
}
