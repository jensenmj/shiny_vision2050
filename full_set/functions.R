compile.tbl <- function(geog) {
  df <- NULL
  for (r in 1:length(run.dir)) { # for each run
    base.dir <- purrr::pluck(allruns, run.dir[r]) 
    for (a in 1:length(attributes)) { # for each attribute
      filename <- paste0(geog,'__',"table",'__',attributes[a], ind.extension)
      datatable <- read.csv(file.path(base.dir, indicator.dirnm, filename), header = TRUE, sep = ",")
      colnames(datatable)[2: ncol(datatable)] <- str_replace(colnames(datatable)[2: ncol(datatable)], '\\w+_', 'yr') # rename columns
      colnames(datatable)[1] <- str_replace(colnames(datatable)[1], '\\w+_', 'name_')
      datatable$indicator <- attributes[a]
      datatable$run <- run.dir[r]
      df <- rbindlist(list(df, datatable), use.names = TRUE, fill = TRUE)
    }
  }
  return(df)
}

get.military <- function(geog) {
  enlist.lu <- read.xlsx(file.path(data.dir, "enlisted_personnel_geo.xlsx"))

  enlist.mil.file.nm <- "enlisted_personnel_SoundCast_08202018.csv"

  mil <- read.csv(file.path(data.dir, enlist.mil.file.nm), stringsAsFactors = FALSE) %>%
            drop_na(everything())

  colnames(mil)[grep("^X\\d+", colnames(mil))] <- gsub("X", "yr", colnames(mil)[grep("^X\\d+", colnames(mil))])
  dots <- lapply(c(geog, "year"), as.symbol)
  mil.df <- mil %>% 
    left_join(enlist.lu, by = c("Base", "Zone", "ParcelID" = "parcel_id")) %>%
    gather(contains("yr"), key = "year", value = "estimate") %>%
    filter(year %in% paste0("yr", c(2017, years))) %>%
    group_by_(.dots = dots) %>%
    summarise(estimate = sum(estimate))  #%>%
    #summarise_(.dots = setNames(geog, "name_id"))
    #left_join(subarea.cnty.lu, by = "subarea_id")
  
  return(mil.df)
}

get.gq <- function(geog) {
  # GQ population -----------------------------------------------------------
  
  # read GQ pop (incorporate to 2050 data)
  gq.file <- read.xlsx(file.path(data.dir, "group-quarters.xlsx"), check.names = TRUE)
  colnames(gq.file)[grep("^X\\d+", colnames(gq.file))] <- gsub("X", "yr", colnames(gq.file)[grep("^X\\d+", colnames(gq.file))])
  #gq.cols <- c(geog, setNames(paste0("`", c(2017, years), "`"), "gq"))
  gq.cols <- lapply(c(geog, "year"), as.symbol)
  gq <- gq.file %>%
    gather(contains("yr"), key = "year", value = "estimate") %>% 
    filter(year %in% paste0("yr", c(2017, years))) %>%
    group_by_(.dots = gq.cols) %>%
    summarise(estimate = sum(estimate))
  return(gq)
}