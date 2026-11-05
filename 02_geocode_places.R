# ─────────────────────────────────────────────────────────────────────────────
# 02_geocode_places.R
# Geocodes the unique artist birth- and death-places listed in ham_people.csv.
#
# Uses OpenStreetMap Nominatim (free, no key) via {tidygeocoder}. Nominatim's
# terms allow one request per second; tidygeocoder throttles for us, so a full
# run takes a couple of minutes. Results are cached to CSV — rerun only when
# ham_people.csv changes.
#
# HAM writes some places in historical or bracketed form ("Breslau, Prussia
# [now Wroclav, Poland]"), which Nominatim cannot parse. `place_overrides`
# below maps those raw strings to a query Nominatim does resolve. The raw HAM
# string stays the key in the output, so downstream joins are unaffected.
#
# Input : data/ham_people.csv
# Output: data/birthplace_coords.csv, data/deathplace_coords.csv
# ─────────────────────────────────────────────────────────────────────────────

library(tidygeocoder)
library(tidyverse)

# Fills birthplaces the HAM record leaves blank, so they get geocoded here too.
source("00_people_supplements.R")

people_df <- read_csv("data/ham_people.csv", show_col_types = FALSE) |>
  apply_birthplace_supplements()

# ── Query rewrites for places Nominatim cannot resolve as written ─────────────
place_overrides <- tribble(
  ~raw,                                                      ~query,
  "St. Thomas, Danish W. Indies (now U.S. Virgin Islands)",  "Charlotte Amalie, Saint Thomas, U.S. Virgin Islands",
  "Breslau, Prussia [now Wroclav, Poland]",                  "Wroclaw, Poland",
  "Tapiau, East Prussia [now Gvardeysk, Russia]",            "Gvardeysk, Kaliningrad Oblast, Russia",
  "Lattrop (Denekamp), The Netherlands",                     "Lattrop, Dinkelland, Netherlands",
  "Moutier-en-Der",                                          "Montier-en-Der, Haute-Marne, France",
  "Scaleby, Cumbria",                                        "Scaleby, Cumberland, England",
  "Grüngiebing, Schwindkirchen near Haag",                  "Grüngiebing, Obertaufkirchen, Bayern, Germany",
  "Obergibeln, Tyrol",                                       "Obergiblen, Elbigenalp, Tirol, Austria",
  "Fatu-Iwa [Marquesas Islands]",                            "Fatu Hiva, Marquesas Islands, French Polynesia",
  "La Tour-de-Peilzy, near Vevey, Switzerland",              "La Tour-de-Peilz, Vaud, Switzerland",
  "Boldre, Hants",                                           "Boldre, Hampshire, England"
)

geocode_places <- function(df, place_col, out_file) {
  unique_places <- df |>
    filter(!is.na(.data[[place_col]]), nzchar(.data[[place_col]])) |>
    distinct(raw = .data[[place_col]]) |>
    left_join(place_overrides, by = "raw") |>
    mutate(address = coalesce(query, raw))

  n_over <- sum(!is.na(unique_places$query))
  cat("Geocoding", nrow(unique_places), "unique", place_col, "entries",
      sprintf("(%d via override)…\n", n_over))

  coords <- unique_places |>
    geocode(
      address      = address,
      method       = "osm",      # swap to "google" or "arcgis" for better accuracy
      lat          = "latitude",
      long         = "longitude",
      full_results = FALSE,
      verbose      = TRUE
    ) |>
    select(raw, geocode_query = address, latitude, longitude) |>
    rename(!!place_col := raw)

  unresolved <- coords |> filter(is.na(latitude))
  if (nrow(unresolved) > 0) {
    cat("  Unresolved — add to place_overrides:\n")
    walk(unresolved[[place_col]], ~ cat("    ", .x, "\n"))
  }

  write_csv(coords, out_file)
  cat(sprintf("Saved: %s (%d of %d resolved)\n",
              out_file, sum(!is.na(coords$latitude)), nrow(coords)))
}

geocode_places(people_df, "birthplace", "data/birthplace_coords.csv")
geocode_places(people_df, "deathplace", "data/deathplace_coords.csv")
