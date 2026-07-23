using System.Text.Json.Serialization;

namespace HotelManagement.Core.Configuration;

/// <summary>
/// Matches the generic config.json shape documented in the repo's top-level README
/// (capellaEndpointUrl / username / password), shared by the Android and Flutter ports.
/// </summary>
public sealed class ConfigurationModel
{
    [JsonPropertyName("capellaEndpointUrl")]
    public string CapellaEndpointUrl { get; set; } = "";

    [JsonPropertyName("username")]
    public string Username { get; set; } = "";

    [JsonPropertyName("password")]
    public string Password { get; set; } = "";

    public bool HasSyncCredentials =>
        !string.IsNullOrWhiteSpace(CapellaEndpointUrl)
        && !string.IsNullOrWhiteSpace(Username)
        && !string.IsNullOrWhiteSpace(Password);
}
