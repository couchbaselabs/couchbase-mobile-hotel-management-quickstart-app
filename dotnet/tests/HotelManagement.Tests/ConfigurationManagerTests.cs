using HotelManagement.Core.Configuration;
using Xunit;

namespace HotelManagement.Tests;

public class ConfigurationManagerTests
{
    [Fact]
    public void LoadConfiguration_ValidFile_ReturnsPopulatedModel()
    {
        var path = WriteTempConfig("""
        {
          "capellaEndpointUrl": "wss://example.apps.cloud.couchbase.com/hotels",
          "username": "demo-user",
          "password": "demo-pass"
        }
        """);

        var config = new ConfigurationManager().LoadConfiguration(path);

        Assert.Equal("wss://example.apps.cloud.couchbase.com/hotels", config.CapellaEndpointUrl);
        Assert.Equal("demo-user", config.Username);
        Assert.Equal("demo-pass", config.Password);
        Assert.True(config.HasSyncCredentials);
    }

    [Fact]
    public void LoadConfiguration_MissingFile_ReturnsEmptyModelWithoutThrowing()
    {
        var config = new ConfigurationManager()
            .LoadConfiguration(Path.Combine(Path.GetTempPath(), "does-not-exist-" + Guid.NewGuid() + ".json"));

        Assert.Equal("", config.CapellaEndpointUrl);
        Assert.Equal("", config.Username);
        Assert.Equal("", config.Password);
        Assert.False(config.HasSyncCredentials);
    }

    [Fact]
    public void LoadConfiguration_MalformedJson_ReturnsEmptyModelWithoutThrowing()
    {
        var path = WriteTempConfig("{ this is not valid json ");

        var config = new ConfigurationManager().LoadConfiguration(path);

        Assert.False(config.HasSyncCredentials);
    }

    [Fact]
    public void LoadConfiguration_MissingKeys_DefaultsToEmptyStrings()
    {
        var path = WriteTempConfig("""{ "capellaEndpointUrl": "wss://example.com/hotels" }""");

        var config = new ConfigurationManager().LoadConfiguration(path);

        Assert.Equal("wss://example.com/hotels", config.CapellaEndpointUrl);
        Assert.Equal("", config.Username);
        Assert.Equal("", config.Password);
        Assert.False(config.HasSyncCredentials);
    }

    private static string WriteTempConfig(string json)
    {
        var path = Path.Combine(Path.GetTempPath(), "config-test-" + Guid.NewGuid() + ".json");
        File.WriteAllText(path, json);
        return path;
    }
}
