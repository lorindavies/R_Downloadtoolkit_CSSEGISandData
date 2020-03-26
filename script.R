library(readr)
library(tidyverse)
library(rvest)
library(glue)
library(stringr)
library(lubridate)
library(purrr)
library(magrittr)
library(jsonlite)


# load yesterday's data only ---------------------------------------------------------

d <- lubridate::today() + lubridate::days(-1)
d1<- glue({sprintf("%02d",lubridate::month(d))},"-",{sprintf("%02d",lubridate::day(d))},"-", {sprintf("%02d",lubridate::year(d))})
CSSEGISandData <- read_csv(glue("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/",{d1},".csv"))

# Load live data - thanks to contributions from prfl

ffg <- fromJSON("https://covid19-report.today/api/latest-report/")


ffg.new <- as_tibble(ffg$report[2:nrow(ffg$report),], .name_repair= ~ffg$report[1,])
ffg.new 

ffg_totals <- as_tibble(t(ffg$totals[2,]), .name_repair= ~ffg$totals[1,])
ffg_totals 

ffg_last_update <- lubridate::as_datetime(ffg$lastUpdateTimestamp/1000, tz='UTC' )
# not sure about the time zone, the web content did not appear to list a time zone
ffg_last_update
real_time_now <- as.numeric(Sys.time()) 
real_time_now




working_df <-
  CSSEGISandData %>% 
  group_by(`Country_Region`) %>% 
  summarise(Confirmed = sum(Confirmed),
            Deaths = sum(Deaths),
            Recovered = sum(Recovered),
            Rate = Deaths / Confirmed *100)

# Scraping data for all days available -----------------------------------------------------------

# read the gitpage for CSSE data
cssegit <- read_html("https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_daily_reports") 

# use rvest to extract the table of csvs
tabcsv <-
  cssegit %>%
  html_table(header = 1, trim = TRUE, fill = TRUE, dec = ".") %>%
  as.data.frame()

# filter out non.csv entries and select the filenames
t1 <- tabcsv %>% 
  filter(str_detect(tolower(`Name`), pattern = ".csv")) %>% 
  select(`Name`)

# For loop which goes through the list of csvs and build a link to each raw file on github
for (i in t1) {
  dat<- glue("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/{i}")
}


# use map function to build a list of dfs of all the data. 
ldat<-
  dat %>%
  map(read_csv)

names(ldat) <-i

# run the same function as we did on 'yesterday's data' as above, but on a list of dfs
lapply(
  ldat,
  function(x) {
    x %>% 
      group_by(`Country/Region`) %>% 
      summarise(Confirmed = sum(Confirmed),
                Deaths = sum(Deaths),
                Recovered = sum(Recovered),
                Rate = Deaths / Confirmed *100)
  }
)





