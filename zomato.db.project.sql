								-- zomato project--

select * from customers
select * from deliveries
select * from orders
select *  from restaurant
select * from riders

-- EDA

select * from deliveries where delivery_time is null
select * from deliveries where delivery_status = 'Not Delivered'

select * from orders where order_id is null 
	or customer_id is null 
	or restaurant_id is null 
	or order_item is null 
	or order_date is null 
	or order_time is null 
	or order_status is null 
	or total_amount is null 
                         
						 -- ANALYSIS--
--1 Write a query to find the top 5 most frequently ordered dishes by customer called "Arjun Mehta" in the last 1 year.
	select customer_name, order_item, no_of_order,rank from
	(select o.order_item, c.customer_id, c.customer_name, count(*) as no_of_order ,
	dense_rank() over(order by count(*) desc ) as rank
	from  orders o 
	join customers c on c.customer_id = o.customer_id
	where order_date >= current_date - interval '2 year' and customer_name = 'Arjun Mehta'
	group by 1,2,3 order by 2, 4 desc) as t1
	where rank <=5

-- 2 Identify the time slots during which the most orders are placed. based on 2-hour intervals.
select
	case
		when extract(hour from order_time) between 0 and 1 then '00:00-02:00'
		when extract(hour from order_time) between 2 and 3 then '02:00-04:00'
		when extract(hour from order_time) between 4 and 5 then '04:00-06:00'
		when extract(hour from order_time) between 6 and 7 then '06:00-08:00'
		when extract(hour from order_time) between 8 and 9 then '08:00-10:00'
		when extract(hour from order_time) between 10 and 11 then '10:00-12:00'
		when extract(hour from order_time) between 12 and 13 then '12:00-14:00'
		when extract(hour from order_time) between 14 and 15 then '14:00-16:00'
		when extract(hour from order_time) between 16 and 17 then '16:00-18:00'
		when extract(hour from order_time) between 18 and 19 then '18:00-20:00'
		when extract(hour from order_time) between 20 and 21 then '20:00-22:00'
		when extract(hour from order_time) between 22 and 23 then '22:00-00:00'
		end as time_slot, count(order_id) as order_count_hourly,
		dense_rank() over(order by count(order_id )desc)
		from orders
		group by time_slot

 -- Question:3 Find the average order value per customer who has placed more than 750 orders.
-- Return customer_name, and aov(average order value)
	select o.customer_id , avg(o.total_amount), count(o.order_id), c.customer_name,
	dense_rank() over(order by  avg(o.total_amount) desc) as rank
	from orders o
	join customers c on c.customer_id = o.customer_id
	group by 1,4
	having count(order_id)>750

 -- Question:4 List the customers who have spent more than 100K in total on food orders.
-- return customer_name, and customer_id!
	select o.customer_id , sum(o.total_amount) as total_spent , c.customer_name
	from orders o 
	join customers c on c.customer_id=o.customer_id
	group by 1,3
	having sum(o.total_amount) >100000 

-- Question:5 Write a query to find orders that were placed but not delivered. 
-- Return each restuarant name, city and number of not delivered orders
					
	select r.restaurant_name , o.order_status, count(o.order_id) from orders o
	left join restaurant r on r.restaurant_id = o.restaurant_id
	left join deliveries d on d.order_id= o.order_id
	where d.delivery_id is null
	group by 1,2 order by 3 desc

--6 Rank restaurants by their total revenue from the last year, including their name, 
-- total revenue, and rank within their city.
	with ranking as
				(select r.restaurant_name, r.city,  sum(o.total_amount) as revenue,
				rank() over(partition by r.city order by sum(o.total_amount) desc) as res_rank
				from restaurant r 
				join orders o on r.restaurant_id= o.restaurant_id 
				where o.order_date >= current_date - interval'2 year'
				group by 1,2)

	select * from ranking where res_rank = 1

-- Q. 7
-- Most Popular Dish by City: 
-- Identify the most popular dish in each city based on the number of orders.
	with popular_dish as 
				(select o.order_item, r.city , count(o.order_id) as total_order,
				rank() over(partition by r.city order by  count(o.order_id)desc ) as rank
				from orders o 
				join restaurant r on o.restaurant_id = r.restaurant_id
				group by 1,2)
	select * from popular_dish 
	where rank =1

