--tạo bảng tạm
CREATE DATABASE SuperstoreDB;
GO
USE SuperstoreDB;
GO

-- xem tên, kiểu dữ liệu
USE SuperstoreDB;
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Superstore_raw'
ORDER BY ORDINAL_POSITION;

-- kiểm tra dữ liệu ngày tháng
USE SuperstoreDB;
SELECT
    MAX(CAST(SUBSTRING([Order_Date],
        CHARINDEX('/', [Order_Date]) + 1,
        CHARINDEX('/', [Order_Date], CHARINDEX('/', [Order_Date]) + 1)
          - CHARINDEX('/', [Order_Date]) - 1) AS int)) AS MaxPhanGiua
FROM dbo.Superstore_raw;
-- Kết quả 31 => phần giữa là NGÀY => dạng M/D/YYYY => dùng style 101 ở date

--Tạo bảng sạch theo kiểu chuẩn
USE SuperstoreDB;
GO
IF OBJECT_ID('dbo.Sales', 'U') IS NOT NULL DROP TABLE dbo.Sales;
GO
SELECT
    CAST([Row_ID]        AS int)             AS RowID,
    CAST([Order_ID]      AS varchar(20))     AS OrderID,
    CONVERT(date, [Order_Date], 101)         AS OrderDate,
    CONVERT(date, [Ship_Date],  101)         AS ShipDate,
    CAST([Ship_Mode]     AS varchar(30))     AS ShipMode,
    CAST([Customer_ID]   AS varchar(20))     AS CustomerID,
    CAST([Customer_Name] AS nvarchar(100))   AS CustomerName,
    CAST(Segment         AS varchar(30))     AS Segment,
    CAST(Country         AS nvarchar(60))    AS Country,
    CAST(City            AS nvarchar(60))    AS City,
    CAST([State]         AS nvarchar(60))    AS StateName,
    CAST([Postal_Code]   AS varchar(10))     AS PostalCode,
    CAST(Region          AS varchar(20))     AS Region,
    CAST([Product_ID]    AS varchar(30))     AS ProductID,
    CAST(Category        AS varchar(40))     AS Category,
    CAST([Sub_Category]  AS varchar(40))     AS SubCategory,
    CAST([Product_Name]  AS nvarchar(255))   AS ProductName,
    CAST(Sales           AS decimal(18,4))   AS Sales,
    CAST(Quantity        AS int)             AS Quantity,
    CAST(Discount        AS decimal(9,4))    AS Discount,
    CAST(Profit          AS decimal(18,4))   AS Profit
INTO dbo.Sales
FROM dbo.Superstore_raw;
GO

--- Khóa chính và Index
USE SuperstoreDB;
GO
-- 1. Đổi cột thành NOT NULL
ALTER TABLE dbo.Sales ALTER COLUMN RowID int NOT NULL;
GO
-- 2. Thêm khóa chính
ALTER TABLE dbo.Sales ADD CONSTRAINT PK_Sales PRIMARY KEY (RowID);
GO
-- 3. Index
CREATE INDEX IX_Sales_OrderDate ON dbo.Sales(OrderDate) INCLUDE (Sales, Profit);
CREATE INDEX IX_Sales_Region    ON dbo.Sales(Region, Category);
GO


---kiểm tra và xem lại dữ liệu
-- 1. Nhìn qua 20 dòng
SELECT TOP (20) * FROM dbo.Sales;

-- 2. Kiểm tra số dòng + khoảng thời gian
SELECT COUNT(*) AS SoDong,
       MIN(OrderDate) AS NgayDau,
       MAX(OrderDate) AS NgayCuoi
FROM dbo.Sales;              -- kỳ vọng: 9994 dòng, 2014-01-03 → 2017-12-30

-- 3. Các giá trị phân loại
SELECT DISTINCT Region   FROM dbo.Sales;   -- 4 vùng
SELECT DISTINCT Category FROM dbo.Sales;   -- 3 nhóm
SELECT DISTINCT Segment  FROM dbo.Sales;   -- 3 phân khúc

-- 4. Đếm NULL ở từng cột quan trọng
SELECT
    SUM(CASE WHEN OrderDate  IS NULL THEN 1 ELSE 0 END) AS Null_OrderDate,
    SUM(CASE WHEN PostalCode IS NULL THEN 1 ELSE 0 END) AS Null_PostalCode,
    SUM(CASE WHEN Sales      IS NULL THEN 1 ELSE 0 END) AS Null_Sales
FROM dbo.Sales;

-- 5. WHERE: các giao dịch lỗ nặng
SELECT TOP (20) OrderID, ProductName, Sales, Discount, Profit
FROM dbo.Sales
WHERE Profit < 0
ORDER BY Profit ASC;

-- 6. WHERE nhiều điều kiện
SELECT OrderID, OrderDate, City, Sales, Profit
FROM dbo.Sales
WHERE Region = 'West'
  AND Category = 'Technology'
  AND OrderDate >= '2017-01-01'
ORDER BY Sales DESC;

-- 7. Kiểm tra logic nghiệp vụ: có đơn nào giao trước ngày đặt không?
SELECT COUNT(*) AS DonLoiNgay
FROM dbo.Sales
WHERE ShipDate < OrderDate;   -- kỳ vọng: 0