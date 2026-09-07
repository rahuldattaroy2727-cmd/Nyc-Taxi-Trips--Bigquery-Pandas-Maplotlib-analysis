<div align="center">

# 🚕 NYC Yellow Taxi 2021 — End-to-End EDA Project

[![BigQuery](https://img.shields.io/badge/Google_BigQuery-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/bigquery)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![Pandas](https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white)](https://pandas.pydata.org)
[![Seaborn](https://img.shields.io/badge/Seaborn-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://seaborn.pydata.org)
[![Matplotlib](https://img.shields.io/badge/Matplotlib-11557c?style=for-the-badge&logo=python&logoColor=white)](https://matplotlib.org)
[![Colab](https://img.shields.io/badge/Google_Colab-F9AB00?style=for-the-badge&logo=google-colab&logoColor=white)](https://colab.research.google.com)

---

### 📊 28.1 Million Trips &nbsp;|&nbsp; 30 Business Questions &nbsp;|&nbsp; BigQuery + Python Pipeline

---

</div>

## 📌 Project Overview

This project performs a comprehensive **Exploratory Data Analysis (EDA)** of the **NYC Yellow Taxi 2021** dataset — one of the largest publicly available transportation datasets in the world, containing over **30.9 million raw trip records**.

The analysis follows a complete modern data analytics workflow:

```
BigQuery Public Dataset
        ↓
  Data Cleaning & Feature Engineering (SQL + Python)
        ↓
  Cleaned Table → BigQuery (28.1M rows)
        ↓
  EDA — 30 Business Questions (BigQuery SQL)
        ↓
  Random Sample → Pandas (100,000 rows)
        ↓
  Visualizations (Matplotlib + Seaborn)
        ↓
  Insights & Findings
```

---

## 📂 Project Structure

```
NYC-Taxi-2021-EDA/
│
├── 📓 Initial_exploration_and_cleaning.ipynb     # Pandas EDA on raw sample + cleaning logic
├── 📓 Nyc_Taxi_sample_visualisation_analysis.ipynb  # Visualizations on 100k cleaned sample
│
├── 🗄️ Cleaned_nyc_taxi_table_generator.sql      # BigQuery cleaning script
├── 🗄️ EDA_nyc_taxi_query.sql                    # 30 business questions in BigQuery SQL
│
├── 📋 Data_Cleaning_Methodology.md              # Detailed cleaning decisions and rationale
├── 📊 Nyc_taxi_dataset_sample_100_000_rows.csv  # 100k row sample used for Python analysis
│
└── README.md
```

---

## 🗄️ Dataset

| Property | Detail |
|----------|--------|
| **Source** | `bigquery-public-data.biglake-public-nyc-taxi-iceberg.public_data.nyc_taxicab_2021` |
| **Original rows** | 30,904,427 |
| **Cleaned rows** | 28,101,653 |
| **Retention rate** | 90.93% |
| **Python sample** | 100,000 rows (random `ORDER BY RAND()`) |
| **Key columns** | pickup/dropoff datetime, trip distance, fare amount, tip, total amount, passenger count, payment type, pickup/dropoff location |

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|------|---------|
| **Google BigQuery** | Cloud data warehouse — cleaning, storage, SQL EDA |
| **Google Colab** | Python environment connected to BigQuery |
| **Python (Pandas)** | Data manipulation and sample analysis |
| **Matplotlib** | Data visualization |
| **Seaborn** | Statistical visualizations |
| **SQL (BigQuery dialect)** | 30 business questions across 6 analytical sections |

---

## 🧹 Data Cleaning Summary

Full methodology documented in [`Data_Cleaning_Methodology.md`](Data_Cleaning_Methodology.md)

| Filter | Condition | Reason |
|--------|-----------|--------|
| Year | = 2021 | Raw data contained years 2003–2098 |
| Trip duration | 1 – 300 minutes | Remove cancelled trips and anomalous long journeys |
| Trip distance | 0 – 100 miles | Remove impossible and suspicious values |
| Fare amount | > 0 | Remove unpaid/invalid transactions |
| Total amount | > 0 | Remove voided transactions |
| Extra charges | >= 0 | Cannot be negative |
| Passenger count | 1–5 or NULL | Remove invalid counts, retain NULLs |

### 🔍 Notable Discovery During EDA

> A significant correlation discrepancy was identified during analysis:
> - **SQL** `CORR(trip_distance, fare_amount)` = **0.064** (full 28M rows)
> - **Pandas** `.corr()` on 100k sample = **0.93**
>
> Investigation revealed **6 extreme fare outliers** (including a fare of **$818,283**) that were collapsing the SQL correlation toward zero across millions of rows. After applying `fare_amount <= 600`, the SQL correlation jumped from **0.064 → 0.935**, confirming the expected strong positive relationship between distance and fare.
>
> This cross-validation between SQL and Python is a key analytical finding of this project.

---

## 📊 Analysis Sections

### 1️⃣ Overall Trip Analysis
- Total completed trips: **28.1 million**
- Total revenue generated: **~$563.9 million**
- Average fare: **$13.97** | Median fare: **$10** *(right-skewed distribution)*
- Average trip distance: **3.38 miles** | Median: **2 miles**
- Average trip duration: **14.19 minutes** | Median: **11 minutes**

### 2️⃣ Time & Demand Analysis
- **November** had the highest trip volume | **January** had the lowest
- **November** also generated the highest revenue: **$67.1 million**
- **December** had the highest average fare: **$14.79**
- Peak demand hour: **18:00** — consistent with end-of-office commute
- Lowest demand: **04:00** — early morning quiet period
- **Peak demand does NOT correspond to higher fares** — early morning 5AM had the highest average fare (~$21) due to long airport trips, not volume

### 3️⃣ Fare & Revenue Analysis
- Revenue per mile: **$5.93**
- Tips contribute **12.05%** of total revenue
- Trip category generating highest revenue per trip: **51–60 mile range** (~$155.18 avg)
- As fare increases, tip amount increases — but **tip percentage decreases** at higher fares
- Cash trips show almost **zero recorded tips** — not because cash passengers tip less, but because cash tips are not captured in the system

### 4️⃣ Trip Characteristics
- **Medium trips** (2–10 miles) are most common: **57.2%**
- **Short trips** (<2 miles): **36.3%**
- **Long trips** (>10 miles): only **6.4%**
- Trip distance vs fare correlation: **r = 0.935** (after outlier treatment)
- Trip distance vs duration correlation: **r = 0.77–0.78** (consistent across SQL and Python)

### 5️⃣ Payment & Passenger Analysis
- **Credit card** dominates with **20.75 million transactions** vs **5.88 million cash**
- Credit card trips average: **$20.21** | Cash trips: **$16.83**
- **Solo riders dominate** — 1-passenger trips account for over **70%** of volume in sample
- No clear linear relationship between passenger count and average fare

### 6️⃣ Location Analysis
- **Upper East Side South** — highest pickup demand (~1.40 million trips)
- **JFK Airport** — highest total revenue despite lower trip count — airport trips are longer and more valuable
- Several high-demand Manhattan zones generate **below-average revenue per trip** — their contribution is volume-driven, not value-driven
- **Most popular route:** Upper East Side South ↔ Upper East Side North — strong intra-Manhattan demand
- **Busiest routes are not necessarily the most profitable** — airport routes generate disproportionately high revenue per trip

---

## 🔑 Key Insights

> 💡 **November drives volume, December drives value** — November had the most trips but December had the highest average fare, suggesting different demand dynamics across holiday months.

> 💡 **Early morning trips are the most valuable per ride** — 5AM had the highest average fare (~$21), driven by long airport journeys, not commuter volume.

> 💡 **JFK Airport outperforms on revenue despite fewer trips** — airport-originating trips generate disproportionately high revenue compared to high-volume Manhattan zones.

> 💡 **Credit card dominates but cash tips are invisible** — recorded tip data heavily favors credit card ($3.12 avg) vs cash ($0 recorded), but this reflects data capture limitations, not actual tipping behavior.

> 💡 **Outlier detection changed the entire correlation story** — cross-validating SQL and Python results revealed 6 extreme fare records that were masking a true 0.935 correlation. This demonstrates the importance of multi-tool validation in data analysis.

---

## ▶️ How to Reproduce

### BigQuery (SQL Analysis)
1. Access [Google BigQuery](https://console.cloud.google.com/bigquery)
2. The source dataset is publicly available at:
   ```
   bigquery-public-data.biglake-public-nyc-taxi-iceberg.public_data.nyc_taxicab_2021
   ```
3. Run `Cleaned_nyc_taxi_table_generator.sql` to create the cleaned table
4. Run queries from `EDA_nyc_taxi_query.sql` — each query is self-contained and independent

### Python (Colab Analysis)
1. Open `Initial_exploration_and_cleaning.ipynb` or `Nyc_Taxi_sample_visualisation_analysis.ipynb` in Google Colab
2. Authenticate with your Google account
3. Install required libraries:
   ```bash
   pip install google-cloud-bigquery pandas db-dtypes matplotlib seaborn
   ```
4. Update the `project_id` variable to your own GCP project
5. Run all cells

> **Note:** The 100k sample CSV (`Nyc_taxi_dataset_sample_100_000_rows.csv`) is included for offline analysis without BigQuery access.

---

## ⚠️ Limitations

- Revenue figures are based on `total_amount` from trip records — not verified against actual payment processor data
- Cash tips are not recorded in the dataset — tip analysis reflects only electronic payment tips
- The Python visualizations are based on a **100,000 row random sample** — percentages and counts represent the sample, not the full 28.1M dataset
- The 2021 dataset covers the full calendar year but some months may reflect COVID-19 related demand variations

---

## 📊 Visualizations

### 🕐 Trips by Hour
![Trips by Hour](Visual_graph_screenshots/trips_by_hour.png)
> Peak demand at **18:00**, lowest at **04:00**. Clear office commute pattern visible.

---

### 📅 Trips by Month
![Trips by Month](Visual_graph_screenshots/trips_by_month.png)
> January and February had the lowest demand. October and November peaked at ~11,250 trips in the sample.

---

### 🌡️ Heatmap — Hour × Day of Week
![Heatmap Hour vs Day](Visual_graph_screenshots/heatmap_hour_day.png)
> Friday and Thursday show the darkest cells during evening hours — confirming end-of-week peak demand. Early morning hours (0–5) are consistently light across all days.

---

### 💰 Average Fare by Hour
![Average Fare by Hour](Visual_graph_screenshots/avg_fare_by_hour.png)
> **5AM spike (~$21)** driven by long airport trips — not commuter volume. Business hours (8AM–1PM) show the lowest average fares (~$13).

---

### 📏 Trip Distance vs Fare Amount *(r = 0.935)*
![Distance vs Fare](Visual_graph_screenshots/distance_vs_fare.png)
> Strong positive correlation confirmed after outlier treatment. The orange regression line shows the clear linear relationship.

---

### ⏱️ Trip Distance vs Duration *(r = 0.77)*
![Distance vs Duration](Visual_graph_screenshots/distance_vs_duration.png)
> Strong positive correlation — longer trips naturally take more time. Consistent result across both SQL (0.78) and Python (0.77).

---

### 📊 Trip Duration Distribution
![Trip Duration Distribution](Visual_graph_screenshots/trip_duration_distribution.png)
> Heavily right-skewed — majority of trips fall between 1–20 minutes. Long tail confirms presence of occasional long-distance journeys.

---

### 🚗 Average Fare by Trip Duration Category
![Fare by Duration Category](Visual_graph_screenshots/fare_by_duration_category.png)
> Long trips (~$42) generate significantly higher average fares than medium (~$15) and short (~$7) trips.

---

### 💳 Payment Type Distribution
![Payment Type Distribution](Visual_graph_screenshots/payment_type_distribution.png)
> **Credit card dominates** with 73,668 transactions vs 21,053 cash in the 100k sample — consistent with full dataset ratio.

---

### 👥 Passenger Count Distribution
![Passenger Count Distribution](Visual_graph_screenshots/passenger_count_distribution.png)
> Solo riders (~72,000) overwhelmingly dominate — NYC taxis are primarily used for individual commuting rather than group travel.

---

## 📁 Related Files

- 📋 [Data Cleaning Methodology](Data_Cleaning_Methodology.md) — detailed explanation of every cleaning decision
- 🗄️ [BigQuery EDA Queries](EDA_nyc_taxi_query.sql) — all 30 SQL business questions with insights
- 📓 [Python Visualizations Notebook](Nyc_Taxi_sample_visualisation_analysis.ipynb) — open in Google Colab

---

<div align="center">

## 👤 Author

**Rahul Datta Roy**

Aspiring Data Analyst | SQL | Python | Power BI | BigQuery

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/rahul-datta-roy-0340a7209)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/rahuldattaroy2727-cmd)

---

*⭐ If you found this project useful, consider giving it a star!*

</div>

