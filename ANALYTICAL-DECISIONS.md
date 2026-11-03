# Analytical Decisions

Every judgment call in this project, the alternative, and what changed when the alternative was run. Decisions marked † were finalized after preliminary runs; decisions marked ‡ were added after an external review (DESIGN.md, Section 8).

## Sample

**1. All adults, no age or income restriction.**
*Alternative considered:* adults aged 18–24 only (n = 414). Set aside because the sample is small (effective n about 300 under weights) and the question was already studied on this survey. Using all adults makes age a control and allows the age split in R6.

**2. Exclude respondents who refused an item in the primary model.** Exclusions total 175, leaving 6,219 (DESIGN.md, Section 4).

## Coding

**3. Special codes treated as missing:** −1 refused, −2 not asked, −3 invalid, −4 not recorded, −5 county unknown. `KHscore` takes legitimate negative values and is not recoded.

**4. Savings: "don't know," "prefer not to say," and refused kept as their own category.** 18% of respondents gave one of these answers; dropping them would remove a large, distinctive group.

**5. † Material hardship: count of items 2–6 answered "sometimes" or "often."**
*Alternatives:* all six items (R1); no hardship measure (R2).
*Why:* item 1 asks about *worry* that food would run out, a feeling that overlaps the outcome; items 2–6 record events.
*Effect:* self-discipline 3.10 (six items) and 3.27 (none) versus 3.15.

**6. † "Not sure" and "refused" on debt collection and employment kept as categories.**
*Alternative:* exclude them (R4, n = 5,910).
*Effect:* self-discipline 3.32 versus 3.15.

**7. Excluded from the circumstances block because they measure feelings that overlap the outcome:** confidence in raising $2,000 (`ABSORBSHOCK`); difficulty covering bills (`ENDSMEET`).
*Alternative:* `ENDSMEET` added (R3).
*Effect:* self-discipline 2.37; R² added by traits 0.016 versus 0.030. This check weakens the headline and is reported with it.

**8. † The three self-control items are not averaged.** Items 2–3 form self-discipline; item 1 is impulsivity.
*Why:* the three items have low internal consistency (α = 0.52); item 1 correlates weakly with the others; the Brief Self-Control Scale separates restraint from impulsivity (Hagger et al., 2021).
*Alternative:* items entered individually (R5).
*Effect:* "work diligently toward long-term goals" 2.86 (95% CI 2.36 to 3.36); "resisting temptation" 0.38 (−0.10 to 0.86). Only the first item has a clear association with financial well-being.

**9. Planning horizon as five categories.**
*Alternative:* a linear term (R7).
*Effect:* 0.83 points per category; self-discipline unchanged (3.16).

**10. Present and future subscales are our grouping of six scale items** (DESIGN.md, Section 5.1), used only for E1 and E2. The CFPB validates the scale as a single score.

**11. † Control block named "reported financial circumstances"** rather than "objective circumstances." The variables are unchanged; the label reflects that they are self-reported and bracketed.

## Estimation

**12. Survey weight (`finalwt`) with sandwich standard errors.** The public file releases no strata, PSUs, or replicate weights. `svyset _n [pweight = finalwt]` gives weighted Huber–White sandwich standard errors under an independence working assumption; they may understate uncertainty from the original sampling design. The 6,393 degrees of freedom come from this imposed pseudo-design.
*Alternative:* unweighted (R8). *Effect:* self-discipline 3.53.

**13. Linear regression in three blocks** for H1–H3, so the R² added by the traits can be reported directly.

**14. † E1 and E2 estimated jointly.** The two standardized subscales are stacked, every coefficient is allowed to differ by outcome, and standard errors are clustered by respondent. This tests whether a coefficient differs between present and future well-being, rather than comparing two separate models by eye.

**15. † Measurement error: sensitivity analysis conditional on an assumed reliability (R9).** Self-discipline's reliability is set at 0.61 (two items correlating 0.44; Spearman–Brown).
*Effect:* self-discipline 5.77. The estimate depends on the assumed reliability; it shows how much measurement error could matter if that value holds.
*Not used:* a latent-variable model (SEM). With two items, the self-discipline factor is barely identified and would reproduce the same adjustment with more risk of unstable estimates.

