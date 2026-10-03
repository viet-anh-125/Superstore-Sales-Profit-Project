# Superstore Sales & Profit Dashboard (SQL Server + Power BI)

Dashboard phân tích doanh thu bán lẻ: nạp dữ liệu thô vào **SQL Server**, làm sạch và tổng hợp bằng **T-SQL**, rồi trực quan hóa doanh thu/lợi nhuận theo khu vực, ngành hàng và thời gian bằng **Power BI**.

### Trang 1 — Overview
![Overview](screenshots/dashboard_overview.png)

### Trang 2 — Trends & Regions
![Trends & Regions](screenshots/dashboard_trends.png)

## Bài toán

Một chuỗi bán lẻ muốn biết: **doanh thu tăng thì lợi nhuận có tăng theo không, và nhóm nào đang làm mất lợi nhuận?** Dự án trả lời bằng bộ dữ liệu Superstore (9.994 dòng, 5.009 đơn hàng, 2014–2017).

## Công nghệ

| Lớp | Công cụ |
|---|---|
| Lưu trữ & xử lý | SQL Server, T-SQL, SSMS |
| Trực quan hóa | Power BI Desktop, DAX |
| Báo cáo dự phòng | Excel (PivotTable, PivotChart, Slicer) |

## Quy trình

```
superstore.csv ─► Superstore_raw ─► Sales ─► sales_summary_v ─┬─► Power BI (dashboard)
 (Kaggle)        (nvarchar, thô)   (ép kiểu,  (GROUP BY theo  └─► CSV ─► Excel (PivotTable)
                                    khóa, index) tháng/vùng/...)
```

1. **Nạp dữ liệu thô:** import CSV bằng Import Flat File Wizard, để mọi cột là `nvarchar` để không lỗi cả lô vì vài dòng bẩn.
2. **Làm sạch & ép kiểu:** tạo bảng `Sales` với kiểu dữ liệu chuẩn, khóa chính `RowID` và hai index. Ngày trong file có dạng `M/D/YYYY` nên dùng `CONVERT(date, ..., 101)`. Dạng này được xác định bằng cách kiểm tra phần giữa của chuỗi ngày có đạt giá trị 31 hay không, chứ không đoán.
3. **Khám phá dữ liệu:** kiểm tra số dòng, khoảng thời gian, NULL, giao dịch lỗ và logic nghiệp vụ (không có đơn nào giao trước ngày đặt).
4. **Tổng hợp:** 6 truy vấn `GROUP BY` / `HAVING` / `CASE`, rồi đóng gói thành view `sales_summary_v`, đối chiếu tổng với bảng gốc cho khớp tuyệt đối.
5. **Excel:** xuất view ra CSV, dựng PivotTable, PivotChart và Slicer làm bản dự phòng.
6. **Power BI:** nối thẳng SQL Server (chế độ Import), tạo bảng `DimDate` bằng DAX, quan hệ 1–nhiều với `Sales[OrderDate]`, viết measure và dựng dashboard 2 trang: *Overview* (KPI, doanh thu theo Category, lợi nhuận theo SubCategory, lợi nhuận theo mức chiết khấu) và *Trends & Regions* (xu hướng theo tháng, đơn hàng theo vùng, bảng hiệu suất theo năm). Slicer Year, Region, Category lọc toàn bộ các visual.

## Cấu trúc repo

```
├── README.md
├── data/
│   ├── superstore.csv            # dữ liệu gốc từ Kaggle
│   └── sales_summary.csv         # kết quả export từ sales_summary_v
├── sql/
│   ├── import_data.sql           # tạo DB, làm sạch, tạo bảng Sales, kiểm tra dữ liệu
│   ├── sales_summary_view.sql    # 6 truy vấn tổng hợp + view sales_summary_v
│   └── export_query.sql          # truy vấn dùng để xuất CSV (đổi tên từ SQLQuery7.sql)
├── powerbi/
│   └── Superstore_Dashboard.pbix
├── excel/
│   └── superstore_report.xlsx
└── screenshots/
    ├── dashboard_overview.png
    └── dashboard_trends.png
```

## Measure DAX chính

