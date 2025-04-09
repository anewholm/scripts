-- DROP FUNCTION IF EXISTS public.fn_acornassociated_lojistiks_replication_update_seq();

CREATE OR REPLACE FUNCTION public.fn_acornassociated_lojistiks_replication_update_seq()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
declare
	seq_name varchar(1024);
begin
	-- Get the associated sequence name
	SELECT into seq_name concat(PGT.schemaname, '.', S.relname)
		FROM pg_class AS S
			inner join pg_depend AS D on S.oid = D.objid
			inner join pg_class AS T on D.refobjid = T.oid
			inner join pg_attribute AS C on D.refobjid = C.attrelid and D.refobjsubid = C.attnum
			inner join pg_tables AS PGT on T.relname = PGT.tablename
		WHERE S.relkind = 'S'
			AND T.relname = TG_TABLE_NAME
			AND PGT.schemaname = TG_TABLE_SCHEMA;
	if new.id > pg_sequence_last_value(seq_name) then
		perform setval(seq_name, new.id);
	end if;
	
	return new;
end;
$BODY$;

-- DROP TRIGGER tr_acornassociated_lojistiks_replication_update_seq;
CREATE OR REPLACE TRIGGER tr_acornassociated_lojistiks_replication_update_brands_seq
    AFTER INSERT
    ON public.acornassociated_lojistiks_brands
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_acornassociated_lojistiks_replication_update_seq();

-- Trigger on replpica only
ALTER TABLE IF EXISTS public.acornassociated_lojistiks_brands ENABLE REPLICA TRIGGER tr_acornassociated_lojistiks_replication_update_brands_seq;