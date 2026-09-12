using Mizan.Domain.Entities;

namespace Mizan.Infrastructure.Services;

public interface IJwtTokenService
{
    string GenerateAccessToken(User user);
    string GenerateRefreshToken();
}
