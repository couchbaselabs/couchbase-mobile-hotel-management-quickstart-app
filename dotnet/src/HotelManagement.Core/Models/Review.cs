using System.Text.Json.Serialization;

namespace HotelManagement.Core.Models;

public sealed class Review
{
    [JsonPropertyName("content")]
    public string Content { get; set; } = "";

    [JsonPropertyName("ratings")]
    public Dictionary<string, double> Ratings { get; set; } = new();

    [JsonPropertyName("author")]
    public string Author { get; set; } = "";

    [JsonPropertyName("date")]
    public string Date { get; set; } = "";
}
