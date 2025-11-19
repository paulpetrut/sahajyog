Mix.install([:req])

url = "https://learnsahajayoga.org/api/talks?lang=en&sort_by=date&sort_order=ASC"
IO.puts("Fetching #{url}...")

case Req.get(url, connect_options: [timeout: 8000], receive_timeout: 12000, retry: :transient) do
  {:ok, %{status: 200, body: body}} ->
    IO.puts("Success!")
    IO.inspect(Map.keys(body))
  {:ok, %{status: status, body: body}} ->
    IO.puts("Failed with status: #{status}")
    IO.inspect(body)
  {:error, reason} ->
    IO.puts("Error: #{inspect(reason)}")
end
