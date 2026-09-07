# Data Cleaning Methodology

## NYC Yellow Taxi 2021 — BigQuery EDA Project

---

## Overview

This document describes the data cleaning and outlier-treatment process applied to the **NYC Yellow Taxi 2021** dataset used in this project.

The source dataset is:

```text
bigquery-public-data.biglake-public-nyc-taxi-iceberg.public_data.nyc_taxicab_2021
```

The cleaned dataset was created in Google BigQuery and saved as:

```text
nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data
```

The cleaning process was performed primarily in **BigQuery SQL**, while **Pandas** was used during the exploratory stage to inspect distributions, identify unusual records, and help determine reasonable cleaning thresholds.

---

# 1. Dataset Scale

| Metric             |      Value |
| ------------------ | ---------: |
| Original row count | 30,904,427 |
| Cleaned row count  | 28,101,643 |
| Rows removed       |  2,802,784 |
| **Retention rate** | **90.93%** |

Approximately **90.93% of the original records were retained** after applying the cleaning and outlier conditions described below.

The objective was not to remove every unusual observation. Instead, the cleaning process focused on removing records that were clearly invalid, irrelevant to the 2021 analysis, or extreme enough to materially distort financial analysis.

---

# 2. Feature Engineering

Before applying the cleaning conditions, several analytical columns were derived from the original dataset.

| New Column              | Description                                                  |
| ----------------------- | ------------------------------------------------------------ |
| `trip_duration_minutes` | Difference between drop-off and pickup timestamps in minutes |
| `year`                  | Year extracted from `pickup_datetime`                        |
| `day`                   | Day of the week extracted from the pickup date               |
| `month`                 | Month extracted from the pickup date                         |

### Derived fields

```text
trip_duration_minutes
= TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE)

year
= EXTRACT(YEAR FROM pickup_datetime)

day
= FORMAT_DATE('%A', pickup_datetime)

month
= FORMAT_DATE('%B', pickup_datetime)
```

These fields were created before filtering so that the cleaning conditions could be applied consistently.

---

# 3. Cleaning Conditions

## 3.1 Year Filter

### Condition

```text
year = 2021
```

### Reason

Although the dataset represents NYC taxi data for 2021, the raw data contained records with timestamps corresponding to years outside the expected period.

Examples identified during the analysis included:

* 2003
* 2008
* 2009
* 2011
* 2020
* 2022
* 2028
* 2029
* 2098

These dates are not relevant to the intended 2021 analysis and were therefore removed.

---

## 3.2 Minimum Trip Duration

### Condition

```text
trip_duration_minutes > 1
```

### Reason

Initial exploratory analysis using a sample of the data in Pandas showed that trips lasting one minute or less frequently had very little distance travelled and appeared inconsistent with normal completed taxi journeys.

To reduce the inclusion of potentially cancelled, incomplete, or otherwise abnormal records, trips with a duration of **1 minute or less** were excluded.

This threshold was selected based on exploratory analysis rather than assuming that every short trip is invalid.

---

## 3.3 Maximum Trip Duration

### Condition

```text
trip_duration_minutes < 300
```

This corresponds to a maximum duration of **5 hours**.

### Reason

Initial exploratory analysis identified trips exceeding five hours as anomalous relative to normal NYC taxi operations.

Rather than attempting to determine whether every extreme-duration record was legitimate, trips exceeding five hours were excluded because they were considered unlikely to represent normal taxi journeys and could distort duration-based analysis.

---

## 3.4 Trip Distance

### Conditions

```text
trip_distance > 0
AND trip_distance < 100
```

### Reason

A completed taxi trip should have a positive distance.

Therefore:

* Zero-distance trips were removed.
* Negative-distance trips were removed.
* Trips exceeding 100 miles were removed as suspicious extreme observations.

The 100-mile threshold was selected because NYC taxi trips rarely reach such distances, and extremely large values were considered more likely to represent data-quality issues or exceptional records that could distort the analysis.

Importantly, trips between 50 and 100 miles were not automatically considered invalid. They were retained unless they violated another cleaning condition.

---

## 3.5 Fare Amount

### Condition

```text
fare_amount > 0
```

### Reason

The analysis focuses on completed taxi trips and their financial characteristics. A fare amount of zero or below does not represent a normal paid taxi transaction.

Complementary or special transactions were not specifically analyzed because the available payment-type information does not provide enough context to reliably distinguish all such cases.

Therefore, records with zero or negative fare amounts were excluded.

---

## 3.6 Total Amount

### Condition

```text
total_amount > 0
```

### Reason

The total transaction amount should be positive for a completed paid trip.

Records with zero or negative total amounts were therefore excluded because they could represent invalid, reversed, voided, or otherwise non-standard transactions.

---

## 3.7 Extra Charges

### Condition

```text
extra >= 0
```

### Reason

Extra charges may legitimately be zero when no additional charge applies.

However, a negative extra charge was considered invalid and was therefore removed.

---

## 3.8 Passenger Count

### Condition

