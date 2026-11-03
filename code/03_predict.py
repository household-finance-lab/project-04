#!/usr/bin/env python3
"""HFL Project 04: reproducible weighted out-of-sample prediction.
Usage: python 03_predict.py --input p04_analytic.csv --output-dir output
Requires pandas, numpy, scikit-learn. Run from repository root.
Five shuffled KFold repeats with seeds 0..4, shared across feature sets and models.
Weighted R2 is computed separately on each held-out fold using its own weighted mean.

Revised after external review:
- Weighted RMSE and MAE are reported alongside weighted R2.
- Paired differences between nested feature sets (Set 3 minus Set 2) are
  reported with a corrected resampled t interval (Nadeau and Bengio, 2003).
  These are approximate sensitivity intervals, not definitive 95% confidence
  intervals: repeated k-fold estimates are correlated, so the 25 fold-level
  values carry less independent information than 25 observations.
- The summary reports baseline and augmented R2, RMSE, and MAE for each set.

Workflow, from analytic file to each held-out prediction:
1. Keep insample == 1 (complete cases from 01_build.do; no imputation).
2. For each seed 0..4, KFold(5, shuffle=True) splits individual respondents.
3. Within each fold, one Pipeline is fitted on training rows only:
   OneHotEncoder for categorical predictors, StandardScaler for numeric
   predictors, then the model, with finalwt as sample_weight.
4. Gradient-boosting settings are fixed in advance (no tuning, no early stopping).
5. The fitted Pipeline predicts the held-out fold.

Metrics on each held-out fold (w = finalwt of the test rows):
  weighted R2   = 1 - sum(w*(y - yhat)^2) / sum(w*(y - ybar_w)^2),
                  ybar_w = weighted mean of y in the test fold
  weighted RMSE = sqrt(sum(w*(y - yhat)^2) / sum(w))
  weighted MAE  = sum(w*|y - yhat|) / sum(w)
Weighting targets predictive performance for the weighted U.S. adult
population represented by finalwt, which can differ from performance on
the sampled records.
"""
import argparse
import json
import platform
from pathlib import Path
import numpy as np
import pandas as pd
import sklearn
from scipy import stats
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import HistGradientBoostingRegressor
from sklearn.model_selection import KFold
from sklearn.metrics import r2_score
from sklearn.inspection import permutation_importance

DEM_CAT = ['agecat', 'educ', 'ethnicity', 'marital', 'female']
FIN_CAT = ['inc', 'sav', 'collect4', 'rejected', 'housing', 'employ']
FIN_NUM = ['hardship5', 'nprod', 'kh']
TRAIT_CAT = ['horizon']
TRAIT_NUM = ['selfdisc', 'impulsive']
SETS = {
    'Set 1': (DEM_CAT, []),
    'Set 2': (DEM_CAT + FIN_CAT, FIN_NUM),
    'Set 3': (DEM_CAT + FIN_CAT + TRAIT_CAT, FIN_NUM + TRAIT_NUM),
}
GB_SETTINGS = dict(max_iter=150, learning_rate=0.05, max_leaf_nodes=15,
                   min_samples_leaf=20, l2_regularization=1.0,
                   early_stopping=False, random_state=42)

def build_model(kind, cats, nums):
    transformer = ColumnTransformer([
        ('cat', OneHotEncoder(handle_unknown='ignore', sparse_output=False), cats),
        ('num', StandardScaler(), nums),
    ], remainder='drop', sparse_threshold=0)
    reg = LinearRegression() if kind == 'Linear' else HistGradientBoostingRegressor(**GB_SETTINGS)
    return Pipeline([('preprocess', transformer), ('regressor', reg)])

