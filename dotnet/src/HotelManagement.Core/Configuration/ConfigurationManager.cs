using System.Text.Json;

namespace HotelManagement.Core.Configuration;

/// <summary>
/// Loads Capella App Services connection details from a config.json file.
/// Mirrors the Android/Flutter behavior: missing keys or a missing file fall back to
/// empty strings rather than throwing, so the app can still run fully offline.
/// </summary>
public sealed class ConfigurationManager
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public ConfigurationModel LoadConfiguration(string configFilePath)
    {
        if (!File.Exists(configFilePath))
        {
            return new ConfigurationModel();
        }

        try
        {
            var json = File.ReadAllText(configFilePath);
            var model = JsonSerializer.Deserialize<ConfigurationModel>(json, JsonOptions);
            return model ?? new ConfigurationModel();
        }
        catch (JsonException)
        {
            return new ConfigurationModel();
        }
    }
}
