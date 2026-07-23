using System.Text.Json.Serialization;

namespace HotelManagement.Core.Models;

/// <summary>
/// Mirrors the full travel-sample "hotel" document shape (matches the iOS quickstart's schema),
/// so the .NET port has feature parity with the richest of the three native examples.
/// </summary>
public sealed class Hotel
{
    /// <summary>Couchbase Lite's own document id (META().id). Not part of the JSON body.</summary>
    [JsonIgnore]
    public string? DocumentId { get; set; }

    [JsonPropertyName("type")]
    public string Type { get; set; } = "hotel";

    /// <summary>App-level numeric identifier carried over from the original travel-sample data,
    /// kept for schema parity. All lookups in this app use <see cref="DocumentId"/>, not this field.</summary>
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("title")]
    public string Title { get; set; } = "";

    [JsonPropertyName("name")]
    public string Name { get; set; } = "";

    [JsonPropertyName("address")]
    public string Address { get; set; } = "";

    [JsonPropertyName("directions")]
    public string Directions { get; set; } = "";

    [JsonPropertyName("phone")]
    public string Phone { get; set; } = "";

    [JsonPropertyName("tollfree")]
    public string Tollfree { get; set; } = "";

    [JsonPropertyName("email")]
    public string Email { get; set; } = "";

    [JsonPropertyName("fax")]
    public string Fax { get; set; } = "";

    [JsonPropertyName("url")]
    public string Url { get; set; } = "";

    [JsonPropertyName("checkin")]
    public string Checkin { get; set; } = "";

    [JsonPropertyName("checkout")]
    public string Checkout { get; set; } = "";

    [JsonPropertyName("price")]
    public string Price { get; set; } = "";

    [JsonPropertyName("geo")]
    public Geo Geo { get; set; } = new();

    [JsonPropertyName("country")]
    public string Country { get; set; } = "";

    [JsonPropertyName("city")]
    public string City { get; set; } = "";

    [JsonPropertyName("state")]
    public string State { get; set; } = "";

    [JsonPropertyName("reviews")]
    public List<Review> Reviews { get; set; } = new();

    [JsonPropertyName("public_likes")]
    public List<string> PublicLikes { get; set; } = new();

    [JsonPropertyName("vacancy")]
    public bool Vacancy { get; set; }

    [JsonPropertyName("description")]
    public string Description { get; set; } = "";

    [JsonPropertyName("alias")]
    public string Alias { get; set; } = "";

    [JsonPropertyName("pets_ok")]
    public bool PetsOk { get; set; }

    [JsonPropertyName("free_breakfast")]
    public bool FreeBreakfast { get; set; }

    [JsonPropertyName("free_internet")]
    public bool FreeInternet { get; set; }

    [JsonPropertyName("free_parking")]
    public bool FreeParking { get; set; }

    public Hotel Clone()
    {
        var clone = (Hotel)MemberwiseClone();
        clone.Geo = new Geo { Lat = Geo.Lat, Lon = Geo.Lon, Accuracy = Geo.Accuracy };
        clone.Reviews = Reviews.Select(r => new Review
        {
            Content = r.Content,
            Ratings = new Dictionary<string, double>(r.Ratings),
            Author = r.Author,
            Date = r.Date
        }).ToList();
        clone.PublicLikes = new List<string>(PublicLikes);
        return clone;
    }

    /// <summary>Structural equality over every editable field, used to detect unsaved changes in the form screen.</summary>
    public bool HasSameContentAs(Hotel other)
    {
        if (other is null) return false;
        return Title == other.Title
            && Name == other.Name
            && Address == other.Address
            && Directions == other.Directions
            && Phone == other.Phone
            && Tollfree == other.Tollfree
            && Email == other.Email
            && Fax == other.Fax
            && Url == other.Url
            && Checkin == other.Checkin
            && Checkout == other.Checkout
            && Price == other.Price
            && Geo.Lat == other.Geo.Lat
            && Geo.Lon == other.Geo.Lon
            && Geo.Accuracy == other.Geo.Accuracy
            && Country == other.Country
            && City == other.City
            && State == other.State
            && Vacancy == other.Vacancy
            && Description == other.Description
            && Alias == other.Alias
            && PetsOk == other.PetsOk
            && FreeBreakfast == other.FreeBreakfast
            && FreeInternet == other.FreeInternet
            && FreeParking == other.FreeParking;
    }
}
