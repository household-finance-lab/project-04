* =====================================================================
* HFL Project 04 — 02_analyze.do  (Stage 2: inference)
* Same Money, Different Feelings: Self-Discipline, Planning Horizon,
* and Financial Well-Being
*
* Run from the repository root, after 01_build.do.
* Input:  data/p04_analytic.dta
* Output: output/p04_results.csv, output/p04_horizon_margins.png
*         logs/02_analyze.log
* Stata:  StataNow 19.5
*
* Revised after external review: A5 excluded-case profile, B trend and
* adjacent-category contrasts for horizon, B items table, R9 relabeled,
* R11 multiple imputation. These additions are post-review and are
* labeled as such in DESIGN.md, Section 8.
*
* Variance: svyset _n [pweight = finalwt]. The public file releases no
* strata, PSUs, or replicate weights. Standard errors are therefore
* weighted Huber-White sandwich standard errors under an independence
* working assumption; because design strata and clustered PSUs are
* unavailable, they may understate uncertainty from the original sampling
* design. The 6,393 degrees of freedom come from this imposed pseudo-design,
* not from known survey-design degrees of freedom.
*
* Order follows DESIGN.md, Section 6: A descriptive, B confirmatory,
* C exploratory, D robustness. "Expected" comments are the preliminary
* Python estimates on the same specification; small differences in
* standard errors are normal (Stata uses survey linearization).
* =====================================================================

version 19
clear all
set more off

global proj "."
capture mkdir "output"
capture mkdir "logs"
capture log close
log using "$proj/logs/02_analyze.log", replace text

use "$proj/data/p04_analytic.dta", clear
assert _N == 6394
count if insample
assert r(N) == 6219

svyset _n [pweight = finalwt]

* Variable blocks (DESIGN.md, Section 5)
global demo   "i.agecat female i.ethnicity i.educ i.marital"
global circ   "i.inc i.sav hardship5 i.collect4 rejected nprod i.housing i.employ kh"
global traits "selfdisc impulsive i.horizon"

