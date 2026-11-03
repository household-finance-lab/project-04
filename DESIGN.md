# Project 4 — DESIGN

**Title:** Self-Discipline, Impulsivity, Planning Horizon, and Financial Well-Being: Evidence from the 2016 CFPB Survey
**Dataset:** Consumer Financial Protection Bureau, 2016 National Financial Well-Being Survey (public use file)
**Analysts:** Lena Gan (inference, Stata 19.5) · Sara Kay (prediction, Python)
**Status:** the research question and hypotheses were fixed before analysis. Specification choices finalized after preliminary runs are listed in Section 8 and documented, with their alternatives, in ANALYTICAL-DECISIONS.md.

---

## 1. Why this project

| Criterion | Assessment |
|---|---|
| Worth asking | Households with similar income and savings report very different levels of financial well-being. Whether decision-related traits account for part of that gap matters for financial educators and planners. |
| Answerable | All variables are in the 2016 public use file (verified against the codebook). |
| Contributory | On this survey, the CFPB's own analysis (Abt Associates, 2018) entered self-control only as a control, as a three-item average, and did not use the planning-horizon item. Collins & Urban (2020) omit both traits; Hudson et al. (2022) dichotomize horizon without controls for savings or hardship. Netemeyer et al. (2018) and van Raaij et al. (2023) use other well-being scales. This project separates impulsivity from self-discipline, adds planning horizon, measures the variation the traits add, and tests whether they improve out-of-sample prediction. |
| Communicable | Two people have the same money. Why does one feel secure and the other does not? |

## 2. Research question

After accounting for reported financial circumstances, are self-discipline and planning horizon associated with financial well-being among U.S. adults, and do they improve prediction of an individual's financial well-being?

*Note:* the question has two parts. The association part (H1–H3) is answered with survey-weighted regression in Stata. The prediction part is answered with cross-validated models in Python. The data are cross-sectional, so all findings are associations: they describe how financial well-being differs among adults in similar current circumstances. Current circumstances may partly reflect earlier self-discipline, so controlling for them changes the question being answered rather than isolating an effect.

## 3. Hypotheses

**H1 — Self-discipline (confirmatory).** Self-discipline is positively associated with financial well-being, controlling for reported financial circumstances, financial knowledge, and demographics.
*Basis:* The planner–doer model of self-control (Thaler & Shefrin, 1981) and the behavioral life-cycle hypothesis (Shefrin & Thaler, 1988); Abt Associates (2018) reported a small positive self-control coefficient on this survey after objective financial situation; Strömbäck et al. (2017) found self-control associated with lower financial anxiety and greater security, controlling for income bands.

**H2 — Planning horizon (confirmatory).** A longer financial planning horizon is positively associated with financial well-being, under the same controls.
*Basis:* Netemeyer et al. (2018) found long-term planning associated with expected future financial security; van Raaij et al. (2023) found future time perspective the main determinant of expected future security.

**H3 — Added variation (confirmatory).** Together, self-discipline, impulsivity, and planning horizon explain additional variation in financial well-being beyond reported financial circumstances and demographics.

**E1 — Present and future well-being (exploratory).** Self-discipline is more closely related to present-focused well-being items, and planning horizon to future-focused items.
*Basis:* van Raaij et al. (2023); Riitsalu & van Raaij (2022) found the antecedents of current and future financial well-being differ.

**E2 — Components of self-control (exploratory, added after preliminary runs).** Impulsivity and self-discipline relate differently to present and future well-being.
*Basis:* Netemeyer et al. (2018) found lack of self-control associated with current money management stress but not with expected future security; Hagger et al. (2021) separate restraint from impulsivity.

## 4. Sample

All adults in the public use file. No age or income restriction.

| Step | Respondents |
|---|---|
| All respondents, 2016 public use file | 6,394 |
| Excluded: FWBscore not recorded | 5 |
| Excluded: any self-control item refused | 61 |
| Excluded: SCFHORIZON refused | 44 |
| Excluded: material hardship items 2–6 refused | 2 |
| Excluded: REJECTED_1 refused | 43 |
| Excluded: HOUSING refused | 20 |
| **Analytic sample** | **6,219** |

