using HotelManagement.Core.Models;

namespace HotelManagement.App.Screens;

internal static class HotelListScreen
{
    public static void Render(IReadOnlyList<Hotel> hotels, string replicatorStatus, bool descending, string searchText)
    {
        Console.WriteLine();
        Console.WriteLine("=====================================================");
        Console.WriteLine($" Hotels        Sync: {replicatorStatus}");
        Console.WriteLine($" Sort: name {(descending ? "DESC" : "ASC")}" +
                           (string.IsNullOrWhiteSpace(searchText) ? "" : $"   Search: \"{searchText}\""));
        Console.WriteLine("=====================================================");

        if (hotels.Count == 0)
        {
            Console.WriteLine(" No hotels found.");
            return;
        }

        for (var i = 0; i < hotels.Count; i++)
        {
            var hotel = hotels[i];
            var displayName = string.IsNullOrWhiteSpace(hotel.Name) ? hotel.Title : hotel.Name;
            var location = string.Join(", ", new[] { hotel.Address, hotel.City, hotel.Country }
                .Where(s => !string.IsNullOrWhiteSpace(s)));

            Console.WriteLine($" {i + 1,3}. {displayName}");
            if (!string.IsNullOrWhiteSpace(location))
            {
                Console.WriteLine($"      {location}");
            }
            if (!string.IsNullOrWhiteSpace(hotel.Phone))
            {
                Console.WriteLine($"      {hotel.Phone}");
            }
        }
    }
}
