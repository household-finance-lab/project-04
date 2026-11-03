* =====================================================================
* HFL Project 04 — 01_build.do
* Same Money, Different Feelings: Self-Discipline, Planning Horizon,
* and Financial Well-Being
*
* Data:   CFPB 2016 National Financial Well-Being Survey, public use file
* Run from the repository root (File > Change Working Directory).
* Input:  data/NFWBS_PUF_2016_data.csv  (download from the CFPB; see data/README.md)
* Output: data/p04_analytic.dta
*         data/p04_analytic.csv  (for Python)
*         logs/01_build.log
* Stata:  StataNow 19.5
*
* Every "assert" line is a validation check. If a number drifts from
* its expected value, the run stops at that line.
* =====================================================================

version 19
clear all
set more off

* ---------------------------------------------------------------------
* 1. Paths
* ---------------------------------------------------------------------
global raw  "data"
global proj "."

capture mkdir "logs"

capture log close
log using "$proj/logs/01_build.log", replace text

* ---------------------------------------------------------------------
* 2. Import
* ---------------------------------------------------------------------
import delimited using "$raw/NFWBS_PUF_2016_data.csv", case(preserve) clear

* ---------------------------------------------------------------------
* 3. Validation against published figures (before any construction)
* ---------------------------------------------------------------------

* V1. Respondents: 6,394 (CFPB public use file user guide)
assert _N == 6394

* V2. Weighted mean FWBscore, special codes excluded:
*     54.25 (Collins & Urban 2020, Table 2)
summarize FWBscore [aweight = finalwt] if FWBscore >= 0
assert abs(r(mean) - 54.25) < 0.01

* V3. SCFHORIZON unweighted counts (codebook):
*     refused 82; categories 1-5 = 1,022 / 923 / 1,730 / 1,574 / 1,063
local vals "-1 1 2 3 4 5"
local ns   "82 1022 923 1730 1574 1063"
forvalues i = 1/6 {
    local v : word `i' of `vals'
    local n : word `i' of `ns'
    quietly count if SCFHORIZON == `v'
    assert r(N) == `n'
}

