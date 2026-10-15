using System.Text.Json.Serialization;

namespace HotelManagement.Core.Models;

public sealed class Geo
{
    [JsonPropertyName("lat")]
    public double Lat { get; set; }

    [JsonPropertyName("lon")]
    public double Lon { get; set; }

    [JsonPropertyName("accuracy")]
    public string Accuracy { get; set; } = "";
}
