# gis_homework


<img src="WX20201128-224809@2x.png" width="500">


<img src="WX20201128-224819@2x.png" width="500">


```sql
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
```