def evaluate(df, cohort, include_importance=False):
    records = []
    importance_rows = []
    y = df['fwb'].to_numpy(dtype=float)
    w = df['finalwt'].to_numpy(dtype=float)
    # Same folds for all six model-feature-set combinations, no leakage.
    for repeat in range(5):
        splitter = KFold(n_splits=5, shuffle=True, random_state=repeat)
        for fold, (tr, te) in enumerate(splitter.split(df), start=1):
            for kind in ['Linear', 'Gradient boosting']:
                for set_name, (cats, nums) in SETS.items():
                    model = build_model(kind, cats, nums)
                    cols = cats + nums
                    model.fit(df.iloc[tr][cols], y[tr], regressor__sample_weight=w[tr])
                    pred = model.predict(df.iloc[te][cols])
                    score = r2_score(y[te], pred, sample_weight=w[te])
                    err = y[te] - pred
                    rmse = float(np.sqrt(np.average(err ** 2, weights=w[te])))
                    mae = float(np.average(np.abs(err), weights=w[te]))
                    records.append(dict(cohort=cohort, repeat=repeat + 1, seed=repeat,
                                        fold=fold, model=kind, feature_set=set_name,
                                        n_train=len(tr), n_test=len(te), weighted_r2=score,
                                        weighted_rmse=rmse, weighted_mae=mae))
                    # One held-out fold per repeat for permutation importance, descriptive only.
                    if include_importance and kind == 'Gradient boosting' and set_name == 'Set 3' and fold == 1:
                        imp = permutation_importance(
                            model, df.iloc[te][cols], y[te], sample_weight=w[te],
                            scoring='r2', n_repeats=3, random_state=100 + repeat,
                            n_jobs=1)
                        for feature, value in zip(cols, imp.importances_mean):
                            importance_rows.append(dict(cohort=cohort, repeat=repeat + 1,
                                                        feature=feature, decrease_weighted_r2=value))
    return pd.DataFrame(records), pd.DataFrame(importance_rows)

def summarize(folds):
    rows = []
    for (cohort, kind), g in folds.groupby(['cohort', 'model'], sort=False):
        by_set = {name: g.loc[g.feature_set == name, 'weighted_r2'].to_numpy() for name in SETS}
        for name, scores in by_set.items():
            sub = g[g.feature_set == name]
            rows.append(dict(cohort=cohort, model=kind, feature_set=name,
                             mean_weighted_r2=scores.mean(), min_weighted_r2=scores.min(),
                             max_weighted_r2=scores.max(),
                             mean_weighted_rmse=sub.weighted_rmse.mean(),
                             mean_weighted_mae=sub.weighted_mae.mean(), n_folds=len(scores),
                             gain_mean=np.nan, gain_min=np.nan, gain_max=np.nan,
                             gain_positive_folds=np.nan))
        a = g[g.feature_set == 'Set 2'].set_index(['repeat', 'fold']).weighted_r2
        b = g[g.feature_set == 'Set 3'].set_index(['repeat', 'fold']).weighted_r2
        gain = (b - a).to_numpy()
        rows.append(dict(cohort=cohort, model=kind, feature_set='Set 3 minus Set 2',
                         mean_weighted_r2=np.nan, min_weighted_r2=np.nan,
                         max_weighted_r2=np.nan, mean_weighted_rmse=np.nan,
                         mean_weighted_mae=np.nan, n_folds=len(gain),
                         gain_mean=gain.mean(), gain_min=gain.min(), gain_max=gain.max(),
                         gain_positive_folds=int((gain > 0).sum())))
    return pd.DataFrame(rows)

