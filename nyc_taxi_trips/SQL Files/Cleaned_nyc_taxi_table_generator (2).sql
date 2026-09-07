#
#CREATE OR REPLACE TABLE `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data` AS
with column_assign as 
(
SELECT *,
timestamp_diff(dropoff_datetime, pickup_datetime, minute) as trip_duration_minutes,
extract(year from pickup_datetime)as year,
format_date('%A',pickup_datetime )as day,
format_date('%B',pickup_datetime )as month
FROM `bigquery-public-data.biglake-public-nyc-taxi-iceberg.public_data.nyc_taxicab_2021`  
)


# hours-removing the columns with trips mode than 5 hours as after analysis found that  trips exceeding 5 hours were excluded as anomalous records based on the initial exploratory analysis in pandas
# year-only kept rows with 2021 data , there are years such as 2009,2008,2022,2020,2003,2011,2029,2028,2098 etc , which is not relevant dates that we want , hence remvoed 
#minutes-trip duration is  taken more than 1 minutes as we have analysed(sample in pandas) that mostly trips are cancelled one where distance travelled is too less, 
#trip_distance - removed rows with trip duration  is wuals to 0 or in negetive 
#fare_amount cant be 0 in any paid trip , we are not analysing complementary trips as there is no official payment code map to know payment method
#total_amount should be greater than 0 as well so it should not be negetive or zero
#extra can be 0 but not negetivve
#passenger needs to be more than one, but there are lots of rows with nulls,so to preserve the infos, nulls has been kept, and it should not bbe more than 5 .
#trip distance have data more than 100+miles that seems suspicious,so removed
#--------------------------------------------------------------------------------------------------------------#
##**Clening Update:**
#During Pandas analysis, a strong relationship between **trip distance and fare amount** was observed, which showed a significant discrepancy 
#compared with the SQL correlation result (**0.93 in Pandas vs 0.064 in SQL**). This difference prompted further investigation of the data
#and revealed several extreme fare outliers. Six records with `fare_amount > 600` were identified and excluded from the correlation analysis. 
#After removing these extreme values, the SQL correlation increased from **0.064 to 0.935**, confirming a strong positive relationship 
#between trip distance and fare amount.
#---------------------------------------------------------------------------------------------------------------#
#Cleaning Update#
#During the revenue analysis, a small number of extreme total_amount values were identified that could disproportionately affect #revenue-based calculations. Further investigation revealed 10 records with total_amount > 900, including several extremely large values such #as $395,855 and $818,287. These observations were treated as extreme outliers and excluded from relevant revenue-based analyses. After #applying the outlier threshold, total_amount <= 900 was used to reduce the influence of these exceptional values while retaining the vast# #majority of valid transactions.
, cleaned_taxi as (
select * 
from column_assign
where trip_duration_minutes < 300   #(5 hours)
 and year  =2021
 and trip_duration_minutes >1
 and trip_distance > 0
 and fare_amount > 0
 and total_amount >0
 and extra >=0
 and ((passenger_count> 0 and  passenger_count <= 5) or passenger_count is null)
and trip_distance < 100
and fare_amount <=600
and total_amount <900
)
#select *
#from cleaned_taxi
select count(*)  as cleaned_rows_no,
(select count(*) from `bigquery-public-data.biglake-public-nyc-taxi-iceberg.public_data.nyc_taxicab_2021`)original_rows_no
from cleaned_taxi

#cleaned_rows_no	original_rows_no
#     28101643	    30904427	
#retaintion rate 90.93%%
