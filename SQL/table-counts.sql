-- drop function fn_acorn_lojistiks_table_counts(_schema varchar(1024));

CREATE OR REPLACE FUNCTION fn_acorn_university_table_counts(_schema varchar(1024))
  RETURNS table("table" text, "count" bigint)
  LANGUAGE plpgsql AS
$BODY$
BEGIN
	-- SELECT * FROM information_schema.tables;
  	return query execute (select concat(
		'select "table", "count" from (', 
		(
			SELECT string_agg(
				concat('select ''', table_name, ''' as "table", count(*) as "count" from ', table_name),
				' union all '
			) 
			FROM information_schema.tables 
			where table_catalog = current_database()
			and table_schema = _schema
			and table_type = 'BASE TABLE'
		), 
		') data order by "count" desc, "table" asc'
	));
END
$BODY$;

-- delete from system_event_logs;

select * from fn_acorn_university_table_counts('public')
-- where "table" like('acorn%')
order by "count" desc;

