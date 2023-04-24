-- 1. Create a query to get the total users who completed the order and total orders per month. Time frame from Jan 2019 until Des 2022.
-- Expected output:
-- •	Month
-- •	Total Users
-- •	Total Orders

-- select
--  date_trunc(date(created_at),month) month
--  , count(distinct user_id) total_user
--  , count(order_id) total_order
-- from `bigquery-public-data.thelook_ecommerce.orders`
-- where date_trunc(date(created_at),month) between '2019-01-01' and '2022-12-31'
-- group by 1
-- order by 1
--------------------------------------------------------------------------------------------------------------------------------------------
-- 2.	Create a query to get average order value and total number of unique users, grouped by month. Time frame from Jan 2019 until Des 2022.
-- Expected output:
-- • Month-year
-- • AOV (Revenue per order)
-- • Distinct Users

-- select
--   format_date('%b %Y',created_at) month_year
--   , round(sum(sale_price)/count(order_id),2) aov
--   , count(distinct user_id) total_user
-- from `bigquery-public-data.thelook_ecommerce.order_items`
-- where date_trunc(date(created_at),month) between '2019-01-01' and '2022-12-31'
-- group by 1
-- order by parse_date('%b %Y',month_year)
--------------------------------------------------------------------------------------------------------------------------------------------
-- 3.	Find the first and last name of users from the youngest and oldest age of each gender.
-- Expected output:
-- • Gender   
-- • Youngest Age
-- • Oldest Age
-- • First name
-- • Last name

-- with female_youngest_age as
-- (
--   select
--     gender
--     , min(age) age
--     , first_name
--     , last_name
--   from `bigquery-public-data.thelook_ecommerce.users`
--   where gender = 'F'
--   group by 1,3,4
--   order by 2
--   limit 1
-- ),
-- female_oldest_age as
-- (
--   select
--     gender
--     , max(age) age
--     , first_name
--     , last_name
--   from `bigquery-public-data.thelook_ecommerce.users`
--   where gender = 'F'
--   group by 1,3,4
--   order by 2 desc
--   limit 1
-- ),
-- male_youngest_age as
-- (
--   select
--     gender
--     , min(age) age
--     , first_name
--     , last_name
--   from `bigquery-public-data.thelook_ecommerce.users`
--   where gender = 'M'
--   group by 1,3,4
--   order by 2
--   limit 1
-- ),
-- male_oldest_age as
-- (
--   select
--     gender
--     , max(age) age
--     , first_name
--     , last_name
--   from `bigquery-public-data.thelook_ecommerce.users`
--   where gender = 'M'
--   group by 1,3,4
--   order by 2 desc
--   limit 1
-- )
-- select
--   *
-- from female_youngest_age
-- union all
-- select
--   *
-- from female_oldest_age
-- union all
-- select
--   *
-- from male_youngest_age
-- union all
-- select
--   *
-- from male_oldest_age
--------------------------------------------------------------------------------------------------------------------------------------------
-- 4.	Get the top 5 most profitable product and its profit detail breakdown by month.
-- Expected output:
-- • Month
-- • Product id
-- • Product name
-- • Sales
-- • Cost
-- • Profit
-- • Cumulative Profit
-- • Rank per month

-- with products as
-- (
--   select
--     date_trunc(date(oi.created_at),month) month
--     , oi.product_id product_id
--     , p.name product_name
--     , round(p.retail_price,2) sale
--     , round(p.cost,2) cost
--     , round(p.retail_price - p.cost,2) profit
--   from `bigquery-public-data.thelook_ecommerce.products` p
--   left join `bigquery-public-data.thelook_ecommerce.order_items` oi
--   on p.id = oi.product_id
--   where oi.status = 'Complete'
-- ),
-- cumulative_profit as (
-- select
--   *
--   , round(sum(profit) over (partition by product_name order by month),2) cumv_profit
-- from products
-- order by 7 desc
-- limit 5
-- )
-- select
--   *
--   , row_number() over (partition by month order by cumv_profit desc) rank
-- from cumulative_profit
-- order by 8
------------------------------------------------------------------------------------------------------------------------------------------
-- 5.	Create a query to get Month to Date of total revenue in each product categories of past 3 months.
-- Expected Output:
-- • Date (in date format)
-- • Product Categories 
-- • Revenue

