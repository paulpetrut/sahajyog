[
  # Gettext plural forms warnings - these are expected due to Expo.PluralForms opaque types
  # Target both source and beam files for ElixirLS compatibility
  {"lib/sahajyog_web/gettext.ex", :call_without_opaque},
  {"Elixir.SahajyogWeb.Gettext", :call_without_opaque},

  # Additional warning types for Gettext plural handling
  {"lib/sahajyog_web/gettext.ex", :contract_diff},
  {"Elixir.SahajyogWeb.Gettext", :contract_diff},
  {"lib/sahajyog_web/gettext.ex", :contract_range},
  {"Elixir.SahajyogWeb.Gettext", :contract_range},
  {"lib/sahajyog_web/gettext.ex", :contract_subtype},
  {"Elixir.SahajyogWeb.Gettext", :contract_subtype},
  {"lib/sahajyog_web/gettext.ex", :contract_supertype},
  {"Elixir.SahajyogWeb.Gettext", :contract_supertype}
]
