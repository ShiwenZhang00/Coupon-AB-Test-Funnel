###############################################################################
#  A/B Test Analysis: The Impact of Coupons on the Visit-to-Purchase Funnel
#  
#  Usage: 
#    1. Set working directory to where Coupon_Impact.csv is located
#    2. source("ab_test_analysis.R")
###############################################################################

# --- Load Data ---
setwd("C:/Users/86186/Desktop/BU/job/Portfolio/AB-testing/Effect of Coupons")
df <- read.csv("Coupon_Impact.csv", stringsAsFactors = FALSE)

# Subset by group
t1l <- df[df$group == "T1L", ]
cgl <- df[df$group == "CGL", ]
t1h <- df[df$group == "T1H", ]
t2h <- df[df$group == "T2H", ]
cgh <- df[df$group == "CGH", ]


###############################################################################
#  STEP 1: EDA
###############################################################################

str(df)
summary(df)
table(df$group)

# Check for missing values
colSums(is.na(df))

# Logic checks
sum(df$visit == 0 & df$purchase == 1)       # visited=0 but purchased=1?
sum(df$purchase == 0 & df$redeem == 1)       # purchased=0 but redeemed=1?
sum(df$visit == 0 & df$pageviews > 0)        # visited=0 but has pageviews?
sum(df$group %in% c("CGL","CGH") & df$redeem == 1)  # control group redeemed?

# Group-level summary
aggregate(cbind(visit, purchase, redeem, amount, pageviews, discount) ~ group,
          data = df, FUN = mean)


###############################################################################
#  STEP 2: Sample Ratio Mismatch (SRM) Check
###############################################################################

# Low-value segment: designed ratio T1L:CGL = 70:30
chisq.test(c(nrow(t1l), nrow(cgl)), p = c(0.70, 0.30))

# High-value segment: designed ratio T1H:T2H:CGH ≈ 30.8:56:13.2
ratio_h <- c(0.308, 0.56, 0.132)
chisq.test(c(nrow(t1h), nrow(t2h), nrow(cgh)), p = ratio_h / sum(ratio_h))


###############################################################################
#  STEP 3: Core Metrics Analysis
#
#  For proportions (purchase rate, redeem rate): prop.test()
#  For continuous variables (ARPC, ARPB): t.test()
#  
#  Four comparisons:
#    1. T1L vs CGL  -- base coupon effect on low-value customers
#    2. T1H vs CGH  -- base coupon effect on high-value customers
#    3. T2H vs CGH  -- better coupon effect on high-value customers
#    4. T2H vs T1H  -- better coupon vs base coupon
###############################################################################

# --- Comparison 1: T1L vs CGL ---

# Purchase rate
prop.test(x = c(sum(t1l$purchase), sum(cgl$purchase)),
          n = c(nrow(t1l), nrow(cgl)))

# Redeem rate
prop.test(x = c(sum(t1l$redeem), sum(cgl$redeem)),
          n = c(nrow(t1l), nrow(cgl)))

# ARPC (average revenue per customer)
t.test(t1l$amount, cgl$amount)

# ARPB (average revenue per buyer, conditional on purchase)
t.test(t1l$amount[t1l$purchase == 1],
       cgl$amount[cgl$purchase == 1])


# --- Comparison 2: T1H vs CGH ---

prop.test(x = c(sum(t1h$purchase), sum(cgh$purchase)),
          n = c(nrow(t1h), nrow(cgh)))

prop.test(x = c(sum(t1h$redeem), sum(cgh$redeem)),
          n = c(nrow(t1h), nrow(cgh)))

t.test(t1h$amount, cgh$amount)

t.test(t1h$amount[t1h$purchase == 1],
       cgh$amount[cgh$purchase == 1])


# --- Comparison 3: T2H vs CGH ---

prop.test(x = c(sum(t2h$purchase), sum(cgh$purchase)),
          n = c(nrow(t2h), nrow(cgh)))

prop.test(x = c(sum(t2h$redeem), sum(cgh$redeem)),
          n = c(nrow(t2h), nrow(cgh)))

t.test(t2h$amount, cgh$amount)

t.test(t2h$amount[t2h$purchase == 1],
       cgh$amount[cgh$purchase == 1])


# --- Comparison 4: T2H vs T1H ---

prop.test(x = c(sum(t2h$purchase), sum(t1h$purchase)),
          n = c(nrow(t2h), nrow(t1h)))

prop.test(x = c(sum(t2h$redeem), sum(t1h$redeem)),
          n = c(nrow(t2h), nrow(t1h)))

t.test(t2h$amount, t1h$amount)

t.test(t2h$amount[t2h$purchase == 1],
       t1h$amount[t1h$purchase == 1])


###############################################################################
#  STEP 3b: Regression approach (alternative to t-tests above)
#  
#  Using lm() lets you control for segment and test multiple comparisons
#  in a single model. The coefficients directly give you the treatment effects.
###############################################################################

# Create segment variable
df$segment <- ifelse(df$group %in% c("T1L", "CGL"), "low", "high")

# Create treatment variable
df$treatment <- "control"
df$treatment[df$group %in% c("T1L", "T1H")] <- "base_coupon"
df$treatment[df$group == "T2H"] <- "better_coupon"
df$treatment <- factor(df$treatment, levels = c("control", "base_coupon", "better_coupon"))

# --- Low-value segment: effect of base coupon on ARPC ---
low_df <- df[df$segment == "low", ]
lm_low_arpc <- lm(amount ~ treatment, data = low_df)
summary(lm_low_arpc)

