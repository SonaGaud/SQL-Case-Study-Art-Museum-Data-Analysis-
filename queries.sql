
--1) Fetch all the paintings which are not displayed on any museums?
	select * from work where museum_id is null;

--2) Retrieve all records from the artist table, displaying only the artist_id, full_name, and nationality.
	select artist_id, full_name, nationality from artist;

--3) Are there museuems without any paintings?
	select * from museum m
	where not exists (select 1 from work w
	where w.museum_id = m.museum_id)
	
--4) Find the total number of paintings in the dataset.
	select count(*) as total_paintings from work;

--5) How many paintings have an asking price of more than their regular price? 
	select * from product_size
	where sale_price > regular_price;
	
--6) List all distinct painting styles available in the dataset.
	select distinct style from work;
	
--7) Identify the paintings whose asking price is less than 50% of its regular price.
 	select * 
	from product_size
	where sale_price < (regular_price*0.5);
	
--8) Which canva size costs the most?
	select cs.label as canva, ps.sale_price
	from (select *
	, rank() over(order by sale_price desc) as rnk 
	from product_size) ps
	join canvas_size cs on cs.size_id::text=ps.size_id
	where ps.rnk=1;	

--9) Delete duplicate records from work, product_size, subject and image_link tables.
	delete from work 
	where ctid not in 
	(select min(ctid) from work group by work_id );	

	delete from product_size 
	where ctid not in (select min(ctid) from product_size
	group by work_id, size_id );

	delete from subject 
	where ctid not in (select min(ctid) from subject
	group by work_id, subject );

	delete from image_link 
	where ctid not in (select min(ctid) from image_link
	group by work_id );

--10) Identify the museums with invalid city information in the given dataset.
	select * from museum where city ~ '^[0-9]'

--11) Museum_Hours table has 1 invalid entry. Identify it and remove it.
	delete from museum_hours 
	where ctid not in (select min(ctid)
	from museum_hours
	group by museum_id, day );

--12) Fetch the top 10 most famous painting subjects.
	select * from (select s.subject,count(1) as no_of_paintings,
		rank() over(order by count(1) desc) as ranking
		from work w join subject s on s.work_id=w.work_id
		group by s.subject )x where ranking <= 10;

--13) Identify the museums which are open on both Sunday and Monday. 
	select distinct m.name as museum_name, m.city, m.state,m.country
	from museum_hours mh 
	join museum m on m.museum_id=mh.museum_id
	where day='Sunday' and exists 
	(select 1 from museum_hours mh2 
			where mh2.museum_id=mh.museum_id and mh2.day='Monday');

--14) How many museums are open every single day?
	select count(1) as open_museums_everyday
	from (select museum_id, count(1)
		  from museum_hours
		  group by museum_id
		  having count(1) = 7) x;


--15) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum).
	select m.name as museum, m.city, m.country, x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs,
			rank() over(order by count(1) desc) as rnk
			from work w join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id where x.rnk<=5;

--16) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
	select a.full_name as artist, a.nationality,x.no_of_painintgs
	from (select a.artist_id, count(1) as no_of_painintgs,
		  rank() over(order by count(1) desc) as rnk
		  from work w join artist a on a.artist_id=w.artist_id
		  group by a.artist_id)x
	join artist a on a.artist_id=x.artist_id where x.rnk<=5;

--17) Display the 3 least popular canva sizes
	select label,ranking,no_of_paintings
	from (select cs.size_id,cs.label,count(1) as no_of_paintings, 
		  dense_rank() over(order by count(1) ) as ranking
		  from work w
		  join product_size ps on ps.work_id=w.work_id
		  join canvas_size cs on cs.size_id::text = ps.size_id
		  group by cs.size_id,cs.label) x where x.ranking<=3;
	

--18) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
select museum_name,state as city,day, open, close, duration from
	(select m.name as museum_name, m.state, day, open, close, 
	 to_timestamp(open,'HH:MI AM'), 
	 to_timestamp(close,'HH:MI PM'), 
	 to_timestamp(close,'HH:MI PM') - to_timestamp(open,'HH:MI AM') as duration, 
	 rank() over (order by (to_timestamp(close,'HH:MI PM') - to_timestamp(open,'HH:MI AM')) desc) as rnk
	 from museum_hours mh
	 join museum m on m.museum_id=mh.museum_id) x where x.rnk=1;

