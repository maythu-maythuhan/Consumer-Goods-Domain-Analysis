#1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select 
	market
from dim_customer 
where customer = "Atliq Exclusive" and region = "APAC";

 #2. What is the percentage of unique product increase in 2021 vs. 2020? 
 # The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg
With unique_product as(
SELECT 
	(SELECT COUNT(DISTINCT product_code) FROM fact_sales_monthly WHERE fiscal_year = 2020) AS unique_product_2020,
    (SELECT COUNT(DISTINCT product_code) FROM fact_sales_monthly WHERE fiscal_year = 2021) AS unique_product_2021
) 
select 
	*, 
	round((unique_product_2021 - unique_product_2020) * 100/unique_product_2020,2) as percentage_chg
from unique_product;	

#3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.	 

select
 segment,
 count(distinct product_code) as product_count 
from dim_product
group by segment
order by product_count desc;

#4. Which segment had the most increase in unique products in 2021 vs 2020?
with product_count_by_year2020 as (
	select
		segment,
		count(distinct s.product_code) as product_count_2020
	from dim_product p 
	join fact_sales_monthly s 
	on s.product_code = p.product_code
    where fiscal_year = 2020
	group by 1
    ),
product_count_by_year2021 as (
	select
		segment,
		count(distinct s.product_code) as product_count_2021
	from dim_product p 
	join fact_sales_monthly s 
	on s.product_code = p.product_code
    where fiscal_year = 2021
	group by 1
    )
select 
	p21.segment,
    product_count_2020,
    product_count_2021,
    (product_count_2020 -  product_count_2021) as difference
from product_count_by_year2021 p21
join product_count_by_year2020 p20
on p21.segment = p20.segment
order by difference;

#5. Get the products that have the highest and lowest manufacturing costs.
select 
	product_code,
    product,
    manufacturing_cost
from dim_product p 
join fact_manufacturing_cost m 
using (product_code)
where manufacturing_cost in (
	(select max(manufacturing_cost) from fact_manufacturing_cost), 
    (select min(manufacturing_cost) from fact_manufacturing_cost)
    );

#6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct
 #for the fiscal year 2021 and in the Indian market.
 select 
	customer_code,
    customer,
    pre_invoice_discount_pct as average_discount_percentage
from fact_pre_invoice_deductions pre 
join dim_customer c 
using (customer_code) 
where market = "india" 
and fiscal_year = 2021 
and pre_invoice_discount_pct > (select avg(pre_invoice_discount_pct) from fact_pre_invoice_deductions)
order by pre_invoice_discount_pct desc
limit 5;

#7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
#This analysis helps to get an idea of low and high-performing months and take strategic decisions.
select 
	monthname(date) as Month,
    g.fiscal_year as Year,
    sum(gross_price) as 'Gross sales Amount'
from dim_customer c  
join fact_sales_monthly s 
on c.customer_code = s.customer_code 
join fact_gross_price g 
on g.fiscal_year = s.fiscal_year
where customer = 'Atliq Exclusive'  
group by 2,1
order by 3 desc;  

#8. In which quarter of 2020, got the maximum total_sold_quantity?

select 
	concat("Q",ceil(month(date_add(date,interval 4 month))/3))  as Quarter,
    sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year="2020" 
group by Quarter
order by total_sold_quantity desc
limit 1;

#9. Which channel helped to bring more gross sales in the fiscal year 2021 
-- and the percentage of contribution?
With gross_sales_mln_byChannel as (
	select 
		channel,
		round(sum(gross_price)/1000000,2) as gross_sales_mln
	from fact_gross_price g 
	join fact_sales_monthly s 
	on g.product_code = s.product_code
	and g.fiscal_year = s.fiscal_year
	join dim_customer c 
	on c.customer_code = s.customer_code
	where g.fiscal_year = 2021
	group by channel
	order by gross_sales_mln desc
)
select 
	*,
   FORMAT(gross_sales_mln * 100 / sum(gross_sales_mln) over(), 2) as percentage
from gross_sales_mln_byChannel
group by channel;

#10. Get the Top 3 products in each division that have a high total_sold_quantity 
#    in the fiscal_year 2021?
With top_products as (
	select
		division,
		p.product_code,
		product,
		sum(sold_quantity) as total_sold_quantity
	from dim_product p 
	join fact_sales_monthly s 
	on p.product_code = s.product_code
	where s.fiscal_year = 2021
	group by 1,2,3
),
all_rank as (
	select 
		*,
		dense_rank() over(partition by division order by total_sold_quantity desc) as rank_order
	from top_products
)
select * from all_rank where rank_order < 4;







