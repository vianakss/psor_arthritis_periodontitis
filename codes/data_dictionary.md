# Data Dictionary

---

## 1. Study Design Variables

| Variable | Type | Values | Description 
|---|---|---|---|
| `id` | Integer | 1–168 | Participant unique identifier | 
| `case_status` | Binary | 0 = Control, 1 = Case (PsA) | Case-control status | 
| `match_id` | Integer | 1–84 | Matched pair identifier (from MatchIt `subclass`) |
| `match_weight` | Numeric | 1 | Matching weight (all = 1 in 1:1 exact matching) | 

---

## 2. Sociodemographic Variables

| Variable | Type | Values | Description | 
|---|---|---|---|
| `age` | Integer | 35–65 | Age in years (matching variable) |
| `sex` | Binary | 0 = Female, 1 = Male | Sex (matching variable) | 
| `education` | Binary | 0 = < 8 years, 1 = ≥ 8 years | Educational level | 
| `income` | Categorical | 0 = Up to 2 MW, 1 = 2–5 MW, 2 = ≥ 5 MW | Household income in minimum wages (MW) | 

---

## 3. Behavioral and Medical History Variables

| Variable | Type | Values | Description | 
|---|---|---|---|
| `smoking` | Binary | 0 = No, 1 = Yes | Current smoker | 
| `alcohol` | Binary | 0 = No, 1 = Yes | Alcohol consumption | 
| `diabetes` | Binary | 0 = No, 1 = Yes | Self-reported diabetes | 

---

## 4. Periodontal Diagnosis Variables

| Variable | Type | Values | Description 
|---|---|---|---|
| `periodontitis` | Binary | 0 = No, 1 = Yes | Periodontitis diagnosis (Tonetti et al., 2018) | 
| `perio_stage` | Categorical | 0–4 | Original periodontitis stage (0 = health/gingivitis, 1–4 = Stages I–IV) | 
| `perio_stage_cat` | Categorical | 0 = Health/gingivitis, 1 = Stage I/II, 2 = Stage III/IV | Periodontitis stage — categorized (derived) |

---

## 5. Site-Level Clinical Variables

### Naming convention

All site-level variables follow the pattern `{parameter}_{surface}_{tooth}` using FDI tooth notation:

- **Parameters:** `pd` = probing depth (mm), `cal` = clinical attachment level (mm), `bop` = bleeding on probing
- **Surfaces:** `d` = distal, `b` = buccal, `m` = mesial, `l` = lingual
- **Teeth:** FDI notation (17, 16, 15, 14, 13, 12, 11, 21, 22, 23, 24, 25, 26, 27, 47, 46, 45, 44, 43, 42, 41, 31, 32, 33, 34, 35, 36, 37)

### 5.1. Probing depth (112 variables)

| Variables | Type | Unit | Range | Description |
|---|---|---|---|---|
| `pd_d_17` – `pd_l_37` | Integer | mm | 0–15 | Probing depth at each of 4 sites per tooth (28 teeth × 4 sites) |

### 5.2. Clinical attachment level (112 variables)

| Variables | Type | Unit | Range | Description |
|---|---|---|---|---|
| `cal_d_17` – `cal_l_37` | Integer | mm | 0–20 | Clinical attachment level at each of 4 sites per tooth |

### 5.3. Bleeding on probing (112 variables)

| Variables | Type | Unit | Coding | Description |
|---|---|---|---|---|
| `bop_d_17` – `bop_l_37` | Integer | — | 1 = absent, ≥ 2 = present | Bleeding on probing at each of 4 sites per tooth |

---

## 6. Derived Periodontal Variables

All derived variables are computed in the analysis script from the site-level data above.

### 6.1. Probing depth summaries

| Variable | Type | Unit | Formula | Description | Used in |
|---|---|---|---|---|---|
| `mean_pd` | Numeric | mm | `rowmean(pd_d_17-pd_l_37)` | Mean PD across all non-missing sites | Tables 2, 3 (Model 1) |
| `pd_sites_total` | Integer | count | `rownonmiss(pd_d_17-pd_l_37)` | Total number of non-missing PD sites (denominator) | Derivation only |
| `pd4_count` | Integer | count | Loop: count sites where PD == 4 | Number of sites with PD = 4 mm | Derivation only |
| `pct_pd4` | Numeric | % | `(pd4_count / pd_sites_total) × 100` | Percentage of sites with PD = 4 mm | Table 2 |
| `pd5_6_count` | Integer | count | Loop: count sites where PD ∈ {5, 6} | Number of sites with PD = 5–6 mm | Derivation only |
| `pct_pd5_6` | Numeric | % | `(pd5_6_count / pd_sites_total) × 100` | Percentage of sites with PD = 5–6 mm | Table 2 |
| `pd7plus_count` | Integer | count | Loop: count sites where PD ≥ 7 | Number of sites with PD ≥ 7 mm | Derivation only |
| `pct_pd7plus` | Numeric | % | `(pd7plus_count / pd_sites_total) × 100` | Percentage of sites with PD ≥ 7 mm | Table 2 |

### 8.2. Clinical attachment level summaries

| Variable | Type | Unit | Formula | Description 
|---|---|---|---|---|
| `mean_cal` | Numeric | mm | `rowmean(cal_d_17-cal_l_37)` | Mean CAL across all non-missing sites | 
| `mean_cal_cat` | Categorical | — | `xtile mean_cal, nq(3)` | Mean CAL categorized into tertiles | 

Tertile cutpoints (from data):

| Tertile | Range | Mean (SD) | n |
|---|---|---|---|
| Tertile 1 (lowest) | ≤ 3.55 mm | 3.13 (0.21) | 56 |
| Tertile 2 | 3.55–4.49 mm | 4.02 (0.31) | 56 |
| Tertile 3 (highest) | > 4.49 mm | 4.76 (0.25) | 56 |

### 8.3. Bleeding on probing summary

| Variable | Type | Unit | Formula | Description | Used in |
|---|---|---|---|---|---|
| `bop_count` | Integer | count | `anycount(bop_d_17-bop_l_37), values(2/1000)` | Number of sites with BOP present (value ≥ 2) | Derivation only |
| `bop_sites_total` | Integer | count | `rownonmiss(bop_d_17-bop_l_37)` | Total number of non-missing BOP sites | Derivation only |
| `pct_bop` | Numeric | % | `(bop_count / bop_sites_total) × 100` | Percentage of sites with BOP | Tables 2, 3 (Model 2) |

---

## 9. Summary of Variables by Analysis Table

| Table | Variables used |
|---|---|
| **Table 1** | `age`, `sex`, `education`, `income`, `smoking`, `alcohol`, `diabetes` |
| **Table 2** | `periodontitis`, `perio_stage_cat`, `mean_cal`, `mean_pd`, `pct_bop`, `plaque_pct`, `pct_pd4`, `pct_pd5_6`, `pct_pd7plus` |
| **Table 3** | `mean_pd` (Model 1), `pct_bop` (Model 2), `mean_cal_cat` (Model 3), `education`, `income`, `smoking`, `alcohol`, `diabetes` |
| **All tables** | `case_status` (outcome/grouping), `match_id` (pair identifier) |
