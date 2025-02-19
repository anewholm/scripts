CREATE EXTENSION IF NOT EXISTS hostname WITH SCHEMA public;

CREATE TABLE IF NOT EXISTS public.acornassociated_lojistiks_servers (
    id uuid NOT NULL default gen_random_uuid(),
    hostname character varying(1024) DEFAULT public.hostname() NOT NULL
);

CREATE OR REPLACE FUNCTION public.fn_acornassociated_lojistiks_server_id() 
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
	declare pid uuid;
begin
	-- We do not trigger on replicated rows
	-- that already have a server_id set
	if new.server_id is null then
		select "id" into pid from acornassociated_lojistiks_servers where hostname = hostname();
		if pid is null then
			insert into acornassociated_lojistiks_servers(hostname) values(hostname()) returning id as pid;
		end if;
		new.server_id = pid;
	end if;
	return new;
end;
$BODY$;

-- Example: CREATE OR REPLACE TRIGGER tr_acornassociated_lojistiks_addresses_server_id BEFORE INSERT ON public.acornassociated_lojistiks_addresses FOR EACH ROW EXECUTE FUNCTION public.fn_acornassociated_lojistiks_server_id();
