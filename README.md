# Time-Series in R — Practical Forecasting, Validation & Decision-Making (Mixed: fable + forecast)

[![R](https://img.shields.io/badge/R-%3E%3D%204.2-blue)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-active-brightgreen)](#)

A practical **time series** repository in **R** built to be both:
- an **industry-facing portfolio** (clean, reproducible, evaluation-first workflows), and
- a **public reference** for anyone with time series questions—even if you’re new to R.

This repo intentionally uses a **mixed ecosystem**:
- **tidy time series** tools (`tsibble`, `fable`, `feasts`) for modern, modular workflows, and
- **classic** tools (`forecast`) because they’re still widely used and show up in real teams.

---

## Learning map (recommended path)

| Module | What you’ll learn | Where to look |
|---|---|---|
| 00 — Setup & basics | How to run the project, project structure, time series “gotchas” | `notes/` + `notebooks/00_*` |
| 01 — EDA & baselines | Seasonal patterns, naive/seasonal naive, sanity checks | `notebooks/01_*` |
| 02 — Decomposition | STL, trend/seasonality, residual thinking | `notes/decomposition*` + `notebooks/02_*` |
| 03 — Feature engineering | Lags, rolling windows, calendar effects | `notebooks/03_*` + `scripts/feature_*` |
| 04 — ETS | Exponential smoothing, diagnostics, stability | `notebooks/04_*` |
| 05 — ARIMA/SARIMA | Identification, diagnostics, SARIMA seasonality | `notebooks/05_*` |
| 06 — Backtesting | Walk-forward / rolling origin, leakage-free validation | `notebooks/06_*` + `scripts/backtest_*` |
| 07 — Anomalies | Residual-based detection, thresholds, alerting mindset | `notebooks/07_*` |
| 08 — Case studies | Demand forecasting, KPI monitoring, incident retros | `notebooks/08_*` |

> Tip: If you’re here with a specific doubt, start in `notes/` (concept) and then jump to the matching `notebooks/` (runnable example).

---

## What you’ll find here

### Core topics (practical)
- Decomposition (including **STL**)
- Forecasting with **ETS** and **ARIMA/SARIMA**
- Feature engineering for temporal data (lags, rolling windows, calendar features)
- Time-aware validation: walk-forward / rolling origin backtesting
- Forecast evaluation: MAE, RMSE, MAPE/sMAPE (and tradeoffs)
- Anomaly detection (residual-based + operational thresholds)
- Reproducible workflows (clean scripts, notebook-first explanations)

### What this repo is not
- Not a theory-only collection
- Not tied to a single dataset
- Not optimized for leaderboard-style “one split” performance

---

## Who this is for
- **Analysts / Data Scientists / ML Engineers** forecasting demand, revenue, product metrics, operations, finance, energy, etc.
- **Students** who want an applied path with runnable code.
- **Anyone** who needs a reference when stuck on a time-series concept.

New to R? You can still follow along—start with **Quickstart**.

---

## Repository structure

```text
.
├── slides/                 # Slides (html/pdf)
├── notes/                  # Topic notes (Markdown)
├── notebooks/              # Quarto/Rmd notebooks (reproducible)
├── scripts/                # Reusable R code (functions, pipelines)
├── data/
│   ├── raw/                # Immutable source data
│   └── processed/          # Modeling-ready datasets
├── assignments/            # Exercises + rubrics (optional)
├── outputs/                # Figures, reports, saved models
├── LICENSE
└── README.md
```

---

## Quickstart (copy/paste friendly)

### 1) Requirements

* **R >= 4.2**
* Recommended: **RStudio**
* Optional but great for notebooks: **Quarto**

### 2) Clone

```bash
git clone https://github.com/Urielledezma/Time-Series.git
cd Time-Series
```

### 3) Install dependencies

#### Option A (recommended): `renv` for reproducibility

> Best for “industry-grade” setups and consistent environments.

```r
install.packages("renv")
renv::init()      # typically done by repo owner once
renv::restore()   # restores exact versions once a lockfile exists
```

#### Option B: quick install (common packages)

```r
install.packages(c(
  "tidyverse",
  "lubridate",
  "tsibble", "fable", "fabletools", "feasts",
  "forecast",
  "yardstick"
))
```

### 4) Run a notebook

Open any file in `notebooks/` and click **Render** / **Run** in RStudio.

---

## Evaluation philosophy (industry mindset)

Forecasting is an evaluation problem first:

* Choose a **time-aware** validation strategy (avoid leakage)
* Compare against strong **baselines** (naive / seasonal naive)
* Use metrics that reflect cost (MAE vs RMSE vs sMAPE, etc.)
* Track **stability over time**, not just a single split
* Diagnose failures (residual patterns, regime shifts, holiday effects)

---

## Mixed ecosystem: why both `fable` and `forecast`?

* `tsibble`/`fable`/`feasts` support modern, tidy workflows and modular modeling.
* `forecast` is still common in production codebases and interviews, and it’s useful to understand the “classic” tooling.

Where possible, notebooks show:

* a **tidy** approach (tsibble/fable) and
* a **classic** approach (forecast)
  side-by-side, so you can translate between them.

---

## Data policy

* Small datasets can live in `data/raw/`.
* Large or restricted datasets should not be committed:

  * add a download script (e.g., `scripts/01_download_data.R`)
  * document the source + license
  * ensure `data/processed/` is reproducible from raw

If you add third-party data, include attribution (source + license) in the relevant note/notebook.

---

## Code conventions

* `snake_case` for objects and functions
* Scripts numbered by pipeline stage (example):

  * `scripts/01_ingest.R`
  * `scripts/02_clean.R`
  * `scripts/03_features.R`
  * `scripts/04_train.R`
  * `scripts/05_backtest.R`
  * `scripts/06_report.R`

Optional (when the repo grows):

* `styler` for auto-formatting
* `lintr` for linting
* `testthat` for unit tests (core utilities)

---

## Roadmap

* [ ] Create full folder structure (`slides/`, `notes/`, `notebooks/`, `data/`, `scripts/`)
* [ ] Notebook: EDA + baselines (naive/seasonal naive)
* [ ] Notebook: STL + feature engineering
* [ ] Notebook: ETS + diagnostics
* [ ] Notebook: ARIMA/SARIMA + walk-forward backtesting
* [ ] Notebook: anomaly detection + alert thresholds
* [ ] Case studies: demand forecasting + KPI anomaly monitoring
* [ ] Add reproducibility: commit `renv.lock`
* [ ] Add CI badges (R CMD check / lint / render)

---

## Contributing

Contributions are welcome:

* typo fixes / clearer explanations
* new examples or datasets (with license + attribution)
* improvements to utilities and reproducibility

Please open an Issue or PR describing:

* what you’re changing
* why it helps
* how to reproduce (if relevant)

---

## License

MIT — see [`LICENSE`](LICENSE).

---

## Citation

```bibtex
@misc{time_series_urielledezma,
  author       = {Urielledezma},
  title        = {Time-Series in R: Practical Forecasting, Validation \& Decision-Making (Mixed fable + forecast)},
  year         = {2026},
  publisher    = {GitHub},
  howpublished = {\url{https://github.com/Urielledezma/Time-Series}},
  note         = {MIT License}
}
```

```
::contentReference[oaicite:0]{index=0}
```
