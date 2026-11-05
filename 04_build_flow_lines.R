# ─────────────────────────────────────────────────────────────────────────────
# 04_build_flow_lines.R
# Builds the three map layers: where each artist came from, where the work
# looks at, and the line between the two.
#
# Only the primary artist (displayorder == 1) is used, and only objects where
# both ends of the line are known — so the layer counts are smaller than the
# object count, by design.
#
# Inputs : data/ham_objects.csv, data/ham_people.csv,
#          data/objects_with_coords.csv, data/birthplace_coords.csv
# Outputs: data/geojson/{objects_points,birthplace_points,flow_lines}.geojson
# ─────────────────────────────────────────────────────────────────────────────

library(tidyverse)
library(sf)
library(geosphere)

source("00_people_supplements.R")

people    <- read_csv("data/ham_people.csv",           show_col_types = FALSE) |>
  apply_birthplace_supplements()
depicted  <- read_csv("data/objects_with_coords.csv",  show_col_types = FALSE) |>
  mutate(specificity = as.integer(specificity))
bp_coords <- read_csv("data/birthplace_coords.csv",    show_col_types = FALSE)

# ── Primary artists only ──────────────────────────────────────────────────────
artists <- people |>
  filter(displayorder == 1, !is.na(birthplace)) |>
  left_join(bp_coords, by = "birthplace") |>
  rename(birth_lat = latitude, birth_lon = longitude)

# ── Join everything ───────────────────────────────────────────────────────────
flow_flat <- artists |>
  left_join(
    select(depicted, objectnumber, depicted_loc, latitude, longitude,
           specificity, basis, title, alt_title, alt_title_type, dated,
           datebegin, dateend, medium, century, primaryimageurl, url),
    by = "objectnumber"
  ) |>
  rename(dep_lat = latitude, dep_lon = longitude) |>
  filter(!is.na(birth_lat), !is.na(dep_lat)) |>
  mutate(
    nationality = case_when(
      str_detect(culture, regex("british|english|scottish|welsh|irish", ignore_case = TRUE)) ~ "British",
      str_detect(culture, regex("french",  ignore_case = TRUE)) ~ "French",
      str_detect(culture, regex("german",  ignore_case = TRUE)) ~ "German",
      str_detect(culture, regex("dutch|flemish|netherlandish", ignore_case = TRUE)) ~ "Dutch/Flemish",
      str_detect(culture, regex("swiss",   ignore_case = TRUE)) ~ "Swiss",
      str_detect(culture, regex("italian", ignore_case = TRUE)) ~ "Italian",
      TRUE ~ coalesce(culture, "Unknown")
    )
  )

# ── Calculate distance ────────────────────────────────────────────────────────
flow_flat <- flow_flat |>
  rowwise() |>
  mutate(distance_km = round(distGeo(c(birth_lon, birth_lat),
                                     c(dep_lon,   dep_lat)) / 1000, 1)) |>
  ungroup()

# ── LAYER 1: object points (depicted location) ────────────────────────────────
# `alt_title` / `alt_title_type` ride on this layer only. The line layer is
# about the journey between two places, not about what the object is called.
objects_sf <- flow_flat |>
  select(objectnumber, title, alt_title, alt_title_type,
         artist_name = name, nationality,
         culture, dated, datebegin, dateend, century, medium,
         depicted_loc, specificity, basis, dep_lat, dep_lon, distance_km,
         primaryimageurl, url) |>
  st_as_sf(coords = c("dep_lon", "dep_lat"), crs = 4326)

# ── LAYER 2: birthplace points ────────────────────────────────────────────────
birthplaces_sf <- flow_flat |>
  distinct(name, birthplace, birthplace_source, birth_lat, birth_lon,
           nationality, culture, birth_year, death_year, displaydate) |>
  filter(!is.na(birth_lat)) |>
  st_as_sf(coords = c("birth_lon", "birth_lat"), crs = 4326)

# ── LAYER 3: flow lines ───────────────────────────────────────────────────────
lines_geom <- flow_flat |>
  rowwise() |>
  mutate(geometry = st_sfc(st_linestring(
    matrix(c(birth_lon, birth_lat, dep_lon, dep_lat), nrow = 2, byrow = TRUE)
  ), crs = 4326)) |>
  ungroup()

flow_sf <- st_as_sf(
  select(flow_flat, objectnumber, title, artist_name = name,
         nationality, culture, birthplace, birthplace_source, depicted_loc,
         specificity, basis, distance_km, datebegin, dateend,
         primaryimageurl, url),
  geometry = lines_geom$geometry
)
st_crs(flow_sf) <- 4326

# ── Export ────────────────────────────────────────────────────────────────────
dir.create("data/geojson", showWarnings = FALSE)
st_write(objects_sf,     "data/geojson/objects_points.geojson",    delete_dsn = TRUE, quiet = TRUE)
st_write(birthplaces_sf, "data/geojson/birthplace_points.geojson", delete_dsn = TRUE, quiet = TRUE)
st_write(flow_sf,        "data/geojson/flow_lines.geojson",        delete_dsn = TRUE, quiet = TRUE)

cat(sprintf("\n── Layers ───────────────────────────────────────────────\n"))
cat(sprintf("Objects placed   : %d\n", nrow(objects_sf)))
cat(sprintf("Birthplaces      : %d\n", nrow(birthplaces_sf)))
cat(sprintf("Flow lines       : %d\n", nrow(flow_sf)))
cat(sprintf("Median distance  : %.0f km\n", median(flow_flat$distance_km, na.rm = TRUE)))
cat(sprintf("  of which from a supplied birthplace: %d\n",
            sum(birthplaces_sf$birthplace_source == "supplement", na.rm = TRUE)))
cat(sprintf("With alt. title  : %d\n",
            sum(!is.na(objects_sf$alt_title))))
cat("\nPlaced objects by basis:\n")
objects_sf |> st_drop_geometry() |> count(basis, sort = TRUE) |>
  pwalk(\(basis, n) cat(sprintf("  %-15s %d\n", basis, n)))
cat("\nExported 3 GeoJSON files to data/geojson/\n")