**16. † Shared outlook: life satisfaction and optimism items added (R10).**
*Effect:* self-discipline 1.96; R² added by traits 0.014. Because these items may also absorb some real association, this is a lower-bound check.

**17. Ages 18–61 and 62+ estimated separately (R6),** because the CFPB scores the scale differently for the two groups.
*Effect:* 2.80 and 4.32.

**21. ‡ Excluded respondents profiled.** The 175 excluded (2.7%) have, weighted, lower financial well-being (53.0 vs 54.3), more income under $40,000 (46% vs 32%), fewer bachelor's degrees (16% vs 31%), more non-White respondents (51% vs 35%), and more "don't know" or refused savings answers (49% vs 19%). Complete-case findings may generalize less well to financially disadvantaged and historically underrepresented adults.

**22. ‡ Multiple imputation (R11).** Imputed: the refused items behind the exclusions (three self-control items, planning horizon, hardship items 2–6, credit denial, housing), for the 6,389 respondents with a score. Not imputed: the outcome, and "don't know"/refused answers on savings, collection, and employment, which stay as observed categories because refusing to disclose money may itself be informative. Chained equations, 20 imputations, ordered logit for ordered items; predictors are the outcome, every analysis-model variable, log of the survey weight, and refusals elsewhere in the survey (log of 1 + count). Imputation is unweighted; analysis is weighted. Indices are rebuilt from imputed items.
*Effect:* self-discipline 3.19 (2.63 to 3.75) versus 3.15; largest fraction of missing information 0.07.

**23. ‡ Not-at-random sensitivity (R11b).** Imputed self-discipline items lowered, and the imputed impulsivity item raised, by 0.5.
*Effect:* 3.18. Only about 50 values per item were imputed, so this shows insensitivity to these refusals; it does not show the refusals are random.

**24. ‡ Planning horizon pattern.** The five categories remain the result. Adjacent-category contrasts and a linear trend test are added as descriptive summaries, with a plot of the category estimates.
*Effect:* well-being rises from next few months to next year (+1.70) and from next few years to 5–10 years (+1.20); the other two steps are not distinguishable from zero. Trend F = 42.5.

**25. ‡ Self-discipline items in the main table.** A two-item mean can conceal divergent items, so both items are reported alongside the index.

## Prediction

**18. Settings fixed before results were seen:**

| Setting | Value |
|---|---|
| Cross-validation | 5 folds × 5 repeats, seeds 0–4; same folds for every feature set and model |
| Feature sets | 1 demographics; 2 + circumstances and knowledge; 3 + decision traits |
| Linear model | Weighted least squares |
| Gradient boosting | HistGradientBoostingRegressor; 150 iterations; learning rate 0.05; 15 maximum leaf nodes; 20 minimum samples per leaf; L2 regularization 1.0; no early stopping |
| Encoding | Categorical predictors one-hot encoded; encoding and scaling fitted within each training fold |
| Weighting | `finalwt` in fitting and in held-out scoring |
| Metrics | Weighted out-of-sample R², RMSE, and MAE on each held-out fold (‡ RMSE and MAE added after review) |

**19. The 25 folds are reported as consistency across folds,** not as 25 independent replications; they reuse the same respondents. ‡ The paired gain (Set 3 minus Set 2) is reported with a corrected resampled t interval (Nadeau & Bengio, 2003), described as an approximate sensitivity interval rather than a definitive 95% confidence interval. The conclusion rests on the size and consistency of the gain.

**26. ‡ Weighting target.** Weighted training and scoring target predictive performance for the weighted U.S. adult population, which can differ from performance on the sampled records.

**20. Variable importance is descriptive** (permutation importance in the gradient-boosting model). Correlated predictors share information, so a low rank for income does not mean income is unrelated to financial well-being.
