select * from orders_clean

ALTER TABLE dbo.orders_clean
ADD Profit_per_item AS 
    ([List_Price] * (100.0 - [Discount_Percent]) / 100.0) 
    - [cost_price]
    PERSISTED;

ALTER TABLE dbo.orders_clean
DROP COLUMN Profit_per_item;

ALTER TABLE dbo.orders_clean
ALTER COLUMN cost_price DECIMAL(18,2);

ALTER TABLE dbo.orders_clean
ALTER COLUMN List_Price DECIMAL(18,2);


ALTER TABLE dbo.orders_clean 
ALTER COLUMN Discount_Percent DECIMAL(5,2);


/*
SELECT COLUMN_NAME, DATA_TYPE, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'orders_clean';
*/

ALTER TABLE orders_clean
ALTER COLUMN cost_price DECIMAL(18,2);

ALTER TABLE orders_clean
ALTER COLUMN List_Price DECIMAL(18,2);

ALTER TABLE orders_clean
ALTER COLUMN Quantity DECIMAL(18,2);


--(A)Overall Sales & Profitability

--1. Which regions, states, and cities generate the highest total sales and profit?
select State, sum(profit) [Total Profit] from orders_clean
group by State
order by [Total Profit] desc
-------------------------------
select City, sum(profit) [Total Profit] from orders_clean
group by City
order by [Total Profit] desc
-------------------------------
select Region, sum(profit) [Total Profit] from orders_clean
group by Region
order by [Total Profit] desc
--2. Are there any geographic “underperformers” where sales are high but profits are low (or negative)?
select Region,State,(sum((List_Price*(100-Discount_percent)/100)*Quantity)) [Sales],
(sum(Profit_per_item)/(sum(List_Price*(100-Discount_percent)/100))*100) [Profit Margin] 
from orders_clean
group by Region,State
having (sum(Profit_per_item)/(sum(List_Price*(100-Discount_percent)/100))*100) < 7.5
order by Region, [Sales] desc, [Profit Margin] asc


--(B)Category & Sub-Category Performance

--1. Which product categories (Furniture, Office Supplies, Technology) and sub-categories deliver the best profit margins?
select Category,Sub_category, (sum(Profit_per_item)/(sum(List_Price*(100-Discount_percent)/100))*100) [Profit Margin] from orders_clean
group by Category,Sub_category
having (sum(Profit_per_item)/(sum(List_Price*(100-Discount_percent)/100))*100) > 9
order by Category, [Profit Margin] desc

--2. Are there specific sub-categories that consistently incur losses and should be reconsidered?
select Sub_category, count(profit) [Total Bad Sales] from orders_clean
where profit < 0
group by Sub_category
order by [Total Bad Sales] desc


--(C)Customer Segment Analysis

--How do sales volume, average order size, and profit differ across segments (Consumer, Corporate, Home Office)?
select Segment, (sum((List_Price*(100-Discount_percent)/100)*Quantity)) [Sales],
((sum((List_Price*(100-Discount_percent)/100)*Quantity)/count(Order_Id))) [Avg Order Size],
sum(profit) [Profit]
from orders_clean
group by Segment
order by Segment

--Which segment offers the highest lifetime value, and where should marketing efforts be focused?
select Segment, (sum((List_Price*(100-Discount_percent)/100)*Quantity)) [Sales],
sum(profit) [Profit]
from orders_clean
group by Segment
order by Segment

--(D)Discounting Impact

--What is the relationship between discount percent and profit per order?
select Discount_Percent, sum(Profit_per_item) [Profit per Discount], count(Order_id) [No. of Orders] from orders_clean
group by Discount_Percent
order by Discount_Percent 

--Is there an optimal discount range that maximizes volume without eroding margin?
select Discount_Percent,
(sum((List_Price*(100-Discount_percent)/100)*Quantity)) [Sales] ,
(sum(Profit_per_item)/(sum(List_Price*(100-Discount_percent)/100))*100) [Profit Margin]
from orders_clean
group by Discount_Percent
order by Discount_Percent 


--(E)Ship Mode & Fulfillment Efficiency

--1. How does ship mode (Standard vs. Second Class vs. Next Day) affect on-time delivery, cost, and profit?
select Ship_Mode, 
sum(cost_price*Quantity) [Total Cost],
(sum(Profit_per_item)/(sum(List_Price*(100-Discount_percent)/100))*100) [Profit Margin]
from orders_clean
group by Ship_Mode
Order by [Total Cost] desc

--2. Should we adjust our shipping policy or renegotiate carrier rates based on profitability analysis by ship mode?
/*
We can remove discounts on items which are offered in First Class and Same day to balance our Profit margins.
*/


--(F)Seasonality & Trends

--1. Are there monthly or quarterly seasonality patterns in orders, revenue, or profit?
SELECT 
    DATEPART(YEAR, Order_Date) AS Order_Year,
    DATEPART(MONTH, Order_Date) AS Order_Month,
    COUNT(Order_ID) AS Total_Orders,
    SUM(Quantity * (List_Price * (100.0 - Discount_Percent) / 100.0)) AS Total_Revenue,
    SUM(profit) AS Total_Profit
FROM dbo.orders_clean
GROUP BY 
    DATEPART(YEAR, Order_Date),
    DATEPART(MONTH, Order_Date)
