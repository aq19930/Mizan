namespace Mizan.Application.Interfaces;

public interface IFirebaseNotificationService
{
    Task<bool> SendPushNotificationAsync(
        string token,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default);

    Task<int> SendMulticastNotificationAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default);
}
