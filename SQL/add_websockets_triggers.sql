-- DROP FUNCTION IF EXISTS public.fn_acornassociated_lojistiks_add_websockets_triggers(character varying, character varying);
CREATE OR REPLACE FUNCTION public.fn_acornassociated_lojistiks_add_websockets_triggers(
	schema character varying, table_prefix character varying)
    RETURNS void 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	-- SELECT * FROM information_schema.tables;
	-- This assumes that fn_acornassociated_lojistiks_new_replicated_row() exists
	-- Trigger on replpica also: ENABLE ALWAYS
  	execute (
			SELECT string_agg(concat(
				'ALTER TABLE IF EXISTS ', table_schema, '.', table_name, ' ADD COLUMN IF NOT EXISTS response text;',
				'CREATE OR REPLACE TRIGGER tr_', table_name, '_new_replicated_row
				    BEFORE INSERT
				    ON ', table_schema, '.', table_name, '
				    FOR EACH ROW
				    EXECUTE FUNCTION public.fn_acornassociated_lojistiks_new_replicated_row();',
				'ALTER TABLE IF EXISTS ', table_schema, '.', table_name, ' ENABLE ALWAYS TRIGGER tr_', table_name, '_new_replicated_row;'
			), ' ') 
			FROM information_schema.tables 
			where table_catalog = current_database()
			and table_schema like(schema)
			and table_name like(table_prefix)
			and table_type = 'BASE TABLE'
		);
END
$BODY$;

ALTER FUNCTION public.fn_acornassociated_lojistiks_add_websockets_triggers(character varying, character varying)
    OWNER TO acornlojistiks;

select fn_acornassociated_lojistiks_add_websockets_triggers('%', 'acornassociated_%')