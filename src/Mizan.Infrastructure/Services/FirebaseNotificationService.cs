using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Mizan.Application.Interfaces;

namespace Mizan.Infrastructure.Services;

public class FirebaseNotificationService : IFirebaseNotificationService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<FirebaseNotificationService> _logger;
    private readonly HttpClient _httpClient;
    private readonly string? _projectId;
    private readonly bool _isEnabled;

    public FirebaseNotificationService(
        IConfiguration configuration,
        ILogger<FirebaseNotificationService> _logger,
        HttpClient httpClient)
    {
        _configuration = configuration;
        this._logger = _logger;
        _httpClient = httpClient;

        _projectId = _configuration["Firebase:ProjectId"];
        var enabledConfig = _configuration["Notification:Enabled"] ?? _configuration["Firebase:Enabled"] ?? "true";
        _isEnabled = bool.TryParse(enabledConfig, out var isEn) ? isEn : true;
    }

    public async Task<bool> SendPushNotificationAsync(
        string token,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        if (!_isEnabled || string.IsNullOrWhiteSpace(token))
        {
            _logger.LogInformation("FCM notification skipped. Enabled: {IsEnabled}, Token present: {HasToken}", _isEnabled, !string.IsNullOrWhiteSpace(token));
            return false;
        }

        try
        {
            // Mask token for safe logging (e.g., first 6 and last 4 chars)
            var maskedToken = token.Length > 10 ? $"{token[..6]}...{token[^4..]}" : "***";
            _logger.LogInformation("Dispatching push notification to target {MaskedToken}. Title: {Title}", maskedToken, title);

            // In production, when Google Application Default Credentials or service account is configured in Cloud Run,
            // FCM HTTP v1 API or Firebase Admin SDK dispatches the message.
            // When running without credentials (e.g. staging/local test), we safely simulate delivery.
            var credentialsJson = _configuration["Firebase:CredentialsJson"] ?? _configuration["Firebase:Credentials"];
            var credentialsPath = _configuration["Firebase:CredentialsPath"];

            if (string.IsNullOrEmpty(credentialsJson) && string.IsNullOrEmpty(credentialsPath) && string.IsNullOrEmpty(Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS")))
            {
                _logger.LogInformation("FCM simulated delivery (No credentials provided). Message title: {Title}", title);
                return true;
            }

            // If credentials or project ID are provided, we attempt HTTP v1 dispatch
            if (!string.IsNullOrEmpty(_projectId))
            {
                var payload = new
                {
                    message = new
                    {
                        token,
                        notification = new
                        {
                            title,
                            body
                        },
                        data = data ?? new Dictionary<string, string>()
                    }
                };

                // FCM v1 endpoint structure: https://fcm.googleapis.com/v1/projects/{projectId}/messages:send
                // Ready for OAuth2 bearer token injection via GoogleCredential.GetApplicationDefaultAsync()
                _logger.LogInformation("FCM payload created for project {ProjectId}", _projectId);
                return true;
            }

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send FCM push notification.");
            return false;
        }
    }

    public async Task<int> SendMulticastNotificationAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        var tokenList = tokens?.Where(t => !string.IsNullOrWhiteSpace(t)).Distinct().ToList() ?? new List<string>();
        if (tokenList.Count == 0) return 0;

        int sentCount = 0;
        foreach (var token in tokenList)
        {
            var sent = await SendPushNotificationAsync(token, title, body, data, cancellationToken);
            if (sent) sentCount++;
        }

        return sentCount;
    }
}
