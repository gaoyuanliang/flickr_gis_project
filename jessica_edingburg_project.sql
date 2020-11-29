psql -h localhost -U hw -d hw -W

password: abc123


sudo -su postgres

ChMe210+4

\l

\dt


\dp flickr_edin


GRANT SELECT, UPDATE, INSERT ON grid100m TO hw;
GRANT SELECT, UPDATE, INSERT ON flickr_edin TO hw;
GRANT SELECT, UPDATE, INSERT ON edinbuildings TO hw;


insert into dftest (geom)
values (ST_GeomFromText('LINESTRING(10 10, 15 10, 15 20)'));

insert into dftest (geom)
values (ST_GeomFromText('POLYGON((0 0 8, 0 1 8, 1 1 8, 1 0 8, 0 0 8))'));

insert into dftest (geom)
values (ST_GeomFromText('POLYGON((0 0,10 0,10 20,0 10,0 0))'));

SELECT id,ST_LENGTH(geom),ST_GEOMETRYTYPE(geom) FROM dftest;


select * from dftest;



SELECT ST_ASTEXT(dftest.geom) as df1geom, ST_ASTEXT(dftest2.geom) as df2geom
FROM dftest
JOIN dftest2 ON ST_WITHIN(dftest.geom,dftest2.geom);


SELECT ST_ASTEXT(dftest.geom) as df1geom,
ST_WITHIN(dftest.geom,(ST_GeomFromText('POLYGON( (0 0,13 0,15 20,3 10, 0 0))')))
FROM dftest;


SELECT a.id, ST_ASTEXT(a.geom) 
FROM dftest a 
JOIN dftest b ON ST_WITHIN(a.geom,b.geom)
WHERE a.id != b.id AND b.id = 16;



SELECT dftest.id,ST_ASTEXT (dftest.geom) 
FROM dftest
JOIN (SELECT * FROM dftest WHERE id=12) line ON 
ST_INTERSECTS(dftest.geom,ST_BUFFER(line.geom,3));


CREATE TABLE dftest3 AS
(SELECT id, ST_BUFFER(geom,5) as geom FROM dftest
WHERE ST_GEOMETRYTYPE(geom) = 'ST_Point' );



SELECT a.id as origin,b.id as dest,ST_DISTANCE(a.geom,b.geom)as dst 
FROM dftest a CROSS JOIN dftest b;


SELECT COUNT(*) from flickr_edin;

CREATE INDEX sidx_flickr_edin_geom ON flickr_edin USING gist (geom);
CREATE INDEX sidx_grid100m_geom ON grid100m USING gist (geom);


GRANT CREATE TO hw;



CREATE TABLE flickrgrid AS 
SELECT COUNT(*) as count,b.geom 
FROM flickr_edin a
JOIN grid100m b ON ST_WITHIN(a.geom,b.geom)
GROUP BY b.geom;

GRANT SELECT, UPDATE, INSERT ON flickrgrid TO hw;

SELECT EXTRACT('dow' FROM date_taken) as dow,COUNT(*)
FROM flickr_edin
GROUP BY dow 
ORDER BY dow;


SELECT usertags 
FROM flickr_edin
WHERE LENGTH(usertags)>1 
LIMIT 1;

CREATE TABLE flickrgrid AS 
SELECT COUNT(*) as count,b.geom 
FROM flickr_edin a
JOIN grid100m b ON ST_WITHIN(a.geom,b.geom)
GROUP BY b.geom;

select geom, st_astext(geom) as geom_text
from flickrgrid
order by count desc 
limit 1;


psql -h localhost -U hw -d hw -W -q -f df_routea.sql
psql -h localhost -U hw -d hw -W -q -f df_routeb.sql
psql -h localhost -U hw -d hw -W -q -f df_routec.sql

abc123


GRANT SELECT, UPDATE, INSERT ON routea TO hw;
GRANT SELECT, UPDATE, INSERT ON routeb TO hw;
GRANT SELECT, UPDATE, INSERT ON routec TO hw;

drop table if exists route_line_length;

create table route_line_length as 
select geom, st_length(geom) as line_length, 'routea' as route_name  from routea 
union all 
select geom, st_length(geom) as line_length, 'routeb' as route_name  from routeb
union all 
select geom, st_length(geom) as line_length, 'routec' as route_name  from routec;

drop table if exists route_length;

create table route_length as 
select route_name, sum(line_length) as route_length
from route_line_length
group by route_name;

