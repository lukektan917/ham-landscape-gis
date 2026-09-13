# ─────────────────────────────────────────────────────────────────────────────
# 02_geocode_places.R
# Geocodes the unique artist birth- and death-places listed in ham_people.csv.
#
# Uses OpenStreetMap Nominatim (free, no key) via {tidygeocoder}. Nominatim's
# terms allow one request per second; tidygeocoder throttles for us, so a full
# run takes a couple of minutes. Results are cached to CSV — rerun only when
# ham_people.csv changes.
#
# Input : data/ham_people.csv
# Output: data/birthplace_coords.csv, data/deathplace_coords.csv
# ─────────────────────────────────────────────────────────────────────────────

library(tidygeocoder)
library(tidyverse)

people_df <- read_csv("data/ham_people.csv", show_col_types = FALSE)

geocode_places <- function(df, place_col, out_file) {
  unique_places <- df |>
    filter(!is.na(.data[[place_col]]), nzchar(.data[[place_col]])) |>
    distinct(address = .data[[place_col]])

  cat("Geocoding", nrow(unique_places), "unique", place_col, "entries…\n")

  coords <- unique_places |>
    geocode(
      address      = address,
      method       = "osm",      # swap to "google" or "arcgis" for better accuracy
      lat          = "latitude",
      long         = "longitude",
      full_results = FALSE,
      verbose      = TRUE
    ) |>
    rename(!!place_col := address)

  write_csv(coords, out_file)
  cat(sprintf("Saved: %s (%d of %d resolved)\n",
              out_file, sum(!is.na(coords$latitude)), nrow(coords)))
}

geocode_places(people_df, "birthplace", "data/birthplace_coords.csv")
geocode_places(people_df, "deathplace", "data/deathplace_coords.csv")
