USE onlineStoreDB;
GO

INSERT INTO Users (name, email, password_hash)
VALUES
('Ahmed Hassan', 'ahmed@gmail.com', 'hashed_pass1'),
('Sara Ali', 'sara@gmail.com', 'hashed_pass2'),
('Omar Khaled', 'omar@gmail.com', 'hashed_pass3'),
('Admin1', 'admin1@store.com', 'hashed_admin1'),
('Admin2', 'admin2@store.com', 'hashed_admin2');
GO

INSERT INTO Customers (customer_id, phone)
VALUES
(1, '01012345678'),
(2, '01198765432'),
(3, '01255554444');
GO

INSERT INTO Admins (admin_id, creator_id)
VALUES
(4, NULL),  -- First admin
(5, 4);     -- Created by Admin 4
GO

INSERT INTO Categories (name, parent_category_id)
VALUES
('Electronics', NULL),
('Mobiles', 1),
('Laptops', 1),
('Home Appliances', NULL);
GO

INSERT INTO Coupons (coupon_code, type, value, min_discount, max_discount, remaining_usage, expire_date)
VALUES
('SALE10', 'Percent', 5, 0, 5000, 100, '2026-12-31'),
('FLAT200', 'Value', 1000, 1000, 1000, 20, '2026-06-30');
GO

INSERT INTO Products (name, description, brand, weight, price, stock_quantity, category_id, created_date)
VALUES
('iPhone 17 Pro Max', 'Latest Apple iPhone', 'Apple', 0.5, 80000, 20, 2, '2025-12-10'),
('Samsung S25 Ultra', 'Flagship Samsung phone', 'Samsung', 0.45, 65000, 15, 2, '2025-06-23'),
('Dell XPS 15', 'High performance laptop', 'Dell', 2.0, 60000, 8, 3, '2026-12-31'),
('Microwave Oven', '800W microwave', 'LG', 7.5, 5000, 25, 4, '2024-10-31');
GO

INSERT INTO ProductImages (product_id, image_url)
VALUES
(1, 'iphone17ProMax_1.jpg'),
(1, 'iphone17ProMax_2.jpg'),
(2, 's25Ultra.jpg'),
(3, 'xps15.jpg'),
(4, 'microwave.jpg');
GO

INSERT INTO Orders (customer_id, order_status, order_date, delivery_date,
                    shipping_fees, payment_reference, payment_method, pay_date,
                    address, city)
VALUES
(1, 'Delivered', '2026-01-10', GETDATE(), 100, 'PAY123', 'Credit Card', GETDATE(), 'Nasr City', 'Cairo'),
(2, 'Shipped', '2026-02-15', NULL, 100, 'PAY124', 'Vodafone Cash', GETDATE(), 'Smouha', 'Alexandria'),
(3, 'Pending', '2026-02-20', NULL, 50, NULL, NULL, NULL, '6th October', 'Giza');
GO

INSERT INTO OrderItems (order_id, product_id, quantity, purchased_price)
VALUES
(1, 1, 1, 60000),
(1, 4, 1, 5300),
(2, 2, 1, 55000),
(3, 3, 1, 60000);
GO


INSERT INTO Ratings (customer_id, product_id, rating, review)
VALUES
(1, 1, 5, 'Excellent phone!')
GO

-- Update Orders with Coupons
UPDATE Orders
SET coupon_code = 'SALE10'
WHERE order_id = 1;

UPDATE Orders
SET coupon_code = 'FLAT200'
WHERE order_id = 2;
GO