* ---------------------------------------------------------------------
* 3b. Refusal propensity (auxiliary variable for multiple imputation, R11)
* ---------------------------------------------------------------------
* Number of survey items refused (-1), excluding the items imputed in R11.
* Captures a general tendency to refuse, a likely predictor of refusal.
* Expected: total 6,681 refusals across respondents; maximum 106.
quietly ds, has(type numeric)
egen nrefuse_all = anycount(`r(varlist)'), values(-1)
egen nrefuse_own = anycount(SELFCONTROL_1 SELFCONTROL_2 SELFCONTROL_3 ///
    SCFHORIZON MATHARDSHIP_2 MATHARDSHIP_3 MATHARDSHIP_4            ///
    MATHARDSHIP_5 MATHARDSHIP_6 REJECTED_1 HOUSING), values(-1)
gen nrefuse_other = nrefuse_all - nrefuse_own
label var nrefuse_other "Items refused elsewhere in the survey (R11 auxiliary)"
quietly summarize nrefuse_other
assert r(sum) == 6681
assert r(max) == 106
drop nrefuse_all nrefuse_own

* ---------------------------------------------------------------------
* 4. Outcome
* ---------------------------------------------------------------------
* Special codes: -1 refused, -4 not recorded -> missing
gen fwb = FWBscore if FWBscore >= 0
label var fwb "CFPB financial well-being score"

* Present- and future-focused item subscales (exploratory E1, E2).
* Items recoded so that higher = better; missing if any item missing.
foreach v in FWB1_2 FWB1_5 FWB1_6 FWB2_2 FWB2_3 FWB2_4 {
    gen i_`v' = `v' if `v' > 0
}
replace i_FWB1_5 = 6 - i_FWB1_5   // "I am just getting by financially"
replace i_FWB1_6 = 6 - i_FWB1_6   // "concerned the money ... won't last"
replace i_FWB2_3 = 6 - i_FWB2_3   // "I am behind with my finances"
replace i_FWB2_4 = 6 - i_FWB2_4   // "My finances control my life"

gen fwb_present = (i_FWB1_5 + i_FWB2_2 + i_FWB2_3 + i_FWB2_4) / 4
gen fwb_future  = (i_FWB1_2 + i_FWB1_6) / 2
label var fwb_present "Present-focused FWB items, mean (1-5, higher = better)"
label var fwb_future  "Future-focused FWB items, mean (1-5, higher = better)"
drop i_FWB*

* ---------------------------------------------------------------------
* 5. Decision-related characteristics
* ---------------------------------------------------------------------
* SELFCONTROL items: 1 not at all ... 4 completely well; -1 refused
gen sc1 = SELFCONTROL_1 if SELFCONTROL_1 > 0
gen sc2 = SELFCONTROL_2 if SELFCONTROL_2 > 0
gen sc3 = SELFCONTROL_3 if SELFCONTROL_3 > 0
label var sc1 "I often act without thinking through all the alternatives"
label var sc2 "I am good at resisting temptation"
label var sc3 "I am able to work diligently toward long-term goals"

* Measurement check M1: three-item alpha (item 1 reversed) = 0.52
alpha sc1 sc2 sc3, reverse(sc1) casewise
assert abs(r(alpha) - 0.52) < 0.01

* Measurement check M2: correlation of items 2 and 3 = 0.44
quietly correlate sc2 sc3
assert abs(r(rho) - 0.44) < 0.01

gen selfdisc  = (sc2 + sc3) / 2
gen impulsive = sc1
label var selfdisc  "Self-discipline: mean of SELFCONTROL_2 and _3 (1-4)"
label var impulsive "Impulsivity: SELFCONTROL_1 (1-4, higher = more impulsive)"

* Planning horizon: -1 refused -> missing
gen horizon = SCFHORIZON if SCFHORIZON > 0
label define hz 1 "Next few months" 2 "Next year" 3 "Next few years" ///
                4 "Next 5 to 10 years" 5 "Longer than 10 years"
label values horizon hz
label var horizon "Financial planning time horizon (ref = next few months)"

* ---------------------------------------------------------------------
* 6. Objective financial circumstances and knowledge
* ---------------------------------------------------------------------
gen inc = PPINCIMP
label define inc 1 "<$20k" 2 "$20-29k" 3 "$30-39k" 4 "$40-49k" 5 "$50-59k" ///
                 6 "$60-74k" 7 "$75-99k" 8 "$100-149k" 9 "$150k+"
label values inc inc
label var inc "Household income"

* Savings: 98 don't know, 99 prefer not to say, -1 refused -> category 0
gen sav = SAVINGSRANGES if inrange(SAVINGSRANGES, 1, 7)
replace sav = 0 if inlist(SAVINGSRANGES, 98, 99, -1)
label define sav 0 "DK / prefer not to say / refused" 1 "$0" 2 "$1-99" ///
                 3 "$100-999" 4 "$1,000-4,999" 5 "$5,000-19,999"   ///
                 6 "$20,000-74,999" 7 "$75,000+"
label values sav sav
label var sav "Savings range"

* Material hardship: 1 never, 2 sometimes, 3 often; -1 refused
forvalues i = 1/6 {
    gen mh`i' = (MATHARDSHIP_`i' >= 2) if MATHARDSHIP_`i' > 0
}
egen hardship5 = rowtotal(mh2-mh6)
egen nmiss5    = rowmiss(mh2-mh6)
replace hardship5 = . if nmiss5 > 0
egen hardship6 = rowtotal(mh1-mh6)
egen nmiss6    = rowmiss(mh1-mh6)
replace hardship6 = . if nmiss6 > 0
label var hardship5 "Material hardship count, items 2-6 (primary)"
label var hardship6 "Material hardship count, items 1-6 (R1)"
drop mh1-mh6 nmiss5 nmiss6

* Debt collection: 0 no, 1 yes, 8 not sure, -1 refused
gen collect4 = .
replace collect4 = 0 if COLLECT == 0
replace collect4 = 1 if COLLECT == 1
replace collect4 = 2 if COLLECT == 8
replace collect4 = 3 if COLLECT == -1
label define col 0 "No" 1 "Yes" 2 "Not sure" 3 "Refused"
label values collect4 col
label var collect4 "Contacted by debt collector, past 12 months (primary)"
gen collect_r4 = COLLECT if inlist(COLLECT, 0, 1)
label var collect_r4 "Debt collector contact, yes/no only (R4)"

gen rejected = REJECTED_1 if REJECTED_1 >= 0
label var rejected "Applied for credit and was turned down"

gen nprod = 0
forvalues i = 1/9 {
    replace nprod = nprod + (PRODHAVE_`i' == 1)
}
label var nprod "Number of financial products held (0-9)"

gen housing = HOUSING if HOUSING > 0
label define hous 1 "Own" 2 "Rent" 3 "Neither own nor rent"
label values housing hous
label var housing "Housing tenure"

* Employment: 99 refused kept as a category (primary); dropped in R4
gen employ = EMPLOY
label define emp 1 "Self-employed" 2 "Full-time" 3 "Part-time" 4 "Homemaker" ///
                 5 "Full-time student" 6 "Sick or disabled" 7 "Unemployed"   ///
                 8 "Retired" 99 "Refused"
label values employ emp
label var employ "Employment status (primary)"
gen employ_r4 = EMPLOY if EMPLOY != 99
label values employ_r4 emp
label var employ_r4 "Employment status, refused excluded (R4)"

* Financial knowledge: IRT score; negative values are legitimate
gen kh = KHscore
label var kh "Knoll-Houts financial knowledge score (IRT)"

