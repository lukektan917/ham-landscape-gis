# ─────────────────────────────────────────────────────────────────────────────
# 03_object_coords.R
# Attaches a depicted location (the place the artwork shows, not where it is
# held) to every object fetched by 01_fetch_ham.R.
#
# Coordinates are assigned by hand from the object title, image and curatorial
# notes, then graded on two axes:
#
#   specificity – how tightly the view can be pinned
#     2 – a named, identifiable view (a bridge, a harbour, a peak)
#     1 – a settlement, valley or estate
#     0 – approximate; the object is placed but should not be read as a
#         precise viewpoint
#
#   basis – what the placement rests on, so a reader can weigh it
#     title          – the HAM title names the place
#     alt_title      – a HAM alternative title names it. The alternative titles
#                      themselves ride along in the `alt_title` /
#                      `alt_title_type` columns from 01_fetch_ham.R, so a
#                      reader can see the evidence rather than take it on
#                      trust — and so can see the alternative titles carried
#                      by objects placed on some other basis.
#     description    – the HAM description or curatorial note names it
#     creation_place – the HAM `places` record names it
#     biography      – the artist's documented location at the work's date
#     curatorial     – an identification argued from a related work or source
#
# `title`, `alt_title`, `description` and `creation_place` are backed by the
# museum's own record. `biography` and `curatorial` are inference, and no such
# row is graded above specificity 1.
#
# Input : data/ham_objects.csv
# Output: data/objects_with_coords.csv
# ─────────────────────────────────────────────────────────────────────────────

library(tidyverse)

source("00_catalogue_supplements.R")

# ── Load objects from 01_fetch_ham.R ──────────────────────────────────────────
# Catalogue supplements fill the NOT_FOUND rows the API cannot describe; every
# API-sourced field is left untouched. Adds `record_source`.
objects_df <- read_csv("data/ham_objects.csv", show_col_types = FALSE) |>
  apply_catalogue_objects()

# ── Dates the exhibition catalogue supplies and the API does not ─────────────
# The catalogue is NOT generally a better date source — where the two disagree
# HAM is usually more precise, carrying full dates ("September 12, 1864") where
# the catalogue prints only a year. This table is only for objects HAM leaves
# undated (datebegin 0). See CATALOGUE.md.
catalogue_dates <- tribble(
  ~objectnumber, ~dated,     ~datebegin, ~dateend,
  "2023.542",    "1773-77",  1773L,      1777L
)

objects_df <- objects_df |>
  rows_update(catalogue_dates, by = "objectnumber", unmatched = "ignore")

