# ─────────────────────────────────────────────────────────────────────────────
# 00_people_supplements.R
# Birthplaces the HAM record leaves blank, supplied by hand.
#
# The API returns no `birthplace` for these artists, so 04_build_flow_lines.R
# drops their objects before they reach the map even when the depicted end is
# known. Each row below is keyed on the HAM `personid` and carries the source
# it was taken from.
#
# Anything filled in here is marked `birthplace_source = "supplement"` in the
# output layers, so a hand-supplied origin is never silently mixed with one the
# museum recorded.
#
# Sourced by 02_geocode_places.R (so the place gets geocoded) and by
# 04_build_flow_lines.R (so the line gets drawn). Needs no network or API key.
# ─────────────────────────────────────────────────────────────────────────────

birthplace_supplements <- tribble(
  ~personid, ~name,                         ~birthplace,                        ~source,
  28753,     "John (called Warwick) Smith", "Irthington, Cumberland, England",  "Dictionary of National Biography: born Irthington, near Carlisle, 26 July 1749",
  26657,     "Victor Marie Hugo",           "Besançon, Doubs, France",          "Born 26 February 1802 at 140 Grande-Rue, Besançon, now a museum",
  27687,     "Berthe Morisot",              "Bourges, Cher, France",            "Born 14 January 1841 at Bourges; the family moved to Passy before she was 12",
  70058,     "George Vicat Cole",           "Portsmouth, Hampshire, England",   "Born 17 April 1833 at Portsmouth; a plaque marks the house",
  33933,     "Alexander Cozens",            "Saint Petersburg, Russia",         "Born St Petersburg 1717; son of Richard Cozens, shipbuilder to Peter the Great",
  26651,     "Paul Huet",                   "Paris, France",                    "Born 3 October 1803 in Paris",
  31028,     "Jean François Janinet",       "Paris, France",                    "Born Paris 1752, died Paris 1 November 1814"
)

# Fill a blank `birthplace` from the table above, matching on personid.
# Adds `birthplace_source`: "ham", "supplement", or NA where still unknown.
apply_birthplace_supplements <- function(people_df) {
  people_df |>
    left_join(
      select(birthplace_supplements, personid, .supp = birthplace),
      by = "personid"
    ) |>
    mutate(
      birthplace_source = case_when(
        !is.na(birthplace) ~ "ham",
        !is.na(.supp)      ~ "supplement",
        TRUE               ~ NA_character_
      ),
      birthplace = coalesce(birthplace, .supp)
    ) |>
    select(-.supp)
}