--8 Find customers who haven’t placed an order in 2024 but did in 2023.

-- find cx who has done orders in 2023
-- find cx who has not done orders in 2024
-- compare 1 and 2
	SELECT DISTINCT customer_id FROM orders
WHERE 
	EXTRACT(YEAR FROM order_date) = 2023
	AND
	customer_id NOT IN 
					(SELECT DISTINCT customer_id FROM orders
					WHERE EXTRACT(YEAR FROM order_date) = 2024)

-- Calculate and compare the order cancellation rate for each restaurant between the 
-- current year and the previous year.
	WITH cancel_ratio_23 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
    FROM orders AS o
    LEFT JOIN deliveries AS d
    ON o.order_id = d.order_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2023
    GROUP BY o.restaurant_id
),
cancel_ratio_24 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
    FROM orders AS o
    LEFT JOIN deliveries AS d
    ON o.order_id = d.order_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2024
    GROUP BY o.restaurant_id
),
last_year_data AS (
    SELECT 
        restaurant_id,
        total_orders,
        not_delivered,
        ROUND((not_delivered::numeric / total_orders::numeric) * 100, 2) AS cancel_ratio
    FROM cancel_ratio_23
),
current_year_data AS (
    SELECT 
        restaurant_id,
        total_orders,
        not_delivered,
        ROUND((not_delivered::numeric / total_orders::numeric) * 100, 2) AS cancel_ratio
    FROM cancel_ratio_24
)	

SELECT 
    c.restaurant_id AS restaurant_id,
    c.cancel_ratio AS current_year_cancel_ratio,
    l.cancel_ratio AS last_year_cancel_ratio
FROM current_year_data AS c
JOIN last_year_data AS l
ON c.restaurant_id = l.restaurant_id;

-- Q.10 Rider Average Delivery Time: 
-- Determine each rider's average delivery time.
SELECT 
    o.order_id,
    o.order_time,
    d.delivery_time,
    d.rider_id,
    d.delivery_time - o.order_time AS time_difference,
	EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
	CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
	INTERVAL '0 day' END))/60 as time_difference_insec
FROM orders  o
JOIN deliveries  d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered';

--11 Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining monthly
select * from orders
with growth_ratio as
		(select o.restaurant_id, 
		to_char(o.order_date , 'mm-yy') as month,
		count(o.order_id) as curr_month_sale,
		lag(count(o.order_id),1) over(partition by o.restaurant_id order by to_char(o.order_date , 'mm-yy') ) as pre_month_sale
		from orders o join deliveries d 
		on o.order_id = d.order_id
		where delivery_status = 'Delivered'
		group by 1,2 order by 1 ,2)
select restaurant_id, month , pre_month_sale, curr_month_sale,
	round((curr_month_sale::numeric - pre_month_sale::numeric)/pre_month_sale::numeric*100,2)
	from growth_ratio
		
--12 Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending 
-- compared to the average order value (AOV). If a customer's total spending exceeds the AOV, 
-- label them as 'Gold'; otherwise, label them as 'Silver'. Write an SQL query to determine each segment's 
-- total number of orders and total revenue
with members as
		(select customer_id , sum(total_amount) as total_spent,count(order_id) as order_count,
		case 
			when sum(total_amount) >(select avg(total_amount) from orders) then 'gold' 
			else 'silver' end as member
			from orders
			group by 1)
	select  member, sum(total_spent)as revenue, sum(order_count) as total_orders 
	from members group by 1


	
select avg(total_amount) from orders

	select customer_id , avg(total_amount)
	from orders group by 1 order by 1


-- Q.13 Rider Monthly Earnings: 
-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.
	select d.rider_id, to_char(order_date, 'mm-yy') as month ,				
	sum(o.total_amount) as revenue,
	sum(o.total_amount)*0.08 as riders_earning
	from orders o join deliveries d on d.order_id=o.order_id
	group by 1,2 order by 1,2

	-- Q.14 Rider Ratings Analysis: 
