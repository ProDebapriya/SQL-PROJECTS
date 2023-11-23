-- SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='public';
select * from information_schema.tables where table_schema='public';
-- SQL PROJECT- MUSIC STORE DATA ANALYSIS
-- Q1. Who is the senior most employee based on job title?
select * 
from employee
order by levels desc
limit 1;

-- Q2. Which countries have the most Invoices?
select billing_country,sum(total)
from invoice
group by billing_country
order by billing_country desc
limit 1;
-- select * from invoice;
-- Q3. What are top 3 values of total invoice?
select * from invoice;
select billing_country,cast(sum(total) as int ) as total_invoice
from invoice
group by billing_country
order by billing_country desc
limit 3;

/* Q4. Which city has the best customers? We would like to throw a promotional Music 
Festival in the city we made the most money. Write a query that returns one city that 
has the highest sum of invoice totals. Return both the city name & sum of all invoice 
totals */
select * from customer;
select * from invoice;

select billing_city, sum(total) as sum_total
from invoice 
group by billing_city
order by sum_total desc
limit 1;

/* Q5. Who is the best customer? The customer who has spent the most money will be 
declared the best customer. Write a query that returns the person who has spent the 
most money */
select * from customer;
select * from invoice;

select iv.customer_id, 
		c.first_name, 
		c.last_name, 
		c.city,
		c.country,
		sum(iv.total) sum_totals
from invoice iv
join customer c
on iv.customer_id = c.customer_id
group by iv.customer_id,
		 c.first_name, 
		 c.last_name,
		 c.city,
		 c.country
order by sum_totals desc
limit 1;


-- Question Set 2 – Moderate
-- ======================================
-- Q6. Write query to return the email, first name, last name, & Genre of all Rock Music 
-- listeners. Return your list ordered alphabetically by email starting with A
select * from genre;
select * from track;
select * from invoice_line;
select * from invoice;
select * from customer;

select distinct c.email, c.first_name, c.last_name , g.name as genere_name
from customer c
join invoice iv on c.customer_id = iv.customer_id
join invoice_line ivl on iv.invoice_id = ivl.invoice_id
join track tr on ivl.track_id = tr.track_id
join genre g on tr.genre_id = g.genre_id
where g.name = 'Rock'
order by c.email asc;

/* Q7. Let's invite the artists who have written the most rock music in our dataset. Write a 
query that returns the Artist name and total track count of the top 10 rock bands */
select * from artist;
select * from album;
select * from track;
select * from genre;
-- artist who written the most rock music

select ar.name, count(tr.track_id) as total_track_count
from artist ar 
join
	album al on ar.artist_id = al.artist_id
join
	track tr on al.album_id = tr.album_id
join
	genre g on tr.genre_id = g.genre_id
where g.name = 'Rock' 
group by ar.name
order by total_track_count desc
limit 10;

/* Q8.Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the 
longest songs listed first */
select * from track
select
	  tr.name as track_name,
	  tr.milliseconds as song_length
from track tr
where tr.milliseconds >
		(select avg(milliseconds) from track)
order by tr.milliseconds desc;	  

-- Question Set 3 – Advance
-- =============================================
/*Q9.Find how much amount spent by each customer on artists? Write a query to return
customer name, artist name and total spent*/
select * from customer;
select * from invoice;
select * from invoice_line;
select * from track;
select * from album;
select * from artist;

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, 
	artist.name AS artist_name, 
	SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, 
	   c.first_name, 
	   c.last_name, 
	   bsa.artist_name, 
	   SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN 
	customer c ON c.customer_id = i.customer_id
JOIN 
	invoice_line il ON il.invoice_id = i.invoice_id
JOIN 
	track t ON t.track_id = il.track_id
JOIN 
	album alb ON alb.album_id = t.album_id
JOIN 
	best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY c.first_name DESC;

/* Q10.We want to find out the most popular music Genre for each country. We determine the 
most popular genre as the genre with the highest amount of purchases. Write a query 
that returns each country along with the top Genre. For countries where the maximum 
number of purchases is shared return all Genres */
select * from genre;
select * from track;
select * from invoice_line;
select * from invoice;

-- genre <-- track <-- invoice_line <-- invoice(country, amnt purchase as total)
-- genre <-- genre_id--track_id <-- track_id--invoice_id <--invoice_id--invoice_id

WITH CountryGenrePurchase AS (
    SELECT
        c.country AS country_name,
        g.name AS genre_name,
        COUNT(il.invoice_id) AS total_purchases
    FROM
        invoice_line il
    JOIN
        invoice i ON il.invoice_id = i.invoice_id
    JOIN
        customer c ON i.customer_id = c.customer_id
    JOIN
        track t ON il.track_id = t.track_id
    JOIN
        genre g ON t.genre_id = g.genre_id
    GROUP BY
        c.country,
        g.genre_id
)

SELECT
    cgp.country_name,
    cgp.genre_name
FROM
    CountryGenrePurchase cgp
JOIN (
    SELECT
        country_name,
        MAX(total_purchases) AS max_purchases
    FROM
        CountryGenrePurchase
    GROUP BY
        country_name
) max_purchases_per_country
ON
    cgp.country_name = max_purchases_per_country.country_name
    AND cgp.total_purchases = max_purchases_per_country.max_purchases
ORDER BY
    cgp.country_name;

-- ==========================================
WITH CountryGenrePurchases AS (
    SELECT
        iv.billing_country AS country,
        g.name AS genre_name,
        SUM(iv.total) AS total_purchases
    FROM
        invoice iv
    JOIN
        invoice_line ivl ON iv.invoice_id = ivl.invoice_id
    JOIN
        track tr ON ivl.track_id = tr.track_id
    JOIN
        genre g ON g.genre_id = tr.genre_id
    GROUP BY
        iv.billing_country,
        g.name
)

SELECT
    country,
    genre_name,
    total_purchases AS maxm_no_purchase
FROM
    (
        SELECT
            cgp.*,
            ROW_NUMBER() OVER (PARTITION BY cgp.country ORDER BY cgp.total_purchases DESC) AS row_num
        FROM
            CountryGenrePurchases cgp
    ) ranked
WHERE
    row_num = 1
ORDER BY
    maxm_no_purchase DESC, country;

-- ============================================================
WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

-- =====================================================
/* Q11.Write a query that determines the customer that has spent the most on music for each 
country. Write a query that returns the country along with the top customer and how
much they spent. For countries where the top amount spent is shared, provide all 
customers who spent this amount */

WITH CustomerSpending AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.country,
        SUM(il.quantity * il.unit_price) AS total_spent
    FROM
        customer c
    JOIN
        invoice i ON c.customer_id = i.customer_id
    JOIN
        invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY
        c.customer_id, customer_name, c.country
)

SELECT
    cs.country,
    cs.customer_name,
    cs.total_spent
FROM
    CustomerSpending cs
JOIN (
    SELECT
        country,
        MAX(total_spent) AS max_spent
    FROM
        CustomerSpending
    GROUP BY
        country
) max_spent_per_country
ON
    cs.country = max_spent_per_country.country
    AND cs.total_spent = max_spent_per_country.max_spent
ORDER BY
    cs.country, cs.total_spent DESC, cs.customer_name;

-- ================================================
WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1

















































































