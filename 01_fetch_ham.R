# ─────────────────────────────────────────────────────────────────────────────
# 01_fetch_ham.R
# Fetches object + people data from the HAM API.
#
# Outputs:
#   ham_objects.csv  – one row per object, summary people columns
#   ham_people.csv   – one row per person–object link, for artist geocoding
#
# Join key between the two files: objectnumber
# ─────────────────────────────────────────────────────────────────────────────

source("00_config.R")

library(httr2)
library(jsonlite)
library(tidyverse)

# ── Helpers ───────────────────────────────────────────────────────────────────

# NULL-safe default
`%||%` <- function(a, b) if (!is.null(a)) a else b

# Deduplicate and collapse a character vector to a single string, dropping NA/blank
collapse_vals <- function(x, sep = "; ") {
  x <- unique(x[!is.na(x) & nzchar(trimws(x))])
  if (length(x) == 0) NA_character_ else paste(x, collapse = sep)
}

# Extract a field from every element of a people list as character
people_chr <- function(people, field) {
  map_chr(people, ~ .x[[field]] %||% NA_character_)
}

# Parse birth/death years from a display-date string.
# Returns a named integer vector: c(birth_year = ..., death_year = ...)
# Works for: "1577 - 1640", "c. 1710–1785", "active 1850-1870", "born 1756"
# When the date is prefixed "active", the years are activity dates not birth/death;
# this is flagged via the `active_dates` column in parse_people_df().
parse_years <- function(displaydate) {
  empty <- c(birth_year = NA_integer_, death_year = NA_integer_)
  if (is.na(displaydate) || !nzchar(trimws(displaydate))) return(empty)
  
  # Two four-digit years separated by a dash/en-dash/em-dash
  m <- str_match(displaydate, "(\\d{4})\\s*[-\u2013\u2014]\\s*(\\d{4})")
  if (!is.na(m[1, 1]))
    return(c(birth_year = as.integer(m[1, 2]), death_year = as.integer(m[1, 3])))
  
  # Single four-digit year (born YYYY, active YYYY, or bare YYYY)
  m2 <- str_match(displaydate, "(\\d{4})")
  if (!is.na(m2[1, 1]))
    return(c(birth_year = as.integer(m2[1, 2]), death_year = NA_integer_))
  
  empty
}

# ── People data frame (one row per person–object link) ────────────────────────
parse_people_df <- function(objnum, people) {
  if (is.null(people) || length(people) == 0) {
    return(tibble(
      objectnumber = objnum,
      personid     = NA_integer_,
      displayorder = NA_integer_,
      role         = NA_character_,
      name         = NA_character_,
      displaydate  = NA_character_,
      active_dates = NA,           # TRUE when displaydate means activity period
      birth_year   = NA_integer_,
      death_year   = NA_integer_,
      culture      = NA_character_,
      birthplace   = NA_character_,
      deathplace   = NA_character_
    ))
  }
  
  displaydates <- people_chr(people, "displaydate")
  years_list   <- map(displaydates, parse_years)
  
  tibble(
    objectnumber = objnum,
    personid     = map_int(people, ~ as.integer(.x$personid     %||% NA_integer_)),
    displayorder = map_int(people, ~ as.integer(.x$displayorder %||% NA_integer_)),
    role         = people_chr(people, "role"),
    name         = people_chr(people, "name"),
    displaydate  = displaydates,
    active_dates = str_detect(tolower(displaydates), "^active"),
    birth_year   = map_int(years_list, "birth_year"),
    death_year   = map_int(years_list, "death_year"),
    culture      = people_chr(people, "culture"),
    birthplace   = people_chr(people, "birthplace"),
    deathplace   = people_chr(people, "deathplace")
  )
}

# ── People summary strings for the objects table ──────────────────────────────
people_summary <- function(people) {
  empty <- list(
    people_names       = NA_character_,
    people_displaydate = NA_character_,
    people_culture     = NA_character_,
    people_birthplace  = NA_character_,
    people_deathplace  = NA_character_
  )
  if (is.null(people) || length(people) == 0) return(empty)
  
  list(
    people_names       = collapse_vals(people_chr(people, "name")),
    people_displaydate = collapse_vals(people_chr(people, "displaydate")),
    people_culture     = collapse_vals(people_chr(people, "culture")),
    people_birthplace  = collapse_vals(people_chr(people, "birthplace")),
    people_deathplace  = collapse_vals(people_chr(people, "deathplace"))
  )
}