-- Find the number of 5-star, 4-star, and 3-star ratings each rider has.
-- riders receive this rating based on delivery time.
-- If orders are delivered less than 15 minutes of order received time the rider get 5 star rating,
-- if they deliver 15 and 20 minute they get 4 star rating 
-- if they deliver after 20 minute they get 3 star rating.

with stars as 
	(select  rider_id ,time_taken,
		case
			when time_taken <15 then '5 star'
			when time_taken between 15 and 20 then '4 star'
			else '3 star' end as stars
from
(
	SELECT o.restaurant_id, d.rider_id, o.order_time,d.delivery_time,
	extract(epoch from (d.delivery_time-o.order_time+ case when d.delivery_time< o.order_time then interval '1 day'
	else interval '0 day' end))/60 as time_taken
	from orders o join deliveries d on o.order_id = d.order_id
	where delivery_status = 'Delivered') as ti order by 3)

select  stars, rider_id , count(*)as total_ratings from stars
group by 1,2 order by 2

-- Q.15 Order Frequency by Day: 
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.
	select restaurant_id ,name, day ,total_order, rank
	from
		(select o.restaurant_id, r.restaurant_name as name ,count(o.order_id) as total_order,
		to_char(o.order_date , 'day') as day,
		rank() over(partition by o.restaurant_id order by count(o.order_id)desc ) as rank
		from orders o join restaurant r on r.restaurant_id= o.restaurant_id
		group by 1,2,4 order by 1) as t1
	where rank = 1 order by name

-- Q.16 Customer Lifetime Value (CLV): 
-- Calculate the total revenue generated by each customer over all their orders. and most loved item?
with ranking as		
		(select customer_id ,order_item, sum(total_amount), count(order_id),
		rank() over(partition by customer_id order by sum(total_amount) desc) as rank
		from orders
		group by 1,2 order by 1)
select * from ranking 
where rank = 1

-- Q.17 Monthly Sales Trends: 
-- Identify sales trends by comparing each month's total sales to the previous month.
with sales_analysis as
	(SELECT 
		EXTRACT(YEAR FROM order_date) as year,
		EXTRACT(MONTH FROM order_date) as month,
		SUM(total_amount) as curr_month_sale,
		LAG(SUM(total_amount), 1) OVER(ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) as prev_month_sale
	FROM orders
	GROUP BY 1, 2)
select year,month, 
	curr_month_sale,
	prev_month_sale,
	round((curr_month_sale::numeric - prev_month_sale::numeric)/prev_month_sale::numeric*100,2) as percentage
	from sales_analysis
	

-- Q.18 Rider Efficiency: 
-- Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.

select max(avg_time_taken),min(avg_time_taken)
	from
		(select avg(time_taken) as avg_time_taken, rider_id 
			from
				(select d.rider_id, o.order_time, d.delivery_time,
					round(extract(epoch from (d.delivery_time- o.order_time + case when o.order_time>d.delivery_time then interval '1 day'
					else '0 day' end))/60 ,2)as time_taken
					from deliveries d join orders o on d.order_id = o.order_id
					where delivery_status = 'Delivered') as t1
			group by 2	order by 2)as t2
			


-- Q.19 Order Item Popularity: 
-- Track the popularity of specific order items over time and identify seasonal demand spikes.

with ranking as 
	(with seasons as
		(select *,
		extract(month from order_date) as month,
		case 
			when extract(month from order_date) between 3 and 6 then 'spring'
			when extract(month from order_date) between 6 and 9 then 'summer'
 			else 'winter' end as season from orders)
	select season, order_item, count(order_id),
	rank() over(partition by season order by count(order_id)desc) from seasons
	group by 1,2)
select * from ranking where rank = 1	


-- Q.20 Rank each city based on the total revenue for last year 2023 
		SELECT r.city , sum(o.total_amount) as revenue,
		rank() over(order by  sum(o.total_amount)desc) as rank
		from restaurant r join orders o 
		on r.restaurant_id =o.restaurant_id
		where to_char(o.order_date,'yyyy') ='2023'
		group by 1

---------------------------------------------------------------------------------------------------------------------------------------








