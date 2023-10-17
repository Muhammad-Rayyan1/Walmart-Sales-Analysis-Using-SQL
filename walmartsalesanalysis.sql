#Creating Database 
CREATE DATABASE IF NOT EXISTS SalesDataWalmart;

USE SalesDataWalmart;

#Creating table sales for SlaesDataWalmart
CREATE TABLE IF NOT EXISTS sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    vat FLOAT(6, 4) NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment_method VARCHAR(15) NOT NULL,
    cogs DECIMAL(10, 2) NOT NULL,
    gross_margin_pct FLOAT(11, 9),
    gross_income DECIMAL(12, 4) NOT NULL,
    rating FLOAT(2, 1)
);




-- -----------------------------------------------------------------------------------------
-- --------------------------------FEATURE ENGINEERING--------------------------------------

SET SQL_SAFE_UPDATES = 0;


#Add a new column named time_of_day to give insight of sales in the Morning, Afternoon and Evening. This will help answer the question on which part of the day most sales are made.

-- Add a new column named 'time_of_day' to the 'sales' table
ALTER TABLE sales
ADD time_of_day VARCHAR(20);

-- Update the 'time_of_day' column based on the time of the 'Time' column
UPDATE sales
SET time_of_day = CASE
    -- Morning: Transactions occurring from midnight to 11:59:59 AM
    WHEN TIME(Time) BETWEEN '00:00:00' AND '11:59:59' THEN 'Morning'
    
    -- Afternoon: Transactions occurring from 12:00:00 PM to 5:59:59 PM
    WHEN TIME(Time) BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
    
    -- Evening: All other transactions
    ELSE 'Evening'
END;


#Add a new column named day_name that contains the extracted days of the week on which the given transaction took place (Mon, Tue, Wed, Thur, Fri). This will help answer the question on which week of the day each branch is busiest.

ALTER TABLE sales
ADD day_name VARCHAR(3); -- Assuming you want the day abbreviation (Mon, Tue, etc.)

UPDATE sales
SET day_name = DATE_FORMAT(Date, '%a'); -- Extract and store the abbreviated day name


#Add a new column named month_name that contains the extracted months of the year on which the given transaction took place (Jan, Feb, Mar). Help determine which month of the year has the most sales and profit.

ALTER TABLE sales
ADD month_name VARCHAR(3); -- Assuming you want the month abbreviation (Jan, Feb, etc.)

-- Extract and store the abbreviated month name
UPDATE sales
SET month_name = DATE_FORMAT(Date, '%b');

-- Calculate total sales and profit for each month
SELECT
    month_name,
    MONTH(Date) AS month_number,
    SUM(Total) AS total_sales,
    SUM(gross_income) AS total_profit
FROM sales
GROUP BY month_name, month_number
ORDER BY month_number;




-- -----------------------------------------------------------------------------------------------
-- --------------------------------EXPLORATORY DATA ANALYSIS--------------------------------------

-- --- GENERIC-QUESTIONS -----

-- 1. How many unique cities does the data have?
SELECT COUNT(DISTINCT City) AS UniqueCitiesCount
FROM sales;

-- 2. In which city is each branch?
SELECT Branch, City
FROM sales
GROUP BY Branch, City;




-- --- PRODUCT-ANALYSIS-----

-- 1. How many unique product lines does the data have?
SELECT COUNT(DISTINCT `product_line`) AS UniqueProductLinesCount
FROM sales;

-- 2. What is the most common payment method?
SELECT payment_method, COUNT(*) AS PaymentFrequency
FROM sales
GROUP BY payment_method
ORDER BY PaymentFrequency DESC
LIMIT 1;

-- 3. What is the most selling product line?
SELECT `product_line`, SUM(quantity) AS TotalSold
FROM sales
GROUP BY `product_line`
ORDER BY TotalSold DESC
LIMIT 1;

-- 4. What is the total revenue by month?
SELECT
    DATE_FORMAT(Date, '%Y-%m') AS Month,
    SUM(total) AS TotalRevenue
FROM sales
GROUP BY Month;

-- 5. What month had the largest COGS?
SELECT
    DATE_FORMAT(Date, '%Y-%m') AS Month,
    SUM(`cogs`) AS TotalCOGS
FROM sales
GROUP BY Month
ORDER BY TotalCOGS DESC
LIMIT 1;

-- 6. What product line had the largest revenue?
SELECT `product_line`, SUM(total) AS TotalRevenue
FROM sales
GROUP BY `product_line`
ORDER BY TotalRevenue DESC
LIMIT 1;

