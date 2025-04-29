## -----------------------------
## Script Name: award_pull.R
##
## Author: Sam Powers
## Date Created: 2022-05-20
##
## -----------------------------
## Purpose of Script: 
##
##
## -----------------------------
## Update Log:
## 
##
## -----------------------------

# Step 1: Generate the Addresses for the award ----------------------------

award_address <- paste0(address, '%20CONTRACT_TYPE:%22AWARD%22')

## get the final link
award_final_link <- attr(as_list(read_xml(award_address))[[1]][[3]], "href")

## pull what the last n will be
award_final_n <- as.numeric(str_split(award_final_link, "start=", simplify = TRUE )[2])

if (is.na(award_final_n)) {award_final_n <- 0}

if (award_final_n > 399999) {print("Award Links Out of Range")} else {print(paste0("final link is: ", award_final_n))}

## generate all of your query links
award_query_links <- paste0(award_address, "&start=", seq(0, award_final_n, 10))

# Step 2: Pull the Atom Feed award Data -----------------------------------------
library(tictoc)

### Part A: Source The Decoder Script: 
source("dependencies/award_fields.R")

### Part B: Set up the parallel scheme
plan(multisession, workers = 10)

tic()
### Part C: Loop through the links pulling the ATOM feed data entries 10 at a time 
award_pull_list <- 
  future_map(award_query_links, function(this_link) {
    
    # read in the link. If the link doesn't read in, return null instead of breaking the loop. 
    xml_call <- tryCatch(xml_children(xml_children(xml_children(read_xml(this_link)))), error = function(e) return( NULL ) )
    
    # If there was an error thrown in the previous line, just output null for that list element
    if (is.null(xml_call)) {
      
      return(NULL)
      
    } else { # if there wasnt an error thrown in the xml script, continue on to clean the xml
      
      ## turn award and idv xml into award and idv lists
      list_award <- as_list(xml_call)
      
      ## Clean up the award using the pre-specified paths 
      award <- rbindlist(map(list_award, award_fields), fill = TRUE) 
      
      ## Add in the AWARD_OR_IDV column
      award[, AWARD_OR_IDV := "AWARD"]
      
      ## Store this one
      return(award)
      
    }
  }
  
  ,.progress = TRUE
  ) 

toc() 

# Step 3: Label the chunks in the output list -----------------
names(award_pull_list) <- paste0("n",str_sub(award_query_links, 170, -1))

# Step 4: bind the data together into a list ------------------------------
award_pull_df <- rbindlist(award_pull_list, fill = TRUE)

# Step 5: Check for and Store the Nulls -----------------------------------
award_pull_check <- map_lgl(award_pull_list,  is.null )
print(paste0("The Following Chunks Were Missed: ", paste0(names(award_pull_check[award_pull_check]), collapse = ", ") ))

# Step 6: Write out the missed award links --------------------------------
missed_award_links <- award_query_links[award_pull_check]




