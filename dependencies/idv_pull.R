## -----------------------------
## Script Name: idv_pull.R
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

# Step 1: Generate the Addresses for the idv ----------------------------

idv_address <- paste0(address, '%20CONTRACT_TYPE:%22IDV%22')

## get the final link
idv_final_link <- attr(as_list(read_xml(idv_address))[[1]][[3]], "href")

## pull what the last n will be
idv_final_n <- as.numeric(str_split(idv_final_link, "start=", simplify = TRUE )[2])

if (idv_final_n > 399999) {print("IDV Links Out of Range")} else {print(paste0("final link is: ", idv_final_n))}

## generate all of your query links
idv_query_links <- paste0(idv_address, "&start=", seq(0, idv_final_n, 10))

# Step 2: Pull the Atom Feed idv Data -----------------------------------------
library(tictoc)

### Part A: Source the Decoder Script
source("dependencies/idv_fields.R")

### Part A: Set up the parallel scheme
plan(multisession, workers = 10)

tic()
## Part B: Loop through the links pulling the ATOM feed data entries 10 at a time 
idv_pull_list <- 
  future_map(idv_query_links, function(this_link) {
    
    # read in the link. If the link doesn't read in, return null instead of breaking the loop. 
    xml_call <- tryCatch(xml_children(xml_children(xml_children(read_xml(this_link)))), error = function(e) return( NULL ) )
    
    # If there was an error thrown in the previous line, just output null for that list element
    if (is.null(xml_call)) {
      
      return(NULL)
      
    } else { # if there wasnt an error thrown in the xml script, continue on to clean the xml
      
      ## turn idv and idv xml into idv and idv lists
      list_idv <- as_list(xml_call)
      
      ## Clean up the idv using the pre-specified paths 
      idv <- rbindlist(map(list_idv, idv_fields), fill = TRUE) 
      
      ## Add in the AWARD_OR_IDV column
      idv[, AWARD_OR_IDV := "IDV"]
      
      ## Store this one
      return(idv)
      
    }
  }
  
  ,.progress = TRUE
  ) 

toc() 


# Step 3: Label the chunks in the output list -----------------
names(idv_pull_list) <- paste0("n",str_sub(idv_query_links, 168, -1))

# Step 4: bind the data together into a list ------------------------------
idv_pull_df <- rbindlist(idv_pull_list, fill = TRUE)

# Step 5: Check for and Store the Nulls -----------------------------------
idv_pull_check <- map_lgl(idv_pull_list,  is.null )
print(paste0("The Following Chunks Were Missed:", names(idv_pull_check[idv_pull_check])))

# Step 6: Write out the missed idv links --------------------------------
missed_idv_links <- idv_query_links[idv_pull_check]












