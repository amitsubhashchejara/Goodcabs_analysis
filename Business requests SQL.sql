-- Business Request - I: City-Level Fare and Trip Summary Report
USE trips_db;

SELECT city_name, COUNT(trip_id) AS total_trips, AVG(fare_amount/distance_travelled_km) AS avg_fair_per_km, 
	AVG(fare_amount) AS avg_fair_amount, (COUNT(trip_id)*100/(SELECT COUNT(trip_id) FROM fact_trips)) AS percent_contribution
    FROM
    dim_city JOIN fact_trips ON dim_city.city_id = fact_trips.city_id
    GROUP BY city_name;

-- Business Request - 2: Monthly City-Level Trips Target Performance Report
USE targets_db;

SELECT dc.city_name AS city_name, MONTHNAME(ft.`date`) AS month_name, COUNT(ft.trip_id) AS actual_trips,
	AVG(mtt.total_target_trips) AS target_trips,
    CASE 
		WHEN COUNT(ft.trip_id)>AVG(mtt.total_target_trips) THEN "Above Target"
		ELSE "Below Target"
    END AS performance_status,
    ABS((COUNT(ft.trip_id) - AVG(mtt.total_target_trips))*100/AVG(mtt.total_target_trips)) AS `%_difference`
	FROM 
    trips_db.fact_trips ft LEFT JOIN targets_db.monthly_target_trips mtt 
    ON ft.city_id = mtt.city_id AND MONTHNAME(ft.`date`) = MONTHNAME(mtt.`month`)
    LEFT JOIN trips_db.dim_city dc
    ON mtt.city_id = dc.city_id
    GROUP BY 
    city_name, month_name, MONTH(ft.`date`)
	ORDER BY 
    city_name, MONTH(ft.`date`);
    
-- Business Request - 3: City-Level Repeat Passenger Trip Frequency Report

USE trips_db;

SELECT city_name, (SUM(CASE WHEN trip_count = "2-Trips" THEN repeat_passenger_count ELSE 0 END)*100/ SUM(repeat_passenger_count)) AS `2-Trip`,
	(SUM(CASE WHEN trip_count = "3-Trips" THEN repeat_passenger_count ELSE 0 END)*100/ SUM(repeat_passenger_count)) AS `3-Trip`,
    (SUM(CASE WHEN trip_count = "4-Trips" THEN repeat_passenger_count ELSE 0 END)*100/ SUM(repeat_passenger_count)) AS `4-Trip`,
    (SUM(CASE WHEN trip_count = "5-Trips" THEN repeat_passenger_count ELSE 0 END)*100/ SUM(repeat_passenger_count)) AS `5-Trip`,
    (SUM(CASE WHEN trip_count = "6-Trips" THEN repeat_passenger_count ELSE 0 END)*100/ SUM(repeat_passenger_count)) AS `6-Trip`,
    (SUM(CASE WHEN trip_count = "7-Trips" THEN repeat_passenger_count ELSE 0 END)*100/ SUM(repeat_passenger_count)) AS `7-Trip`,
    (SUM(CASE WHEN trip_count = "8-Trips" THEN repeat_passenger_count ELSE 0 END)*100/ SUM(repeat_passenger_count)) AS `8-Trip`,
    (SUM(CASE WHEN trip_count = "9-Trips" THEN repeat_passenger_count ELSE 0 END)*100/ SUM(repeat_passenger_count)) AS `9-Trip`,
    (SUM(CASE WHEN trip_count = "10-Trips" THEN repeat_passenger_count ELSE 0 END)*100/ SUM(repeat_passenger_count)) AS `10-Trip`
    FROM 
    `dim_repeat_trip_distribution` LEFT JOIN `dim_city`
    ON `dim_repeat_trip_distribution`.city_id = `dim_city`.city_id
    GROUP BY city_name;
    
-- Business Request -4: Identify Cities with Highest and Lowest Total New Passengers

USE trips_db;

SELECT city_name, SUM(new_passengers) AS total_new_passengers, 
	(CASE 
		WHEN SUM(new_passengers)>=(SELECT SUM(new_passengers) AS np FROM `fact_passenger_summary` GROUP BY city_id ORDER BY np DESC LIMIT 1 OFFSET 2)
		THEN "Top-3"
        WHEN SUM(new_passengers)<=(SELECT SUM(new_passengers) AS np FROM `fact_passenger_summary` GROUP BY city_id ORDER BY np ASC LIMIT 1 OFFSET 2)
        THEN "Bottom-3"
        ELSE "None" 
	END) AS city_category
    FROM `fact_passenger_summary` LEFT JOIN `dim_city`
    ON `fact_passenger_summary`.city_id = `dim_city`.city_id
    GROUP BY city_name;
    
-- Business Request - 5: Identify Month with Highest Revenue for Each City
USE trips_db;
SELECT derived.city_name AS city_name, 
       derived.`month` AS highest_revenue_month, 
       derived.revenue AS max_revenue
FROM (
    SELECT dc.city_name, 
           MONTHNAME(ft.`date`) AS `month`, 
           SUM(ft.fare_amount) AS revenue
    FROM fact_trips ft
    LEFT JOIN dim_city dc
    ON ft.city_id = dc.city_id
    GROUP BY dc.city_name, `month`
) derived
JOIN (
    SELECT city_id, MAX(revenue) AS max_revenue
    FROM (
        SELECT city_id, 
               MONTHNAME(`date`) AS `month`, 
               SUM(fare_amount) AS revenue
        FROM fact_trips
        GROUP BY city_id, `month`
    ) aggregated
    GROUP BY city_id
) max_derived
ON derived.revenue = max_derived.max_revenue 
AND derived.city_name = (SELECT city_name FROM dim_city WHERE dim_city.city_id = max_derived.city_id);

-- Business Request - 6: Repeat Passenger Rate Analysis
USE trips_db;

SELECT 
	`dim_city`.`city_name` AS `city_name`, MONTHNAME(`fact_passenger_summary`.`month`) AS `month`, 
    SUM(`fact_passenger_summary`.total_passengers) AS `total_passengers`, 
    SUM(`fact_passenger_summary`.repeat_passengers) AS `repeat_passengers`,
    (SUM(`fact_passenger_summary`.repeat_passengers)*100/SUM(`fact_passenger_summary`.total_passengers)) AS `monthly_repeat_passenger_rate_(%)`,
    AVG(`temp`.`city_repeat_passengers_rate_(%)`*100) AS  `city_repeat_passengers_rate_(%)`
	FROM 
    `fact_passenger_summary`
    LEFT JOIN
    (SELECT city_id, (SUM(repeat_passengers)/SUM(total_passengers)) AS `city_repeat_passengers_rate_(%)`
	FROM `fact_passenger_summary`
    GROUP BY city_id) temp
    ON `fact_passenger_summary`.city_id = `temp`.city_id
    LEFT JOIN 
    `dim_city`
    ON `fact_passenger_summary`.`city_id` = `dim_city`.`city_id`
    GROUP By `month`,`city_name`
    ORDER BY `city_name`, MONTH(`fact_passenger_summary`.`month`);
    
