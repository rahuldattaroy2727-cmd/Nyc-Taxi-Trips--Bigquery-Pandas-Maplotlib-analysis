-- ============================================================================
-- EDA CLEANING NOTE
-- ============================================================================
--
-- The cleaned_taxi_data table contains the primary data-cleaning conditions
-- applied during the initial data-cleaning stage.
--
-- During the subsequent EDA, additional outlier checks were performed on
-- specific financial variables. The following conditions were added later
-- and were NOT part of the original cleaned_taxi_data table:
--
-- 1. Fare Amount Outliers:
--    fare_amount <= 600
--    Applied specifically to analyses involving fare_amount to reduce the
--    influence of extreme fare values.
--
-- 2. Total Amount Outliers:
--    total_amount < 900
--    Applied specifically to analyses involving total_amount/revenue to
--    reduce the influence of extreme transaction values.
--
-- These are additional EDA-specific outlier treatments and do not represent
-- changes to the underlying cleaned_taxi_data table. They are applied only
-- where relevant to the variable being analyzed.
--
-- ============================================================================

                                                                                # 1. Overall Trip Analysis #
#########################################
#1.What is the total number of completed taxi trips?
SELECT count(*)
 FROM `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data` 
 #######################
 #Insights:
 #Total number of actual trips completed is 28,101,653 or 28.1 million.(Note:Data after suspicious or irrealvant data removed )

 #################################################################
 #2.What is the total revenue generated from all trips?
 ##################################################################
select sum(total_amount)
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data` 
where total_amount < 900  --(for total_amount outlier)

##################################################################
#Insights :
# the New york taxi trips generated overall $563,902,470 which approximate 563.9 million




##################################################################
#3.What are the average and median fare amounts?
##################################################################

select avg(fare_amount)avg_fare_amount,
  APPROX_QUANTILES(fare_amount, 2)[OFFSET(1)] as median
 from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data` 
 where fare_amount <= 600 --(for fare_outliers)

 ############################################################################
#Insights:
#avgerage fare amount is $13.97 where the median is $10
#so it is Right-skewed as most of the trips  have made $10 while some expensive trips have pull the mean towards right
############################################################################


####################################################
#4.What are the average and median trip distances?
###################################################
select avg(trip_distance)avg_trip_distance,
approx_quantiles(trip_distance, 2)[offset(1)]as median_trip_distance
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`

###################################################
#Insights:
#Average trip distance is 3.38 miles, while the median is 2 miles. This means that at least 50% of trips are 2 miles or less, while longer #trips pull the average upward. The mean being higher than the median indicates a right-skewed distribution.
##################################################



#################################################
#5.What are the average and median trip durations?
#################################################
select avg(trip_duration_minutes)avg_trip_suration_minutes,
approx_quantiles(trip_duration_minutes, 2)[offset(1)]as median_trip_minutes
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
#################################################
#Insights:
#Average trip duration is 14.19 minutes whereas average median trip duration is 11 minutes , so it can be slightly Right-skewed
#################################################

                                                                               # 2. Time & Demand Analysis #
########################################################################
#6.Which month had the highest and lowest number of trips?
########################################################################

select month,
t.no_of_trips,
(case when highest_rn = 1 then 'Highest trips month' when lowest_rn =1 then 'Lowest trips month'end)Trend
from
(
select count(*) as no_of_trips,
month,
rank()over(order by Count(*)desc)highest_rn,
rank()over(order by count(*)asc)lowest_rn
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
group by month
)t
where highest_rn =1 or
 lowest_rn = 1


#####################################################################
#Insights:
#November has the highest number of trips while january has the lowest .This suggests strong monthly seasonality in taxi demand.
# Weather, tourism, holidays, and other external factors may contribute to this variation.
#####################################################################




#####################################################################
#7.Which month generated the highest total revenue?
####################################################################
select month,
sum(total_amount) as revenue_by_month
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
where total_amount < 900  --(for total_amount outliers)
group by month
order by revenue_by_month desc limit 1
####################################################################
#Insights:
#November made the highest revenue with $67,107,961 or 67.1 million
####################################################################



####################################################################
#8.How does the average fare vary across months?
####################################################################
select month,
avg(fare_amount)as avg_fare_amount
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
 where fare_amount <= 600 --(for fare_outliers)
group by month
order by avg_fare_amount desc

###################################################################
#Insights:
#December accounts for the highest average fare amouth wich is 14.79  whereas  january  have 12.62 , novemeber tops both highest revenue and most number of trips
#this shows the driver behind the  higest revenue for november was because of number of trip not the avg fare was high .
###################################################################


###################################################################
#9.Which hours of the day have the highest and lowest demand?
###################################################################

#including booking hour
#----------------------
with bookhour as(
select *,
time_trunc(time(pickup_datetime),hour)as booking_time
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`)