* Sensitivity only: difficulty covering bills (R3)
gen endsmeet = ENDSMEET if ENDSMEET > 0
label define em 1 "Not at all difficult" 2 "Somewhat difficult" 3 "Very difficult"
label values endsmeet em
label var endsmeet "Difficulty covering monthly bills (R3 only)"

* ---------------------------------------------------------------------
* 7. Demographics
* ---------------------------------------------------------------------
label define age 1 "18-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-61" ///
                 6 "62-69" 7 "70-74" 8 "75+"
label values agecat age
gen age62 = (agecat >= 6)
label var age62 "Age 62 or older (CFPB scores FWB separately; R6)"

gen female = (PPGENDER == 2)
label var female "Female"

rename PPETHM ethnicity
rename PPEDUC educ
rename PPMARIT marital
label define eth 1 "White, non-Hispanic" 2 "Black, non-Hispanic" ///
                 3 "Other, non-Hispanic" 4 "Hispanic"
label values ethnicity eth
label define ed 1 "Less than high school" 2 "High school" 3 "Some college" ///
                4 "Bachelor's" 5 "Graduate/professional"
label values educ ed
label define mar 1 "Married" 2 "Widowed" 3 "Divorced/separated" ///
                 4 "Never married" 5 "Living with partner"
label values marital mar

* ---------------------------------------------------------------------
* 7b. Measurement-check and sensitivity variables (DESIGN 5.2, 5.4)
* ---------------------------------------------------------------------
* Propensity to plan: 1 strongly disagree ... 5 strongly agree; -1 refused
forvalues i = 1/4 {
    gen pp`i' = PROPPLAN_`i' if PROPPLAN_`i' > 0
}
gen propplan = (pp1 + pp2 + pp3 + pp4) / 4
label var propplan "Propensity to plan: mean of PROPPLAN_1-4 (1-5)"
drop pp1-pp4

gen frugality = FRUGALITY if FRUGALITY > 0
label var frugality "Frugality (measurement check)"

gen patient = (DISCOUNT == 2) if DISCOUNT > 0
label var patient "Chose $860 in three months over $816 now"

* Life satisfaction and optimism (R10): 1-7; -1 refused
forvalues i = 1/3 {
    gen swb`i' = SWB_`i' if SWB_`i' > 0
}
label var swb1 "I am satisfied with my life"
label var swb2 "I am optimistic about my future"
label var swb3 "If I work hard today, I will be more successful in the future"

* ---------------------------------------------------------------------
* 8. Analytic sample (DESIGN.md, Section 4)
* ---------------------------------------------------------------------
gen byte step = 1

quietly count if step & missing(fwb)
assert r(N) == 5
replace step = 0 if missing(fwb)

quietly count if step & missing(sc1, sc2, sc3)
assert r(N) == 61
replace step = 0 if missing(sc1, sc2, sc3)

quietly count if step & missing(horizon)
assert r(N) == 44
replace step = 0 if missing(horizon)

quietly count if step & missing(hardship5)
assert r(N) == 2
replace step = 0 if missing(hardship5)

quietly count if step & missing(rejected)
assert r(N) == 43
replace step = 0 if missing(rejected)

quietly count if step & missing(housing)
assert r(N) == 20
replace step = 0 if missing(housing)

gen byte insample = step & !missing(kh, inc, sav, collect4, nprod, employ, ///
                    agecat, female, ethnicity, educ, marital)
drop step
label var insample "Primary analytic sample"

* S1. Primary analytic sample: 6,219
count if insample
assert r(N) == 6219

* S2. Weighted mean FWBscore in the analytic sample: 54.29
summarize fwb [aweight = finalwt] if insample
assert abs(r(mean) - 54.29) < 0.01

* Sensitivity samples
gen byte sample_r3 = insample & !missing(endsmeet)
gen byte sample_r4 = insample & !missing(collect_r4, employ_r4)
label var sample_r3 "R3 sample: ENDSMEET non-missing"
label var sample_r4 "R4 sample: not sure / refused excluded"
count if sample_r3
assert r(N) == 6205
count if sample_r4
assert r(N) == 5910

* ---------------------------------------------------------------------
* 9. Survey design and save
* ---------------------------------------------------------------------
svyset _n [pweight = finalwt]

keep PUF_ID finalwt fwb fwb_present fwb_future selfdisc impulsive        ///
     sc1 sc2 sc3 horizon kh inc sav hardship5 hardship6 collect4         ///
     collect_r4 rejected nprod housing employ employ_r4 endsmeet         ///
     agecat age62 female ethnicity educ marital propplan frugality patient    ///
     swb1 swb2 swb3 nrefuse_other insample sample_r3 sample_r4
order PUF_ID finalwt insample sample_r3 sample_r4 fwb fwb_present fwb_future

compress
save "$proj/data/p04_analytic.dta", replace
export delimited using "$proj/data/p04_analytic.csv", nolabel replace

display as result "01_build.do finished: all validation checks passed."
log close
