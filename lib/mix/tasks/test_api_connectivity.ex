defmodule Mix.Tasks.TestApiConnectivity do
  @moduledoc """
  Test API connectivity to learnsahajayoga.org from the deployment environment.

  Usage: mix test_api_connectivity
  """
  use Mix.Task

  @shortdoc "Test external API connectivity"

  def run(_args) do
    Mix.Task.run("app.start")

    IO.puts("🔍 Testing API connectivity to learnsahajayoga.org...")
    IO.puts("=" |> String.duplicate(60))

    # Test basic connectivity
    test_basic_connectivity()

    # Test DNS resolution
    test_dns_resolution()

    # Test API endpoints
    test_api_endpoints()

    IO.puts("=" |> String.duplicate(60))
    IO.puts("✅ API connectivity test completed")
  end

  defp test_basic_connectivity do
    IO.puts("\n📡 Testing basic connectivity...")

    case :inet.gethostbyname(~c"learnsahajayoga.org") do
      {:ok, {:hostent, _name, _aliases, :inet, 4, addresses}} ->
        IO.puts("✅ DNS resolution successful")
        IO.puts("   IP addresses: #{inspect(addresses)}")

      {:error, reason} ->
        IO.puts("❌ DNS resolution failed: #{inspect(reason)}")
    end
  end

  defp test_dns_resolution do
    IO.puts("\n🔍 Testing DNS resolution with different methods...")

    # Test with :inet.getaddr
    case :inet.getaddr(~c"learnsahajayoga.org", :inet) do
      {:ok, ip} ->
        IO.puts("✅ inet.getaddr successful: #{:inet.ntoa(ip)}")

      {:error, reason} ->
        IO.puts("❌ inet.getaddr failed: #{inspect(reason)}")
    end
  end

  defp test_api_endpoints do
    IO.puts("\n🌐 Testing API endpoints...")

    endpoints = [
      {"Basic talks endpoint", "https://learnsahajayoga.org/api/talks?lang=en"},
      {"Search endpoint", "https://learnsahajayoga.org/api/search?q=test&lang=en"},
      {"Countries metadata", "https://learnsahajayoga.org/api/meta/countries"},
      {"Years metadata", "https://learnsahajayoga.org/api/meta/years"}
    ]

    for {name, url} <- endpoints do
      IO.puts("\n  Testing #{name}...")
      IO.puts("  URL: #{url}")

      start_time = System.monotonic_time(:millisecond)

      result =
        Req.get(url,
          connect_options: [timeout: 10_000],
          receive_timeout: 15_000,
          retry: false,
          redirect: true
        )

      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time

      case result do
        {:ok, %{status: status, body: body}} when status in 200..299 ->
          body_size = if is_binary(body), do: byte_size(body), else: "unknown"
          IO.puts("  ✅ Success (#{status}) - #{duration}ms - #{body_size} bytes")

          # Show first few characters of response
          preview =
            case body do
              binary when is_binary(binary) ->
                binary |> String.slice(0, 100) |> String.replace("\n", " ")

              map when is_map(map) ->
                map |> Jason.encode!() |> String.slice(0, 100)

              other ->
                inspect(other) |> String.slice(0, 100)
            end

          IO.puts("  Preview: #{preview}...")

        {:ok, %{status: status, body: body}} ->
          IO.puts("  ❌ HTTP Error #{status} - #{duration}ms")
          IO.puts("  Body: #{inspect(body)}")

        {:error, %Req.TransportError{reason: reason}} ->
          IO.puts("  ❌ Transport Error - #{duration}ms")
          IO.puts("  Reason: #{inspect(reason)}")

        {:error, reason} ->
          IO.puts("  ❌ Request Error - #{duration}ms")
          IO.puts("  Reason: #{inspect(reason)}")
      end
    end
  end
end
