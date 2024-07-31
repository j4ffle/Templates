clear all

// Set working directory - I like to make it the main project shared folder that way I can access the data through "data/..." or print docs to the results folder "results/..."
cd "path/to/working_directory"
// Create a macro with today's date yyyymmdd. This helps to create documents with the date in the title
local wanted : di %tdDNCY daily("$S_DATE","DMY")
global today = substr("`wanted'",5,4)+substr("`wanted'",3,2)+substr("`wanted'",1,2)
di "$today"

use data\For_Regs, clear

// This creates labels for the variabls so when we print tables, we can use the labels instead of the variable names. the {\i } tells rtf that the text is to be italicized
label var x "{\i X}"

// Create useful macros for later
global controls_w z1 z2

// Table 1: Descriptive Statistics
// Panel A: Call Characteristics - if want higher level 
// This preserves the original dataset so that after we have done our calculations, we can call restore and come back to the original data
preserve
keep firm_id event_id x
duplicates drop
*If want to report any variables at a different unit - change them
replace vshrs = vshrs/1000
// Descriptive statistics - post and store the results so we can then tabulate them
eststo callChar: estpost sum z3 z4 z5, d

// Tabulate descriptive statistics - this creates a new file, replacing any file previously created with the same name
* \qc tells rtf to center the text {\b} tells rtf to bold text
esttab callChar using results/results_$today.rtf, replace ///
 cells("count(fmt(%13.0fc)) mean(fmt(%13.3fc)) sd(fmt(%13.3fc)) min(fmt(%13.3fc)) p25(fmt(%13.3fc)) p50(fmt(%13.3fc)) p75(fmt(%13.3fc)) max(fmt(%13.3fc))") nonumber ///
  nomtitle nonote noobs label collabels("N" "Mean" "Std. Dev" "Min" "25th" "50th" "75th" "Max") title(\qc{\b Table 1: Descriptive Statistics}\par\par\qj{\i Panel A: Call Characteristics})
// Restore original data to continue with analysis
restore

// Panel B: Conv Characteristics
eststo convChar: estpost sum y1 y2 x z1 z2, d
// Tabulate descriptive statistics - this creates a new file, replacing any file previously created with the same name
* \qj tells rtf to justify the text {\i} tells rtf to italicize text
esttab convChar using results/results_$today.rtf, append ///
 cells("count(fmt(%13.0fc)) mean(fmt(%13.3fc)) sd(fmt(%13.3fc)) min(fmt(%13.3fc)) p25(fmt(%13.3fc)) p50(fmt(%13.3fc)) p75(fmt(%13.3fc)) max(fmt(%13.3fc))") nonumber ///
  nomtitle nonote noobs label collabels("N" "Mean" "Std. Dev" "Min" "25th" "50th" "75th" "Max") title(\qj{\i Panel B: Conversation Characteristics})

  
// Table 2: Univariate Analysis 
// Panel A: Variance of y given sets of fixed effects
local i = 1
foreach fe of varlist event_id firm_id {

    eststo vd`i': qui reghdfe y , absorb(`fe') keepsing
    local i = `i' + 1

}

estfe vd*, labels(event_id "Call FE" firm_id "Firm FE")
esttab vd* using results/results_$today.rtf, append noconstant stat(N r2_a mss tss, label("Conversations" "Adj. R2" "Model SS" "Total SS") fmt(%9.0gc %9.3f %9.0fc %9.0fc)) indicate(`r(indicate_fe)') title(\page\qc{\b Table 2: Variance Decomposition for the use of Complex and Evasive Answers}) nogap label varwidth(31) modelwidth(7) nonote
estfe vd*, restore

// Panel B: Mean y by treatment status
// Perform t-test and store the results
eststo t: estpost ttest y1, by(x)
// Tabulate results and append to rtf file
esttab t using results/results_$today.rtf, append ///
 cells("mu_2(fmt(%13.4fc)) mu_1(fmt(%13.4fc)) b(fmt(%13.4fc)) t(fmt(%13.3fc)) p(fmt(%13.3fc))") nonumber ///
  nomtitle nonote noobs label collabels("=1" "=0" "Difference" "t-Stat" "p-Value") title(\qj{\i Panel B: Mean y given Treatment Status})

  