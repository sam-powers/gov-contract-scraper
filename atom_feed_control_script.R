## -----------------------------
## Script Name: atom_feed_control_script.R
##
## Author: Sam Powers
## Date Created: 2022-05-20
##
## -----------------------------
## Purpose of Script: This script integrates all the components of making an atom feed call to update an existing FPDS data base with new data. 
## Edit the last modified dates. And then run this. 
## Use the unique IDs from both the atom pull and the deleted pull to drop deleted and corrected contracts. Then add in the atom feed data. 
## -----------------------------
## Update Log:
## - 6/13/2022: SDP added sourcing of missed_award_pull.R to handle the missing awards from within the control script if necessary. 

## -----------------------------##
## Set working directory
library("rstudioapi")    
setwd(dirname(getActiveDocumentContext()$path)) ## set to source file location

## -----------------------------
## Load routine packages and options:
library(tidyverse)
library(data.table)
library(fst)
library(xml2)
library(furrr)
library(odbc)

options(scipen=6, digits = 4)
summarise <- dplyr::summarise
select <- dplyr::select

### NOTE: If you update the atom_feed_definitions_final.csv to change what fields are pulled, first execute update_atom_definitions.R 

# Step 1: Define the Date Ranges ------------------------------------------

### For signed date, we now have two fiscal years worth. This gets split out into year data sets later in the ETL
signed_start <- "2021/10/01"
signed_end <- "2023/09/30"

### For modification date, we want to put in the week of interest
mod_start <- "2022/10/31"
mod_end <- "2022/11/06"

# Step 2: Create the Base Query Link based on inputs --------------------------
address <- paste0("https://www.fpds.gov/ezsearch/FEEDS/ATOM?FEEDNAME=PUBLIC&q=SIGNED_DATE:[",signed_start,",",signed_end,"]%20LAST_MOD_DATE:[",mod_start,",",mod_end,"]")

# Step 3: Source the Awards -----------------------------------------------
source("dependencies/award_pull.R")

if (length(missed_award_links) > 0) {           ## Check for any that were missed 
  source("dependencies/missed_award_pull.R")    ## if there is missingness, run this script
}

# Step 4: Source the IDVs -------------------------------------------------
source("dependencies/idv_pull.R")

if (length(missed_idv_links) > 0) {           ## Check for any that were missed 
  source("dependencies/missed_idv_pull.R")    ## if there is missingness, run this script
}

# Step 5: make the master data set ----------------------------------------------
atom_pull_df <- rbindlist(list(
                                award_pull_df
                               ,idv_pull_df
                               ,award_pull_df_missing
#                              ,idv_pull_df_missing
                               ), fill = TRUE)

nrow(atom_pull_df)

# Step 6: Add in the Transaction ID ---------------------------------------
atom_pull_df <- 
  atom_pull_df %>% 
  mutate(
    across(c("IDV_DEPARTMENT_ID", "IDV_PIID", "AWARD_DEPARTMENT_ID", "PIID","MODIFICATION_NUMBER", "TRANSACTION_NUMBER"),
    ~fcase(is.na(.x), "NONE", !is.na(.x), .x),
    .names = "{col}_NAREPAIRED"
    )
    ) %>%
  mutate(
    UNIQUE_ID = paste(IDV_DEPARTMENT_ID_NAREPAIRED, IDV_PIID_NAREPAIRED, AWARD_DEPARTMENT_ID_NAREPAIRED, PIID_NAREPAIRED, MODIFICATION_NUMBER_NAREPAIRED, TRANSACTION_NUMBER_NAREPAIRED, sep = "-")
  ) %>%
  select(
    -contains("_NAREPAIRED")
  )


# Step 7: Create the Deleted Feed Address ---------------------------------
deleted_address <- paste0("https://www.fpds.gov/ezsearch/FEEDS/ATOM?FEEDNAME=DELETED&q=SIGNED_DATE:[",signed_start,",",signed_end,"]%20LAST_MOD_DATE:[",mod_start,",",mod_end,"]")

# Step 8: Source the Deleted Script ---------------------------------------
source("dependencies/deleted_pull.R")

# Step 9: Add in the Transaction ID ---------------------------------------
deleted_pull_df <- 
  deleted_pull_df %>% 
  mutate(
    across(c("IDV_DEPARTMENT_ID", "IDV_PIID", "AWARD_DEPARTMENT_ID", "PIID","MODIFICATION_NUMBER", "TRANSACTION_NUMBER"),
           ~fcase(is.na(.x), "NONE", !is.na(.x), .x),
           .names = "{col}_NAREPAIRED"
    )
  ) %>%
  mutate(
    UNIQUE_ID = paste(IDV_DEPARTMENT_ID_NAREPAIRED, IDV_PIID_NAREPAIRED, AWARD_DEPARTMENT_ID_NAREPAIRED, PIID_NAREPAIRED, MODIFICATION_NUMBER_NAREPAIRED, TRANSACTION_NUMBER_NAREPAIRED, sep = "-")
  ) %>%
  select(
    -contains("_NAREPAIRED")
  )


# Step 10: Save out the data ------------------
write_fst(atom_pull_df, paste0("extracts/atom_pull_fy22_23_",str_replace_all(mod_start, "\\/", ""), "to",str_replace_all(mod_end, "\\/", ""),".fst"), compress = 100)
write_fst(deleted_pull_df, paste0("extracts/deleted_pull_fy22_23_",str_replace_all(mod_start, "\\/", ""), "to",str_replace_all(mod_end, "\\/", ""),".fst"), compress = 100)

# atom_pull_df <- read_fst( paste0("extracts/atom_pull_fy22_",str_replace_all(mod_start, "\\/", ""), "to",str_replace_all(mod_end, "\\/", ""),".fst"), as.data.table = TRUE)
# deleted_pull_df <- read_fst(paste0("extracts/deleted_pull_fy22_",str_replace_all(mod_start, "\\/", ""), "to",str_replace_all(mod_end, "\\/", ""),".fst"), as.data.table = TRUE)

# Step 11: Load into the server --------------------------------------------
source("dependencies/weekly_etl.R")