# ── Depicted locations ────────────────────────────────────────────────────────
depicted_coords <- tribble(
  ~objectnumber, ~title,                                                                    ~depicted_loc,                                               ~latitude,  ~longitude,  ~specificity, ~basis,
  "1962.42",   "Parahi te marae (There Is the Temple)",                                   "Tahiti, French Polynesia",                                    -17.650,  -149.430,  2L, "title",
  "1919.47",   "Falls of Schaffhausen",                                                   "Rhine Falls, Neuhausen am Rheinfall, Switzerland",             47.677,     8.616,  2L, "title",
  "1943.395",  "Landscape, Eragny",                                                       "Éragny-sur-Epte, Oise, France",                                49.315,     1.775,  2L, "title",
  "1991.25",   "Study in the Forest of Fontainebleau",                                    "Forest of Fontainebleau, Seine-et-Marne, France",              48.407,     2.702,  1L, "title",
  "2011.90",   "Baths of Trajan, Rome",                                                   "Baths of Trajan, Oppian Hill, Rome, Italy",                    41.889,    12.498,  2L, "title",
  "2023.538",  "The Pond, Honfleur, France",                                              "Honfleur, Calvados, Normandy, France",                         49.419,     0.232,  2L, "title",
  "2023.547",  "Fall of the Tritt near the Iron Foundries at Oberhasli",                  "Oberhasli valley, Bern canton, Switzerland",                   46.706,     8.228,  1L, "title",
  "2021.513",  "No 566 Menai Suspension Bridge From the Beach on the Anglesea Side",      "Menai Bridge, Anglesey, Wales",                                53.224,    -4.162,  2L, "title",
  "2021.516",  "The Porch at East Bergholt Church, Suffolk",                              "East Bergholt, Suffolk, England",                              51.970,     1.014,  2L, "title",
  "1993.231",  "Hat, Shoes and Undergarments (Study for 'Une baignade, Asnières')",       "Asnières-sur-Seine, Hauts-de-Seine, France",                   48.915,     2.286,  2L, "title",
  "R3740",     "Tomb of Jean Jacques Rousseau",                                           "Île des Peupliers, Ermenonville, Oise, France",                49.130,     2.712,  2L, "title",
  "1912.329",  "Illustration with music for 'On the Ancient Walls of Venice'",            "Venice, Veneto, Italy",                                        45.434,    12.338,  1L, "title",
  "2021.51",   "Pyramids",                                                                "Giza Necropolis, Egypt",                                       29.979,    31.134,  1L, "title",
  "1943.515",  "Peasant of the Camargue",                                                 "Camargue, Bouches-du-Rhône, France",                           43.500,     4.600,  1L, "title",
  "1898.80",   "View of the Riverbank, the Frauenkirche...Dresden",                       "Elbe riverbank, Dresden, Germany",                             51.053,    13.741,  1L, "title",
  "8.2023",    "Observations on the coasts of Hampshire, Sussex & Kent",                  "Hampshire coast, England",                                     50.800,    -1.300,  0L, "description",
  "2007.226",  "Church Ruins in Bergen(?)",                                               "Bergen, Vestland, Norway (uncertain)",                         60.390,     5.320,  0L, "title",
  "1994.184",  "Burned-out Building in Holstein",                                         "Holstein, Schleswig-Holstein, Germany",                        54.000,    10.000,  0L, "title",
  "1979.131",  "Cascade de Lys",                                                          "Cascade d'Enfer, France",                                      42.732,     0.551,  0L, "title",
  "2005.251",  "San Arcangelo",                                                           "Sant'Arcangelo, Cava de' Tirreni, Campania, Italy",            40.697,    14.693,  0L, "title",
  "2024.223",  "Rocca Pia Castle in Tivoli",                                              "Rocca Pia Castle, Tivoli, Lazio, Italy",                       41.960,    12.798,  0L, "title",
  "1965.247",  "View of Mount Soracte from Civita Castellana",                            "Monte Soratte, near Sant'Oreste, Lazio, Italy",                42.250,    12.500,  0L, "title",
  "2023.528",  "Church of Tamins opposite Reichenau, Switzerland",                        "Evangelisch-reformierte Kirche Tamins, Graubünden, Switzerland",    46.829,     9.408,  0L, "title",
  "2023.542",  "Fall of the Tritt in the Mühlethal Valley, Switzerland",                  "Mühlethal Valley, Innertkirchen, Bern, Switzerland",           46.705,     8.227,  0L, "title",
  "2023.543",  "The Ruins of Geiersberg Castle in Bohemia",                               "Kyšperk (Geiersburg) Castle, Krupka, Czechia",                 50.696,    13.890,  0L, "title",
  "1907.6",    "Stirling Castle",                                                         "Stirling Castle, Stirling, Scotland",                          56.124,    -3.947,  0L, "title",
  "1943.687",  "Brighton Beach, with a Horse Turning a Capstan",                          "Brighton Beach, East Sussex, England",                         50.820,    -0.138,  0L, "title",
  "2021.517",  "At Parton Hall, Staffordshire",                                           "Wrottesley Hall, Staffordshire, England",                      52.613,    -2.223,  0L, "curatorial",
  "2023.488",  "Page's Farm, Easton Park, Essex",                                         "Page's Farm, Little Easton, Essex, England",                   51.874,     0.322,  0L, "title",
  "2023.489",  "Entrance into Easton Park from Dunmont",                                  "Easton Park, Great Dunmow, Essex, England",                    51.873,     0.362,  0L, "title",
  "2024.59",   "Evening View near the Thames in Lambeth, London",                         "Thames riverside, Lambeth, London, England",                   51.499,    -0.121,  0L, "title",
  "2024.60",   "Figures on the Shore, looking out to Sea, Penmaen Beach, North Wales",    "Penmaenmawr Beach, Conwy, North Wales",                        53.268,    -3.920,  0L, "title",
  "1979.111",  "Rocky Gorge, Via Mala",                                                   "Viamala Gorge, Hinterrhein River, Graubünden, Switzerland",    46.663,     9.449,  0L, "title",
  "2023.56",   "The Interior of the Colosseum, Rome",                                     "Colosseum, Rome, Italy",                                       41.890,    12.492,  0L, "title",
  "2026.65",   "View of the Cataract of the Mothvaye, Merionethshire, North Wales",       "Maesglase Waterfall, Merionethshire, North Wales",             52.714,    -3.725,  0L, "title",
  "1943.387",  "Race Course at Longchamp; verso: Section of grandstand area",             "Hippodrome de Longchamp, Paris, France",                       48.855,     2.234,  0L, "title",
  "1943.393",  "Boats (Entry of the Midina to the Isle of Wight)",                        "River Medina, Cowes, Isle of Wight, England",                  50.758,    -1.292,  0L, "title",
  "1999.12",   "Mount Vesuvius",                                                          "Mount Vesuvius, near Naples, Italy",                           40.821,    14.427,  1L, "title",
  "2001.77",   "Fountain Near the Hill of Montmartre",                                    "Butte Montmartre area, Paris, France",                         48.887,     2.343,  1L, "title",
  "2007.139",  "Entrance to the Baumannshöhle in the Harz Mountains",                     "Baumannshöhle, Rübeland, Harz Mountains, Germany",             51.755,    10.843,  1L, "title",
  "1943.281",  "Honfleur Harbor",                                                         "Honfleur harbour, Calvados, Normandy, France",                 49.419,     0.232,  1L, "title",
  # Catalogue titles it "Tombelaine and the Mont St. Michel". Tombelaine is the
  # islet 3 km north, so the sheet shows both from the bay rather than the Mount
  # alone. Kept at the Mount: a view containing both does not pin a viewpoint.
  "1943.345",  "Mont St. Michel",                                                         "Mont-Saint-Michel, Normandy, France",                          48.636,    -1.512,  1L, "title",
  "2023.522",  "Panoramic View of Grindelwald with View of Finsteraarhorn and both Grindelwald Glaciers", "Grindelwald, Bernese Oberland, Switzerland",                   46.624,     8.041,  1L, "title",
  "2023.529",  "View of the City of Zürich from Present Day Seefeld",                     "Seefeld lakeside quarter, Zürich, Switzerland",                47.355,     8.551,  1L, "title",
  "1898.23",   "View of Olevano; verso: Landscape",                                       "Olevano Romano, Lazio, Italy",                                 41.853,    13.040,  1L, "title",
  "1898.84",   "Panorama from a Lookout at Borsberg",                                     "Borsberg Lookout, near Dresden, Germany",                      51.022,    13.898,  1L, "title",
  "1943.686",  "The Gardens at Stourhead",                                                "Stourhead gardens, Stourton, Wiltshire, England",              51.105,    -2.315,  1L, "title",
  "1954.133",  "Simplon Pass",                                                            "Simplon Pass summit, Valais, Switzerland",                     46.250,     8.032,  1L, "title",
  "TL42852.4", "Hauteville",                                                              "Hauteville House, Guernsey",                                   49.451,    -2.538,  1L, "title",
  "1903.49",   "Devonport and Dockyard, Devonshire",                                      "Devonport Dockyard, Plymouth, Devon, England",                 50.374,    -4.184,  2L, "title",
  "2004.73",   "A Willow Tree on the Prater Island in Munich, with the Quellwasser Footbridge and the Hospital on the Opposite Bank of the Isar River", "Praterinsel, Munich, Germany",                                 48.136,    11.591,  2L, "title",
  "2022.225",  "Above Lyme Regis, looking across Marshwood Vale, Dorset",                 "Lyme Regis, Dorset, England",                                  50.735,    -2.942,  2L, "title",
  "1943.517",  "Abbeville",                                                               "Abbeville, Somme, Hauts-de-France, France",                    50.106,     1.835,  2L, "title",
  "1977.173",  "Mont Sainte-Victoire",                                                    "Mont Sainte-Victoire, near Aix-en-Provence, France",           43.526,     5.561,  2L, "title",
  "1999.247",  "View Near Nemi",                                                          "Countryside near Lake Nemi, Lazio, Italy",                     41.703,    12.707,  2L, "title",
  # Placed here before the catalogue was read; the catalogue confirms the title
  # and lender. `basis` corrected from "title" to "catalogue" — HAM holds no
  # record for this loan, so the title naming the cliffs is the catalogue's,
  # not the museum's. Coordinate regeocoded (was 49.901, 0.980 by hand).
  "TL42858.2", "The Cliffs of Varengeville in Full Sun",                                  "Varengeville-sur-Mer, Seine-Maritime, France",                 49.905,     1.002,  2L, "catalogue",
  "2023.518",  "Study of a Wooded Hillside near Weesen",                                  "Weesen area, Walensee, Switzerland",                           47.133,     9.094,  2L, "title",
  "1943.533",  "Barns in Interlaken",                                                     "Interlaken, Bernese Oberland, Switzerland",                    46.686,     7.863,  2L, "title",
  "1959.113",  "View of Amalfi",                                                          "Amalfi, Amalfi Coast, Campania, Italy",                        40.634,    14.602,  2L, "title",
  "1943.283",  "Windmills close to Rotterdam",                                            "Rotterdam, South Holland, Netherlands",                        51.916,     4.399,  2L, "title",
  "1951.143",  "Winter (The Plain of Chailly)",                                           "Chailly-en-Bière, Forest of Fontainebleau, France",            48.468,     2.608,  2L, "title",
  "1934.203",  "The Fishing Boats at Scheveningen",                                       "Scheveningen, The Hague, Netherlands",                         52.108,     4.275,  2L, "title",
  "1943.314",  "Olive Trees, Corfu",                                                      "Corfu, Ionian Islands, Greece",                                39.451,    19.979,  2L, "title",
  "2025.321",  "Leuvehave, Rotterdam (seen from the Leuvebrug on the Zeevischmarkt)",     "Rotterdam, Netherlands",                                       51.915,     4.483,  2L, "title",
  "2025.362",  "Harvest Time near Holmbury Hill, Surrey",                                 "Holmbury Hill, Surrey, England",                               51.176,    -0.423,  2L, "title",
  # HAM alternative title: "Boulder at Chamonix"
  "1919.506",  "Fragment of the Alps",                                                    "Chamonix valley, Haute-Savoie, France",                        45.923,     6.870,  1L, "alt_title",
  # HAM alternative title: "Landscape (George Sand’s Garden at Nohant)"
  "2023.252",  "Forest Clearing",                                                         "Nohant-Vic, Indre, France",                                    46.638,     1.959,  2L, "alt_title",
  # HAM alternative title: "Harvest at La Crau"; study for The Harvest, Arles, June 1888
  "1943.279",  "The Blue Cart",                                                           "Plain of La Crau toward Montmajour, Arles, France",            43.695,     4.683,  1L, "alt_title",
  # HAM alternative title: "Children Playing in the Water at Scheveningen"
  "1934.201",  "Children of the Sea",                                                     "Scheveningen, The Hague, Netherlands",                         52.107,     4.274,  2L, "alt_title",
  # HAM alternative title locates it "au Faÿ [Berri]"; Le Faÿ is now in the commune of Parnac
  "1943.917",  "Great Oak",                                                               "Le Faÿ, Parnac, Indre, France",                                46.453,     1.442,  1L, "alt_title",
  # Only object in the set with a HAM places entry: "Europe, United Kingdom, England, Newcastle"; Homer resident at Cullercoats 1881-82
  "1943.296",  "Watching the Tempest",                                                    "Cullercoats, North Tyneside, England",                         55.035,    -1.434,  1L, "creation_place",
  # Dated c. 1826-27, the years Palmer settled at Shoreham
  "2023.623",  "A Cornfield with Windmill and Spire seen under a Crescent Moon",          "Shoreham, Kent, England",                                      51.334,     0.179,  1L, "biography",
  # Sheet dated 24 June 1811; HAM cites Zschoche, Caspar David Friedrich im Harz. Placed on the Brocken as a range centroid
  "1985.51",   "Landscape Studies",                                                       "Harz Mountains, Germany",                                      51.799,    10.616,  0L, "curatorial",
  # Catalogue biography: "Géricault spent time in London, enamored by the local
  # equestrian culture and its imagery." Subject of his lithograph The Coal
  # Waggon, published London, 1 Feb 1821.
  "1943.364",  "Coal Wagon Hauled by Seven Horses",                                       "London, England",                                              51.516,    -0.092,  0L, "curatorial",
  # c. 1851-52. Catalogue biography: Millet "moved from Paris to the village of
  # Barbizon, near the Forest of Fontainebleau, in 1849 and remained there for
  # the rest of his life."
  "1978.32",   "The Month of August: The Gleaners",                                       "Plain of Chailly, near Barbizon, France",                      48.458,     2.615,  0L, "biography",
  # c. 1852-56; same catalogue biography as 1978.32
  "1972.312",  "Landscape with Sheep",                                                    "Barbizon, Seine-et-Marne, France",                             48.445,     2.606,  0L, "biography",
  # 1881-82, Pissarro at Pontoise until late 1882; no view named. The catalogue
  # biography does not mention Pontoise — this rests on the standard chronology.
  "1993.60",   "Two Peasant Women",                                                       "Pontoise, Val-d’Oise, France",                                 49.051,     2.101,  0L, "biography",
  # c. 1800. Catalogue biography: Reinhart "moved to Rome in 1789 ... a member of
  # the international community of artists in Rome for almost six decades."
  "1985.74",   "Artist Sketching beneath Spreading Trees",                                "Rome, Italy",                                                  41.893,    12.483,  0L, "biography",
  # ── Works the HAM API cannot describe; records from 00_catalogue_supplements.R
  # Unlike every row above, these three coordinates were GEOCODED (Nominatim,
  # same source as the birthplaces) rather than entered by hand.
  # Hugo's title is the house itself; the catalogue essay confirms the setting:
  # "Hauteville House, his Guernsey residence, is in reality part of the densely
  # built historic Saint Peter Port."
  "MS Typ 481","Hauteville",                                                              "Hauteville House, Saint Peter Port, Guernsey",                 49.451,    -2.538,  2L, "catalogue",
  # Catalogue title is simply "Montreux"; point is the town, not a view in it
  "TL42858.1", "Montreux",                                                                "Montreux, Vaud, Switzerland",                                  46.431,     6.913,  1L, "catalogue"
)

