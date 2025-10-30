# Clinical Trial Analysis: Acupuncture Headache Study

**Author:** Jay Sminchak  
**Date:** 2025  

## Overview
This project replicates a clinical trial–style analysis comparing **acupuncture vs. usual care** for headache outcomes.  
All work is performed in **SAS**, following the workflow used in CRO and hospital biostatistics environments.

## Objectives
1. Import and clean raw trial data  
2. Create analysis datasets and define primary/secondary outcomes  
3. Generate descriptive statistics by treatment arm  
4. Model continuous and binary outcomes using GLM and logistic methods  
5. Estimate per-protocol effects using **inverse probability weighting (IPW)**  
6. Test for **interaction/modification** by migraine status and sex  
7. Export reproducible tables and figures  

## Methods Summary

| Analysis Step | SAS Procedure | Output |
|----------------|---------------|---------|
| Descriptive statistics | `PROC MEANS`, `PROC FREQ` | Summary Stats |
| Primary linear regression | `PROC GLM` | Table 2: Regression Results |
| Interaction by migraine | `PROC TTEST`, `PROC SGPLOT` | Figure 1: Interaction Plot |
| IPW estimation | `PROC LOGISTIC`, `PROC GENMOD` | Model output |
| Binary outcome (Pain Med Decrease) | `PROC FREQ` | Odds Ratios, Risk Differences |

## Key Outputs
- `Table 1. Characteristics.png` – Descriptive Study Characteristics
- `Table2_RegressionResults.csv` – Adjusted model estimates  
- `Figure1_InteractionPlot.png` – Mean difference by migraine status  


## Skills Demonstrated
- Clinical data management and cleaning  
- Regression modeling and subgroup analysis  
- IPW implementation for per-protocol effect  
- ODS output automation and reproducibility in SAS  
- Preparation of publication-ready tables and figures 
