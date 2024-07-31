CREATE EXTENSION IF NOT EXISTS hostname WITH SCHEMA public;

CREATE SEQUENCE IF NOT EXISTS public.acorn_lojistiks_servers_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE TABLE IF NOT EXISTS public.acorn_lojistiks_servers (
    id bigint NOT NULL default nextval('public.acorn_lojistiks_servers_id_seq'::regclass),
    hostname character varying(1024) DEFAULT public.hostname() NOT NULL
);

CREATE OR REPLACE FUNCTION public.fn_acorn_lojistiks_server_id() 
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
	declare pid bigint;
begin
	select "id" into pid from acorn_lojistiks_servers where hostname = hostname();
	if pid is null then
		insert into acorn_lojistiks_servers(hostname) values(hostname());
		pid := currval('acorn_lojistiks_servers_id_seq');
	end if;
	new.server_id = pid;
	return new;
end;
$BODY$;

CREATE OR REPLACE TRIGGER tr_acorn_lojistiks_addresses_server_id BEFORE INSERT ON public.acorn_lojistiks_addresses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_lojistiks_server_id();
