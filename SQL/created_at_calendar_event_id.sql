CREATE or replace FUNCTION public.fn_acorn_lojistiks_transfers_update_calendar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	event_name text;
begin
	if not new.created_at is null then
		-- Use the Calendar system
		select into event_name        concat('Transfer to ', coalesce(name, 'Unknown'))
			from public.acorn_lojistiks_locations
			where id = new.destination_location_id;
		update acorn_calendar_event_part 
			set name = event_name
			where event_id = new.created_at;
	end if;
	return new;
end;
$$;

CREATE or replace FUNCTION public.fn_acorn_lojistiks_transfers_delete_calendar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if not old.created_at is null then
		-- Use the Calendar system
		delete from acorn_calendar_event
			where id = old.created_at;
	end if;
	return old;
end;
$$;

CREATE or replace FUNCTION public.fn_acorn_lojistiks_transfers_insert_calendar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	event_id integer;
	event_name text;
	external_url varchar(2048);
begin
	-- Use the Calendar system
	select into event_name        concat('Transfer (', coalesce(name, 'Unknown'), ')')
		from public.acorn_lojistiks_locations
		where id = new.destination_location_id;
	external_url := concat('/backend/acorn/lojistiks/transfers/update/', new.id);
	insert into public.acorn_calendar_event(calendar_id, owner_user_id, owner_user_group_id, external_url) 
		values(1,1,1, external_url);
	event_id = currval('acorn_calendar_event_id_seq'::regclass);
	insert into public.acorn_calendar_event_part(event_id, "name", description, "start", "end", type_id) 
		values(event_id, event_name, '', now(), now(), 4);
	new.created_at = event_id;

	return new;
end;
$$;

CREATE or replace TRIGGER tr_acorn_lojistiks_transfers_insert_calendar BEFORE INSERT ON public.acorn_lojistiks_transfers 
FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_lojistiks_transfers_insert_calendar();

CREATE or replace TRIGGER tr_acorn_lojistiks_transfers_update_calendar BEFORE UPDATE ON public.acorn_lojistiks_transfers 
FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_lojistiks_transfers_update_calendar();

CREATE or replace TRIGGER tr_acorn_lojistiks_transfers_delete_calendar AFTER DELETE ON public.acorn_lojistiks_transfers 
FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_lojistiks_transfers_delete_calendar();
