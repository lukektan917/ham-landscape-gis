# The exhibition catalogue as a source

`On Location: Drawing the Outdoors`, ed. Joachim Homann (Harvard Art Museums,
distributed by Yale University Press), ~312 pages. It is the catalogue of the
exhibition this project maps, and until now nothing in this repo drew on it.

It has a full text layer, so no OCR is needed:

```bash
pdftotext "On Location_3p_spreads.pdf" out.txt     # block mode, one caption per block
```

Use **block mode**, not `-layout`. The book is laid out as two-page spreads with
multi-column plate captions and a three-column biographies section; `-layout`
splices adjacent columns together mid-sentence and silently produces captions
that belong to two different objects.

## What was extracted

| File | Rows | Contents |
| --- | --- | --- |
| `data/catalogue_captions.csv` | 138 | plate captions: artist, title, date |
| `data/catalogue_biographies.csv` | 97 | artist biographies with life dates and documented movements |

138 of our 153 objects have a caption; 115 of those parsed cleanly (`parse_ok`).
The remaining 23 carry artist-name fragments at the front of the title and should
be read by eye before use. 92 captions carry a date.

Captions were parsed by bounding each one between consecutive accession numbers
and anchoring the start on the artist's surname from `ham_objects.csv`. Parsing
without that bound produces plausible-looking captions assembled from two
different objects — the failure is silent, so don't skip it.

## What the captions are worth: less than expected

The plate captions are **not** a better date source than the HAM API.

- They supply a year for exactly **one** object HAM leaves undated:
  `2023.542` → **1773–77** (HAM: "18th century"). Its `datebegin` should be 1773.
- Of 7 genuine date disagreements, HAM is **more** precise in 6 — it carries
  full dates (`1943.281` "September 12, 1864") where the catalogue prints only
  the year.
- One real conflict: `2023.547` *Fall of the Tritt near the Iron Foundries at
  Oberhasli* — HAM says **1776**, the catalogue says **1780–82**. Unresolved.

The other 13 century-only objects are undated in the catalogue too, which is
worth knowing: "19th century" is the state of knowledge, not an API gap.

Two titles differ substantively:

| Object | HAM | Catalogue |
| --- | --- | --- |
| `1943.345` | Mont St. Michel | **Tombelaine and the** Mont St. Michel |
| `1943.351` | A Woman Bathing and Her Moorish Servant | **Two Moroccan Women by a Stream** |

`1943.345` is graded `specificity` 1 on Mont-Saint-Michel. Tombelaine is the
islet north of it, so the catalogue title implies a viewpoint, not just a subject.

## What the biographies are worth: a great deal

`data/catalogue_biographies.csv` is the documented-whereabouts evidence that the
`biography` and `curatorial` rows in `03_object_coords.R` rest on and do not cite.
Checked against all ten inference-based placements:

**Confirmed (5 objects)**

- `1943.364` Géricault — *"Géricault spent time in London, enamored by the local
  equestrian culture and its imagery."* Our London placement holds.
- `1978.32`, `1972.312` Millet — *"moved from Paris to the village of Barbizon,
  near the Forest of Fontainebleau, in 1849 and remained there for the rest of
  his life."* Both sheets post-date 1849.
- `1985.74` Reinhart — *"moved to Rome in 1789 … a member of the international
  community of artists in Rome for almost six decades."*
- `2023.623` Palmer — *"gathered together in the country village of Shoreham,
  Kent, where Palmer created almost hallucinatory watercolors and drawings."*

**Not supported (1 object)**

- `1974.161` Pissarro, *Eclipse of the Sun*. The row is placed on St Thomas with
  the note "c. 1854, when Pissarro had returned to St Thomas". The catalogue's
  chronology names no such interval: *"established a studio with Danish artist
  Fritz Melbye in Caracas, Venezuela (1852–54), before returning to France in
  1855."* That does not disprove a St Thomas stop — he had to sail from
  somewhere — but the museum's own account places him in Caracas through 1854
  and in France from 1855, and the sheet is dated c. 1854 within a window of
  1849–1859. This was already the weakest placement in the set; it is weaker now.

**Neutral (4 objects)** — `1993.60` (Pontoise not mentioned), `1985.51` (no Harz),
`1943.296` (an England sojourn, no Cullercoats), `1919.506` (no Chamonix).

The biographies also carry structured birth and death places
(`St. Thomas, Danish W. Indies [now U.S. Virgin Islands] 1830–1903 Paris`), which
could cross-check the Nominatim geocoding in `data/birthplace_coords.csv`.

## The objects the API cannot resolve

`ham_objects.csv` carries five rows with `status = NOT_FOUND` and every other
field empty — one Houghton shelfmark and four temporary-loan numbers. A plain
accession regex (`19xx.n` / `18xx.n` / `20xx.n`) does not match either format, so
a search built on one will report them as absent rather than as unresolved.

Two are now identified from the catalogue, recorded in `catalogue_only` in
`03_object_coords.R`:

| Row | Work | Location |
| --- | --- | --- |
| `MS Typ 481` | Victor Marie Hugo, *Hauteville*, 1861 | Hauteville House, Saint Peter Port, Guernsey |
| `TL42858.1` | Gustave Doré, *Montreux* | Montreux, Vaud |