```dax
Total Sales     = SUM ( Sales[Sales] )
Total Profit    = SUM ( Sales[Profit] )
Profit Margin   = DIVIDE ( [Total Profit], [Total Sales] )
Total Orders    = DISTINCTCOUNT ( Sales[OrderID] )
Sales LY        = CALCULATE ( [Total Sales], DATEADD ( DimDate[Date], -1, YEAR ) )
Sales YoY %     = DIVIDE ( [Total Sales] - [Sales LY], [Sales LY] )
```

`Total Orders` dùng `DISTINCTCOUNT` trên bảng `Sales` thay vì cộng từ view, vì một đơn hàng có thể thuộc nhiều Category và sẽ bị đếm trùng nếu cộng dồn.

## Kết quả chính

| Chỉ số | Giá trị |
|---|---|
| Tổng doanh thu | $2.297.201 |
| Tổng lợi nhuận | $286.397 |
| Biên lợi nhuận | 12,47% |
| Số đơn hàng | 5.009 |

## Insight

**1. Chiết khấu trên 20% làm mất lợi nhuận** (biểu đồ *Profit by Discount Band* ở trang Overview). Nhóm không chiết khấu có biên lợi nhuận khoảng 29,5%, nhóm 1–20% còn khoảng 11,9%, nhóm 21–40% âm 15,3% và nhóm trên 40% âm 77,4%. Hơn 1.390 dòng bán (khoảng 14% tổng số dòng) rơi vào hai nhóm lỗ này.

| Nhóm chiết khấu | Số dòng | Doanh thu | Lợi nhuận | Biên |
|---|---|---|---|---|
| 0% | 4.798 | $1.087.908 | $320.988 | 29,5% |
| 1–20% | 3.803 | $846.522 | $100.785 | 11,9% |
| 21–40% | 460 | $234.138 | -$35.817 | -15,3% |
| >40% | 933 | $128.632 | -$99.559 | -77,4% |

**2. Ba Sub-Category lỗ ròng dù có doanh thu.** *Tables* lỗ $17.725 trên doanh thu $206.966, *Bookcases* lỗ $3.473 và *Supplies* lỗ $1.189. Tables đáng chú ý nhất vì doanh thu lớn nhưng vẫn lỗ.

**3. Doanh thu có tính mùa vụ rõ rệt.** Quý 4 chiếm khoảng 38% doanh thu cả giai đoạn, riêng tháng 9, 11 và 12 chiếm khoảng 43%.

**4. Vùng West dẫn đầu, Central yếu nhất.** West đạt $725K doanh thu và $108K lợi nhuận. Central chỉ có biên khoảng 7,9%, thấp nhất trong 4 vùng. Ở cấp bang, Texas (-$25.7K), Ohio (-$17.0K) và Pennsylvania (-$15.6K) lỗ nhiều nhất.

**Đề xuất:** đặt trần chiết khấu khoảng 20% (hoặc xét riêng cho Tables, Bookcases) và rà soát lại chính sách giá ở các bang đang lỗ.

## Cách chạy lại

1. Tải `superstore.csv` từ [Kaggle](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final).
2. Trong SSMS: tạo database `SuperstoreDB`, rồi chuột phải → **Tasks → Import Flat File** và nạp file vào bảng `Superstore_raw` (đặt mọi cột là `nvarchar(255)`).
3. Chạy `sql/import_data.sql` rồi `sql/sales_summary_view.sql`.
4. Mở `powerbi/Superstore_Dashboard.pbix`, vào **Transform data → Data source settings** và đổi server thành SQL Server của bạn, sau đó **Refresh**.

## Lưu ý kỹ thuật

- Wizard import đổi tên cột có khoảng trắng và dấu gạch thành gạch dưới (`Order Date` → `Order_Date`), nên script làm sạch dùng tên gạch dưới. Nếu wizard của bạn đặt tên khác, kiểm tra bằng `INFORMATION_SCHEMA.COLUMNS` và sửa lại cho khớp.
- Lệnh `ProfitMargin` trong view không thể cộng hay lấy trung bình. Trong Power BI luôn dùng measure `Profit Margin` thay vì cột này.
- Export Wizard của SSMS cần Integration Services. Với bản SQL Server Evaluation đã hết hạn, dùng **Save Results As** để xuất CSV.

## Nguồn dữ liệu

[Superstore Dataset Final — Kaggle (vivek468)](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final). Dữ liệu công khai, dùng cho mục đích học tập.
