## -----------------------------
## Script Name: deleted_pull.R
##
## Author: Sam Powers
## Date Created: 2022-05-20
##
## -----------------------------
## Purpose of Script: To scrape the deleted awards and idvs
##
##
## -----------------------------
## Update Log:
## 
##
## -----------------------------
## Set working directory

# Step 1: Generate the Addresses for the award ----------------------------

deleted_award_address <- paste0(deleted_address, '%20CONTRACT_TYPE:%22AWARD%22')

## get the final link
deleted_award_final_link <- attr(as_list(read_xml(deleted_award_address))[[1]][[3]], "href")

## pull what the last n will be
deleted_award_final_n <- as.numeric(str_split(deleted_award_final_link, "start=", simplify = TRUE )[2])

if (is.na(deleted_award_final_n)) {deleted_award_final_n <- 0}
  
if (deleted_award_final_n > 399999) {print("Award Links Out of Range")} else {print(paste0("deleted award final link is: ", deleted_award_final_n))}

## generate all of your query links
deleted_award_query_links <- paste0(deleted_award_address, "&start=", seq(0, deleted_award_final_n, 10))

# Step 2: Pull the Deleted Feed award Data -----------------------------------------
library(tictoc)

### Part A: Source The Decoder Script: 
source("dependencies/deleted_award_fields.R")

### Part B: Set up the parallel scheme
plan(multisession, workers = 10)

tic()
### Part C: Loop through the links pulling the Deleted feed data entries 10 at a time 
deleted_award_pull_list <- 
  future_map(deleted_award_query_links, function(this_link) {
    
    # read in the link. If the link doesn't read in, return null instead of breaking the loop. 
    xml_call <- tryCatch(xml_children(xml_children(xml_children(read_xml(this_link)))), error = function(e) return( NULL ) )
    
    # If there was an error thrown in the previous line, just output null for that list element
    if (is.null(xml_call)) {
      
      return(NULL)
      
    } else { # if there wasnt an error thrown in the xml script, continue on to clean the xml
      
      ## turn award and idv xml into award and idv lists
      list_award <- as_list(xml_call)
      
      ## Clean up the award using the pre-specified paths 
      deleted_award <- rbindlist(map(list_award, deleted_award_fields), fill = TRUE) 
      
      ## Add in the AWARD_OR_IDV column
      deleted_award[, AWARD_OR_IDV := "AWARD"]
      
      ## Store this one
      return(deleted_award)
      
    }
  }
  
  ,.progress = TRUE
  ) 

toc() 

# Step 3: Label the chunks in the output list -----------------
names(deleted_award_pull_list) <- paste0("n",str_sub(deleted_award_query_links, 170, -1))

# Step 4: bind the data together into a list ------------------------------
deleted_award_pull_df <- rbindlist(deleted_award_pull_list, fill = TRUE)

# Step 5: Check for and Store the Nulls -----------------------------------
deleted_award_pull_check <- map_lgl(deleted_award_pull_list,  is.null )
print(paste0("The Following Deleted Award Chunks Were Missed:", names(deleted_award_pull_check[deleted_award_pull_check])))



# --------------------------------------------------------------------------------------------------------
## Repeat for IDVs

# Step 6: Generate the Addresses for the idv ----------------------------

deleted_idv_address <- paste0(deleted_address, '%20CONTRACT_TYPE:%22IDV%22')

## get the final link
deleted_idv_final_link <- attr(as_list(read_xml(deleted_idv_address))[[1]][[3]], "href")

## pull what the last n will be
deleted_idv_final_n <- as.numeric(str_split(deleted_idv_final_link, "start=", simplify = TRUE )[2])

if (is.na(deleted_idv_final_n)) {deleted_idv_final_n <- 0}

if (deleted_idv_final_n > 399999) {print("idv Links Out of Range")} else {print(paste0("deleted idv final link is: ", deleted_idv_final_n))}

## generate all of your query links
deleted_idv_query_links <- paste0(deleted_idv_address, "&start=", seq(0, deleted_idv_final_n, 10))

# Step 7: Pull the Deleted Feed Idv Data -----------------------------------------
library(tictoc)

### Part A: Source The Decoder Script: 
source("dependencies/deleted_idv_fields.R")

### Part B: Set up the parallel scheme
plan(multisession, workers = 10)

tic()
### Part C: Loop through the links pulling the Deleted feed data entries 10 at a time 
deleted_idv_pull_list <- 
  future_map(deleted_idv_query_links, function(this_link) {
    
    # read in the link. If the link doesn't read in, return null instead of breaking the loop. 
    xml_call <- tryCatch(xml_children(xml_children(xml_children(read_xml(this_link)))), error = function(e) return( NULL ) )
    
    # If there was an error thrown in the previous line, just output null for that list element
    if (is.null(xml_call)) {
      
      return(NULL)
      
    } else { # if there wasnt an error thrown in the xml script, continue on to clean the xml
      
      ## turn idv and idv xml into idv and idv lists
      list_idv <- as_list(xml_call)
      
      ## Clean up the idv using the pre-specified paths 
      deleted_idv <- rbindlist(map(list_idv, deleted_idv_fields), fill = TRUE) 
      
      ## Add in the idv_OR_IDV column
      deleted_idv[, AWARD_OR_IDV := "IDV"]
      
      ## Store this one
      return(deleted_idv)
      
    }
  }
  
  ,.progress = TRUE
  ) 

toc() 

# Step 8: Label the chunks in the output list -----------------
names(deleted_idv_pull_list) <- paste0("n",str_sub(deleted_idv_query_links, 170, -1))

# Step 9: bind the data together into a list ------------------------------
deleted_idv_pull_df <- rbindlist(deleted_idv_pull_list, fill = TRUE)

# Step 10: Check for and Store the Nulls -----------------------------------
deleted_idv_pull_check <- map_lgl(deleted_idv_pull_list,  is.null )
print(paste0("The Following Deleted IDV Chunks Were Missed:", names(deleted_idv_pull_check[deleted_idv_pull_check])))

# Step 11: To End Bind it all together------------------------------------------------------------------
deleted_pull_df <- rbindlist(list(deleted_award_pull_df, deleted_idv_pull_df), fill = TRUE)
deleted_pull_df <- deleted_pull_df[!is.na(PIID),] ## sometime there aren't IDVs or there aren't awards in call and we need to catch that. 





