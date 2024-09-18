
---- 1. Get details of employees where Region is provided. If Region not available, get City as location

select * from northwind.dbo.Employees where Region is not null

select *, coalesce(Region, City) as location from northwind.dbo.Employees

---- 2. Get a list of customers placing more than 5 orders every month

select order_date_quarter_end,CustomerID, count(distinct OrderID) order_count
from 
(
select CAST(DATEADD(DAY, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, OrderDate) + 1, 0)) AS DATE) order_date_quarter_end, *
from  northwind.dbo.Orders 
)a
group by order_date_quarter_end, CustomerID
having count(distinct OrderID) > 5


---- 3. Get top 3 highest selling products every quarter along with their selling price

with cte1 
as (
select CAST(DATEADD(DAY, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, OrderDate) + 1, 0)) AS DATE) order_date_quarter_end,
order_details.ProductID, products.ProductName,orders.OrderID,
(order_details.UnitPrice * order_details.Quantity * (1 - order_details.Discount)) product_selling_price
from  northwind.dbo.Orders orders left join northwind.dbo.[Order Details] order_details
on orders.OrderID = order_details.OrderID
left join northwind.dbo.Products products
on order_details.ProductID = products.ProductID
)

, cte2 
as (
select order_date_quarter_end, ProductID, ProductName, count(OrderID) order_count,
min(product_selling_price) min_product_selling_price, max(product_selling_price) max_product_selling_price
from cte1
group by order_date_quarter_end, ProductID, ProductName
)

select *  from (
select *, dense_rank() over(partition by order_date_quarter_end order by order_count desc) product_rank
from cte2 ) c
where product_rank <=3

---- 4. Get quarterly total number of orders for each employee

with cte_orders as 
(
select distinct EmployeeID, order_date_quarter_end, count( OrderID) over(partition by EmployeeID, order_date_quarter_end) order_count
from (
select *, 
CAST( DATEADD(QUARTER, DATEDIFF(QUARTER, 0, OrderDate) , 0) AS DATE) order_date_quarter_start,
CAST(DATEADD(DAY, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, OrderDate) + 1, 0)) AS DATE) order_date_quarter_end
from northwind.dbo.Orders
)a)

select EmployeeID, employee_name,
[1996-09-30], [1996-12-31], [1997-03-31], [1997-06-30], [1997-09-30], [1997-12-31],
[1998-03-31], [1998-06-30]
from (
 select concat(FirstName, ' ', LastName) employee_name, orders.* 
 FROM northwind.dbo.Employees emp join cte_orders orders
  on emp.EmployeeID = orders.EmployeeID
  )b
  pivot (sum(order_count) for order_date_quarter_end in ([1996-09-30], [1996-12-31], [1997-03-31], [1997-06-30], [1997-09-30], [1997-12-31],
[1998-03-31], [1998-06-30]) 
)as pivot_table;


---- 5. Get a list of products ordered together in every order. One row per order

select distinct order_details.OrderID, 
string_agg(products.ProductName,',') within group (order by order_details.quantity desc) as product_names
FROM northwind.dbo.[Order Details] order_details left join northwind.dbo.Products products
on order_details.ProductID = products.ProductID
group by order_details.OrderID