select  booking_time,
count(*)no_of_trips
from bookhour
group by booking_time
order by count(*) desc
###########################################################
# the highest demand is at 18:00 hours followed by 17:00 and 15:00 hours, these are the busiest time which i s after office 
# the lowest demand  is at 04:00 hours followed by 5:00 and 3:00, these are the odd times of the day

###########################################################



###########################################################
#10.Does peak demand correspond to higher average fares?
###########################################################
with bookhour as(
select *,
time_trunc(time(pickup_datetime),hour)as booking_time
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`)


select  booking_time,
count(*)no_of_trips,
avg(fare_amount)avg_fare_amount
from bookhour
 where fare_amount <= 600 --(for fare_outliers)
group by booking_time
order by count(*) desc,avg(fare_amount) desc

#############################################################
#Peak demand does not correspond to higher average fares. The busiest period occurs around the late afternoon/early evening, while the highest average fares occur during low-demand early-morning hours.
############################################################


                                                            #3. Fare & Revenue Analysis #

###########################################################
#11.How does fare amount change as trip distance increases?
###########################################################
select trip_distance,
avg(fare_amount)avg_fare
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
 where fare_amount <= 600 --(for fare_outliers)
group by trip_distance
order by trip_distance asc
###########################################################
#Insight: Average fare generally increases as trip distance increases, indicating a strong positive relationship between the two variables. #However, at very high trip distances, the increase in average fare becomes less consistent, likely due to the relatively small number of #trips in these distance ranges.
###########################################################





###########################################################
#12.Does a longer trip always generate more revenue?
###########################################################
select 
(case when trip_distance >=1 and trip_distance <= 10 then '1 to 10 miles'
          when trip_distance >10 and trip_distance <= 20 then '11 to 20 miles'
          when trip_distance >20 and trip_distance <= 30 then '21 to 30 miles'
          when trip_distance >30 and trip_distance <= 40 then '31 to 40 miles'
          when trip_distance >40 and trip_distance <= 50 then '41 to 50 miles'
          when trip_distance >50 and trip_distance <= 60 then '51 to 60 miles'
          when trip_distance >60 and trip_distance <= 70 then '61 to 70 miles'
          when trip_distance >70 and trip_distance <= 80 then '71 to 80 miles'
          when trip_distance >80 and trip_distance <= 90 then '81 to 90 miles'
         else '91 to 100 miles' end) as Distance_range,
avg(total_amount)avg_revenue
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
where total_amount <900   #(for total_amount outliers)
group by  Distance_range
order by  Distance_range asc



###########################################################################
#Insights:
#Revenue generally increases with trip distance up to 51–60 miles, after which average revenue declines. Further investigation is required due to the potentially low number of observations in the longer-distance ranges.
###########################################################################




###########################################################################
#13.What is the average revenue generated per mile?
############################################################################
select 
round((sum(total_amount)/sum(trip_distance)),2)Dollars_per_mile
from  `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
where total_amount < 900
###########################################################################
#Insigts:
#Average revenue generated is $5.93 per mile
###########################################################################




###########################################################################
#14.What percentage of total revenue comes from tips?
###########################################################################
select 
(sum(tip_amount)*100.0)/(sum(total_amount))  
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
where total_amount < 900 #(for total_amount outliers)
############################################################################
#Insights:
#Tips contribute approximately 12.05% of total revenue.
############################################################################




##########################################################################
#15.How does tip percentage vary with fare amount?
##########################################################################
select 
(case when fare_amount  between 1 and 10 then '1 -10'
      when fare_amount  between 11 and 20 then '11 -20'
      when fare_amount  between 21 and 30 then '21 -30'
      when fare_amount  between 31 and 40 then '31 -40'
      when fare_amount  between 41 and 50 then '41 -50'
      when fare_amount  between 51 and 60 then '51 -60'
      when fare_amount  between 61 and 70 then '61 -70'
      when fare_amount  between 71 and 80 then '71 -80'
      when fare_amount  between 81 and 90 then '81 -90'
      when fare_amount  between 91 and 100 then '91 -100'
      end)as fare_bracket
    ,
    (sum(tip_amount)*100.0/(sum(fare_amount)))tip_percent,
    avg(tip_amount)tip_amount
    from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
    where fare_amount <= 600 --(for fare_outliers)
    group by fare_bracket
    order by fare_bracket asc
#####################################################################################
#Insight: Average tip amount generally increases as fare amount increases. however, tips do not increase proportionally to the fare. As a result, the percentage of fare paid as tips generally decreases at higher fare levels.
#####################################################################################


#######################################################################################
#16.Which distance category generates the highest revenue per trip?
#######################################################################################
select 
(case when trip_distance >=1 and trip_distance <= 10 then '1 to 10 miles'
          when trip_distance >10 and trip_distance <= 20 then '11 to 20 miles'
          when trip_distance >20 and trip_distance <= 30 then '21 to 30 miles'
          when trip_distance >30 and trip_distance <= 40 then '31 to 40 miles'
          when trip_distance >40 and trip_distance <= 50 then '41 to 50 miles'
          when trip_distance >50 and trip_distance <= 60 then '51 to 60 miles'
          when trip_distance >60 and trip_distance <= 70 then '61 to 70 miles'
          when trip_distance >70 and trip_distance <= 80 then '71 to 80 miles'
          when trip_distance >80 and trip_distance <= 90 then '81 to 90 miles'
         else '91 to 100 miles' end) as Distance_range,
avg(total_amount)avg_revenue
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
where total_amount < 900 #(for total_amount outliers)
group by  Distance_range
order by  avg_revenue desc

###########################################################################
#Insights:
#Insight: Trips in the 51–60 mile category generate the highest average revenue per trip at approximately $155.18. Average revenue increases with distance up to this category, after which it gradually declines.
###########################################################################




                                                 #4. Trip Characteristics  #
#############################################################################
#17.What percentage of trips are short (<2 miles), medium (2–10 miles), and long (>10 miles)?
##############################################################################
select (case when trip_distance < 2  then  'Short'
              when  trip_distance >= 2  and  trip_distance <= 10 then 'Medium'
              else 'Long'end)as Trip_category,
              count(*)as no_of_trips,
              ((count(*)*100.0)/(select count(*) from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`))as trips_pct
       from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`     
       group by trip_category  
###############################################################################
#Insights:
#Medium trips account for the majority of trips which is  57.2% ,followed by short trips with 36.3%. The Long trips are only 6.4% of the 
#trips
###############################################################################




###############################################################################
#18.What percentage of trips are short (<10 min), medium (10–30 min), and long (>30 min)?
###############################################################################
select (case when trip_duration_minutes < 10 then 'Short'
            when  trip_duration_minutes >=10 and trip_duration_minutes <= 30 then 'Medium'
            else 'Long'end)as duration_category,
             count(*)as no_of_trips,
              ((count(*)*100.0)/(select count(*) from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`))as trips_pct
       from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`     
       group by duration_category
########################################################################################
#Insights:
#Medium-duration trips are the most common, accounting for 50.16% of all trips, followed by short trips at 42.06%. Long trips represent only #7.78% of total trips.
########################################################################################



##############################################################################
#19.Is trip distance strongly correlated with trip duration?
##############################################################################
select 
corr(trip_distance,trip_duration_minutes)distanceVSduration
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`

##############################################################################
#Insights:
#Trip distance and trip duration have a strong positive correlation
##############################################################################


################################################################
#20.Is trip distance more strongly correlated with fare than trip duration is?
################################################################
select 
corr(trip_distance,trip_duration_minutes)distanceVSduration,
corr(trip_distance,fare_amount)distanceVSfare
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
where fare_amount < 600 --(for fare_amount otliers)


#_____________________________Potential Anomalies__________________________________________#
SELECT *
FROM `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
WHERE 
    trip_distance > 50 
    AND fare_amount < 50
#I identified 1,721 trips with unusually high distance and relatively low recorded fares, but because the available trip data cannot 
#establish whether these fares were legitimate adjustments or data-quality errors, I retained them and treated them as potential anomalies
#____________________________________________________________________________________________#    

#################################################################
##**Insight Update:**
#During Pandas analysis, a strong relationship between **trip distance and fare amount** was observed, which showed a significant discrepancy 
#compared with the SQL correlation result (**0.93 in Pandas vs 0.064 in SQL**). This difference prompted further investigation of the data
#and revealed several extreme fare outliers. Six records with `fare_amount > 600` were identified and excluded from the correlation analysis. 
#After removing these extreme values, the SQL correlation increased from **0.064 to 0.935**, confirming a strong positive relationship 
#between trip distance and fare amount.
##################################################################

#################################################################
#21.What factors have the strongest correlation with total trip revenue?
#################################################################
select 
corr(trip_distance,total_amount)distanceVSrevenue,
corr(trip_duration_minutes,total_amount)durationVsrevenue,
corr(fare_amount,total_amount)farevsrevenue,
corr(tip_amount,total_amount)tip_amountVSrevenue,
corr(tolls_amount,total_amount)toll_amountVSrevenue,
corr(mta_tax,total_amount)mtaVSrevenue,
corr(extra,total_amount)extraVSrevenue,
corr(imp_surcharge,total_amount)improvementVSrevenue,
corr(airport_fee ,total_amount)airport_feeVSrevenue
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
where fare_amount <=600 and total_amount <900 9 #(for total_amount and fare_amount outliers)




######################################################################
#Insights:
#Fare amount has the strongest correlation with total trip revenue (0.976), which is expected because fare amount is a major component of total amount. Trip distance (0.925) and trip #duration (0.826) also show strong positive correlations with total revenue, indicating that longer and farther trips are generally associated with higher revenue. Tolls (0.678), tips
#(0.637), and airport fees (0.581) show moderate positive correlations, while extra charges show almost no linear correlation (0.033).

######################################################################

                                                       #  5. Payment & Passenger Analysis #
#22.Which payment method is most commonly used?     

select *,
(case when  payment_type = '0'  then 'Un-documented'
      when  payment_type = '1'  then 'Credit card'
      when  payment_type = '2'  then 'Cash'
      when  payment_type = '3' then 'No-Charge'
      when  payment_type = '4'  then 'Dispute'
      when  payment_type = '5' then 'Unknown'
      when  payment_type = '6'  then 'Voided trip' end)as payment_category
from

(
select payment_type,
count(*) no_of_transactions
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
group by payment_type
)
order by no_of_transactions desc


#####################################################################
#Insights:
#Credit card is the most commonly used payment method, with 20.75 million transactions, followed by cash with 5.88 million transactions.
#Credit card payments account for the majority of recorded transactions, indicating that electronic payment is significantly more common than cash in the dataset.
#1.37 million transactions have payment_type = 0, which is an undocumented payment code. These records were retained rather than removed because their actual payment method cannot be #determined from the available data.
#No-charge transactions account for 69,201 trips, while disputed transactions account for 31,401 trips.
#Only 1 transaction is recorded with payment_type = 5 (Unknown).
#Overall, credit card is clearly the dominant documented payment method in the 2021 NYC taxi dataset.
#####################################################################



#####################################################################
#23.Which payment method has the highest average transaction value?
#####################################################################
with  payment_mapped as 
(
select *,
(case when  payment_type = '0'  then 'Un-documented'
      when  payment_type = '1'  then 'Credit card'
      when  payment_type = '2'  then 'Cash'
      when  payment_type = '3' then 'No-Charge'
      when  payment_type = '4'  then 'Dispute'
      when  payment_type = '5' then 'Unknown'
      when  payment_type = '6'  then 'Voided trip' end)as payment_category
from

(
select payment_type,
total_amount
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
where total_amount <900
)
)
 
select payment_category,
avg(total_amount) avg_revenue
from payment_mapped
group by payment_category
order by avg(total_amount) desc
########################################################################
#Insights:
# Un-documented trips have the highest average transaction value at $31.92,
# followed by Credit Card at $20.21 and Dispute transactions at $18.98.
# Cash payments have a lower average transaction value of $16.83,
# while Unknown payment types have the lowest at $8.00.
# The high averages for Un-documented, Dispute, and No-Charge categories
# should be interpreted cautiously, as these classifications may represent
# unusual or exceptional transactions rather than typical customer payments.
########################################################################



#########################################################################
#24.How does average tip vary across payment methods?
#########################################################################
with  payment_mapped as 
(
select *,
(case when  payment_type = '0'  then 'Un-documented'
      when  payment_type = '1'  then 'Credit card'
      when  payment_type = '2'  then 'Cash'
      when  payment_type = '3' then 'No-Charge'
      when  payment_type = '4'  then 'Dispute'
      when  payment_type = '5' then 'Unknown'
      when  payment_type = '6'  then 'Voided trip' end)as payment_category
from

(
select payment_type,
tip_amount
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`

)
)
 
select payment_category,
avg(tip_amount) avg_revenue
from payment_mapped
group by payment_category
order by avg(tip_amount) desc




#########################################################################
#Insights:
#Credit card trips have the highest average recorded tip at $3.12.
#Cash trips show almost no recorded tips, but cash tips are not captured in the dataset, so this does not indicate that cash passengers tip less.
#Overall, the recorded tip data shows substantially higher tipping for credit-card transactions.
#########################################################################




#########################################################################
#25.How does average fare vary by passenger count?
#########################################################################
select passenger_count,
avg(fare_amount)
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data`
where fare_amount <= 600
group by passenger_count
order by passenger_count asc
#########################################################################

#########################################################################
#Insights:
#There is no clear linear relationship between passenger count and average fare. The average fare fluctuates across passenger counts rather than consistently increasing or decreasing #as the number of passengers rises.
##########################################################################


                                                                                            # 6. Location Analysis
##########################################################################
#26.Which pickup zones have the highest number of trips?
#########################################################################

select c.pickup_location_id,
l.Zone as zone,
l.Borough as Borough,
count(*)as no_of_trips
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data` as c
join `nyc-taxi-analysis-507515.Nyc_taxi_trips.location_Lookup` as l  
on cast(c.pickup_location_id as int) = cast(l.LocationID as int)
group by c.pickup_location_id,l.Zone,l.Borough
order by count(*) desc

###########################################################################
#Insights:
#Upper East Side South had the highest pickup demand, with approximately 1.40 million trips, followed by Upper East Side North with 1.28 
#million trips. Midtown Center ranked third with approximately 1.01 million trips.
############################################################################



###########################################################################
#27.Which pickup zones generate the highest total revenue?
###########################################################################
select c.pickup_location_id,
l.Zone as zone,
l.Borough as Borough,
sum(total_amount) as revenue
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data` as c
join `nyc-taxi-analysis-507515.Nyc_taxi_trips.location_Lookup` as l  
on cast(c.pickup_location_id as int) = cast(l.LocationID as int)
where total_amount < 900   --(for tatal_amount otliers)
group by c.pickup_location_id,l.Zone,l.Borough
order by sum(total_amount)  desc

########################################################################
#Insights:
#Although Upper East Side South recorded more pickup trips than JFK Airport, JFK Airport generated substantially higher total revenue, followed by LaGuardia Airport. This suggests that airport-originating trips tend to have higher revenue per trip, potentially due to longer and higher-value journeys.
#######################################################################



#####################################################################
#28.Which pickup zones have high demand but low revenue per trip?
######################################################################

with pickup_rev_trips as 
( select c.pickup_location_id as pick_locationid,
l.Zone as zone,
l.Borough as Borough,
sum(total_amount) as revenue,
count(*) AS NO_OF_TRIPS
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data` as c
join `nyc-taxi-analysis-507515.Nyc_taxi_trips.location_Lookup` as l  
on cast(c.pickup_location_id as int) = cast(l.LocationID as int)
where total_amount < 900 --(for tatal_amount otliers)
group by c.pickup_location_id,l.Zone,l.Borough
order by sum(total_amount)  desc
)


select *
from
(
select pickup_rev_trips.pick_locationid,
zone,
revenue,
no_of_trips,
Borough,
(case when  revenue/NO_OF_TRIPS >(select sum(revenue)/sum(NO_OF_TRIPS) from pickup_rev_trips)  and 
            no_of_trips >  (select avg(no_of_trips) from pickup_rev_trips) then'High demand and High revenue'
      when  revenue/NO_OF_TRIPS <  (select sum(revenue)/sum(NO_OF_TRIPS) from pickup_rev_trips)  and 
            no_of_trips >  (select avg(no_of_trips) from pickup_rev_trips) then'High demand and low revenue'      
      when  revenue/NO_OF_TRIPS >(select sum(revenue)/sum(NO_OF_TRIPS) from pickup_rev_trips)  and 
            no_of_trips <  (select avg(no_of_trips) from pickup_rev_trips) then'Low demand and High revenue' 
      when  revenue/NO_OF_TRIPS < (select sum(revenue)/sum(NO_OF_TRIPS) from pickup_rev_trips)  and 
            no_of_trips <  (select avg( no_of_trips) from pickup_rev_trips) then'Low demand and Low revenue' else 'Medium demand and revenue' end ) as demand_rev_category          
from pickup_rev_trips
)
where demand_rev_category  = 'High demand and low revenue'



###############################################################################3
#Insights:
#Several high-demand Manhattan pickup zones generate below-average revenue per trip, suggesting that their strong revenue contribution is primarily volume-driven rather than driven by high-value individual trips.
###############################################################################



################################################################################
#29.Which pickup-to-dropoff routes are the most popular?
################################################################################

with pickup_rev_trips as 
( select c.pickup_location_id as pick_locationid,
c.dropoff_location_id as dropoff_location_id,
l.Zone as pickup_zone,
d.zone as dropoff_zone,
l.Borough as pickup_Borough,
d.borough as dropodd_borough,
sum(total_amount) as revenue,
count(*) AS NO_OF_TRIPS
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data` as c
join `nyc-taxi-analysis-507515.Nyc_taxi_trips.location_Lookup` as l  
on cast(c.pickup_location_id as int) = cast(l.LocationID as int)
join `nyc-taxi-analysis-507515.Nyc_taxi_trips.location_Lookup` as d
on cast(c.dropoff_location_id as int) = cast(d.LocationID as int)
group by c.pickup_location_id,c.dropoff_location_id,l.Zone,d.zone,l.Borough,d.borough

)

select *
from pickup_rev_trips
order by NO_OF_TRIPS desc

##############################################################################
#Insights:
#The most popular pickup-to-dropoff routes are concentrated within Manhattan, with the Upper East Side South ↔ Upper East Side North corridor recording the highest trip volumes. This suggests strong intra-Manhattan travel demand between nearby commercial and residential zones
##############################################################################


#############################################################################################
#30.Are the busiest routes also the most profitable?
#############################################################################################
with pickup_rev_trips as 
( select c.pickup_location_id as pick_locationid,
c.dropoff_location_id as dropoff_location_id,
l.Zone as pickup_zone,
d.zone as dropoff_zone,
l.Borough as pickup_Borough,
d.borough as dropodd_borough,
sum(total_amount) as revenue,
count(*) AS NO_OF_TRIPS
from `nyc-taxi-analysis-507515.Nyc_taxi_trips.cleaned_taxi_data` as c
join `nyc-taxi-analysis-507515.Nyc_taxi_trips.location_Lookup` as l  
on cast(c.pickup_location_id as int) = cast(l.LocationID as int)
join `nyc-taxi-analysis-507515.Nyc_taxi_trips.location_Lookup` as d
on cast(c.dropoff_location_id as int) = cast(d.LocationID as int)
where total_amount < 900  --(for total_amount outliers)
group by c.pickup_location_id,c.dropoff_location_id,l.Zone,d.zone,l.Borough,d.borough

)

select *
from
(
select *,
dense_rank()over(order by revenue desc) revenue_rank,
dense_rank()over(order by no_of_trips desc) trips_rank,
from pickup_rev_trips
)
where revenue_rank <= 10 or trips_rank <=10
limit 10

#Ranked the the routes based on the trips and revenue generated
#############################################################
#Insights:
#The busiest routes are not necessarily the most profitable. While some high-volume routes also rank highly in revenue, several routes with #relatively low trip volumes generate #revenue than trip frequency alone.
#############################################################