--19) Which museum has the most no of most popular painting style?
	with pop_style as 
			(select style, rank() over(order by count(1) desc) as rnk
			from work group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings,
			 rank() over(order by count(1) desc) as rnk from work w
			 join museum m on m.museum_id=w.museum_id
			 join pop_style ps on ps.style = w.style
			 where w.museum_id is not null and ps.rnk=1
			 group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings from cte where rnk=1;

--20) Identify the artists whose paintings are displayed in multiple countries
	with cte as
		(select distinct a.full_name as artist, m.country from work w
		 join artist a on a.artist_id=w.artist_id
		 join museum m on m.museum_id=w.museum_id)
	select artist,count(1) as no_of_countries from cte
	group by artist having count(1)>1 order by 2 desc;

--21) Display the country and the city with most no of museums. 
--Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.
	with cte_country as 
		(select country, count(1), 
		 rank() over(order by count(1) desc) as rnk
		 from museum group by country),
		 cte_city as
			(select city, count(1), rank() over(order by count(1) desc) as rnk
			from museum group by city)
	select string_agg(distinct country.country,', ') as countries, string_agg(city.city,', ') as city
	from cte_country country cross join cte_city city
	where country.rnk = 1 and city.rnk = 1;

--22) Identify the artist and the museum where the most expensive and least expensive painting is placed. 
-- Display the artist name, sale_price, painting name, museum name, museum city and canvas label
	with cte as 
		(select *, rank() over(order by sale_price desc) as rnk, 
		 rank() over(order by sale_price ) as rnk_asc
		 from product_size )
	select w.name as painting, cte.sale_price, a.full_name as artist, 
	m.name as museum, m.city, cz.label as canvas from cte
	join work w on w.work_id=cte.work_id
	join museum m on m.museum_id=w.museum_id
	join artist a on a.artist_id=w.artist_id
	join canvas_size cz on cz.size_id = cte.size_id::NUMERIC
	where rnk=1 or rnk_asc=1;

--23) Which country has the 5th highest no of paintings?
	with cte as 
		(select m.country, count(1) as no_of_Paintings, 
		 rank() over(order by count(1) desc) as rnk from work w
		 join museum m on m.museum_id=w.museum_id group by m.country)
	select country, no_of_Paintings
	from cte where rnk=5;

--24) Retrieve the name and sale price of paintings that are priced above the average sale price.
	select w.name as painting, ps.sale_price 
	from work w 
	join product_size ps on w.work_id = ps.work_id 
	where ps.sale_price > (select avg(sale_price) from product_size);

--25) Which are the 3 most popular and 3 least popular painting styles?
	with cte as 
		(select style, count(1) as cnt,
		 rank() over(order by count(1) desc) rnk, 
		 count(1) over() as no_of_records
		 from work where style is not null group by style)
	select style, 
	case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte where rnk <=3 or rnk > no_of_records - 3;

--26) Which artist has the most no of Portraits paintings outside USA? 
-- Display artist name, no of paintings and the artist nationality.
	select full_name as artist_name, nationality, no_of_paintings
	from (select a.full_name, a.nationality,count(1) as no_of_paintings,
		  rank() over(order by count(1) desc) as rnk from work w
		  join artist a on a.artist_id=w.artist_id
		  join subject s on s.work_id=w.work_id
		  join museum m on m.museum_id=w.museum_id
	      where s.subject='Portraits' and m.country != 'USA'
		  group by a.full_name, a.nationality) x
	where rnk=1;
	
--27) Identify the artists who have more than 5 paintings in the dataset.
	select a.full_name, count(w.work_id) as total_paintings 
	from artist a 
	join work w on a.artist_id = w.artist_id 
	group by a.full_name 
	having count(w.work_id) > 5;

--28) Retrieve all paintings and their corresponding museums, ensuring that 
--paintings with no museum assignments are also included.
	select w.name as painting, m.name as museum 
	from work w 
	left join museum m on w.museum_id = m.museum_id;

--29) List the paintings and their sale price in descending order.
	select w.name as painting, ps.sale_price 
	from work w 
	join product_size ps on w.work_id = ps.work_id 
	order by ps.sale_price desc;

--30) Rank the museums based on the total number of paintings they display.
	select m.name as museum, count(w.work_id) as total_paintings, 
    rank() over (order by count(w.work_id) desc) as ranking
 	from museum m join work w on m.museum_id = w.museum_id 
    group by m.name;

--31) Find the museum that has the highest total sale value of paintings.
	select m.name as museum, sum(ps.sale_price) as total_sales 
	from museum m 
	join work w on m.museum_id = w.museum_id 
	join product_size ps on w.work_id = ps.work_id 
	group by m.name 
	order by total_sales desc
	limit 1;

	





