def paired_gains(folds):
    """Set 3 minus Set 2 for each metric, with an approximate corrected resampled t interval.
    Nadeau and Bengio (2003): var_corrected = (1/k + n_test/n_train) * s^2,
    where k is the number of folds (25) and s^2 the variance of the fold differences."""
    rows = []
    for (cohort, kind), g in folds.groupby(['cohort', 'model'], sort=False):
        a = g[g.feature_set == 'Set 2'].set_index(['repeat', 'fold'])
        b = g[g.feature_set == 'Set 3'].set_index(['repeat', 'fold'])
        ratio = float((a.n_test / a.n_train).mean())
        for metric in ['weighted_r2', 'weighted_rmse', 'weighted_mae']:
            diff = (b[metric] - a[metric]).to_numpy()
            k = len(diff)
            mean = diff.mean()
            se = np.sqrt((1 / k + ratio) * diff.var(ddof=1))
            t = stats.t.ppf(0.975, k - 1)
            better = (diff > 0) if metric == 'weighted_r2' else (diff < 0)
            rows.append(dict(cohort=cohort, model=kind, metric=metric,
                             mean_difference=mean, ci_low=mean - t * se, ci_high=mean + t * se,
                             n_folds=k, folds_improved=int(better.sum())))
    return pd.DataFrame(rows)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--input', default='p04_analytic.csv')
    ap.add_argument('--output-dir', default='output')
    ap.add_argument('--skip-age', action='store_true')
    ap.add_argument('--age-only', action='store_true')
    args = ap.parse_args()
    out = Path(args.output_dir); out.mkdir(parents=True, exist_ok=True)
    df = pd.read_csv(args.input)
    assert len(df) == 6394, 'Expected 6394 source rows'
    df = df.loc[df.insample == 1].copy()
    assert len(df) == 6219, 'Expected 6219 primary analysis rows'
    required = set(['fwb', 'finalwt', 'age62'] + [x for cats, nums in SETS.values() for x in cats + nums])
    assert not df[list(required)].isna().any().any(), 'Missing values in primary model variables'
    assert (df.finalwt > 0).all(), 'Weights must be positive'
    frames = []; imps = []
    cohorts = [] if args.age_only else [('All adults', df)]
    if not args.skip_age:
        cohorts += [('Age 18–61', df.loc[df.age62 == 0].copy()),
                    ('Age 62+', df.loc[df.age62 == 1].copy())]
    for label, data in cohorts:
        print(f'Running {label}: n={len(data)}', flush=True)
        f, imp = evaluate(data.reset_index(drop=True), label, include_importance=(label == 'All adults'))
        frames.append(f)
        if not imp.empty: imps.append(imp)
    folds = pd.concat(frames, ignore_index=True)
    folds.to_csv(out / 'p04_prediction_folds.csv', index=False, float_format='%.10f')
    summary = summarize(folds)
    summary.to_csv(out / 'p04_prediction_summary.csv', index=False, float_format='%.10f')
    gains = paired_gains(folds)
    gains.to_csv(out / 'p04_prediction_gains.csv', index=False, float_format='%.10f')
    if imps:
        importance = pd.concat(imps).groupby('feature', as_index=False).agg(
            mean_decrease_weighted_r2=('decrease_weighted_r2', 'mean'),
            min_decrease_weighted_r2=('decrease_weighted_r2', 'min'),
            max_decrease_weighted_r2=('decrease_weighted_r2', 'max'))
        importance.sort_values('mean_decrease_weighted_r2', ascending=False).to_csv(
            out / 'p04_gb_importance_descriptive.csv', index=False, float_format='%.10f')
    settings = dict(python=platform.python_version(), pandas=pd.__version__, numpy=np.__version__,
                    scikit_learn=sklearn.__version__, seeds=list(range(5)),
                    folds_per_repeat=5, train_weights='finalwt',
                    test_metric='weighted R2 (sklearn r2_score, sample_weight=finalwt), weighted RMSE, weighted MAE per held-out fold',
                    gain_interval='Set 3 minus Set 2, approximate sensitivity interval: corrected resampled t (Nadeau and Bengio, 2003)',
                    preprocessing='OneHotEncoder(handle_unknown=ignore) fit on training fold only; StandardScaler numeric fitted on training fold only',
                    gb_settings=GB_SETTINGS, feature_sets=SETS,
                    permutation_importance='Descriptive, held-out fold 1 of each repeat, 3 shuffles, weighted R2; correlated features share information',
                    cohort_note='Separate within-age-group cross-validation, not validation of full-sample model in subgroups')
    (out / 'p04_prediction_settings.json').write_text(json.dumps(settings, indent=2) + '\n')
    print(summary.to_string(index=False, float_format=lambda x: f'{x:.4f}'))
    print(gains.to_string(index=False, float_format=lambda x: f'{x:.4f}'))
if __name__ == '__main__': main()
