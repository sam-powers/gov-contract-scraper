# Get the missing idvs --------------------------------------------------
missed_idv_links

### Part A: Source The Decoder Script: 
source("dependencies/idv_fields.R")

### Part B: Set up the parallel scheme
plan(multisession, workers = 10)

### Part C: Loop through the links pulling the ATOM feed data entries 10 at a time 
tic()
idv_pull_list_missing <- 
  future_map(missed_idv_links, function(this_link) {
    
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
      
      ## Add in the idv_OR_IDV column
      idv[, AWARD_OR_IDV := "IDV"]
      
      ## Store this one
      return(idv)
      
    }
  }
  
  ,.progress = TRUE
  ) 


# Label the chunks in the output list -----------------
names(idv_pull_list_missing) <- paste0("n",str_sub(missed_idv_links, 170, -1))

# bind the data together into a list ------------------------------
idv_pull_df_missing <- rbindlist(idv_pull_list_missing, fill = TRUE)

# Check for and Store the Nulls -----------------------------------
idv_pull_missing_check <- map_lgl(idv_pull_list_missing,  is.null )
print(paste0("The Following Chunks Were Missed:", names(idv_pull_missing_check[idv_pull_missing_check])))