# ── Region-level placements — not joined ──────────────────────────────────────
# These works name no locatable view ("Umbrian Landscape", "Italian Landscape").
# The coordinates below are regional centroids kept for reference only; mapping
# them as points would imply a precision the objects do not carry.
# Move a row into `depicted_coords` above once a view has been identified.
region_coords <- tribble(
  ~objectnumber, ~title,                                       ~depicted_loc,                                  ~latitude, ~longitude, ~specificity,
  "32.1979",     "Moonlit Normandy Coast",                     "Normandy coast, France",                          49.500,      0.500, 0L,
  "1985.47",     "Umbrian Landscape",                          "Umbria, Italy",                                   43.100,     12.400, 0L,
  "1998.182",    "Italian Mountain Scene with Stream",         "Northern Italian Alps",                           46.000,     11.000, 0L,
  "2023.511",    "Mountain Torrent in a Storm",                "Swiss Alps",                                      46.500,      8.000, 0L,
  "2023.533",    "Waterfall Cascading Down a Mountain",        "Swiss Alps",                                      46.700,      8.100, 0L,
  "2023.532",    "Forested Landscape below an Italian Village","Central Italy",                                   43.000,     12.000, 0L,
  "1991.228",    "Italian Coastal Landscape",                  "Tyrrhenian coast, Italy",                         43.000,     10.800, 0L,
  "1964.15.15",  "Mediterranean Landscape",                    "Mediterranean coast",                             43.500,      5.500, 0L,
  "1964.15.10",  "Mediterranean Landscape with Olive Trees",   "Mediterranean coast",                             43.500,      5.600, 0L,
  "2023.534",    "Street Scene in Italy",                      "Italy (unspecified)",                             41.900,     12.500, 0L,
  # Both carry the HAM alternative title "Italian Landscape" and name no view.
  "1965.287",    "Study for \"Landscape with Fishermen\"",     "Italy (unspecified)",                             41.900,     12.500, 0L,
  "1943.469",    "Landscape with Cow, Three Figures, and Buildings", "Italy (unspecified)",                       41.900,     12.500, 0L
)

