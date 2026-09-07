# Data Cleaning Methodology
## NYC Yellow Taxi 2021 — BigQuery EDA Project

---

## Overview

This document describes the data cleaning process applied to the **NYC Yellow Taxi 2021** dataset sourced from the BigQuery public dataset:

```
bigquery-public-data.biglake-public-nyc-taxi-iceberg.public_data.nyc_taxicab_2021
```

The cleaned table was saved as:
```
nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data
```

---

## Dataset Scale

| Metric | Value |
|--------|-------|
| Original row count | 30,904,427 |
| Cleaned row count | 28,101,653 |
| Rows removed | 2,802,774 |
| **Retention rate** | **90.93%** |

---

## Feature Engineering

Before applying cleaning filters, the following columns were derived from the raw data:

| New Column | Description |
|------------|-------------|
| `trip_duration_minutes` | Calculated as `TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE)` |
| `year` | Extracted from `pickup_datetime` using `EXTRACT(YEAR ...)` |
| `day` | Day of week extracted using `FORMAT_DATE('%A', ...)` |
| `month` | Month name extracted using `FORMAT_DATE('%B', ...)` |

---

## Cleaning Conditions Applied

### 1. Year Filter
```sql
year = 2021
```
**Reason:** The raw dataset contained records with years outside the expected 2021 range, including 2003, 2008, 2009, 2011, 2020, 2022, 2028, 2029, and 2098. These were identified as invalid timestamps and removed to ensure temporal consistency.

---

### 2. Trip Duration — Minimum
```sql
trip_duration_minutes > 1
```
**Reason:** Initial Pandas EDA on a random sample revealed that trips with duration of 1 minute or less were predominantly cancelled or incomplete trips with negligible distance travelled. These were excluded as they do not represent completed taxi journeys.

---

### 3. Trip Duration — Maximum
```sql
trip_duration_minutes < 300
```
**Reason:** Trips exceeding 5 hours (300 minutes) were identified as anomalous based on initial Pandas EDA. Such durations are inconsistent with typical NYC taxi operations and likely represent data entry errors or system anomalies.

---

### 4. Trip Distance
```sql
trip_distance > 0
AND trip_distance < 100
```
**Reason:** Zero or negative trip distances are physically impossible for completed trips. Distances above 100 miles were identified as suspicious — NYC taxi trips rarely exceed this threshold and values beyond this range likely represent data quality issues rather than legitimate long-distance journeys.

---

### 5. Fare Amount
```sql
fare_amount > 0
```
**Reason:** Fare amounts of zero or below are inconsistent with paid taxi trips. Complementary or no-charge trips were excluded as the available payment type codes do not allow reliable identification of the actual payment method for these records.

---

### 6. Total Amount
```sql
total_amount > 0
```
**Reason:** Total amount must be positive for any valid completed transaction. Zero or negative values indicate voided, reversed, or erroneous records.

---

### 7. Extra Charges
```sql
extra >= 0
```
**Reason:** Extra charges (rush hour surcharges, overnight fees) can legitimately be zero but cannot be negative.

---

### 8. Passenger Count
```sql
(passenger_count > 0 AND passenger_count <= 5) OR passenger_count IS NULL
```
**Reason:** Passenger count must be between 1 and 5 for a valid trip. Records with passenger count of 0 or above 5 were removed. NULL values were **retained** rather than removed, as dropping them would result in unnecessary data loss given that the passenger count field is not critical to the primary analyses being conducted.

---

## EDA-Specific Outlier Treatments

The following additional filters were **not applied** to the base `cleaned_taxi_data` table. They were applied selectively during EDA queries where extreme values would disproportionately affect specific financial analyses.