## 5. Measures

All measures are self-reported answers to the survey. Self-report is the method, chosen because the outcome is a perception; each construct below is defined so readers can see exactly what is measured. Where we build an index, the items, coding, and rationale are stated, along with the evidence for treating the items as one measure. Full coding, special codes, and reference categories are in CODEBOOK.md.

### 5.1 Financial well-being (outcome)

**Definition.** How people perceive their financial situation: control over day-to-day finances, capacity to absorb a shock, being on track to meet goals, and freedom to make choices that allow enjoyment of life (CFPB, 2015).

**Measure.** The CFPB Financial Well-Being Scale score (FWBscore), used exactly as published. We did not build this scale. The CFPB developed it from consumer interviews, cognitive testing, and item response theory, and scores it separately for adults 62 and older (CFPB, 2017). Collins & Urban (2020) show on this survey that the score tracks income, savings, and hardship, rises with age, and is distinct from general life satisfaction (correlation 0.41). Our build reproduces their published weighted mean (54.25).

**Present and future subscales (exploratory only).** Our own grouping of six of the ten scale items, standardized: present-focused (just getting by; money left over; behind with finances; finances control my life) and future-focused (securing my financial future; concerned money won't last). The CFPB does not score these separately; we use them only to test E1 and E2.

### 5.2 Decision-related characteristics

| Construct | Definition used here | Items | Index |
|---|---|---|---|
| Self-discipline | Restraint: resisting temptation and persisting toward long-term goals | SELFCONTROL_2 "I am good at resisting temptation"; SELFCONTROL_3 "I am able to work diligently toward long-term goals" | Mean of two items, 1–4 |
| Impulsivity | Acting before weighing alternatives | SELFCONTROL_1 "I often act without thinking through all the alternatives" | Single item, 1–4, higher = more impulsive |
| Planning horizon | How far ahead a person looks when planning saving and spending | SCFHORIZON, the planning-horizon question from the Survey of Consumer Finances | Five categories, reference = "the next few months" |

**Why the self-control items are split.** Items 1 and 2 match wording from the Brief Self-Control Scale (Tangney et al., 2004). Across national samples, that scale separates into restraint and non-impulsivity (Hagger et al., 2021). On this survey the three items have low internal consistency together (α = 0.52); items 2 and 3 correlate at 0.44, and item 1 correlates weakly with both. Averaging all three, as the CFPB's analysis did, would mix two constructs.

**Supporting evidence for a pragmatic short index.** A correlation of 0.44 and a two-item reliability of about 0.61 support a pragmatic short index, not strong construct validation. The two items are therefore also reported separately in the main results. Correlations with related items in the same survey (Spearman, unweighted):

| | Propensity to plan (PROPPLAN_1–4) | Frugality | Patience (DISCOUNT) |
|---|---|---|---|
| Self-discipline | 0.36 | 0.24 | reported in analysis |
| Impulsivity | −0.18 | −0.17 | reported in analysis |
| Planning horizon | 0.03 | 0.04 | reported in analysis |

Self-discipline and impulsivity relate to planning behavior and frugality in the expected directions. Planning horizon is nearly unrelated to budgeting and goal-setting behavior. We therefore interpret it narrowly, as how far ahead a person looks, separate from whether they plan.

### 5.3 Reported financial circumstances

**Definition.** What a household has and what has happened to it, as distinct from how it feels about its finances. These are self-reported and mostly in brackets; the survey does not record debt amounts or net worth.

| Measure | Variable | Form |
|---|---|---|
| Household income | PPINCIMP | 9 brackets |
| Savings | SAVINGSRANGES | 7 brackets, plus a category for don't know, prefer not to say, refused |
| Material hardship | MATHARDSHIP_2–6 | Count of hardship events reported "sometimes" or "often" |
| Debt collection contact | COLLECT | No, yes, not sure, refused |
| Credit denial | REJECTED_1 | Yes, no |
| Financial products held | PRODHAVE_1–9 | Count |
| Housing tenure | HOUSING | Own, rent, neither |
| Employment | EMPLOY | Eight categories, refused kept |

**Excluded because they measure feelings that overlap the outcome:** ABSORBSHOCK (confidence in raising $2,000); ENDSMEET (difficulty covering bills, sensitivity analysis only); MATHARDSHIP_1 (worry about food running out, sensitivity analysis only).

### 5.4 Controls and other variables

| Role | Variable | Source |
|---|---|---|
| Control | Financial knowledge (IRT score) | KHscore |
| Demographics | Age group; sex; race and ethnicity; education; marital status | agecat; PPGENDER; PPETHM; PPEDUC; PPMARIT |
| Measurement checks | Propensity to plan; frugality; patience | PROPPLAN_1–4; FRUGALITY; DISCOUNT |
| Shared-mood check (R10) | Life satisfaction and optimism items | SWB_1–3 |
| Design | Final survey weight | finalwt |

## 6. Analysis plan

All estimates use the final survey weight (`finalwt`). The public file releases no strata, PSUs, or replicate weights; `svyset _n [pweight = finalwt]` therefore gives weighted Huber–White sandwich standard errors under an independence working assumption, which may understate uncertainty from the original sampling design. The 6,393 degrees of freedom come from this imposed pseudo-design.

### A. Descriptive (run first)
- Weighted mean FWBscore, all adults and by age group.
- Measurement: internal consistency of the self-control items; the convergent correlations in Section 5.2, including patience.
- Planning horizon distribution; weighted FWBscore by horizon category and by self-discipline level.
- Excluded versus retained respondents: weighted financial well-being, age, sex, income, education, race and ethnicity, and savings response (added after review).

### B. Confirmatory
| Test | Method |
|---|---|
| H1, H2 | Weighted linear regression of FWBscore in three blocks: (1) demographics; (2) + reported financial circumstances and knowledge; (3) + self-discipline, impulsivity, planning horizon |
| H3 | Change in weighted R² from block 2 to block 3; joint Wald test of the block-3 variables |
| Effect sizes | Coefficients with 95% CIs; self-discipline also per standard deviation; the two self-discipline items reported separately in the same table |
| Horizon pattern | Category estimates with 95% CIs (plotted); adjacent-category contrasts and a linear trend test as a descriptive summary (added after review) |

### C. Exploratory
| Analysis | Method |
|---|---|
| E1, E2 | Block-3 model estimated on the standardized present and future subscales jointly (stacked outcomes, all coefficients allowed to differ, standard errors clustered by respondent; equivalent to `suest`); Wald tests of whether each trait's coefficient differs between the two |
| Adjustment comparison | Self-discipline coefficient with and without the reported-circumstances block |

### D. Robustness
| ID | Check |
|---|---|
| R1 | Six-item material hardship index, including the food-worry item |
| R2 | No material hardship measure |
| R3 | ENDSMEET added to the reported-circumstances block |
| R4 | "Not sure" and "refused" on COLLECT and EMPLOY excluded rather than kept as categories (n = 5,910) |
| R5 | Self-control items entered individually |
| R6 | Ages 18–61 and 62+ estimated separately (the CFPB scores the scale differently for the two groups) |
| R7 | Planning horizon entered as a linear ordinal term |
| R8 | Unweighted estimates |
| R9 | Sensitivity analysis conditional on an assumed reliability of 0.61 for self-discipline (`eivreg`); the estimate depends on that assumed value; analytic weights, since `eivreg` does not accept survey weights |
| R10 | Life satisfaction and optimism (SWB_1–3) added as controls, to check whether a general positive outlook drives the associations; may also remove some real association |
| R11 | Multiple imputation (20 imputations, chained equations) of the refused items behind the exclusions; predictors: the outcome, all analysis-model variables, log survey weight, and refusals elsewhere in the survey; compared with the complete-case estimate (added after review) |
| R11b | Not-at-random sensitivity: imputed self-discipline items lowered and the imputed impulsivity item raised by 0.5 (added after review) |

### Reading rules
- H1–H3 are judged on the primary model.
- Exploratory results are reported as exploratory.
- Robustness checks that weaken the headline stay in the write-up.
- Nulls are reported with the estimate, 95% CI, and "did not resolve."

### Prediction
Do self-discipline, impulsivity, and planning horizon improve out-of-sample prediction of FWBscore beyond demographics, reported financial circumstances, and knowledge? Nested feature sets; five-fold cross-validation repeated five times (seeds 0–4), splitting individual respondents; encoding and scaling fitted within each training fold; gradient-boosting settings fixed in advance; linear regression and gradient boosting. Metrics on each held-out fold, weighted by `finalwt` so performance is targeted to the weighted adult population: R² = 1 − Σw(y − ŷ)²/Σw(y − ȳ_w), RMSE, and MAE. Baseline and augmented values are reported, with the paired gain and an approximate corrected resampled t interval (Nadeau & Bengio, 2003), treated as a sensitivity interval rather than a definitive 95% confidence interval (RMSE, MAE, and intervals added after review).

## 7. Validation

| Measure | Published | Our build |
|---|---|---|
| Respondents | 6,394 (CFPB user guide) | 6,394 |
| Weighted mean FWBscore | 54.25, SD 13.74 (Collins & Urban, 2020) | 54.25 |
| SCFHORIZON, unweighted counts, categories 1–5 | 1,022 / 923 / 1,730 / 1,574 / 1,063 (codebook) | identical |

Independently reproduced in Stata and Python.

## 8. Decisions finalized after preliminary runs

1. Material hardship counts items 2–6; the food-worry item moves to R1.
2. "Not sure" and "refused" on COLLECT and EMPLOY are kept as categories; exclusion moves to R4.
3. The three self-control items are not combined; items 2–3 form self-discipline and item 1 is impulsivity.
4. E2 was added after reading Netemeyer et al. (2018).
5. The control block is named "reported financial circumstances" rather than "objective circumstances," and the research question wording was updated to match. The variables are unchanged.
6. Measurement checks (Section 5.2), the joint test for E1 and E2, and robustness checks R9 and R10 were added.
7. After an external review: the standard-error description was corrected; the excluded-case comparison, horizon contrasts and plot, item-level results in the main table, R11 and R11b, and prediction RMSE, MAE, and approximate intervals were added; R9 was relabeled a sensitivity analysis; and the title was made descriptive.

None of these choices changed the direction or significance of the confirmatory results in preliminary runs. ANALYTICAL-DECISIONS.md reports each alternative.

## 9. Limitations

These follow from the design and apply whatever the results.

1. **Cross-sectional data.** The survey observes each person once, so the study describes associations and cannot establish direction. Feeling financially secure may make self-discipline easier, as well as the reverse.
2. **Controls that may be outcomes.** Savings, hardship, and credit problems may partly result from earlier self-discipline. Holding them constant estimates the association among people in similar circumstances, which may understate any total relationship.
3. **Brief trait measures.** Self-discipline rests on two items, impulsivity and planning horizon on one each. Measurement error biases their coefficients toward zero (R9 gauges how much). A latent-variable model (SEM) was considered and not used: with two items, the self-discipline factor is barely identified and would reproduce the reliability adjustment in R9 with more risk of unstable estimates. A fuller self-control scale, of four or more items, would allow one.
4. **One survey, one respondent.** All measures come from the same self-report at the same time, so a shared outlook can inflate associations (R10 checks this).
5. **Bracketed circumstances.** Income and savings are recorded in ranges, and debt balances, net worth, and local costs are not recorded, so the controls are not a full balance sheet and some differences in circumstances remain uncontrolled.
6. **Standard errors.** Without design strata and clustered PSUs, the sandwich standard errors may understate uncertainty from the original sampling design.
7. **Who is excluded.** The 175 respondents excluded for refusing model items (2.7%) have lower financial well-being and income, less education, and more often are non-White. Imputation leaves the estimates essentially unchanged, but complete-case findings may generalize less well to financially disadvantaged and historically underrepresented adults.
8. **Data from 2016.** The relationships may have shifted since; the study does not speak to current levels of financial well-being.
9. **Exploratory subscales.** The present and future groupings are ours; the CFPB validates the ten-item scale as a single score.

## References

Abt Associates. (2018). *Understanding the pathways to financial well-being. National Financial Well-Being Survey: Report 2*. Prepared for the Bureau of Consumer Financial Protection. Walker, J. T., Bocian, D. G., DeMarco, D., & Freeman, B.

Consumer Financial Protection Bureau. (2015). *Financial well-being: The goal of financial education*. https://files.consumerfinance.gov/f/201501_cfpb_report_financial-well-being.pdf

Consumer Financial Protection Bureau. (2017). *CFPB Financial Well-Being Scale: Scale development technical report*.

Collins, J. M., & Urban, C. (2020). Measuring financial well-being over the lifecourse. *The European Journal of Finance*, 26(4–5), 341–359. https://doi.org/10.1080/1351847X.2019.1682631

Hagger, M. S., Zhang, C.-Q., Kangro, E.-M., Ries, F., Wang, J. C. K., Heritage, B., & Chan, D. K. C. (2021). Trait self-control and self-discipline: Structure, validity, and invariance across national groups. *Current Psychology*, 40(3), 1015–1030. https://doi.org/10.1007/s12144-018-0021-6

Hudson, C. R., Copeland, C., & Young, J. (2022). Financial well-being: Psychological factors that affect African Americans' financial well-being. *Journal of Financial Therapy*, 13(2), 4. https://doi.org/10.4148/1944-9771.1296

Nadeau, C., & Bengio, Y. (2003). Inference for the generalization error. *Machine Learning*, 52(3), 239–281. https://doi.org/10.1023/A:1024068626366

Netemeyer, R. G., Warmath, D., Fernandes, D., & Lynch, J. G., Jr. (2018). How am I doing? Perceived financial well-being, its potential antecedents, and its relation to overall well-being. *Journal of Consumer Research*, 45(1), 68–89. https://doi.org/10.1093/jcr/ucx109

Riitsalu, L., & van Raaij, W. F. (2022). Current and future financial well-being in 16 countries. *Journal of International Marketing*, 30(3), 35–56. https://doi.org/10.1177/1069031X221095076

Shefrin, H. M., & Thaler, R. H. (1988). The behavioral life-cycle hypothesis. *Economic Inquiry*, 26(4), 609–643. https://doi.org/10.1111/j.1465-7295.1988.tb01520.x

Strömbäck, C., Lind, T., Skagerlund, K., Västfjäll, D., & Tinghög, G. (2017). Does self-control predict financial behavior and financial well-being? *Journal of Behavioral and Experimental Finance*, 14, 30–38. https://doi.org/10.1016/j.jbef.2017.04.002

Tangney, J. P., Baumeister, R. F., & Boone, A. L. (2004). High self-control predicts good adjustment, less pathology, better grades, and interpersonal success. *Journal of Personality*, 72(2), 271–324. https://doi.org/10.1111/j.0022-3506.2004.00263.x

Thaler, R. H., & Shefrin, H. M. (1981). An economic theory of self-control. *Journal of Political Economy*, 89(2), 392–406. https://doi.org/10.1086/260971

van Raaij, W. F., Riitsalu, L., & Põder, K. (2023). Direct and indirect effects of self-control and future time perspective on financial well-being. *Journal of Economic Psychology*, 99, 102667. https://doi.org/10.1016/j.joep.2023.102667