* Results file: one row per model pair
tempname res
postfile `res' str24 model double(b_selfdisc se_selfdisc ll ul r2_base r2_full dr2) ///
    long n using "$proj/output/p04_results_tmp.dta", replace

* Helper: base model, then base + extra; posts self-discipline and the R2 change
capture program drop pair
program define pair
    args id sample base extra
    quietly svy, subpop(`sample'): regress fwb `base'
    local r2b = e(r2)
    quietly svy, subpop(`sample'): regress fwb `base' `extra'
    local r2f = e(r2)
    local n   = e(N_sub)
    local df  = e(df_r)
    capture local b  = _b[selfdisc]
    if _rc local b = .
    capture local se = _se[selfdisc]
    if _rc local se = .
    local t = invttail(`df', 0.025)
    post $RES ("`id'") (`b') (`se') (`b' - `t'*`se') (`b' + `t'*`se') ///
        (`r2b') (`r2f') (`r2f' - `r2b') (`n')
    display as result "`id'" _col(26) "n = " `n' _col(40) ///
        "R2 " %5.3f `r2b' " -> " %5.3f `r2f' "  (change " %5.3f (`r2f' - `r2b') ")" ///
        _col(80) "self-discipline b = " %5.2f `b' " (SE " %4.2f `se' ")"
end
global RES "`res'"

* =====================================================================
* A. DESCRIPTIVE
* =====================================================================

* A1. Weighted mean FWBscore, all adults in the sample and by age group
*     Expected: 54.29
svy, subpop(insample): mean fwb
svy, subpop(insample): mean fwb, over(agecat)

* A2. Measurement: self-control items (DESIGN 5.2)
*     Expected: three-item alpha 0.52; items 2-3 correlation 0.44
alpha sc1 sc2 sc3 if insample, reverse(sc1) casewise
correlate sc2 sc3 if insample

* A3. Convergent validity (Spearman, unweighted)
*     Expected: self-discipline with propensity to plan 0.36, frugality 0.24;
*     impulsivity -0.18, -0.17; planning horizon 0.03, 0.04
spearman selfdisc impulsive horizon propplan frugality patient if insample, stats(rho obs)

* A4. Planning horizon distribution, and FWB by horizon and self-discipline
svy, subpop(insample): proportion horizon
svy, subpop(insample): mean fwb, over(horizon)
gen sd_group = cond(selfdisc < 2.5, 1, cond(selfdisc < 3.5, 2, 3)) if !missing(selfdisc)
label define sdg 1 "Low (1-2)" 2 "Middle (2.5-3)" 3 "High (3.5-4)"
label values sd_group sdg
svy, subpop(insample): mean fwb, over(sd_group)

* A5. Excluded versus retained respondents (post-review addition)
*     Weighted means; each variable estimated separately so one missing
*     value does not drop a respondent from the other comparisons.
*     Expected (retained / excluded):
*       fwb 54.29 / 53.00     age 62+ .239 / .257    female .514 / .566
*       income <$40k .317 / .460    bachelor's+ .311 / .155
*       non-White .352 / .510       savings DK/refused .186 / .494
gen byte lowinc   = (inc <= 3)
gen byte ba_plus  = (educ >= 4)
gen byte nonwhite = (ethnicity != 1)
gen byte sav_dk   = (sav == 0)
foreach v in fwb age62 female lowinc ba_plus nonwhite sav_dk {
    svy: mean `v', over(insample)
}
count if !insample
display as result "Excluded respondents: " r(N) " of 6,394 (" %4.1f 100*r(N)/6394 "%)"

* =====================================================================
* B. CONFIRMATORY: H1, H2, H3
* =====================================================================

* Block 1: demographics.  Expected R2 0.169
svy, subpop(insample): regress fwb $demo
estimates store m1

* Block 2: + reported financial circumstances and knowledge.  Expected R2 0.491
svy, subpop(insample): regress fwb $demo $circ
estimates store m2

* Block 3: + self-discipline, impulsivity, planning horizon.  Expected R2 0.521
*   Expected coefficients (SE):
*     selfdisc   3.15 (0.29)      H1
*     impulsive -1.05 (0.20)
*     horizon 2  1.70 (0.51)      H2 (ref = next few months)
*     horizon 3  1.74 (0.48)
*     horizon 4  2.94 (0.49)
*     horizon 5  3.41 (0.56)
*     kh        -0.30 (0.24)      control
svy, subpop(insample): regress fwb $demo $circ $traits
estimates store m3

* H3: joint test of the block-3 variables, and the change in R2 (expected 0.030)
test selfdisc impulsive 2.horizon 3.horizon 4.horizon 5.horizon
pair "Primary" "insample" "$demo $circ" "$traits"

* Effect size: self-discipline per standard deviation (expected SD 0.60; 1.9 points)
quietly svy, subpop(insample): regress fwb $demo $circ $traits
local b = _b[selfdisc]
summarize selfdisc [aweight = finalwt] if insample
display as result "Self-discipline, per SD: " %5.2f `b' * r(sd) " FWB points"

* Adjusted FWB by planning horizon
quietly svy, subpop(insample): regress fwb $demo $circ $traits
margins horizon, subpop(insample)
marginsplot, recast(scatter) xtitle("Planning horizon") ///
    ytitle("Adjusted financial well-being") title("")      ///
    xlabel(, angle(20) labsize(small)) xscale(range(0.7 5.3))
graph export "$proj/output/p04_horizon_margins.png", replace

* Planning horizon: ordered pattern (post-review addition)
*   p. = orthogonal polynomial contrasts; the linear term is the trend test.
*   ar. = each category versus the one before it.
*   The categorical model is the result; the linear trend is a compact
*   descriptive summary, not evidence that the relationship is linear.
quietly svy, subpop(insample): regress fwb $demo $circ $traits
contrast p.horizon
contrast ar.horizon

* Self-discipline items, reported in the main results table
*   (same model with the two items in place of the index)
*   Expected: sc3 (long-term goals) 2.86; sc2 (temptation) 0.38; sc1 -1.14
svy, subpop(insample): regress fwb $demo $circ sc1 sc2 sc3 i.horizon

* =====================================================================
* C. EXPLORATORY: E1, E2, and the adjustment comparison
* =====================================================================

* C1. Adjustment comparison: self-discipline without the circumstances block
*     Expected: 5.4 (versus 3.15 with the block)
svy, subpop(insample): regress fwb $demo $traits

* C2. E1, E2: present- and future-focused subscales, estimated jointly.
*     The two outcomes are stacked and every coefficient is allowed to
*     differ by outcome; standard errors are clustered by respondent.
*     This is equivalent to estimating the two models together (suest).
*     Expected (standardized outcomes):
*                    present   future
*       selfdisc      0.209    0.301
*       impulsive    -0.068   -0.004
*       horizon 5     0.241    0.198
preserve
keep if insample & !missing(fwb_present, fwb_future)
foreach v in fwb_present fwb_future {
    quietly summarize `v' [aweight = finalwt]
    gen z_`v' = (`v' - r(mean)) / r(sd)
}
gen long id = _n
expand 2
bysort id: gen byte outcome = _n
label define oc 1 "Present" 2 "Future"
label values outcome oc
gen z = cond(outcome == 1, z_fwb_present, z_fwb_future)

regress z i.outcome##(i.agecat c.female i.ethnicity i.educ i.marital         ///
                      i.inc i.sav c.hardship5 i.collect4 c.rejected c.nprod  ///
                      i.housing i.employ c.kh                                ///
                      c.selfdisc c.impulsive i.horizon)                      ///
      [pweight = finalwt], vce(cluster id)

* Coefficients by outcome
lincom selfdisc
lincom selfdisc + 2.outcome#c.selfdisc
lincom impulsive
lincom impulsive + 2.outcome#c.impulsive

* Tests of whether each trait differs between present and future
test 2.outcome#c.selfdisc
test 2.outcome#c.impulsive
test 2.outcome#2.horizon 2.outcome#3.horizon 2.outcome#4.horizon 2.outcome#5.horizon
restore

* =====================================================================
* D. ROBUSTNESS (DESIGN.md, Section 6D)
*    Expected: R2 change and self-discipline b (SE)
* =====================================================================

* R1. Six-item hardship index.          Expected 0.029; 3.10 (0.28)
pair "R1 six-item hardship" "insample" ///
    "$demo i.inc i.sav hardship6 i.collect4 rejected nprod i.housing i.employ kh" "$traits"

* R2. No hardship measure.               Expected 0.036; 3.27 (0.30)
pair "R2 no hardship" "insample" ///
    "$demo i.inc i.sav i.collect4 rejected nprod i.housing i.employ kh" "$traits"

* R3. ENDSMEET added (n = 6,205).        Expected 0.016; 2.37 (0.27)
pair "R3 + ENDSMEET" "sample_r3" "$demo $circ i.endsmeet" "$traits"

* R4. Not sure/refused excluded (n = 5,910). Expected 0.032; 3.32 (0.30)
pair "R4 exclusions" "sample_r4" ///
    "$demo i.inc i.sav hardship5 i.collect_r4 rejected nprod i.housing i.employ_r4 kh" "$traits"

* R5. Self-control items entered individually. Expected R2 change 0.034
svy, subpop(insample): regress fwb $demo $circ sc1 sc2 sc3 i.horizon
pair "R5 items separately" "insample" "$demo $circ" "sc1 sc2 sc3 i.horizon"

* R6. Ages 18-61 and 62+ separately.
*     Expected 18-61 (n = 4,029): 0.029; 2.80 (0.32)
*     Expected 62+   (n = 2,190): 0.041; 4.32 (0.58)
pair "R6 ages 18-61" "if insample & age62 == 0" "$demo $circ" "$traits"
pair "R6 ages 62+"   "if insample & age62 == 1" "$demo $circ" "$traits"

* R7. Planning horizon as a linear term. Expected 0.029; 3.16; horizon 0.83 per category
pair "R7 horizon linear" "insample" "$demo $circ" "selfdisc impulsive c.horizon"
svy, subpop(insample): regress fwb $demo $circ selfdisc impulsive c.horizon

* R8. Unweighted.                         Expected 0.033; 3.53 (0.26)
quietly regress fwb $demo $circ if insample, vce(robust)
local r2b = e(r2)
regress fwb $demo $circ $traits if insample, vce(robust)
local t = invttail(e(df_r), 0.025)
post $RES ("R8 unweighted") (_b[selfdisc]) (_se[selfdisc])            ///
    (_b[selfdisc] - `t'*_se[selfdisc]) (_b[selfdisc] + `t'*_se[selfdisc]) ///
    (`r2b') (e(r2)) (e(r2) - `r2b') (e(N))

* R9. Sensitivity analysis conditional on an assumed reliability of 0.61
*     for self-discipline (two items correlating 0.44; Spearman-Brown
*     2(0.44)/1.44 = 0.61). The estimate depends on that assumed value.
*     Analytic weights, because eivreg does not accept survey weights.
*     Expected 5.77.
eivreg fwb selfdisc impulsive i.horizon $demo $circ ///
    [aweight = finalwt] if insample, reliab(selfdisc 0.61)
post $RES ("R9 reliability .61") (_b[selfdisc]) (_se[selfdisc])     ///
    (_b[selfdisc] - invttail(e(df_r),0.025)*_se[selfdisc])              ///
    (_b[selfdisc] + invttail(e(df_r),0.025)*_se[selfdisc]) (.) (.) (.) (e(N))

* R10. Life satisfaction and optimism added. Expected (n = 6,152): 0.014; 1.96 (0.29)
gen byte sample_r10 = insample & !missing(swb1, swb2, swb3)
pair "R10 + SWB items" "sample_r10" "$demo $circ swb1 swb2 swb3" "$traits"

* R11. Multiple imputation (post-review addition)
*      Imputed: the refused items behind the exclusions (self-control items,
*      planning horizon, hardship items 2-6, credit denial, housing), for
*      everyone with a recorded FWBscore (n = 6,389). Not imputed: the
*      outcome; "don't know"/refused on savings, collection, and employment,
*      which stay as observed categories.
*      Imputation predictors: the outcome, every analysis-model variable,
*      log of the survey weight, and refusals elsewhere in the survey
*      (log of 1 + count). Imputation is unweighted; the analysis is weighted.
*      Items are imputed as ordered categories; indices are rebuilt from them.
*      Results are compared with the complete-case estimate (Primary);
*      neither is treated as the truth. No expected value: new analysis.
preserve
keep if !missing(fwb)
drop selfdisc impulsive
gen ln_wt     = ln(finalwt)
gen ln_refuse = ln(1 + nrefuse_other)
foreach v in sc1 sc2 sc3 {
    gen byte miss_`v' = missing(`v')
}
mi set wide
mi svyset _n [pweight = finalwt]
mi register imputed sc1 sc2 sc3 horizon hardship5 rejected housing
mi impute chained                                            ///
    (ologit, augment) sc1 sc2 sc3 horizon hardship5          ///
    (logit, augment) rejected                                ///
    (mlogit, augment) housing                                ///
    = fwb i.agecat female i.ethnicity i.educ i.marital       ///
      i.inc i.sav i.collect4 nprod i.employ kh               ///
      ln_wt ln_refuse,                                       ///
    add(20) rseed(20261026)
mi passive: gen selfdisc  = (sc2 + sc3) / 2
mi passive: gen impulsive = sc1

mi estimate, dftable: svy: regress fwb $demo $circ $traits
matrix T = r(table)
local j = colnumb(T, "selfdisc")
post $RES ("R11 multiple imputation") (T[1,`j']) (T[2,`j']) (T[5,`j']) ///
    (T[6,`j']) (.) (.) (.) (e(N))

* R11b. Not-at-random sensitivity (post-review addition)
*       Assumes people who refused a self-control item have less self-control
*       than their observed characteristics predict: imputed self-discipline
*       items are lowered by 0.5 and the imputed impulsivity item raised by 0.5.
mi passive: gen selfdisc_d  = ((sc2 - 0.5*miss_sc2) + (sc3 - 0.5*miss_sc3)) / 2
mi passive: gen impulsive_d = sc1 + 0.5*miss_sc1
mi estimate: svy: regress fwb $demo $circ selfdisc_d impulsive_d i.horizon
matrix T = r(table)
local j = colnumb(T, "selfdisc_d")
post $RES ("R11b MNAR shift 0.5") (T[1,`j']) (T[2,`j']) (T[5,`j']) ///
    (T[6,`j']) (.) (.) (.) (e(N))
restore

* =====================================================================
* Save results
* =====================================================================
postclose `res'
preserve
use "$proj/output/p04_results_tmp.dta", clear
format b_selfdisc se_selfdisc ll ul %6.3f
format r2_base r2_full dr2 %6.4f
list, noobs abbreviate(24)
export delimited using "$proj/output/p04_results.csv", replace
restore
erase "$proj/output/p04_results_tmp.dta"

display as result "02_analyze.do finished."
log close
