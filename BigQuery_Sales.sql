SELECT * FROM `ml-project-482013.sales_ds.orders_table` LIMIT 1000


create OR REPLACE TABLE `sales_ds.orders_table` AS
SELECT
  `Row ID`         AS row_id,
  `Order ID`       AS order_id,
  `Order Date`     AS order_date,
  `Ship Date`      AS ship_date,
  `Ship Mode`      AS ship_mode,
  `Customer ID`    AS customer_id,
  `Customer Name`  AS customer_name,
  Segment          AS segment,
  Country          AS country,
  City             AS city,
  State            AS state,
  Region           AS region,
  `Product ID`     AS product_id,
  Category         AS category,
  `Sub-Category`   AS sub_category,
  `Product Name`   AS product_name,
  Sales            AS sales,
  Quantity         AS quantity,
  Discount         AS discount,
  Profit           AS profit
FROM `sales_ds.orders_table`

--- discount impact -----

SELECT
  discount,
  COUNT(*) AS total_rows,
  ROUND(AVG(sales), 2) AS avg_sales,
  ROUND(AVG(profit), 2) AS avg_profit
FROM `sales_ds.orders_table`
GROUP BY discount
ORDER BY discount

SELECT
  COUNT(*) AS total_rows,
  MIN(order_date) AS start_date,
  MAX(order_date) AS end_date
FROM `sales_ds.orders_table`

SELECT
  MIN(sales) AS min_sales,
  MAX(sales) AS max_sales,
  AVG(sales) AS avg_sales,
  SUM(sales) AS total_sales
FROM `sales_ds.orders_table`

SELECT
  COUNT(DISTINCT order_id) AS total_orders,
  COUNT(DISTINCT product_id) AS total_products
FROM `sales_ds.orders_table`

SELECT
  category,
  ROUND(SUM(sales), 2) AS total_sales,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND(SUM(profit) / SUM(sales), 3) AS profit_margin
FROM `sales_ds.orders_table`
GROUP BY category
ORDER BY total_sales DESC

SELECT
  region,
  ROUND(SUM(sales), 2) AS total_sales,
  ROUND(SUM(profit), 2) AS total_profit
FROM `sales_ds.orders_table`
GROUP BY region
ORDER BY total_profit DESC

SELECT
  FORMAT_DATE('%Y-%m', order_date) AS month,
  ROUND(SUM(sales), 2) AS monthly_sales,
  ROUND(SUM(profit), 2) AS monthly_profit
FROM `sales_ds.orders_table`
GROUP BY month
ORDER BY month


SELECT
  FORMAT_DATE('%Y-%m', order_date) AS month,
  discount,
  COUNT(*) AS orders,
  ROUND(AVG(sales),2) AS avg_sales,
  ROUND(AVG(profit),2) AS avg_profit
FROM `sales_ds.orders_table`
WHERE FORMAT_DATE('%Y-%m', order_date) IN ('2011-07', '2012-01')
GROUP BY month, discount
ORDER BY month, discount

--- 🎯 Business Objective
--- Predict whether an order will result in a loss based on discount and order characteristics, so the business can prevent unprofitable discounts

CREATE OR REPLACE TABLE `ml-project-482013.sales_ds.superstore_ml` AS
SELECT
  quantity,
  discount,
  sales,
  category,
  sub_category,
  region,
  ship_mode,
  CASE
    WHEN profit < 0 THEN 1
    ELSE 0
  END AS loss_flag
FROM `sales_ds.orders_table`


SELECT
  loss_flag,
  COUNT(*) AS rows_
FROM `ml-project-482013.sales_ds.superstore_ml`
GROUP BY loss_flag;

------------------------------------

  -- Train a model that learns:

  -- Q: When an order is likely to become a loss ?

  -- 🧠 Why Logistic Regression?

 --- Best for binary classification
 --- Explainable (key for interviews)
 --- Works great with discounts + categories

----------------------------------------

create or replace model `ml-project-482013.sales_ds.loss_prediction_model`
options(
  model_type = 'Logistic_reg',
  input_label_cols = ['loss_flag'], auto_class_weights = TRUE
) as 
SELECT
  quantity,
  discount,
  sales,
  category,
  sub_category,
  region,
  ship_mode,
  loss_flag
FROM `ml-project-482013.sales_ds.superstore_ml`;


--- model evaluation ---
 -- can this model realy ideantify loss makinng orders ?

select * from ml.evaluate(MODEL `sales_ds.loss_prediction_model`)


--- feature importane 
--- y loss happen


SELECT
  processed_input,
  weight
FROM ML.WEIGHTS(
  MODEL `ml-project-482013.sales_ds.loss_prediction_model`
)
ORDER BY ABS(weight) DESC;


 --- predict loss risk ----

 SELECT
  quantity,
  discount,
  sales,
  category,
  region,
  ship_mode,
  predicted_loss_flag,
  prob.prob AS loss_probability
FROM ML.PREDICT(
  MODEL `ml-project-482013.sales_ds.loss_prediction_model`,
  (
    SELECT
      quantity,
      discount,
      sales,
      category,
      sub_category,
      region,
      ship_mode
    FROM `ml-project-482013.sales_ds.orders_table`
  )
),
UNNEST(predicted_loss_flag_probs) AS prob
WHERE prob.label = 1
ORDER BY loss_probability DESC
LIMIT 100;


WITH predictions AS (
  SELECT
    profit,
    CASE WHEN profit < 0 THEN 1 ELSE 0 END AS loss_flag,
    predicted_loss_flag,
    predicted_loss_flag_probs[OFFSET(1)].prob AS loss_probability
  FROM ML.PREDICT(
    MODEL `ml-project-482013.sales_ds.loss_prediction_model`,
    (
      SELECT
        quantity,
        discount,
        sales,
        category,
        sub_category,
        region,
        ship_mode,
        profit
      FROM `ml-project-482013.sales_ds.orders_table`
    )
  )
)

SELECT
  COUNT(*) AS risky_loss_orders,
  SUM(profit) AS total_actual_loss,
  SUM(
    CASE
      WHEN loss_probability >= 0.80 THEN profit
      ELSE 0
    END
  ) AS avoidable_loss
FROM predictions
WHERE loss_flag = 1;

















