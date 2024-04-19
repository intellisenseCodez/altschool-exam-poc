
/*
Question 1
what is the most ordered item based on the number of times it appears in an order cart that checked out successfully? you are expected to return the product_id, and product_name and num_times_in_successful_orders
*/

WITH add_to_cart_events AS (
    SELECT
        e.customer_id
    FROM alt_school.events e
    WHERE e.event_data @> '{"event_type": "add_to_cart"}' -- Filter events that are add_to_cart
),
successful_orders AS (
    SELECT
        li.item_id AS product_id,
        o.order_id,
        c.customer_id
    FROM alt_school.orders o
    JOIN alt_school.line_items li ON o.order_id = li.order_id
    JOIN alt_school.customers c ON o.customer_id = c.customer_id
    WHERE o.status = 'success' -- Filter only successful orders
),
products_in_successful_orders AS (
    SELECT
        so.product_id
    FROM successful_orders so
    JOIN add_to_cart_events atc ON so.customer_id = atc.customer_id
)
SELECT
    p.id AS product_id,
    p.name AS product_name,
    COUNT(p.id) AS num_times_in_successful_orders
FROM alt_school.products p
JOIN products_in_successful_orders piso ON p.id = piso.product_id
GROUP BY p.id, p.name -- Group by product ID and name
ORDER BY num_times_in_successful_orders DESC;


/*
Question 2
without considering currency, and without using the line_item table, find the top 5 spenders you are exxpected to return the customer_id, location, total_spend
*/
SELECT
    c.customer_id,
    c.location,
    SUM(p.price * CAST((e.event_data::jsonb->>'quantity') AS numeric)) AS total_spend
FROM alt_school.events e
JOIN alt_school.customers c ON e.customer_id = c.customer_id
JOIN alt_school.products p ON (e.event_data::jsonb->>'item_id')::int = p.id
JOIN alt_school.orders o ON e.customer_id = o.customer_id
WHERE
    e.event_data::jsonb->>'event_type' = 'add_to_cart' -- Only consider add_to_cart events
    AND o.status = 'success' -- Only consider successful orders
GROUP BY c.customer_id, c.location
ORDER BY total_spend DESC
LIMIT 5;


/*
Question 3
using the events table, Determine the most common location (country) where successful checkouts occurred. 
return location and checkout_count
*/

SELECT c.location AS location,
       COUNT(e.event_id) AS checkout_count
FROM alt_school.events e
JOIN alt_school.orders o ON e.customer_id = o.customer_id AND o.status = 'success'
JOIN alt_school.customers c ON c.customer_id = o.customer_id
WHERE e.event_data::jsonb->>'event_type' = 'checkout' -- Only consider checkout event in the events table
GROUP BY c.location
ORDER BY checkout_count DESC
LIMIT 1;



/*
Question 4
using the events table, identify the customers who abandoned their carts and count the number of events (excluding visits) 
that occurred before the abandonment. return the customer_id and num_events
*/

SELECT e1.customer_id,
       COUNT(*) AS num_events
FROM alt_school.events e1
JOIN alt_school.events e2 ON e1.customer_id = e2.customer_id
                    AND e2.event_timestamp < e1.event_timestamp
                    AND e2.event_data::jsonb->>'event_type' <> 'visit'
WHERE e1.event_data::jsonb->>'event_type' = 'remove_from_cart'
GROUP BY e1.customer_id;



/*
Question 5
Find the average number of visits per customer, considering only customers who completed a checkout! 
return average_visits to 2 decimal place
*/

SELECT ROUND(AVG(visit_count), 2) AS average_visits
FROM (
    SELECT e.customer_id,
           COUNT(*) AS visit_count
    FROM alt_school.events e
    JOIN alt_school.orders o ON e.customer_id = o.customer_id
                     AND o.status = 'success'
    WHERE e.event_data::jsonb->>'event_type' = 'visit'
    GROUP BY e.customer_id
) AS visit_counts;


