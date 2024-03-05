SELECT  P.product_name, E.base_price
FROM dim_products P
Join fact_events E
ON P.product_code = E.product_code
WHERE E.base_price > 500 AND E.promo_type ="BOGOF"
GROUP BY P.product_code, E.base_price;


SELECT city, Count(store_id) as Store_counts 
FROM retail_events_db.dim_stores
GROUP BY city
ORDER BY Store_counts desc;

SELECT C.campaign_id, (E.base_price*quantity_sold(before_promo)) AS Total_revenue_before_promotion
FROM dim_campaigns C
JOIN fact_events E
ON C.campaign_id = E.campaign_id
GROUP BY C.campaign_id
;

SELECT campaign_name,
CONCAT(ROUND(
             SUM((base_price) * (`quantity_sold(before_promo)`))
,1)/1000000,"M") AS total_revenue_before_promotion, 
CONCAT(ROUND(
             SUM(CASE 
                  WHEN promo_type = "25% OFF" THEN ((base_price) * 0.75) * (`quantity_sold(after_promo)`)
	              WHEN promo_type = "33% OFF" THEN ((base_price) * 0.67) * (`quantity_sold(after_promo)`)
				  WHEN promo_type = "50% OFF" THEN ((base_price) * 0.50) * (`quantity_sold(after_promo)`)
	              WHEN promo_type = "500 Cashback" THEN ((base_price) - 500) * (`quantity_sold(after_promo)`)
	              WHEN promo_type = "BOGOF" THEN (base_price*0.50) * (`quantity_sold(after_promo)`*2) 
                  ELSE 0 
                  END )
,1)/1000000,"M") AS total_revenue_after_promotion 
FROM dim_campaigns C JOIN fact_events F
ON C.campaign_id = F.campaign_id
GROUP BY campaign_name;
UPDATE fact_events
SET 
quantity_sold_AP_updated = CASE 
                  WHEN promo_type = "BOGOF" THEN  `quantity_sold(after_promo)`*2
                  ELSE `quantity_sold(after_promo)` END;




SELECT category,
CONCAT(ROUND(
      (
      SUM((CASE 
                  WHEN promo_type = "BOGOF" THEN  `quantity_sold(after_promo)`*2
                  ELSE `quantity_sold(after_promo)`
                  END)
      - `quantity_sold(before_promo)`) / SUM(`quantity_sold(before_promo)`)
      )*100
,1),"%") AS "ISU%",
RANK() OVER (ORDER BY 
ROUND((SUM(
(CASE 
                  WHEN promo_type = "BOGOF" THEN  `quantity_sold(after_promo)`*2
                  ELSE `quantity_sold(after_promo)`
                  END)
 - `quantity_sold(before_promo)`) / SUM(`quantity_sold(before_promo)`))*100,1)
DESC) AS ranking
FROM dim_products dp JOIN fact_events f
ON dp.product_code = f.product_code
WHERE campaign_id = "CAMP_DIW_01"
GROUP BY Category;




SELECT Category, product_name,
CONCAT(ROUND(
      (SUM(CASE 
                  WHEN promo_type = "25% OFF" THEN ((base_price) * 0.75) * (`quantity_sold(after_promo)`)
	              WHEN promo_type = "33% OFF" THEN ((base_price) * 0.67) * (`quantity_sold(after_promo)`)
				  WHEN promo_type = "50% OFF" THEN ((base_price) * 0.50) * (`quantity_sold(after_promo)`)
	              WHEN promo_type = "500 Cashback" THEN ((base_price) - 500) * (`quantity_sold(after_promo)`)
	              WHEN promo_type = "BOGOF" THEN (base_price*0.50) * (`quantity_sold(after_promo)`*2) 
                  ELSE 0 
                  END)/1000000) - SUM((base_price) * (`quantity_sold(before_promo)`))/1000000
       / SUM((base_price) * (`quantity_sold(before_promo)`))/1000000 * 100
      ,1),"%") AS IR_percentage
FROM dim_products dp JOIN fact_events f
ON dp.product_code = f.product_code
GROUP BY product_name, Category
ORDER BY IR_percentage DESC   
LIMIT 5