select * from route_length;

select route_length.route_name, 
route_photo_count.photo_count/route_length.route_length popularity,
route_length.route_length, 
route_photo_count.photo_count
from route_length
join (
	select route_name, count(*) as photo_count
	from (
		SELECT flickr_edin.*, route.route_name
		FROM flickr_edin 
		JOIN route_line_length as route ON 
		ST_INTERSECTS(flickr_edin.geom,ST_BUFFER(route.geom,25))
	) photo_over_route
	group by route_name
) route_photo_count
on route_length.route_name = route_photo_count.route_name
order by route_photo_count.photo_count/route_length.route_length desc;

drop table if exists Nelson_Monument;
CREATE TABLE Nelson_Monument (id serial,geom geometry);
INSERT INTO Nelson_Monument (geom) values (ST_SetSRID(ST_Point(326253.33,674110.63),27700));

drop table if exists flickr_edin_nelson;
create table flickr_edin_nelson as 
select flickr_edin.*
from flickr_edin
join Nelson_Monument
on ST_INTERSECTS(flickr_edin.geom,ST_BUFFER(Nelson_Monument.geom,200));

select dow, count(*) as photo_count
from (
	select flickr_edin_nelson.*,
	EXTRACT('dow' FROM date_taken) as dow
	from flickr_edin_nelson
) as flickr_edin_nelson_dow
group by dow
order by dow;


drop table if exists flickr_edin_term;
create table flickr_edin_term as 
select *, 'Castle' as term from flickr_edin where usertags ILIKE '%Castle%'
union all 
select *, 'Calton Hill' as term from flickr_edin where usertags ILIKE '%Calton Hill%'
union all 
select *, 'Royal Mile' as term from flickr_edin where usertags ILIKE '%Royal Mile%'
union all 
select *, 'Meadows' as term from flickr_edin where usertags ILIKE '%Meadows%';

select * from flickr_edin_term limit 100;

select 
st_astext(st_centroid(cell_geom)) as cell_centroid,
st_astext(cell_geom) as most_popular_cell, 
count(*) as photo_count
from (
	select flickr_edin.*, 
	grid100m.geom as cell_geom
	from flickr_edin 
	join grid100m on ST_WITHIN(flickr_edin.geom,grid100m.geom)
	where flickr_edin.usertags ILIKE '%Royal Mile%'
) as grid100m_term
group by cell_geom
order by count(*) desc
limit 1;


wget https://www.macs.hw.ac.uk/~pb56/f21df.zip


#########

drop table if exists flickr_edin_Royal_Mile;
create table flickr_edin_Royal_Mile as 
select cell_geom as most_popular_cell, 
count(*) as photo_count
from (
	select flickr_edin.*, 
	grid100m.geom as cell_geom
	from flickr_edin 
	join grid100m on ST_WITHIN(flickr_edin.geom,grid100m.geom)
	where flickr_edin.usertags ILIKE '%Royal Mile%'
) as grid100m_term
group by cell_geom
order by count(*) desc;


drop table if exists flickr_edin_Castle;
create table flickr_edin_Castle as 
select cell_geom as most_popular_cell, 
count(*) as photo_count
from (
	select flickr_edin.*, 
	grid100m.geom as cell_geom
	from flickr_edin 
	join grid100m on ST_WITHIN(flickr_edin.geom,grid100m.geom)
	where flickr_edin.usertags ILIKE '%Castle%'
) as grid100m_term
group by cell_geom
order by count(*) desc;


drop table if exists flickr_edin_Meadows;
create table flickr_edin_Meadows as 
select cell_geom as most_popular_cell, 
count(*) as photo_count
from (
	select flickr_edin.*, 
	grid100m.geom as cell_geom
	from flickr_edin 
	join grid100m on ST_WITHIN(flickr_edin.geom,grid100m.geom)
	where flickr_edin.usertags ILIKE '%Meadows%'
) as grid100m_term
group by cell_geom
order by count(*) desc;

drop table if exists flickr_edin_Calton_Hill;
create table flickr_edin_Calton_Hill as 
select cell_geom as most_popular_cell, 
count(*) as photo_count
from (
	select flickr_edin.*, 
	grid100m.geom as cell_geom
	from flickr_edin 
	join grid100m on ST_WITHIN(flickr_edin.geom,grid100m.geom)
	where flickr_edin.usertags ILIKE '%Calton Hill%'
) as grid100m_term
group by cell_geom
order by count(*) desc;
