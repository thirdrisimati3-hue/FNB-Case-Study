----------------------------------------------------------------------
-- MASTER SALES ANALYTICS QUERY
----------------------------------------------------------------------

WITH Sales_Base AS
(
SELECT
        Date,

    -- Date Dimensions
        YEAR(Date) AS Year,
        MONTHNAME(Date) AS Month_Name,
        DAYNAME(Date) AS Day_Name,
        Sales,
        `Cost Of Sales`,
        `Quantity Sold`,
-- Unit Price
    ROUND(Sales / `Quantity Sold`,2) AS Unit_Price,
    ROUND(`Cost Of Sales`/ `Quantity Sold`,2) AS Cost_Per_Unit
FROM fnb_sales.default.fnb_sales
),
Sales_Calculations AS
(
SELECT *,

    --------------------------------------------------
    -- Profitability Metrics
    --------------------------------------------------
    ROUND(Sales-`Cost Of Sales`,2) AS Gross_Profit,
    ROUND(((Sales-`Cost Of Sales`) / Sales)*100,2) AS Gross_Profit_Percentage,
    ROUND(((Sales-`Cost Of Sales`) / `Cost Of Sales`)*100,2) AS Gross_Profit_Per_Unit,

    --------------------------------------------------
    -- Daily Growth
    --------------------------------------------------
    ROUND(((Sales-LAG(Sales) OVER(ORDER BY Date))/LAG(Sales) OVER(ORDER BY Date))*100 ,2) AS Revenue_Growth_Percent,
    ROUND(((`Quantity Sold`-LAG(`Quantity Sold`) OVER(ORDER BY Date))/LAG(`Quantity Sold`) OVER(ORDER BY Date))*100,2) AS Quantity_Growth_Percent,

    --------------------------------------------------
    -- Running Totals
    --------------------------------------------------
    SUM(Sales)OVER(ORDER BY Date)AS Running_Sales,
    SUM(Sales-`Cost Of Sales`)OVER(ORDER BY Date)AS Running_Gross_Profit,
    SUM(`Quantity Sold`)OVER(ORDER BY Date)AS Running_Quantity,

    --------------------------------------------------
    -- Moving Averages
    --------------------------------------------------
    ROUND(AVG(Sales)OVER(ORDER BY Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS Weekly_Sales_Moving_Avg,
    ROUND(AVG(Sales)OVER(ORDER BY Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW),2) AS Monthly_Sales_Moving_Avg,

    --------------------------------------------------
    -- Previous Values
    --------------------------------------------------
    LAG(Unit_Price)OVER(ORDER BY Date) AS Previous_Unit_Price,LAG(`Quantity Sold`)OVER(ORDER BY Date) AS Previous_Quantity,
    LAG(Sales)OVER(ORDER BY Date) AS Previous_Sales
FROM Sales_Base
)

SELECT *,
    --------------------------------------------------
    -- Promotion Flag
    --------------------------------------------------
    CASE
        WHEN Unit_Price < AVG(Unit_Price) OVER()*0.90 THEN 'Promotion'
        ELSE 'Normal Price'
    END AS Promotion_Flag,

    --------------------------------------------------
    -- Loss Flag
    --------------------------------------------------
    CASE
        WHEN Sales < `Cost Of Sales`THEN 'Loss'
        ELSE 'Profit'
    END AS Profit_Status,

    --------------------------------------------------
    -- Price Elasticity
    --------------------------------------------------
    COALESCE(ROUND(TRY_DIVIDE(TRY_DIVIDE(`Quantity Sold` - Previous_Quantity, Previous_Quantity),TRY_DIVIDE(Unit_Price - Previous_Unit_Price, Previous_Unit_Price)), 2),0) AS Price_Elasticity,

    --------------------------------------------------
    -- Elasticity Classification
    --------------------------------------------------
    CASE
        WHEN Previous_Quantity IS NULL OR Previous_Unit_Price IS NULL THEN 'Undefined'
        WHEN COALESCE(ROUND(TRY_DIVIDE(TRY_DIVIDE(`Quantity Sold` - Previous_Quantity, Previous_Quantity),TRY_DIVIDE(Unit_Price - Previous_Unit_Price, Previous_Unit_Price)),2),0) = 0 THEN 'Perfectly Inelastic'
        WHEN COALESCE(ROUND(TRY_DIVIDE(TRY_DIVIDE(`Quantity Sold` - Previous_Quantity, Previous_Quantity),TRY_DIVIDE(Unit_Price - Previous_Unit_Price, Previous_Unit_Price)),2),0) > 0 AND COALESCE(ROUND(TRY_DIVIDE(TRY_DIVIDE(`Quantity Sold` - Previous_Quantity, Previous_Quantity),TRY_DIVIDE(Unit_Price - Previous_Unit_Price, Previous_Unit_Price)),2),0) < 1 THEN 'Inelastic Demand'
        WHEN COALESCE(ROUND(TRY_DIVIDE(TRY_DIVIDE(`Quantity Sold` - Previous_Quantity, Previous_Quantity),TRY_DIVIDE(Unit_Price - Previous_Unit_Price, Previous_Unit_Price)),2),0) = 1 THEN 'Unit Elastic'
        WHEN COALESCE(ROUND(TRY_DIVIDE(TRY_DIVIDE(`Quantity Sold` - Previous_Quantity, Previous_Quantity),TRY_DIVIDE(Unit_Price - Previous_Unit_Price, Previous_Unit_Price)),2),0) > 1 THEN 'Elastic Demand'
        WHEN ABS(Unit_Price - Previous_Unit_Price) < 0.000001 AND `Quantity Sold` <> Previous_Quantity THEN 'Perfectly Elastic'
        ELSE 'Undefined'
    END AS Demand_Elasticity
FROM Sales_Calculations
ORDER BY Date;
