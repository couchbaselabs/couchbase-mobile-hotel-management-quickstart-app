using HotelManagement.Core.Models;

namespace HotelManagement.App.Screens;

internal static class HotelDetailsScreen
{
    public static void Render(Hotel hotel)
    {
        Console.WriteLine();
        Console.WriteLine("=====================================================");
        Console.WriteLine($" {(string.IsNullOrWhiteSpace(hotel.Name) ? hotel.Title : hotel.Name)}");
        Console.WriteLine("=====================================================");

        PrintSection("Info", new[]
        {
            ("Name", hotel.Name),
            ("Title", hotel.Title),
            ("Description", hotel.Description),
            ("Alias", hotel.Alias),
            ("Price", hotel.Price)
        });

        PrintSection("Address", new[]
        {
            ("Address", hotel.Address),
            ("Directions", hotel.Directions),
            ("City", hotel.City),
            ("State", hotel.State),
            ("Country", hotel.Country),
            ("Geo", hotel.Geo.Lat == 0 && hotel.Geo.Lon == 0 ? "" : $"{hotel.Geo.Lat}, {hotel.Geo.Lon} ({hotel.Geo.Accuracy})")
        });

        PrintSection("Contact", new[]
        {
            ("Phone", hotel.Phone),
            ("Toll-free", hotel.Tollfree),
            ("Fax", hotel.Fax),
            ("Email", hotel.Email),
            ("Website", hotel.Url),
            ("Check-in", hotel.Checkin),
            ("Check-out", hotel.Checkout)
        });

        PrintSection("Amenities", new[]
        {
            ("Vacancy", hotel.Vacancy ? "Available" : "Full"),
            ("Pets", hotel.PetsOk ? "Allowed" : "Not allowed"),
            ("Breakfast", hotel.FreeBreakfast ? "Free" : "Not included"),
            ("Internet", hotel.FreeInternet ? "Free" : "Not included"),
            ("Parking", hotel.FreeParking ? "Free" : "Not included")
        });

        if (hotel.PublicLikes.Count > 0)
        {
            Console.WriteLine();
            Console.WriteLine(" Public likes: " + string.Join(", ", hotel.PublicLikes));
        }

        if (hotel.Reviews.Count > 0)
        {
            Console.WriteLine();
            Console.WriteLine(" Reviews:");
            foreach (var review in hotel.Reviews)
            {
                Console.WriteLine($"   - {review.Author} ({review.Date}): {review.Content}");
            }
        }
    }

    private static void PrintSection(string title, (string Label, string Value)[] rows)
    {
        var visible = rows.Where(r => !string.IsNullOrWhiteSpace(r.Value)).ToArray();
        if (visible.Length == 0)
        {
            return;
        }

        Console.WriteLine();
        Console.WriteLine($" {title}");
        foreach (var (label, value) in visible)
        {
            Console.WriteLine($"   {label}: {value}");
        }
    }
}
