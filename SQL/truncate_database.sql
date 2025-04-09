-- drop FUNCTION fn_acornassociated_lojistiks_truncate_database(_schema varchar(1024));

CREATE OR REPLACE FUNCTION fn_acornassociated_lojistiks_truncate_database(schema_like varchar(1024), table_like varchar(1024))
  RETURNS void
  LANGUAGE plpgsql AS
$BODY$
declare
	reset_query varchar(32596);
BEGIN
	reset_query = (SELECT 'TRUNCATE TABLE '
	       || string_agg(format('%I.%I', schemaname, tablename), ', ')
	       || ' CASCADE'
	   	FROM   pg_tables
	   	WHERE  schemaname like(schema_like)
		   AND tablename like(table_like)
   	);
	if not reset_query is null then
		execute reset_query;
	end if;
END
$BODY$;

