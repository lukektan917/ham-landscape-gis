# Working in this repo

R pipeline that maps Harvard Art Museums landscape works: where the artist was born,
where the work looks at, and the line between. `README.md` explains the data and the
grading scheme — read it first. This file is only about not breaking things.

## Running the pipeline

`00_config.R` → `01` → `02` → `03` → `04`. Run from the repo root with `Rscript`.
The API key lives in `~/.Renviron` as `HAM_APIKEY`; never print or echo it.

| Script | Cost | Re-run freely? |
| --- | --- | --- |
| `01_fetch_ham.R` | ~90s, 153 API calls | Yes |
| `02_geocode_places.R` | ~2 min, Nominatim | **No — see below** |
| `03_object_coords.R` | instant, pure | Yes |
| `04_build_flow_lines.R` | instant, pure | Yes |

### Never re-run 02 casually

`02` geocodes against OSM Nominatim, which allows **1 request/second and no
concurrency**. Its outputs (`data/birthplace_coords.csv`, `data/deathplace_coords.csv`)
are committed and complete — 72/72 and 58/58. There is no reason to regenerate them
unless a birthplace or deathplace *string* changed in `ham_people.csv`.

Running anything else against Nominatim while `02` is in flight gets the whole session
rate-limited: it has already happened once here, and `deathplace_coords.csv` silently
degraded from 55 to 45 resolved rows before anyone noticed. If you must re-run it, run
it **alone**, and diff the output against `git show HEAD:data/deathplace_coords.csv`
before committing.

Re-running `01` rewrites `ham_people.csv`, so check it is byte-identical afterwards
(`diff`) — if it is, `02`'s outputs are still valid and you can skip straight to `03`.

## Before trusting a refetch

HAM changes its records. After any `01` re-run, diff against the previous CSV and
confirm the only changes are ones you meant to make:

```bash
git stash && cp data/ham_objects.csv /tmp/baseline.csv && git stash pop
```

Then compare field by field, not just row counts. A real example: HAM renamed `1999.12`
from "Mountainous Landscape with a Volcano" to "Mount Vesuvius" and demoted the old name
to a `Former Title`, which silently invalidated that row's `basis`.

## The hand-maintained tables in 03

`depicted_coords` is the heart of the project and is edited by hand. Three things that
are not obvious from reading it:

- **The `title` column is a label, not data.** Only `objectnumber`, `depicted_loc`,
  `latitude`, `longitude`, `specificity` and `basis` are joined out. Titles in the
  tribble exist so a human can read the table; the real title comes from
  `ham_objects.csv`. A stale one there is untidy but harmless.
- **`region_coords` and `candidate_coords` are deliberately not joined.** They hold
  works too vague to place and works with an unconfirmed location in the literature.
  Promoting a row means moving it into `depicted_coords` *with a `basis`*.
- **The validation warnings are real.** `03` warns on duplicate object numbers,
  on `biography`/`curatorial` rows graded above `specificity` 1, and on rows graded
  `alt_title` with no alternative title left in the record. Don't silence them; each
  one has caught a genuine error.

## Conventions

- `alt_title` / `alt_title_type` are `" | "`-separated and positionally parallel. The
  separator is **not** `"; "` because a single title can contain a semicolon
  (`1962.42`: "La Montagne Sacrée; The Sacred Mountain").
- Non-ASCII is everywhere (Grüngiebing, Faÿ, Éragny). Write files as UTF-8 and never
  round-trip them through a shell heredoc that might ASCII-ize them — use Python with
  explicit `encoding="utf-8"`.
- HAM carries a two-sided sheet as **one** object, with the verso named inside the
  title string. Same accession number, one row. Two rows sharing an accession number
  is always a bug, never a recto/verso pair.

## ArcGIS Online deployment

Three hosted feature layers in the `harvard-cga` org, owned by `lut688_Harvard_CGA`,
consumed by a Web Map and a Web Experience. Item IDs are in the item URLs; they are
not secrets, but the layers' sharing state is.

**`ARCGIS.md` is the procedure** — how to empty a layer with the REST API's
`deleteFeatures`, what to create before refilling, and a record of what was
actually run. What follows here is only the list of things that go wrong.

Traps, all learned the hard way:

- **Use a clean browser.** The owner's Chrome profile has an extension that breaks
  ArcGIS Online modals — they fail to render with
  `TypeError: Cannot read properties of null (reading 'appendChild')`, and
  "Update data" silently routes into the *create new item* wizard, which would publish
  a duplicate layer. Everything works in a stock Chromium.
- **Appending cannot create fields.** Fields must exist in the layer *before* the data
  arrives, or the values are dropped silently. This is why `specificity` and `basis`
  sat empty through an entire append cycle.
- **"Update features" needs a unique index** on the match field. `objectnumber` has
  none by default, so only `GlobalID`/`ObjectId` are offered — neither of which exists
  in the GeoJSON.
- **"Overwrite entire feature layer" is greyed out** for these layers.
- **`Date_DT` is an ArcGIS-side date field** derived from `datebegin`. It cannot
  survive a GeoJSON load and must be recalculated afterwards.
- **Never enable "public data collection"** to get editing on a shared layer. It allows
  anonymous internet edits to a Harvard-hosted asset. Unshare → edit → re-share instead.
- **A new text field defaults to 255 characters.** `biography` on the birthplace layer
  runs to 949, and 58 of its 63 rows are over 255, so a field created at the default
  silently truncates almost every one. Create `biography` with a length of at least
  1000 and `biography_life` at 255 before loading — and remember appending cannot
  create fields, so both must exist first or the column arrives empty.

### Current state (2026-11-08)

The pipeline now exports **74 objects, 61 birthplaces, 74 flow lines**, all three
verified free of duplicate accession numbers. Nothing on the map rests on
an artist’s whereabouts: `basis` `biography` no longer appears, and those five
objects sit in `candidate_coords`. `curatorial` placements stay, each resting
on a published identification of that sheet. Median distance is 314 km.

`data/geojson/` holds the current files under their committed names; the
`*_116.geojson` copies beside them are stale renamed exports from an earlier
upload and can go once ArcGIS is refreshed.

ArcGIS has not been updated since the catalogue work. All three hosted layers are
behind, and two things changed shape:

- `birthplace_points` gained `biography` and `biography_life` — create both before
  loading, at the lengths noted above.
- `objects_points` and `flow_lines` gained `date_mid` (Integer),
  `date_is_approx` (String or Integer — GeoJSON booleans land as whichever the
  loader picks, so check after the first load), plus, on `objects_points`
  only, `trail` (Integer) and `trail_title` / `trail_label` (String, 100;
  longest values 57 and 68). A trail belongs to a work, not to an artist —
  Ruskin's sit in 3, 7 and 10 — so neither the birthplace nor the line layer
  carries one.
- `basis` has a new value, `catalogue`, on three objects. No new field, but any
  renderer or filter keyed on `basis` needs the extra category.

`date_mid` is never null, which simplifies the `Date_DT` calculation to a single
line with no guard:

```
Date(Floor($feature.date_mid), 0, 1, 12, 0, 0)
```

Month 0 is January and the 12 is noon — ArcGIS renders in UTC and applies a local
mean time offset to pre-1900 dates, so a midnight 1 January displays as 31 December
of the previous year. Filter on `date_is_approx` to show or hide the 15 objects
whose year is a century midpoint rather than a record.

`objects_points_76` was last left unshared with editing enabled and duplicate rows.
Rebuilding it from the current export clears that.