# ── Researched but not placed — not joined ────────────────────────────────────
# Each of these has a plausible location in the literature that this project
# could not confirm to the standard the `basis` grades above require. They are
# recorded so the research is not lost and the next pass starts here rather
# than from scratch. Promote a row into `depicted_coords` with a `basis` once a
# source pins it.
candidate_coords <- tribble(
  ~objectnumber, ~title,                               ~candidate_loc,                    ~why_not_placed,
  "1943.295",    "The Bathers",                        "Dalarö, Stockholm archipelago",   "Sources put Zorn's bather subjects at Dalarö from 1887 or 1888; the 1887 date straddles the disagreement",
  "1979.348",    "Study for \"Hind Forced Down in the Snow\"", "Franche-Comté / Jura",    "Courbet hunted in Franche-Comté, but the literature treats the stag pictures as studio recompositions, not views",
  "1974.170",    "Large Pine, Study",                  "Montbriand, Aix-en-Provence",     "The Montbriand identification belongs to the related oils, not to this sheet",
  "1943.284",    "The Old Ploughman",                  "Laren, North Holland",            "Mauve worked at both The Hague and Laren; HAM dates the sheet only to '19th century'",
  "1943.520",    "A Shepherdess with Her Flock",       "Laren, North Holland",            "Same as 1943.284 — no date narrow enough to choose between Mauve's two bases",
  "1943.341",    "Promenaders on the Beach",           "Trouville-sur-Mer, Calvados",     "Boudin's 1860s beach scenes are overwhelmingly Trouville/Deauville, but HAM dates this '1867(?)' and names no beach",
  "1926.33.142", "A Landscape with a Church Tower and a House", "Dedham Vale, Suffolk",   "Constable worked at East Bergholt in 1809 but also at Epsom and Malvern Hall; the title names no view",
  "1943.536",    "Linen Bleachers",                    "Bavaria",                         "Menzel's summer travels in 1886 are documented, but nothing ties this sheet to one of them",
  # Demoted from `depicted_coords` after checking the exhibition catalogue.
  "1974.161",    "Eclipse of the Sun",                 "Charlotte Amalie, St Thomas",     "Was placed on St Thomas as Pissarro's documented location c. 1854. The catalogue biography names no such interval — 'a studio with Fritz Melbye in Caracas, Venezuela (1852-54), before returning to France in 1855' — and HAM's date window is 1849-1859, which also covers Venezuela and France"
)

