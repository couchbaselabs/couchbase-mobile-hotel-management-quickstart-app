using HotelManagement.Core.Models;

namespace HotelManagement.Core.Data;

/// <summary>
/// Abstraction over the Couchbase Lite-backed data layer, mirroring the
/// DatabaseManaging interfaces in the Android and Flutter ports so the app/UI
/// layer and its tests can be exercised against a fake implementation.
/// </summary>
public interface IDatabaseManaging : IDisposable
{
    /// <summary>Raised whenever the live query result set changes (local edits or incoming sync).</summary>
    event Action<IReadOnlyList<Hotel>>? HotelsChanged;

    /// <summary>Raised whenever the replicator's activity level changes (e.g. Idle, Busy, Offline, Stopped).</summary>
    event Action<string>? ReplicatorStatusChanged;

    string ReplicatorStatus { get; }

    void Initialize();

    /// <summary>(Re)runs the live query with the given sort direction and optional full-text search term.</summary>
    void QueryHotels(bool descending, string searchText);

    void AddHotel(Hotel hotel);

    void UpdateHotel(Hotel hotel);

    void DeleteHotel(Hotel hotel);
}
