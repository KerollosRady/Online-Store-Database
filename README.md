# 🛒 Online Store Database

A complete relational database design and SQL implementation for an online store system. This project provides a hands-on experience with database creation, querying, and reporting. It includes the database schema, stored procedures, and sample queries — all derived from a set of business requirements, making it ideal for learning SQL and relational database concepts in practice.

---

## 📁 Repository Structure

* **/Design** – Contains the ERD and relational schema diagrams (created in `drawio`), along with exported images.
* **/SQL** – SQL scripts to create tables, insert sample data, define stored procedures, and run sample queries.
* **`Business Requirements.pdf`** – Original document outlining the functional needs the database satisfies.

---

## 🗄️ Database Design

The `Design/` directory contains the ERD and relational schema diagrams.

### Entity-Relationship Diagram (ERD)

![ERD Diagram](Design/Online%20Store%20EERD.png)

### Relational Schema

![Schema Diagram](Design/Online%20Store%20Schema.png)

---

## 🛠️ SQL Implementation

The `SQL/` directory contains all scripts to build and interact with the database.

* **`Database Creation.sql`** – Defines tables, constraints, primary/foreign keys, triggers, and validations.
* **`Reports Procedures.sql`** – Contains stored procedures:

  * `sp_TotalSales` – Shows total sales for a given date range.
  * `sp_BestSellingProducts` – Lists top-selling products for a given date range.
  * `sp_TopActiveCustomers` – Shows customers with the highest purchase activity for a given date range.
  * `sp_LowStockProducts` – Shows products with the lowest stock levels.
* **`Inserting Data.sql`** – Populates tables with sample data for testing and exploration.
* **`Sample Queries.sql`** – Example queries to explore the database and test reports.

---

## 🧪 Sample Queries and Outputs

### All orders for a specific customer

```sql
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
```

![Sample Query 1](https://github.com/user-attachments/assets/d120a202-b5e1-437e-bdb3-694b6c8fff09)

---

### Total Sales Summary Between Two Dates

```sql
EXEC sp_TotalSales '2026-01-01 08:00', '2026-02-20 18:30';
```

![Total Sales](https://github.com/user-attachments/assets/a0bcbed5-b511-44a6-944c-2bff6643ca0d)

---

### Top 2 Best-Selling Products Between Two Dates

```sql
EXEC sp_BestSellingProducts '2026-01-01 08:00', '2026-02-20 18:30', 2;
```

![Best Selling Products](https://github.com/user-attachments/assets/486d089a-bf50-45c6-8e15-586918862193)

---

### Top 2 Customers with Highest Purchase Activity Between Two Dates

```sql
EXEC sp_TopActiveCustomers '2026-01-01 08:00', '2026-02-20 18:30', 2;
```

![Top Customers](https://github.com/user-attachments/assets/4e6b931b-61aa-4b97-b1f1-05eb99788fec)

---

### 10 Products with the Lowest Stock Levels 

```sql
EXEC sp_LowStockProducts 10;
```

![Low Stock Products](https://github.com/user-attachments/assets/df582776-f2dd-4b0f-8314-a399aa20e307)

*(Note: the sample data only contains 4 products, so only 4 are shown here 😄)*

---

