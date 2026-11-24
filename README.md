# Social Representativeness of French Municipal Councils

Research internship in political economy, Bordeaux Sciences Économiques (University of Bordeaux), June–July 2026, supervised by Christophe Lévêque.

This repository contains the Stata code used to study **how closely French municipal councillors mirror the social composition of their municipality**, and whether **local associational life** (the density of associations, and of political associations in particular) is linked to the over- or under-representation of social groups among elected officials.

## Research question

Managers and higher intellectual professions (*cadres*) are over-represented among French local elected officials, while manual and clerical workers are under-represented. The project asks whether municipalities with a denser associational fabric elect councils that are more or less socially representative of their population.

## Data

The analysis covers about 36,000 metropolitan French municipalities and the 2008, 2014 and 2020 municipal terms. The data files are **not included** in this repository because of their size. All of them are public:

| Source | Content | Use |
|---|---|---|
| **RNE** – Répertoire national des élus (Ministry of the Interior) | Every municipal councillor: sex, age, occupation, function (mayor, deputy mayor) | Social profile of elected officials |
| **RNA** – Répertoire national des associations (extract of 1 June 2026, one file per département) | Every registered association, with its commune and declared purpose | Associational density by municipality |
| **Filosofi** (INSEE) | Median disposable income by municipality | Control variable |
| **Population census, employment by occupation** (INSEE, `DS_RP_EMPLOI`, 2021) | Employed population by socio-professional category (PCS) | Social composition of each municipality |

## Method

1. **Classifying elected officials.** The free-text occupation labels in the RNE are mapped onto the six INSEE socio-professional groups (farmers; craftsmen, shopkeepers and business owners; managers and higher professions; intermediate professions; clerical workers; manual workers), plus an "unknown" category. Because the occupation nomenclature changed in 2020, each councillor's 2020 occupation is carried back to their earlier terms when the same person can be identified.
2. **Measuring representativeness.** For each municipality and group, a *representation gap* is the group's share among councillors minus its share in the employed population (positive = over-represented).
3. **Measuring associational life.** The 98 RNA files (plus Corsica) are imported and classified automatically. Associations are flagged as *political* (purpose code 001) or *indirectly political* (codes 002, 003, 005, 022, 023), then aggregated by municipality and matched to the RNE through normalised commune names and département codes (about 17,000 municipalities matched).
4. **Estimation.**
   - OLS regressions of each gap on standardised association counts and log median income, with population-size brackets and département fixed effects (`areg`, robust standard errors), summarised in a coefficient plot.
   - **Propensity score matching** (`psmatch2`, logit, caliper 0.01) with three treatments: at least one political association; at least one indirectly political association; total number of associations above the median. Matching covariates: log median income, the population's occupational shares and population-size brackets. Each treatment is estimated on 7 outcomes (six representation gaps and the share of women among councillors), i.e. **21 estimations** of the average treatment effect on the treated (ATT).

## Main results

- Municipalities with a denser associational life elect more managers and higher professionals, both as mayors and as councillors (ATT up to +0.019, p < 0.05).
- No effect is found on the share of women among councillors.

These results are the basis of a paper in preparation for a political science journal.

## Repository structure

```
Stage_EcoPo.do    Master do-file: data construction, regressions, matching, descriptive statistics
```

The do-file is organised in numbered sections:

| Section | Step | Main output |
|---|---|---|
| 0 | Global parameters and file paths | |
| 1 | Builds the RNE base: population, income, size brackets, occupational classification | `rne_cat_actualise.dta` |
| 2 | Carries 2020 occupations back to the 2008 and 2014 terms | `rne_cat_actualise.dta` (updated) |
| 3 | Occupational structure of the population (census) | `pop_pcs_communes.dta` |
| 4 | Representation gaps by municipality (2020 term) | `rne_proportion_pop_elus_v2.dta` |
| 5 | Imports and aggregates the RNA files by municipality | `rna_collapsed_commune.dta` |
| 6–7 | Municipality reference file and final merge | `fichier_final_commune.dta` |
| 8 | OLS regressions and coefficient plot | `coefplot_gaps.png` |
| 9 | Propensity score matching (3 treatments × 7 outcomes) | |
| – | Descriptive statistics and charts (sex, age, social status and occupation of mayors by term and municipality size) | `.png` charts |

## Reproducing the analysis

**Requirements:** Stata 17 or later, and two user-written packages:

```stata
ssc install psmatch2
ssc install coefplot
```

**Steps:**

1. Download the data listed above.
2. Edit the paths in section 0 of the do-file (`$rne`, `$rne26`, `$rna`, `$data`) to point to your own folders.
3. Run `Stage_EcoPo.do` from top to bottom.

Note: section 1 starts from an RNE file already merged across terms (`data_rne_all_copie.dta`) and from a population-by-year file (`pop_par_annee.dta`), which were prepared beforehand and are not built by this script.

## Author

**Louis Briaux**, Master's student in Public Policy Analysis and Magistère in Economics, University of Bordeaux
louisbriaux@gmail.com
