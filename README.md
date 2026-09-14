# ham-landscape-gis

Mapping where nineteenth-century landscape artists came *from* against where they
chose to *look* — built from the Harvard Art Museums collection API.

The pipeline in this repo produces three map layers for a set of 154 landscape
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
the title, the image and curatorial notes, and each one carries a `specificity`
grade recording how much weight the point can bear:

| `specificity` | Meaning | Count |
| --- | --- | --- |
| `2` | a named, identifiable view — a bridge, a harbour, a peak | 25 |
| `1` | a settlement, valley or estate | 18 |
| `0` | approximate; placed, but not a precise viewpoint | 21 |

A further 12 works name no locatable view at all. Their regional centroids sit in
a `region_coords` table that is deliberately **not** joined into the output —
mapping them would imply a precision the objects don't carry. Move a row up into
`depicted_coords` once a view has been identified.

`04_build_flow_lines.R` uses only the primary artist (`displayorder == 1`) and
only objects where both ends of the line are known, which is why the layers hold
48 objects and 40 birthplaces rather than all 154. Median birthplace-to-subject
distance across those lines is 267 km.

## Data

| File | Rows | Notes |
| --- | --- | --- |
| `data/ham_objects.csv` | 154 | one row per object; 149 resolved, 5 `NOT_FOUND` |
| `data/ham_people.csv` | 155 | one row per person–object link, with parsed birth/death years |
| `data/objects_with_coords.csv` | 154 | objects plus depicted location and `specificity` |
| `data/birthplace_coords.csv` | 67 | geocoded via OSM Nominatim |
| `data/deathplace_coords.csv` | 58 | geocoded via OSM Nominatim |
| `data/geojson/` | — | the three layers, EPSG:4326 |

Object and artist metadata is © President and Fellows of Harvard College,
retrieved through the Harvard Art Museums API. Geocodes are derived from
OpenStreetMap (ODbL).

### Known gaps

- Five accession numbers return `NOT_FOUND` — non-standard prefixes (`TL…`,
  `MS Typ…`, `5.2023…`) that the object endpoint doesn't resolve.
- Three hand-entered coordinates don't match any fetched object and are reported
  as a warning by `03_object_coords.R`: `2024.6`, `1898.8` (probably `2024.60`
  and `1898.80`) and `2001.77v` (a verso, which has no accession record of its own).
- `active_dates` in `ham_people.csv` flags artists whose display date is an
  activity period rather than birth–death; treat their `birth_year` accordingly.
- Nominatim resolves place names as written, so historical or superseded names
  may land on the modern settlement of the same name.

## Licence

Copyright © 2026 Luke Tan. All rights reserved. This repository is published for
reference and review only — no permission is granted to use, copy, modify or
redistribute it. See [LICENSE](LICENSE), and get in touch if you'd like to use
any of it.
