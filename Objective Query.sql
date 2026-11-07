create database p;
use p;

-- Q14
WITH CustomerMetrics AS (
    SELECT
        CustomerID,
        SUM(`Sale Price` * `Order Quantity`) AS TotalRevenue,
        COUNT(DISTINCT OrderID) AS OrderFrequency,
        AVG(`Sale Price` * `Order Quantity`) AS AverageOrderValue
    FROM Orders
    GROUP BY CustomerID
)
SELECT
    CustomerID,
    TotalRevenue,
    OrderFrequency,
    AverageOrderValue,
    (
        TotalRevenue * 0.50 +
        OrderFrequency * 0.30 +
        AverageOrderValue * 0.20
    ) AS CompositeScore
FROM CustomerMetrics
ORDER BY CompositeScore DESC
LIMIT 5;

-- Q15
WITH MonthlyRevenue AS (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(`Sale Price` * `Order Quantity`) AS TotalRevenue
    FROM Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)

SELECT
    OrderYear,
    OrderMonth,
    TotalRevenue,
    LAG(TotalRevenue) OVER (ORDER BY OrderYear, OrderMonth) AS PreviousMonthRevenue,
    ROUND(
        (
            (TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY OrderYear, OrderMonth))
            / LAG(TotalRevenue) OVER (ORDER BY OrderYear, OrderMonth)
        ) * 100,
        2
    ) AS MoM_Growth_Percentage
FROM MonthlyRevenue
ORDER BY OrderYear, OrderMonth;

-- Q16
WITH MonthlyRevenue AS (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        `Product Category`,
        SUM(`Sale Price` * `Order Quantity`) AS MonthlyRevenue
    FROM Orders
    GROUP BY
        YEAR(OrderDate),
        MONTH(OrderDate),
        `Product Category`
)

SELECT
    OrderYear,
    OrderMonth,
    `Product Category`,
    MonthlyRevenue,
    ROUND(
        AVG(MonthlyRevenue) OVER (
            PARTITION BY `Product Category`
            ORDER BY OrderYear, OrderMonth
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS Rolling_3_Month_Avg_Revenue
FROM MonthlyRevenue
ORDER BY
    `Product Category`,
    OrderYear,
    OrderMonth;
    
   
-- Q17
UPDATE Orders
SET `Sale Price` = `Sale Price` * 0.85
WHERE CustomerID IN (
    SELECT CustomerID
    FROM (
        SELECT CustomerID
        FROM Orders
        GROUP BY CustomerID
        HAVING COUNT(DISTINCT OrderID) >= 10
    ) AS EligibleCustomers
);


-- Q18
WITH CustomerOrders AS (
    SELECT
        CustomerID,
        STR_TO_DATE(OrderDate, '%d-%m-%Y') AS OrderDate,
        LAG(STR_TO_DATE(OrderDate, '%d-%m-%Y'))
            OVER (PARTITION BY CustomerID
                  ORDER BY STR_TO_DATE(OrderDate, '%d-%m-%Y')) AS PreviousOrderDate
    FROM Orders
),
OrderIntervals AS (
    SELECT
        CustomerID,
        DATEDIFF(OrderDate, PreviousOrderDate) AS DaysBetweenOrders
    FROM CustomerOrders
    WHERE PreviousOrderDate IS NOT NULL
)

SELECT
    CustomerID,
    ROUND(AVG(DaysBetweenOrders), 2) AS AvgDaysBetweenOrders
FROM OrderIntervals
GROUP BY CustomerID
HAVING COUNT(*) >= 4;


-- Q19
WITH CustomerRevenue AS (
    SELECT
        CustomerID,
        SUM(`Sale Price` * `Order Quantity`) AS TotalRevenue
    FROM Orders
    GROUP BY CustomerID
),
AverageRevenue AS (
    SELECT
        AVG(TotalRevenue) AS AvgRevenuePerCustomer
    FROM CustomerRevenue
)
SELECT
    cr.CustomerID,
    cr.TotalRevenue,
    ar.AvgRevenuePerCustomer,
    ROUND(ar.AvgRevenuePerCustomer * 1.30, 2) AS RevenueThreshold
FROM CustomerRevenue cr
CROSS JOIN AverageRevenue ar
WHERE cr.TotalRevenue > ar.AvgRevenuePerCustomer * 1.30
ORDER BY cr.TotalRevenue DESC;


-- Q20
WITH YearlySales AS (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        `Product Category`,
        SUM(`Sale Price` * `Order Quantity`) AS TotalSales
    FROM Orders
    GROUP BY
        YEAR(OrderDate),
        `Product Category`
),
YearlyGrowth AS (
    SELECT
        OrderYear,
        `Product Category`,
        TotalSales,
        LAG(TotalSales) OVER (
            PARTITION BY `Product Category`
            ORDER BY OrderYear
        ) AS PreviousYearSales
    FROM YearlySales
)

SELECT
    OrderYear,
    `Product Category`,
    TotalSales,
    PreviousYearSales,
    (TotalSales - PreviousYearSales) AS SalesIncrease
FROM YearlyGrowth
WHERE PreviousYearSales IS NOT NULL
ORDER BY SalesIncrease DESC
LIMIT 3;