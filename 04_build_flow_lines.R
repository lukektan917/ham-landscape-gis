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
source("00_catalogue_supplements.R")

people    <- read_csv("data/ham_people.csv",           show_col_types = FALSE) |>
  apply_birthplace_supplements() |>
  apply_catalogue_people() |>
  apply_culture_supplements()

# Artist biographies transcribed from the exhibition catalogue, joined onto the
# birthplace layer by surname. 95 of the 100 primary artists have one. See
# CATALOGUE.md for how the section was parsed.
#
# Joined on surname AND first forename, not surname alone. The catalogue holds
# two Hunts (William Henry, William Holman) and two Varleys (John, Cornelius),
# and a surname-only join silently gives one brother the other's life story.
# Where a surname is unique in the catalogue it can also match on its own, which
# catches artists whose name carries a particle ("Jan van Ravenswaay").
ascii_lower <- function(x) str_to_lower(stringi::stri_trans_general(x, "Latin-ASCII"))

bios_raw <- read_csv("data/catalogue_biographies.csv", show_col_types = FALSE) |>
  filter(!is.na(text), str_squish(text) != "") |>
  mutate(
    bio_sur   = ascii_lower(word(str_squish(surname), -1)),
    bio_fore  = ascii_lower(word(str_squish(forename), 1))
  )

bios_full <- bios_raw |>
  transmute(join_key = str_c(bio_sur, "|", bio_fore),
            biography = text, biography_life = life)

bios_sur <- bios_raw |>
  add_count(bio_sur) |>
  filter(n == 1) |>
  transmute(join_key = bio_sur, biography = text, biography_life = life)

bios <- bind_rows(bios_full, bios_sur) |> distinct(join_key, .keep_all = TRUE)
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
           datebegin, dateend, date_mid, date_is_approx, medium, century,
           primaryimageurl, url),
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
         culture, dated, datebegin, dateend, date_mid, date_is_approx,
         century, medium,
         depicted_loc, specificity, basis, dep_lat, dep_lon, distance_km,
         primaryimageurl, url) |>
  st_as_sf(coords = c("dep_lon", "dep_lat"), crs = 4326)

# ── LAYER 2: birthplace points ────────────────────────────────────────────────
# `biography` is the catalogue's prose account of the artist and `biography_life`
# its birth/death line. They sit on this layer because they are about the person,
# not the object — one artist, one point, one biography.
# One point per artist. Hugo has two people rows (a HAM sheet and a catalogue
# loan), so dedupe on name, preferring the museum's own record.
birthplaces_sf <- flow_flat |>
  filter(!is.na(birth_lat)) |>
  mutate(.src_rank = match(birthplace_source, c("ham", "supplement", "catalogue"))) |>
  arrange(.src_rank) |>
  distinct(name, .keep_all = TRUE) |>
  select(name, birthplace, birthplace_source, birth_lat, birth_lon,
         nationality, culture, birth_year, death_year, displaydate) |>
  mutate(
    .sur      = ascii_lower(word(str_squish(name), -1)),
    .fore     = ascii_lower(word(str_squish(name), 1)),
    .key_full = str_c(.sur, "|", .fore)
  ) |>
  left_join(bios, by = join_by(.sur == join_key)) |>
  rename(biography_s = biography, biography_life_s = biography_life) |>
  left_join(bios, by = join_by(.key_full == join_key)) |>
  mutate(
    biography      = coalesce(biography, biography_s),
    biography_life = coalesce(biography_life, biography_life_s)
  ) |>
  select(-.sur, -.fore, -.key_full, -biography_s, -biography_life_s) |>
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
         date_mid, date_is_approx, primaryimageurl, url),
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
cat(sprintf("With a biography : %d of %d birthplaces\n",
            sum(!is.na(birthplaces_sf$biography)), nrow(birthplaces_sf)))
cat(sprintf("Dated            : %d exact, %d century midpoint, %d undated\n",
            sum(!objects_sf$date_is_approx & !is.na(objects_sf$date_mid)),
            sum(objects_sf$date_is_approx, na.rm = TRUE),
            sum(is.na(objects_sf$date_mid))))
unknown_nat <- birthplaces_sf |> filter(nationality == "Unknown")
if (nrow(unknown_nat) > 0)
  warning("Artists with no culture, so nationality 'Unknown': ",
          paste(unknown_nat$name, collapse = ", "))
cat(sprintf("  of which from a supplied birthplace: %d\n",
            sum(birthplaces_sf$birthplace_source == "supplement", na.rm = TRUE)))
cat(sprintf("With alt. title  : %d\n",
            sum(!is.na(objects_sf$alt_title))))
cat("\nPlaced objects by basis:\n")
objects_sf |> st_drop_geometry() |> count(basis, sort = TRUE) |>
  pwalk(\(basis, n) cat(sprintf("  %-15s %d\n", basis, n)))
cat("\nExported 3 GeoJSON files to data/geojson/\n")
