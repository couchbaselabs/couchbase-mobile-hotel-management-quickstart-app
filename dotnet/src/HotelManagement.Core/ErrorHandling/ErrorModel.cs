namespace HotelManagement.Core.ErrorHandling;

public sealed class ErrorModel
{
    public ErrorModel(string title, string message)
    {
        Title = title;
        Message = message;
    }

    public string Title { get; }
    public string Message { get; }
}
