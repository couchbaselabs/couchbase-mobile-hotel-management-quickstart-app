namespace HotelManagement.Core.ErrorHandling;

/// <summary>
/// FIFO error queue, equivalent to the ErrorManager singleton in the Android/Flutter/iOS ports.
/// Not static so it can be instantiated per-DatabaseManager in tests without cross-test bleed.
/// </summary>
public sealed class ErrorManager
{
    private readonly Queue<ErrorModel> _errors = new();

    public event Action<ErrorModel>? ErrorRaised;

    public IReadOnlyCollection<ErrorModel> Errors => _errors.ToArray();

    public void ShowError(ErrorModel error)
    {
        _errors.Enqueue(error);
        ErrorRaised?.Invoke(error);
    }

    public ErrorModel? DismissAndShowNext()
    {
        if (_errors.Count > 0)
        {
            _errors.Dequeue();
        }

        return _errors.Count > 0 ? _errors.Peek() : null;
    }
}
