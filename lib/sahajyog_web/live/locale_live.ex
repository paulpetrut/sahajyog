defmodule SahajyogWeb.LocaleLive do
  @moduledoc """
  LiveView hook for handling locale changes across all LiveViews.
  """

  def on_mount(:default, _params, session, socket) do
    locale = session["locale"] || "en"
    Gettext.put_locale(SahajyogWeb.Gettext, locale)
    {:cont, Phoenix.Component.assign(socket, :locale, locale)}
  end
end
