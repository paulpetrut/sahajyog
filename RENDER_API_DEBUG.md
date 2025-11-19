# Render.com API Connectivity Debug Guide

This guide helps debug the external API connectivity issues on Render.com deployment.

## Quick Diagnosis

### Step 1: Run the connectivity test script

Add this to your Render.com build command or run it manually:

```bash
./test_render_connectivity.sh
```

### Step 2: Run the Elixir connectivity test

```bash
mix test_api_connectivity
```

### Step 3: Check logs in Render.com dashboard

Look for these error patterns in your logs:

- `DNS resolution failed`
- `Connection refused`
- `Transport error`
- `Request timeout`

## Common Issues and Solutions

### Issue 1: DNS Resolution Problems

**Symptoms:**

- `nxdomain` errors
- `DNS resolution failed` in logs

**Solutions:**

1. Add DNS fallback in your runtime.exs:

```elixir
# In config/runtime.exs
if config_env() == :prod do
  # Add DNS configuration
  config :kernel,
    inet_dist_use_interface: {0, 0, 0, 0}
end
```

2. Try using IP address directly (temporary test):

```elixir
# In lib/sahajyog/external_api.ex, temporarily change:
@base_url "https://104.21.35.112/api"  # learnsahajayoga.org IP
```

### Issue 2: SSL/TLS Certificate Issues

**Symptoms:**

- SSL verification errors
- Certificate validation failures

**Solutions:**

1. Add environment variable in Render.com:

```
DISABLE_SSL_VERIFY=true
```

2. Update the API client to handle SSL issues:

```elixir
# Add to lib/sahajyog/external_api.ex
defp ssl_options do
  case System.get_env("DISABLE_SSL_VERIFY") do
    "true" ->
      [verify: :verify_none]
    _ ->
      []
  end
end
```

### Issue 3: Firewall/Network Restrictions

**Symptoms:**

- Connection refused errors
- Timeouts on specific domains

**Solutions:**

1. Contact Render.com support to whitelist the domain
2. Use a proxy service if needed
3. Implement caching to reduce API calls

### Issue 4: Timeout Issues

**Symptoms:**

- Request timeout errors
- Slow response times

**Solutions:**

1. Increase timeouts in production:

```elixir
# In lib/sahajyog/external_api.ex
@default_timeout 30_000  # 30 seconds
@default_receive_timeout 45_000  # 45 seconds
```

2. Add environment-specific timeouts:

```elixir
defp get_timeout do
  case System.get_env("MIX_ENV") do
    "prod" -> 30_000
    _ -> 10_000
  end
end
```

## Environment Variables for Render.com

Add these environment variables in your Render.com dashboard:

```
# Optional: Disable SSL verification if needed
DISABLE_SSL_VERIFY=false

# Optional: Custom API timeout
API_TIMEOUT=30000

# Optional: Enable debug logging
LOG_LEVEL=debug
```

## Testing Commands

### Test from Render.com shell:

1. Access your Render.com shell
2. Run these commands:

```bash
# Test basic connectivity
curl -I https://learnsahajayoga.org/

# Test API endpoint
curl -s "https://learnsahajayoga.org/api/talks?lang=en" | head -c 200

# Test DNS resolution
nslookup learnsahajayoga.org

# Test with different DNS servers
nslookup learnsahajayoga.org 8.8.8.8
```

### Test from Elixir console:

```elixir
# Start IEx in production
iex -S mix

# Test the API client
Sahajyog.ExternalApi.fetch_talks(%{})

# Test raw HTTP request
Req.get("https://learnsahajayoga.org/api/talks?lang=en")
```

## Fallback Solutions

### Solution 1: Implement Caching

```elixir
# Add to your application
defmodule Sahajyog.TalksCache do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_talks(filters) do
    case GenServer.call(__MODULE__, {:get_talks, filters}) do
      nil ->
        case Sahajyog.ExternalApi.fetch_talks(filters) do
          {:ok, talks, total} ->
            GenServer.cast(__MODULE__, {:cache_talks, filters, talks, total})
            {:ok, talks, total}
          error -> error
        end
      cached -> cached
    end
  end

  # ... implement GenServer callbacks
end
```

### Solution 2: Use Alternative HTTP Client

If Req continues to have issues, fallback to HTTPoison:

```elixir
# Add to mix.exs
{:httpoison, "~> 2.0"}

# Alternative implementation
defp make_request_httpoison(url) do
  case HTTPoison.get(url, [], timeout: 30_000, recv_timeout: 45_000) do
    {:ok, %{status_code: 200, body: body}} ->
      {:ok, Jason.decode!(body)}
    {:ok, %{status_code: status}} ->
      {:error, "HTTP #{status}"}
    {:error, %{reason: reason}} ->
      {:error, "Request failed: #{reason}"}
  end
end
```

## Monitoring and Alerts

Add logging to track API health:

```elixir
defmodule Sahajyog.ApiHealthCheck do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_health_check()
    {:ok, state}
  end

  def handle_info(:health_check, state) do
    case Sahajyog.ExternalApi.fetch_talks(%{}) do
      {:ok, _, _} ->
        Logger.info("API health check: OK")
      {:error, reason} ->
        Logger.error("API health check failed: #{reason}")
    end

    schedule_health_check()
    {:noreply, state}
  end

  defp schedule_health_check do
    Process.send_after(self(), :health_check, 5 * 60 * 1000) # 5 minutes
  end
end
```

## Contact Support

If none of these solutions work:

1. Contact Render.com support with:

   - Your app name
   - The external domain you're trying to reach
   - Error logs from the connectivity tests

2. Consider using a different deployment platform temporarily

3. Implement a webhook or proxy solution where the external API pushes data to your app instead
