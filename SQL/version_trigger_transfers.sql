-- Add versioning columns to the table
alter table IF EXISTS public.transfers add column "version" bigint default 1 not null;
alter table IF EXISTS public.transfers add column is_current_version bool default true not null;
alter table IF EXISTS public.transfers ADD COLUMN created_at timestamp with time zone;
-- Change the primary key to include version
ALTER TABLE IF EXISTS public.transfers DROP CONSTRAINT IF EXISTS transfers_pkey;
ALTER TABLE IF EXISTS public.transfers ADD PRIMARY KEY (id, version);

CREATE OR REPLACE FUNCTION public.fn_transfers_version() 
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
begin
	if old.id != new.id then raise exception 'Cannot change id directly'; end if;
	if old.version != new.version then raise exception 'Cannot change version directly'; end if;
	if old.is_current_version != new.is_current_version then raise exception 'Cannot change is_current_version directly'; end if;

	if old.arrived_at is null and new.arrived_at is not null then
		-- We do not make new versions for completion of null fields
	else
		insert into public.transfers("id", source_address_id, destination_address_id, arrived_at, "version", is_current_version, created_at) 
		values(old.id, old.source_address_id, old.destination_address_id, old.arrived_at, old.version, false, old.created_at);
	
		new.version := old.version + 1;
		new.is_current_version := true;
		new.created_at = now();
	end if;
	
	return new;
end;
$BODY$;

CREATE OR REPLACE TRIGGER tr_transfers_version
    BEFORE UPDATE ON public.transfers
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_transfers_version()