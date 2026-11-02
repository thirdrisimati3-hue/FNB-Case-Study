-- Chekcing the dataset
SELECT *
FROM fnb_sales.default.fnb_sales
LIMIT 100;

--Check the highest sales and the lowest sales
SELECT MIN(Sales) AS Lowest_Sale,
        MAX(Sales) AS Highest_Sale
FROM fnb_sales.default.fnb_sales

--Check the highest Cost of sales and the lowest  cost of sales
SELECT MIN(`Cost Of Sales`) AS Lowest_Cost_of_Sale,
        MAX(`Cost Of Sales`) AS Highest_Cost_of_Sale
FROM fnb_sales.default.fnb_sales

--Check the hiest Quantity sold and lowest quantity sold
SELECT MIN(`Quantity Sold`) AS Lowest_QTD_Sold,
        MAX(`Quantity Sold`) AS Highest_QTD_sold
FROM fnb_sales.default.fnb_sales

-- Computing for date functions
SELECT
    Date,
    YEAR(Date) AS Year,
    MONTHNAME(Date) AS Month_Name,
     QUARTER(Date) AS Quarter_Year,
    DAYNAME(Date) AS Day_Name
FROM fnb_sales.default.fnb_sales;

-- Question 1 -- Daily sales price per unit 
SELECT
    `date`,
    Sales,
    `Quantity Sold`,
    ROUND(Sales / `Quantity Sold`, 2) AS Daily_price_per_unit
FROM fnb_sales.default.fnb_sales
ORDER BY `date`;

-- Question 2 -- Average unit sales price of the product
SELECT
    ROUND(AVG(Sales / `Quantity Sold`), 2) AS Avg_unit_sales_price
FROM fnb_sales.default.fnb_sales;

-- Question 3 -- Daily gross profit and daily percentage gross profit
SELECT
    Date,
    Sales,
   `Cost Of Sales`,
    ROUND(Sales - `Cost Of Sales`, 2) AS Gross_Profit,
    ROUND(((Sales - `Cost Of Sales`)/Sales)*100,2) AS Gross_Profit_Percentage,
    CASE 
        WHEN Sales < `Cost Of Sales` THEN 1 
        ELSE 0 
    END AS Loss_day
FROM fnb_sales.default.fnb_sales
ORDER BY `date`;

-- Qustion 4 -- Daily Gross Profit Percentage per Unit
SELECT Date,
        ROUND((Sales-`Cost Of Sales`)/`Cost Of Sales`,2) AS Gross_Profit_Per_Unit
FROM fnb_sales.default.fnb_sales
ORDER BY Date;

-- Deriving daily revenue growth
SELECT Date,
        Sales,
        ROUND(((Sales - LAG(Sales) OVER(ORDER BY Date)) /LAG(Sales) OVER(ORDER BY Date))*100,2) AS Revenue_Growth
FROM fnb_sales.default.fnb_sales
ORDER BY Date;

-- Calculating daily quantity growth
SELECT Date, 
    `Quantity Sold`,
ROUND(((`Quantity Sold`-LAG(`Quantity Sold`) OVER(ORDER BY Date))/LAG(`Quantity Sold`) OVER(ORDER BY Date))*100,2) AS Quantity_Growth
FROM fnb_sales.default.fnb_sales;

-- Calculating running sales
SELECT Date,
    Sales,
    SUM(Sales) OVER(ORDER BY Date) AS Running_Sales
FROM fnb_sales.default.fnb_sales;

-- Computing for running profit
SELECT Date,
SUM(Sales-`Cost Of Sales`) OVER(ORDER BY Date) AS Running_Profit
FROM fnb_sales.default.fnb_sales;

-- Computing for one moving average sales
SELECT Date, 
        Sales,
ROUND(AVG(Sales)OVER(ORDER BY Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS Weekly_Sales_Moving_Avg,
ROUND(AVG(Sales)OVER(ORDER BY Date ROWS BETWEEN 30 PRECEDING AND CURRENT ROW),2) AS Monthly_Sales_Moving_Avg
FROM fnb_sales.default.fnb_sales;

-- Computing for promotional periods
WITH Prices AS
(
SELECT *,
        Sales/`Quantity Sold` AS Unit_Price
FROM fnb_sales.default.fnb_sales
)

SELECT *,
    CASE
        WHEN Unit_Price <AVG(Unit_Price) OVER()*0.90 THEN 'Promotion'
    ELSE 'Normal Price'
END AS PromotionFlag
FROM Prices;

--Computing for Price Elasticity of Demand

WITH Elasticity AS
(
SELECT Date,
       Sales,
        `Quantity Sold`,
        Sales/`Quantity Sold` AS Price,
        LAG(Sales/`Quantity Sold`)OVER(ORDER BY Date) PreviousPrice, LAG(`Quantity Sold`) OVER(ORDER BY Date) PreviousQuantity
FROM fnb_sales.default.fnb_sales
)

SELECT
        Date,
        ROUND(((`Quantity Sold`-PreviousQuantity)/PreviousQuantity)/((Price-PreviousPrice)/PreviousPrice),2) AS Price_Elasticity,
    CASE
        WHEN Price_Elasticity > 1 THEN 'Elastic Demand'
        WHEN Price_Elasticity < 1 THEN 'Inelastic Demand'
        WHEN Price_Elasticity = 1 THEN 'Unit Elastic Demand'
        ELSE 'Undefined'
    END AS Demand_Elasticity
FROM Elasticity
WHERE PreviousPrice IS NOT NULL;
