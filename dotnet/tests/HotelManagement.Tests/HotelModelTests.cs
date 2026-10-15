using System.Text.Json;
using HotelManagement.Core.Models;
using Xunit;

namespace HotelManagement.Tests;

public class HotelModelTests
{
    private static Hotel MakeSampleHotel() => new()
    {
        Id = 42,
        Title = "Test Hotel Title",
        Name = "Test Hotel",
        Address = "123 Main St",
        Directions = "Turn left",
        Phone = "555-1234",
        Tollfree = "800-555-1234",
        Email = "info@testhotel.example",
        Fax = "555-4321",
        Url = "https://testhotel.example",
        Checkin = "3:00 PM",
        Checkout = "11:00 AM",
        Price = "$100",
        Geo = new Geo { Lat = 12.34, Lon = 56.78, Accuracy = "ROOFTOP" },
        Country = "United States",
        City = "Springfield",
        State = "IL",
        Reviews = new List<Review>
        {
            new() { Content = "Great stay", Author = "A. Guest", Date = "2024-01-01", Ratings = new() { ["Overall"] = 5 } }
        },
        PublicLikes = new List<string> { "Jane D.", "John S." },
        Vacancy = true,
        Description = "A nice hotel",
        Alias = "TH",
        PetsOk = true,
        FreeBreakfast = false,
        FreeInternet = true,
        FreeParking = false
    };

    [Fact]
    public void Serialize_UsesTravelSampleJsonFieldNames()
    {
        var json = JsonSerializer.Serialize(MakeSampleHotel());

        Assert.Contains("\"public_likes\"", json);
        Assert.Contains("\"pets_ok\"", json);
        Assert.Contains("\"free_breakfast\"", json);
        Assert.Contains("\"free_internet\"", json);
        Assert.Contains("\"free_parking\"", json);
        Assert.Contains("\"type\":\"hotel\"", json);
    }

    [Fact]
    public void RoundTrip_SerializeThenDeserialize_PreservesAllFields()
    {
        var original = MakeSampleHotel();

        var json = JsonSerializer.Serialize(original);
        var roundTripped = JsonSerializer.Deserialize<Hotel>(json)!;

        Assert.True(original.HasSameContentAs(roundTripped));
        Assert.Equal(original.Id, roundTripped.Id);
        Assert.Equal(original.Reviews.Single().Content, roundTripped.Reviews.Single().Content);
        Assert.Equal(original.PublicLikes, roundTripped.PublicLikes);
    }

    [Fact]
    public void Clone_ProducesDeepCopy_NotSharedReferences()
    {
        var original = MakeSampleHotel();
        var clone = original.Clone();

        clone.PublicLikes.Add("New Fan");
        clone.Geo.Lat = 0;

        Assert.Equal(2, original.PublicLikes.Count);
        Assert.Equal(12.34, original.Geo.Lat);
    }

    [Fact]
    public void HasSameContentAs_DetectsFieldChange()
    {
        var original = MakeSampleHotel();
        var clone = original.Clone();

        Assert.True(original.HasSameContentAs(clone));

        clone.Name = "A Different Name";

        Assert.False(original.HasSameContentAs(clone));
    }
}
