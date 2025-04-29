# Get the missing awards --------------------------------------------------
missed_award_links

### Part A: Source The Decoder Script: 
source("dependencies/award_fields.R")

### Part B: Set up the parallel scheme
plan(multisession, workers = 10)

### Part C: Loop through the links pulling the ATOM feed data entries 10 at a time 
tic()
award_pull_list_missing <- 
  future_map(missed_award_links, function(this_link) {
    
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


# Label the chunks in the output list -----------------
names(award_pull_list_missing) <- paste0("n",str_sub(missed_award_links, 170, -1))

# bind the data together into a list ------------------------------
award_pull_df_missing <- rbindlist(award_pull_list_missing, fill = TRUE)

# Check for and Store the Nulls -----------------------------------
award_pull_missing_check <- map_lgl(award_pull_list_missing,  is.null )
print(paste0("The Following Chunks Were Missed:", names(award_pull_missing_check[award_pull_missing_check])))




