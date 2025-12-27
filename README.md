# Loss Prediction & Discount Optimization using BigQuery ML

## Business Problem
Retail discounts were driving revenue growth but also causing hidden profit losses.
The objective of this project was to identify loss-making orders in advance and
optimize discount strategies using predictive analytics.

## Dataset
- Retail Superstore transactional dataset
- Order-level sales, discounts, profits, categories, and shipping information

## Key Analysis
- Exploratory data analysis to identify loss patterns
- Discount impact on profit margins
- Category and regional performance analysis

## Machine Learning Approach
- Built a binary classification model using BigQuery ML
- Target variable: loss_flag (profit < 0)
- Key features: discount, sales, quantity, category, region, shipping mode

## Model Performance
- ROC AUC: 0.97
- Recall: 0.89
- Precision: 0.74

## Business Impact
- Identified high-risk discounted orders before fulfillment
- Designed probability-based intervention thresholds
- Recommended dynamic discount control instead of order blocking

## Tools Used
- Google BigQuery (SQL)
- BigQuery ML
- Google Cloud Platform

## Key Takeaway
SQL explains historical loss patterns, while machine learning enables proactive,
order-level risk detection to support data-driven pricing decisions.
