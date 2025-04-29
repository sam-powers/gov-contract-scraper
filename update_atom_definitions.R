## -----------------------------
## Script Name: update_atom_definitions.R
##
## Author: Sam Powers
## Date Created: 2022-05-20
##
## -----------------------------
## Purpose of Script: Run this script if you would like to update the fields and definitions that are pulled through the ATOM feed pull process
##
##
## -----------------------------
## Update Log:
## 
##
## -----------------------------
## Load routine packages and options:
library(tidyverse)
library("rstudioapi")    

## -----------------------------
## Set working directory

setwd(dirname(getActiveDocumentContext()$path)) ## set to source file location

##### Awards & IDVs
# Step 1: Read in the atom feed formats and source the translation functions. -------------------------------------------
### If there are any edits to the ATOM feed definitions, edit them in the atom_feed_definitions_final.csv+

## read in the atom feed definitions
atom_feed_definitions <- read_csv("atom_feed_definitions_final.csv")

# Step 2: Use the atom feed definitions sheet to generate the xml decoder scripts --------

## Awards
paste0(
  "library(data.table) \n\n award_fields = function(list_element){\ndata.table(\n",
  atom_feed_definitions %>%
    select(colname, award, Tag) %>%
    filter(!is.na(award)) %>%
    mutate(script = paste0(colname, " = tryCatch(", award, ", error = function(e) return(NA))")) %>%
    summarise(script = paste0(script, collapse = ",\n")) %>%
    pull(script), "\n)\n}"
) %>%
  write_lines(. , "dependencies/award_fields.R")

## IDVs
paste0(
  "library(data.table) \n\n idv_fields = function(list_element){\ndata.table(\n",
  atom_feed_definitions %>%
    select(colname, idv, Tag) %>%
    filter(!is.na(idv)) %>%
    mutate(script = paste0(colname, " = tryCatch(", idv, ", error = function(e) return(NA))")) %>%
    summarise(script = paste0(script, collapse = ",\n")) %>%
    pull(script), "\n)\n}"
) %>%
  write_lines(. , "dependencies/idv_fields.R")




##### Deleted Feed -----------------------------------------------

# Step 1: Read in the deleted feed formats and source the translation functions. -------------------------------------------
### If there are any edits to the deleted feed definitions, edit them in the deleted_feed_definitions_final.csv

## read in the atom feed definitions
deleted_feed_definitions <- read_csv("deleted_feed_definitions_final.csv")

# Step 2: Use the atom feed definitions sheet to generate the xml decoder scripts --------
## Awards
paste0(
  "library(data.table) \n\n deleted_award_fields = function(list_element){\ndata.table(\n",
  deleted_feed_definitions %>%
    select(colname, award, Tag) %>%
    filter(!is.na(award)) %>%
    mutate(script = paste0(colname, " = tryCatch(", award, ", error = function(e) return(NA))")) %>%
    summarise(script = paste0(script, collapse = ",\n")) %>%
    pull(script), "\n)\n}"
) %>%
  write_lines(. , "dependencies/deleted_award_fields.R")

## IDVs
paste0(
  "library(data.table) \n\n deleted_idv_fields = function(list_element){\ndata.table(\n",
  deleted_feed_definitions %>%
    select(colname, idv, Tag) %>%
    filter(!is.na(idv)) %>%
    mutate(script = paste0(colname, " = tryCatch(", idv, ", error = function(e) return(NA))")) %>%
    summarise(script = paste0(script, collapse = ",\n")) %>%
    pull(script), "\n)\n}"
) %>%
  write_lines(. , "dependencies/deleted_idv_fields.R")


