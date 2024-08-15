-- drop function fn_acorn_lojistiks_reset_sequences(_schema varchar(1024));

CREATE OR REPLACE FUNCTION fn_acorn_lojistiks_reset_sequences(schema_like varchar(1024), table_like varchar(1024))
  RETURNS void
  LANGUAGE plpgsql AS
$BODY$
declare
	reset_query varchar(32596);
BEGIN
  	reset_query = (SELECT string_agg(
		  		concat('SELECT SETVAL(''',
				PGT.schemaname, '.', S.relname,
				''', COALESCE(MAX(', C.attname, '), 1) ) FROM ',
				PGT.schemaname, '.', T.relname, ';'), 
			'')
		FROM pg_class AS S,
			pg_depend AS D,
			pg_class AS T,
			pg_attribute AS C,
			pg_tables AS PGT
		WHERE S.relkind = 'S'
			AND S.oid = D.objid
			AND D.refobjid = T.oid
			AND D.refobjid = C.attrelid
			AND D.refobjsubid = C.attnum
			AND T.relname = PGT.tablename
			AND PGT.schemaname = like(schema_like)
			AND T.relname like(table_like)
	);
	if not reset_query is null then
		execute reset_query;
	end if;
END
$BODY$;

select fn_acorn_lojistiks_reset_sequences('public', 'acorn_%');
select fn_acorn_lojistiks_reset_sequences('product', 'acorn_%');
--SELECT concat(sequence_schema::text, '.', sequence_name::text) as sequence, currval(concat(sequence_schema::text, '.', sequence_name::text)::regclass) as currval FROM information_schema.sequences ORDER BY sequence_schema, sequence_name;
