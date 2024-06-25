USE toys_and_models;

-- évolution du chiffre d'affaires par office par an

SELECT offices.city as office,
	year(orderdate) as année,
    SUM(quantityOrdered) as quantité_de_commande,
    SUM(quantityOrdered * priceEach) as total_ca
    
FROM offices

	JOIN employees USING (officecode)
    
	JOIN customers ON customers.salesrepemployeenumber = employees.employeenumber
    
	JOIN orders USING (customernumber)
    
	JOIN orderdetails USING (ordernumber)
    
GROUP BY  offices.city, year(orderdate) 

ORDER BY office, année;


-- total de quantité vendu et de ca pr chaque categorie de produit, année,office

SELECT
    offices.city as office,
    year(orderdate) as année,
    productline as catégorie_de_produit,
    SUM(quantityOrdered) as quantité_de_commande,
    SUM(quantityOrdered * priceEach) as total_ca
    
FROM products

	JOIN orderdetails USING (productcode)
    
	JOIN orders USING (ordernumber)  
    
	JOIN customers USING (customernumber) 
    
	JOIN employees ON employees.employeenumber = customers.salesrepemployeenumber   
    
	JOIN offices USING (officecode)
    
WHERE status != 'cancelled'

GROUP BY productline, offices.city, year(orderdate)

ORDER BY offices.city, year(orderdate), productline DESC;



  -- TOP 5 CLIENT total ca et total quantity par year 
  

WITH TOP_5_client as (SELECT 

    offices.city as office,
    concat(customers.city, ", ", customers.country),
    year(`orderdate`) as année,
    customername as client, 
    SUM(quantityOrdered) as quantité_de_commande,
    sum(quantityordered*priceeach) as total_ca,
    rank() over (partition by offices.city,  year(`orderdate`) order by sum(quantityordered*priceeach) desc) as classement
    
FROM products

	JOIN orderdetails USING (productcode)
    
	JOIN orders USING (ordernumber)  
    
	JOIN customers USING (customernumber) 
    
	JOIN employees ON employees.employeenumber = customers.salesrepemployeenumber 
    
	JOIN offices USING (officecode)
    
GROUP BY  année, offices.city, concat(customers.city, ", ", customers.country), customers.addressline1, customername

ORDER BY offices.city, année)

SELECT * FROM TOP_5_client
WHERE classement <= 5

;


--  5 moins bon client total ca et total quantity par year pr chaque client	


WITH flop_5_client as (SELECT 

     offices.city as office,
     year(`orderdate`) as année, 
     concat(customers.city, ", ", customers.country),
     customername, 
     SUM(quantityOrdered) as quantité_de_commande,
     sum(quantityordered*priceeach) as total_ca,
    rank() over (partition by offices.city,  year(`orderdate`) order by sum(quantityordered*priceeach) ASC) as classement
    
FROM products

	JOIN orderdetails USING(productcode)  
    
	JOIN orders USING(ordernumber)
	
    JOIN customers USING(customernumber) 
	
    JOIN employees ON employees.employeenumber = customers.salesrepemployeenumber
	
    JOIN offices USING (officecode)
    
GROUP BY  année, offices.city, concat(customers.city, ", ", customers.country), customername)

SELECT * FROM flop_5_client
WHERE classement <= 5

;

/* pr chaque année, pr chaque categorie produit, 
 top 3 de produit plus vendu*/

WITH top_3_produit_plus_vendus as( SELECT 
offices.city as office,
year(`orderdate`) as année,
productline as catégorie_de_produit,
productname as nom_du_produit,
sum(quantityordered*priceeach) as total_ca,
rank() over( partition by offices.city, year(`orderdate`), productline order by  year(`orderdate`), sum(quantityordered*priceeach) desc) as classement

FROM products

	JOIN orderdetails USING(productcode)     
    
	JOIN orders USING(ordernumber)
	
    JOIN customers USING(customernumber) 
	
    JOIN employees ON employees.employeenumber = customers.salesrepemployeenumber
	
    JOIN offices USING (officecode)
    
WHERE status != 'cancelled'

GROUP BY office, year(`orderdate`), productline,productname, productline   

ORDER BY office,année,productLine) 
    