# ── Loans still unidentified — not joined ────────────────────────────────────
# Of the five NOT_FOUND accessions, three are now described in
# 00_catalogue_supplements.R and placed above. These two are not: no catalogue
# work can be tied to either number. Every plate in the book is otherwise
# accounted for, so they are probably works shown without a plate, or withdrawn
# from the final checklist. HAM's exhibition checklist is the source that would
# settle it.
unidentified_loans <- c("TL42852.4", "TL42880")

# ── Join by objectnumber ──────────────────────────────────────────────────────
objects_with_coords <- objects_df |>
  left_join(
    select(depicted_coords, objectnumber, depicted_loc, latitude, longitude,
           specificity, basis),
    by = "objectnumber"
  )

# ── Report ────────────────────────────────────────────────────────────────────
unmatched <- setdiff(depicted_coords$objectnumber, objects_df$objectnumber)
if (length(unmatched) > 0)
  warning("Coordinates given for objectnumbers absent from ham_objects.csv: ",
          paste(unmatched, collapse = ", "))

dupes <- depicted_coords$objectnumber[duplicated(depicted_coords$objectnumber)]
if (length(dupes) > 0)
  warning("Duplicate objectnumbers in depicted_coords: ", paste(dupes, collapse = ", "))

overgraded <- depicted_coords |>
  filter(basis %in% c("biography", "curatorial"), specificity > 1)