lm_low_purch <- lm(purchase ~ treatment, data = low_df)
summary(lm_low_purch)   # Linear Probability Model for purchase rate

# --- High-value segment: effect of base and better coupons ---
high_df <- df[df$segment == "high", ]
lm_high_arpc <- lm(amount ~ treatment, data = high_df)
summary(lm_high_arpc)

lm_high_purch <- lm(purchase ~ treatment, data = high_df)
summary(lm_high_purch)

# --- Full model with interaction (segment x treatment) ---
# This tests whether coupon effects differ by segment
full_df <- df[df$treatment != "better_coupon", ]  # only base coupon & control
lm_interaction <- lm(amount ~ treatment * segment, data = full_df)
summary(lm_interaction)
# The interaction term tells you if the base coupon effect is 
# significantly different for high-value vs low-value customers


###############################################################################
#  STEP 4: Funnel Decomposition (Paper Table 3)
#  
#  Decompose purchase rate into:
#    Purchase Rate = Visit Rate × (Purchase Rate | Visit)
#  
#  This reveals WHERE in the funnel the coupon has its effect.
###############################################################################

# ---- Layer 1: Visit Rate (unconditional) ----

# T1L vs CGL
prop.test(x = c(sum(t1l$visit), sum(cgl$visit)),
          n = c(nrow(t1l), nrow(cgl)))

# T1H vs CGH
prop.test(x = c(sum(t1h$visit), sum(cgh$visit)),
          n = c(nrow(t1h), nrow(cgh)))

# T2H vs CGH
prop.test(x = c(sum(t2h$visit), sum(cgh$visit)),
          n = c(nrow(t2h), nrow(cgh)))

# T2H vs T1H
prop.test(x = c(sum(t2h$visit), sum(t1h$visit)),
          n = c(nrow(t2h), nrow(t1h)))


# ---- Layer 2: Pageviews given Visit (conditional on visit) ----

# T1L vs CGL
t.test(t1l$pageviews[t1l$visit == 1],
       cgl$pageviews[cgl$visit == 1])

# T1H vs CGH
t.test(t1h$pageviews[t1h$visit == 1],
       cgh$pageviews[cgh$visit == 1])

# T2H vs CGH
t.test(t2h$pageviews[t2h$visit == 1],
       cgh$pageviews[cgh$visit == 1])

# T2H vs T1H
t.test(t2h$pageviews[t2h$visit == 1],
       t1h$pageviews[t1h$visit == 1])


# ---- Layer 3: Purchase Rate given Visit (conditional on visit) ----

# T1L vs CGL
visitors_t1l <- t1l[t1l$visit == 1, ]
visitors_cgl <- cgl[cgl$visit == 1, ]
prop.test(x = c(sum(visitors_t1l$purchase), sum(visitors_cgl$purchase)),
          n = c(nrow(visitors_t1l), nrow(visitors_cgl)))

# T1H vs CGH
visitors_t1h <- t1h[t1h$visit == 1, ]
visitors_cgh <- cgh[cgh$visit == 1, ]
prop.test(x = c(sum(visitors_t1h$purchase), sum(visitors_cgh$purchase)),
          n = c(nrow(visitors_t1h), nrow(visitors_cgh)))

# T2H vs CGH
visitors_t2h <- t2h[t2h$visit == 1, ]
prop.test(x = c(sum(visitors_t2h$purchase), sum(visitors_cgh$purchase)),
          n = c(nrow(visitors_t2h), nrow(visitors_cgh)))

# T2H vs T1H
prop.test(x = c(sum(visitors_t2h$purchase), sum(visitors_t1h$purchase)),
          n = c(nrow(visitors_t2h), nrow(visitors_t1h)))


# ---- Layer 4: Discount given Purchase (conditional on purchase) ----

# T1L vs CGL
t.test(t1l$discount[t1l$purchase == 1],
       cgl$discount[cgl$purchase == 1])

# T1H vs CGH
t.test(t1h$discount[t1h$purchase == 1],
       cgh$discount[cgh$purchase == 1])

# T2H vs CGH
t.test(t2h$discount[t2h$purchase == 1],
       cgh$discount[cgh$purchase == 1])

# T2H vs T1H
t.test(t2h$discount[t2h$purchase == 1],
       t1h$discount[t1h$purchase == 1])


# ---- Funnel Summary Table ----
# Compute visit rate, conversion rate, and overall purchase rate per group

funnel_summary <- data.frame(
  group = c("CGL", "T1L", "CGH", "T1H", "T2H"),
  n = c(nrow(cgl), nrow(t1l), nrow(cgh), nrow(t1h), nrow(t2h))
)

for (i in 1:nrow(funnel_summary)) {
  g <- df[df$group == funnel_summary$group[i], ]
  v <- g[g$visit == 1, ]
  
  funnel_summary$visit_rate[i]    <- mean(g$visit)
  funnel_summary$conv_rate[i]     <- ifelse(nrow(v) > 0, mean(v$purchase), NA)
  funnel_summary$purchase_rate[i] <- mean(g$purchase)
  funnel_summary$arpc[i]          <- mean(g$amount)
  funnel_summary$redeem_rate[i]   <- mean(g$redeem)
}

print(funnel_summary)

# Verify: visit_rate * conv_rate ≈ purchase_rate
funnel_summary$check <- funnel_summary$visit_rate * funnel_summary$conv_rate
print(funnel_summary[, c("group", "purchase_rate", "check")])

