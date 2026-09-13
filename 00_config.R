# ─────────────────────────────────────────────────────────────────────────────
# 00_config.R
# Harvard Art Museums – central configuration.
# Only edit this file. Source it from the fetch script.
# ─────────────────────────────────────────────────────────────────────────────

# ── API key (stored in ~/.Renviron as  HAM_APIKEY=xxxxxxxx ) ─────────────────
HAM_APIKEY <- Sys.getenv("HAM_APIKEY")
if (HAM_APIKEY == "") stop("HAM_APIKEY not found – add it to ~/.Renviron and restart R.")

# ── Output paths ──────────────────────────────────────────────────────────────
OUT_DIR     <- "data"
OUT_OBJECTS <- file.path(OUT_DIR, "ham_objects.csv")  # one row per object
OUT_PEOPLE  <- file.path(OUT_DIR, "ham_people.csv")   # one row per person–object link

# ── Fields requested from the /object endpoint ───────────────────────────────
# `people` returns: name, role, displayorder, personid, displaydate,
#                   culture, birthplace, deathplace, prefix, displayname
# `primaryimageurl` is included for QGIS popup balloons
HAM_FIELDS <- paste(c(
  "objectnumber",
  "title",
  "people",
  "primaryimageurl",
  "url",
  "dated",
  "datebegin",
  "dateend",
  "medium",
  "technique",
  "century",
  "culture",
  "classification",
  "creditline",
  "accessionyear"
), collapse = ",")

# ── Object accession numbers ──────────────────────────────────────────────────
# Note: "1898.23" appeared twice in the original list – kept once here.
# Objects with non-standard prefixes (TL…, MS Typ…, 5.2023…) may return NOT_FOUND.


OBJNUMS <- unique(c(
  #LIGHT TO MATERIAL
  "2003.40.3", #Cezanne, Tree Trunks
  "1962.42", #Gauguin, Parahi te marae
  
  #GAINING A FOOTHOLD
  "2023.534", #Salathe, Italy
  "1919.47", #Ruskin
  
  #DRAWING THE TERRA COGNITA
  "1926.33.150",
  
#OBJECTS
  "2001.77",
  "1999.12",
  "2022.225",
  "1903.49",
  "2004.73",
  "1985.63",
  "1988.447",
  "2007.139",
  "1985.74",
  "2024.223",
  "2025.229",
  "1979.131",
  "2005.251",
  "1934.3",
  "2026.52",
  "1943.28",
  "1943.917",
  "1979.348",
  "1943.900",
  "1943.517",
  "1943.281",
  "1943.395",
  "1943.345",
  "1999.247",
  "1998.182",
  "1965.247",
  "1991.25",
  "2023.252",
  "TL42858.2",
  "2019.195",
  "32.1979",
  "1974.170",
  "1977.173",
  "1919.506",
  "1898.1",
  "1943.1336",
  "1919.261",
  "2023.490",
  "1943.482",
  "1943.714",
  "1912.329",
  "1969.41",
  "1979.99",
  "2023.535",
  "2023.542",
  "2023.511",
  "2023.522",
  "2023.528",
  "2023.529",
  "2023.539",
  "2023.533",
  "2023.532",
  "2023.518",
  "1956.220",
  "1943.555",
  "2023.543",
  "1898.205",
  "2011.90",
  "1985.47",
  "1898.23",
  "1985.51",
  "1898.84",
  "1898.80",
  "2007.226",
  "2019.181",
  "1943.536",
  "1943.533",
  "1943.91",
  "1994.184",
  "2023.488",
  "2023.489",
  "1907.6",
  "1970.149",
  "1926.33.142",
  "1943.686",
  "2024.59",
  "2021.517",
  "1943.687",
  "2024.60",
  "TL42880",
  "1979.111",
  "2023.56",
  "1943.402",
  "5.2023.7",
  "1943.469",
  "1959.113",
  "1954.133",
  "1943.351",
  "1943.352",
  "MS Typ 481",
  "2021.51",
  "TL42858.1",
  "1943.392",
  "1965.287",
  "1943.364",
  "1978.32",
  "1972.312",
  "1943.791",
  "1951.143",
  "1943.283",
  "1943.284",
  "1993.60",
  "2015.49",
  "1943.515",
  "1943.279",
  "2021.98",
  "2021.90",
  "1979.61",
  "1993.147",
  "1943.773",
  "1943.369",
  "1943.341",
  "1943.342",
  "1934.201",
  "1943.810",
  "1943.809",
  "1943.387",
  "1943.393",
  "1993.59",
  "1964.15.15",
  "1964.15.10",
  "1978.33",
  "1993.231",
  "1943.295",
  "2025.362",
  "1934.203",
  "1943.296",
  "1943.864",
  "1943.314",
  "2025.321",
  "2003.40.3",
  "1962.42",
  "1919.47",
  "1926.33.150",
  #Example of JJR
  "R3740", #tomb of jjr
  "1943.1421", #jjr statue
  #Materiality and Process
  "1963.10",
  "1997.119",
  "1974.161",
  "2023.538",
  #Education of an artist
  "1991.228",
  "8.2023",
  "1964.17",
  #Nature and Nat'l Identity
  "2023.547",
  "2023.513",
  #Travel and Home
  #Optical Devices
  "2021.513",
  "2021.516",
  "1961.38",
  #Landscapes of the Mind
  "2023.623",
  "TL42858.1", #Montreux
  #Labor and land
  "1943.520",
  #Escapism
  #Landscape and Environment
  "TL42852.4",
  "2026.65"
))
