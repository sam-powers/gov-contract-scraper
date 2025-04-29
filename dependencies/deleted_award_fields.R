library(data.table) 

 deleted_award_fields = function(list_element){
data.table(
AWARD_DEPARTMENT_ID = tryCatch(list_element$awardID$awardContractID$agencyID[[1]], error = function(e) return(NA)),
MODIFICATION_NUMBER = tryCatch(list_element$awardID$awardContractID$modNumber[[1]], error = function(e) return(NA)),
PIID = tryCatch(list_element$awardID$awardContractID$PIID[[1]], error = function(e) return(NA)),
TRANSACTION_NUMBER = tryCatch(list_element$awardID$awardContractID$transactionNumber[[1]], error = function(e) return(NA)),
IDV_DEPARTMENT_ID = tryCatch(list_element$awardID$referencedIDVID$agencyID[[1]], error = function(e) return(NA)),
IDV_MODIFICATION_NUMBER = tryCatch(list_element$awardID$referencedIDVID$modNumber[[1]], error = function(e) return(NA)),
IDV_PIID = tryCatch(list_element$awardID$referencedIDVID$PIID[[1]], error = function(e) return(NA)),
DOLLARS_OBLIGATED = tryCatch(list_element$dollarValues$obligatedAmount[[1]], error = function(e) return(NA)),
DATE_SIGNED = tryCatch(list_element$relevantContractDates$signedDate[[1]], error = function(e) return(NA))
)
}
