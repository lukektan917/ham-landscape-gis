# ─────────────────────────────────────────────────────────────────────────────
# 03_object_coords.R
# Attaches a depicted location (the place the artwork shows, not where it is
# held) to every object fetched by 01_fetch_ham.R.
#
# Coordinates are assigned by hand from the object title, image and curatorial
# notes, then graded by how confidently the view can be pinned:
#   specificity 2 – a named, identifiable view (a bridge, a harbour, a peak)
#   specificity 1 – a settlement, valley or estate
#   specificity 0 – approximate; the object is placed but should not be read
#                   as a precise viewpoint
#
# Input : data/ham_objects.csv
# Output: data/objects_with_coords.csv
# ─────────────────────────────────────────────────────────────────────────────

library(tidyverse)

# ── Load objects from 01_fetch_ham.R ──────────────────────────────────────────
objects_df <- read_csv("data/ham_objects.csv", show_col_types = FALSE)

# ── Depicted locations ────────────────────────────────────────────────────────
depicted_coords <- tribble(
  ~objectnumber,  ~title,                                                                    ~depicted_loc,                                              ~latitude,  ~longitude, ~specificity,
  
  # ── SPECIFIC LOCATIONS ────────────────────────────────────────────────────────────
  "1962.42",      "Parahi te marae (There Is the Temple)",                                   "Tahiti, French Polynesia",                                 -17.650,   -149.430,    2L,
  "1919.47",      "Falls of Schaffhausen",                                                   "Rhine Falls, Neuhausen am Rheinfall, Switzerland",          47.677,      8.616,    2L,
  "1943.395",     "Landscape, Eragny",                                                       "Éragny-sur-Epte, Normandy, France",                         49.263,      1.685,    2L,
  "1991.25",      "Study in the Forest of Fontainebleau",                                    "Forest of Fontainebleau, Seine-et-Marne, France",           48.407,      2.702,    1L,
  "2011.90",      "Baths of Trajan, Rome",                                                   "Baths of Trajan, Oppian Hill, Rome, Italy",                 41.889,     12.498,    2L,
  "2023.538",     "The Pond, Honfleur, France",                                              "Honfleur, Calvados, Normandy, France",                      49.419,      0.232,    2L,
  "2023.547",     "Fall of the Tritt near the Iron Foundries at Oberhasli",                  "Oberhasli valley, Bern canton, Switzerland",                46.706,      8.228,    1L,
  "2021.513",     "No 566 Menai Suspension Bridge From the Beach on the Anglesea Side",      "Menai Bridge, Anglesey, Wales",                             53.224,     -4.162,    2L,
  "2021.516",     "The Porch at East Bergholt Church, Suffolk",                              "East Bergholt, Suffolk, England",                           51.970,      1.014,    2L,
  "1993.231",     "Hat, Shoes and Undergarments (Study for 'Une baignade, Asnières')",       "Asnières-sur-Seine, Hauts-de-Seine, France",                48.915,      2.286,    2L,
  "R3740",        "Tomb of Jean Jacques Rousseau",                                            "Île des Peupliers, Ermenonville, Oise, France",             49.130,      2.712,    2L,
  "1912.329",     "Illustration with music for 'On the Ancient Walls of Venice'",            "Venice, Veneto, Italy",                                     45.434,     12.338,    1L,
  "2021.51",      "Pyramids",                                                                "Giza Necropolis, Egypt",                                    29.979,     31.134,    1L,
  "1943.515",     "Peasant of the Camargue",                                                 "Camargue, Bouches-du-Rhône, France",                        43.500,      4.600,    1L,
  "1898.80",      "View of the Riverbank, the Frauenkirche...Dresden",                       "Elbe riverbank, Dresden, Germany",                          51.053,     13.741,    1L,
  "8.2023",       "Observations on the coasts of Hampshire, Sussex & Kent",                  "Hampshire coast, England",                                  50.800,     -1.300,    0L,
  "2007.226",     "Church Ruins in Bergen(?)",                                               "Bergen, Vestland, Norway (uncertain)",                      60.390,      5.320,    0L,
  "1994.184",     "Burned-out Building in Holstein",                                         "Holstein, Schleswig-Holstein, Germany",                     54.000,     10.000,    0L,
  "1979.131",     "Cascade de Lys",                                                           "Cascade d'Enfer, France",                                   42.732,      0.551,    0L,
  "2005.251",     "San Arcangelo",                                                            "Sant'Arcangelo, Cava de' Tirreni, Campania, Italy",         40.697,     14.693,    0L,
  "2024.223",     "Rocca Pia Castle in Tivoli",                                               "Rocca Pia Castle, Tivoli, Lazio, Italy",                   41.960,     12.798,    0L,
  "1965.247",     "View of Mount Soracte from Civita Castellana",                             "Monte Soratte, near Sant'Oreste, Lazio, Italy",             42.250,     12.500,    0L,
  "2023.528",     "Church of Tamins opposite Reichenau, Switzerland",                         "Evangelisch-reformierte Kirche Tamins, Graubünden, Switzerland", 46.829,  9.408,    0L,
  "2023.542",     "Fall of the Tritt in the Mühlethal Valley, Switzerland",                  "Mühlethal Valley, Innertkirchen, Bern, Switzerland",        46.705,      8.227,    0L,
  "2023.543",     "The Ruins of Geiersberg Castle in Bohemia",                                "Kyšperk (Geiersburg) Castle, Krupka, Czechia",              50.696,     13.890,    0L,
  "1907.6",       "Stirling Castle",                                                          "Stirling Castle, Stirling, Scotland",                       56.124,     -3.947,    0L,
  "1943.687",     "Brighton Beach, with a Horse Turning a Capstan",                           "Brighton Beach, East Sussex, England",                      50.820,     -0.138,    0L,
  "2021.517",     "At Parton Hall, Staffordshire",                                            "Wrottesley Hall, Staffordshire, England",                   52.613,     -2.223,    0L,
  "2023.488",     "Page's Farm, Easton Park, Essex",                                          "Page's Farm, Little Easton, Essex, England",                51.874,      0.322,    0L,
  "2023.489",     "Entrance into Easton Park from Dunmont",                                   "Easton Park, Great Dunmow, Essex, England",                 51.873,      0.362,    0L,
  "2024.59",      "Evening View near the Thames in Lambeth, London",                          "Thames riverside, Lambeth, London, England",                51.499,     -0.121,    0L,
  "2024.6",       "Figures on the Shore, looking out to Sea, Penmaen Beach, North Wales",     "Penmaenmawr Beach, Conwy, North Wales",                     53.270,     -3.929,    0L,
  "1979.111",     "Rocky Gorge, Via Mala",                                                    "Viamala Gorge, Hinterrhein River, Graubünden, Switzerland",  46.663,      9.449,    0L,
  "2023.56",      "The Interior of the Colosseum, Rome",                                      "Colosseum, Rome, Italy",                                    41.890,     12.492,    0L,
  "2026.65",      "View of the Cataract of the Mothvaye, Merionethshire, North Wales",        "Maesglase Waterfall, Merionethshire, North Wales",           52.714,     -3.725,    0L,
  "1943.387",     "Race Course at Longchamp; verso: Section of grandstand area",              "Hippodrome de Longchamp, Paris, France",                    48.855,      2.234,    0L,
  "1943.393",     "Boats (Entry of the Midina to the Isle of Wight)",                         "River Medina, Cowes, Isle of Wight, England",                50.758,     -1.292,    0L,
  "1999.12",      "Mountainous Landscape with a Volcano",                                     "Mount Vesuvius, near Naples, Italy",                        40.821,     14.427,    1L,
  "2001.77",      "Fountain Near the Hill of Montmartre",                                     "Butte Montmartre area, Paris, France",                      48.887,      2.343,    1L,
  "2001.77v",     "Street Scene in the North of Paris",                                       "Northern districts of Paris, France",                       48.890,      2.350,    1L,
  "2007.139",     "Entrance to the Baumannshöhle in the Harz Mountains",                      "Baumannshöhle, Rübeland, Harz Mountains, Germany",          51.755,     10.843,    1L,
  "1943.281",     "Honfleur Harbor",                                                          "Honfleur harbour, Calvados, Normandy, France",              49.419,      0.232,    1L,
  "1943.345",     "Mont St. Michel",                                                          "Mont-Saint-Michel, Normandy, France",                       48.636,     -1.512,    1L,
  "2023.522",     "Panoramic View of Grindelwald with View of Finsteraarhorn and both Grindelwald Glaciers", "Grindelwald, Bernese Oberland, Switzerland", 46.624, 8.041, 1L,
  "2023.529",     "View of the City of Zürich from Present Day Seefeld",                     "Seefeld lakeside quarter, Zürich, Switzerland",             47.355,      8.551,    1L,
  "1898.23",      "View of Olevano; verso: Landscape",                                        "Olevano Romano, Lazio, Italy",                              41.853,     13.040,    1L,
  "1898.8",       "View of the Riverbank, the Frauenkirche, the Hofkirche, and the Augustus Bridge, Dresden", "Elbe riverbank, Dresden, Germany", 51.053, 13.741, 1L,
  "1898.84",      "Panorama from a Lookout at Borsberg",                                      "Borsberg Lookout, near Dresden, Germany",                   51.022,     13.898,    1L,
  "1943.686",     "The Gardens at Stourhead",                                                 "Stourhead gardens, Stourton, Wiltshire, England",           51.105,     -2.315,    1L,
  "1954.133",     "Simplon Pass",                                                             "Simplon Pass summit, Valais, Switzerland",                  46.250,      8.032,    1L,
  "TL42852.4",    "Hauteville",                                                               "Hauteville House, Guernsey",                                49.451,     -2.538,    1L,
  "1903.49",      "Devonport and Dockyard, Devonshire",                                       "Devonport Dockyard, Plymouth, Devon, England",              50.374,     -4.184,    2L,
  "2004.73",      "A Willow Tree on the Prater Island in Munich, with the Quellwasser Footbridge and the Hospital on the Opposite Bank of the Isar River", "Praterinsel, Munich, Germany", 48.136, 11.591, 2L,
  "2022.225",     "Above Lyme Regis, looking across Marshwood Vale, Dorset",                  "Lyme Regis, Dorset, England",                               50.735,     -2.942,    2L,
  "1943.517",     "Abbeville",                                                                "Abbeville, Somme, Hauts-de-France, France",                 50.106,      1.835,    2L,
  "1977.173",     "Mont Sainte-Victoire",                                                     "Mont Sainte-Victoire, near Aix-en-Provence, France",         43.526,      5.561,    2L,
  "1999.247",     "View Near Nemi",                                                           "Countryside near Lake Nemi, Lazio, Italy",                  41.703,     12.707,    2L,
  "TL42858.2",    "The Cliffs of Varengeville in Full Sun",                                  "Varengeville-sur-Mer, Normandy, France",                    49.901,      0.980,    2L,
  "2023.518",     "Study of a Wooded Hillside near Weesen",                                  "Weesen area, Walensee, Switzerland",                        47.133,      9.094,    2L,
  "1943.533",     "Barns in Interlaken",                                                      "Interlaken, Bernese Oberland, Switzerland",                 46.686,      7.863,    2L,
  "1959.113",     "View of Amalfi",                                                           "Amalfi, Amalfi Coast, Campania, Italy",                     40.634,     14.602,    2L,
  "1943.283",     "Windmills close to Rotterdam",                                             "Rotterdam, South Holland, Netherlands",                      51.916,      4.399,    2L,
  "1951.143",     "Winter (The Plain of Chailly)",                                            "Chailly-en-Bière, Forest of Fontainebleau, France",         48.468,      2.608,    2L,
  "1934.203",     "The Fishing Boats at Scheveningen",                                        "Scheveningen, The Hague, Netherlands",                      52.108,      4.275,    2L,
  "1943.314",     "Olive Trees, Corfu",                                                       "Corfu, Ionian Islands, Greece",                             39.451,     19.979,    2L,
  "2025.321",     "Leuvehave, Rotterdam (seen from the Leuvebrug on the Zeevischmarkt)",      "Rotterdam, Netherlands",                                     51.915,      4.483,    2L,
  "2025.362",     "Harvest Time near Holmbury Hill, Surrey",                                  "Holmbury Hill, Surrey, England",                            51.176,     -0.423,    2L
)

