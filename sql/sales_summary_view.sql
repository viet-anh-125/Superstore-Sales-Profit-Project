USE SuperstoreDB;
GO
-- Q1. Doanh thu & lợi nhuận theo Region
SELECT
    Region,
    COUNT(DISTINCT OrderID)                              AS SoDonHang,
    SUM(Sales)                                           AS DoanhThu,
    SUM(Profit)                                          AS LoiNhuan,
    CAST(SUM(Profit) / NULLIF(SUM(Sales),0) AS decimal(9,4)) AS BienLoiNhuan,
    AVG(Sales)                                           AS GiaTriTB
FROM dbo.Sales
GROUP BY Region
ORDER BY DoanhThu DESC;
-- Q2. Theo Category + Sub-Category (GROUP BY nhiều cột)
SELECT
    Category, SubCategory,
    SUM(Sales)  AS DoanhThu,
    SUM(Profit) AS LoiNhuan,
    CAST(SUM(Profit) / NULLIF(SUM(Sales),0) AS decimal(9,4)) AS BienLoiNhuan
FROM dbo.Sales
GROUP BY Category, SubCategory
ORDER BY Category, LoiNhuan ASC;
-- Phát hiện: Tables, Bookcases, Supplies đều ÂM lợi nhuận

-- Q3. Doanh thu theo tháng (chuỗi thời gian)
SELECT
    YEAR(OrderDate)  AS Nam,
    MONTH(OrderDate) AS Thang,
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS DauThang,
    SUM(Sales)  AS DoanhThu,
    SUM(Profit) AS LoiNhuan
FROM dbo.Sales
GROUP BY YEAR(OrderDate), MONTH(OrderDate),
         DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
ORDER BY Nam, Thang;

-- Q4. HAVING: chỉ lấy bang có doanh thu > 50.000 nhưng đang lỗ
SELECT
    StateName,
    SUM(Sales)  AS DoanhThu,
    SUM(Profit) AS LoiNhuan
FROM dbo.Sales
GROUP BY StateName
HAVING SUM(Sales) > 50000 AND SUM(Profit) < 0
ORDER BY LoiNhuan ASC;

-- Q5. Top 10 sản phẩm theo doanh thu
SELECT TOP (10)
    ProductName,
    SUM(Sales)     AS DoanhThu,
    SUM(Quantity)  AS SoLuong,
    SUM(Profit)    AS LoiNhuan
FROM dbo.Sales
GROUP BY ProductName
ORDER BY DoanhThu DESC;

-- Q6. Ảnh hưởng của chiết khấu lên lợi nhuận (CASE + GROUP BY)
SELECT
    CASE
        WHEN Discount = 0                     THEN '0%'
        WHEN Discount <= 0.20                 THEN '1-20%'
        WHEN Discount <= 0.40                 THEN '21-40%'
        ELSE '>40%'
    END AS NhomChietKhau,
    COUNT(*)    AS SoDong,
    SUM(Sales)  AS DoanhThu,
    SUM(Profit) AS LoiNhuan
FROM dbo.Sales
GROUP BY CASE
        WHEN Discount = 0     THEN '0%'
        WHEN Discount <= 0.20 THEN '1-20%'
        WHEN Discount <= 0.40 THEN '21-40%'
        ELSE '>40%'
    END
ORDER BY NhomChietKhau;

USE SuperstoreDB;
GO

CREATE OR ALTER VIEW dbo.sales_summary_v AS
SELECT
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS MonthStart,
    YEAR(OrderDate)   AS OrderYear,
    MONTH(OrderDate)  AS OrderMonth,
    Region,
    StateName,
    Segment,
    Category,
    SubCategory,
    COUNT(DISTINCT OrderID) AS TotalOrders,
    SUM(Quantity)           AS TotalQuantity,
    SUM(Sales)              AS TotalSales,
    SUM(Profit)             AS TotalProfit,
    CAST(SUM(Profit) / NULLIF(SUM(Sales), 0) AS decimal(9,4)) AS ProfitMargin
FROM dbo.Sales
GROUP BY
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1),
    YEAR(OrderDate), MONTH(OrderDate),
    Region, StateName, Segment, Category, SubCategory;
GO

-- Kiểm tra
SELECT TOP (20) * FROM dbo.sales_summary_v ORDER BY MonthStart;

-- Đối chiếu tổng: phải khớp tuyệt đối với bảng gốc
SELECT SUM(TotalSales) AS View_Sales, SUM(TotalProfit) AS View_Profit FROM dbo.sales_summary_v;
SELECT SUM(Sales)      AS Raw_Sales,  SUM(Profit)      AS Raw_Profit  FROM dbo.Sales;
-- ~2,297,200.86  và  ~286,397.02