-- DROP FUNCTION IF EXISTS public.fn_acorn_lojistiks_new_replicated_row();

CREATE OR REPLACE FUNCTION public.fn_acorn_lojistiks_new_replicated_row()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
declare
	domain varchar(1024);
	plugin_path varchar(1024);
	action varchar(2048);
	params varchar(2048);
	url varchar(2048);
	res public.http_response;
begin
	-- https://www.postgresql.org/docs/current/plpgsql-trigger.html
	domain = 'acorn-lojistiks.laptop';
	plugin_path = '/api';
	action = '/newrow';
	params = concat('TG_NAME=', TG_NAME, '&TG_OP=', TG_OP, '&TG_TABLE_SCHEMA=', TG_TABLE_SCHEMA, '&TG_TABLE_NAME=', TG_TABLE_NAME, '&ID=', new.id);
	url = concat('http://', domain, plugin_path, action, '?', params);

	res = public.http_get(url);
	new.response = concat(res.status, ' ', res.content);

	return new;
end;
$BODY$;

-- DROP TRIGGER tr_acorn_lojistiks_brands_new_replicated_row()
CREATE OR REPLACE TRIGGER tr_acorn_lojistiks_brands_new_replicated_row
    BEFORE INSERT
    ON public.acorn_lojistiks_brands
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_acorn_lojistiks_new_replicated_row();

-- Trigger on replpica also
ALTER TABLE IF EXISTS public.acorn_lojistiks_brands ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_brands_new_replicated_row;