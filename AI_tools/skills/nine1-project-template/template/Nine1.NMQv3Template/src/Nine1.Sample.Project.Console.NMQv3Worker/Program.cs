using Microsoft.Extensions.Hosting;
#if (!isDatabaseSecretNone)
using Microsoft.Extensions.DependencyInjection;
#endif
using Nine1.NMQ.Extensions.Hosting.Extensions;
using Nine1.Sample.Project.Console.NMQv3Worker.Job;
using System;

namespace Nine1.Sample.Project.Console.NMQv3Worker;

public class Program
{
    /// <summary>
    /// Main
    /// </summary>
    /// <param name="args">arguments</param>
    public static void Main(string[] args)
    {
        try
        {
            var nmqv3Host = CreateNMQv3Host(args);
            using (nmqv3Host)
            {
                nmqv3Host.RunJob();
            }
        }
        catch (Exception ex)
        {
            System.Console.Error.WriteLine("Application start-up failed.");
            System.Console.Error.WriteLine(ex.ToString());
        }
    }

    private static IHost CreateNMQv3Host(string[] args)
    {
        var msaConfigurationModuleNames = new string[] { };
        var hostBuilder = Nine1Host.CreateNmqv3Builder(args)
            .UseNMQv3(
                args,
                msaConfigurationModuleNames,
                (map) =>
                {
                    map.Add("Heartbeat", typeof(HeartbeatJob));
                    map.Add("RepeatMessage", typeof(RepeatMessageJob));
                }
            );

#if (!isDatabaseSecretNone)
        hostBuilder.ConfigureServices((services) =>
        {
#if (isDatabaseSecretPostgresql)
            // 加入 Nine1 Secret Connection String Provider
            services.AddNine1SecretConnectionStringProvider<Npgsql.NpgsqlConnectionStringBuilder>();
#endif
#if (isDatabaseSecretMssql)
            // 加入 Nine1 Secret Connection String Provider
            services.AddNine1SecretConnectionStringProvider<Microsoft.Data.SqlClient.SqlConnectionStringBuilder>();
#endif
        });
#endif

        return hostBuilder.Build();
    }
}