# ── Blank row templates (keeps column types stable on failure) ─────────────────
na_object_row <- function(objnum, status) {
  tibble(
    objectnumber       = objnum,
    title              = NA_character_,
    people_names       = NA_character_,
    people_displaydate = NA_character_,
    people_culture     = NA_character_,
    people_birthplace  = NA_character_,
    people_deathplace  = NA_character_,
    culture            = NA_character_,
    medium             = NA_character_,
    technique          = NA_character_,
    century            = NA_character_,
    classification     = NA_character_,
    creditline         = NA_character_,
    accessionyear      = NA_integer_,
    primaryimageurl    = NA_character_,
    url                = NA_character_,
    dated              = NA_character_,
    datebegin          = NA_integer_,
    dateend            = NA_integer_,
    status             = status
  )
}

# ── Core fetch ────────────────────────────────────────────────────────────────
fetch_one <- function(objnum) {
  req <- request("https://api.harvardartmuseums.org/object") |>
    req_url_query(
      apikey       = HAM_APIKEY,
      objectnumber = objnum,
      size         = 1,
      fields       = HAM_FIELDS
    )
  
  tryCatch({
    resp <- req_perform(req)
    dat  <- resp_body_string(resp) |> fromJSON(simplifyVector = FALSE)
    
    if (is.null(dat$records) || length(dat$records) == 0) {
      return(list(
        object = na_object_row(objnum, "NOT_FOUND"),
        people = parse_people_df(objnum, NULL)
      ))
    }
    
    r  <- dat$records[[1]]
    p  <- r$people        # may be NULL
    ps <- people_summary(p)
    
    # `culture` can arrive as a plain string or as a list with $name elements
    culture_val <- if (is.character(r$culture)) {
      collapse_vals(r$culture)
    } else if (is.list(r$culture)) {
      collapse_vals(map_chr(r$culture, ~ .x$name %||% NA_character_))
    } else {
      NA_character_
    }
    
    obj <- tibble(
      objectnumber       = objnum,
      title              = r$title           %||% NA_character_,
      people_names       = ps$people_names,
      people_displaydate = ps$people_displaydate,
      people_culture     = ps$people_culture,
      people_birthplace  = ps$people_birthplace,
      people_deathplace  = ps$people_deathplace,
      culture            = culture_val,
      medium             = r$medium          %||% NA_character_,
      technique          = r$technique       %||% NA_character_,
      century            = r$century         %||% NA_character_,
      classification     = r$classification  %||% NA_character_,
      creditline         = r$creditline      %||% NA_character_,
      accessionyear      = as.integer(r$accessionyear %||% NA_integer_),
      primaryimageurl    = r$primaryimageurl %||% NA_character_,
      url                = str_replace(r$url %||% NA_character_, "^http://", "https://"),
      dated              = r$dated           %||% NA_character_,
      datebegin          = as.integer(r$datebegin %||% NA_integer_),
      dateend            = as.integer(r$dateend   %||% NA_integer_),
      status             = "OK"
    )
    
    list(object = obj, people = parse_people_df(objnum, p))
    
  }, error = function(e) {
    list(
      object = na_object_row(objnum, paste0("ERROR: ", conditionMessage(e))),
      people = parse_people_df(objnum, NULL)
    )
  })
}

# ── Run ───────────────────────────────────────────────────────────────────────
message("Fetching ", length(OBJNUMS), " objects from HAM API…")

results <- map(OBJNUMS, function(x) {
  Sys.sleep(0.15)           # ~6 req/s; stay well within API limits
  message("  ", x)
  fetch_one(x)
})

objects_df <- map_dfr(results, "object")
people_df  <- map_dfr(results, "people")

# ── Status report ─────────────────────────────────────────────────────────────
cat("\n── Summary ──────────────────────────────────────────────\n")
cat(sprintf("Objects fetched : %d\n",   nrow(objects_df)))
cat(sprintf("  OK            : %d\n",   sum(objects_df$status == "OK")))
cat(sprintf("  Not found     : %d\n",   sum(objects_df$status == "NOT_FOUND")))
cat(sprintf("  Errors        : %d\n",   sum(startsWith(objects_df$status, "ERROR"))))
cat(sprintf("People rows     : %d\n",   nrow(people_df)))
cat(sprintf("Unique artists  : %d\n",   n_distinct(na.omit(people_df$personid))))
cat(sprintf("With birthplace : %d\n",   sum(!is.na(people_df$birthplace))))

# ── Save ──────────────────────────────────────────────────────────────────────
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)
write.csv(objects_df, OUT_OBJECTS, fileEncoding = "UTF-8", row.names = FALSE, na = "")
write.csv(people_df,  OUT_PEOPLE,  fileEncoding = "UTF-8", row.names = FALSE, na = "")
cat(sprintf("\nSaved:\n  %s\n  %s\n", OUT_OBJECTS, OUT_PEOPLE))
