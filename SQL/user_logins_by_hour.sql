select 
	(u.last_login + '3 hours'::interval)::date, 
	extract('hour' from u.last_login + '3 hours'::interval) as hour,
	count(*)
from public.acorn_user_users u
where not u.last_login is null
group by (u.last_login + '3 hours'::interval)::date, 
	extract('hour' from u.last_login + '3 hours'::interval)
order by (u.last_login + '3 hours'::interval)::date desc, 
	extract('hour' from u.last_login + '3 hours'::interval) desc