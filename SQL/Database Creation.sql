USE master;
GO
CREATE DATABASE onlineStoreDB;
GO

USE onlineStoreDB;
GO

CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_date DATETIME NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY REFERENCES Users(user_id),
    phone VARCHAR(11) NOT NULL CHECK (
        LEN(phone) = 11
        AND phone NOT LIKE '%[^0-9]%' -- only digits
        AND LEFT(phone, 3) IN ('010','011','012','015')
    )
);
GO

CREATE TABLE Admins (
    admin_id INT PRIMARY KEY REFERENCES Users(user_id),
    creator_id INT NULL REFERENCES Admins(admin_id)
);
GO

CREATE TABLE Categories (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(50) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    parent_category_id INT NULL REFERENCES Categories(category_id),
    CONSTRAINT UQ_Categories_Name_Parent UNIQUE (name, parent_category_id)
);
GO

CREATE TABLE Coupons (
    coupon_code NVARCHAR(20) PRIMARY KEY,
    expire_date DATETIME NULL,
    type VARCHAR(10) NOT NULL CHECK (type IN ('Percent','Value')),
    value DECIMAL(10,2) NOT NULL DEFAULT 0,
    remaining_usage INT NOT NULL DEFAULT 0 CHECK (remaining_usage >= 0),
    min_discount DECIMAL(10,2) NOT NULL CHECK (min_discount >= 0),
    max_discount DECIMAL(10,2) NOT NULL,
    CONSTRAINT CK_Coupons_Max_Gte_Min CHECK (max_discount >= min_discount),
    CONSTRAINT CK_Coupons_Value_Valid CHECK (
        (type = 'Percent' AND value >= 0 AND value <= 100) OR
        (type = 'Value' AND value = min_discount AND value = max_discount)
    )
);
GO

CREATE TABLE Products (
    product_id INT IDENTITY(1,1) PRIMARY KEY,  
    name NVARCHAR(100) NOT NULL,
    description NVARCHAR(1000) NULL,
    brand NVARCHAR(50) NULL,
    weight DECIMAL(10,2) NULL CHECK (weight >= 0),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    created_date DATETIME NOT NULL DEFAULT GETDATE(),
    is_active BIT NOT NULL DEFAULT 1,
    category_id INT NULL REFERENCES Categories(category_id)
);
GO

CREATE TABLE Ratings (
    customer_id INT NOT NULL REFERENCES Customers(customer_id),
    product_id INT NOT NULL REFERENCES Products(product_id),
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    rating_date DATETIME NOT NULL DEFAULT GETDATE(),
    review NVARCHAR(255) NULL,
    PRIMARY KEY (customer_id, product_id)
);
GO

CREATE TABLE Carts (
    customer_id INT NOT NULL REFERENCES Customers(customer_id),
    product_id INT NOT NULL REFERENCES Products(product_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (customer_id, product_id)
);
GO

CREATE TABLE ProductImages (
    product_id INT NOT NULL REFERENCES Products(product_id),
    image_url VARCHAR(255) NOT NULL,
    PRIMARY KEY (product_id, image_url)
);
GO

CREATE TABLE Orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    order_status VARCHAR(20) NOT NULL CHECK (order_status IN ('Pending','Paid','Shipped','Delivered','Cancelled')),
    address NVARCHAR(255) NOT NULL,
    city NVARCHAR(100) NOT NULL,
    order_date DATETIME NOT NULL DEFAULT GETDATE(),
    delivery_date DATETIME NULL,
	products_cost DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (products_cost >= 0),
    shipping_fees DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (shipping_fees >= 0),
    payment_reference VARCHAR(50) NULL,
    payment_method VARCHAR(20) NULL,
    pay_date DATETIME NULL,
	coupon_code NVARCHAR(20) NULL REFERENCES Coupons(coupon_code),
	applied_discount DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (applied_discount >= 0),
    customer_id INT NOT NULL REFERENCES Customers(customer_id),
	CONSTRAINT CK_Discount_Lte_Cost CHECK (applied_discount = 0 OR applied_discount <= products_cost)
);
GO

CREATE TABLE OrderItems (
    order_id INT NOT NULL REFERENCES Orders(order_id),
    product_id INT NOT NULL REFERENCES Products(product_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    purchased_price DECIMAL(10,2) NOT NULL CHECK (purchased_price >= 0),
    PRIMARY KEY (order_id, product_id)
);
GO

-- Calculate the total order cost (without coupons)
CREATE TRIGGER trg_UpdateProductsCost
ON OrderItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- affected orders
    WITH ChangedOrders AS (
        SELECT order_id FROM inserted
        UNION
        SELECT order_id FROM deleted
    )

    UPDATE o
    SET products_cost = ISNULL((
        SELECT SUM(oi.quantity * oi.purchased_price)
        FROM OrderItems oi
        WHERE oi.order_id = o.order_id
    ), 0)
    FROM Orders o
    JOIN ChangedOrders co ON o.order_id = co.order_id;
END;
GO

-- Check if inserted ratings belong to customers who purchased the product
CREATE TRIGGER trg_AllowRatingOnlyIfPurchased
ON Ratings
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM Orders o
            JOIN OrderItems oi ON o.order_id = oi.order_id
            WHERE o.customer_id = i.customer_id
              AND oi.product_id = i.product_id
              AND o.order_status IN ('Paid','Shipped','Delivered')
        )
    )
    BEGIN
        RAISERROR ('Customer cannot rate a product they have not purchased.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Calculate the order discount and validate it
CREATE TRIGGER trg_CheckCouponDiscount
ON Orders
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted o
        JOIN Coupons c ON o.coupon_code = c.coupon_code
        CROSS APPLY (
            SELECT CASE 
                WHEN c.type = 'Percent' THEN o.products_cost * c.value / 100.0
                WHEN c.type = 'Value' THEN c.value
            END AS calculated_discount
        ) d
        WHERE 
            (c.expire_date IS NOT NULL AND o.order_date > c.expire_date)							-- Expired
			OR c.remaining_usage = 0																-- No Remaining Usage
            OR d.calculated_discount < c.min_discount OR d.calculated_discount > c.max_discount		-- Out of Discount Range
	    )
    BEGIN
        RAISERROR('Invalid coupon: expired or discount out of allowed range.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE o
    SET applied_discount =
        CASE 
            WHEN o.coupon_code IS NULL THEN 0
            WHEN c.type = 'Percent' THEN o.products_cost * c.value / 100.0
            WHEN c.type = 'Value' THEN c.value
        END
    FROM Orders o
    JOIN inserted i ON o.order_id = i.order_id
    LEFT JOIN Coupons c ON o.coupon_code = c.coupon_code;
END;
GO