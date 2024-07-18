-- Add versioning columns to the table
alter table IF EXISTS public.addresses add column "version" bigint default 1 not null;
alter table IF EXISTS public.addresses add column is_current_version bool default true not null;
alter table IF EXISTS public.addresses ADD COLUMN created_at timestamp with time zone;
-- Change the primary key to include version
ALTER TABLE IF EXISTS public.addresses DROP CONSTRAINT IF EXISTS addresses_pkey;
ALTER TABLE IF EXISTS public.addresses ADD PRIMARY KEY (id, version);

CREATE OR REPLACE FUNCTION public.fn_addresses_version() 
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
begin
	if old.id != new.id then raise exception 'Cannot change id directly'; end if;
	if old.version != new.version then raise exception 'Cannot change version directly'; end if;
	if old.is_current_version != new.is_current_version then raise exception 'Cannot change is_current_version directly'; end if;
	
	insert into public.addresses("id", "name", "version", is_current_version, created_at) values(old.id, old.name, old.version, false, old.created_at);
	
	new.version := old.version + 1;
	new.is_current_version := true;
	new.created_at = now();
	
	return new;
end;
$BODY$;

CREATE OR REPLACE TRIGGER tr_addresses_version
    BEFORE UPDATE ON public.addresses
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_addresses_version()