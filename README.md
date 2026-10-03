# Superstore Sales & Profit Dashboard (SQL Server + Power BI)

An end-to-end retail analytics project: raw CSV data is loaded into **SQL Server**, cleaned and aggregated with **T-SQL**, and visualized in a two-page **Power BI** dashboard showing sales and profit by region, category, discount level and time.

*Vietnamese version: [README_vi.md](README_vi.md)*

### Page 1: Overview
![Overview](screenshots/dashboard_overview.png)

### Page 2: Trends & Regions
![Trends & Regions](screenshots/dashboard_trends.png)

## Business question

**Does growing revenue also grow profit, and which segments are quietly losing money?** The project answers this using the Superstore dataset: 9,994 order lines, 5,009 orders, January 2014 to December 2017.

## Tech stack

| Layer | Tools |
|---|---|
| Storage & processing | SQL Server, T-SQL, SSMS |
| Visualization | Power BI Desktop, DAX |
| Backup reporting | Excel (PivotTable, PivotChart, Slicers) |

## Workflow

```
superstore.csv ─► Superstore_raw ─► Sales ─► sales_summary_v ─┬─► Power BI (dashboard)
 (Kaggle)         (all nvarchar)   (typed,    (GROUP BY month/ └─► CSV ─► Excel (PivotTable)
                                    keyed,     region/category)
                                    indexed)
```

1. **Load raw data.** The CSV is imported with the Import Flat File Wizard, with every column set to `nvarchar` so that a few dirty rows cannot fail the whole load.
2. **Clean and cast.** The `Sales` table is built with proper data types, a primary key on `RowID` and two indexes. Dates in the file use `M/D/YYYY`, so they are converted with style 101. The format was verified rather than guessed: the middle part of the date string reaches 31, so it must be the day.
3. **Explore.** Checks cover row count, date range, NULLs, loss-making transactions and business logic (no order ships before it is placed).
4. **Aggregate.** Six `GROUP BY` / `HAVING` / `CASE` queries, then a reusable view `sales_summary_v`, whose totals are reconciled against the base table.
5. **Excel backup.** The view is exported to CSV and analyzed with PivotTables, PivotCharts and slicers.
6. **Power BI.** Connected directly to SQL Server in Import mode. A `DimDate` table built in DAX has a one-to-many relationship to `Sales[OrderDate]`. Slicers for Year, Region and Category filter every visual on both pages.

## Dashboard contents

| Page | Visuals |
|---|---|
| Overview | KPI cards (Sales, Profit, Orders, Margin), Sales by Category, Profit by Discount Band, Profit by SubCategory (losses in red) |
| Trends & Regions | Monthly Sales & Profit line chart (48 months), Orders by Region donut, Performance by Year table |

## Key DAX measures

```dax
Total Sales     = SUM ( Sales[Sales] )
Total Profit    = SUM ( Sales[Profit] )
Profit Margin   = DIVIDE ( [Total Profit], [Total Sales] )
Total Orders    = DISTINCTCOUNT ( Sales[OrderID] )
Sales LY        = CALCULATE ( [Total Sales], DATEADD ( DimDate[Date], -1, YEAR ) )
Sales YoY %     = DIVIDE ( [Total Sales] - [Sales LY], [Sales LY] )

Discount Band =
SWITCH (
    TRUE (),
    Sales[Discount] = 0,    "0%",
    Sales[Discount] <= 0.2, "1-20%",
    Sales[Discount] <= 0.4, "21-40%",
    ">40%"
)
```

`Total Orders` uses `DISTINCTCOUNT` on the `Sales` table instead of summing the view, because an order can span several categories and would be double-counted.

## Headline numbers

| Metric | Value |
|---|---|
| Total sales | $2,297,201 |
| Total profit | $286,397 |
| Profit margin | 12.47% |
| Orders | 5,009 |

## Insights

**1. Discounts above 20% destroy profit.** Lines with no discount earn a 29.5% margin, the 1-20% band earns 11.9%, the 21-40% band loses 15.3% and the band above 40% loses 77.4%. About 1,390 order lines, roughly 14% of the total, fall into the two loss-making bands.

| Discount band | Order lines | Sales | Profit | Margin |
|---|---|---|---|---|
| 0% | 4,798 | $1,087,908 | $320,988 | 29.5% |
| 1-20% | 3,803 | $846,522 | $100,785 | 11.9% |
| 21-40% | 460 | $234,138 | -$35,817 | -15.3% |
| >40% | 933 | $128,632 | -$99,559 | -77.4% |

**2. Three sub-categories lose money despite healthy sales.** *Tables* loses $17,725 on $206,966 of sales, *Bookcases* loses $3,473 and *Supplies* loses $1,189. Tables is the most striking: it is a large revenue line that still destroys profit.

**3. Sales are strongly seasonal.** Q4 accounts for about 38% of all revenue, and September, November and December together account for about 43%.

**4. West leads, Central lags.** West delivers $725K in sales and $108K in profit, while Central has the lowest margin of the four regions at about 7.9%. At state level, Texas (-$25.7K), Ohio (-$17.0K) and Pennsylvania (-$15.6K) lose the most.

**Recommendation:** cap discounts at around 20% (or review them separately for Tables and Bookcases) and review pricing in the loss-making states.

## Repository structure

```
├── README.md
├── README_vi.md
├── data/
│   ├── superstore.csv            # raw data from Kaggle
│   └── sales_summary.csv         # export of sales_summary_v
├── sql/
│   ├── import_data.sql           # create DB, clean, build Sales table, validation checks
│   ├── sales_summary_view.sql    # 6 aggregate queries + sales_summary_v view
│   └── export_query.sql          # query used to export the CSV
├── powerbi/
│   └── Superstore_Dashboard.pbix
├── excel/
│   └── superstore_report.xlsx
└── screenshots/
    ├── dashboard_overview.png
    └── dashboard_trends.png
```

## How to reproduce

1. Download `superstore.csv` from [Kaggle](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final).
2. In SSMS, create the database `SuperstoreDB`, then right-click it → **Tasks → Import Flat File** and load the file into a table named `Superstore_raw` (set every column to `nvarchar(255)`).
3. Run `sql/import_data.sql`, then `sql/sales_summary_view.sql`.
4. Open `powerbi/Superstore_Dashboard.pbix`, go to **Transform data → Data source settings**, point it to your SQL Server instance, and **Refresh**.

## Technical notes

- The import wizard renames columns with spaces or hyphens to use underscores (`Order Date` becomes `Order_Date`), so the cleaning script uses the underscore names. If your wizard names them differently, check `INFORMATION_SCHEMA.COLUMNS` and adjust.
- `ProfitMargin` in the view cannot be summed or averaged. In Power BI, always use the `Profit Margin` measure instead of that column.
- The SSMS Export Wizard needs Integration Services. On an expired SQL Server Evaluation edition, use **Save Results As** to export CSV instead.
- If Power BI cannot connect with an encrypted connection to a local SQL Server, untick **Use Encrypted Connection**.

## Data source

[Superstore Dataset Final on Kaggle (vivek468)](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final). Public data, used here for learning purposes.
