CREATE EXTENSION IF NOT EXISTS hostname WITH SCHEMA public;

CREATE TABLE public.servers (
    id bigint NOT NULL,
    hostname character varying(1024) DEFAULT public.hostname() NOT NULL
);

CREATE SEQUENCE public.servers_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1 OWNED BY public.servers.id;
 ALTER TABLE ONLY public.servers ALTER COLUMN id SET DEFAULT nextval('public.servers_id_seq'::regclass);

CREATE OR REPLACE FUNCTION public.fn_server_id() 
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
	declare pid bigint;
begin
	select "id" into pid from servers where hostname = hostname();
	if pid is null then
		insert into servers(hostname) values(hostname());
		pid := currval('server_id');
	end if;
	new.created_by_server_id = pid;
	return new;
end;
$BODY$;

CREATE OR REPLACE TRIGGER tr_addresses_server_id
    BEFORE INSERT ON public.addresses
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_server_id()