-- with product_category_table as
-- (
--   select
--     date_trunc(date(oi.created_at),day) day
--     , p.category product_category
--     , p.retail_price sale_price
--   from `bigquery-public-data.thelook_ecommerce.products` p
--   left join `bigquery-public-data.thelook_ecommerce.order_items` oi
--   on p.id = oi.product_id
--   where oi.status = 'Complete' 
--   and date(oi.created_at) >= date_sub(date'2023-03-16', interval 90 day)
--   )
-- select
--   day
--   , product_category
--   , round(sum(sale_price) over (partition by product_category order by day),2) revenue_per_day
-- from product_category_table
-- order by 1
--------------------------------------------------------------------------------------------------------------------------------------------
-- 6.	Find monthly growth of TPO (# of completed orders) and TPV (# of revenue) in percentage breakdown by product categories, ordered by time descendingly. Time frame from Jan 2019 until Apr 2022.
-- Expected output:
-- •	Month
-- •	Categories 
-- •	Order Growth
-- •	Revenue Growth (%)

-- with detail as
-- (
--   select
--     distinct p.category product_category
--     , date_trunc(date(oi.created_at),month) month
--     , count(oi.order_id) total_order
--     , round(sum(sale_price),2) revenue
--   from `bigquery-public-data.thelook_ecommerce.products` p 
--   join `bigquery-public-data.thelook_ecommerce.order_items` oi
--   on p.id = oi.product_id  
--   where date(oi.created_at) between '2019-01-01' and '2022-04-30'
--   and oi.status = 'Complete'
--   group by 1,2
--   order by 2
-- ),
-- previous as
-- (
--   select
--     month
--     , product_category
--     , total_order
--     , lag(total_order) over (partition by product_category order by month) prev_total_order
--     , revenue
--     , lag(revenue) over (partition by product_category order by month) prev_revenue
--   from detail
-- order by 1
-- )
  -- select
  --   month
  --   , product_category
  --   , round((total_order - prev_total_order)/prev_total_order*100,2) order_growth
  --   , round((revenue - prev_revenue)/prev_revenue*100,2) revenue_growth
  -- from previous
  -- order by 1 desc
--------------------------------------------------------------------------------------------------------------------------------------------
-- 7.	Create monthly retention cohorts (the groups, or cohorts, can be defined based upon the date that a user purchased a product) and then how many of them (%) coming back for the following 3 months.
-- Expected output:
-- •	Month
-- •	M (# of users in current month)
-- •	Ml (# of users in following months)
-- •	M2 (# of users in following two months)
-- •	M3 (# of users in following three months)

-- create cohort/grup
with cohort as
(
  select
    user_id user_id
    , min(date_trunc(date(created_at), month)) cohort_month
  from `bigquery-public-data.thelook_ecommerce.orders`
  group by 1
  order by 2
),
-- see user activity after buy first time
user_activities as
(
  select
    c.user_id
    , date_diff(date_trunc(date(o.created_at),month),c.cohort_month,month) num_month
  from cohort c
  left join `bigquery-public-data.thelook_ecommerce.orders` o
  on c.user_id = o.user_id
  where extract(year from c.cohort_month) in (2022,2023)
),
-- the total number of users who made orders in month 0
cohort_size as
(
  select
    cohort_month
    , count(1) num_user
  from cohort
  group by 1
  order by 1
),
-- users who place orders after the first order
retention as
(
  select
    c.cohort_month cohort_month
    , count (case when ua.num_month =1 then cohort_month end) as m1
    , count (case when ua.num_month =2 then cohort_month end) as m2
    , count (case when ua.num_month =3 then cohort_month end) as m3
  from user_activities ua
  left join cohort c
  on c.user_id = ua.user_id
  group by 1
  order by 1
)
-- final results and see user retention for 3 months after the first order
  select
    cs.cohort_month
   , cs.num_user
   , r.m1 m1
   , r.m2 m2
   , r.m3 m3
  from cohort_size cs
  left join retention r
  on cs.cohort_month = r.cohort_month
  where r.cohort_month is not null
  order by 1
--------------------------------------------------------------------------------------------------------------------------------------------
