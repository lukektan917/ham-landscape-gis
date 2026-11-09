# ham-landscape-gis

Mapping where nineteenth-century landscape artists came *from* against where they
chose to *look* — built from the Harvard Art Museums collection API.

The pipeline in this repo produces three map layers for a set of 153 landscape
works (c. 1774–1915, mostly French, British, Swiss, Dutch and German artists):

| Layer | What it is |
| --- | --- |
| `objects_points` | the place each work depicts |
| `birthplace_points` | where the artist was born |
| `flow_lines` | a great-circle line joining the two, with the distance |

**The finished map:** [On Location — ArcGIS Experience](https://experience.arcgis.com/experience/893f423062da4db0bbbdee8a4afc8c36/)

## The pipeline

```
00_config.R              API key + the list of accession numbers to fetch
00_people_supplements.R  birthplaces the HAM record leaves blank
      │
01_fetch_ham.R           HAM API  →  data/ham_objects.csv
      │                            data/ham_people.csv
      ├──────────────────┐
      │                  │
02_geocode_places.R      03_object_coords.R
  artist birthplaces       depicted locations, assigned by hand
  via OSM Nominatim        → data/objects_with_coords.csv
  → data/*_coords.csv      │
      │                  │
      └────────┬─────────┘
               │
      04_build_flow_lines.R  →  data/geojson/*.geojson  →  ArcGIS Experience
```

Both `00_*` files are sourced by the numbered steps rather than run on their
own.

Scripts are numbered in run order and each writes its outputs to `data/`, so any
step can be rerun on its own. Steps 3 and 4 need no network access — the CSVs
they read are committed here.

```bash
Rscript 01_fetch_ham.R        # needs HAM_APIKEY, ~1 min
Rscript 02_geocode_places.R   # needs network, ~2 min (Nominatim is rate-limited)
Rscript 03_object_coords.R
Rscript 04_build_flow_lines.R
```

### Setup

R 4.3+ with `tidyverse`, `httr2`, `jsonlite`, `tidygeocoder`, `sf`, `geosphere`:

```r
install.packages(c("tidyverse", "httr2", "jsonlite", "tidygeocoder", "sf", "geosphere"))
```

Only `01_fetch_ham.R` needs a key. Request one from the
[Harvard Art Museums API](https://harvardartmuseums.org/collections/api) and put
it in `~/.Renviron` (see `.Renviron.example`), then restart R:

```
HAM_APIKEY=your-key-here
```

## The locating problem

Most of the work in this project is not code. The HAM API says who made an object
and when, but never where the view is — "Umbrian Landscape" could be anywhere in
Umbria. So depicted locations are assigned by hand in `03_object_coords.R` from
the title, the image and curatorial notes, and each one is graded on two axes.

`specificity` records how tightly the view can be pinned:

| `specificity` | Meaning | Count |
| --- | --- | --- |
| `2` | a named, identifiable view — a bridge, a harbour, a peak | 28 |
| `1` | a settlement, valley or estate | 23 |
| `0` | approximate; placed, but not a precise viewpoint | 24 |

`basis` records what the placement rests on, so a reader can weigh it:

| `basis` | Meaning | Count |
| --- | --- | --- |
| `title` | the HAM title names the place | 62 |
| `alt_title` | a HAM alternative title names it | 5 |
| `catalogue` | the exhibition catalogue names the place | 3 |
| `curatorial` | argued from a related work or published source | 3 |
| `description` | the HAM description names it | 1 |
| `creation_place` | the HAM `places` record names it | 1 |

Four of those bases are the museum's own record. `catalogue` covers three works
the HAM API holds no record for at all — a Houghton Library shelfmark and two
loans — described from the exhibition catalogue in
`00_catalogue_supplements.R`. See `CATALOGUE.md`.

`curatorial` is the one inferential basis still on the map, and deliberately so:
each of its three rows rests on a published identification of *that sheet* —
Géricault's `1943.364` through his lithograph *The Coal Waggon*, Friedrich's
`1985.51` through Zschoche's study of his Harz drawings, `2021.517` through the
sitter's family seat. The script refuses to let such a row be graded above
`specificity` 1.

What is no longer mapped is `basis` `biography` — a work placed where its artist
was documented to be living at its date. The research was not wrong, but the
claim is different in kind: knowing Millet lived at Barbizon from 1849 does not
establish that an undated sheet of his depicts Barbizon. Those five rows moved
to `candidate_coords` with their reasoning intact.

A further 12 works name no locatable view at all. Their regional centroids sit in
a `region_coords` table that is deliberately **not** joined into the output —
mapping them would imply a precision the objects don't carry. Move a row up into
`depicted_coords` once a view has been identified.

A third table, `candidate_coords`, holds 14 works with a plausible location the
project could not confirm to the standard above — Zorn's bathers at Dalarö,
Mauve’s undated Laren subjects, Boudin’s "1867(?)" beach, and the five
placements once made from an artist’s whereabouts. It is not joined either; it exists
so the research isn't repeated.

`04_build_flow_lines.R` uses only the primary artist (`displayorder == 1`) and
only objects where both ends of the line are known, which is why the layers hold
74 objects and 61 birthplaces rather than all 153.
Median birthplace-to-subject distance across those lines is 314 km.

`birthplace_points` also carries `biography` and `biography_life`, the
catalogue's prose account of each artist and its birth/death line. They sit on
that layer rather than on the objects because they describe the person, not the
work — one artist, one point, one biography. 56 of the 61 have one; the five
without are artists the catalogue's Artist Biographies section does not cover,
plus George Vicat Cole, whose entry the parser could not recover.

### Dates on the map

HAM encodes "no year" as `datebegin` 0, and 15 of the 74 placed objects are
dated only to a century. A time slider built on `datebegin` drops them, so the
object and line layers carry two more columns:

| Column | Meaning |
| --- | --- |
| `date_mid` | the recorded begin year, or the century midpoint where there is none |
| `date_is_approx` | `true` when `date_mid` is a midpoint rather than a record |

Midpoints are 1750 / 1800 / 1850 / 1900 for the 18th, 18th–19th, 19th and
19th–20th centuries. They are a convention, not evidence: an 18th–19th century
work sits at 1800 because that is the middle of the span HAM allows, not
because anything points to 1800. `date_is_approx` exists so an invented year
can always be told from a recorded one, and styled or filtered apart.

All 74 placed objects now carry a `date_mid`; recorded years run 1773–1909.

`objects_points` and `flow_lines` both carry `specificity` and `basis`, so the
map can filter or style by how firm a placement is.

### Alternative titles

A title is not a neutral label here — it is the main thing that does or doesn't
disclose a place, so the names the museum holds beyond the primary one are
carried as data rather than left in the API. `01_fetch_ham.R` splits HAM's
`titles` array into `title` (the primary) and two parallel columns on
`objects_points`:

| Column | Holds |
| --- | --- |
| `alt_title` | every other name HAM carries, `" \| "`-separated |
| `alt_title_type` | the matching HAM type for each, in the same order |

Splitting both on `" | "` lines the types up with the titles. The separator is
not `"; "` because a single title may contain a semicolon — 1962.42's
alternative title is `La Montagne Sacrée; The Sacred Mountain`.

44 of the 153 objects carry at least one, and 24 of the 74 placed ones do. By
type, across those 24:

| `alt_title_type` | Count | What it is |
| --- | --- | --- |
| `Original Language Title` | 13 | usually the artist's own wording |
| `Alternate Title` | 7 | a curatorial variant |
| `Former Title` | 5 | what the museum used to call the work |
| `Title` | 2 | a co-equal second primary title |

These are worth showing because they often carry the place the primary title
withholds, and sometimes the reverse. 1999.247 is catalogued both as *View Near
Nemi* and as *Italian Landscape* — the same sheet named once precisely and once
vaguely. 1943.515 is *Peasant of the Camargue*, but its alternative title
*Portrait of Patience Escalier* is the reason this project flags it as a
portrait being mapped as a view (see Known gaps). 2023.252 carries two titles
both typed `Title`, so *Landscape (George Sand's Garden at Nohant)* is not a
variant but a second primary name, and it is the one that locates the work.

An object's primary title can change. 1999.12 was *Mountainous Landscape with a
Volcano* with *Mount Vesuvius* as the alternative, and HAM has since swapped
them — so its `basis` is now `title`, and the old name survives as a
`Former Title`. `03_object_coords.R` warns if any row graded `alt_title` has no
alternative title left in the record, which is how that was caught.

The alternative titles are **not** carried on `flow_lines`: that layer is about
the journey between two places, not about what the object is called.

### Supplied birthplaces

The API returns no birthplace for 7 of the artists, which silently cost the map
their lines. `00_people_supplements.R` fills those in by hand, keyed on HAM's
`personid` and carrying the source for each — Morisot at Bourges, Hugo at
Besançon, Cozens at St Petersburg, and four more. 5 of the 61 birthplace points
come from that table, and every one is marked `birthplace_source = "supplement"`
in `birthplace_points` and `flow_lines` so a supplied origin is never mistaken
for one the museum recorded.

## Data

| File | Rows | Notes |
| --- | --- | --- |
| `data/ham_objects.csv` | 153 | one row per object; 148 resolved, 5 `NOT_FOUND`; 44 carry an `alt_title` |
| `data/ham_people.csv` | 154 | one row per person–object link, with parsed birth/death years |
| `data/objects_with_coords.csv` | 153 | objects plus depicted location, `specificity`, `basis` and alternative titles |
| `data/birthplace_coords.csv` | 72 | geocoded via OSM Nominatim; 72 resolved |
| `data/deathplace_coords.csv` | 58 | geocoded via OSM Nominatim; 58 resolved |
| `data/geojson/` | — | the three layers, EPSG:4326 |

Object and artist metadata is © President and Fellows of Harvard College,
retrieved through the Harvard Art Museums API. Geocodes are derived from
OpenStreetMap (ODbL).

### Known gaps

- 5 accession numbers return `NOT_FOUND` — non-standard prefixes (`TL…`,
  `MS Typ…`) that the object endpoint doesn't resolve. Two of them
  (`TL42852.4`, `TL42858.2`) still carry hand-assigned coordinates and reach the
  map with no title or artist attached.
- **The HAM API records a place for one object in 153.** The `places` field
  (`Creation Place`) is populated only for `1943.296`. There is no systematic
  place data to fall back on, which is why every other point is hand-assigned.
- `active_dates` in `ham_people.csv` flags artists whose display date is an
  activity period rather than birth–death; treat their `birth_year` accordingly.
- Nominatim resolves place names as written, so historical or superseded names
  may land on the modern settlement of the same name. `place_overrides` in
  `02_geocode_places.R` rewrites the eleven HAM strings it could not parse at all.
- `1943.515` ("Peasant of the Camargue") is a portrait, not a view. It is placed
  in the Camargue on the sitter's identity rather than on anything the sheet
  depicts. Its alternative title "Portrait of Patience Escalier" now travels
  with the point, so the map discloses this rather than burying it here.
- `8.2023` is a bound album of 30 drawings spanning Hampshire, Sussex and Kent.
  It carries one point, which sits in the Solent and stands for the whole album.
- `2021.517` is titled "At Parton Hall, Staffordshire"; no such hall is recorded.
  The point is placed at Wrottesley Hall, but Patshull Hall, 5 km south, is the
  likelier reading. Flagged rather than changed.
- HAM gives John "Warwick" Smith's dates as `1749 - 1851`. He died in 1831, so
  `death_year` for `personid` 28753 is twenty years out. Left as the API
  returns it; `00_people_supplements.R` corrects only the birthplace.

## Licence

Copyright © 2026 Luke Tan. All rights reserved. This repository is published for
reference and review only — no permission is granted to use, copy, modify or
redistribute it. See [LICENSE](LICENSE), and get in touch if you'd like to use
any of it.
