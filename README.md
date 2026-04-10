# Coupon A/B Test: Visit-to-Purchase Funnel Analysis

A replication and analysis of a randomized field experiment on coupon effectiveness in e-commerce, based on Gopalakrishnan & Park (2021), *Marketing Science*.

📄 **Original paper:** [The Impact of Coupons on the Visit-to-Purchase Funnel](https://doi.org/10.1287/mksc.2020.1232)

## Overview

This project walks through a complete A/B test workflow using simulated data from a randomized field experiment with an Asian e-commerce retailer. The goal is to measure how coupons affect customer behavior at each stage of the visit-to-purchase funnel: visit, search, and purchase.

The analysis answers four business questions:

1. Does the base coupon increase revenue for low-value customers?
2. Does the base coupon increase revenue for high-value customers?
3. Does a deeper discount (better coupon) outperform the base coupon for high-value customers?
4. Where in the funnel do coupons actually take effect?

## Data

The dataset (`Coupon_Impact.csv`) contains 12,959 individual-level records with the following variables:

| Variable | Description |
|---|---|
| `consumer_id` | Unique customer identifier |
| `group` | Experimental condition (T1L, T1H, T2H, CGL, CGH) |
| `visit` | Whether the customer visited the website (1=yes) |
| `pageviews` | Number of pages viewed during the session |
| `purchase` | Whether the customer made a purchase (1=yes) |
| `redeem` | Whether the customer redeemed the focal coupon (1=yes) |
| `amount` | Purchase amount in USD, net of any discount |
| `discount` | Discount percentage off gross price |

### Experimental design

| Group | Segment | Treatment | N |
|---|---|---|---|
| CGL | Low-value | Control (no coupon) | 1,998 |
| T1L | Low-value | Base coupon ($7 off) | 4,787 |
| CGH | High-value | Control (no coupon) | 801 |
| T1H | High-value | Base coupon ($7 off) | 1,927 |
| T2H | High-value | Better coupon ($10 off) | 3,446 |

## Analysis Workflow

The R script `ab_test_analysis.R` runs the full analysis in five steps:

1. **EDA** — sample sizes, missing values, logic checks
2. **SRM check** — chi-square test for sample ratio mismatch
3. **Core metrics** — purchase rate, redeem rate, ARPC, ARPB (Table 2 in the paper)
4. **Funnel decomposition** — visit rate, pageviews, purchase given visit, discount given purchase (Table 3 in the paper)
5. **Regression models** — linear models with treatment-by-segment interaction

Statistical methods used:

- `prop.test()` for proportion comparisons (purchase rate, visit rate, redeem rate)
- `t.test()` for continuous variables (ARPC, ARPB, pageviews, discount)
- `chisq.test()` for sample ratio mismatch
- `lm()` for regression models with interaction terms

## Files

```
.
├── README.md
├── Coupon_Impact.csv              # Individual-level experiment data
├── ab_test_analysis.R             # Full R analysis script
└── ab_test_results_report.html    # Results report with tables and conclusions
```

## How to Run

1. Clone this repository
2. Open R or RStudio and set the working directory to the cloned folder
3. Run the analysis:

```r
source("ab_test_analysis.R")
```

The script outputs all statistical test results to the console. The HTML report contains the formatted results and business conclusions.

## Key Findings

- **Coupons are effective**, but most of the lift comes from non-redeemers. Only about 20% of purchasers actually used the coupon.
- **The main mechanism is increased website visits.** Visit rates rose by 22 to 24 percentage points across all segments, while conversion among visitors held steady.
- **A deeper discount does not bring more visits.** It does, however, raise purchase conversion among visitors for high-value customers.
- **Margin erosion is limited** under the base coupon. The better coupon trades a small margin loss for higher volume.

## Reference

Gopalakrishnan, A., & Park, Y. H. (2021). The Impact of Coupons on the Visit-to-Purchase Funnel. *Marketing Science*, 40(1), 48-61. https://doi.org/10.1287/mksc.2020.1232

## License

This project is for educational purposes. The original paper and data are the intellectual property of the authors and INFORMS.