```text
(passenger_count > 0 AND passenger_count <= 5)
OR passenger_count IS NULL
```

### Reason

The analysis retained trips with passenger counts between **1 and 5**.

Records with:

* `passenger_count = 0`
* negative passenger counts
* passenger counts greater than 5

were removed.

However, NULL passenger counts were deliberately retained.

There were a substantial number of NULL values, and removing them would result in unnecessary information loss. Passenger count was also not a critical variable for the primary trip, revenue, and location analyses.

Therefore, NULL values were preserved rather than treating missing passenger counts as invalid trips.

---

# 4. Financial Outlier Treatment

During the subsequent EDA, extreme financial observations were identified.

These observations were investigated separately because they could have a disproportionate effect on averages, correlations, and revenue calculations.

After investigation, the thresholds below were incorporated into the final cleaned table.

---

## 4.1 Fare Amount Outliers

### Condition

```text
fare_amount <= 600
```

### Discovery

During the Pandas analysis, a strong relationship between trip distance and fare amount was observed.

However, the SQL correlation calculated on the data before applying the extreme fare filter was approximately:

```text
0.064
```

This differed substantially from the relationship observed during Pandas analysis, where the correlation was approximately:

```text
0.93
```

Further investigation identified **6 extreme records with `fare_amount > 600`**.

One of these observations had a fare amount of approximately:

```text
$818,283
```

Such values were several orders of magnitude larger than normal taxi fares and had a substantial effect on the correlation calculation.

After excluding fare values above $600:

```text
Correlation before filtering ≈ 0.064
Correlation after filtering  ≈ 0.935
```

The resulting correlation was consistent with the strong positive relationship observed during the Pandas analysis.

### Treatment

The threshold:

```text
fare_amount <= 600
```

was therefore included in the final cleaned table.

This reduced the influence of extreme fare observations on fare-related analyses while retaining the overwhelming majority of legitimate fare records.

---

## 4.2 Total Amount Outliers

### Condition

```text
total_amount < 900
```

### Discovery

During revenue analysis, several exceptionally large `total_amount` values were identified.

Further investigation found **10 records with `total_amount > 900`**.

Some extreme examples included values of approximately:

```text
$395,855
$818,287
```

These values were considered extreme outliers relative to normal NYC taxi transactions and could disproportionately affect:

* Total revenue
* Average revenue
* Revenue per trip
* Revenue-based comparisons

### Treatment

A threshold of:

```text
total_amount < 900
```

was therefore applied.

This removed the extreme transaction values while retaining the vast majority of valid transactions.

---

# 5. Potential Anomalies Retained

Not every unusual observation was removed.

One important example was trips with:

```text
trip_distance > 50
AND fare_amount < 50
```

A total of **1,721 trips** met these conditions.

These trips appear unusual because they combine a relatively high recorded distance with a comparatively low fare.

However, the available dataset does not provide enough information to determine whether these records are definitely incorrect.

Possible explanations could include special fare arrangements, fare adjustments, flat-rate pricing, or other circumstances that are not explicitly represented in the available fields.

Therefore, these records were **retained** rather than removed.

They are treated as **potential anomalies** during interpretation rather than automatically classified as errors.

This approach follows a benefit-of-the-doubt principle: an unusual observation was removed only when there was sufficient evidence that it was invalid or likely to distort the analysis.

---

# 6. Final Cleaning Logic

The final cleaned table was created by applying the following conditions:

```text
trip_duration_minutes < 300
AND year = 2021
AND trip_duration_minutes > 1
AND trip_distance > 0
AND trip_distance < 100
AND fare_amount > 0
AND fare_amount <= 600
AND total_amount > 0
AND total_amount < 900
AND extra >= 0
AND ((passenger_count > 0 AND passenger_count <= 5)
     OR passenger_count IS NULL)
```

The final table therefore contains both:

1. **Data-validity filters**, such as valid dates, durations, distances, fares, and passenger counts.
2. **Extreme financial outlier filters**, specifically the fare and total-amount thresholds discovered during EDA.

---

# 7. Final Cleaning SQL

The following SQL was used to create the cleaned table.

> **Important:** The project ID in this example belongs to the original project. If you reproduce this project in your own Google Cloud account, replace `nyc-taxi-analysis-507515` with your own BigQuery project ID.

```sql
CREATE OR REPLACE TABLE `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data` AS

WITH column_assign AS (
    SELECT *,
        TIMESTAMP_DIFF(
            dropoff_datetime,
            pickup_datetime,
            MINUTE
        ) AS trip_duration_minutes,

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
      AND trip_distance < 100
      AND fare_amount > 0
      AND fare_amount <= 600
      AND total_amount > 0
      AND total_amount < 900
      AND extra >= 0
      AND (
          (passenger_count > 0 AND passenger_count <= 5)
          OR passenger_count IS NULL
      )
)

SELECT *
FROM cleaned_taxi;
```

---

# 8. Reproducing the Cleaned Dataset

Someone reproducing this project should follow these steps.

### Step 1 — Create a Google Cloud / BigQuery Project

