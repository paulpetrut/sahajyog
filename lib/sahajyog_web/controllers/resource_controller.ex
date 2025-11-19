defmodule SahajyogWeb.ResourceController do
  use SahajyogWeb, :controller

  alias Sahajyog.Resources
  alias Sahajyog.Resources.R2Storage

  def download(conn, %{"id" => id}) do
    resource = Resources.get_resource!(id)
    current_user = conn.assigns.current_scope.user

    # Check if user has access to this resource level
    if resource.level == current_user.level do
      # Increment download counter asynchronously
      Task.start(fn -> Resources.increment_downloads(resource) end)

      # Generate presigned URL with forced download
      download_url = R2Storage.generate_download_url(resource.r2_key, force_download: true)

      conn
      |> redirect(external: download_url)
    else
      conn
      |> put_flash(:error, "You don't have access to this resource")
      |> redirect(to: ~p"/resources")
    end
  end
end
