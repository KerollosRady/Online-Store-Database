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
    remaining_usage INT NOT NULL DEFAULT 0 CHECK (remaining_usage >= 0),
    min_discount DECIMAL(10,2) NOT NULL CHECK (min_discount >= 0),
    max_discount DECIMAL(10,2) NOT NULL,
    CONSTRAINT CK_Coupons_Max_Gte_Min CHECK (max_discount >= min_discount)
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
    shipping_fees DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (shipping_fees >= 0),
    payment_reference VARCHAR(50) NULL,
    payment_method VARCHAR(20) NULL,
    pay_date DATETIME NULL,
    customer_id INT NOT NULL REFERENCES Customers(customer_id)
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

CREATE TABLE OrderCoupons (
    order_id INT NOT NULL REFERENCES Orders(order_id),
    coupon_code NVARCHAR(20) NOT NULL REFERENCES Coupons(coupon_code),
    PRIMARY KEY (order_id, coupon_code)
);
GO