Create a project in Google Cloud with **BigQuery** enabled.

They do not need to use the original project ID.

For example, if their project ID is:

```text
my-taxi-analysis-project
```

they should replace:

```text
nyc-taxi-analysis-507515
```

with their own project ID.

---

### Step 2 — Create a Dataset

Inside their BigQuery project, create a dataset named:

```text
Nyc_taxi_trips
```

The dataset should be created in the appropriate location for their BigQuery setup.

---

### Step 3 — Run the Cleaning SQL First

Before running the EDA queries, they must run the **cleaning SQL** that creates:

```text
Nyc_taxi_trips.cleaned_taxi_data
```

If they are using the SQL file from this repository, they should:

1. Remove the comment marker from the `CREATE OR REPLACE TABLE` statement if necessary.
2. Replace the original project ID with their own project ID.
3. Run the cleaning query.
4. Verify that the `cleaned_taxi_data` table has been created successfully.

The EDA queries depend on this table, so the cleaning step should be completed first.

---

### Step 4 — Run the Location Lookup Setup

The location-based analyses also require the `location_Lookup` table.

Therefore, the lookup table must be created or loaded before running the location-analysis queries.

The project repository contains the required SQL/data needed for this step.

---

### Step 5 — Run the EDA Queries

Once the cleaned table has been created, the EDA queries can be executed.

The queries reference:

```text
<YOUR_PROJECT_ID>.Nyc_taxi_trips.cleaned_taxi_data
```

Therefore, the original project ID should be replaced with the reproducer's project ID throughout the SQL files.

---

# 9. Retention Rate Verification

The final cleaned table was compared against the original BigQuery public dataset.

```sql
SELECT
    COUNT(*) AS cleaned_rows_no,

    (
        SELECT COUNT(*)
        FROM `bigquery-public-data.biglake-public-nyc-taxi-iceberg.public_data.nyc_taxicab_2021`
    ) AS original_rows_no

FROM `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`;
```

### Result

| Metric           |       Rows |
| ---------------- | ---------: |
| Original dataset | 30,904,427 |
| Cleaned dataset  | 28,101,643 |
| Rows removed     |  2,802,784 |
| Retention rate   | **90.93%** |

### Retention calculation

```text
28,101,643 / 30,904,427 × 100
≈ 90.93%
```

Therefore, approximately **90.93% of the original records were retained**.

---

# 10. Cleaning Summary

| Filter                       | Condition       | Purpose                                                       |
| ---------------------------- | --------------- | ------------------------------------------------------------- |
| Year                         | `year = 2021`   | Remove records outside the analysis period                    |
| Trip duration — minimum      | `> 1 minute`    | Remove potentially incomplete or abnormal very-short trips    |
| Trip duration — maximum      | `< 300 minutes` | Remove anomalous trips exceeding 5 hours                      |
| Trip distance — minimum      | `> 0 miles`     | Remove zero/negative distances                                |
| Trip distance — maximum      | `< 100 miles`   | Remove suspicious extreme distances                           |
| Fare amount — minimum        | `> 0`           | Remove zero/negative fares                                    |
| Fare amount — maximum        | `<= 600`        | Reduce influence of extreme fare outliers                     |
| Total amount — minimum       | `> 0`           | Remove zero/negative transactions                             |
| Total amount — maximum       | `< 900`         | Reduce influence of extreme transaction outliers              |
| Extra charges                | `>= 0`          | Remove impossible negative extras                             |
| Passenger count              | `1–5 or NULL`   | Remove invalid counts while preserving missing values         |
| High-distance/low-fare trips | **Retained**    | Potential anomalies without sufficient evidence of invalidity |

---

# 11. Important Data-Quality Decisions

The cleaning process followed three principles:

### 1. Remove clearly invalid records

Examples include:

* Invalid years
* Non-positive trip distances
* Non-positive fares
* Non-positive total amounts
* Negative extra charges
* Invalid passenger counts
* Extremely long trip durations

### 2. Control extreme financial outliers

Extreme `fare_amount` and `total_amount` values were investigated because they had a substantial impact on statistical and financial analysis.

The thresholds of:

```text
fare_amount <= 600
total_amount < 900
```

were subsequently incorporated into the final cleaned table.

### 3. Do not automatically remove unusual observations

The presence of an unusual value does not necessarily mean that the value is incorrect.

For example, the **1,721 high-distance/low-fare trips** were retained because the available fields did not provide enough evidence to determine that they were invalid.

This distinction is important because the objective of data cleaning is to improve data quality without unnecessarily removing potentially legitimate observations.

---

# 12. Final Dataset

After applying the cleaning methodology:

**Original records:**

```text
30,904,427
```

**Final cleaned records:**

```text
28,101,643
```

**Records retained:**

```text
90.93%
```

The resulting dataset was then used for the project's SQL-based exploratory analysis and the Pandas-based visualization and distribution analysis.

---

*Author: Rahul Datta Roy*

*Project: NYC Yellow Taxi 2021 EDA — BigQuery + Python*
