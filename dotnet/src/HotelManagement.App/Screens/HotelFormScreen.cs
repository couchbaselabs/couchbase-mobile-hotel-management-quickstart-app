using HotelManagement.Core.Models;

namespace HotelManagement.App.Screens;

internal static class HotelFormScreen
{
    /// <summary>
    /// Prompts for every editable field. In edit mode, pressing Enter on a text field keeps
    /// the current value (mirrors the mobile ports' "Save" button only being enabled on a
    /// real change - here an unmodified field is simply left untouched instead of re-entered).
    /// </summary>
    public static Hotel Prompt(Hotel? existing)
    {
        var isEdit = existing is not null;
        var hotel = existing?.Clone() ?? new Hotel();

        Console.WriteLine();
        Console.WriteLine(isEdit ? "=== Edit Hotel ===" : "=== New Hotel ===");
        Console.WriteLine("Press Enter to keep the current/default value for any field.");

        Console.WriteLine("-- Basic Info --");
        hotel.Name = PromptText("Name", hotel.Name);
        hotel.Title = PromptText("Title", hotel.Title);
        hotel.Description = PromptText("Description", hotel.Description);
        hotel.Alias = PromptText("Alias", hotel.Alias);
        hotel.Price = PromptText("Price", hotel.Price);

        Console.WriteLine("-- Location --");
        hotel.Address = PromptText("Address", hotel.Address);
        hotel.Directions = PromptText("Directions", hotel.Directions);
        hotel.City = PromptText("City", hotel.City);
        hotel.State = PromptText("State", hotel.State);
        hotel.Country = PromptText("Country", hotel.Country);
        hotel.Geo.Lat = PromptDouble("Latitude", hotel.Geo.Lat);
        hotel.Geo.Lon = PromptDouble("Longitude", hotel.Geo.Lon);
        hotel.Geo.Accuracy = PromptText("Geo accuracy", hotel.Geo.Accuracy);

        Console.WriteLine("-- Contact --");
        hotel.Phone = PromptText("Phone", hotel.Phone);
        hotel.Tollfree = PromptText("Toll-free", hotel.Tollfree);
        hotel.Fax = PromptText("Fax", hotel.Fax);
        hotel.Email = PromptText("Email", hotel.Email);
        hotel.Url = PromptText("Website", hotel.Url);
        hotel.Checkin = PromptText("Check-in", hotel.Checkin);
        hotel.Checkout = PromptText("Check-out", hotel.Checkout);

        Console.WriteLine("-- Amenities --");
        hotel.Vacancy = PromptBool("Vacancy available", hotel.Vacancy);
        hotel.PetsOk = PromptBool("Pets allowed", hotel.PetsOk);
        hotel.FreeBreakfast = PromptBool("Free breakfast", hotel.FreeBreakfast);
        hotel.FreeInternet = PromptBool("Free internet", hotel.FreeInternet);
        hotel.FreeParking = PromptBool("Free parking", hotel.FreeParking);

        Console.WriteLine("-- Public Likes --");
        var likes = PromptText("Public likes (comma-separated)", string.Join(", ", hotel.PublicLikes));
        hotel.PublicLikes = likes.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries).ToList();

        return hotel;
    }

    private static string PromptText(string label, string currentValue)
    {
        Console.Write(string.IsNullOrWhiteSpace(currentValue) ? $"  {label}: " : $"  {label} [{currentValue}]: ");
        var input = Console.ReadLine();
        return string.IsNullOrEmpty(input) ? currentValue : input;
    }

    private static double PromptDouble(string label, double currentValue)
    {
        Console.Write($"  {label} [{currentValue}]: ");
        var input = Console.ReadLine();
        if (string.IsNullOrWhiteSpace(input))
        {
            return currentValue;
        }

        return double.TryParse(input, out var parsed) ? parsed : currentValue;
    }

    private static bool PromptBool(string label, bool currentValue)
    {
        Console.Write($"  {label} [{(currentValue ? "y" : "n")}]: ");
        var input = Console.ReadLine()?.Trim().ToLowerInvariant();
        return input switch
        {
            "y" or "yes" or "true" => true,
            "n" or "no" or "false" => false,
            _ => currentValue
        };
    }
}
