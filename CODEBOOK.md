# Codebook

Variables in `p04_analytic.dta` / `p04_analytic.csv`, built by `01_build.do` from the CFPB 2016 National Financial Well-Being Survey public use file. Survey special codes (−1 refused, −2 not asked, −3 invalid, −4 not recorded, −5 county unknown) are set to missing unless stated otherwise.

## Identifiers, weight, and samples

| Variable | Description | Coding |
|---|---|---|
| `PUF_ID` | Respondent identifier | As in source |
| `finalwt` | Final survey weight | As in source |
| `insample` | Primary analytic sample | 1 = included (n = 6,219) |
| `sample_r3` | R3 sample: `endsmeet` non-missing | 1 = included (n = 6,205) |
| `sample_r4` | R4 sample: "not sure"/refused on collection and employment excluded | 1 = included (n = 5,910) |

## Outcome

| Variable | Source | Coding |
|---|---|---|
| `fwb` | FWBscore | CFPB Financial Well-Being Scale score, as published |
| `fwb_present` | FWB1_5, FWB2_2, FWB2_3, FWB2_4 | Mean of four items, 1–5, higher = better; FWB1_5, FWB2_3, FWB2_4 reversed; missing if any item missing |
| `fwb_future` | FWB1_2, FWB1_6 | Mean of two items, 1–5, higher = better; FWB1_6 reversed; missing if any item missing |

## Decision-related characteristics

| Variable | Source | Coding |
|---|---|---|
| `sc1` | SELFCONTROL_1 | "I often act without thinking through all the alternatives," 1 = not at all to 4 = completely well |
| `sc2` | SELFCONTROL_2 | "I am good at resisting temptation," 1–4 |
| `sc3` | SELFCONTROL_3 | "I am able to work diligently toward long-term goals," 1–4 |
| `selfdisc` | sc2, sc3 | Mean of the two items, 1–4 |
| `impulsive` | sc1 | 1–4, higher = more impulsive |
| `horizon` | SCFHORIZON | 1 next few months (reference); 2 next year; 3 next few years; 4 next 5 to 10 years; 5 longer than 10 years |

## Reported financial circumstances

| Variable | Source | Coding |
|---|---|---|
| `inc` | PPINCIMP | 1 <$20k (reference) … 9 $150k+ |
| `sav` | SAVINGSRANGES | 0 don't know / prefer not to say / refused (reference); 1 $0; 2 $1–99; 3 $100–999; 4 $1,000–4,999; 5 $5,000–19,999; 6 $20,000–74,999; 7 $75,000+ |
| `hardship5` | MATHARDSHIP_2–6 | Count (0–5) of items answered "sometimes" or "often"; missing if any item refused |
| `hardship6` | MATHARDSHIP_1–6 | Count (0–6), same rule; R1 only |
| `collect4` | COLLECT | 0 no (reference); 1 yes; 2 not sure; 3 refused |
| `collect_r4` | COLLECT | 0 no; 1 yes; otherwise missing; R4 only |
| `rejected` | REJECTED_1 | 1 = applied for credit and was turned down |
| `nprod` | PRODHAVE_1–9 | Count (0–9) of financial products held |
| `housing` | HOUSING | 1 own (reference); 2 rent; 3 neither |
| `employ` | EMPLOY | 1 self-employed (reference); 2 full-time; 3 part-time; 4 homemaker; 5 full-time student; 6 sick or disabled; 7 unemployed; 8 retired; 99 refused |
| `employ_r4` | EMPLOY | As `employ`, refused set to missing; R4 only |
| `endsmeet` | ENDSMEET | 1 not at all difficult; 2 somewhat; 3 very difficult; R3 only |

## Controls

| Variable | Source | Coding |
|---|---|---|
| `kh` | KHscore | Knoll–Houts financial knowledge score (IRT); negative values are legitimate |
| `agecat` | agecat | 1 18–24 (reference); 2 25–34; 3 35–44; 4 45–54; 5 55–61; 6 62–69; 7 70–74; 8 75+ |
| `age62` | agecat | 1 = age 62 or older; R6 only |
| `female` | PPGENDER | 1 = female |
| `ethnicity` | PPETHM | 1 White, non-Hispanic (reference); 2 Black, non-Hispanic; 3 Other, non-Hispanic; 4 Hispanic |
| `educ` | PPEDUC | 1 less than high school (reference); 2 high school; 3 some college; 4 bachelor's; 5 graduate/professional |
| `marital` | PPMARIT | 1 married (reference); 2 widowed; 3 divorced/separated; 4 never married; 5 living with partner |

## Measurement checks and sensitivity variables

| Variable | Source | Coding |
|---|---|---|
| `propplan` | PROPPLAN_1–4 | Mean of four items, 1 strongly disagree to 5 strongly agree |
| `frugality` | FRUGALITY | As in source, 1–6 |
| `patient` | DISCOUNT | 1 = chose $860 in three months over $816 now |
| `swb1` | SWB_1 | "I am satisfied with my life," 1–7; R10 only |
| `swb2` | SWB_2 | "I am optimistic about my future," 1–7; R10 only |
| `nrefuse_other` | all survey items | Number of items refused (−1) elsewhere in the survey, excluding the items imputed in R11; auxiliary predictor for R11 |
| `swb3` | SWB_3 | "If I work hard today, I will be more successful in the future," 1–7; R10 only |
