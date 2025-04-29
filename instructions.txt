This code will pull data from the FPDS ATOM Feed. It is meant to help users keep up to date data bases of FPDS data by pulling daily or weekly extracts.

How this code works:
- atom_feed_definitions_final.csv defines how atom feed paths map to data elements in the final table. 
	To add a column, find it in the XML specification here: https://www.fpds.gov/wiki/index.php/Atom_Feed_Specifications_V_1.5.2. Then write out its path
	This code digests the XML by transforming it into List format. This also strips away the top layer of the xml path. Do should not include the Award$ or the IDV$ prefix on the paths
	Instead, structure your paths following this example: list_element$awardContractID$agencyID[[1]].
	If you are trying to pull data stored in a tag, use an attributes call instead. For example, attributes(list_element$productOrServiceInformation$principalNAICSCode)$description
	"list_element" is the placeholder variable utilized in the code. For now, it helps if you include it in your path writeups. 
- If you change the atom_feed_definitions_final.csv file, then run the update_atom_definitions.R file. This will translate the .csv into R functions that actually do the work. 
- To run the ATOM feed scrape, use atom_feed_control_script.R. The Steps there should walk you through how to run it. But all you should really need to edit are the start and end dates. 

