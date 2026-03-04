Use onlineStoreDB;
GO

-- All orders for a specific customer (by email)
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    o.products_cost,
    o.applied_discount
FROM Orders o
JOIN Users u ON o.customer_id = u.user_id
WHERE u.email = 'ahmed@gmail.com'
ORDER BY o.order_date DESC;


-- Total Sales Summary Between Two Dates
EXEC sp_TotalSales '2026-01-01 08:00', '2026-02-20 18:30';

-- Top 2 Best-Selling Products Between Two Dates
EXEC sp_BestSellingProducts '2026-01-01 08:00', '2026-02-20 18:30', 2;

-- Top 2 Customers with the highest purchase activity
EXEC sp_TopActiveCustomers '2026-01-01 08:00', '2026-02-20 18:30', 2;

-- The 10 Products with the Lowest Stock Levels
EXEC sp_LowStockProducts 10;

