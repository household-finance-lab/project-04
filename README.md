# Same Money, Different Feelings

**Household Finance Lab · Project 4 · 2016 CFPB National Financial Well-Being Survey**
*Self-Discipline, Impulsivity, Planning Horizon, and Financial Well-Being: Evidence from the 2016 CFPB Survey*

Two households can have similar incomes and savings and feel very differently about their financial lives. After accounting for those circumstances, does the way people approach decisions tell us anything about how financially secure they feel?

A little. Among U.S. adults in similar reported financial circumstances, each scale point of self-discipline (on a 1–4 scale) was associated with **3.15 points** higher financial well-being (95% CI: 2.59 to 3.71; the scale's standard deviation is about 13.7). Adding self-discipline, impulsivity, and planning horizon raised out-of-sample R² by about **0.03** (linear model: +0.028, approximate interval 0.020 to 0.037), and improved prediction in all 25 cross-validation folds. Circumstances carry most of the variation; the decision measures add a modest share. Standard errors are approximate: the public file releases no design strata or PSUs.

**What it does not show:** that self-discipline causes financial well-being, that building it would raise a person's score, or that psychological measures can substitute for resources. The data are cross-sectional, and the controls are not a full balance sheet: debt balances, net worth, and local costs are not measured.

📖 [**Read the story**](docs/empirically-yours.md) (Empirically Yours №4) · 🔁 [**Reproduce it**](#reproduce-it) · 📎 [**Cite it**](CITATION.cff)

> **Research status:** observational analysis of cross-sectional survey data. The research question and hypotheses H1–H3 were fixed before analysis; exploratory expectation E2 and several specification choices were added after preliminary runs, and each is listed in [`DESIGN.md`](DESIGN.md), Section 8. **Not peer reviewed.**

---

## Methodological lesson

**Adjustment changes the question.** Without circumstances in the model, self-discipline is associated with 5.40 points; with them, 3.15. The smaller number is the association among people in similar circumstances. It is a different quantity, and controlling for circumstances that may themselves reflect earlier self-discipline does not by itself remove bias.

**Check items before trusting a scale.** The survey's three self-control items do not form one scale, and only one of the two self-discipline items has a clear association with the outcome. An averaged score would have hidden both.

## What this study supports

- **H1, H2, H3 supported.** Among adults in similar reported circumstances, those with more self-discipline, less impulsivity, and longer planning horizons report higher financial well-being. The three measures add 0.030 to weighted R² (joint test F(6, 6388) = 40.2, p < .001).
- **One self-discipline item carries the association.** "I am able to work diligently toward long-term goals": 2.86 points (95% CI 2.36 to 3.36). "I am good at resisting temptation": 0.38 points (95% CI −0.10 to 0.86).
- **Planning horizon rises in two steps,** from the next few months to the next year, and again at 5 to 10 years, with flat stretches between.
- **Two checks roughly halve the association.** Adding difficulty covering bills or life satisfaction reduces self-discipline to about 2 points; it remains clearly positive.

## What changed along the way

- **We guessed wrong on the future.** E1 expected self-discipline to matter more for present well-being. It had the larger association with future well-being (0.30 versus 0.21 standard deviations).
- **The self-control items were split.** The survey's three items did not behave as one scale, so two form self-discipline and the third is treated as impulsivity. E2, comparing the two, was added after reading Netemeyer et al. (2018).
- **An external review changed the reporting.** It corrected the standard-error description and added the excluded-case comparison, the horizon contrasts, item-level results, multiple-imputation checks, and prediction intervals. The full list is in [`DESIGN.md`](DESIGN.md), Section 8.
- **Who was excluded matters.** The 175 respondents dropped for refusing an item are poorer and more often non-White. Imputing their answers leaves the estimates essentially unchanged (3.19 versus 3.15), but the findings may describe them less well.

## What's here

| File | What it is |
|---|---|
| [`TECHNICAL-SUMMARY.md`](TECHNICAL-SUMMARY.md) | The full technical presentation: framework, measurement, validation, every table, robustness, prediction, and limitations |
| [`DESIGN.md`](DESIGN.md) | The plan: question, hypotheses, variables, methods, and decisions finalized after preliminary runs |
| [`ANALYTICAL-DECISIONS.md`](ANALYTICAL-DECISIONS.md) | Every choice and its alternative |
| [`CODEBOOK.md`](CODEBOOK.md) | Every variable: source, coding, how to rebuild it |
| [`LITERATURE.md`](LITERATURE.md) | Who established what before us, and what remains open |
| [`data/README.md`](data/README.md) | Where to get the data |
| `code/` | Stata build and analysis; Python prediction |
| `output/` | Result tables and the planning-horizon figure |

## Reproduce it

**Data** (free): `NFWBS_PUF_2016_data.csv`, the 2016 National Financial Well-Being Survey public use file from the CFPB. Save it in `data/`; see [`data/README.md`](data/README.md). No survey data are redistributed here.

**Software:** StataNow 19.5. Python 3.13.5: `pip install -r requirements.txt`.

**Run order,** from the repository folder:

```
do code/01_build.do         # build and validate; stops if any check drifts
do code/02_analyze.do       # all models; writes output/p04_results.csv
python code/03_predict.py --input data/p04_analytic.csv --output-dir output   # repeated cross-validation
```

**How you know it worked:** the build reproduces the published 6,394 respondents and the weighted mean financial well-being of 54.25 (Collins & Urban, 2020). The primary self-discipline coefficient is 3.15 on 6,219 complete cases.

## Authors

- **Lena Gan, PhD, CFP®, CIMA®**: inference (Stata)
- **Sara Kay** ([sarakay.me](https://sarakay.me)): prediction (Python)

## Tell us we're wrong

Open an Issue or email householdfinancelab@gmail.com. Corrections, failed reproductions, and "you've mischaracterized my paper" messages are all welcome.

## Using this work

Code: MIT (see [`LICENSE`](LICENSE)). Text, tables, and results: CC BY 4.0 (see [`LICENSE-CC-BY`](LICENSE-CC-BY)). The NFWBS public use file is published by the Consumer Financial Protection Bureau.