`MS Typ 481` is a **Houghton Library** shelfmark, not a HAM object — the HAM API
will never return it, however the query is written. The catalogue essay places
it: *"Hauteville House, his Guernsey residence, is in reality part of the densely
built historic Saint Peter Port."* `TL42858.1` confirms a guess already in
`region_coords`; the catalogue title is simply *Montreux*.

`TL42858.2`, `TL42852.4` and `TL42880` remain unmatched. Two catalogue works
carry no HAM accession and are the likely candidates: Eugène Isabey, *The Cliffs
of Varengeville in Full Sun* (Leventhal collection) and Francis Towne, *View of
the Cataract of the Mothvaye, Merionethshire, North Wales*, 1777.

None of the five can reach the map. `04_build_flow_lines.R` needs an artist
birthplace for one end of the line, and these rows carry no artist for
`02_geocode_places.R` to geocode.

### No HAM objects are missing

An earlier pass reported seven accessions in the catalogue absent from our 153.
That was wrong. Six were regex false positives — four are footnote markers
(`in June 1857.⁴⁰` → "1857.40") and two are *other museums'* accessions quoted in
an endnote (`2007.111.66` National Gallery of Art, `2008.613` the Metropolitan).
The seventh, "2023.7", is a truncation of `5.2023.7`, which we already hold.

## Still unmined

- **Five essays**, printed pp. 11–84, and **ten trail descriptions** across
  pp. 85–283. Roughly 75 pages of prose, untouched.
- The `Illustrated: cat. N` cross-references in the biographies map artists to
  plate numbers, which would let plate numbers be joined to accession numbers.

## Putting the catalogue works on the map

`00_catalogue_supplements.R` describes the three unresolvable works from the
catalogue — objects from the plate captions, artists from the Artist
Biographies — so they can travel through the pipeline like any other row. They
carry `basis = "catalogue"` and `birthplace_source = "catalogue"`, so a
catalogue-sourced placement is never silently mixed with a museum-sourced one.

Only one new birthplace needed geocoding (Strasbourg, for Doré); Besançon and
Paris were already in `birthplace_coords.csv`. It was geocoded on its own, and
the file diffed against a backup before committing — see the warning in
`CLAUDE.md`. The three new depicted coordinates were geocoded too, which makes
them the only rows in `depicted_coords` that were not entered by hand.

Hugo already had a HAM people row from his sheet `2021.51`, so he has two rows
in `people` — one per object. The birthplace layer collapses them to one point.

### Biographies on the birthplace layer

`04_build_flow_lines.R` joins the biography text onto `birthplace_points` as
`biography` and `biography_life`. Two things about that join are load-bearing:

- **It matches on surname *and* first forename.** The catalogue holds two Hunts
  (William Henry, William Holman) and two Varleys (John, Cornelius). A
  surname-only join silently gives one brother the other's life story. A
  surname-only match is still used where the surname is unique, which catches
  names carrying a particle.
- **Three entries had to be repaired.** Where the three-column layout runs two
  headers together, the parser read `HeaderA HeaderB BodyA` and attached A's
  body to B — so Teerlink was given Seurat's biography, Cross was given
  Courbet's, and Cole was given Brondgeest's. Splitting the shared region on its
  `Illustrated:` marker restored Brondgeest, Courbet and Seurat. Cole, Cross and
  Teerlink are now empty rather than wrong; only Cole reaches the map.

## What this changed in the pipeline

| Change | Where |
| --- | --- |
| `1974.161` *Eclipse of the Sun* demoted from `depicted_coords` to `candidate_coords` | `03_object_coords.R` |
| `2023.542` dated 1773–77 via a new `catalogue_dates` override | `03_object_coords.R` |
| `TL42858.1` identified as Doré's *Montreux*, graded `specificity` 1 | `03_object_coords.R` |
| `MS Typ 481` and the three unmatched loans recorded in a new `catalogue_only` table | `03_object_coords.R` |
| Four `biography` / `curatorial` rows now cite the catalogue in their comments | `03_object_coords.R` |
| `1943.345` annotated with the catalogue's *Tombelaine* title | `03_object_coords.R` |

| The three catalogue works added to the map via `00_catalogue_supplements.R` | new file, `03`, `04` |
| `biography` / `biography_life` added to the birthplace layer | `04_build_flow_lines.R` |

Layer counts after the rebuild: **71** objects, **58** birthplaces, 71 flow
lines (was 77 / 61 / 77 before any of this). `catalogue` adds 3 placements.
53 of the 58 birthplaces carry a biography.

## Postscript: the inference-based placements came off the map

The biographies were gathered to shore up the `biography` and `curatorial`
placements, and they did — the catalogue confirms Géricault in London, Millet
at Barbizon, Reinhart in Rome, Palmer at Shoreham. But confirming where an
artist *lived* is a different claim from establishing what a sheet *depicts*,
and the eight placements built on that reasoning have since been moved to
`candidate_coords`. The research is recorded there; the points are off the map.

The effect on the data is worth noting: median birthplace-to-subject distance
rose from 312 km to **378 km**. Those placements were systematically short,
because a work placed where its artist was living sits near that artist's
birthplace more often than not — `1974.161` was the extreme case, a flow line
of 0.0 km. Removing them took out a set of short lines the method had
manufactured rather than found.
