// Sergiy Radyakin, World Bank, 2021
// Requires Survey Solutions API package for Stata and its dependencies
// >>> ssc install susoapi

clear all

local q1="0434573c-67b3-4d93-b1f0-799fb042f9e6"
local v1="1"
local rootfile="CHL_STRUCT"

local q2="cdbc65c2-7666-4111-a44b-b602553ae727"
local v2="1"
local workfolder="C:\TEMP\ealist-data\"
local currentfolder=`"`=c(pwd)'"'

do private.do
.s = .SuSo.new "$susoserver" "$susouser" "$susopassword" // from private.do

// download data
tempfile tmp
.s.export2, qid("`q1'$`v1'") status("Completed") ///
            saveto("`tmp'") replace

// unpack data
capture mkdir "`workfolder'"
cd "`workfolder'"
unzipfile `"`tmp'"', replace

// process data
use "`rootfile'.dta", clear

merge 1:1 interview__id using "interview__diagnostics.dta", keepusing(responsible)
assert _merge==3
drop _merge

// iterate over structures
forval i=1/`=_N' {
	if (interview__status[`i']==100 /* Status 100 is 'Completed' */) {

        display " {break}Found building to process: `=streetAddr[`i']'"

        if (autoprocessready[`i']==1) {
            // If the building is residential and operational 
            // (and otherwise eligible) and number of apts entered.

            // create new assignments for this building's apartments.
            
            local nd=numDwellings[`i']  
            assert inrange(`nd',0,999) // this is expected to be a reasonable number [1..999]
            
            forval j=1/`nd' {
                display "Processing building `i' apt `j'!"

                local d=`" {"Variable":"province", "Answer":"`=province[`i']'"}, "' + ///
                        `" {"Variable":"city", "Answer":"`=city[`i']'"},"' + ///
                        `" {"Variable":"ea", "Answer":"`=ea[`i']'"},"' + ///
                        `" {"Variable":"streetAddr", "Answer":"`=streetAddr[`i']'"},"' + ///
                        `" {"Variable":"description", "Answer":"`=description[`i']'"},"' + ///
                        `" {"Variable":"location", "Answer":"`=location__Latitude[`i']'\$`=location__Longitude[`i']'"},"' + ///
                        `" {"Variable":"dwellingNum", "Answer":"`j'"}"'

                local responsible `"`=responsible[`i']'"'

                .s.assignments_create, ///
                    qxguid ("`q2'") qxversion(`v2') responsible("`responsible'") ///
                    data(`d') comment("Created by API")
            }
            
            .s.interviews_hqapprove `=interview__id[`i']' "Processed by API `c(current_date)' `c(current_time)'"
        }
    }
}

// clean-up
clear
erase `"`tmp'"'
cd `"`currentfolder'"'
assert substr("`workfolder'",1,8)=="C:\TEMP\"
shell rmdir /Q /S "`workfolder'"