### Fare Amount Outlier — EDA Only
```sql
WHERE fare_amount <= 600
```
**Discovery:** During Pandas EDA, a strong positive correlation (r = 0.93) was observed between `trip_distance` and `fare_amount`. This contrasted sharply with the SQL result of r = 0.064 on the full cleaned table. Investigation revealed that **6 records** with `fare_amount > 600` — including a maximum fare of **$818,283** — were acting as extreme outliers and collapsing the correlation toward zero across 28 million rows.

After applying the `fare_amount <= 600` filter, the SQL correlation increased from **0.064 to 0.935**, consistent with the Pandas result and confirming the expected positive relationship between distance and fare.

**Applied to:** All fare-related correlation and average fare analyses.

---

### Total Amount Outlier — EDA Only
```sql
WHERE total_amount < 900
```
**Discovery:** Revenue-based analysis identified **10 records** with `total_amount > 900`, including values of $395,855 and $818,287. These were identified as extreme outliers inconsistent with legitimate taxi transactions.

**Applied to:** All total revenue, average revenue, and revenue per trip analyses.

---

## Anomalies Retained

### High Distance, Low Fare Trips
```sql
WHERE trip_distance > 50 AND fare_amount < 50
```
**Finding:** 1,721 trips were identified with unusually high trip distance and relatively low recorded fares. These records were **retained** in the cleaned table rather than removed, as the available data does not provide sufficient evidence to determine whether these represent legitimate fare adjustments (e.g. flat rates, corporate accounts) or genuine data quality errors.

These are flagged as **potential anomalies** for awareness during interpretation.

---

## Cleaning Script

```sql
CREATE OR REPLACE TABLE `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data` AS

WITH column_assign AS (
    SELECT *,
        TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) AS trip_duration_minutes,
        EXTRACT(YEAR FROM pickup_datetime) AS year,
        FORMAT_DATE('%A', pickup_datetime) AS day,
        FORMAT_DATE('%B', pickup_datetime) AS month
    FROM `bigquery-public-data.biglake-public-nyc-taxi-iceberg.public_data.nyc_taxicab_2021`
),

cleaned_taxi AS (
    SELECT *
    FROM column_assign
    WHERE trip_duration_minutes < 300
      AND year = 2021
      AND trip_duration_minutes > 1
      AND trip_distance > 0
      AND fare_amount > 0
      AND total_amount > 0
      AND extra >= 0
      AND ((passenger_count > 0 AND passenger_count <= 5) OR passenger_count IS NULL)
      AND trip_distance < 100
)

SELECT * FROM cleaned_taxi
```

---

## Retention Rate Verification

```sql
SELECT
    COUNT(*) AS cleaned_rows_no,
    (SELECT COUNT(*) FROM `bigquery-public-data.biglake-public-nyc-taxi-iceberg.public_data.nyc_taxicab_2021`) AS original_rows_no
FROM cleaned_taxi
```

**Result:**

| cleaned_rows_no | original_rows_no |
|----------------|-----------------|
| 28,101,653 | 30,904,427 |

**Retention Rate: 90.93%**

---

## Summary

| Filter | Condition | Reason |
|--------|-----------|--------|
| Year | = 2021 | Remove invalid timestamps |
| Trip duration min | > 1 minute | Remove cancelled/incomplete trips |
| Trip duration max | < 300 minutes | Remove anomalous long trips |
| Trip distance min | > 0 miles | Remove impossible zero-distance trips |
| Trip distance max | < 100 miles | Remove suspicious long-distance outliers |
| Fare amount | > 0 | Remove unpaid/invalid fares |
| Total amount | > 0 | Remove voided/reversed transactions |
| Extra charges | >= 0 | Remove impossible negative extras |
| Passenger count | 1–5 or NULL | Remove invalid passenger counts |
| Fare outlier (EDA) | <= 600 | Applied selectively — extreme outlier treatment |
| Total outlier (EDA) | < 900 | Applied selectively — extreme outlier treatment |

---

*Author: Rahul Datta Roy*
*Project: NYC Yellow Taxi 2021 EDA — BigQuery + Python*
