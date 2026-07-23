namespace HotelManagement.Core.ErrorHandling;

public sealed class ErrorModel
{
    public ErrorModel(string title, string message, bool closable = true)
    {
        Title = title;
        Message = message;
        Closable = closable;
    }

    public string Title { get; }
    public string Message { get; }
    public bool Closable { get; }
}