# ── Region-level placements — not joined ──────────────────────────────────────
# These works name no locatable view ("Umbrian Landscape", "Fragment of the
# Alps"). The coordinates below are regional centroids kept for reference only;
# mapping them as points would imply a precision the objects do not carry.
# Move a row into `depicted_coords` above once a view has been identified.
region_coords <- tribble(
  ~objectnumber,  ~title,                                                                    ~depicted_loc,                                              ~latitude,  ~longitude, ~specificity,
"32.1979",      "Moonlit Normandy Coast",                                                  "Normandy coast, France (region approximate)",               49.500,      0.500,    0L,
"1919.506",     "Fragment of the Alps",                                                    "Alps (region approximate)",                                 46.500,      8.000,    0L,
"1985.47",      "Umbrian Landscape",                                                       "Umbria, Italy (region approximate)",                        43.100,     12.400,    0L,
"1998.182",     "Italian Mountain Scene with Stream",                                      "Northern Italian Alps (region approximate)",                46.000,     11.000,    0L,
"2023.511",     "Mountain Torrent in a Storm",                                             "Swiss Alps (region approximate, 2023 series)",              46.500,      8.000,    0L,
"2023.533",     "Waterfall Cascading Down a Mountain",                                     "Swiss Alps (region approximate, 2023 series)",              46.700,      8.100,    0L,
"2023.532",     "Forested Landscape below an Italian Village",                             "Central Italy (region approximate)",                        43.000,     12.000,    0L,
"1991.228",     "Italian Coastal Landscape",                                               "Tyrrhenian coast, Italy (region approximate)",              43.000,     10.800,    0L,
"1964.15.15",   "Mediterranean Landscape",                                                 "Mediterranean coast (region approximate)",                  43.500,      5.500,    0L,
"1964.15.10",   "Mediterranean Landscape with Olive Trees",                                "Mediterranean coast (region approximate)",                  43.500,      5.600,    0L,
"2023.534",     "Street Scene in Italy",                                                   "Italy (unspecified)",                                       41.900,     12.500,    0L,
"TL42858.1",    "TL42858.1",                                                               "Montreux area, Lake Geneva (unverified)",                   46.431,      6.909,    0L
)

# ── Join by objectnumber ──────────────────────────────────────────────────────
objects_with_coords <- objects_df |>
  left_join(
    select(depicted_coords, objectnumber, depicted_loc, latitude, longitude, specificity),
    by = "objectnumber"
  )

# ── Report ────────────────────────────────────────────────────────────────────
unmatched <- setdiff(depicted_coords$objectnumber, objects_df$objectnumber)
if (length(unmatched) > 0)
  warning("Coordinates given for objectnumbers absent from ham_objects.csv: ",
          paste(unmatched, collapse = ", "))

cat(sprintf("Objects            : %d\n", nrow(objects_with_coords)))
cat(sprintf("  with coordinates : %d\n", sum(!is.na(objects_with_coords$latitude))))
cat(sprintf("  region-level only: %d\n", nrow(region_coords)))

# ── Save ──────────────────────────────────────────────────────────────────────
write_csv(objects_with_coords, "data/objects_with_coords.csv")
cat("Saved: data/objects_with_coords.csv\n")