SELECT * FROM top_3_produit_plus_vendus
WHERE classement <= 3
;

-- les 3 produits les moins bons

with FLOP_3_produit as( SELECT 
offices.city as office,
year(`orderdate`) as année,
productline as catégorie_de_produit,
productname as nom_du_produit,
sum(quantityordered*priceeach) as total_ca,
rank() over( partition by offices.city, year(`orderdate`), productline order by  year(`orderdate`), sum(quantityordered*priceeach) asc) as classement

FROM products

	JOIN orderdetails USING(productcode)  
    
	JOIN orders USING(ordernumber)
	
    JOIN customers USING(customernumber) 
	
    JOIN employees ON employees.employeenumber = customers.salesrepemployeenumber
	
    JOIN offices USING (officecode)
    
WHERE status != 'cancelled'

GROUP BY office, year(`orderdate`), productline,productname, productline  
 
ORDER BY office,année,productLine) 

SELECT * FROM FLOP_3_produit
WHERE classement <= 3
;

-- total ca et total quantity commandée par year pr chaque pays des client

SELECT
    customers.country as pays_client,
    customers.city,
    year(orderdate) as année,
    SUM(quantityOrdered) as quantité_de_commande,
    SUM(quantityOrdered * priceEach) as total_ca
    
FROM products
	JOIN orderdetails ON orderdetails.productcode = products.productcode
    
	JOIN orders ON orders.ordernumber = orderdetails.ordernumber    
    
	JOIN customers ON customers.customernumber = orders.customernumber 
    
	JOIN employees ON employees.employeenumber = customers.salesrepemployeenumber 
    
	JOIN offices USING (officecode)
    
WHERE status != 'cancelled'

GROUP BY customers.country,customers.city, year(orderdate)

ORDER BY customers.country, year(orderdate);
    
    
-- repartition en pourcentage des ca par categorie produit, par year, mois
   
SELECT 
    
    offices.city AS office,
    YEAR(`orderdate`) AS année,
    productline AS catégorie_de_produit,
    SUM(quantityOrdered * priceeach) AS total_CA,
    LAG(SUM(quantityOrdered * priceeach)) OVER (PARTITION BY offices.city, productline ORDER BY YEAR(`orderdate`)) AS CA_annee_precedente,
    CASE 
        WHEN LAG(SUM(quantityOrdered * priceeach)) OVER (PARTITION BY offices.city, productline ORDER BY YEAR(`orderdate`)) IS NULL THEN NULL
        ELSE ((SUM(quantityOrdered * priceeach) - LAG(SUM(quantityOrdered * priceeach)) OVER (PARTITION BY offices.city, productline ORDER BY YEAR(`orderdate`))) / LAG(SUM(quantityOrdered * priceeach)) OVER (PARTITION BY offices.city, productline ORDER BY YEAR(`orderdate`))) * 100
    END AS pourcentage_variation
    
FROM products

	JOIN orderdetails ON orderdetails.productcode = products.productcode
    
	JOIN  orders ON orders.ordernumber = orderdetails.ordernumber
	
    JOIN  customers ON customers.customernumber = orders.customernumber
	
    JOIN  employees ON employees.employeenumber = customers.salesrepemployeenumber
	
    JOIN  offices USING (officecode)
    
GROUP BY année, office, catégorie_de_produit

ORDER BY office, catégorie_de_produit, année;
	
SELECT year(`orderdate`) as year, sum(productline) 

FROM productlines

	JOIN products USING (productline)
    
	JOIN Orderdetails USING (productcode)
	
    JOIN orders USING (ordernumber)
    
GROUP BY year;


-- le panier moyen

SELECT SUM(quantityordered*priceeach) / COUNT(DISTINCT ordernumber) AS panier_moyen
FROM orderdetails;

-- la moyenne pondérées de sprix

SELECT sum(quantityordered*priceeach) / sum(quantityordered) 
FROM orderdetails;