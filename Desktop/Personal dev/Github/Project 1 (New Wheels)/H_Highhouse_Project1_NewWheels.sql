/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
SELECT 
state, 
COUNT(DISTINCT customer_id) as cust_count FROM customer_t
GROUP BY 1
ORDER BY 2;

-- For the QBR top 5 states with the most customers
SELECT 
state, 
COUNT(DISTINCT customer_id) as cust_count FROM customer_t
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. 

Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/

With CTE AS ( -- CTE to convert strings to Int
SELECT 
	customer_id,
	quarter_number,
	CASE 
		WHEN customer_feedback = 'Very Bad' THEN 1
		WHEN customer_feedback = 'Bad' THEN 2
		WHEN customer_feedback = 'Okay' THEN 3
		WHEN customer_feedback = 'Good' THEN 4
		WHEN customer_feedback = 'Very Good' THEN 5
	END AS numerical_feedback 
FROM order_t
)
Select 
	quarter_number,
	AVG(numerical_feedback) AS avg_rating
FROM CTE
GROUP BY quarter_number
ORDER BY quarter_number;



-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.
      
Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/
      
With CTE AS (
SELECT
    quarter_number,
	customer_feedback,
    count(customer_id) as cust_count
FROM order_t
GROUP BY quarter_number, customer_feedback
)
SELECT *,
SUM(cust_count) over (partition by quarter_number) as total_orders_by_Q,
cust_count/SUM(cust_count) over (partition by quarter_number) * 100 as perc_total_orders_by_Q 
FROM CTE;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/
SELECT 
	Vehicle_maker, 
	count(customer_id) as pref_vehicles
FROM product_t prod
	INNER JOIN order_t ord
	    ON prod.product_id = ord.product_id
GROUP BY 1
ORDER BY pref_vehicles DESC
Limit 5;

-- output: ['Chevrolet', 83, 'Ford', 63, 'Toyota', 52, 'Dodge', 50, 'Pontiac', 50]


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

WITH CTE as (
SELECT 
    state,
    vehicle_maker,
    COUNT(DISTINCT customer_id) AS customer_count
    FROM order_t JOIN product_t USING (product_id)
    JOIN customer_t USING (customer_id)
    GROUP BY state, vehicle_maker
    )
SELECT * FROM (
SELECT *, RANK() OVER(PARTITION BY state ORDER BY customer_count DESC) AS preference_rank FROM CTE) ranked_tbl
WHERE preference_rank = 1;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/
SELECT 
	quarter_number, 
	COUNT(order_id) as orders_per_Q
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;
-- CORRECT

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/

With CTE as (
SELECT 
quarter_number,
SUM(quantity*(vehicle_price - discount/100 * vehicle_price)) AS order_revenue
FROM order_t
GROUP BY quarter_number)

SELECT *,
LAG(order_revenue) OVER(ORDER BY quarter_number) as prev_Q_rev,
(order_revenue - LAG(order_revenue) OVER(ORDER BY quarter_number)) AS QoQ_revenue,
((order_revenue - LAG(order_revenue) OVER(ORDER BY quarter_number))/ LAG(order_revenue) OVER(ORDER BY quarter_number)) * 100 AS QoQ_rev_perc
FROM CTE
ORDER BY quarter_number;
      
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

SELECT 
quarter_number,
SUM(quantity*(vehicle_price - ((discount/100) * vehicle_price))) AS order_revenue,
COUNT(order_id) AS order_count
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

SELECT 
credit_card_type, 
AVG((discount) *100) as avg_discount
FROM order_t JOIN customer_t USING(customer_id)
GROUP BY 1
ORDER BY 1 ASC, 2;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/

SELECT
    quarter_number,
	AVG(DATEDIFF(ship_date, order_date)) as avg_shipping_days
FROM order_t
GROUP BY 1
ORDER BY quarter_number;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------