-- 7. What is the city with the largest revenue?
SELECT city, SUM(total) AS TotalRevenue
FROM sales
GROUP BY city
ORDER BY TotalRevenue DESC
LIMIT 1;

-- 8. What product line had the largest VAT?
SELECT `product_line`, SUM(`vat`) AS TotalVAT
FROM sales
GROUP BY `product_line`
ORDER BY TotalVAT DESC
LIMIT 1;

-- 9. Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales
SELECT *,
    CASE
        WHEN quantity > (SELECT AVG(quantity) FROM sales) THEN 'Good'
        ELSE 'Bad'
    END AS SalesCategory
FROM sales;

-- 10. Which branch sold more products than average product sold?
SELECT branch
FROM sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM sales);

-- 11. What is the most common product line by gender?
SELECT Gender, `product_line`, COUNT(*) AS Frequency
FROM sales
GROUP BY gender, `product_line`
HAVING Frequency = (SELECT MAX(Frequency) FROM (SELECT gender, `product_line`, COUNT(*) AS Frequency FROM sales GROUP BY gender, `product_line`) AS temp);

-- 12. What is the average rating of each product line?
SELECT `product_line`, AVG(rating) AS AverageRating
FROM sales
GROUP BY `product_line`;




-- --- SALES-ANALYSIS-----

-- 1. Number of sales made in each time of the day per weekday
SELECT 
    DAYNAME(Date) AS Weekday,
    time_of_day,
    COUNT(*) AS SalesCount
FROM sales
GROUP BY Weekday, time_of_day
ORDER BY Weekday, time_of_day;

-- 2. Which of the customer types brings the most revenue?
SELECT `customer_type`, SUM(total) AS TotalRevenue
FROM sales
GROUP BY `customer_type`
ORDER BY TotalRevenue DESC
LIMIT 1;

-- 3. Which city has the largest tax percent/ VAT (Value Added Tax)?
SELECT city, AVG(`vat`) AS AvgTaxPercent
FROM sales
GROUP BY city
ORDER BY AvgTaxPercent DESC
LIMIT 1;

-- 4. Which customer type pays the most in VAT?
SELECT `customer_type`, SUM(`vat`) AS TotalVAT
FROM sales
GROUP BY `customer_type`
ORDER BY TotalVAT DESC
LIMIT 1;




-- --- CUSTOMER-ANALYSIS-----
-- 1. How many unique customer types does the data have?
SELECT COUNT(DISTINCT `customer_type`) AS UniqueCustomerTypesCount
FROM sales;

-- 2. How many unique payment methods does the data have?
SELECT COUNT(DISTINCT payment_method) AS UniquePaymentMethodsCount
FROM sales;

-- 3. What is the most common customer type?
SELECT `customer_type`, COUNT(*) AS CustomerTypeFrequency
FROM sales
GROUP BY `customer_type`
ORDER BY CustomerTypeFrequency DESC
LIMIT 1;

-- 4. Which customer type buys the most?
SELECT `customer_type`, SUM(quantity) AS TotalPurchased
FROM sales
GROUP BY `customer_type`
ORDER BY TotalPurchased DESC
LIMIT 1;

-- 5. What is the gender of most of the customers?
SELECT gender, COUNT(*) AS GenderFrequency
FROM sales
GROUP BY gender
ORDER BY GenderFrequency DESC
LIMIT 1;

-- 6. What is the gender distribution per branch?
SELECT branch, gender, COUNT(*) AS GenderCount
FROM sales
GROUP BY branch, gender;

-- 7. Which time of the day do customers give most ratings?
SELECT time_of_day, COUNT(*) AS RatingsCount
FROM sales
GROUP BY time_of_day
ORDER BY RatingsCount DESC
LIMIT 1;

-- 8. Which time of the day do customers give most ratings per branch?
SELECT branch, time_of_day, COUNT(*) AS RatingsCount
FROM sales
GROUP BY branch, time_of_day;

-- 9. Which day fo the week has the best avg ratings?
SELECT DAYNAME(Date) AS Weekday, AVG(rating) AS AvgRating
FROM sales
GROUP BY Weekday
ORDER BY AvgRating DESC
LIMIT 1;

-- 10. Which day of the week has the best average ratings per branch?
SELECT branch, DAYNAME(Date) AS Weekday, AVG(rating) AS AvgRating
FROM sales
GROUP BY branch, Weekday;