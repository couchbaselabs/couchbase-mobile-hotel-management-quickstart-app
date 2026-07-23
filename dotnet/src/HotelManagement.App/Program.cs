using HotelManagement.App.Screens;
using HotelManagement.Core.Configuration;
using HotelManagement.Core.Data;
using HotelManagement.Core.ErrorHandling;
using HotelManagement.Core.Models;

var configPath = Path.Combine(AppContext.BaseDirectory, "config.json");

var errorManager = new ErrorManager();
errorManager.ErrorRaised += error =>
{
    Console.WriteLine();
    Console.WriteLine($"[{error.Title}] {error.Message}");
};

var configuration = new ConfigurationManager().LoadConfiguration(configPath);
if (!configuration.HasSyncCredentials)
{
    Console.WriteLine("No Capella sync credentials configured - running fully offline. See config.json / README.md.");
}

using IDatabaseManaging db = new DatabaseManager(errorManager, configuration);

var hotels = new List<Hotel>();
var replicatorStatus = "Stopped";
var descending = false;
var searchText = "";

using var updateGate = new ManualResetEventSlim(false);

db.HotelsChanged += updated =>
{
    hotels.Clear();
    hotels.AddRange(updated);
    updateGate.Set();
};
db.ReplicatorStatusChanged += status => replicatorStatus = status;

// The live query reports results asynchronously, so every mutation/re-query below is
// followed by a wait on this gate - otherwise the very next render could show stale data
// from just before the change (e.g. a just-added hotel briefly missing from the list).
RunAndWaitForUpdate(db.Initialize);

var running = true;
while (running)
{
    HotelListScreen.Render(hotels, replicatorStatus, descending, searchText);
    Console.WriteLine();
    Console.WriteLine("Enter a hotel number to view/edit/delete, or a command:");
    Console.WriteLine("  [n] New hotel   [f] Search   [c] Clear search   [o] Toggle sort   [q] Quit");
    Console.Write("> ");
    var input = (Console.ReadLine() ?? "").Trim();

    switch (input.ToLowerInvariant())
    {
        case "q":
            running = false;
            break;

        case "n":
            var newHotel = HotelFormScreen.Prompt(existing: null);
            RunAndWaitForUpdate(() => db.AddHotel(newHotel));
            break;

        case "f":
            Console.Write("Search text: ");
            searchText = (Console.ReadLine() ?? "").Trim();
            RunAndWaitForUpdate(() => db.QueryHotels(descending, searchText));
            break;

        case "c":
            searchText = "";
            RunAndWaitForUpdate(() => db.QueryHotels(descending, searchText));
            break;

        case "o":
            descending = !descending;
            RunAndWaitForUpdate(() => db.QueryHotels(descending, searchText));
            break;

        default:
            if (int.TryParse(input, out var index) && index >= 1 && index <= hotels.Count)
            {
                HandleHotelSelected(hotels[index - 1]);
            }
            else if (input.Length > 0)
            {
                Console.WriteLine("Unrecognized input.");
            }
            break;
    }
}

void HandleHotelSelected(Hotel hotel)
{
    while (true)
    {
        HotelDetailsScreen.Render(hotel);
        Console.WriteLine();
        Console.WriteLine("  [e] Edit   [d] Delete   [b] Back");
        Console.Write("> ");
        var choice = (Console.ReadLine() ?? "").Trim().ToLowerInvariant();

        if (choice == "e")
        {
            var edited = HotelFormScreen.Prompt(hotel);
            edited.DocumentId = hotel.DocumentId;
            RunAndWaitForUpdate(() => db.UpdateHotel(edited));
            return;
        }

        if (choice == "d")
        {
            Console.Write("Are you sure you want to delete this hotel? [y/n]: ");
            var confirm = (Console.ReadLine() ?? "").Trim().ToLowerInvariant();
            if (confirm == "y" || confirm == "yes")
            {
                RunAndWaitForUpdate(() => db.DeleteHotel(hotel));
            }
            return;
        }

        if (choice == "b")
        {
            return;
        }
    }
}

void RunAndWaitForUpdate(Action action, int timeoutMs = 2000)
{
    updateGate.Reset();
    action();
    updateGate.Wait(timeoutMs);
}