ORDER BY 
    Order_Year,
    Order_Month;


--2. Can we forecast peak demand periods for each category to optimize inventory levels?

SELECT Category,
    DATEPART(YEAR, Order_Date) AS Order_Year,
    DATEPART(MONTH, Order_Date) AS Order_Month,
    COUNT(Order_ID) AS Total_Orders,
    SUM(Quantity * (List_Price * (100.0 - Discount_Percent) / 100.0)) AS Total_Revenue,
    SUM(profit) AS Total_Profit
FROM dbo.orders_clean
where Category = 'Technology'
GROUP BY
    DATEPART(YEAR, Order_Date),
    DATEPART(MONTH, Order_Date),
	Category
ORDER BY 
    Order_Year,
    Order_Month;


--(G)Order Size & Frequency

--1. What is the distribution of order quantities and order values?
/*
Need a histogram for this
*/

--2. Which customers place the largest and most frequent orders, and can we create loyalty tiers?
select Segment,Category,(sum((List_Price*(100-Discount_percent)/100)*Quantity)) [Sales] ,
count(Order_Id) [No. of Orders], 
(sum((List_Price*(100-Discount_percent)/100)*Quantity))/(count(Order_Id)) as Avg_Order_size
from orders_clean
group by Segment,Category order by [Sales] desc



--(H)Product-Level Insights

--1. Which individual products (by Product Id) are our top sellers and top profit drivers?

select Category,Sub_Category,Product_Id,count(Order_Id) [No. of Orders],sum(profit) [Total Profit] from orders_clean
group by Category,Sub_Category,Product_Id
order by [Total Profit] desc


--2. Are any specific items showing declining sales or profitability that warrant delisting?
SELECT Product_Id,
    DATEPART(YEAR, Order_Date) AS Order_Year,
    DATEPART(MONTH, Order_Date) AS Order_Month,
    COUNT(Order_ID) AS Total_Orders,
    SUM(Quantity * (List_Price * (100.0 - Discount_Percent) / 100.0)) AS Total_Revenue,
    SUM(profit) AS Total_Profit
FROM dbo.orders_clean
GROUP BY Product_Id,
    DATEPART(YEAR, Order_Date),
    DATEPART(MONTH, Order_Date)
ORDER BY Product_Id,
	Order_Year,
    Order_Month



--(I)Cost vs. List Price Dynamics

--1. How often does list price significantly exceed cost price, and what margin buffer does that create?
--Significant = 25%
select segment,count(Order_Id) [No. of Orders], avg(((List_Price-cost_price)/cost_price)*100) [Average buffer]
from orders_clean
where List_Price is not null and cost_price is not null and (List_Price-cost_price) > (0.25*cost_price)
group by Segment;

--2. Where are cost increases (e.g., commodity price hikes) squeezing margins?
/*
Information not available
*/



--(J)Regional Profitability Drivers

--1. Within each region (West, South, etc.), what combination of category, segment, and ship mode yields the highest profit?
with CTE as (
select Region,Segment,Category,Ship_Mode,sum(profit) [Profit] From orders_clean
group by Region,Segment,Category,Ship_Mode
)
select * from CTE 
--where Region = 'Central'
order by Profit desc




--2. Can we replicate best-practices from high-profit locales in lower-profit ones?
with CTE as (
select Region,Segment,Category,Ship_Mode,sum(profit) [Profit] From orders_clean
group by Region,Segment,Category,Ship_Mode
)
select * from CTE 
--where Region = 'Central'
order by Profit




--(K)Customer Churn & Retention

--1. By tracking repeat orders over time, which customers are churning after an initial purchase?
-- Customer info not available
--What factors (ship mode, discount level, product type) correlate with higher repeat rates?
-- customer info not available




--(L)Promotion Effectiveness

--For orders placed during promotional periods (assumed by higher discounts), did we achieve uplift in volume sufficient to offset lower unit margin?
select Category,Sub_Category, Discount_Percent, count(Order_Id) [No. of Orders],
(sum((List_Price*(100-Discount_percent)/100)*Quantity)) [Sales]
from orders_clean
group by Category,Sub_Category, Discount_Percent
order by Category,Sub_Category, Discount_Percent


--Which promotions were most and least profitable?
select Segment,Discount_Percent, count(Order_Id) [No. of Orders],
(sum((List_Price*(100-Discount_percent)/100)*Quantity)) [Sales]
from orders_clean
group by Segment,Discount_Percent
order by Segment,Discount_Percent



--(M)Shipping Cost Allocation

--1. Can we estimate actual shipping costs per order (using ship mode as a proxy) and allocate them to measure net profit more accurately?
-- We don't have information of cost per shipping mode

--2. Which orders are effectively subsidizing shipping, and is there scope to pass through more cost to customers?
-- We don't have information



--(N)Inventory Planning & Stockouts

--1. Based on sales velocity by product and region, which SKUs risk stockouts, and when should we reorder?
-- No inventory info
--2. Are there slow-moving items that tie up working capital?
-- No inventory info


--(O)Cross-Sell & Up-Sell Opportunities

--Which products are frequently bought together (e.g., tables and chairs)?

--How can bundles or targeted recommendations increase average order value?
