using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Mizan.Infrastructure.Persistence;

public class MizanDbContextFactory : IDesignTimeDbContextFactory<MizanDbContext>
{
    public MizanDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<MizanDbContext>();

        var envConn = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");
        var passedConn = args?.FirstOrDefault(a => !string.IsNullOrWhiteSpace(a) && (a.Contains("Host=", StringComparison.OrdinalIgnoreCase) || a.Contains("Server=", StringComparison.OrdinalIgnoreCase) || a.Contains("postgres", StringComparison.OrdinalIgnoreCase)));
        var connToUse = passedConn ?? envConn;
        var dbProvider = Environment.GetEnvironmentVariable("DB_PROVIDER") ?? Environment.GetEnvironmentVariable("DATABASE_PROVIDER");

        bool usePostgres = string.Equals(dbProvider, "PostgreSQL", StringComparison.OrdinalIgnoreCase) ||
                           string.Equals(dbProvider, "Postgres", StringComparison.OrdinalIgnoreCase) ||
                           (!string.IsNullOrEmpty(connToUse) && (connToUse.Contains("Host=", StringComparison.OrdinalIgnoreCase) || connToUse.Contains("Port=", StringComparison.OrdinalIgnoreCase) || connToUse.Contains("postgres", StringComparison.OrdinalIgnoreCase) || connToUse.Contains("supabase", StringComparison.OrdinalIgnoreCase)));

        if (usePostgres)
        {
            var conn = connToUse ?? "Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres";
            optionsBuilder.UseNpgsql(conn, npgsqlOptions =>
            {
                npgsqlOptions.MigrationsAssembly(typeof(MizanDbContext).Assembly.FullName);
                npgsqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 5,
                    maxRetryDelay: TimeSpan.FromSeconds(30),
                    errorCodesToAdd: null);
            });
        }
        else
        {
            var conn = envConn ?? "Server=localhost;Database=MizanDb;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True";
            optionsBuilder.UseSqlServer(conn, sqlOptions =>
            {
                sqlOptions.MigrationsAssembly(typeof(MizanDbContext).Assembly.FullName);
                sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 5,
                    maxRetryDelay: TimeSpan.FromSeconds(30),
                    errorNumbersToAdd: null);
            });
        }

        return new MizanDbContext(optionsBuilder.Options);
    }
}
