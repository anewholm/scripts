-- create extension hostname;

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
