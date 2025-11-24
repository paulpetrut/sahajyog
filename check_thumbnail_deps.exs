# Script to check thumbnail generation dependencies on Render.com
# Run with: ./bin/sahajyog eval "$(cat check_thumbnail_deps.exs)"

IO.puts("\n=== Checking Thumbnail Generation Dependencies ===\n")

# Check for magick command (ImageMagick 7)
IO.puts("Checking for 'magick' command...")

case System.cmd("which", ["magick"]) do
  {path, 0} ->
    IO.puts("✓ magick found at: #{String.trim(path)}")
    {version, 0} = System.cmd("magick", ["--version"])
    IO.puts("  Version: #{String.split(version, "\n") |> Enum.at(0)}")

  _ ->
    IO.puts("✗ magick command not found")
end

IO.puts("")

# Check for convert command (ImageMagick 6)
IO.puts("Checking for 'convert' command...")

case System.cmd("which", ["convert"]) do
  {path, 0} ->
    IO.puts("✓ convert found at: #{String.trim(path)}")
    {version, 0} = System.cmd("convert", ["--version"])
    IO.puts("  Version: #{String.split(version, "\n") |> Enum.at(0)}")

  _ ->
    IO.puts("✗ convert command not found")
end

IO.puts("")

# Check for ffmpeg
IO.puts("Checking for 'ffmpeg' command...")

case System.cmd("which", ["ffmpeg"]) do
  {path, 0} ->
    IO.puts("✓ ffmpeg found at: #{String.trim(path)}")
    {version, 0} = System.cmd("ffmpeg", ["-version"])
    IO.puts("  Version: #{String.split(version, "\n") |> Enum.at(0)}")

  _ ->
    IO.puts("✗ ffmpeg command not found")
end

IO.puts("")

# Check Thumbnex
IO.puts("Checking Thumbnex module...")

case Code.ensure_loaded(Thumbnex) do
  {:module, _} ->
    IO.puts("✓ Thumbnex module loaded")

    # Check dependencies
    deps = Sahajyog.Resources.ThumbnailGenerator.check_dependencies()
    IO.puts("  Dependencies: #{inspect(deps)}")

  {:error, reason} ->
    IO.puts("✗ Thumbnex not loaded: #{inspect(reason)}")
end

IO.puts("\n=== Check Complete ===\n")
