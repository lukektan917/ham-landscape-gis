# ─────────────────────────────────────────────────────────────────────────────
# 00_catalogue_supplements.R
# Works in the exhibition that the HAM API cannot describe, supplied from the
# exhibition catalogue.
#
# `01_fetch_ham.R` returns five accessions with status NOT_FOUND and every other
# field empty: one Houghton Library shelfmark and four temporary-loan numbers.
# They are in the exhibition but not in the API, so without this file they carry
# no title, no artist and therefore no birthplace, and 04_build_flow_lines.R
# drops them before the map.
#
# Everything here is transcribed from `On Location: Drawing the Outdoors`
# (ed. Joachim Homann, Harvard Art Museums / Yale University Press) — plate
# captions for the objects, the Artist Biographies section for the people.
# See CATALOGUE.md. Nothing here comes from the HAM API, and every row is
# marked `record_source = "catalogue"` in the output layers so a catalogue-
# sourced object is never silently mixed with one the API returned.
#
# Sourced by 03_object_coords.R and 04_build_flow_lines.R.
# ─────────────────────────────────────────────────────────────────────────────

# Objects. `objectnumber` matches the NOT_FOUND rows in data/ham_objects.csv.
catalogue_objects <- tribble(
  ~objectnumber,  ~title,                                   ~people_names,       ~culture,  ~medium,                                             ~dated,  ~datebegin, ~dateend, ~century,       ~creditline,
  "MS Typ 481",   "Hauteville",                             "Victor Marie Hugo", "French",  "Ink and brown wash on paper",                       "1861",  1861L,      1861L,    "19th century", "Houghton Library, Harvard University",
  "TL42858.1",    "Montreux",                               "Gustave Doré",      "French",  "Watercolor over graphite",                          NA,      0L,         0L,       "19th century", "Collection of David M. Leventhal ’71",
  "TL42858.2",    "The Cliffs of Varengeville in Full Sun", "Eugène Isabey",     "French",  "Transparent and opaque watercolor and oil on paper", NA,      0L,         0L,       "19th century", "Collection of David M. Leventhal ’71, promised gift to the Harvard Art Museums in memory of William Robinson"
)

# People. `personid` 26657 is Hugo's real HAM id, already present in
# 00_people_supplements.R from his sheet 2021.51. Doré and Isabey have no HAM
# record at all, so they take negative placeholder ids — negative so they can
# never collide with a real one, and so a join against HAM data fails loudly
# rather than matching the wrong person.
catalogue_people <- tribble(
  ~objectnumber,  ~personid, ~displayorder, ~role,      ~name,               ~culture,  ~birth_year, ~death_year, ~birthplace,                 ~deathplace,
  "MS Typ 481",   26657L,    1L,            "Artist",   "Victor Marie Hugo", "French",  1802L,       1885L,       "Besançon, Doubs, France",   "Paris, France",
  "TL42858.1",    -1L,       1L,            "Artist",   "Gustave Doré",      "French",  1832L,       1883L,       "Strasbourg, Bas-Rhin, France", "Paris, France",
  "TL42858.2",    -2L,       1L,            "Artist",   "Eugène Isabey",     "French",  1803L,       1886L,       "Paris, France",             "Paris, France"
)

# ── Note on TL42858.2 ────────────────────────────────────────────────────────
# The catalogue prints no accession for the Isabey, crediting only "Collection
# of David M. Leventhal ’71" — but 03_object_coords.R already carried this
# identification before the catalogue was read, and the catalogue corroborates
# it: the Doré (TL42858.1, confirmed by its title) comes from the same lender
# and shares the loan prefix 42858. TL42852.4 and TL42880 remain unidentified.

# Merge the catalogue object records into the objects table, filling only the
# empty NOT_FOUND rows and leaving every API-sourced field untouched.
apply_catalogue_objects <- function(objects_df) {
  objects_df |>
    rows_update(catalogue_objects, by = "objectnumber", unmatched = "ignore") |>
    mutate(record_source = if_else(objectnumber %in% catalogue_objects$objectnumber,
                                   "catalogue", "ham"))
}

# ── Nationalities the HAM record leaves blank ────────────────────────────────
# 04_build_flow_lines.R derives `nationality` from `culture`, so an artist with
# no culture falls through to "Unknown" on the birthplace layer. Both of these
# are stated plainly in the catalogue's Artist Biographies headers
# ("Brondgeest, Albertus, Dutch (Amsterdam 1786–1849 Amsterdam)").
culture_supplements <- tribble(
  ~name,                 ~culture,
  "Albertus Brondgeest", "Dutch",
  "Francis Towne",       "British"
)

# HAM sometimes records a doubled culture — "British, English" on four rows.
# The derived `nationality` already collapses that to "British", but `culture`
# itself rides along into the layers and popups, so tidy it at source.
culture_rewrites <- c("British, English" = "British")

apply_culture_supplements <- function(people_df) {
  people_df |>
    left_join(culture_supplements, by = "name", suffix = c("", ".supp")) |>
    mutate(
      culture = coalesce(culture, culture.supp),
      culture = recode(culture, !!!as.list(culture_rewrites))
    ) |>
    select(-culture.supp)
}

# Add the catalogue artists to the people table. These objectnumbers have no
# people rows at all, so this is a bind, not an update.
#
# `birthplace_source = "catalogue"` keeps these distinguishable from both the
# museum's own data ("ham") and 00_people_supplements.R ("supplement").
# Hugo already has a HAM people row from his sheet 2021.51, so he ends up with
# two rows here — one per object, which is how `people` is keyed. The birthplace
# layer in 04 collapses them back to one point per artist.
apply_catalogue_people <- function(people_df) {
  bind_rows(people_df, mutate(catalogue_people, birthplace_source = "catalogue"))
}
