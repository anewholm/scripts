-- Versioning Function
CREATE OR REPLACE FUNCTION public.fn_acorn_lojistiks_addresses_version() 
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
begin
	-- For adding versioning columns to the table
	-- alter table IF EXISTS public.acorn_lojistiks_addresses add column "version" bigint default 1 not null;
	-- alter table IF EXISTS public.acorn_lojistiks_addresses add column is_current_version bool default true not null;
	-- alter table IF EXISTS public.acorn_lojistiks_addresses ADD COLUMN created_at timestamp with time zone default now();
	-- Change the primary key to include version
	-- ALTER TABLE IF EXISTS public.acorn_lojistiks_addresses DROP CONSTRAINT IF EXISTS addresses_pkey;
	-- ALTER TABLE IF EXISTS public.acorn_lojistiks_addresses ADD PRIMARY KEY (id, version);

	-- TODO: Translation
	if old.id != new.id then raise exception 'Cannot change id directly'; end if;
	if old.version != new.version then raise exception 'Cannot change version directly'; end if;
	if old.is_current_version != new.is_current_version then raise exception 'Cannot change is_current_version irectly'; end if;
	if not old.is_current_version then raise exception 'Can only change the current version'; end if;

	if old.number is null and not new.number is null then
		-- We do not make new versions for completion of null fields
	else
		-- Insert the new record instead
		-- TODO: Can we insert the row object directly here?
		new.version := new.version + 1;
		new.created_at = now();
		insert into public.acorn_lojistiks_addresses
			("id", "name", "number", "area_id", "gps_id", "version", is_current_version, created_at)
			values(new.id, new.name, new.number, new.area_id, new.gps_id, new.version, new.is_current_version, new.created_at);

		-- Switch, so we keep the old record
		new := old;
		new.is_current_version := false;
	end if;

	return new;
end;
$BODY$;

CREATE OR REPLACE TRIGGER tr_acorn_lojistiks_addresses_version
    BEFORE UPDATE ON public.acorn_lojistiks_addresses
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_acorn_lojistiks_addresses_version()
