defmodule SahajyogWeb.Plugs.Locale do
  @moduledoc """
  Plug to set the locale based on URL params or session.
  """
  import Plug.Conn

  @supported_locales Gettext.known_locales(SahajyogWeb.Gettext)

  def init(default), do: default

  def call(conn, _default) do
    locale = get_locale_from_params(conn) || get_locale_from_session(conn) || "en"

    if locale in @supported_locales do
      Gettext.put_locale(SahajyogWeb.Gettext, locale)
      conn |> put_session(:locale, locale) |> assign(:locale, locale)
    else
      conn |> assign(:locale, "en")
    end
  end

  defp get_locale_from_params(conn) do
    conn.params["locale"]
  end

  defp get_locale_from_session(conn) do
    get_session(conn, :locale)
  end
end