if (nrow(overgraded) > 0)
  warning("Inferred placements graded above specificity 1: ",
          paste(overgraded$objectnumber, collapse = ", "))

# A row graded `alt_title` must actually have an alternative title in the
# museum record. This catches the case where HAM promotes a former alternative
# to the primary title — 1999.12 was "Mountainous Landscape with a Volcano"
# with "Mount Vesuvius" as the alternative, and is now the other way round.
alt_basis <- objects_with_coords |>
  filter(basis == "alt_title", is.na(alt_title))
if (nrow(alt_basis) > 0)
  warning("Graded `alt_title` but HAM lists no alternative title: ",
          paste(alt_basis$objectnumber, collapse = ", "))

cat(sprintf("Objects            : %d\n", nrow(objects_with_coords)))
cat(sprintf("  with coordinates : %d\n", sum(!is.na(objects_with_coords$latitude))))
cat(sprintf("  region-level only: %d\n", nrow(region_coords)))
cat(sprintf("  researched only  : %d\n", nrow(candidate_coords)))
cat("\nBy basis:\n")
depicted_coords |> count(basis, sort = TRUE) |> pwalk(\(basis, n) cat(sprintf("  %-15s %d\n", basis, n)))
cat(sprintf("\nPlaced objects with an alternative title: %d\n",
            sum(!is.na(objects_with_coords$alt_title) &
                !is.na(objects_with_coords$latitude))))
cat("\nBy specificity:\n")
depicted_coords |> count(specificity) |> pwalk(\(specificity, n) cat(sprintf("  %-15d %d\n", specificity, n)))

# ── Save ──────────────────────────────────────────────────────────────────────
write_csv(objects_with_coords, "data/objects_with_coords.csv")
cat("\nSaved: data/objects_with_coords.csv\n")
