library(data.table) 

 deleted_idv_fields = function(list_element){
data.table(
AWARD_DEPARTMENT_ID = tryCatch(list_element$contractID$IDVID$agencyID[[1]], error = function(e) return(NA)),
MODIFICATION_NUMBER = tryCatch(list_element$contractID$IDVID$modNumber[[1]], error = function(e) return(NA)),
PIID = tryCatch(list_element$contractID$IDVID$PIID[[1]], error = function(e) return(NA)),
TRANSACTION_NUMBER = tryCatch(list_element$contractID$IDVID$transactionNumber[[1]], error = function(e) return(NA)),
IDV_DEPARTMENT_ID = tryCatch(list_element$contractID$referencedIDVID$agencyID[[1]], error = function(e) return(NA)),
IDV_MODIFICATION_NUMBER = tryCatch(list_element$contractID$referencedIDVID$modNumber[[1]], error = function(e) return(NA)),
IDV_PIID = tryCatch(list_element$contractID$referencedIDVID$PIID[[1]], error = function(e) return(NA)),
DOLLARS_OBLIGATED = tryCatch(list_element$dollarValues$obligatedAmount[[1]], error = function(e) return(NA)),
DATE_SIGNED = tryCatch(list_element$relevantContractDates$signedDate[[1]], error = function(e) return(NA))
)
}
