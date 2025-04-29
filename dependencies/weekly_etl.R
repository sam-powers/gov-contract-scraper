## -----------------------------
## Script Name: weekly_etl.R
##
## Author: Sam Powers
## Date Created: 2022-06-01
##
## -----------------------------
## Purpose of Script: 
##
##
## -----------------------------
## Update Log:
## - 2022-09-15, restricted vendor address line 2 to be less than 60 characters because a unique international address threw everything off. 
##
## -----------------------------

### Part A: Prep the data into a weekly chunk
## add a deleted flag
atom_pull_df[, DELETED := "NO"]
deleted_pull_df[, DELETED := "YES"]

## bind together
weekly_chunk <- rbindlist(list(atom_pull_df, deleted_pull_df), fill = TRUE)

## remove any that are blank
weekly_chunk <- weekly_chunk[!is.na(PIID),]
weekly_chunk$VENDOR_ADDRESS_LINE_2[nchar(weekly_chunk$VENDOR_ADDRESS_LINE_2) > 60 & !is.na(nchar(weekly_chunk$VENDOR_ADDRESS_LINE_2))] <- NA

### Part B: Make the connection
ATOMCON <- dbConnect(odbc(), 
                     Driver = "SQL Server", 
                     Server = "vmeprd-dat-sq05",
                     Database = "ATOM",   
                     timeout = Inf,
                     Trusted_Connection = 'Yes')

### Part C: Load the weekly chunk

## Drop current weekly chunk. Its saved in the .fst, so its fine to drop it and just keep this process lean.  
dbGetQuery(ATOMCON,
           "DROP TABLE ATOM_WEEKLY_CHUNK")

## write the create table query
create_query <- paste0(read_lines("etl/initiate_chunk.sql"), collapse = " ")

## create the table
dbGetQuery(ATOMCON, create_query)


# odbc::odbcConnectionColumns(ATOMCON, "ATOM_WEEKLY_CHUNK") %>%
#   select(name, column_size) %>%
#   full_join(
# weekly_chunk %>%
#   summarise(across(.cols = everything(), ~max(nchar(.x), na.rm = TRUE))) %>%
#   t() %>%
#   as.data.frame() %>%
#   rownames_to_column() %>%
#   rename(
#     name = 1, 
#     data_length = 2
#   )
# ) %>%
#   filter(data_length > column_size)
# 
# weekly_chunk %>%
#   filter(
#     nchar(VENDOR_ADDRESS_LINE_2) > 60
#   )


## Upload the weekly chunk data. 
dbWriteTable(conn = ATOMCON,
             name = "ATOM_WEEKLY_CHUNK",
             value = weekly_chunk,
             overwrite = FALSE, 
             row.names = FALSE , 
             append = TRUE
)


### Part D: Delete the deleted and Corrected Transactions from the current running table
dbGetQuery(ATOMCON,
           "DELETE FROM  ATOM_ALLDATA
 WHERE UNIQUE_ID IN (SELECT UNIQUE_ID FROM  ATOM_WEEKLY_CHUNK)"
)

### Part E: Add the Weekly Chunk to the atom data bank

## Drop the deleted records from the weekly update 
dbGetQuery(ATOMCON,
           "DELETE FROM ATOM_WEEKLY_CHUNK WHERE DELETED LIKE 'YES'")

## drop the deleted column as well
dbGetQuery(ATOMCON,
           "ALTER TABLE ATOM_WEEKLY_CHUNK DROP COLUMN DELETED")

## Insert the records into the running data bank
dbGetQuery(ATOMCON, 
           "INSERT INTO ATOM_ALLDATA
SELECT * FROM ATOM_WEEKLY_CHUNK"
)

### Part F: Create the current year views

## Drop the prior week
dbGetQuery(ATOMCON,
           "DROP VIEW ATOMFY2022_ALLDATA")

dbGetQuery(ATOMCON,
           "DROP VIEW ATOMFY2022_SBGR")

dbGetQuery(ATOMCON,
           "DROP VIEW ATOMFY2023_ALLDATA")

dbGetQuery(ATOMCON,
           "DROP VIEW ATOMFY2023_SBGR")


## create the all data view
all_dat_query <- paste0(read_lines("etl/fy_alldata_view.sql"), collapse = "\n")
dbGetQuery(ATOMCON, all_dat_query)

all_dat_query23 <- paste0(read_lines("etl/fy23_alldata_view.sql"), collapse = "\n")
dbGetQuery(ATOMCON, all_dat_query23)

## create the sbgr data view
sbgr_query <- paste0(read_lines("etl/fy_sbgr_view.sql"), collapse = "\n")
dbGetQuery(ATOMCON, sbgr_query)

sbgr_query23 <- paste0(read_lines("etl/fy23_sbgr_view.sql"), collapse = "\n")
dbGetQuery(ATOMCON, sbgr_query23)



