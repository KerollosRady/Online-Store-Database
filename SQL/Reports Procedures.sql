-- 1) Total sales
-- 2) Best-selling products
-- 3) Customers with the highest purchase activity
-- 4) Products with low stock levels

USE onlineStoreDB
GO


-- 1) Total sales
CREATE PROCEDURE sp_TotalSalesPeriod
    @start_date DATETIME,
    @end_date DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ISNULL(SUM(products_cost), 0) AS total_product_sales,
        ISNULL(SUM(shipping_fees), 0) AS total_shipping_fees,
        ISNULL(SUM(applied_discount), 0) AS total_discount,
        ISNULL(SUM(products_cost + shipping_fees - applied_discount), 0) AS total_net
    FROM Orders o
    WHERE o.order_status IN ('Paid','Shipped','Delivered')
        AND o.order_date BETWEEN @start_date AND @end_date

END;
GO


-- 2) Best-selling products
CREATE PROCEDURE sp_BestSellingProductsPeriod
    @start_date DATETIME,
    @end_date DATETIME,
    @top_count INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@top_count)
        p.product_id,
        p.name AS product_name,
        SUM(oi.quantity) AS total_quantity_sold,
        SUM(oi.quantity * oi.purchased_price) AS total_revenue
    FROM OrderItems oi
    JOIN Orders o ON oi.order_id = o.order_id
    JOIN Products p ON oi.product_id = p.product_id
    WHERE o.order_status IN ('Paid','Shipped','Delivered')
		AND o.order_date BETWEEN @start_date AND @end_date
    GROUP BY p.product_id, p.name
    ORDER BY total_quantity_sold DESC;
END;
GO


-- 3) Customers with the highest purchase activity
CREATE PROCEDURE sp_TopActiveCustomers
    @start_date DATETIME,
    @end_date DATETIME,
    @top_count INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@top_count)
        c.customer_id,
        u.name AS customer_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.quantity) AS total_items_purchased,
        SUM(oi.quantity * oi.purchased_price) AS total_spent
    FROM Customers c
    JOIN Users u ON c.customer_id = u.user_id
    JOIN Orders o ON c.customer_id = o.customer_id
    JOIN OrderItems oi ON o.order_id = oi.order_id
    WHERE o.order_status IN ('Paid','Shipped','Delivered')
		AND o.order_date BETWEEN @start_date AND @end_date
    GROUP BY c.customer_id, u.name
    ORDER BY total_spent DESC;
END;
GO


-- 4) Products with low stock levels
CREATE PROCEDURE sp_LowStockProducts
    @top_count INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@top_count)
        product_id,
        name AS product_name,
        stock_quantity
    FROM Products
    WHERE is_active = 1
    ORDER BY stock_quantity;
END;
GO

EXEC sp_TotalSalesPeriod '2026-01-01 08:00', '2026-02-20 18:30';
EXEC sp_BestSellingProductsPeriod '2026-01-01 08:00', '2026-02-20 18:30', 2;
EXEC sp_TopActiveCustomers '2026-01-01 08:00', '2026-02-20 18:30', 2;
EXEC sp_LowStockProducts 10;