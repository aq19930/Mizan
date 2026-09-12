namespace Mizan.Contracts.Auth;

public record RegisterRequest(
    string FullName,
    string Email,
    string Password,
    string PreferredLanguage = "ar",
    string PreferredCurrency = "SAR"
);

public record LoginRequest(
    string Email,
    string Password
);

public record AuthResponse(
    string AccessToken,
    string RefreshToken,
    int ExpiresIn,
    Guid UserId,
    string Email,
    string FullName
);

public record RefreshTokenRequest(
    string RefreshToken
);

public record ForgotPasswordRequest(
    string Email
);

public record UpdateProfileRequest(
    string FullName,
    string PreferredLanguage,
    string PreferredCurrency
);

public record UserProfileResponse(
    Guid Id,
    string Email,
    string FullName,
    string PreferredLanguage,
    string PreferredCurrency,
    DateTime CreatedAt
);
