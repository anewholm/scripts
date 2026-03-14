SELECT string_agg(
				concat('drop table ', table_name, ' cascade'),
				'; '
			) 
			FROM information_schema.tables 
			where table_catalog = current_database()
			and table_schema = 'public'
			and table_type = 'BASE TABLE'
			and table_name like('acorn_mofadala_%');


/*
SELECT concat('drop function ', n.nspname, '.', p.proname, '(', 
		(select string_agg((select typname from pg_type pa where pa.oid = unnest), ',') from unnest(p.proargtypes)),
	')', ' cascade', '; '
)
FROM pg_proc p
LEFT JOIN pg_namespace n ON p.pronamespace = n.oid
LEFT JOIN pg_type t ON t.oid = p.prorettype
WHERE n.nspname = 'public'
and p.proname like('fn_acorn_enrollment_%')
group by n.nspname, p.proname, p.proargtypes;
*/