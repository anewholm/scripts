--
-- PostgreSQL database dump
--

-- Dumped from database version 16.7 (Ubuntu 16.7-1.pgdg24.04+1)
-- Dumped by pg_dump version 16.7 (Ubuntu 16.7-1.pgdg24.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: product; Type: SCHEMA; Schema: -; Owner: justice
--

CREATE SCHEMA product;


ALTER SCHEMA product OWNER TO justice;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: justice
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO justice;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: justice
--

COMMENT ON SCHEMA public IS '';


--
-- Name: cube; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS cube WITH SCHEMA public;


--
-- Name: EXTENSION cube; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION cube IS 'data type for multidimensional cubes';


--
-- Name: earthdistance; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS earthdistance WITH SCHEMA public;


--
-- Name: EXTENSION earthdistance; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION earthdistance IS 'calculate great-circle distances on the surface of the Earth';


--
-- Name: hostname; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hostname WITH SCHEMA public;


--
-- Name: EXTENSION hostname; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hostname IS 'Get the server host name';


--
-- Name: http; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA public;


--
-- Name: EXTENSION http; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION http IS 'HTTP client for PostgreSQL, allows web page retrieval inside the database.';


--
-- Name: fn_acorn_add_websockets_triggers(character varying, character varying); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
            
            begin
        -- SELECT * FROM information_schema.tables;
        -- This assumes that fn_acorn_new_replicated_row() exists
        -- Trigger on replpica also: ENABLE ALWAYS
        execute (
          SELECT string_agg(concat(
            'ALTER TABLE IF EXISTS ', table_schema, '.', table_name, ' ADD COLUMN IF NOT EXISTS response text;',
            'CREATE OR REPLACE TRIGGER tr_', table_name, '_new_replicated_row
                BEFORE INSERT
                ON ', table_schema, '.', table_name, '
                FOR EACH ROW
                EXECUTE FUNCTION public.fn_acorn_new_replicated_row();',
            'ALTER TABLE IF EXISTS ', table_schema, '.', table_name, ' ENABLE ALWAYS TRIGGER tr_', table_name, '_new_replicated_row;'
          ), ' ')
          FROM information_schema.tables
          where table_catalog = current_database()
          and table_schema like(schema)
          and table_name like(table_prefix)
          and table_type = 'BASE TABLE'
        );
end;
            $$;


ALTER FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) OWNER TO justice;

--
-- Name: fn_acorn_calendar_create_activity_log_event(character varying, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_calendar_create_activity_log_event(type character varying, user_id uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
declare 
	owner_user_id uuid;
	title character varying(1024);
	calendar_id uuid;
	event_type_id uuid;
	event_status_id uuid;
	new_event_id uuid;
begin
	-- Calendar (system): acorn.justice::lang.plugin.activity_log
	calendar_id   := 'f3bc49bc-eac7-11ef-9e4a-1740a039dada';
	title         := initcap(replace(type, '_', ' '));
	owner_user_id := user_id;

	select into event_status_id id from public.acorn_calendar_event_statuses limit 1;
	insert into public.acorn_calendar_event_types(name, colour, style) values('Create', '#091386', 'color:#fff') returning id into event_type_id;

	insert into public.acorn_calendar_events(calendar_id, owner_user_id) values(calendar_id, owner_user_id) returning id into new_event_id;
	insert into public.acorn_calendar_event_parts(event_id, type_id, status_id, name, start, "end") 
		values(new_event_id, event_type_id, event_status_id, concat(title, ' ', 'Create'), now(), now());

	return new_event_id;
end;
$$;


ALTER FUNCTION public.fn_acorn_calendar_create_activity_log_event(type character varying, user_id uuid) OWNER TO justice;

--
-- Name: fn_acorn_calendar_events_generate_event_instances(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_calendar_events_generate_event_instances() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	return public.fn_acorn_calendar_generate_event_instances(NEW, OLD);
end;
$$;


ALTER FUNCTION public.fn_acorn_calendar_events_generate_event_instances() OWNER TO justice;

--
-- Name: fn_acorn_calendar_generate_event_instances(record, record); Type: FUNCTION; Schema: public; Owner: sz
--

CREATE FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) RETURNS record
    LANGUAGE plpgsql
    AS $$
declare
	days_before interval;
	days_after interval;
	days_count int;
	today date := now();
	date_start date;
begin
	-- This function creates the individual event instances on specific dates
	-- from event definitions, that can have preiodic repetition
	-- For example, an single event definition that repeats weekly for 2 months
	-- may have 9 individual event instances on specific dates
	-- Declares are configurable from WinterCMS settings

	-- Check if anything repeaty has changed (not locked_by_user_id)
	if     old_event_part is null
		or new_event_part.start  is distinct from old_event_part.start
		or new_event_part."end"  is distinct from old_event_part."end"
		or new_event_part.until  is distinct from old_event_part.until
		or new_event_part.mask   is distinct from old_event_part.mask
		or new_event_part.repeat is distinct from old_event_part.repeat
		or new_event_part.mask_type is distinct from old_event_part.mask_type
		or new_event_part.repeat_frequency     is distinct from old_event_part.repeat_frequency
		or new_event_part.parent_event_part_id is distinct from old_event_part.parent_event_part_id
		or new_event_part.instances_deleted    is distinct from old_event_part.instances_deleted
	then
		-- Settings
		select coalesce((select substring("value" from '"days_before":"([^"]+)"')
			from system_settings where item = 'acorn_calendar_settings'), '1 year')
			into days_before;
		select coalesce((select substring("value" from '"days_after":"([^"]+)"')
			from system_settings where item = 'acorn_calendar_settings'), '2 years')
			into days_after;
		select extract('epoch' from days_before + days_after)/3600/24.0
			into days_count;
		select today - days_before
			into date_start;

		-- For updates (id cannot change)
		delete from acorn_calendar_instances where event_part_id = new_event_part.id;
		-- TODO: use a sub-ID also for created_at, updated_at etc.

		-- For inserts
		insert into acorn_calendar_instances("date", event_part_id, instance_start, instance_end, instance_num)
		select date_start + interval '1' day * gs as "date", ev.*
		from generate_series(0, days_count) as gs
		inner join (
			-- single event
			select new_event_part.id as event_part_id,
				new_event_part."start" as "instance_start",
				new_event_part."end"   as "instance_end",
				0 as instance_num
			where new_event_part.repeat is null
		union all
			-- repetition, no parent container
			select new_event_part.id as event_part_id,
				new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs as "instance_start",
				new_event_part."end" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs   as "instance_end",
				gs.gs as instance_num
			from generate_series(0, days_count) as gs
			where not new_event_part.repeat is null and new_event_part.parent_event_part_id is null
			and (new_event_part.instances_deleted is null or not gs.gs = any(new_event_part.instances_deleted))
			and (new_event_part.until is null or new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs < new_event_part.until)
			and (new_event_part.mask = 0 or new_event_part.mask & (2^date_part(new_event_part.mask_type, new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs))::int != 0)
		union all
			-- repetition with parent_event_part_id container calendar events
			select new_event_part.id as event_part_id,
				new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs as "instance_start",
				new_event_part."end" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs   as "instance_end",
				gs.gs as instance_num
			from generate_series(0, days_count) as gs
			inner join acorn_calendar_instances pcc on new_event_part.parent_event_part_id = pcc.event_part_id
				and (pcc.date, pcc.date + 1)
				overlaps (new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs, new_event_part."end" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs)
			where not new_event_part.repeat is null
			and (new_event_part.instances_deleted is null or not gs.gs = any(new_event_part.instances_deleted))
			and (new_event_part.until is null or new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs < new_event_part.until)
			and (new_event_part.mask = 0 or new_event_part.mask & (2^date_part(new_event_part.mask_type, new_event_part."start" + new_event_part.repeat_frequency * new_event_part."repeat" * gs.gs))::int != 0)
		) ev
		on  (date_start + interval '1' day * gs, date_start + interval '1' day * (gs+1))
		overlaps (ev.instance_start, ev.instance_end);

		-- Recursively update child event parts
		-- TODO: This could infinetly cycle
		update acorn_calendar_event_parts set id = id
			where parent_event_part_id = new_event_part.id
			and not id = new_event_part.id;
	end if;

	return new_event_part;
end;
            
$$;


ALTER FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) OWNER TO sz;

--
-- Name: fn_acorn_calendar_is_date(character varying, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp with time zone) RETURNS timestamp with time zone
    LANGUAGE plpgsql
    AS $$
            
            begin

                if s is null then
                    return d;
                end if;
                perform s::timestamp with time zone;
                    return s;
                exception when others then
                    return d;
            
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp with time zone) OWNER TO justice;

--
-- Name: fn_acorn_calendar_seed(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_calendar_seed() RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
            -- Default calendar, with hardcoded id
            if not exists(select * from acorn_calendar_calendars where "id" = 'ceea8856-e4c8-11ef-8719-5f58c97885a2'::uuid) then
                insert into acorn_calendar_calendars(id, "name", "system") 
                    values('ceea8856-e4c8-11ef-8719-5f58c97885a2'::uuid, 'Default', true);
            end if;

            -- System Statuses. Cannot be deleted
            if not exists(select * from acorn_calendar_event_statuses where "id" = '27446472-e4c9-11ef-bde0-9b663c96a619'::uuid) then
                insert into acorn_calendar_event_statuses(id, "name", "system") 
                    values('27446472-e4c9-11ef-bde0-9b663c96a619'::uuid, 'Normal', TRUE);
            end if;
            if not exists(select * from acorn_calendar_event_statuses where "id" = 'fb2392de-e62e-11ef-b202-5fe79ff1071f') then
                insert into acorn_calendar_event_statuses(id, "name", "system", "style") 
                    values('fb2392de-e62e-11ef-b202-5fe79ff1071f', 'Cancelled', TRUE, 'text-decoration:line-through;border:1px dotted #fff;');
            end if;
            if not exists(select * from acorn_calendar_event_statuses where "name" = 'Tentative') then
                insert into acorn_calendar_event_statuses("name", "system", "style") 
                    values('Tentative', TRUE, 'opacity:0.7;');
            end if;
            -- TODO: Does status "Conflict" make sense? Because maybe only 1 instance will conflict
            if not exists(select * from acorn_calendar_event_statuses where "name" = 'Conflict') then
                insert into acorn_calendar_event_statuses("name", "system", "style") 
                    values('Conflict', TRUE, 'border:1px solid red;background-color:#fff;color:#000;font-weight:bold;');
            end if;

            -- System Types. Cannot be deleted
            if not exists(select * from acorn_calendar_event_types where "id" = '2f766546-e4c9-11ef-be8c-1f2daa98a10f'::uuid) then
                insert into acorn_calendar_event_types(id, "name", "system", "colour", "style") 
                    values('2f766546-e4c9-11ef-be8c-1f2daa98a10f'::uuid, 'Normal', TRUE, '#091386', 'color:#fff');
            end if;
            if not exists(select * from acorn_calendar_event_types where "name" = 'Meeting') then
                insert into acorn_calendar_event_types("name", "system", "colour", "style") 
                    values('Meeting', TRUE, '#C0392B', 'color:#fff');
            end if;
end;
$$;


ALTER FUNCTION public.fn_acorn_calendar_seed() OWNER TO justice;

--
-- Name: fn_acorn_calendar_trigger_created_at_event(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_calendar_trigger_created_at_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare 
	name_optional character varying(2048);
	soft_delete_optional boolean = false;

	table_comment character varying(2048);
	table_title character varying(1024);
	title character varying(1024);
	event_time timestamp = now();
	owner_user_id uuid;
	calendar_id uuid;
	new_event_id uuid;
	event_type_id uuid;
	event_status_id uuid;
begin
	-- This trigger function should only be used on final content tables
	-- This is a generic trigger. Some fields are required, others optional
	-- We use PG system catalogs because they are faster
	-- TODO: Process name-object linkage
	
	-- Required fields
	-- created_at_event_id
	-- updated_at_event_id
	owner_user_id := NEW.created_by_user_id; -- NOT NULL
	table_title   := replace(replace(TG_TABLE_NAME, 'acorn_', ''), '_', ' ');
	title         := TG_OP || ' ' || table_title;

	-- Optional fields
	if exists(SELECT * FROM pg_attribute WHERE attrelid = TG_RELID AND attname = 'name') then name_optional := NEW.name; end if;
	if not name_optional is null then title = title || ':' || name_optional; end if;
	if exists(SELECT * FROM pg_attribute WHERE attrelid = TG_RELID AND attname = 'deleted_at') then soft_delete_optional := true; end if;

	-- TODO: Allow control from the table comment over event creation
	table_comment := obj_description(concat(TG_TABLE_SCHEMA, '.', TG_TABLE_NAME)::regclass, 'pg_class');

	-- Calendar (system): acorn.justice::lang.plugin.activity_log
	calendar_id   := 'f3bc49bc-eac7-11ef-9e4a-1740a039dada';
	
	-- Type: lang TG_TABLE_SCHEMA.TG_TABLE_NAME, acorn.justice::lang.models.related_events.label
	select into event_type_id id from acorn_calendar_event_types where activity_log_related_oid = TG_RELID;
	if event_type_id is null then
		-- TODO: Colour?
		-- TODO: acorn.?::lang.models.?.label
		insert into public.acorn_calendar_event_types(name, activity_log_related_oid) values(table_title, TG_RELID) returning id into event_type_id;
	end if;

	-- Scenarios
	case 
		when TG_OP = 'INSERT' then
			-- Just in case the framework has specified it
			if NEW.created_at_event_id is null then
				-- Create event
				event_status_id := '7b432540-eac8-11ef-a9bc-434841a9f67b'; -- INSERT
				insert into public.acorn_calendar_events(calendar_id, owner_user_id) values(calendar_id, owner_user_id) returning id into new_event_id;
				insert into public.acorn_calendar_event_parts(event_id, type_id, status_id, name, start, "end") 
					values(new_event_id, event_type_id, event_status_id, title, event_time, event_time);
				NEW.created_at_event_id = new_event_id;
			end if;
		when TG_OP = 'UPDATE' then 
			event_status_id := '7c18bb7e-eac8-11ef-b4f2-ffae3296f461'; -- UPDATE
			if soft_delete_optional then
				if not NEW.deleted_at = OLD.deleted_at then
					case
						when not NEW.deleted_at is null then event_status_id := '7ceca4c0-eac8-11ef-b685-f7f3f278f676'; -- Soft DELETE
						else                                 event_status_id := 'f9690600-eac9-11ef-8002-5b2cbe0c12c0'; -- Soft un-DELETE
					end case;
				end if;
			end if;
			
			if NEW.updated_at_event_id is null then
				-- Update event
				insert into public.acorn_calendar_events(calendar_id, owner_user_id) values(calendar_id, owner_user_id) returning id into new_event_id;
				insert into public.acorn_calendar_event_parts(event_id, type_id, status_id, name, start, "end") 
					values(new_event_id, event_type_id, event_status_id, title, event_time, event_time);
				NEW.updated_at_event_id = new_event_id;
			else
				update public.acorn_calendar_event_parts set 
					"start"   = event_time, 
					"end"     = event_time,
					status_id = event_status_id,
					"name"    = title
					where event_id = NEW.updated_at_event_id;
			end if;
	end case;

	return NEW;
end;
$$;


ALTER FUNCTION public.fn_acorn_calendar_trigger_created_at_event() OWNER TO justice;

--
-- Name: fn_acorn_criminal_action_legalcase_defendants_cw(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(p_id uuid, p_user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
	justice_legalcase_id uuid;
	warrant_type_id uuid;
begin
	-- Create Warrant
	select into justice_legalcase_id cl.legalcase_id 
		from public.acorn_criminal_legalcases cl
		inner join public.acorn_criminal_legalcase_defendants ld on cl.id = ld.legalcase_id
		where ld.id = p_id;
	select into warrant_type_id id from public.acorn_justice_warrant_types limit 1;
	
	insert into public.acorn_justice_warrants(user_id, created_by_user_id, warrant_type_id, legalcase_id)
		select user_id,
			p_user_id,
			warrant_type_id,
			justice_legalcase_id
		from public.acorn_criminal_legalcase_defendants
		where id = p_id;
end;
$$;


ALTER FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(p_id uuid, p_user_id uuid) OWNER TO justice;

--
-- Name: FUNCTION fn_acorn_criminal_action_legalcase_defendants_cw(p_id uuid, p_user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(p_id uuid, p_user_id uuid) IS 'labels:
  en: Create Warrant';


--
-- Name: fn_acorn_criminal_action_legalcase_related_events_can(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	update public.acorn_calendar_event_parts
		set status_id = 'fb2392de-e62e-11ef-b202-5fe79ff1071f'
		where event_id = (select event_id from public.acorn_criminal_legalcase_related_events re where re.id = primary_id);
end;
$$;


ALTER FUNCTION public.fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid) OWNER TO justice;

--
-- Name: FUNCTION fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid) IS 'labels:
  en: Cancel';


--
-- Name: fn_acorn_criminal_action_legalcases_transfer_case(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
declare
	creator_user_id uuid = user_id;
	justice_legalcase_id uuid;
	new_justice_legalcase_id uuid;
	new_criminal_legalcase_id uuid;
	new_owner_user_group_id uuid = owner_user_group_id;
begin
	select into justice_legalcase_id legalcase_id from public.acorn_criminal_legalcases where id = model_id;
	
	-- Main legalcase & 1-1 records
	insert into public.acorn_justice_legalcases(created_by_user_id, name, description, owner_user_group_id)
		select creator_user_id, 'TBD', description, new_owner_user_group_id 
		from public.acorn_justice_legalcases 
		where id = justice_legalcase_id
		returning id into new_justice_legalcase_id;
	insert into public.acorn_criminal_legalcases(legalcase_id, judge_committee_user_group_id, legalcase_type_id)
		select new_justice_legalcase_id, judge_committee_user_group_id, legalcase_type_id
		from public.acorn_criminal_legalcases 
		where id = model_id
		returning id into new_criminal_legalcase_id;

	-- People
	insert into public.acorn_criminal_legalcase_defendants(created_by_user_id, legalcase_id, user_id) 
		select creator_user_id, new_criminal_legalcase_id, t.user_id from public.acorn_criminal_legalcase_defendants t where legalcase_id = model_id;
	insert into public.acorn_criminal_legalcase_witnesses(created_by_user_id, legalcase_id, user_id) 
		select creator_user_id, new_criminal_legalcase_id, t.user_id from public.acorn_criminal_legalcase_witnesses t where legalcase_id = model_id;
	insert into public.acorn_criminal_legalcase_plaintiffs(created_by_user_id, legalcase_id, user_id) 
		select creator_user_id, new_criminal_legalcase_id, t.user_id from public.acorn_criminal_legalcase_plaintiffs t where legalcase_id = model_id;
	-- insert into public.acorn_criminal_legalcase_prosecutors(legalcase_id) 
	-- 	select new_criminal_legalcase_id from public.acorn_criminal_legalcase_defendants where legalcase_id = model_id;

	-- Other
	-- insert into public.acorn_criminal_legalcase_evidence(legalcase_id) 
	-- 	select new_criminal_legalcase_id from public.acorn_criminal_legalcase_defendants where legalcase_id = model_id;

	return new_criminal_legalcase_id;
end;
$$;


ALTER FUNCTION public.fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid) OWNER TO justice;

--
-- Name: FUNCTION fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid) IS 'labels:
  en: Transfer Case
result-action: model-uuid-redirect
condition: not id is null';


--
-- Name: fn_acorn_first(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_first(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
            
            SELECT $1;
            $_$;


ALTER FUNCTION public.fn_acorn_first(anyelement, anyelement) OWNER TO justice;

--
-- Name: fn_acorn_justice_action_legalcases_close_case(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	update public.acorn_justice_legalcases 
		set closed_at_event_id = public.fn_acorn_calendar_create_activity_log_event('close_case', user_id)
		where id = model_id;
end;
$$;


ALTER FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) OWNER TO justice;

--
-- Name: FUNCTION fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) IS 'labels:
  en: Close Case
  ku: Bigre Sicil
condition: closed_at_event_id is null';


--
-- Name: fn_acorn_justice_action_legalcases_reopen_case(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	update public.acorn_justice_legalcases 
		set closed_at_event_id = NULL
		where id = model_id;
end;
$$;


ALTER FUNCTION public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) OWNER TO justice;

--
-- Name: FUNCTION fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) IS 'labels:
  en: Re-open Case
  ku: Vekrî Sicil
condition: not closed_at_event_id is null';


--
-- Name: fn_acorn_justice_action_warrants_revoke(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	update public.acorn_justice_warrants
		set revoked_at_event_id = public.fn_acorn_calendar_create_activity_log_event('revoke_warrant', p_user_id)
		where id = model_id;
end;
$$;


ALTER FUNCTION public.fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) OWNER TO justice;

--
-- Name: FUNCTION fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) IS 'labels:
  en: Revoke
  ku: Bigre
condition: revoked_at_event_id is null';


--
-- Name: fn_acorn_justice_seed_calendar(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_justice_seed_calendar() RETURNS void
    LANGUAGE plpgsql
    AS $$
declare 
begin
	-- ###################################################### Calendar
	-- TODO: Hardcoded system Calendars, Types and Statuses 
	-- for the acorn_calendar_database_event_instances view
	if not exists(select * from public.acorn_calendar_calendars where id='6faa432c-e3b5-11ef-ac7d-af7a8110175c') then
		insert into public.acorn_calendar(id, name) 
			values('6faa432c-e3b5-11ef-ac7d-af7a8110175c', 'Entity create and update events');
	end if;
	if not exists(select * from public.acorn_calendar_event_statuses where id='c4c3a3d0-e3b5-11ef-98b6-83c560e3d98a') then
		insert into public.acorn_calendar_event_statuses(id, name, style) 
			values('c4c3a3d0-e3b5-11ef-98b6-83c560e3d98a', 'Created', 'color:#050');
	end if;
	if not exists(select * from public.acorn_calendar_event_statuses where id='cb75aa34-e3b5-11ef-abf2-a7e3fb05f16a') then
		insert into public.acorn_calendar_event_statuses(id, name, style) 
			values('cb75aa34-e3b5-11ef-abf2-a7e3fb05f16a', 'Updated', 'color:#005');
	end if;
	-- tables
	if not exists(select * from public.acorn_calendar_event_types where id='7754c714-e3b5-11ef-84f2-2bd5b1a61b38') then
		insert into public.acorn_calendar_event_types(id, name, colour, style) 
			values('7754c714-e3b5-11ef-84f2-2bd5b1a61b38', 'Criminal Legalcase Related Events', '#dfdfdf', '');
	end if;
end;
$$;


ALTER FUNCTION public.fn_acorn_justice_seed_calendar() OWNER TO justice;

--
-- Name: fn_acorn_justice_seed_groups(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_justice_seed_groups() RETURNS void
    LANGUAGE plpgsql
    AS $$
declare 
	parent_id uuid;
	usergroup_id uuid;
begin
	-- ###################################################### Calendar
	-- TODO: Hardcoded system Calendars, Types and Statuses 
	-- for the acorn_calendar_database_event_instances view

	-- ###################################################### Groups
	if not exists(select * from public.acorn_user_user_groups where name like('%Encumena Dadgeriya%')) then
		insert into public.acorn_user_user_groups(name, parent_user_group_id)
			values('Encumena Dadgeriya Civakî ya Rêveberiya Xweser Li Bakur û Rojhilatê Sûriyê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
			values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"ايروس قزشو لامشل ةيتاذلا ةرادلإا يف ةيعامتجلاا ةلادعلا سلجم"}');
		
		insert into acorn_user_user_groups(name, parent_user_group_id)
			values('Encumena Jinê a Dadgeriya Civakî Ya Rêveberiya Xweser Li Bakur û Rojhilatê Sûriyê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
			values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"ايرىس قزشو لامشن تيتاذنا ةرادلإا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}');
		
		insert into acorn_user_user_groups(name, parent_user_group_id)
			values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Cizîrê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
			values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');
		
		insert into acorn_user_user_groups(name, parent_user_group_id)
			values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Reqayê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
			values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"تقزنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');
		
		insert into acorn_user_user_groups(name, parent_user_group_id)
			values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Feratê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
			values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"ثازفنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');
		
		insert into acorn_user_user_groups(name, parent_user_group_id)
			values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Dêra Zorê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
			values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"روشنا زيد يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');
		
		insert into acorn_user_user_groups(name, parent_user_group_id)
			values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Munbicê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
			values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"جبنم يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');
		
		insert into acorn_user_user_groups(name, parent_user_group_id)
			values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Efrînê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
			values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"هيزفع يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');
		
		insert into acorn_user_user_groups(name, parent_user_group_id)
			values('Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Tebqê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
			values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"تقبطنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}');
		
		insert into acorn_user_user_groups(name, parent_user_group_id)
			values('Encumena Jinê Ya Dadgeriya Civakî Li Cizîrê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
			values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}');
		
		insert into acorn_user_user_groups(name, parent_user_group_id)
			values('Encumena Dadgeriya Civakî Li Cizîrê, ji van beşan pêk tê', parent_id) returning id into usergroup_id;
		insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
			values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"هم فنأتي ،ةزيشجنا يف تيعامتجلاا تنادعنا سهجم"}');
		
			parent_id := usergroup_id;
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Serokatiya Encumenê', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"سهجمنا تسائر"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Komîteya Cêgratiyan', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"ثابايننا تنجن"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Komîteya Çavnêrî Ya Dadwerî', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"يئاضقنا شيتفتنا تنجن"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Komîteya Aştbûnê', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"حهصنا تنجن"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Komîteya Bi cihanînê', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"ذيفنتنا تنجن"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Nivîsgeha Darayî û Rêveberî', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"يرادلإاو ينامنا بتكمنا"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Dîwan û Cêgratiyên girêdayî Encumena Dadageriya Civakî li Cizîrê', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"ةزيشجنا يف تيعامتجلاا تنادعنا سهجمن تعباتنا ثاباينناو هيواودنا"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Qamişlo', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"ىهشماق يف تيعامتجلاا تنادعنا ناىيد"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Hesîça', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"تكسحنا يف تيعامتجلاا تنادعنا ناىيد"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Tirbespiyê', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"هيبسبزت يف تيعامتجلاا تنادعنا ناىيد"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Derbasiyê', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"هيسابرد يف تيعامتجلاا تنادعنا ناىيد"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Amûdê', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"ادىماع يف تيعامتجلاا تنادعنا ناىيد"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Til Temir', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"زمت مت يف تيعامتجلاا تنادعنا ناىيد"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Şedadê', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"يدادشنا يف تيعامتجلاا تنادعنا ناىيد"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Girkê Legê', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"يكن يكزك يف تيعامتجلاا تنادعنا ناىيد"}');
	
			insert into acorn_user_user_groups(name, parent_user_group_id)
				values('Dîwana Dadgeriya Civakî li Dêrikê', parent_id) returning id into usergroup_id;
			insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
				values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"كزيد يف تيعامتجلاا تنادعنا ناىيد"}');
		
				parent_id := usergroup_id;
				insert into acorn_user_user_groups(name, parent_user_group_id)
					values('Cêgratiya Giştî li Zerganê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
					values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"ناكرس يف تماعنا تبايننا"}');
	
				insert into acorn_user_user_groups(name, parent_user_group_id)
					values('Cêgratiya Giştî li Til Birakê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
					values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"كازب مت يف تماعنا تبايننا"}');
	
				insert into acorn_user_user_groups(name, parent_user_group_id)
					values('Cêgratiya Giştî li Holê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
					values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"لىهنا يف تماعنا تبايننا"}');
	
				insert into acorn_user_user_groups(name, parent_user_group_id)
					values('Cêgratiya Giştî li Til Hemîsê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
					values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"سيمح مت يف تماعنا تبايننا"}');
	
				insert into acorn_user_user_groups(name, parent_user_group_id)
					values('Cêgratiya Giştî li Çelaxa', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
					values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"اغآ مج يف تماعنا تبايننا"}');
	
				insert into acorn_user_user_groups(name, parent_user_group_id)
					values('Cêgratiya Giştî li Til Koçerê', parent_id) returning id into usergroup_id;
				insert into public.winter_translate_attributes(locale, model_id, model_type, attribute_data)
					values('ar', usergroup_id, 'Acorn\User\Models\UserGroup', '{"name":"زجىك مت يف تماعنا تبايننا"}');
	end if;
end;
$$;


ALTER FUNCTION public.fn_acorn_justice_seed_groups() OWNER TO justice;

--
-- Name: fn_acorn_justice_update_name_identifier(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_justice_update_name_identifier() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if old.name != new.name then
		insert into public.acorn_justice_legalcase_identifiers(legalcase_id, "name", created_by_user_id)
			values(new.id, old.name, public.fn_acorn_user_get_seed_user());
	end if;
	return new;
end;
$$;


ALTER FUNCTION public.fn_acorn_justice_update_name_identifier() OWNER TO justice;

--
-- Name: fn_acorn_last(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_last(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
            
            SELECT $2;
            $_$;


ALTER FUNCTION public.fn_acorn_last(anyelement, anyelement) OWNER TO justice;

--
-- Name: fn_acorn_lojistiks_distance(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_acorn_lojistiks_distance(source_location_id uuid, destination_location_id uuid) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
begin
	return (select point(sg.longitude, sg.latitude) <@> point(dg.longitude, dg.latitude)
		from public.acorn_lojistiks_locations sl
		inner join public.acorn_lojistiks_addresses sa on sl.address_id = sa.id
		inner join public.acorn_lojistiks_gps sg on sa.gps_id = sg.id,
		
		public.acorn_lojistiks_locations dl
		inner join public.acorn_lojistiks_addresses da on dl.address_id = da.id
		inner join public.acorn_lojistiks_gps dg on da.gps_id = dg.id
		
		where sl.id = source_location_id
		and dl.id = destination_location_id
	) * 1.609344; -- Miles to KM
end;
$$;


ALTER FUNCTION public.fn_acorn_lojistiks_distance(source_location_id uuid, destination_location_id uuid) OWNER TO postgres;

--
-- Name: fn_acorn_lojistiks_is_date(character varying, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_acorn_lojistiks_is_date(s character varying, d timestamp with time zone) RETURNS timestamp with time zone
    LANGUAGE plpgsql
    AS $$
            begin
                
                if s is null then
                    return d;
                end if;
                perform s::timestamp with time zone;
                    return s;
                exception when others then
                    return d;
            
            end;
            $$;


ALTER FUNCTION public.fn_acorn_lojistiks_is_date(s character varying, d timestamp with time zone) OWNER TO postgres;

--
-- Name: fn_acorn_new_replicated_row(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_new_replicated_row() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            declare
server_domain varchar(1024);
plugin_path varchar(1024);
action varchar(2048);
params varchar(2048);
url varchar(2048);
res public.http_response;
            begin
            -- https://www.postgresql.org/docs/current/plpgsql-trigger.html
			select "domain" into server_domain from acorn_servers where hostname = hostname();
			if server_domain is null then
				new.response = 'No domain specified';
			else
	            plugin_path = '/api';
	            action = '/datachange';
	            params = concat('TG_NAME=', TG_NAME, '&TG_OP=', TG_OP, '&TG_TABLE_SCHEMA=', TG_TABLE_SCHEMA, '&TG_TABLE_NAME=', TG_TABLE_NAME, '&ID=', new.id);
	            url = concat('http://', server_domain, plugin_path, action, '?', params);
	
	            res = public.http_get(url);
	            new.response = concat(res.status, ' ', res.content);
			end if;

            return new;
end;
            
$$;


ALTER FUNCTION public.fn_acorn_new_replicated_row() OWNER TO justice;

--
-- Name: fn_acorn_reset_sequences(character varying, character varying); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
            declare
reset_query varchar(32596);
            begin
        reset_query = (SELECT string_agg(
                concat('SELECT SETVAL(''',
              PGT.schemaname, '.', S.relname,
              ''', COALESCE(MAX(', C.attname, '), 1) ) FROM ',
              PGT.schemaname, '.', T.relname, ';'),
            '')
          FROM pg_class AS S,
            pg_depend AS D,
            pg_class AS T,
            pg_attribute AS C,
            pg_tables AS PGT
          WHERE S.relkind = 'S'
            AND S.oid = D.objid
            AND D.refobjid = T.oid
            AND D.refobjid = C.attrelid
            AND D.refobjsubid = C.attnum
            AND T.relname = PGT.tablename
            AND PGT.schemaname like(schema_like)
            AND T.relname like(table_like)
        );
        if not reset_query is null then
          execute reset_query;
        end if;
end;
            $$;


ALTER FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) OWNER TO justice;

--
-- Name: fn_acorn_server_id(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_server_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            declare
pid uuid;
            begin
        if new.server_id is null then
          select "id" into pid from acorn_servers where hostname = hostname();
          if pid is null then
            insert into acorn_servers(hostname) values(hostname()) returning id into pid;
          end if;
          new.server_id = pid;
        end if;
        return new;
end;
            $$;


ALTER FUNCTION public.fn_acorn_server_id() OWNER TO justice;

--
-- Name: fn_acorn_table_counts(character varying); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_table_counts(_schema character varying) RETURNS TABLE("table" text, count bigint)
    LANGUAGE plpgsql
    AS $$begin
  -- SELECT * FROM information_schema.tables;
  return query execute (select concat(
	  'select "table", "count" from (',
		(
		  SELECT string_agg(
		  concat('select ''', table_name, ''' as "table", count(*) as "count" from ', table_name),
		  ' union all '
		)
		FROM information_schema.tables
		where table_catalog = current_database()
		and table_schema = _schema
		and table_type = 'BASE TABLE'
	  ),
	  ') data order by "count" desc, "table" asc'
	));
end;
            $$;


ALTER FUNCTION public.fn_acorn_table_counts(_schema character varying) OWNER TO justice;

--
-- Name: fn_acorn_truncate_database(character varying, character varying); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
            declare
reset_query varchar(32596);
            begin
        reset_query = (SELECT 'TRUNCATE TABLE '
              || string_agg(format('%I.%I', schemaname, tablename), ', ')
              || ' CASCADE'
            FROM   pg_tables
            WHERE  schemaname like(schema_like)
            AND tablename like(table_like)
          );
        if not reset_query is null then
          execute reset_query;
        end if;
end;
            $$;


ALTER FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) OWNER TO justice;

--
-- Name: fn_acorn_user_get_seed_user(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_user_get_seed_user() RETURNS uuid
    LANGUAGE plpgsql
    AS $$
begin
	-- We select the first user in the system
	-- Intentional EXCEPTION if there is not one
	return (select uu.id 
		--from public.backend_users bu
		--inner join public.acorn_user_users uu on bu.acorn_user_user_id = uu.id
		--where bu.is_superuser
		from public.acorn_user_users uu
		limit 1);
end;
$$;


ALTER FUNCTION public.fn_acorn_user_get_seed_user() OWNER TO justice;

--
-- Name: agg_acorn_first(anyelement); Type: AGGREGATE; Schema: public; Owner: justice
--

CREATE AGGREGATE public.agg_acorn_first(anyelement) (
    SFUNC = public.fn_acorn_first,
    STYPE = anyelement,
    PARALLEL = safe
);


ALTER AGGREGATE public.agg_acorn_first(anyelement) OWNER TO justice;

--
-- Name: agg_acorn_last(anyelement); Type: AGGREGATE; Schema: public; Owner: justice
--

CREATE AGGREGATE public.agg_acorn_last(anyelement) (
    SFUNC = public.fn_acorn_last,
    STYPE = anyelement,
    PARALLEL = safe
);


ALTER AGGREGATE public.agg_acorn_last(anyelement) OWNER TO justice;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acorn_lojistiks_computer_products; Type: TABLE; Schema: product; Owner: justice
--

CREATE TABLE product.acorn_lojistiks_computer_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    electronic_product_id uuid NOT NULL,
    memory bigint,
    "HDD_size" bigint,
    processor_version double precision,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    processor_type integer,
    response text
);


ALTER TABLE product.acorn_lojistiks_computer_products OWNER TO justice;

--
-- Name: acorn_lojistiks_electronic_products; Type: TABLE; Schema: product; Owner: justice
--

CREATE TABLE product.acorn_lojistiks_electronic_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    voltage double precision,
    created_by_user_id uuid,
    response text
);


ALTER TABLE product.acorn_lojistiks_electronic_products OWNER TO justice;

--
-- Name: acorn_calendar_calendars; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_calendar_calendars (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    sync_file character varying(4096),
    sync_format integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.108968'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    owner_user_id uuid,
    owner_user_group_id uuid,
    permissions integer DEFAULT 1 NOT NULL,
    system boolean DEFAULT false NOT NULL
);


ALTER TABLE public.acorn_calendar_calendars OWNER TO justice;

--
-- Name: TABLE acorn_calendar_calendars; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_calendar_calendars IS 'package-type: plugin
table-type: content';


--
-- Name: acorn_calendar_event_part_user; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_calendar_event_part_user (
    event_part_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid,
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.164696'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_calendar_event_part_user OWNER TO justice;

--
-- Name: TABLE acorn_calendar_event_part_user; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_calendar_event_part_user IS 'table-type: content';


--
-- Name: acorn_calendar_event_part_user_group; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_calendar_event_part_user_group (
    event_part_id uuid NOT NULL,
    user_group_id uuid NOT NULL
);


ALTER TABLE public.acorn_calendar_event_part_user_group OWNER TO justice;

--
-- Name: acorn_calendar_event_parts; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_calendar_event_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    start timestamp(0) without time zone NOT NULL,
    "end" timestamp(0) without time zone NOT NULL,
    until timestamp(0) without time zone,
    mask integer DEFAULT 0 NOT NULL,
    mask_type character varying(256),
    type_id uuid NOT NULL,
    status_id uuid NOT NULL,
    repeat_frequency integer DEFAULT 1 NOT NULL,
    parent_event_part_id uuid,
    location_id uuid,
    locked_by_user_id integer,
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.139605'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    repeat interval,
    alarm interval,
    instances_deleted integer[]
);


ALTER TABLE public.acorn_calendar_event_parts OWNER TO justice;

--
-- Name: TABLE acorn_calendar_event_parts; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_calendar_event_parts IS 'table-type: content';


--
-- Name: acorn_calendar_event_statuses; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_calendar_event_statuses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    style character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    system boolean DEFAULT false NOT NULL
);


ALTER TABLE public.acorn_calendar_event_statuses OWNER TO justice;

--
-- Name: TABLE acorn_calendar_event_statuses; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_calendar_event_statuses IS 'table-type: content';


--
-- Name: acorn_calendar_event_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_calendar_event_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    description text,
    whole_day boolean DEFAULT false NOT NULL,
    colour character varying(16),
    style character varying(2048),
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.11728'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    system boolean DEFAULT false NOT NULL,
    activity_log_related_oid integer
);


ALTER TABLE public.acorn_calendar_event_types OWNER TO justice;

--
-- Name: TABLE acorn_calendar_event_types; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_calendar_event_types IS 'table-type: content';


--
-- Name: acorn_calendar_events; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_calendar_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    calendar_id uuid NOT NULL,
    external_url character varying(2048),
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.128766'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    owner_user_id uuid NOT NULL,
    owner_user_group_id uuid,
    permissions integer DEFAULT 79 NOT NULL
);


ALTER TABLE public.acorn_calendar_events OWNER TO justice;

--
-- Name: TABLE acorn_calendar_events; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_calendar_events IS 'table-type: content';


--
-- Name: acorn_calendar_instances; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_calendar_instances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    date date NOT NULL,
    event_part_id uuid NOT NULL,
    instance_num integer NOT NULL,
    instance_start timestamp(0) without time zone NOT NULL,
    instance_end timestamp(0) without time zone NOT NULL
);


ALTER TABLE public.acorn_calendar_instances OWNER TO justice;

--
-- Name: TABLE acorn_calendar_instances; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_calendar_instances IS 'table-type: content';


--
-- Name: acorn_criminal_appeals; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_appeals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    event_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_appeals OWNER TO justice;

--
-- Name: TABLE acorn_criminal_appeals; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_appeals IS 'icon: hand-paper
labels: 
  en: Appeal
  ar: الاستئناف الجنائي
labels-plural:
  en: Appeals
  ar: الاستئنافات الجنائية
methods:
  name: $this->load(''event''); return $this->event->start?->diffForHumans();';


--
-- Name: acorn_criminal_crime_evidence; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_crime_evidence (
    defendant_crime_id uuid NOT NULL,
    legalcase_evidence_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.acorn_criminal_crime_evidence OWNER TO justice;

--
-- Name: TABLE acorn_criminal_crime_evidence; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_crime_evidence IS 'order: 43
labels:
  ar: دليل الجريمة الجنائية
labels-plural:
  ar: أدلة الجريمة الجنائية
';


--
-- Name: COLUMN acorn_criminal_crime_evidence.legalcase_evidence_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_crime_evidence.legalcase_evidence_id IS 'labels:
  en: Evidence
';


--
-- Name: acorn_criminal_crime_sentences; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_crime_sentences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    defendant_crime_id uuid NOT NULL,
    sentence_type_id uuid NOT NULL,
    amount double precision,
    suspended boolean DEFAULT false NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_crime_sentences OWNER TO justice;

--
-- Name: TABLE acorn_criminal_crime_sentences; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_crime_sentences IS 'icon: id-card
order: 42
labels:
  ar: حكم الجريمة الجنائية
labels-plural:
  ar: أحكام الجرائم الجنائية
methods:
  name: return $this->sentence_type->name . '' ('' . $this->amount . '')'';';


--
-- Name: COLUMN acorn_criminal_crime_sentences.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_crime_sentences.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_crime_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_crime_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    parent_crime_type_id uuid,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid DEFAULT public.fn_acorn_user_get_seed_user() NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_crime_types OWNER TO justice;

--
-- Name: TABLE acorn_criminal_crime_types; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_crime_types IS 'icon: keyboard
order: 40
seeding:
  - [''176d4d98-ed25-11ef-8f3a-e7099c31e054'', ''normal'']
  - [DEFAULT, ''terror'']
  - [DEFAULT, ''custodial'']
labels:
  ar: نوع الجريمة الجنائية
labels-plural:
  ar: أنواع الجرائم الجنائية
';


--
-- Name: COLUMN acorn_criminal_crime_types.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_crime_types.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_crimes; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_crimes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    crime_type_id uuid,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_crimes OWNER TO justice;

--
-- Name: TABLE acorn_criminal_crimes; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_crimes IS 'icon: allergies
order: 41
menuSplitter: yes
labels:
  ar: الجريمة الجنائية
labels-plural:
  ar: الجرائم الجنائية
seeding:
  - [DEFAULT, ''Theft'', ''176d4d98-ed25-11ef-8f3a-e7099c31e054'']
  - [DEFAULT, ''Mysogyny'', ''176d4d98-ed25-11ef-8f3a-e7099c31e054'']';


--
-- Name: COLUMN acorn_criminal_crimes.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_crimes.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_defendant_crimes; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_defendant_crimes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_defendant_id uuid NOT NULL,
    crime_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_defendant_crimes OWNER TO justice;

--
-- Name: TABLE acorn_criminal_defendant_crimes; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_defendant_crimes IS 'icon: id-card
labels:
  ar: جرائم المتهمين الجنائية
labels-plural:
  ar: جرايمة المتهم الجنائية
methods:
  name: return $this->crime->name;';


--
-- Name: COLUMN acorn_criminal_defendant_crimes.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_defendant_crimes.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_defendant_detentions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_defendant_detentions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_id uuid NOT NULL,
    detention_reason_id uuid,
    detention_method_id uuid,
    actual_release_transfer_id uuid,
    legalcase_defendant_id uuid,
    name character varying(1024) GENERATED ALWAYS AS (id) STORED,
    description text
);


ALTER TABLE public.acorn_criminal_defendant_detentions OWNER TO justice;

--
-- Name: TABLE acorn_criminal_defendant_detentions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_defendant_detentions IS 'methods:
  name: return $this->transfer->location->name . '' ('' . $this->detention_reason?->name . '')'';';


--
-- Name: COLUMN acorn_criminal_defendant_detentions.detention_reason_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_defendant_detentions.detention_reason_id IS 'labels:
  en: Reason
new-row: true';


--
-- Name: COLUMN acorn_criminal_defendant_detentions.detention_method_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_defendant_detentions.detention_method_id IS 'labels:
  en: Method';


--
-- Name: COLUMN acorn_criminal_defendant_detentions.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_defendant_detentions.name IS 'hidden: true';


--
-- Name: COLUMN acorn_criminal_defendant_detentions.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_defendant_detentions.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_detention_methods; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_detention_methods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_detention_methods OWNER TO justice;

--
-- Name: TABLE acorn_criminal_detention_methods; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_detention_methods IS 'seeding:
  - [DEFAULT, ''Arrest'']
  - [DEFAULT, ''Request'']';


--
-- Name: COLUMN acorn_criminal_detention_methods.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_detention_methods.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_detention_reasons; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_detention_reasons (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_detention_reasons OWNER TO justice;

--
-- Name: TABLE acorn_criminal_detention_reasons; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_detention_reasons IS 'seeding:
  - [DEFAULT, ''Previous record'']
  - [DEFAULT, ''In danger'']';


--
-- Name: COLUMN acorn_criminal_detention_reasons.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_detention_reasons.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_legalcase_defendants; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_legalcase_defendants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_legalcase_defendants OWNER TO justice;

--
-- Name: TABLE acorn_criminal_legalcase_defendants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_legalcase_defendants IS 'icon: robot
order: 6
menu: false
labels:
  ar: المتهم في قضية جنائية
labels-plural:
  ar: المتهمين في قضية جنائية
';


--
-- Name: COLUMN acorn_criminal_legalcase_defendants.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_defendants.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_legalcase_evidence; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_legalcase_evidence (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    name character varying(1024) NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_legalcase_evidence OWNER TO justice;

--
-- Name: TABLE acorn_criminal_legalcase_evidence; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_legalcase_evidence IS 'table-type: content
plural: legalcase_evidence
icon: object-group
order: 3
menu: false
labels:
  ar: دليل القضايا الجنائية
labels-plural:
  ar: أدلة القضايا الجنائية
';


--
-- Name: COLUMN acorn_criminal_legalcase_evidence.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_evidence.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_legalcase_plaintiffs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_legalcase_plaintiffs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_legalcase_plaintiffs OWNER TO justice;

--
-- Name: TABLE acorn_criminal_legalcase_plaintiffs; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_legalcase_plaintiffs IS 'icon: address-book
order: 2
menu: false
labels:
  ar: ضحية القضية الجنائية
labels-plural:
  ar: ضحايا القضية الجنائية
';


--
-- Name: COLUMN acorn_criminal_legalcase_plaintiffs.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_plaintiffs.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_legalcase_prosecutor; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_legalcase_prosecutor (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    user_id uuid NOT NULL,
    user_group_id uuid,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid DEFAULT public.fn_acorn_user_get_seed_user() NOT NULL,
    description text,
    updated_at_event_id uuid
);


ALTER TABLE public.acorn_criminal_legalcase_prosecutor OWNER TO justice;

--
-- Name: TABLE acorn_criminal_legalcase_prosecutor; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_legalcase_prosecutor IS 'icon: id-card
order: 4
menu: false
labels:
  ar: المدعي العام للقضية الجنائية
labels-plural:
  ar: المدعون العامون للقضايا الجنائية
';


--
-- Name: COLUMN acorn_criminal_legalcase_prosecutor.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_prosecutor.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_legalcase_related_events; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_legalcase_related_events (
    legalcase_id uuid NOT NULL,
    id uuid DEFAULT gen_random_uuid(),
    created_by_user_id uuid NOT NULL,
    event_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_legalcase_related_events OWNER TO justice;

--
-- Name: TABLE acorn_criminal_legalcase_related_events; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_legalcase_related_events IS 'icon: address-book
order: 7
labels:
  en: Legalcase Events
  ar: الحدث المتعلقة بالقضاية الجنائية
labels-plural:
  ar: الأحداث المتعلقة بالقضايا الجنائية
methods:
  name: $this->load(''event''); return $this->event->start?->diffForHumans();';


--
-- Name: acorn_criminal_legalcase_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_legalcase_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_legalcase_types OWNER TO justice;

--
-- Name: TABLE acorn_criminal_legalcase_types; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_legalcase_types IS 'seeding:
  - [DEFAULT, ''Criminal'']
  - [DEFAULT, ''Civil'']
labels:
  en: Type
labels-plural:
  en: Types';


--
-- Name: acorn_criminal_legalcase_witnesses; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_legalcase_witnesses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_legalcase_witnesses OWNER TO justice;

--
-- Name: TABLE acorn_criminal_legalcase_witnesses; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_legalcase_witnesses IS 'icon: search
order: 5
menu: false
labels:
  ar: شاهد القضية الجنائية
labels-plural:
  ar: شهود القضية الجنائية
';


--
-- Name: COLUMN acorn_criminal_legalcase_witnesses.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_witnesses.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_legalcases; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_legalcases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    server_id uuid,
    judge_committee_user_group_id uuid NOT NULL,
    legalcase_type_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_legalcases OWNER TO justice;

--
-- Name: TABLE acorn_criminal_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_legalcases IS 'icon: dizzy
plugin-icon: address-book
order: 1
labels:
  en: LegalCase
  ar: القضية الجنائية
labels-plural:
  en: LegalCases
  ar: القضايا الجنائية
plugin-names:
  en: LegalCases
  ar: القضية الجنائية
filters:
  owner_user_group: id in(select cl.id from acorn_criminal_legalcases cl inner join acorn_justice_legalcases  jl on jl.id = cl.legalcase_id where jl.owner_user_group_id in(:filtered))';


--
-- Name: COLUMN acorn_criminal_legalcases.legalcase_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcases.legalcase_id IS 'order: 1';


--
-- Name: COLUMN acorn_criminal_legalcases.judge_committee_user_group_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcases.judge_committee_user_group_id IS 'bootstraps:
  xs: 4
order: 11';


--
-- Name: COLUMN acorn_criminal_legalcases.legalcase_type_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcases.legalcase_type_id IS 'field-type: radio
bootstraps:
  xs: 4
css-classes: 
  - inline-options
permission-settings:
  NOT=legalcases__legalcase_type_id__update@update:
    field:
      readOnly: true
      disabled: true
      type: dropdown
    labels: 
      en: Update LegalCase type
order: 10';


--
-- Name: acorn_criminal_sentence_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_sentence_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_sentence_types OWNER TO justice;

--
-- Name: TABLE acorn_criminal_sentence_types; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_sentence_types IS 'icon: hand-rock
order: 43
labels:
  ar: نوع الحكم الجنائي
labels-plural:
  ar: أنواع الأحكام الجنائية
seeding:
  - [DEFAULT, ''Custodial'']
  - [DEFAULT, ''Fine'']
  - [DEFAULT, ''Community service'']';


--
-- Name: COLUMN acorn_criminal_sentence_types.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_sentence_types.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_session_recordings; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_session_recordings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trial_session_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    description text,
    name character varying(1024),
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_session_recordings OWNER TO justice;

--
-- Name: TABLE acorn_criminal_session_recordings; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_session_recordings IS 'icon: map
order: 25
menu: false
labels:
  ar: تسجيل الجلسة جنائية
labels-plural:
  ar: تسجيلات الجلسة جنائية
';


--
-- Name: COLUMN acorn_criminal_session_recordings.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_session_recordings.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_trial_judges; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_trial_judges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trial_id uuid NOT NULL,
    user_id uuid NOT NULL,
    user_group_id uuid,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_trial_judges OWNER TO justice;

--
-- Name: TABLE acorn_criminal_trial_judges; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_trial_judges IS 'icon: thumbs-up
order: 22
menu: false
labels:
  ar: قاضي المحكمة الجنائية
labels-plural:
  ar: قضاة المحكمة الجنائية
methods:
  name: return $this->user->name;';


--
-- Name: COLUMN acorn_criminal_trial_judges.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_trial_judges.description IS 'field-comment: Use this field to add any extra notes that do not have fields in the interface yet. The system administrators will check this and expand the interface to accommodate your needs
tab: acorn::lang.models.general.notes
labels:
  en: Notes
tab-location: 1
no-label: true
bootstraps:
  xs: 12';


--
-- Name: acorn_criminal_trial_sessions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_trial_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trial_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    event_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_trial_sessions OWNER TO justice;

--
-- Name: TABLE acorn_criminal_trial_sessions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_trial_sessions IS 'icon: meh
order: 21
labels:
  ar: جلسة المحكمة الجنائية
labels-plural:
  ar: جلسات المحكمة الجنائية
methods:
  name: return $this->created_at_event->start;';


--
-- Name: acorn_criminal_trials; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_trials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    event_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_trials OWNER TO justice;

--
-- Name: TABLE acorn_criminal_trials; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_trials IS 'icon: ankh
order: 20
menuSplitter: yes
labels:
  ar: المحكمة الجنائية
labels-plural:
  ar: المحاكم الجنائية
methods:
  name: $this->load(''event''); return $this->event->start?->diffForHumans();';


--
-- Name: acorn_finance_currencies; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_finance_currencies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    shortname character(3) NOT NULL,
    symbol character varying(16) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_finance_currencies OWNER TO justice;

--
-- Name: TABLE acorn_finance_currencies; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_finance_currencies IS 'plugin-icon: money
icon: stripe
seeding:
  - [DEFAULT, ''Syrian Pound'', ''SYR'', ''£'']
  - [DEFAULT, ''American dollar'', ''USD'', ''$'']
methods:
  present($amount): return "$this->symbol$amount";
';


--
-- Name: acorn_finance_invoices; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_finance_invoices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    number integer NOT NULL,
    currency_id uuid NOT NULL,
    mark_paid boolean DEFAULT false NOT NULL,
    amount integer NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS ((((('#'::text || (number)::text) || ' ('::text) || (amount)::text) || ')'::text)) STORED NOT NULL,
    payer_user_id uuid,
    payer_user_group_id uuid,
    payee_user_id uuid,
    payee_user_group_id uuid,
    created_event_id uuid,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    CONSTRAINT payee_either_or CHECK (((NOT (payee_user_id IS NULL)) OR (NOT (payee_user_group_id IS NULL)))),
    CONSTRAINT payer_either_or CHECK (((NOT (payer_user_id IS NULL)) OR (NOT (payer_user_group_id IS NULL))))
);


ALTER TABLE public.acorn_finance_invoices OWNER TO justice;

--
-- Name: TABLE acorn_finance_invoices; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_finance_invoices IS 'methods:
  name:  return "#$this->number (" . $this->currency?->present($this->amount) . '') to '' . $this->payer_user_group?->name . '' '' . $this->payer_user?->name;
icon: swift';


--
-- Name: COLUMN acorn_finance_invoices.payer_user_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_finance_invoices.payer_user_id IS 'labels: 
  en: Payer
new-row: true';


--
-- Name: COLUMN acorn_finance_invoices.payer_user_group_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_finance_invoices.payer_user_group_id IS 'labels: 
  en: Payer Organisation';


--
-- Name: COLUMN acorn_finance_invoices.payee_user_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_finance_invoices.payee_user_id IS 'labels: 
  en: Payee
new-row: true';


--
-- Name: COLUMN acorn_finance_invoices.payee_user_group_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_finance_invoices.payee_user_group_id IS 'labels: 
  en: Payee Organisation';


--
-- Name: acorn_finance_payments; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_finance_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    currency_id uuid NOT NULL,
    amount integer NOT NULL,
    number integer,
    name character varying(1024) GENERATED ALWAYS AS ((((('#'::text || (number)::text) || ' ('::text) || (amount)::text) || ')'::text)) STORED NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_finance_payments OWNER TO justice;

--
-- Name: TABLE acorn_finance_payments; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_finance_payments IS 'icon: vine';


--
-- Name: COLUMN acorn_finance_payments.amount; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_finance_payments.amount IS 'new-row: true';


--
-- Name: acorn_finance_purchases; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_finance_purchases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    number integer NOT NULL,
    mark_paid boolean DEFAULT false NOT NULL,
    currency_id uuid NOT NULL,
    amount integer NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS ((((('#'::text || (number)::text) || ' ('::text) || (amount)::text) || ')'::text)) STORED NOT NULL,
    payer_user_id uuid,
    payer_user_group_id uuid,
    payee_user_id uuid,
    payee_user_group_id uuid,
    description text,
    created_at_event_id uuid,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    CONSTRAINT payee_either_or CHECK (((NOT (payee_user_id IS NULL)) OR (NOT (payee_user_group_id IS NULL)))),
    CONSTRAINT payer_either_or CHECK (((NOT (payer_user_id IS NULL)) OR (NOT (payer_user_group_id IS NULL))))
);


ALTER TABLE public.acorn_finance_purchases OWNER TO justice;

--
-- Name: TABLE acorn_finance_purchases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_finance_purchases IS 'icon: wpforms';


--
-- Name: COLUMN acorn_finance_purchases.payer_user_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_finance_purchases.payer_user_id IS 'labels: 
  en: Payer
new-row: true';


--
-- Name: COLUMN acorn_finance_purchases.payer_user_group_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_finance_purchases.payer_user_group_id IS 'labels: 
  en: Payer Organisation';


--
-- Name: COLUMN acorn_finance_purchases.payee_user_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_finance_purchases.payee_user_id IS 'labels: 
  en: Payee
new-row: true';


--
-- Name: COLUMN acorn_finance_purchases.payee_user_group_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_finance_purchases.payee_user_group_id IS 'labels: 
  en: Payee Organisation';


--
-- Name: acorn_finance_receipts; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_finance_receipts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_id uuid NOT NULL,
    number integer NOT NULL,
    currency_id uuid NOT NULL,
    amount integer NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS ((((('#'::text || (number)::text) || ' ('::text) || (amount)::text) || ')'::text)) STORED NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_finance_receipts OWNER TO justice;

--
-- Name: TABLE acorn_finance_receipts; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_finance_receipts IS 'icon: receipt';


--
-- Name: COLUMN acorn_finance_receipts.currency_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_finance_receipts.currency_id IS 'new-row: true';


--
-- Name: acorn_justice_legalcase_categories; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_justice_legalcase_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    parent_legalcase_category_id uuid,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_justice_legalcase_categories OWNER TO justice;

--
-- Name: TABLE acorn_justice_legalcase_categories; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_legalcase_categories IS 'icon: cat
labels:
  ar: فئة القضية العدلية
labels-plural:
  ar: فئات القضية العدلية
';


--
-- Name: acorn_justice_legalcase_identifiers; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_justice_legalcase_identifiers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    name character varying(1024) NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_justice_legalcase_identifiers OWNER TO justice;

--
-- Name: TABLE acorn_justice_legalcase_identifiers; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_legalcase_identifiers IS 'icon: unity
labels:
  ar: معرف قضايا العدالة
labels-plural:
  ar: معرفات قضايا العدالة
';


--
-- Name: acorn_justice_legalcase_legalcase_category; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_justice_legalcase_legalcase_category (
    legalcase_id uuid NOT NULL,
    legalcase_category_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid DEFAULT public.fn_acorn_user_get_seed_user() NOT NULL,
    description text,
    updated_at_event_id uuid
);


ALTER TABLE public.acorn_justice_legalcase_legalcase_category OWNER TO justice;

--
-- Name: TABLE acorn_justice_legalcase_legalcase_category; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_legalcase_legalcase_category IS 'labels:
  ar:قضية عدالة فئة القضية
labels-plural:
  ar: قضاية عدالة فئة القضية
';


--
-- Name: acorn_justice_legalcases; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_justice_legalcases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    name character varying(1024) NOT NULL,
    closed_at_event_id uuid,
    owner_user_group_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_justice_legalcases OWNER TO justice;

--
-- Name: TABLE acorn_justice_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_legalcases IS '# Base table for all legal cases
table-type: central
icon: angry
labels:
  en: Case
  ar: قضية عدالة
labels-plural:
  ar: قضاية عدالة
plugin-names:
  ar: قضية عدالة
order: 1
plugin-icon: adjust
';


--
-- Name: COLUMN acorn_justice_legalcases.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_legalcases.name IS 'labels: 
  en: Identifier
  ku: Nav
order: 1
permission-settings:
  NOT=legalcases__legalcase_name__update@update:
    field:
      readOnly: true
      disabled: true
    labels: 
      en: Update LegalCase identifier';


--
-- Name: COLUMN acorn_justice_legalcases.closed_at_event_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_legalcases.closed_at_event_id IS 'labels:
  en: Closed at
css-classes:
  - highlight-value
order: 2
';


--
-- Name: COLUMN acorn_justice_legalcases.owner_user_group_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_legalcases.owner_user_group_id IS 'labels:
  en: Owner Organisation
bootstraps:
  xs: 4
permission-settings:
  NOT=legalcases__owner_user_group_id__update@update:
    field:
      readOnly: true
      disabled: true
    labels: 
      en: Update owning Group
order: 8
';


--
-- Name: COLUMN acorn_justice_legalcases.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_legalcases.description IS 'tab-location: 1
tab: acorn::lang.models.general.description
labels:
  en: Notes
css-classes: single-tab';


--
-- Name: acorn_justice_scanned_documents; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_justice_scanned_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    document path,
    created_by_user_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    legalcase_id uuid NOT NULL,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_justice_scanned_documents OWNER TO justice;

--
-- Name: COLUMN acorn_justice_scanned_documents.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_scanned_documents.description IS 'tab-location: 1
tab: acorn::lang.models.general.description
labels:
  en: Notes
css-classes: single-tab';


--
-- Name: acorn_justice_warrant_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_justice_warrant_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_justice_warrant_types OWNER TO justice;

--
-- Name: TABLE acorn_justice_warrant_types; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_warrant_types IS 'seeding:
  - [DEFAULT, ''Arrest'']
  - [DEFAULT, ''Search'']';


--
-- Name: acorn_justice_warrants; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_justice_warrants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    user_id uuid NOT NULL,
    warrant_type_id uuid,
    legalcase_id uuid NOT NULL,
    revoked_at_event_id uuid,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_justice_warrants OWNER TO justice;

--
-- Name: TABLE acorn_justice_warrants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_warrants IS 'printable: true
methods:
  name: return $this->warrant_type->name;';


--
-- Name: acorn_location_addresses; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_location_addresses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    number character varying(1024),
    image character varying(2048),
    area_id uuid NOT NULL,
    gps_id uuid,
    server_id uuid NOT NULL,
    created_by_user_id uuid,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    response text,
    lookup_id uuid,
    description text
);


ALTER TABLE public.acorn_location_addresses OWNER TO justice;

--
-- Name: acorn_location_area_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_location_area_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    server_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    description text
);


ALTER TABLE public.acorn_location_area_types OWNER TO justice;

--
-- Name: acorn_location_areas; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_location_areas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    area_type_id uuid NOT NULL,
    parent_area_id uuid,
    gps_id uuid,
    server_id uuid NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    is_current_version boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    description text
);


ALTER TABLE public.acorn_location_areas OWNER TO justice;

--
-- Name: acorn_location_gps; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_location_gps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    longitude double precision,
    latitude double precision,
    server_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acorn_location_gps OWNER TO justice;

--
-- Name: acorn_location_locations; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_location_locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    address_id uuid NOT NULL,
    name character varying(2048) NOT NULL,
    image character varying(2048),
    server_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    user_group_id uuid,
    type_id uuid,
    description text
);


ALTER TABLE public.acorn_location_locations OWNER TO justice;

--
-- Name: acorn_location_lookup; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_location_lookup (
    id uuid NOT NULL,
    address character varying(1024) NOT NULL,
    city character varying(1024) NOT NULL,
    zip character varying(1024) NOT NULL,
    country_code character varying(1024) NOT NULL,
    state_code character varying(1024) NOT NULL,
    latitude character varying(1024) NOT NULL,
    longitude character varying(1024) NOT NULL,
    vicinity character varying(1024) NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.acorn_location_lookup OWNER TO justice;

--
-- Name: acorn_location_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_location_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    parent_type_id uuid,
    server_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    colour character varying(1024),
    image character varying(1024),
    description text
);


ALTER TABLE public.acorn_location_types OWNER TO justice;

--
-- Name: acorn_lojistiks_brands; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_brands (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    image character varying(2048),
    response text,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_brands OWNER TO justice;

--
-- Name: TABLE acorn_lojistiks_brands; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_lojistiks_brands IS 'seeding:
  - [DEFAULT, ''Lenovo'']
  - [DEFAULT, ''Samsung'']
  - [DEFAULT, ''Acer'']';


--
-- Name: acorn_lojistiks_containers; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_containers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    name character varying(1024),
    created_by_user_id uuid,
    response text,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_containers OWNER TO justice;

--
-- Name: acorn_lojistiks_drivers; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_drivers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    vehicle_id uuid,
    created_by_user_id uuid,
    response text,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_drivers OWNER TO justice;

--
-- Name: acorn_lojistiks_employees; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_employees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    user_role_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_employees OWNER TO justice;

--
-- Name: acorn_lojistiks_measurement_units; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_measurement_units (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    short_name character varying(1024),
    uses_quantity boolean DEFAULT true NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_measurement_units OWNER TO justice;

--
-- Name: TABLE acorn_lojistiks_measurement_units; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_lojistiks_measurement_units IS 'seeding:
  - [DEFAULT, ''Units'', '''', false]
  - [DEFAULT, ''Litres'', ''l'', true]
  - [DEFAULT, ''Kilograms'', ''kg'', true]
';


--
-- Name: acorn_lojistiks_offices; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_offices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_offices OWNER TO justice;

--
-- Name: acorn_lojistiks_people; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_people (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    image character varying(2048),
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    last_transfer_location_id uuid,
    last_product_instance_location_id uuid,
    description text
);


ALTER TABLE public.acorn_lojistiks_people OWNER TO justice;

--
-- Name: acorn_lojistiks_product_attributes; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_product_attributes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    name character varying(1024) NOT NULL,
    value character varying(1024) NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_product_attributes OWNER TO justice;

--
-- Name: acorn_lojistiks_product_categories; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_product_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    product_category_type_id uuid NOT NULL,
    parent_product_category_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_product_categories OWNER TO justice;

--
-- Name: acorn_lojistiks_product_category_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_product_category_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_product_category_types OWNER TO justice;

--
-- Name: acorn_lojistiks_product_instance_transfer; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_product_instance_transfer (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_id uuid NOT NULL,
    product_instance_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text
);


ALTER TABLE public.acorn_lojistiks_product_instance_transfer OWNER TO justice;

--
-- Name: acorn_lojistiks_product_instances; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_product_instances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    external_identifier character varying(2048),
    asset_class "char" DEFAULT 'C'::"char" NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    image path,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_product_instances OWNER TO justice;

--
-- Name: TABLE acorn_lojistiks_product_instances; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_lojistiks_product_instances IS 'methods:
  name: return $this->product->name . '' x '' . $this->amount;';


--
-- Name: acorn_lojistiks_product_product_category; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_product_product_category (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    product_category_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acorn_lojistiks_product_product_category OWNER TO justice;

--
-- Name: acorn_lojistiks_product_products; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_product_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    sub_product_id uuid NOT NULL,
    quantity integer NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_product_products OWNER TO justice;

--
-- Name: TABLE acorn_lojistiks_product_products; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_lojistiks_product_products IS 'methods:
  name: return $this->subproduct->name . '' x '' . $this->quantity;';


--
-- Name: acorn_lojistiks_products; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    measurement_unit_id uuid NOT NULL,
    brand_id uuid NOT NULL,
    model_name character varying(2048),
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    image path,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_products OWNER TO justice;

--
-- Name: acorn_lojistiks_products_product_category; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_products_product_category (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    product_category_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acorn_lojistiks_products_product_category OWNER TO justice;

--
-- Name: acorn_lojistiks_suppliers; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_suppliers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_suppliers OWNER TO justice;

--
-- Name: acorn_lojistiks_transfer_container_product_instance; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_transfer_container_product_instance (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_container_id uuid NOT NULL,
    product_instance_transfer_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text
);


ALTER TABLE public.acorn_lojistiks_transfer_container_product_instance OWNER TO justice;

--
-- Name: TABLE acorn_lojistiks_transfer_container_product_instance; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_lojistiks_transfer_container_product_instance IS 'todo: true';


--
-- Name: COLUMN acorn_lojistiks_transfer_container_product_instance.transfer_container_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_lojistiks_transfer_container_product_instance.transfer_container_id IS 'todo: true';


--
-- Name: acorn_lojistiks_transfer_containers; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_transfer_containers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_id uuid NOT NULL,
    container_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text
);


ALTER TABLE public.acorn_lojistiks_transfer_containers OWNER TO justice;

--
-- Name: TABLE acorn_lojistiks_transfer_containers; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_lojistiks_transfer_containers IS 'todo: true';


--
-- Name: acorn_lojistiks_transfer_invoice; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_transfer_invoice (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_id uuid NOT NULL,
    invoice_id uuid NOT NULL,
    description text
);


ALTER TABLE public.acorn_lojistiks_transfer_invoice OWNER TO justice;

--
-- Name: acorn_lojistiks_transfer_purchase; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_transfer_purchase (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transfer_id uuid NOT NULL,
    purchase_id uuid NOT NULL,
    description text
);


ALTER TABLE public.acorn_lojistiks_transfer_purchase OWNER TO justice;

--
-- Name: acorn_lojistiks_transfers; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_transfers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    driver_id uuid,
    server_id uuid NOT NULL,
    vehicle_id uuid,
    created_by_user_id uuid,
    created_at_event_id uuid,
    response text,
    pre_marked_arrived boolean DEFAULT false NOT NULL,
    sent_at_event_id uuid,
    arrived_at_event_id uuid,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_transfers OWNER TO justice;

--
-- Name: TABLE acorn_lojistiks_transfers; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_lojistiks_transfers IS 'methods:
  name: return $this->location->name . '' @ '' . $this->sent_at_event->start;';


--
-- Name: COLUMN acorn_lojistiks_transfers.response; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_lojistiks_transfers.response IS 'env: APP_DEBUG';


--
-- Name: COLUMN acorn_lojistiks_transfers.sent_at_event_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_lojistiks_transfers.sent_at_event_id IS 'new-row: true';


--
-- Name: acorn_lojistiks_vehicle_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_vehicle_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_vehicle_types OWNER TO justice;

--
-- Name: TABLE acorn_lojistiks_vehicle_types; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_lojistiks_vehicle_types IS 'seeding:
  - [DEFAULT, ''Car'']
  - [DEFAULT, ''Lorry'']';


--
-- Name: acorn_lojistiks_vehicles; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_vehicles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vehicle_type_id uuid NOT NULL,
    registration character varying(1024) NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    image path,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_vehicles OWNER TO justice;

--
-- Name: TABLE acorn_lojistiks_vehicles; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_lojistiks_vehicles IS 'methods:
  name: return $this->registration;';


--
-- Name: acorn_lojistiks_warehouses; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_lojistiks_warehouses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    location_id uuid NOT NULL,
    server_id uuid NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    response text,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_lojistiks_warehouses OWNER TO justice;

--
-- Name: acorn_messaging_action; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_messaging_action (
    message_id uuid NOT NULL,
    action character varying(1024) NOT NULL,
    settings text NOT NULL,
    status uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_action OWNER TO justice;

--
-- Name: acorn_messaging_label; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_messaging_label (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_label OWNER TO justice;

--
-- Name: acorn_messaging_message; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_messaging_message (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_from_id uuid NOT NULL,
    subject character varying(2048) NOT NULL,
    body text NOT NULL,
    labels character varying(2048),
    "externalID" character varying(2048),
    source character varying(2048),
    mime_type character varying(64),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message OWNER TO justice;

--
-- Name: TABLE acorn_messaging_message; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_messaging_message IS 'table-type: content';


--
-- Name: acorn_messaging_message_instance; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_messaging_message_instance (
    message_id uuid NOT NULL,
    instance_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.183819'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_instance OWNER TO justice;

--
-- Name: acorn_messaging_message_message; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_messaging_message_message (
    message1_id uuid NOT NULL,
    message2_id uuid NOT NULL,
    relationship integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_message OWNER TO justice;

--
-- Name: acorn_messaging_message_user; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_messaging_message_user (
    message_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_user OWNER TO justice;

--
-- Name: acorn_messaging_message_user_group; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_messaging_message_user_group (
    message_id uuid NOT NULL,
    user_group_id uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_user_group OWNER TO justice;

--
-- Name: acorn_messaging_status; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_messaging_status (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_status OWNER TO justice;

--
-- Name: TABLE acorn_messaging_status; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_messaging_status IS 'table-type: content';


--
-- Name: acorn_messaging_user_message_status; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_messaging_user_message_status (
    user_id uuid NOT NULL,
    message_id uuid NOT NULL,
    status_id uuid NOT NULL,
    value character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_user_message_status OWNER TO justice;

--
-- Name: TABLE acorn_messaging_user_message_status; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_messaging_user_message_status IS 'table-type: content';


--
-- Name: acorn_servers; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_servers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    hostname character varying(1024) DEFAULT 'hostname()'::character varying NOT NULL,
    response text,
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:18.175619'::timestamp without time zone NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS (hostname) STORED,
    location_id uuid,
    domain character varying(1024)
);


ALTER TABLE public.acorn_servers OWNER TO justice;

--
-- Name: acorn_user_language_user; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_user_language_user (
    user_id uuid NOT NULL,
    language_id uuid NOT NULL
);


ALTER TABLE public.acorn_user_language_user OWNER TO justice;

--
-- Name: acorn_user_languages; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_user_languages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL
);


ALTER TABLE public.acorn_user_languages OWNER TO justice;

--
-- Name: acorn_user_mail_blockers; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_user_mail_blockers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255),
    template character varying(255),
    user_id uuid,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_user_mail_blockers OWNER TO justice;

--
-- Name: acorn_user_roles; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_user_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255),
    permissions text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_user_roles OWNER TO justice;

--
-- Name: acorn_user_throttle; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_user_throttle (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    ip_address character varying(255),
    attempts integer DEFAULT 0 NOT NULL,
    last_attempt_at timestamp(0) without time zone,
    is_suspended boolean DEFAULT false NOT NULL,
    suspended_at timestamp(0) without time zone,
    is_banned boolean DEFAULT false NOT NULL,
    banned_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_user_throttle OWNER TO justice;

--
-- Name: acorn_user_user_group; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_user_user_group (
    user_id uuid NOT NULL,
    user_group_id uuid NOT NULL
);


ALTER TABLE public.acorn_user_user_group OWNER TO justice;

--
-- Name: acorn_user_user_group_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_user_user_group_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    colour character varying(1024),
    image character varying(1024)
);


ALTER TABLE public.acorn_user_user_group_types OWNER TO justice;

--
-- Name: acorn_user_user_group_version_usages; Type: VIEW; Schema: public; Owner: justice
--

CREATE VIEW public.acorn_user_user_group_version_usages AS
 SELECT NULL::uuid AS user_group_version_id,
    NULL::character varying(1024) AS "table",
    NULL::uuid AS id;


ALTER VIEW public.acorn_user_user_group_version_usages OWNER TO justice;

--
-- Name: acorn_user_user_group_version_user; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_user_user_group_version_user (
    user_group_version_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public.acorn_user_user_group_version_user OWNER TO justice;

--
-- Name: acorn_user_user_group_versions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_user_user_group_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_group_id uuid NOT NULL,
    created_at_event_id uuid,
    from_user_group_version_id uuid
);


ALTER TABLE public.acorn_user_user_group_versions OWNER TO justice;

--
-- Name: acorn_user_user_groups; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_user_user_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255),
    description text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    parent_user_group_id uuid,
    nest_left integer,
    nest_right integer,
    nest_depth integer,
    type_id uuid,
    colour character varying(1024),
    image character varying(1024),
    default_user_group_version_id uuid,
    from_user_group_id uuid
);


ALTER TABLE public.acorn_user_user_groups OWNER TO justice;

--
-- Name: acorn_user_users; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_user_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255),
    email character varying(255),
    password character varying(255),
    activation_code character varying(255),
    persist_code character varying(255),
    reset_password_code character varying(255),
    permissions text,
    is_activated boolean DEFAULT false NOT NULL,
    activated_at timestamp(0) without time zone,
    last_login timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    username character varying(255),
    surname character varying(255),
    deleted_at timestamp(0) without time zone,
    last_seen timestamp(0) without time zone,
    is_guest boolean DEFAULT false NOT NULL,
    is_superuser boolean DEFAULT false NOT NULL,
    created_ip_address character varying(255),
    last_ip_address character varying(255),
    acorn_imap_username character varying(255),
    acorn_imap_password character varying(255),
    acorn_imap_server character varying(255),
    acorn_imap_port integer,
    acorn_imap_protocol character varying(255),
    acorn_imap_encryption character varying(255),
    acorn_imap_authentication character varying(255),
    acorn_imap_validate_cert boolean,
    acorn_smtp_server character varying(255),
    acorn_smtp_port character varying(255),
    acorn_smtp_encryption character varying(255),
    acorn_smtp_authentication character varying(255),
    acorn_smtp_username character varying(255),
    acorn_smtp_password character varying(255),
    acorn_messaging_sounds boolean,
    acorn_messaging_email_notifications character(1),
    acorn_messaging_autocreated boolean,
    acorn_imap_last_fetch timestamp(0) without time zone,
    acorn_default_calendar uuid,
    acorn_start_of_week integer,
    acorn_default_event_time_from date,
    acorn_default_event_time_to date,
    is_system_user boolean DEFAULT false
);


ALTER TABLE public.acorn_user_users OWNER TO justice;

--
-- Name: backend_access_log; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_access_log (
    id integer NOT NULL,
    user_id integer NOT NULL,
    ip_address character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.backend_access_log OWNER TO justice;

--
-- Name: backend_access_log_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_access_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_access_log_id_seq OWNER TO justice;

--
-- Name: backend_access_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_access_log_id_seq OWNED BY public.backend_access_log.id;


--
-- Name: backend_user_groups; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_user_groups (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    code character varying(255),
    description text,
    is_new_user_default boolean DEFAULT false NOT NULL
);


ALTER TABLE public.backend_user_groups OWNER TO justice;

--
-- Name: backend_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_user_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_groups_id_seq OWNER TO justice;

--
-- Name: backend_user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_user_groups_id_seq OWNED BY public.backend_user_groups.id;


--
-- Name: backend_user_preferences; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_user_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    namespace character varying(100) NOT NULL,
    "group" character varying(50) NOT NULL,
    item character varying(150) NOT NULL,
    value text
);


ALTER TABLE public.backend_user_preferences OWNER TO justice;

--
-- Name: backend_user_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_user_preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_preferences_id_seq OWNER TO justice;

--
-- Name: backend_user_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_user_preferences_id_seq OWNED BY public.backend_user_preferences.id;


--
-- Name: backend_user_roles; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_user_roles (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255),
    description text,
    permissions text,
    is_system boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.backend_user_roles OWNER TO justice;

--
-- Name: backend_user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_roles_id_seq OWNER TO justice;

--
-- Name: backend_user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_user_roles_id_seq OWNED BY public.backend_user_roles.id;


--
-- Name: backend_user_throttle; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_user_throttle (
    id integer NOT NULL,
    user_id integer,
    ip_address character varying(255),
    attempts integer DEFAULT 0 NOT NULL,
    last_attempt_at timestamp(0) without time zone,
    is_suspended boolean DEFAULT false NOT NULL,
    suspended_at timestamp(0) without time zone,
    is_banned boolean DEFAULT false NOT NULL,
    banned_at timestamp(0) without time zone
);


ALTER TABLE public.backend_user_throttle OWNER TO justice;

--
-- Name: backend_user_throttle_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_user_throttle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_throttle_id_seq OWNER TO justice;

--
-- Name: backend_user_throttle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_user_throttle_id_seq OWNED BY public.backend_user_throttle.id;


--
-- Name: backend_users; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_users (
    id integer NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    login character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    activation_code character varying(255),
    persist_code character varying(255),
    reset_password_code character varying(255),
    permissions text,
    is_activated boolean DEFAULT false NOT NULL,
    role_id integer,
    activated_at timestamp(0) without time zone,
    last_login timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    deleted_at timestamp(0) without time zone,
    is_superuser boolean DEFAULT false NOT NULL,
    metadata text,
    acorn_url character varying(2048),
    acorn_user_user_id uuid
);


ALTER TABLE public.backend_users OWNER TO justice;

--
-- Name: backend_users_groups; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.backend_users_groups (
    user_id integer NOT NULL,
    user_group_id integer NOT NULL,
    deleted_at timestamp(0) without time zone
);


ALTER TABLE public.backend_users_groups OWNER TO justice;

--
-- Name: backend_users_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.backend_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_users_id_seq OWNER TO justice;

--
-- Name: backend_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.backend_users_id_seq OWNED BY public.backend_users.id;


--
-- Name: cache; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache OWNER TO justice;

--
-- Name: cms_theme_data; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.cms_theme_data (
    id integer NOT NULL,
    theme character varying(255),
    data text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.cms_theme_data OWNER TO justice;

--
-- Name: cms_theme_data_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.cms_theme_data_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_data_id_seq OWNER TO justice;

--
-- Name: cms_theme_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.cms_theme_data_id_seq OWNED BY public.cms_theme_data.id;


--
-- Name: cms_theme_logs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.cms_theme_logs (
    id integer NOT NULL,
    type character varying(20) NOT NULL,
    theme character varying(255),
    template character varying(255),
    old_template character varying(255),
    content text,
    old_content text,
    user_id integer,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.cms_theme_logs OWNER TO justice;

--
-- Name: cms_theme_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.cms_theme_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_logs_id_seq OWNER TO justice;

--
-- Name: cms_theme_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.cms_theme_logs_id_seq OWNED BY public.cms_theme_logs.id;


--
-- Name: cms_theme_templates; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.cms_theme_templates (
    id integer NOT NULL,
    source character varying(255) NOT NULL,
    path character varying(255) NOT NULL,
    content text NOT NULL,
    file_size integer NOT NULL,
    updated_at timestamp(0) without time zone,
    deleted_at timestamp(0) without time zone
);


ALTER TABLE public.cms_theme_templates OWNER TO justice;

--
-- Name: cms_theme_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.cms_theme_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_templates_id_seq OWNER TO justice;

--
-- Name: cms_theme_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.cms_theme_templates_id_seq OWNED BY public.cms_theme_templates.id;


--
-- Name: deferred_bindings; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.deferred_bindings (
    id integer NOT NULL,
    master_type character varying(255) NOT NULL,
    master_field character varying(255) NOT NULL,
    slave_type character varying(255) NOT NULL,
    slave_id character varying(255) NOT NULL,
    session_key character varying(255) NOT NULL,
    is_bind boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    pivot_data text
);


ALTER TABLE public.deferred_bindings OWNER TO justice;

--
-- Name: deferred_bindings_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.deferred_bindings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.deferred_bindings_id_seq OWNER TO justice;

--
-- Name: deferred_bindings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.deferred_bindings_id_seq OWNED BY public.deferred_bindings.id;


--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.failed_jobs (
    id integer NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    failed_at timestamp(0) without time zone,
    exception text,
    uuid character varying(255)
);


ALTER TABLE public.failed_jobs OWNER TO justice;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.failed_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.failed_jobs_id_seq OWNER TO justice;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: job_batches; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


ALTER TABLE public.job_batches OWNER TO justice;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE public.jobs OWNER TO justice;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_id_seq OWNER TO justice;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO justice;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO justice;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: winter_location_countries; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_location_countries (
    id integer NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    is_pinned boolean DEFAULT false NOT NULL
);


ALTER TABLE public.winter_location_countries OWNER TO justice;

--
-- Name: rainlab_location_countries_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_location_countries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_location_countries_id_seq OWNER TO justice;

--
-- Name: rainlab_location_countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_location_countries_id_seq OWNED BY public.winter_location_countries.id;


--
-- Name: winter_location_states; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_location_states (
    id integer NOT NULL,
    country_id integer NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL
);


ALTER TABLE public.winter_location_states OWNER TO justice;

--
-- Name: rainlab_location_states_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_location_states_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_location_states_id_seq OWNER TO justice;

--
-- Name: rainlab_location_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_location_states_id_seq OWNED BY public.winter_location_states.id;


--
-- Name: winter_translate_attributes; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_translate_attributes (
    id integer NOT NULL,
    locale character varying(255) NOT NULL,
    model_id character varying(255),
    model_type character varying(255),
    attribute_data text
);


ALTER TABLE public.winter_translate_attributes OWNER TO justice;

--
-- Name: rainlab_translate_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_translate_attributes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_attributes_id_seq OWNER TO justice;

--
-- Name: rainlab_translate_attributes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_translate_attributes_id_seq OWNED BY public.winter_translate_attributes.id;


--
-- Name: winter_translate_indexes; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_translate_indexes (
    id integer NOT NULL,
    locale character varying(255) NOT NULL,
    model_id character varying(255),
    model_type character varying(255),
    item character varying(255),
    value text
);


ALTER TABLE public.winter_translate_indexes OWNER TO justice;

--
-- Name: rainlab_translate_indexes_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_translate_indexes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_indexes_id_seq OWNER TO justice;

--
-- Name: rainlab_translate_indexes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_translate_indexes_id_seq OWNED BY public.winter_translate_indexes.id;


--
-- Name: winter_translate_locales; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_translate_locales (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255),
    is_default boolean DEFAULT false NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.winter_translate_locales OWNER TO justice;

--
-- Name: rainlab_translate_locales_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_translate_locales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_locales_id_seq OWNER TO justice;

--
-- Name: rainlab_translate_locales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_translate_locales_id_seq OWNED BY public.winter_translate_locales.id;


--
-- Name: winter_translate_messages; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.winter_translate_messages (
    id integer NOT NULL,
    code character varying(255),
    message_data text,
    found boolean DEFAULT true NOT NULL,
    code_pre_2_1_0 character varying(255)
);


ALTER TABLE public.winter_translate_messages OWNER TO justice;

--
-- Name: rainlab_translate_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.rainlab_translate_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_messages_id_seq OWNER TO justice;

--
-- Name: rainlab_translate_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.rainlab_translate_messages_id_seq OWNED BY public.winter_translate_messages.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    payload text,
    last_activity integer,
    user_id integer,
    ip_address character varying(45),
    user_agent text
);


ALTER TABLE public.sessions OWNER TO justice;

--
-- Name: system_event_logs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_event_logs (
    id integer NOT NULL,
    level character varying(255),
    message text,
    details text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_event_logs OWNER TO justice;

--
-- Name: system_event_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_event_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_event_logs_id_seq OWNER TO justice;

--
-- Name: system_event_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_event_logs_id_seq OWNED BY public.system_event_logs.id;


--
-- Name: system_files; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_files (
    id integer NOT NULL,
    disk_name character varying(255) NOT NULL,
    file_name character varying(255) NOT NULL,
    file_size integer NOT NULL,
    content_type character varying(255) NOT NULL,
    title character varying(255),
    description text,
    field character varying(255),
    attachment_id character varying(255),
    attachment_type character varying(255),
    is_public boolean DEFAULT true NOT NULL,
    sort_order integer,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_files OWNER TO justice;

--
-- Name: system_files_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_files_id_seq OWNER TO justice;

--
-- Name: system_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_files_id_seq OWNED BY public.system_files.id;


--
-- Name: system_mail_layouts; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_mail_layouts (
    id integer NOT NULL,
    name character varying(255),
    code character varying(255),
    content_html text,
    content_text text,
    content_css text,
    is_locked boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    options text
);


ALTER TABLE public.system_mail_layouts OWNER TO justice;

--
-- Name: system_mail_layouts_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_mail_layouts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_layouts_id_seq OWNER TO justice;

--
-- Name: system_mail_layouts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_mail_layouts_id_seq OWNED BY public.system_mail_layouts.id;


--
-- Name: system_mail_partials; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_mail_partials (
    id integer NOT NULL,
    name character varying(255),
    code character varying(255),
    content_html text,
    content_text text,
    is_custom boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_mail_partials OWNER TO justice;

--
-- Name: system_mail_partials_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_mail_partials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_partials_id_seq OWNER TO justice;

--
-- Name: system_mail_partials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_mail_partials_id_seq OWNED BY public.system_mail_partials.id;


--
-- Name: system_mail_templates; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_mail_templates (
    id integer NOT NULL,
    code character varying(255),
    subject character varying(255),
    description text,
    content_html text,
    content_text text,
    layout_id integer,
    is_custom boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_mail_templates OWNER TO justice;

--
-- Name: system_mail_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_mail_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_templates_id_seq OWNER TO justice;

--
-- Name: system_mail_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_mail_templates_id_seq OWNED BY public.system_mail_templates.id;


--
-- Name: system_parameters; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_parameters (
    id integer NOT NULL,
    namespace character varying(100) NOT NULL,
    "group" character varying(50) NOT NULL,
    item character varying(150) NOT NULL,
    value text
);


ALTER TABLE public.system_parameters OWNER TO justice;

--
-- Name: system_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_parameters_id_seq OWNER TO justice;

--
-- Name: system_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_parameters_id_seq OWNED BY public.system_parameters.id;


--
-- Name: system_plugin_history; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_plugin_history (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    type character varying(20) NOT NULL,
    version character varying(50) NOT NULL,
    detail text,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.system_plugin_history OWNER TO justice;

--
-- Name: system_plugin_history_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_plugin_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_plugin_history_id_seq OWNER TO justice;

--
-- Name: system_plugin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_plugin_history_id_seq OWNED BY public.system_plugin_history.id;


--
-- Name: system_plugin_versions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_plugin_versions (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    version character varying(50) NOT NULL,
    created_at timestamp(0) without time zone,
    is_disabled boolean DEFAULT false NOT NULL,
    is_frozen boolean DEFAULT false NOT NULL,
    acorn_infrastructure boolean DEFAULT false NOT NULL
);


ALTER TABLE public.system_plugin_versions OWNER TO justice;

--
-- Name: system_plugin_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_plugin_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_plugin_versions_id_seq OWNER TO justice;

--
-- Name: system_plugin_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_plugin_versions_id_seq OWNED BY public.system_plugin_versions.id;


--
-- Name: system_request_logs; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_request_logs (
    id integer NOT NULL,
    status_code integer,
    url character varying(255),
    referer text,
    count integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_request_logs OWNER TO justice;

--
-- Name: system_request_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_request_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_request_logs_id_seq OWNER TO justice;

--
-- Name: system_request_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_request_logs_id_seq OWNED BY public.system_request_logs.id;


--
-- Name: system_revisions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_revisions (
    id integer NOT NULL,
    user_id integer,
    field character varying(255),
    "cast" character varying(255),
    old_value text,
    new_value text,
    revisionable_type character varying(255) NOT NULL,
    revisionable_id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_revisions OWNER TO justice;

--
-- Name: system_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_revisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_revisions_id_seq OWNER TO justice;

--
-- Name: system_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_revisions_id_seq OWNED BY public.system_revisions.id;


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.system_settings (
    id integer NOT NULL,
    item character varying(255),
    value text
);


ALTER TABLE public.system_settings OWNER TO justice;

--
-- Name: system_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: justice
--

CREATE SEQUENCE public.system_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_settings_id_seq OWNER TO justice;

--
-- Name: system_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: justice
--

ALTER SEQUENCE public.system_settings_id_seq OWNED BY public.system_settings.id;


--
-- Name: backend_access_log id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_access_log ALTER COLUMN id SET DEFAULT nextval('public.backend_access_log_id_seq'::regclass);


--
-- Name: backend_user_groups id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_groups ALTER COLUMN id SET DEFAULT nextval('public.backend_user_groups_id_seq'::regclass);


--
-- Name: backend_user_preferences id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_preferences ALTER COLUMN id SET DEFAULT nextval('public.backend_user_preferences_id_seq'::regclass);


--
-- Name: backend_user_roles id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_roles ALTER COLUMN id SET DEFAULT nextval('public.backend_user_roles_id_seq'::regclass);


--
-- Name: backend_user_throttle id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_throttle ALTER COLUMN id SET DEFAULT nextval('public.backend_user_throttle_id_seq'::regclass);


--
-- Name: backend_users id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_users ALTER COLUMN id SET DEFAULT nextval('public.backend_users_id_seq'::regclass);


--
-- Name: cms_theme_data id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_data ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_data_id_seq'::regclass);


--
-- Name: cms_theme_logs id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_logs ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_logs_id_seq'::regclass);


--
-- Name: cms_theme_templates id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_templates ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_templates_id_seq'::regclass);


--
-- Name: deferred_bindings id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.deferred_bindings ALTER COLUMN id SET DEFAULT nextval('public.deferred_bindings_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: system_event_logs id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_event_logs ALTER COLUMN id SET DEFAULT nextval('public.system_event_logs_id_seq'::regclass);


--
-- Name: system_files id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_files ALTER COLUMN id SET DEFAULT nextval('public.system_files_id_seq'::regclass);


--
-- Name: system_mail_layouts id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_layouts ALTER COLUMN id SET DEFAULT nextval('public.system_mail_layouts_id_seq'::regclass);


--
-- Name: system_mail_partials id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_partials ALTER COLUMN id SET DEFAULT nextval('public.system_mail_partials_id_seq'::regclass);


--
-- Name: system_mail_templates id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_templates ALTER COLUMN id SET DEFAULT nextval('public.system_mail_templates_id_seq'::regclass);


--
-- Name: system_parameters id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_parameters ALTER COLUMN id SET DEFAULT nextval('public.system_parameters_id_seq'::regclass);


--
-- Name: system_plugin_history id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_plugin_history ALTER COLUMN id SET DEFAULT nextval('public.system_plugin_history_id_seq'::regclass);


--
-- Name: system_plugin_versions id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_plugin_versions ALTER COLUMN id SET DEFAULT nextval('public.system_plugin_versions_id_seq'::regclass);


--
-- Name: system_request_logs id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_request_logs ALTER COLUMN id SET DEFAULT nextval('public.system_request_logs_id_seq'::regclass);


--
-- Name: system_revisions id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_revisions ALTER COLUMN id SET DEFAULT nextval('public.system_revisions_id_seq'::regclass);


--
-- Name: system_settings id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_settings ALTER COLUMN id SET DEFAULT nextval('public.system_settings_id_seq'::regclass);


--
-- Name: winter_location_countries id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_location_countries ALTER COLUMN id SET DEFAULT nextval('public.rainlab_location_countries_id_seq'::regclass);


--
-- Name: winter_location_states id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_location_states ALTER COLUMN id SET DEFAULT nextval('public.rainlab_location_states_id_seq'::regclass);


--
-- Name: winter_translate_attributes id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_attributes ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_attributes_id_seq'::regclass);


--
-- Name: winter_translate_indexes id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_indexes ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_indexes_id_seq'::regclass);


--
-- Name: winter_translate_locales id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_locales ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_locales_id_seq'::regclass);


--
-- Name: winter_translate_messages id; Type: DEFAULT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_messages ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_messages_id_seq'::regclass);


--
-- Data for Name: acorn_lojistiks_computer_products; Type: TABLE DATA; Schema: product; Owner: justice
--

COPY product.acorn_lojistiks_computer_products (id, electronic_product_id, memory, "HDD_size", processor_version, server_id, created_at_event_id, created_by_user_id, processor_type, response) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_electronic_products; Type: TABLE DATA; Schema: product; Owner: justice
--

COPY product.acorn_lojistiks_electronic_products (id, product_id, server_id, created_at_event_id, voltage, created_by_user_id, response) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_calendars; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_calendar_calendars (id, name, description, sync_file, sync_format, created_at, updated_at, owner_user_id, owner_user_group_id, permissions, system) FROM stdin;
436bb16e-3be1-4fe2-8786-ba018219d266	Default	\N	\N	0	2024-10-19 13:37:23	\N	\N	\N	1	f
9a0600eb-0033-4ef9-9b32-8d91903ac9ae	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
a92cf50f-7e6e-4a00-b1bd-1848a58a0251	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
6faa432c-e3b5-11ef-ac7d-af7a8110175c	Entity create and update events	\N	\N	0	2024-10-19 13:37:23	\N	\N	\N	1	f
9e23cac5-64df-4857-ab56-f1f47aff47a0	Legalcase	\N	\N	0	2025-02-05 14:27:09	\N	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	1	f
9e23caeb-3503-4fad-b2dd-560534ca0564	LegalcaseEvidence	\N	\N	0	2025-02-05 14:27:34	\N	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	1	f
0db9a50e-d24f-49bb-93a5-1740c6ab4b4a	Legalcase Category	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
9e2418f9-6d31-4d54-bdb8-a11b1a26b278	ScannedDocument	\N	\N	0	2025-02-05 18:05:50	\N	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	1	f
9e242335-4cbf-4f35-b878-54140557b031	Crime	\N	\N	0	2025-02-05 18:34:27	\N	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	1	f
9e242396-0152-42df-bf65-958c72afdf1d	LegalcaseDefendant	\N	\N	0	2025-02-05 18:35:30	\N	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	1	f
9e2423a2-1473-4892-8cfa-d8df52ebb7c7	DefendantCrime	\N	\N	0	2025-02-05 18:35:38	\N	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	1	f
869b83cd-178e-409a-a9c6-328e4481dae7	Create Warrant	\N	\N	0	2024-10-19 13:37:23	\N	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	1	f
32075cfa-40d1-4bc6-b8f2-14d3f9177b1e	Legalcase Prosecutor	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
10afa2b1-0e4d-48d5-815f-3c374dbbccb6	Legalcase Prosecutor	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
6bbb67c6-76f1-44ea-9160-cb05f9e1cdab	Legalcase Prosecutor	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
ceea8856-e4c8-11ef-8719-5f58c97885a2	Default	\N	\N	0	2024-10-19 13:37:23	\N	\N	\N	1	t
9e279359-2186-4e64-b81f-14cf227b6834	CrimeType	\N	\N	0	2025-02-07 11:35:30	\N	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	1	f
798eaf60-f210-4847-adbb-11090b57c20c	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
77f31f32-c218-40a5-aa0a-db198fffa151	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
9e338220-afa3-4a32-9064-7891597314cc	Trial	\N	\N	0	2025-02-13 09:57:17	\N	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	1	f
9e33822d-ec49-4011-ad70-80d005634516	LegalcasePlaintiff	\N	\N	0	2025-02-13 09:57:25	\N	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	1	f
3cedce66-d0ce-4aa1-a5f8-cb144ac32614	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
c7348d4f-731f-4aaa-8b4e-a3fa3ea1bb8e	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
1090c88a-d7b0-4103-a0f7-67e9e9466659	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
6890e33a-a35d-43d4-8a0b-25108aba2125	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
f360a98f-377d-40d4-8151-75637625c262	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
674db9d8-6edf-43d5-8623-3f2f0281b458	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
56151d2f-87ff-49c7-a098-18745def5863	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
e195d923-2434-476c-a7e0-3a8519c8fbec	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
3931f04a-5f9c-4136-86dc-fac6d43a701e	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
9ee71f4d-a490-45ae-a938-0bd49b90f8d6	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
629f6d76-0f86-415a-a5a4-48a138e4ddc8	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
cd83b4a4-901c-44bb-87f0-e00d49966dc1	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
2d80f4f0-7834-4213-8a5b-9849bf3ae9ac	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
fe78bd00-ead8-4f3d-8e99-5d452454494e	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
96f55ea7-8c04-4a28-bbc7-207f544003c7	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
61c25cfb-ae3a-4890-b9de-e2c42de5a4a7	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
040f8e66-5e47-418f-b271-368541787639	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
5d3196cf-0fb3-4909-8bea-4f4c4a976c6c	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
366bf8c2-f009-44a1-882d-bfcff37de693	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
a534e082-1a68-472b-bb7f-2c76e072d22e	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
f791ed09-5ef5-4582-ac75-f9e08cba2e6a	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
40761699-1806-4234-89bd-cdf14717aff9	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
f9ecb922-cf88-413a-84fe-f0bd217bbf72	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
43d27df0-6bb9-43ce-8947-43870dea4550	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
9a2f7361-0a71-4808-bde7-f35eb170b68b	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
b6a9872e-5396-4da5-8d12-63961a3d3147	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
15010a55-d9a7-4bc3-8202-4236f9b067fd	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
59849f1f-374d-449c-8ccb-87808d724437	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
2c00048b-9571-4392-b08e-84269fe59be0	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
3673a4ca-19e9-47e1-b8e3-1208abc37b84	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
e5fda23f-ee50-49c6-9927-a7fdd9bd7d62	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
42a376e2-019a-413f-908d-94d9525a0394	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
90604c74-0dc6-4b9e-867b-61c98ad7b36f	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
6b567914-e3cb-4ef1-957a-d2df8e398122	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
3b351c5f-712a-4d2f-9e3f-beea3009222b	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
e890d26a-a477-4409-bd24-00e5b132b43e	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
b888e8ee-c6a5-4e0d-bf38-a04eb8f5e2c4	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
bb10b29b-9910-409e-a92f-69b8e544c006	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
a0f5dbaa-4f85-458a-87f6-8b6a2369e7e5	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
f9b95be0-5328-4008-88cd-ea8bb3a9db4e	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
fe730b86-0cc7-42e6-98b1-5321163f001a	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
9bdacead-5d04-4bce-9395-7fe532a25b26	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
d494c51e-a71c-416b-baa0-e8b9eff3f9b8	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
7cfb1d9c-66e3-44f5-9dd7-8067cfbb16a0	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
cff486f2-1774-4067-b7c0-824aad711d8b	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
4f07e583-bb25-419b-b19f-e9684d01246f	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
0262df51-b8d6-49c5-84e9-0b312da4e6a4	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
901d79ee-d53d-489d-b2d7-d6257c161c03	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
7852ed38-f072-4ade-919c-e9176c6d61ce	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
ed10155e-aba0-4967-a803-f4e58c7ccd37	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
f3bc49bc-eac7-11ef-9e4a-1740a039dada	Activity log	\N	\N	0	2024-10-19 13:37:23	\N	\N	\N	1	f
00227f53-5c07-4f1c-a2cd-34a1be42e6d4	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
320ddf9c-e6d8-493d-852b-006815e10590	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
23e2fb27-3a34-41b9-96e9-40e4cb757879	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
fa782d57-0e76-4da1-9591-7b7297f67702	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
daa92132-2f3f-46e3-a8b1-4580b08630f6	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
15f1df74-aed5-4bfc-acfa-b093b2581bfe	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
90455d8a-7dfc-477d-a3cb-8598a64915b0	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
9892e6d2-24bf-457e-98dc-42c07a87ef36	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
626e0104-f86c-4af7-bff6-7f1b5d18d757	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
8ad77957-40c3-45fa-8c16-e10a5921349e	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
73967297-5f5a-4a93-8cc0-7ad1084caf04	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
24c6a921-641c-4951-898e-a0aa0d0993b0	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
8674a41b-d8cd-43c2-a79d-e1040e93d111	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
5b6be8a5-17a6-4874-8079-2076068eb9c0	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
bfc8d177-8e6e-46d6-8e95-5446ef400b42	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
200cf327-0071-4c6e-9bb1-7067201715ef	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
9ab13570-a3d1-4ad4-9812-a0de9fe7342e	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
32ce47ec-2057-4d94-bc81-42e07476be3f	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
bf462bc2-e8d0-4dbc-8073-b96aa601bee1	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
65fd1885-5d8b-4a2a-845e-40807bd3d174	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
7db17a65-1e97-4cff-bf99-e6675b07b5f5	Legalcase Category	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
3ecb7cd1-6872-4e3b-9d0f-7c045bb68e18	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
c7aa60b3-56e7-4934-804e-d9d5db8b3ecd	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
05267fc4-d8dc-4aca-aa4e-fcc8479cafb8	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
6ac30d28-7467-40c4-bd38-21baceb0745e	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
7c4c335b-c4d7-407f-9acc-f1bbcec44d54	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
091154a6-7a3d-43c0-935f-7b8519a32f23	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
ee49be31-d948-453d-b1cd-8b662646b2e2	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
3f21d539-fb06-473c-b7cd-4ba711368844	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
fea70966-3c9e-4340-8f33-ddc6fcdab1d4	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
faef8dc1-aefd-418d-808c-eb00697c0586	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
4656684f-2e4b-4545-8974-6b92e71fbb91	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
cff10a2d-397f-4a65-ba0f-b77ca71f9a91	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
d1b3401a-5bb9-4e5a-b67f-0b030e773131	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
15e2438b-b1ad-473a-bad7-83c98e1bc0b0	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
faec14dd-5c35-4455-b035-287e1395a1eb	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
7fbc3b73-0918-4d58-b8bf-4f6245019560	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
53642915-4a7e-48b1-9a33-af28ac073565	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
ec4bb70e-bf22-40a1-9f21-b1b15f650e58	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
5261a4fc-38a0-4351-93bf-20d342c3449d	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
7b999975-83e8-4441-b130-5f81e69d3cd0	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
a1070399-b0fb-4049-8426-4a5c8a00fe53	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
35c6be74-1424-480f-a8f5-40df9b95bbc9	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
56486fcd-601a-41eb-91c8-ccbca739f55f	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
ff16acb8-2bdf-426e-a63e-a03dcb481c29	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
ae567e9f-3507-4386-94c7-8527893753d0	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
4392069f-7798-4cf2-abdc-91795268723a	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
8f38c45f-66d1-489f-a2eb-c4b9261a9cdc	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
7341e65d-7633-474e-ae90-aa4ddff78014	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
d6295bcf-2444-4bb7-9037-eb65f34aa4c5	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
6fdf4bc3-8f4d-4878-8284-99d7e6472b57	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
e7aa5fe1-1960-48cc-84c0-1b2e0319a9d8	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
1aa7cc6a-5105-4995-ba16-069d6af7b3cb	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
6cd0e316-ef23-40b9-8c5d-681c94c102b4	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
2a46659a-7380-40c9-a595-2b476f3de942	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
ec35c32e-d1e9-4203-b1e0-04622283b62a	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
b97a225d-e409-41fd-8fe9-3cab9f9800de	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
367aea46-8ffd-49d2-b670-d857bb633ee2	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
3a89567a-5d20-47ba-9093-a1e8d07fa71e	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
d8eff82e-761c-41ab-aeb6-bd19213e71a7	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
d4b713ac-713b-48fd-8df8-b3516c9e525d	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
573541b3-91ff-4b4d-a847-6129dd79de2a	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
6909da16-e70c-43e7-89a6-a9fee22cd178	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
6822526c-889b-4104-aa33-dfe65745bb0c	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
22c50aa2-2e72-4793-804e-ed60e59aaa1d	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
36cd0e95-8c0e-4886-ba15-72edba5af3af	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
7213b9c8-2464-40f1-af8d-fe61013b68f1	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
7826ef11-4c7b-478e-b6f0-b020d8b34483	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
290bdb8e-71d7-447d-9519-c8d510acf93c	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
8a831eb3-4aa2-4307-a774-1deeb149c4c1	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
b1e59e05-0ff7-4826-9f08-7fd6f24907f3	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
021e2c36-a1ce-4020-aa4a-5408f53ecdaa	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
a24662fa-7f6c-4e7a-89aa-13c5e8a16542	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
ceca2c4a-6ca9-4f7a-bab3-2c23c0947503	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
757a7b9d-d952-4569-b433-be1169034b8f	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
164231d1-9cd4-4daf-b267-87c1082075f3	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
8d98b4e4-ee3d-4cb8-8b46-33db893d2575	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
0b997364-4781-4ed6-b4bd-80b95b95ae31	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
c19cb39e-1ab1-4b7f-b88e-b3166d4b563f	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
ce5f810c-a7e3-4c93-acc7-6765af58c9fc	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
d9d30d37-a52b-4828-8909-e5785194cbcb	Crime Type	\N	\N	0	2024-10-19 13:37:23	\N	9d4aa2bc-d139-4fb7-8764-c847acf8a62f	\N	1	f
\.


--
-- Data for Name: acorn_calendar_event_part_user; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_calendar_event_part_user (event_part_id, user_id, role_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_event_part_user_group; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_calendar_event_part_user_group (event_part_id, user_group_id) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_event_parts; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_calendar_event_parts (id, event_id, name, description, start, "end", until, mask, mask_type, type_id, status_id, repeat_frequency, parent_event_part_id, location_id, locked_by_user_id, created_at, updated_at, repeat, alarm, instances_deleted) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_event_statuses; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_calendar_event_statuses (id, name, description, style, created_at, updated_at, system) FROM stdin;
3b6dfc60-d05a-4800-81b5-5ffd8ff4ba0c	Normal	\N	\N	\N	\N	t
4607a77c-3525-486a-bb25-2c2a8521b7e3	Tentative	\N	opacity:0.7;	\N	\N	t
14833f77-5802-429b-bbb7-4567df6e79d4	Conflict	\N	border:1px solid red;background-color:#fff;color:#000;font-weight:bold;	\N	\N	t
c4c3a3d0-e3b5-11ef-98b6-83c560e3d98a	created	\N	color:#050	\N	\N	f
cb75aa34-e3b5-11ef-abf2-a7e3fb05f16a	updated	\N	color:#005	\N	\N	f
9e255bf7-063b-42e4-a4c3-40c7d15051af	Test	\N		2025-02-06 09:08:58	\N	f
27446472-e4c9-11ef-bde0-9b663c96a619	Normal	\N	\N	\N	\N	t
fb2392de-e62e-11ef-b202-5fe79ff1071f	Cancelled	\N	text-decoration:line-through;border:1px dotted #fff;	\N	\N	t
7b432540-eac8-11ef-a9bc-434841a9f67b	acorn.calendar::lang.models.general.insert	\N	color:#fff	\N	\N	t
7c18bb7e-eac8-11ef-b4f2-ffae3296f461	acorn.calendar::lang.models.general.update	\N	color:#fff	\N	\N	t
7ceca4c0-eac8-11ef-b685-f7f3f278f676	acorn.calendar::lang.models.general.soft_delete	\N	color:#fff	\N	\N	t
f9690600-eac9-11ef-8002-5b2cbe0c12c0	acorn.calendar::lang.models.general.soft_undelete	\N	color:#fff	\N	\N	t
\.


--
-- Data for Name: acorn_calendar_event_types; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_calendar_event_types (id, name, description, whole_day, colour, style, created_at, updated_at, system, activity_log_related_oid) FROM stdin;
739c0ad9-d281-4d26-bdf6-7422f8683e5d	Normal	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	t	\N
97483930-3ad6-4207-af3f-c115976478d3	Meeting	\N	f	#C0392B	color:#fff	2024-10-19 13:37:23	\N	t	\N
3df0aed7-8d9e-43dd-9e92-f6ee3c7377ee	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
bb4fe086-5813-48f9-a391-68053ed465f3	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
7754c714-e3b5-11ef-84f2-2bd5b1a61b38	acorn_criminal_legalcase_related_events	\N	f	#dfdfdf		2024-10-19 13:37:23	\N	f	\N
bf1129a0-900f-4788-a6ac-d9bd8df84f7e	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
d2d3a194-6957-4d05-9a25-7af0a7444ad7	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
3fa3a751-f8d9-4b0b-80db-aa72d0366560	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
08da122f-3be7-4d3f-bda8-b4dede2316fd	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
436c0ca6-6a51-4812-83ad-d26e12a80218	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
9e255e16-9917-4e1e-9735-9bc828b1a255	rrr	\N	f	\N		2025-02-06 09:14:55	\N	f	\N
2f766546-e4c9-11ef-be8c-1f2daa98a10f	Normal	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	t	\N
0904667f-e5f1-4f25-a074-78123db3d23d	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
e19a4e05-1496-440b-8e94-69a235a67165	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
0772fca5-fd99-44b5-9d59-85a823556a3c	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
8630d12f-52ee-42be-aeeb-d7eace4220e9	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
0675808f-ef44-4673-b903-a9571df7013f	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
b5e24df5-c678-42c7-9862-8c3d57fc94fe	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
e32e5b2f-fa92-4647-8f0a-85ec25e4bbb2	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
fba8b093-acc5-4724-830c-f1776cb4c544	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
f37c318b-3dc2-4baf-8f01-5f987b06dfce	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
15eb2c08-3f1d-49ff-8e39-dedb5b37ce1c	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
f85a92be-bd69-4433-b0de-e3833519bd01	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
c567b4bd-2c05-46dd-816f-0db709494150	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
1de768af-50d2-4545-8e45-e64359d30c41	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
b907a161-395a-4c50-a317-3ba2b0c08316	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
63c2d928-7425-4900-acda-cd3483a5f0e2	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
3c941544-95a6-47f2-930d-3416f6bc0713	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
03feaeda-a352-45f7-9579-112bf730f1ce	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
b6ac94c3-16e4-4b26-9b5e-e9083f80efd0	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
28f09005-0527-4e95-bb52-6493d4e4128b	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
586e4b3f-46e2-4f0f-84bc-222adb759fca	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
482610e2-24ad-4584-8f81-4557964d1946	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
e75753ae-b0bd-4d55-859a-71b775e2b4d0	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
68b46732-6d47-4ad9-aaca-ee800cc43273	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
6918e14b-1d36-4049-9870-f09ab4a79412	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
0f79cd88-151d-46dd-9772-4f0c207c54be	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
f014cdf8-2503-4f97-893d-fcac3ba6ef64	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
289df4a9-4fca-41d6-83b3-7f817c7310d2	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
c10a85b7-f01c-4c2b-860b-004af7e66cc9	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
07c5fa09-db4f-46c1-8eaf-84cf00a65a96	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
b41175b4-596b-4d5c-8221-f0e10c183778	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
6babc5f0-9eed-4022-8d68-f0e4c27b7531	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
d6af2fd7-e31c-43f3-9ee6-7395530cf41d	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
018989f5-bfb0-47b9-ab1a-7c4c83372a28	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
0955cf9a-45ee-443b-8b0f-e834fa17b841	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
a5b5a468-c02d-4170-bf2c-bdaea308b8f4	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
34476e6e-a8b3-4712-b13e-f6ea3c1ee5ab	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
d81ac8a4-dd91-4699-bbde-0f7a9a2b5fa6	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
39de5954-e1e3-43d8-898c-f3fd6e59ec51	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
5d2ba9f3-1da5-4fd8-bd59-8ac43ef6f556	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
3cae4039-ae7a-41c0-81fe-d6b91a906603	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
5fab2be9-35e9-4d11-bd51-bbf5ba815e68	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
abd65b6e-fb0d-4833-9748-7da9a3224f1e	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
b98ee7d5-48dc-4a69-9137-47febea2c714	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
6870c255-94cf-42a1-9442-49f4c31cc6de	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
3a0d1f8e-e02f-4e59-932a-643b53a90bf6	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
43946f2a-6a41-4706-a4b1-b1e084be0dac	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
df4bb316-b3aa-44cd-8ec3-265fc8c48f6d	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
8506d1aa-bec2-4389-b064-758ac001a629	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
fc9f7702-eedb-4b83-aad1-eb5b5caeedc3	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
9f4c7f4c-db8e-415a-b4ad-7b549386b2e5	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
0aaa768c-ce2f-4078-88da-48dfbb9405d3	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
45ce2031-f53b-4b2c-942b-ab68f5810c09	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
7b432540-eac8-11ef-a9bc-434841a9f67b	INSERT	\N	f	#00390B	color:#fff	2024-10-19 13:37:23	\N	t	\N
7c18bb7e-eac8-11ef-b4f2-ffae3296f461	UPDATE	\N	f	#C0392B	color:#fff	2024-10-19 13:37:23	\N	t	\N
7ceca4c0-eac8-11ef-b685-f7f3f278f676	DELETE	\N	f	#Ca0020	color:#fff	2024-10-19 13:37:23	\N	t	\N
f9690600-eac9-11ef-8002-5b2cbe0c12c0	Soft un-DELETE	\N	f	#Ca0020	color:#fff	2024-10-19 13:37:23	\N	t	\N
09d3bd7e-20c1-4a38-a855-9d1965699b7c	justice legalcases	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22794
af48f08a-80f5-4616-ade3-cfe0ff960295	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
ae61d7f4-217a-4465-bd49-787538595a69	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
86f5ffa1-1155-4274-a05b-ceaf753f960c	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
b91f80a4-7155-41c3-8535-5f50c8a6b5d6	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
da922ec9-a7b4-4d8c-8eaf-1ccb15b7e871	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
1a040915-a2d1-4395-9dff-d62321f3c41a	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
5f6a6285-efd0-4b50-ad3b-ed1e421b02f7	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
77dd2b12-25b4-414d-a9dc-d572143991db	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
c757854a-d05f-4192-a3ae-72ba43a88629	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
059f6d1f-7dcc-45f3-992b-e145e6ad78d5	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
a3d6e0fd-5fab-4996-99b8-2e064afc460c	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
dbdcfb20-e6d7-4ff8-8fc5-4af718a32ed8	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
188ed96e-4908-4915-b021-19bc887fe767	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
789c1b42-5de1-401a-9cc0-944668e9d517	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
8480e5e5-7014-4a55-9cbc-11b0915ea485	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
42c47fd8-9d62-421e-aefb-3e9462f58658	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
0ca08299-c29e-4715-b0c9-d57d40cd4a55	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
98676434-0fe4-435a-b9e4-b272778776e8	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
a8d909b4-97c3-4f8e-813a-c93de61b6594	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
762c3796-bb20-43bc-a6b4-ebd6370d1364	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
2e83e431-c593-48d7-9efd-d71c09824192	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
263528da-86f0-40df-a98d-5bf68464b7b4	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
e1e76439-1f85-48c1-87a6-a3e0b7ac643f	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
66aec278-8509-4632-a1ec-4663360fca54	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
6612df84-f627-4beb-ae45-ae5e44fe1256	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
d3116d84-4df2-4600-a3a2-a35182365413	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
cb71d50c-41ea-4e69-8e37-cffb90eddd55	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
8aa720d5-0d58-4e70-bf6d-e22cfb9ccdf1	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
5fa3aa02-662c-4add-aa56-f2c169981e4c	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
03584176-f3d1-438d-8e16-eed854dbaaf9	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
7311f4da-32cc-46df-849e-e427a06673e9	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
6b82a12c-f163-4388-970b-e956518c6baa	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
d98e2dea-893e-42ac-b150-080663e14f75	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
55924d22-8d1c-4d90-8bac-c89c5ac69030	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
bb9c19bd-fb19-47e6-ae1b-36494fd97c27	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
b7931716-405d-4d91-a0f2-25526e36b8df	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
2e0d10f1-9fa1-48b4-9c51-33b1716a0ec7	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
43b700fc-e292-4f7f-9cea-e98adb16ecb4	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
c7fc2a3c-0bf5-4ec6-b8fc-3bd3da070449	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
62c31f0b-e208-4478-bd7b-f57d4d8baecd	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
5679e24e-2f42-41ba-ac00-000499e8562c	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
50bde220-e942-4f7d-91ca-49f41e018b2a	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
c92fabbd-d6ca-4e4a-a845-ea133af0a522	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
22473b98-44eb-4338-a7dc-04faf1b3df6c	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
845eba27-aa70-4dbc-9fdc-02061da1e5f5	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
d00430d6-929c-4c87-99b6-1b260c9e9e26	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
b6ff94ff-6d54-48b0-afa5-040b84aea634	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
ccb8b49e-dbeb-4a23-a18a-928fb5ad9e8a	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
ba289897-998a-4d3d-9387-f7e4b72bed0f	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
46c4ecdc-7c13-4b48-b035-7675c4197c0e	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
9a15f071-de17-493e-857d-4a1fbdfb8312	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
660c44a1-3d2c-433a-ac3c-f6f5bf3cbc35	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
7f8017ec-c513-437e-9a89-21cf01a0aecb	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
17b2c5fc-de4e-4723-94d7-e822b0fa03e8	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
43ff3045-20fe-4a7f-8445-25ebdb15746e	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
eca213a5-6e8d-4c6c-895b-a7536bdec9ae	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
c5d47514-43b4-42c4-8fd0-c7546919a4e7	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
e9fec54c-e630-4238-ae11-53934b1af319	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
a8353837-5218-49fc-af19-47b413d79d9c	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
1197d1a2-7a8f-42ef-ba09-23fe06a1d66b	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
1c7650be-8a5b-4354-be77-d0088b875a51	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
30785ec6-f4c7-4d14-bca3-54ed1c96bdf0	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
d776f561-6b3b-4c51-bee7-20c0ac00a101	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
81a1cc3d-6578-4e88-9442-c1591e0f3473	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
690addb2-04ba-454c-8442-d0153cde9c20	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
3b26800c-50de-4883-ad24-5d70f0b4bb5f	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
7559a3c6-a92d-4785-96ba-069ddbc11fa3	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
e6f094fc-d095-42c0-b27e-dc6d7018ede3	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
8e8e592c-6214-4727-b01c-18e4349b7b5a	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
d03b40ed-250f-4dee-b877-901c0d4bc887	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
9461a505-9963-439f-952b-3742e90a8a4b	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
0e0fc3a9-ec60-4f74-8fab-c463e9e2be49	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
76c0edd1-acd6-4c5d-95a1-711873bdb490	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
93bc5b0a-6172-46ae-ac36-9f198ce891af	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
9692b62f-3154-4643-9404-aa96e8cad7db	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
3bea2cb8-44db-4132-9a9d-6da6702f034b	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
2a792b6b-7bcd-4dc5-946b-73ae68f2a7fe	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
535afe53-2498-4b80-b2cb-ec6cdfb10b58	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
9740bb5d-7203-4dae-bdf7-17fd00507d8d	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
137f0049-c7d6-4e6e-b9d8-316ae58e31c0	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
c40a888f-b6c1-447d-97d0-807b763a7bf2	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
15c9eaa6-b1d0-4c5e-b53c-fedb5b57947c	criminal crime types	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22636
2a1b0e79-161a-4d32-a552-516bb29e11e1	criminal legalcase types	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	52218
4c3bed8a-0433-4fce-bdd0-6971a583b773	lojistiks measurement units	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22890
f59fc590-93a8-45e4-9a00-35c3ebf0303a	lojistiks vehicle types	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22992
55c34a6f-d5c1-4f2c-b507-5705d1aa3530	lojistiks brands	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22866
3a4f0d0e-0011-4ebb-b175-0307c3ff1249	criminal legalcase defendants	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22673
8a82318e-6640-4a2b-9dec-ed5e44236361	criminal crimes	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22644
76b0e47f-9357-4066-98ff-5881098cfdfc	criminal sentence types	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22705
80e62009-dcbc-4308-80e7-fc641953c2de	criminal detention methods	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22661
3584d268-8b3e-46c0-a514-986739a15d27	criminal detention reasons	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22667
143af584-a987-43a5-83b6-b1e6792f7a91	justice warrant types	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22806
493a3d93-f9c1-4f4a-b047-39f0ee9a8d52	finance currencies	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22727
7671912f-1f12-452b-aba9-30d8a09b56fb	criminal defendant crimes	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22650
e6155bd3-6eca-474e-8e70-4e5eecff09e6	lojistiks transfers	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22985
e96eb5cc-af3d-41db-92a1-58772e9bb84a	criminal crime sentences	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22631
34862c6f-b5b7-4a3d-b392-d20b6999c27e	criminal trials	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22723
31996f45-7d44-4443-ac7e-e3d70db13bab	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
aa62c09e-c71c-431c-ac8b-b89e082e8c5d	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
172b7a25-4e4e-4aba-a4ae-b4be2da81f80	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
017b4bc7-137b-45b3-b3bc-79046d86f8d7	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
86239ac9-fffb-4672-b565-13435e644dfe	justice warrants	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22812
34f250b5-4a31-4ed5-a8b4-b617f7459b6b	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
e73db9c4-25d9-45eb-9112-7abc29490bd9	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
d9fea4df-521a-439e-959e-6ae21c7fcc08	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
1401dd93-3df8-4610-92e8-46ca7fd29a51	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
56961985-75df-453c-8d19-4672de435460	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
46af8e6e-37c6-4dca-a2d0-b4634644d9b5	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
b950ed8b-3f3d-4f26-9f3e-8697f096d1b5	criminal legalcase plaintiffs	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22683
978f6832-ff2a-4a6c-bbb7-5db012becebe	criminal legalcase witnesses	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22697
09c2d991-8af0-48c7-86f8-9f71a367549f	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
bc516489-72d4-4884-a9d3-0919b44c228e	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
5ec59f21-a669-4def-8da9-1b57127ec853	criminal legalcase prosecutor	\N	f	\N	\N	2024-10-19 13:37:23	\N	f	22687
fee0b06d-4af0-4a05-ba58-f6b93376fd7a	Create	\N	f	#091386	color:#fff	2024-10-19 13:37:23	\N	f	\N
\.


--
-- Data for Name: acorn_calendar_events; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_calendar_events (id, calendar_id, external_url, created_at, updated_at, owner_user_id, owner_user_group_id, permissions) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_instances; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_calendar_instances (id, date, event_part_id, instance_num, instance_start, instance_end) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_appeals; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_appeals (id, legalcase_id, created_at_event_id, created_by_user_id, event_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_crime_evidence; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_crime_evidence (defendant_crime_id, legalcase_evidence_id, created_at) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_crime_sentences; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_crime_sentences (id, defendant_crime_id, sentence_type_id, amount, suspended, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_crime_types; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_crime_types (id, name, parent_crime_type_id, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_crimes; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_crimes (id, name, crime_type_id, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_defendant_crimes; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_defendant_crimes (id, legalcase_defendant_id, crime_id, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_defendant_detentions; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_defendant_detentions (id, transfer_id, detention_reason_id, detention_method_id, actual_release_transfer_id, legalcase_defendant_id, description) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_detention_methods; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_detention_methods (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_detention_reasons; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_detention_reasons (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_legalcase_defendants; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_legalcase_defendants (id, legalcase_id, user_id, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_legalcase_evidence; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_legalcase_evidence (id, legalcase_id, name, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_legalcase_plaintiffs; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_legalcase_plaintiffs (id, legalcase_id, user_id, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_legalcase_prosecutor; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_legalcase_prosecutor (id, legalcase_id, user_id, user_group_id, created_at_event_id, created_by_user_id, description, updated_at_event_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_legalcase_related_events; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_legalcase_related_events (legalcase_id, id, created_by_user_id, event_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_legalcase_types; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_legalcase_types (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_legalcase_witnesses; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_legalcase_witnesses (id, user_id, legalcase_id, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_legalcases; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_legalcases (id, legalcase_id, server_id, judge_committee_user_group_id, legalcase_type_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_sentence_types; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_sentence_types (id, name, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_session_recordings; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_session_recordings (id, trial_session_id, created_at_event_id, created_by_user_id, description, name, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_trial_judges; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_trial_judges (id, trial_id, user_id, user_group_id, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_trial_sessions; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_trial_sessions (id, trial_id, created_at_event_id, created_by_user_id, event_id) FROM stdin;
\.


--
-- Data for Name: acorn_criminal_trials; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_criminal_trials (id, legalcase_id, created_at_event_id, created_by_user_id, event_id) FROM stdin;
\.


--
-- Data for Name: acorn_finance_currencies; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_finance_currencies (id, name, shortname, symbol, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_finance_invoices; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_finance_invoices (id, number, currency_id, mark_paid, amount, payer_user_id, payer_user_group_id, payee_user_id, payee_user_group_id, created_event_id, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_finance_payments; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_finance_payments (id, invoice_id, currency_id, amount, number, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_finance_purchases; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_finance_purchases (id, number, mark_paid, currency_id, amount, payer_user_id, payer_user_group_id, payee_user_id, payee_user_group_id, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_finance_receipts; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_finance_receipts (id, purchase_id, number, currency_id, amount, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_justice_legalcase_categories; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_justice_legalcase_categories (id, name, parent_legalcase_category_id, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_justice_legalcase_identifiers; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_justice_legalcase_identifiers (id, legalcase_id, name, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_justice_legalcase_legalcase_category; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_justice_legalcase_legalcase_category (legalcase_id, legalcase_category_id, created_at_event_id, created_by_user_id, description, updated_at_event_id) FROM stdin;
\.


--
-- Data for Name: acorn_justice_legalcases; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_justice_legalcases (id, created_at_event_id, created_by_user_id, name, closed_at_event_id, owner_user_group_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_justice_scanned_documents; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_justice_scanned_documents (id, name, document, created_by_user_id, created_at_event_id, legalcase_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_justice_warrant_types; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_justice_warrant_types (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_justice_warrants; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_justice_warrants (id, created_at_event_id, created_by_user_id, user_id, warrant_type_id, legalcase_id, revoked_at_event_id, description, updated_at_event_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_location_addresses; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_location_addresses (id, name, number, image, area_id, gps_id, server_id, created_by_user_id, created_at, response, lookup_id, description) FROM stdin;
9d6a4b02-b2d3-401a-bfe7-0b6768ea4f9a			\N	d6b3135a-972a-4fa2-b828-f3eb54233a9c	9d6a4b02-88cd-4dad-8f5d-e0a796e02932	385a4d85-31d0-415c-960d-defb9298b432	\N	2024-11-05 09:21:46	200 DataChange event for () Dispatched	\N	\N
5792ec77-8e1d-4d8d-b480-ed1286ec2a03	Court buildings		\N	70ae737a-d840-48ce-b1e4-d38db5a85d6f	e804a8f7-db9c-4c69-ae04-2df706ab07e6	385a4d85-31d0-415c-960d-defb9298b432	\N	2024-11-04 06:30:06	200 DataChange event for () Dispatched	\N	\N
\.


--
-- Data for Name: acorn_location_area_types; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_location_area_types (id, name, server_id, created_at, created_by_user_id, response, description) FROM stdin;
b8f142f9-54c0-426c-81a8-23a9cdd17e59	Country	385a4d85-31d0-415c-960d-defb9298b432	2024-10-19 11:37:20	\N	500 <!DOCTYPE html>\n<html lang="en">\n    <head>\n        <meta charset="utf-8">\n        <title>Exception</title>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/css/styles.css" rel="stylesheet">\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shCore.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushPhp.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushXml.js"></script>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/styles/shCore.css">\n    </head>\n    <body>\n        <div class="container">\n\n            <h1><i class="icon-power-off warning"></i> Error</h1>\n\n            <p class="lead">We're sorry, but an unhandled error occurred. Please see the details below.</p>\n\n            <div class="exception-name-block">\n                <div>public.acorn_location_area_types =&gt; Acorn\\Location\\Models\\Area =&gt; acorn_location_areas does not match</div>\n                <p>/var/www/acorn-lojistiks/modules/acorn/traits/PathsHelper.php <span>line</span> 328</p>\n            </div>\n\n            <ul class="indicators">\n                <li>\n                    <h3>Type</h3>\n                    <p>Undefined</p>\n                </li>\n                <li>\n                    <h3>Exception</h3>\n                    <p>Exception</p>\n                </li>\n            </ul>\n\n            <pre class="brush: php">    {\n        $class = self::fullyQualifiedModelClassFromTableName($tableName);\n        $model = new $class;\n        $fullyQualifiedClassTableName = $model-&gt;getTable();\n        $unqualifiedClassTableName    = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $fullyQualifiedClassTableName);\n        $unqualifiedTableName         = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $tableName);\n        if ($unqualifiedClassTableName != $unqualifiedTableName) throw new Exception(&quot;$tableName =&gt; $class =&gt; $unqualifiedClassTableName does not match&quot;);\n        return $model;\n    }\n}\n</pre>\n\n            <h3><i class="icon-code-fork warning"></i> Stack trace</h3>\n\n            <table class="data-table">\n                <thead>\n                    <tr>\n                        <th class="right">#</th>\n                        <th>Called Code</th>\n                        <th>Document</th>\n                        <th class="right">Line</th>\n                    </tr>\n                </thead>\n                <tbody>\n                                            <tr>\n                            <td class="right">29</td>\n                            <td>\n                                Acorn\\Model::newModelFromTableName()\n                            </td>\n                            <td>~/modules/acorn/events/DataChange.php</td>\n                            <td class="right">42</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">28</td>\n                            <td>\n                                Acorn\\Events\\DataChange->__construct()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Events/Dispatchable.php</td>\n                            <td class="right">14</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">27</td>\n                            <td>\n                                Acorn\\Events\\DataChange::dispatch()\n                            </td>\n                            <td>~/modules/acorn/controllers/DB.php</td>\n                            <td class="right">36</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">26</td>\n                            <td>\n                                Acorn\\Controllers\\DB->datachange()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Controller.php</td>\n                            <td class="right">54</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">25</td>\n                            <td>\n                                Illuminate\\Routing\\Controller->callAction()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/ControllerDispatcher.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">24</td>\n                            <td>\n                                Illuminate\\Routing\\ControllerDispatcher->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">260</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">23</td>\n                            <td>\n                                Illuminate\\Routing\\Route->runController()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">205</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">22</td>\n                            <td>\n                                Illuminate\\Routing\\Route->run()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">798</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">21</td>\n                            <td>\n                                Illuminate\\Routing\\Router->Illuminate\\Routing\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">20</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">19</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">799</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">18</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRouteWithinStack()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">776</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">17</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRoute()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">740</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">16</td>\n                            <td>\n                                Illuminate\\Routing\\Router->dispatchToRoute()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Router/CoreRouter.php</td>\n                            <td class="right">20</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">15</td>\n                            <td>\n                                Winter\\Storm\\Router\\CoreRouter->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">190</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">14</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->Illuminate\\Foundation\\Http\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">13</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/PreventRequestsDuringMaintenance.php</td>\n                            <td class="right">86</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">12</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Middleware\\PreventRequestsDuringMaintenance->handle()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForMaintenanceMode.php</td>\n                            <td class="right">25</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">11</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForMaintenanceMode->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">10</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Http/Middleware/HandleCors.php</td>\n                            <td class="right">49</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">9</td>\n                            <td>\n                                Illuminate\\Http\\Middleware\\HandleCors->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">8</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForTrustedProxies.php</td>\n                            <td class="right">56</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">7</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForTrustedProxies->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">6</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Http/Middleware/TrustHosts.php</td>\n                            <td class="right">46</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">5</td>\n                            <td>\n                                Winter\\Storm\\Http\\Middleware\\TrustHosts->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">4</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">3</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">165</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">2</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->sendRequestThroughRouter()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">134</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">1</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->handle()\n                            </td>\n                            <td>~/index.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                    </tbody>\n            </table>\n        </div>\n\n        <script>\n            SyntaxHighlighter.defaults['toolbar'] = false;\n            SyntaxHighlighter.defaults['quick-code'] = false;\n            SyntaxHighlighter.defaults['html-script'] = true;\n            SyntaxHighlighter.defaults['first-line'] = 322;\n            SyntaxHighlighter.defaults['highlight'] = 328;\n            SyntaxHighlighter.all()\n        </script>\n    </body>\n</html>\n	\N
22a37692-30ab-4ece-a71f-10c8ba99844b	Canton	385a4d85-31d0-415c-960d-defb9298b432	2024-10-19 11:37:20	\N	500 <!DOCTYPE html>\n<html lang="en">\n    <head>\n        <meta charset="utf-8">\n        <title>Exception</title>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/css/styles.css" rel="stylesheet">\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shCore.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushPhp.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushXml.js"></script>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/styles/shCore.css">\n    </head>\n    <body>\n        <div class="container">\n\n            <h1><i class="icon-power-off warning"></i> Error</h1>\n\n            <p class="lead">We're sorry, but an unhandled error occurred. Please see the details below.</p>\n\n            <div class="exception-name-block">\n                <div>public.acorn_location_area_types =&gt; Acorn\\Location\\Models\\Area =&gt; acorn_location_areas does not match</div>\n                <p>/var/www/acorn-lojistiks/modules/acorn/traits/PathsHelper.php <span>line</span> 328</p>\n            </div>\n\n            <ul class="indicators">\n                <li>\n                    <h3>Type</h3>\n                    <p>Undefined</p>\n                </li>\n                <li>\n                    <h3>Exception</h3>\n                    <p>Exception</p>\n                </li>\n            </ul>\n\n            <pre class="brush: php">    {\n        $class = self::fullyQualifiedModelClassFromTableName($tableName);\n        $model = new $class;\n        $fullyQualifiedClassTableName = $model-&gt;getTable();\n        $unqualifiedClassTableName    = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $fullyQualifiedClassTableName);\n        $unqualifiedTableName         = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $tableName);\n        if ($unqualifiedClassTableName != $unqualifiedTableName) throw new Exception(&quot;$tableName =&gt; $class =&gt; $unqualifiedClassTableName does not match&quot;);\n        return $model;\n    }\n}\n</pre>\n\n            <h3><i class="icon-code-fork warning"></i> Stack trace</h3>\n\n            <table class="data-table">\n                <thead>\n                    <tr>\n                        <th class="right">#</th>\n                        <th>Called Code</th>\n                        <th>Document</th>\n                        <th class="right">Line</th>\n                    </tr>\n                </thead>\n                <tbody>\n                                            <tr>\n                            <td class="right">29</td>\n                            <td>\n                                Acorn\\Model::newModelFromTableName()\n                            </td>\n                            <td>~/modules/acorn/events/DataChange.php</td>\n                            <td class="right">42</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">28</td>\n                            <td>\n                                Acorn\\Events\\DataChange->__construct()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Events/Dispatchable.php</td>\n                            <td class="right">14</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">27</td>\n                            <td>\n                                Acorn\\Events\\DataChange::dispatch()\n                            </td>\n                            <td>~/modules/acorn/controllers/DB.php</td>\n                            <td class="right">36</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">26</td>\n                            <td>\n                                Acorn\\Controllers\\DB->datachange()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Controller.php</td>\n                            <td class="right">54</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">25</td>\n                            <td>\n                                Illuminate\\Routing\\Controller->callAction()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/ControllerDispatcher.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">24</td>\n                            <td>\n                                Illuminate\\Routing\\ControllerDispatcher->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">260</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">23</td>\n                            <td>\n                                Illuminate\\Routing\\Route->runController()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">205</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">22</td>\n                            <td>\n                                Illuminate\\Routing\\Route->run()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">798</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">21</td>\n                            <td>\n                                Illuminate\\Routing\\Router->Illuminate\\Routing\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">20</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">19</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">799</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">18</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRouteWithinStack()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">776</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">17</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRoute()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">740</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">16</td>\n                            <td>\n                                Illuminate\\Routing\\Router->dispatchToRoute()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Router/CoreRouter.php</td>\n                            <td class="right">20</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">15</td>\n                            <td>\n                                Winter\\Storm\\Router\\CoreRouter->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">190</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">14</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->Illuminate\\Foundation\\Http\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">13</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/PreventRequestsDuringMaintenance.php</td>\n                            <td class="right">86</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">12</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Middleware\\PreventRequestsDuringMaintenance->handle()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForMaintenanceMode.php</td>\n                            <td class="right">25</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">11</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForMaintenanceMode->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">10</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Http/Middleware/HandleCors.php</td>\n                            <td class="right">49</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">9</td>\n                            <td>\n                                Illuminate\\Http\\Middleware\\HandleCors->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">8</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForTrustedProxies.php</td>\n                            <td class="right">56</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">7</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForTrustedProxies->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">6</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Http/Middleware/TrustHosts.php</td>\n                            <td class="right">46</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">5</td>\n                            <td>\n                                Winter\\Storm\\Http\\Middleware\\TrustHosts->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">4</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">3</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">165</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">2</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->sendRequestThroughRouter()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">134</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">1</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->handle()\n                            </td>\n                            <td>~/index.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                    </tbody>\n            </table>\n        </div>\n\n        <script>\n            SyntaxHighlighter.defaults['toolbar'] = false;\n            SyntaxHighlighter.defaults['quick-code'] = false;\n            SyntaxHighlighter.defaults['html-script'] = true;\n            SyntaxHighlighter.defaults['first-line'] = 322;\n            SyntaxHighlighter.defaults['highlight'] = 328;\n            SyntaxHighlighter.all()\n        </script>\n    </body>\n</html>\n	\N
12ded268-507a-45ea-a3e2-058b3d76d4dc	City	385a4d85-31d0-415c-960d-defb9298b432	2024-10-19 11:37:20	\N	500 <!DOCTYPE html>\n<html lang="en">\n    <head>\n        <meta charset="utf-8">\n        <title>Exception</title>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/css/styles.css" rel="stylesheet">\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shCore.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushPhp.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushXml.js"></script>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/styles/shCore.css">\n    </head>\n    <body>\n        <div class="container">\n\n            <h1><i class="icon-power-off warning"></i> Error</h1>\n\n            <p class="lead">We're sorry, but an unhandled error occurred. Please see the details below.</p>\n\n            <div class="exception-name-block">\n                <div>public.acorn_location_area_types =&gt; Acorn\\Location\\Models\\Area =&gt; acorn_location_areas does not match</div>\n                <p>/var/www/acorn-lojistiks/modules/acorn/traits/PathsHelper.php <span>line</span> 328</p>\n            </div>\n\n            <ul class="indicators">\n                <li>\n                    <h3>Type</h3>\n                    <p>Undefined</p>\n                </li>\n                <li>\n                    <h3>Exception</h3>\n                    <p>Exception</p>\n                </li>\n            </ul>\n\n            <pre class="brush: php">    {\n        $class = self::fullyQualifiedModelClassFromTableName($tableName);\n        $model = new $class;\n        $fullyQualifiedClassTableName = $model-&gt;getTable();\n        $unqualifiedClassTableName    = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $fullyQualifiedClassTableName);\n        $unqualifiedTableName         = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $tableName);\n        if ($unqualifiedClassTableName != $unqualifiedTableName) throw new Exception(&quot;$tableName =&gt; $class =&gt; $unqualifiedClassTableName does not match&quot;);\n        return $model;\n    }\n}\n</pre>\n\n            <h3><i class="icon-code-fork warning"></i> Stack trace</h3>\n\n            <table class="data-table">\n                <thead>\n                    <tr>\n                        <th class="right">#</th>\n                        <th>Called Code</th>\n                        <th>Document</th>\n                        <th class="right">Line</th>\n                    </tr>\n                </thead>\n                <tbody>\n                                            <tr>\n                            <td class="right">29</td>\n                            <td>\n                                Acorn\\Model::newModelFromTableName()\n                            </td>\n                            <td>~/modules/acorn/events/DataChange.php</td>\n                            <td class="right">42</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">28</td>\n                            <td>\n                                Acorn\\Events\\DataChange->__construct()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Events/Dispatchable.php</td>\n                            <td class="right">14</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">27</td>\n                            <td>\n                                Acorn\\Events\\DataChange::dispatch()\n                            </td>\n                            <td>~/modules/acorn/controllers/DB.php</td>\n                            <td class="right">36</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">26</td>\n                            <td>\n                                Acorn\\Controllers\\DB->datachange()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Controller.php</td>\n                            <td class="right">54</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">25</td>\n                            <td>\n                                Illuminate\\Routing\\Controller->callAction()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/ControllerDispatcher.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">24</td>\n                            <td>\n                                Illuminate\\Routing\\ControllerDispatcher->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">260</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">23</td>\n                            <td>\n                                Illuminate\\Routing\\Route->runController()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">205</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">22</td>\n                            <td>\n                                Illuminate\\Routing\\Route->run()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">798</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">21</td>\n                            <td>\n                                Illuminate\\Routing\\Router->Illuminate\\Routing\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">20</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">19</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">799</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">18</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRouteWithinStack()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">776</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">17</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRoute()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">740</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">16</td>\n                            <td>\n                                Illuminate\\Routing\\Router->dispatchToRoute()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Router/CoreRouter.php</td>\n                            <td class="right">20</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">15</td>\n                            <td>\n                                Winter\\Storm\\Router\\CoreRouter->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">190</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">14</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->Illuminate\\Foundation\\Http\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">13</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/PreventRequestsDuringMaintenance.php</td>\n                            <td class="right">86</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">12</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Middleware\\PreventRequestsDuringMaintenance->handle()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForMaintenanceMode.php</td>\n                            <td class="right">25</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">11</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForMaintenanceMode->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">10</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Http/Middleware/HandleCors.php</td>\n                            <td class="right">49</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">9</td>\n                            <td>\n                                Illuminate\\Http\\Middleware\\HandleCors->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">8</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForTrustedProxies.php</td>\n                            <td class="right">56</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">7</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForTrustedProxies->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">6</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Http/Middleware/TrustHosts.php</td>\n                            <td class="right">46</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">5</td>\n                            <td>\n                                Winter\\Storm\\Http\\Middleware\\TrustHosts->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">4</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">3</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">165</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">2</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->sendRequestThroughRouter()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">134</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">1</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->handle()\n                            </td>\n                            <td>~/index.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                    </tbody>\n            </table>\n        </div>\n\n        <script>\n            SyntaxHighlighter.defaults['toolbar'] = false;\n            SyntaxHighlighter.defaults['quick-code'] = false;\n            SyntaxHighlighter.defaults['html-script'] = true;\n            SyntaxHighlighter.defaults['first-line'] = 322;\n            SyntaxHighlighter.defaults['highlight'] = 328;\n            SyntaxHighlighter.all()\n        </script>\n    </body>\n</html>\n	\N
0f26d439-1cf8-4c46-b218-3a10c18dbfa5	Village	385a4d85-31d0-415c-960d-defb9298b432	2024-10-19 11:37:20	\N	500 <!DOCTYPE html>\n<html lang="en">\n    <head>\n        <meta charset="utf-8">\n        <title>Exception</title>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/css/styles.css" rel="stylesheet">\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shCore.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushPhp.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushXml.js"></script>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/styles/shCore.css">\n    </head>\n    <body>\n        <div class="container">\n\n            <h1><i class="icon-power-off warning"></i> Error</h1>\n\n            <p class="lead">We're sorry, but an unhandled error occurred. Please see the details below.</p>\n\n            <div class="exception-name-block">\n                <div>public.acorn_location_area_types =&gt; Acorn\\Location\\Models\\Area =&gt; acorn_location_areas does not match</div>\n                <p>/var/www/acorn-lojistiks/modules/acorn/traits/PathsHelper.php <span>line</span> 328</p>\n            </div>\n\n            <ul class="indicators">\n                <li>\n                    <h3>Type</h3>\n                    <p>Undefined</p>\n                </li>\n                <li>\n                    <h3>Exception</h3>\n                    <p>Exception</p>\n                </li>\n            </ul>\n\n            <pre class="brush: php">    {\n        $class = self::fullyQualifiedModelClassFromTableName($tableName);\n        $model = new $class;\n        $fullyQualifiedClassTableName = $model-&gt;getTable();\n        $unqualifiedClassTableName    = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $fullyQualifiedClassTableName);\n        $unqualifiedTableName         = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $tableName);\n        if ($unqualifiedClassTableName != $unqualifiedTableName) throw new Exception(&quot;$tableName =&gt; $class =&gt; $unqualifiedClassTableName does not match&quot;);\n        return $model;\n    }\n}\n</pre>\n\n            <h3><i class="icon-code-fork warning"></i> Stack trace</h3>\n\n            <table class="data-table">\n                <thead>\n                    <tr>\n                        <th class="right">#</th>\n                        <th>Called Code</th>\n                        <th>Document</th>\n                        <th class="right">Line</th>\n                    </tr>\n                </thead>\n                <tbody>\n                                            <tr>\n                            <td class="right">29</td>\n                            <td>\n                                Acorn\\Model::newModelFromTableName()\n                            </td>\n                            <td>~/modules/acorn/events/DataChange.php</td>\n                            <td class="right">42</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">28</td>\n                            <td>\n                                Acorn\\Events\\DataChange->__construct()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Events/Dispatchable.php</td>\n                            <td class="right">14</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">27</td>\n                            <td>\n                                Acorn\\Events\\DataChange::dispatch()\n                            </td>\n                            <td>~/modules/acorn/controllers/DB.php</td>\n                            <td class="right">36</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">26</td>\n                            <td>\n                                Acorn\\Controllers\\DB->datachange()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Controller.php</td>\n                            <td class="right">54</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">25</td>\n                            <td>\n                                Illuminate\\Routing\\Controller->callAction()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/ControllerDispatcher.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">24</td>\n                            <td>\n                                Illuminate\\Routing\\ControllerDispatcher->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">260</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">23</td>\n                            <td>\n                                Illuminate\\Routing\\Route->runController()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">205</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">22</td>\n                            <td>\n                                Illuminate\\Routing\\Route->run()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">798</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">21</td>\n                            <td>\n                                Illuminate\\Routing\\Router->Illuminate\\Routing\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">20</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">19</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">799</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">18</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRouteWithinStack()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">776</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">17</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRoute()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">740</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">16</td>\n                            <td>\n                                Illuminate\\Routing\\Router->dispatchToRoute()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Router/CoreRouter.php</td>\n                            <td class="right">20</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">15</td>\n                            <td>\n                                Winter\\Storm\\Router\\CoreRouter->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">190</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">14</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->Illuminate\\Foundation\\Http\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">13</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/PreventRequestsDuringMaintenance.php</td>\n                            <td class="right">86</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">12</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Middleware\\PreventRequestsDuringMaintenance->handle()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForMaintenanceMode.php</td>\n                            <td class="right">25</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">11</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForMaintenanceMode->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">10</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Http/Middleware/HandleCors.php</td>\n                            <td class="right">49</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">9</td>\n                            <td>\n                                Illuminate\\Http\\Middleware\\HandleCors->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">8</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForTrustedProxies.php</td>\n                            <td class="right">56</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">7</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForTrustedProxies->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">6</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Http/Middleware/TrustHosts.php</td>\n                            <td class="right">46</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">5</td>\n                            <td>\n                                Winter\\Storm\\Http\\Middleware\\TrustHosts->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">4</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">3</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">165</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">2</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->sendRequestThroughRouter()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">134</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">1</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->handle()\n                            </td>\n                            <td>~/index.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                    </tbody>\n            </table>\n        </div>\n\n        <script>\n            SyntaxHighlighter.defaults['toolbar'] = false;\n            SyntaxHighlighter.defaults['quick-code'] = false;\n            SyntaxHighlighter.defaults['html-script'] = true;\n            SyntaxHighlighter.defaults['first-line'] = 322;\n            SyntaxHighlighter.defaults['highlight'] = 328;\n            SyntaxHighlighter.all()\n        </script>\n    </body>\n</html>\n	\N
25ca35f1-10b7-4307-ac5b-311f03f9eb51	Town	385a4d85-31d0-415c-960d-defb9298b432	2024-10-19 11:37:20	\N	500 <!DOCTYPE html>\n<html lang="en">\n    <head>\n        <meta charset="utf-8">\n        <title>Exception</title>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/css/styles.css" rel="stylesheet">\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shCore.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushPhp.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushXml.js"></script>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/styles/shCore.css">\n    </head>\n    <body>\n        <div class="container">\n\n            <h1><i class="icon-power-off warning"></i> Error</h1>\n\n            <p class="lead">We're sorry, but an unhandled error occurred. Please see the details below.</p>\n\n            <div class="exception-name-block">\n                <div>public.acorn_location_area_types =&gt; Acorn\\Location\\Models\\Area =&gt; acorn_location_areas does not match</div>\n                <p>/var/www/acorn-lojistiks/modules/acorn/traits/PathsHelper.php <span>line</span> 328</p>\n            </div>\n\n            <ul class="indicators">\n                <li>\n                    <h3>Type</h3>\n                    <p>Undefined</p>\n                </li>\n                <li>\n                    <h3>Exception</h3>\n                    <p>Exception</p>\n                </li>\n            </ul>\n\n            <pre class="brush: php">    {\n        $class = self::fullyQualifiedModelClassFromTableName($tableName);\n        $model = new $class;\n        $fullyQualifiedClassTableName = $model-&gt;getTable();\n        $unqualifiedClassTableName    = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $fullyQualifiedClassTableName);\n        $unqualifiedTableName         = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $tableName);\n        if ($unqualifiedClassTableName != $unqualifiedTableName) throw new Exception(&quot;$tableName =&gt; $class =&gt; $unqualifiedClassTableName does not match&quot;);\n        return $model;\n    }\n}\n</pre>\n\n            <h3><i class="icon-code-fork warning"></i> Stack trace</h3>\n\n            <table class="data-table">\n                <thead>\n                    <tr>\n                        <th class="right">#</th>\n                        <th>Called Code</th>\n                        <th>Document</th>\n                        <th class="right">Line</th>\n                    </tr>\n                </thead>\n                <tbody>\n                                            <tr>\n                            <td class="right">29</td>\n                            <td>\n                                Acorn\\Model::newModelFromTableName()\n                            </td>\n                            <td>~/modules/acorn/events/DataChange.php</td>\n                            <td class="right">42</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">28</td>\n                            <td>\n                                Acorn\\Events\\DataChange->__construct()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Events/Dispatchable.php</td>\n                            <td class="right">14</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">27</td>\n                            <td>\n                                Acorn\\Events\\DataChange::dispatch()\n                            </td>\n                            <td>~/modules/acorn/controllers/DB.php</td>\n                            <td class="right">36</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">26</td>\n                            <td>\n                                Acorn\\Controllers\\DB->datachange()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Controller.php</td>\n                            <td class="right">54</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">25</td>\n                            <td>\n                                Illuminate\\Routing\\Controller->callAction()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/ControllerDispatcher.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">24</td>\n                            <td>\n                                Illuminate\\Routing\\ControllerDispatcher->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">260</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">23</td>\n                            <td>\n                                Illuminate\\Routing\\Route->runController()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">205</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">22</td>\n                            <td>\n                                Illuminate\\Routing\\Route->run()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">798</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">21</td>\n                            <td>\n                                Illuminate\\Routing\\Router->Illuminate\\Routing\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">20</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">19</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">799</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">18</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRouteWithinStack()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">776</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">17</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRoute()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">740</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">16</td>\n                            <td>\n                                Illuminate\\Routing\\Router->dispatchToRoute()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Router/CoreRouter.php</td>\n                            <td class="right">20</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">15</td>\n                            <td>\n                                Winter\\Storm\\Router\\CoreRouter->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">190</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">14</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->Illuminate\\Foundation\\Http\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">13</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/PreventRequestsDuringMaintenance.php</td>\n                            <td class="right">86</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">12</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Middleware\\PreventRequestsDuringMaintenance->handle()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForMaintenanceMode.php</td>\n                            <td class="right">25</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">11</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForMaintenanceMode->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">10</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Http/Middleware/HandleCors.php</td>\n                            <td class="right">49</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">9</td>\n                            <td>\n                                Illuminate\\Http\\Middleware\\HandleCors->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">8</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForTrustedProxies.php</td>\n                            <td class="right">56</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">7</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForTrustedProxies->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">6</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Http/Middleware/TrustHosts.php</td>\n                            <td class="right">46</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">5</td>\n                            <td>\n                                Winter\\Storm\\Http\\Middleware\\TrustHosts->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">4</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">3</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">165</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">2</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->sendRequestThroughRouter()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">134</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">1</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->handle()\n                            </td>\n                            <td>~/index.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                    </tbody>\n            </table>\n        </div>\n\n        <script>\n            SyntaxHighlighter.defaults['toolbar'] = false;\n            SyntaxHighlighter.defaults['quick-code'] = false;\n            SyntaxHighlighter.defaults['html-script'] = true;\n            SyntaxHighlighter.defaults['first-line'] = 322;\n            SyntaxHighlighter.defaults['highlight'] = 328;\n            SyntaxHighlighter.all()\n        </script>\n    </body>\n</html>\n	\N
3997fe17-fca7-499e-afa6-2ed45afaf4b8	Comune	385a4d85-31d0-415c-960d-defb9298b432	2024-10-19 11:37:20	\N	500 <!DOCTYPE html>\n<html lang="en">\n    <head>\n        <meta charset="utf-8">\n        <title>Exception</title>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/css/styles.css" rel="stylesheet">\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shCore.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushPhp.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushXml.js"></script>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/styles/shCore.css">\n    </head>\n    <body>\n        <div class="container">\n\n            <h1><i class="icon-power-off warning"></i> Error</h1>\n\n            <p class="lead">We're sorry, but an unhandled error occurred. Please see the details below.</p>\n\n            <div class="exception-name-block">\n                <div>public.acorn_location_area_types =&gt; Acorn\\Location\\Models\\Area =&gt; acorn_location_areas does not match</div>\n                <p>/var/www/acorn-lojistiks/modules/acorn/traits/PathsHelper.php <span>line</span> 328</p>\n            </div>\n\n            <ul class="indicators">\n                <li>\n                    <h3>Type</h3>\n                    <p>Undefined</p>\n                </li>\n                <li>\n                    <h3>Exception</h3>\n                    <p>Exception</p>\n                </li>\n            </ul>\n\n            <pre class="brush: php">    {\n        $class = self::fullyQualifiedModelClassFromTableName($tableName);\n        $model = new $class;\n        $fullyQualifiedClassTableName = $model-&gt;getTable();\n        $unqualifiedClassTableName    = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $fullyQualifiedClassTableName);\n        $unqualifiedTableName         = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $tableName);\n        if ($unqualifiedClassTableName != $unqualifiedTableName) throw new Exception(&quot;$tableName =&gt; $class =&gt; $unqualifiedClassTableName does not match&quot;);\n        return $model;\n    }\n}\n</pre>\n\n            <h3><i class="icon-code-fork warning"></i> Stack trace</h3>\n\n            <table class="data-table">\n                <thead>\n                    <tr>\n                        <th class="right">#</th>\n                        <th>Called Code</th>\n                        <th>Document</th>\n                        <th class="right">Line</th>\n                    </tr>\n                </thead>\n                <tbody>\n                                            <tr>\n                            <td class="right">29</td>\n                            <td>\n                                Acorn\\Model::newModelFromTableName()\n                            </td>\n                            <td>~/modules/acorn/events/DataChange.php</td>\n                            <td class="right">42</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">28</td>\n                            <td>\n                                Acorn\\Events\\DataChange->__construct()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Events/Dispatchable.php</td>\n                            <td class="right">14</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">27</td>\n                            <td>\n                                Acorn\\Events\\DataChange::dispatch()\n                            </td>\n                            <td>~/modules/acorn/controllers/DB.php</td>\n                            <td class="right">36</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">26</td>\n                            <td>\n                                Acorn\\Controllers\\DB->datachange()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Controller.php</td>\n                            <td class="right">54</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">25</td>\n                            <td>\n                                Illuminate\\Routing\\Controller->callAction()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/ControllerDispatcher.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">24</td>\n                            <td>\n                                Illuminate\\Routing\\ControllerDispatcher->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">260</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">23</td>\n                            <td>\n                                Illuminate\\Routing\\Route->runController()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">205</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">22</td>\n                            <td>\n                                Illuminate\\Routing\\Route->run()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">798</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">21</td>\n                            <td>\n                                Illuminate\\Routing\\Router->Illuminate\\Routing\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">20</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">19</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">799</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">18</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRouteWithinStack()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">776</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">17</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRoute()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">740</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">16</td>\n                            <td>\n                                Illuminate\\Routing\\Router->dispatchToRoute()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Router/CoreRouter.php</td>\n                            <td class="right">20</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">15</td>\n                            <td>\n                                Winter\\Storm\\Router\\CoreRouter->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">190</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">14</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->Illuminate\\Foundation\\Http\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">13</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/PreventRequestsDuringMaintenance.php</td>\n                            <td class="right">86</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">12</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Middleware\\PreventRequestsDuringMaintenance->handle()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForMaintenanceMode.php</td>\n                            <td class="right">25</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">11</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForMaintenanceMode->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">10</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Http/Middleware/HandleCors.php</td>\n                            <td class="right">49</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">9</td>\n                            <td>\n                                Illuminate\\Http\\Middleware\\HandleCors->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">8</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForTrustedProxies.php</td>\n                            <td class="right">56</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">7</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForTrustedProxies->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">6</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Http/Middleware/TrustHosts.php</td>\n                            <td class="right">46</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">5</td>\n                            <td>\n                                Winter\\Storm\\Http\\Middleware\\TrustHosts->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">4</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">3</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">165</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">2</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->sendRequestThroughRouter()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">134</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">1</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->handle()\n                            </td>\n                            <td>~/index.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                    </tbody>\n            </table>\n        </div>\n\n        <script>\n            SyntaxHighlighter.defaults['toolbar'] = false;\n            SyntaxHighlighter.defaults['quick-code'] = false;\n            SyntaxHighlighter.defaults['html-script'] = true;\n            SyntaxHighlighter.defaults['first-line'] = 322;\n            SyntaxHighlighter.defaults['highlight'] = 328;\n            SyntaxHighlighter.all()\n        </script>\n    </body>\n</html>\n	\N
\.


--
-- Data for Name: acorn_location_areas; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_location_areas (id, name, area_type_id, parent_area_id, gps_id, server_id, version, is_current_version, created_at, created_by_user_id, response, description) FROM stdin;
97e78c76-c815-44ad-b11a-117cd8414655	Syria	b8f142f9-54c0-426c-81a8-23a9cdd17e59	\N	\N	385a4d85-31d0-415c-960d-defb9298b432	1	t	2024-10-19 11:37:20	\N	200 DataChange event for () Dispatched	\N
d6b3135a-972a-4fa2-b828-f3eb54233a9c	Cezîra	22a37692-30ab-4ece-a71f-10c8ba99844b	97e78c76-c815-44ad-b11a-117cd8414655	\N	385a4d85-31d0-415c-960d-defb9298b432	1	t	2024-10-19 11:37:20	\N	200 DataChange event for () Dispatched	\N
70ae737a-d840-48ce-b1e4-d38db5a85d6f	Qamişlo	12ded268-507a-45ea-a3e2-058b3d76d4dc	d6b3135a-972a-4fa2-b828-f3eb54233a9c	e804a8f7-db9c-4c69-ae04-2df706ab07e6	385a4d85-31d0-415c-960d-defb9298b432	1	t	2024-10-19 11:37:20	\N	200 DataChange event for () Dispatched	\N
f44bac7c-c679-4a9d-965e-96daa5c3662b	Al Hêseke	12ded268-507a-45ea-a3e2-058b3d76d4dc	d6b3135a-972a-4fa2-b828-f3eb54233a9c	faddec10-6fbf-47ca-b97a-165cfb8070c5	385a4d85-31d0-415c-960d-defb9298b432	1	t	2024-10-19 11:37:20	\N	200 DataChange event for () Dispatched	\N
\.


--
-- Data for Name: acorn_location_gps; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_location_gps (id, longitude, latitude, server_id, created_at, created_by_user_id, response) FROM stdin;
e804a8f7-db9c-4c69-ae04-2df706ab07e6	37.0343936	41.2146239	385a4d85-31d0-415c-960d-defb9298b432	2024-10-19 11:37:20	\N	500 <!DOCTYPE html>\n<html lang="en">\n    <head>\n        <meta charset="utf-8">\n        <title>Exception</title>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/css/styles.css" rel="stylesheet">\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shCore.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushPhp.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushXml.js"></script>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/styles/shCore.css">\n    </head>\n    <body>\n        <div class="container">\n\n            <h1><i class="icon-power-off warning"></i> Error</h1>\n\n            <p class="lead">We're sorry, but an unhandled error occurred. Please see the details below.</p>\n\n            <div class="exception-name-block">\n                <div>Class &quot;Acorn\\Location\\Models\\Gp&quot; not found</div>\n                <p>/var/www/acorn-lojistiks/modules/acorn/traits/PathsHelper.php <span>line</span> 324</p>\n            </div>\n\n            <ul class="indicators">\n                <li>\n                    <h3>Type</h3>\n                    <p>Undefined</p>\n                </li>\n                <li>\n                    <h3>Exception</h3>\n                    <p>Error</p>\n                </li>\n            </ul>\n\n            <pre class="brush: php">        return &quot;$authorPascalCase\\\\$pluginPascalCase\\\\Models\\\\$unqualifiedPascalClassName&quot;;\n    }\n&nbsp;\n    public static function newModelFromTableName(string $tableName): Model\n    {\n        $class = self::fullyQualifiedModelClassFromTableName($tableName);\n        $model = new $class;\n        $fullyQualifiedClassTableName = $model-&gt;getTable();\n        $unqualifiedClassTableName    = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $fullyQualifiedClassTableName);\n        $unqualifiedTableName         = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $tableName);\n        if ($unqualifiedClassTableName != $unqualifiedTableName) throw new Exception(&quot;$tableName =&gt; $class =&gt; $unqualifiedClassTableName does not match&quot;);\n        return $model;\n    }\n</pre>\n\n            <h3><i class="icon-code-fork warning"></i> Stack trace</h3>\n\n            <table class="data-table">\n                <thead>\n                    <tr>\n                        <th class="right">#</th>\n                        <th>Called Code</th>\n                        <th>Document</th>\n                        <th class="right">Line</th>\n                    </tr>\n                </thead>\n                <tbody>\n                                            <tr>\n                            <td class="right">29</td>\n                            <td>\n                                Acorn\\Model::newModelFromTableName()\n                            </td>\n                            <td>~/modules/acorn/events/DataChange.php</td>\n                            <td class="right">42</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">28</td>\n                            <td>\n                                Acorn\\Events\\DataChange->__construct()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Events/Dispatchable.php</td>\n                            <td class="right">14</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">27</td>\n                            <td>\n                                Acorn\\Events\\DataChange::dispatch()\n                            </td>\n                            <td>~/modules/acorn/controllers/DB.php</td>\n                            <td class="right">36</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">26</td>\n                            <td>\n                                Acorn\\Controllers\\DB->datachange()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Controller.php</td>\n                            <td class="right">54</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">25</td>\n                            <td>\n                                Illuminate\\Routing\\Controller->callAction()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/ControllerDispatcher.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">24</td>\n                            <td>\n                                Illuminate\\Routing\\ControllerDispatcher->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">260</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">23</td>\n                            <td>\n                                Illuminate\\Routing\\Route->runController()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">205</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">22</td>\n                            <td>\n                                Illuminate\\Routing\\Route->run()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">798</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">21</td>\n                            <td>\n                                Illuminate\\Routing\\Router->Illuminate\\Routing\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">20</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">19</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">799</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">18</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRouteWithinStack()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">776</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">17</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRoute()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">740</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">16</td>\n                            <td>\n                                Illuminate\\Routing\\Router->dispatchToRoute()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Router/CoreRouter.php</td>\n                            <td class="right">20</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">15</td>\n                            <td>\n                                Winter\\Storm\\Router\\CoreRouter->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">190</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">14</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->Illuminate\\Foundation\\Http\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">13</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/PreventRequestsDuringMaintenance.php</td>\n                            <td class="right">86</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">12</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Middleware\\PreventRequestsDuringMaintenance->handle()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForMaintenanceMode.php</td>\n                            <td class="right">25</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">11</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForMaintenanceMode->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">10</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Http/Middleware/HandleCors.php</td>\n                            <td class="right">49</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">9</td>\n                            <td>\n                                Illuminate\\Http\\Middleware\\HandleCors->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">8</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForTrustedProxies.php</td>\n                            <td class="right">56</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">7</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForTrustedProxies->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">6</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Http/Middleware/TrustHosts.php</td>\n                            <td class="right">46</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">5</td>\n                            <td>\n                                Winter\\Storm\\Http\\Middleware\\TrustHosts->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">4</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">3</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">165</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">2</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->sendRequestThroughRouter()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">134</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">1</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->handle()\n                            </td>\n                            <td>~/index.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                    </tbody>\n            </table>\n        </div>\n\n        <script>\n            SyntaxHighlighter.defaults['toolbar'] = false;\n            SyntaxHighlighter.defaults['quick-code'] = false;\n            SyntaxHighlighter.defaults['html-script'] = true;\n            SyntaxHighlighter.defaults['first-line'] = 318;\n            SyntaxHighlighter.defaults['highlight'] = 324;\n            SyntaxHighlighter.all()\n        </script>\n    </body>\n</html>\n
faddec10-6fbf-47ca-b97a-165cfb8070c5	36.5166478	40.7416334	385a4d85-31d0-415c-960d-defb9298b432	2024-10-19 11:37:20	\N	500 <!DOCTYPE html>\n<html lang="en">\n    <head>\n        <meta charset="utf-8">\n        <title>Exception</title>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/css/styles.css" rel="stylesheet">\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shCore.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushPhp.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushXml.js"></script>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/styles/shCore.css">\n    </head>\n    <body>\n        <div class="container">\n\n            <h1><i class="icon-power-off warning"></i> Error</h1>\n\n            <p class="lead">We're sorry, but an unhandled error occurred. Please see the details below.</p>\n\n            <div class="exception-name-block">\n                <div>Class &quot;Acorn\\Location\\Models\\Gp&quot; not found</div>\n                <p>/var/www/acorn-lojistiks/modules/acorn/traits/PathsHelper.php <span>line</span> 324</p>\n            </div>\n\n            <ul class="indicators">\n                <li>\n                    <h3>Type</h3>\n                    <p>Undefined</p>\n                </li>\n                <li>\n                    <h3>Exception</h3>\n                    <p>Error</p>\n                </li>\n            </ul>\n\n            <pre class="brush: php">        return &quot;$authorPascalCase\\\\$pluginPascalCase\\\\Models\\\\$unqualifiedPascalClassName&quot;;\n    }\n&nbsp;\n    public static function newModelFromTableName(string $tableName): Model\n    {\n        $class = self::fullyQualifiedModelClassFromTableName($tableName);\n        $model = new $class;\n        $fullyQualifiedClassTableName = $model-&gt;getTable();\n        $unqualifiedClassTableName    = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $fullyQualifiedClassTableName);\n        $unqualifiedTableName         = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $tableName);\n        if ($unqualifiedClassTableName != $unqualifiedTableName) throw new Exception(&quot;$tableName =&gt; $class =&gt; $unqualifiedClassTableName does not match&quot;);\n        return $model;\n    }\n</pre>\n\n            <h3><i class="icon-code-fork warning"></i> Stack trace</h3>\n\n            <table class="data-table">\n                <thead>\n                    <tr>\n                        <th class="right">#</th>\n                        <th>Called Code</th>\n                        <th>Document</th>\n                        <th class="right">Line</th>\n                    </tr>\n                </thead>\n                <tbody>\n                                            <tr>\n                            <td class="right">29</td>\n                            <td>\n                                Acorn\\Model::newModelFromTableName()\n                            </td>\n                            <td>~/modules/acorn/events/DataChange.php</td>\n                            <td class="right">42</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">28</td>\n                            <td>\n                                Acorn\\Events\\DataChange->__construct()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Events/Dispatchable.php</td>\n                            <td class="right">14</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">27</td>\n                            <td>\n                                Acorn\\Events\\DataChange::dispatch()\n                            </td>\n                            <td>~/modules/acorn/controllers/DB.php</td>\n                            <td class="right">36</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">26</td>\n                            <td>\n                                Acorn\\Controllers\\DB->datachange()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Controller.php</td>\n                            <td class="right">54</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">25</td>\n                            <td>\n                                Illuminate\\Routing\\Controller->callAction()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/ControllerDispatcher.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">24</td>\n                            <td>\n                                Illuminate\\Routing\\ControllerDispatcher->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">260</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">23</td>\n                            <td>\n                                Illuminate\\Routing\\Route->runController()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">205</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">22</td>\n                            <td>\n                                Illuminate\\Routing\\Route->run()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">798</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">21</td>\n                            <td>\n                                Illuminate\\Routing\\Router->Illuminate\\Routing\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">20</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">19</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">799</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">18</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRouteWithinStack()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">776</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">17</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRoute()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">740</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">16</td>\n                            <td>\n                                Illuminate\\Routing\\Router->dispatchToRoute()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Router/CoreRouter.php</td>\n                            <td class="right">20</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">15</td>\n                            <td>\n                                Winter\\Storm\\Router\\CoreRouter->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">190</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">14</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->Illuminate\\Foundation\\Http\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">13</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/PreventRequestsDuringMaintenance.php</td>\n                            <td class="right">86</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">12</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Middleware\\PreventRequestsDuringMaintenance->handle()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForMaintenanceMode.php</td>\n                            <td class="right">25</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">11</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForMaintenanceMode->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">10</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Http/Middleware/HandleCors.php</td>\n                            <td class="right">49</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">9</td>\n                            <td>\n                                Illuminate\\Http\\Middleware\\HandleCors->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">8</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForTrustedProxies.php</td>\n                            <td class="right">56</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">7</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForTrustedProxies->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">6</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Http/Middleware/TrustHosts.php</td>\n                            <td class="right">46</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">5</td>\n                            <td>\n                                Winter\\Storm\\Http\\Middleware\\TrustHosts->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">4</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">3</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">165</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">2</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->sendRequestThroughRouter()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">134</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">1</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->handle()\n                            </td>\n                            <td>~/index.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                    </tbody>\n            </table>\n        </div>\n\n        <script>\n            SyntaxHighlighter.defaults['toolbar'] = false;\n            SyntaxHighlighter.defaults['quick-code'] = false;\n            SyntaxHighlighter.defaults['html-script'] = true;\n            SyntaxHighlighter.defaults['first-line'] = 318;\n            SyntaxHighlighter.defaults['highlight'] = 324;\n            SyntaxHighlighter.all()\n        </script>\n    </body>\n</html>\n
9d6a4b02-88cd-4dad-8f5d-e0a796e02932	\N	\N	385a4d85-31d0-415c-960d-defb9298b432	2024-11-05 09:21:46	\N	500 <!DOCTYPE html>\n<html lang="en">\n    <head>\n        <meta charset="utf-8">\n        <title>Exception</title>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/css/styles.css" rel="stylesheet">\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shCore.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushPhp.js"></script>\n        <script src="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/scripts/shBrushXml.js"></script>\n        <link href="http://acorn-lojistiks.laptop/modules/system/assets/vendor/syntaxhighlighter/styles/shCore.css">\n    </head>\n    <body>\n        <div class="container">\n\n            <h1><i class="icon-power-off warning"></i> Error</h1>\n\n            <p class="lead">We're sorry, but an unhandled error occurred. Please see the details below.</p>\n\n            <div class="exception-name-block">\n                <div>Class &quot;Acorn\\Location\\Models\\Gp&quot; not found</div>\n                <p>/var/www/acorn-lojistiks/modules/acorn/traits/PathsHelper.php <span>line</span> 324</p>\n            </div>\n\n            <ul class="indicators">\n                <li>\n                    <h3>Type</h3>\n                    <p>Undefined</p>\n                </li>\n                <li>\n                    <h3>Exception</h3>\n                    <p>Error</p>\n                </li>\n            </ul>\n\n            <pre class="brush: php">        return &quot;$authorPascalCase\\\\$pluginPascalCase\\\\Models\\\\$unqualifiedPascalClassName&quot;;\n    }\n&nbsp;\n    public static function newModelFromTableName(string $tableName): Model\n    {\n        $class = self::fullyQualifiedModelClassFromTableName($tableName);\n        $model = new $class;\n        $fullyQualifiedClassTableName = $model-&gt;getTable();\n        $unqualifiedClassTableName    = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $fullyQualifiedClassTableName);\n        $unqualifiedTableName         = preg_replace(&#039;/^[^.]+\\./&#039;, &#039;&#039;, $tableName);\n        if ($unqualifiedClassTableName != $unqualifiedTableName) throw new Exception(&quot;$tableName =&gt; $class =&gt; $unqualifiedClassTableName does not match&quot;);\n        return $model;\n    }\n</pre>\n\n            <h3><i class="icon-code-fork warning"></i> Stack trace</h3>\n\n            <table class="data-table">\n                <thead>\n                    <tr>\n                        <th class="right">#</th>\n                        <th>Called Code</th>\n                        <th>Document</th>\n                        <th class="right">Line</th>\n                    </tr>\n                </thead>\n                <tbody>\n                                            <tr>\n                            <td class="right">29</td>\n                            <td>\n                                Acorn\\Model::newModelFromTableName()\n                            </td>\n                            <td>~/modules/acorn/events/DataChange.php</td>\n                            <td class="right">42</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">28</td>\n                            <td>\n                                Acorn\\Events\\DataChange->__construct()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Events/Dispatchable.php</td>\n                            <td class="right">14</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">27</td>\n                            <td>\n                                Acorn\\Events\\DataChange::dispatch()\n                            </td>\n                            <td>~/modules/acorn/controllers/DB.php</td>\n                            <td class="right">36</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">26</td>\n                            <td>\n                                Acorn\\Controllers\\DB->datachange()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Controller.php</td>\n                            <td class="right">54</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">25</td>\n                            <td>\n                                Illuminate\\Routing\\Controller->callAction()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/ControllerDispatcher.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">24</td>\n                            <td>\n                                Illuminate\\Routing\\ControllerDispatcher->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">260</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">23</td>\n                            <td>\n                                Illuminate\\Routing\\Route->runController()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Route.php</td>\n                            <td class="right">205</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">22</td>\n                            <td>\n                                Illuminate\\Routing\\Route->run()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">798</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">21</td>\n                            <td>\n                                Illuminate\\Routing\\Router->Illuminate\\Routing\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">20</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">19</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">799</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">18</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRouteWithinStack()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">776</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">17</td>\n                            <td>\n                                Illuminate\\Routing\\Router->runRoute()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Routing/Router.php</td>\n                            <td class="right">740</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">16</td>\n                            <td>\n                                Illuminate\\Routing\\Router->dispatchToRoute()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Router/CoreRouter.php</td>\n                            <td class="right">20</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">15</td>\n                            <td>\n                                Winter\\Storm\\Router\\CoreRouter->dispatch()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">190</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">14</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->Illuminate\\Foundation\\Http\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">141</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">13</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Middleware/PreventRequestsDuringMaintenance.php</td>\n                            <td class="right">86</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">12</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Middleware\\PreventRequestsDuringMaintenance->handle()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForMaintenanceMode.php</td>\n                            <td class="right">25</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">11</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForMaintenanceMode->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">10</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Http/Middleware/HandleCors.php</td>\n                            <td class="right">49</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">9</td>\n                            <td>\n                                Illuminate\\Http\\Middleware\\HandleCors->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">8</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Foundation/Http/Middleware/CheckForTrustedProxies.php</td>\n                            <td class="right">56</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">7</td>\n                            <td>\n                                Winter\\Storm\\Foundation\\Http\\Middleware\\CheckForTrustedProxies->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">6</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/winter/storm/src/Http/Middleware/TrustHosts.php</td>\n                            <td class="right">46</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">5</td>\n                            <td>\n                                Winter\\Storm\\Http\\Middleware\\TrustHosts->handle()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">180</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">4</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->Illuminate\\Pipeline\\{closure}()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php</td>\n                            <td class="right">116</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">3</td>\n                            <td>\n                                Illuminate\\Pipeline\\Pipeline->then()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">165</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">2</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->sendRequestThroughRouter()\n                            </td>\n                            <td>~/vendor/laravel/framework/src/Illuminate/Foundation/Http/Kernel.php</td>\n                            <td class="right">134</td>\n                        </tr>\n                                            <tr>\n                            <td class="right">1</td>\n                            <td>\n                                Illuminate\\Foundation\\Http\\Kernel->handle()\n                            </td>\n                            <td>~/index.php</td>\n                            <td class="right">43</td>\n                        </tr>\n                                    </tbody>\n            </table>\n        </div>\n\n        <script>\n            SyntaxHighlighter.defaults['toolbar'] = false;\n            SyntaxHighlighter.defaults['quick-code'] = false;\n            SyntaxHighlighter.defaults['html-script'] = true;\n            SyntaxHighlighter.defaults['first-line'] = 318;\n            SyntaxHighlighter.defaults['highlight'] = 324;\n            SyntaxHighlighter.all()\n        </script>\n    </body>\n</html>\n
\.


--
-- Data for Name: acorn_location_locations; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_location_locations (id, address_id, name, image, server_id, created_at, created_by_user_id, response, user_group_id, type_id, description) FROM stdin;
9d6a4b02-c5ae-467a-9749-c077820b4986	9d6a4b02-b2d3-401a-bfe7-0b6768ea4f9a	Test	/parcel.jpeg	385a4d85-31d0-415c-960d-defb9298b432	2024-11-05 09:21:46	\N	200 DataChange event for () Dispatched	\N	ad1f8d2e-da3e-4d03-8bba-4d8ac72bc7a5	\N
e5aa0d61-8c70-4c74-99e6-4312ea063912	5792ec77-8e1d-4d8d-b480-ed1286ec2a03	Court Buildings	/logo.png	385a4d85-31d0-415c-960d-defb9298b432	2024-11-04 06:30:29	\N	200 DataChange event for () Dispatched	9d6d2bbb-447a-411f-99e3-72d2c1707f90	98eb8925-57ad-4646-bef4-4929f4d90191	\N
\.


--
-- Data for Name: acorn_location_lookup; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_location_lookup (id, address, city, zip, country_code, state_code, latitude, longitude, vicinity, created_at) FROM stdin;
\.


--
-- Data for Name: acorn_location_types; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_location_types (id, name, parent_type_id, server_id, created_at, created_by_user_id, response, colour, image, description) FROM stdin;
98eb8925-57ad-4646-bef4-4929f4d90191	Office	\N	385a4d85-31d0-415c-960d-defb9298b432	2024-10-19 11:37:20	\N	200 DataChange event for () Dispatched	\N	\N	\N
d062abea-105d-4726-a6e8-e27aa6cd5d08	Warehouse	ad1f8d2e-da3e-4d03-8bba-4d8ac72bc7a5	385a4d85-31d0-415c-960d-defb9298b432	2024-10-19 11:37:20	\N	200 DataChange event for () Dispatched	#101CA5	\N	\N
ad1f8d2e-da3e-4d03-8bba-4d8ac72bc7a5	Supplier	\N	385a4d85-31d0-415c-960d-defb9298b432	2024-10-19 11:37:20	\N	200 DataChange event for () Dispatched	#F1C40F	\N	\N
\.


--
-- Data for Name: acorn_lojistiks_brands; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_brands (id, name, image, response, server_id, created_at_event_id, created_by_user_id, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_containers; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_containers (id, server_id, created_at_event_id, name, created_by_user_id, response, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_drivers; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_drivers (id, person_id, server_id, created_at_event_id, vehicle_id, created_by_user_id, response, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_employees; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_employees (id, person_id, user_role_id, server_id, created_at_event_id, created_by_user_id, response, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_measurement_units; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_measurement_units (id, name, short_name, uses_quantity, server_id, created_at_event_id, created_by_user_id, response, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_offices; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_offices (id, location_id, server_id, created_at_event_id, created_by_user_id, response, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_people; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_people (id, user_id, image, server_id, created_at_event_id, created_by_user_id, response, last_transfer_location_id, last_product_instance_location_id, description) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_product_attributes; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_product_attributes (id, product_id, name, value, server_id, created_at_event_id, created_by_user_id, response, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_product_categories; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_product_categories (id, name, product_category_type_id, parent_product_category_id, server_id, created_at_event_id, created_by_user_id, response, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_product_category_types; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_product_category_types (id, name, server_id, created_at_event_id, created_by_user_id, response, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_product_instance_transfer; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_product_instance_transfer (id, transfer_id, product_instance_id, server_id, created_at_event_id, created_by_user_id, response, description) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_product_instances; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_product_instances (id, product_id, quantity, external_identifier, asset_class, server_id, created_at_event_id, created_by_user_id, response, image, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_product_product_category; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_product_product_category (id, product_id, product_category_id, server_id, created_at_event_id, created_by_user_id, response) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_product_products; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_product_products (id, product_id, sub_product_id, quantity, server_id, created_at_event_id, created_by_user_id, response, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_products; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_products (id, name, measurement_unit_id, brand_id, model_name, server_id, created_at_event_id, created_by_user_id, response, image, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_products_product_category; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_products_product_category (id, product_id, product_category_id, server_id, created_at_event_id, created_by_user_id, response) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_suppliers; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_suppliers (id, location_id, server_id, created_at_event_id, created_by_user_id, response, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_transfer_container_product_instance; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_transfer_container_product_instance (id, transfer_container_id, product_instance_transfer_id, server_id, created_at_event_id, created_by_user_id, response, description) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_transfer_containers; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_transfer_containers (id, transfer_id, container_id, server_id, created_at_event_id, created_by_user_id, response, description) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_transfer_invoice; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_transfer_invoice (id, transfer_id, invoice_id, description) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_transfer_purchase; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_transfer_purchase (id, transfer_id, purchase_id, description) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_transfers; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_transfers (id, location_id, driver_id, server_id, vehicle_id, created_by_user_id, created_at_event_id, response, pre_marked_arrived, sent_at_event_id, arrived_at_event_id, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_vehicle_types; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_vehicle_types (id, name, server_id, created_at_event_id, created_by_user_id, response, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_vehicles; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_vehicles (id, vehicle_type_id, registration, server_id, created_at_event_id, created_by_user_id, response, image, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_lojistiks_warehouses; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_lojistiks_warehouses (id, location_id, server_id, created_at_event_id, created_by_user_id, response, description, updated_at_event_id, updated_by_user_id) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_action; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_messaging_action (message_id, action, settings, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_label; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_messaging_label (id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_messaging_message (id, user_from_id, subject, body, labels, "externalID", source, mime_type, created_at, updated_at) FROM stdin;
9d6c39d7-9645-492e-9558-4e6a3ad69629	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	test		\N	\N	\N	\N	2024-11-06 08:25:24	\N
9d6c5069-076e-4e68-9cd5-e062d6caf59b	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	test		\N	\N	\N	\N	2024-11-06 09:28:30	\N
\.


--
-- Data for Name: acorn_messaging_message_instance; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_messaging_message_instance (message_id, instance_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message_message; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_messaging_message_message (message1_id, message2_id, relationship, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message_user; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_messaging_message_user (message_id, user_id, created_at, updated_at) FROM stdin;
9d6c39d7-9645-492e-9558-4e6a3ad69629	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	\N
9d6c5069-076e-4e68-9cd5-e062d6caf59b	9d50b9ce-e930-4945-a674-dace41b30aff	\N	\N
9d6c5069-076e-4e68-9cd5-e062d6caf59b	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	\N
\.


--
-- Data for Name: acorn_messaging_message_user_group; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_messaging_message_user_group (message_id, user_group_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_status; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_messaging_status (id, name, description, created_at, updated_at) FROM stdin;
943d4f2e-ee73-4a6c-9d16-17144700dfd5	Arrived	For external messages only, like email.	\N	\N
a1958ec2-b684-4189-8eb9-2d58192e9c5d	Seen	In a list	\N	\N
1a05f53e-d7bb-43d5-81e4-a87668796840	Read	In full view, or if not truncated in a list	\N	\N
28cb0a37-ad9c-4726-a8d0-fe91582fe08c	Important	User Action	\N	\N
66e5f1b1-9c4d-41a2-8673-b74c1f187c0c	Hidden	User Action	\N	\N
\.


--
-- Data for Name: acorn_messaging_user_message_status; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_messaging_user_message_status (user_id, message_id, status_id, value, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_servers; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_servers (id, hostname, response, created_at, location_id, domain) FROM stdin;
385a4d85-31d0-415c-960d-defb9298b432	acorn-LOQ-15IRH8	\N	2024-10-19 13:37:18	\N	justice.laptop
a372d752-2d95-4830-896f-1c7a5bc9dd3c	laptop	\N	2024-10-19 13:37:18	\N	justice.laptop
\.


--
-- Data for Name: acorn_user_language_user; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_user_language_user (user_id, language_id) FROM stdin;
9d50c308-dcde-415d-b36e-4553ea3f99c9	5b8cd54d-fa39-4125-b6a7-ee6c80a2fa2e
9d50c308-dcde-415d-b36e-4553ea3f99c9	9d9a9514-c136-43fa-b05d-c769b27b00fe
9d82aca1-b7de-4f82-a65e-b1d0ea0edcc9	5b8cd54d-fa39-4125-b6a7-ee6c80a2fa2e
9da0c3f6-367a-402b-8d49-ef11333612e8	5b8cd54d-fa39-4125-b6a7-ee6c80a2fa2e
9da0c3f6-367a-402b-8d49-ef11333612e8	9d9a9514-c136-43fa-b05d-c769b27b00fe
9d4a923f-a606-4a03-ab05-1aeaf4877fec	5b8cd54d-fa39-4125-b6a7-ee6c80a2fa2e
9d4a94b1-7932-4ec9-8e86-84a9265eff47	5b8cd54d-fa39-4125-b6a7-ee6c80a2fa2e
9d4a94b1-7932-4ec9-8e86-84a9265eff47	9d9a9514-c136-43fa-b05d-c769b27b00fe
9d82aca1-b7de-4f82-a65e-b1d0ea0edcc9	9d9a9514-c136-43fa-b05d-c769b27b00fe
d57f552e-4ad2-4e9b-9055-d78bb377d1d6	5b8cd54d-fa39-4125-b6a7-ee6c80a2fa2e
\.


--
-- Data for Name: acorn_user_languages; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_user_languages (id, name) FROM stdin;
5b8cd54d-fa39-4125-b6a7-ee6c80a2fa2e	Kurdish
9d9a9514-c136-43fa-b05d-c769b27b00fe	Arabic
\.


--
-- Data for Name: acorn_user_mail_blockers; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_user_mail_blockers (id, email, template, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_user_roles; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_user_roles (id, name, permissions, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_user_throttle; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_user_throttle (id, user_id, ip_address, attempts, last_attempt_at, is_suspended, suspended_at, is_banned, banned_at) FROM stdin;
9d49e60c-dfed-495d-90ad-0a5eb3393a9d	2bc29c8f-e9b0-4bd4-8aff-e691b084a255	\N	0	\N	f	\N	f	\N
9d4afcce-0b67-4f83-81c6-af7f3211d363	9d4a923f-a606-4a03-ab05-1aeaf4877fec	\N	0	\N	f	\N	f	\N
9d4afd70-70b6-4a1e-8f4b-57833bceab1a	9d4aab74-a3e0-4fa6-bdd4-01e616d67db7	\N	0	\N	f	\N	f	\N
9d4bef59-a824-49fd-9a9e-b9d55d4916ce	9d4aa408-bcf3-4629-a1ae-cb1046a10e08	\N	0	\N	f	\N	f	\N
9d50c45a-0a34-45f8-80a6-c38e112a0806	9d4ff7a3-0307-478d-a884-4d7449a04f13	\N	0	\N	f	\N	f	\N
9d5e55a5-2fd5-4c47-8c21-19d9d55305cc	9d50c308-dcde-415d-b36e-4553ea3f99c9	\N	0	\N	f	\N	f	\N
9d68043b-26b9-49d9-ba95-d67faad4165e	9d5e9251-d614-4fb9-87ac-f6569efe465b	\N	0	\N	f	\N	f	\N
9d6c3358-819b-4587-bd8e-d04ddbe181c9	d57f552e-4ad2-4e9b-9055-d78bb377d1d6	\N	0	\N	f	\N	f	\N
9d729266-6c6f-4805-ab49-efad72bd5455	9d4a94b1-7932-4ec9-8e86-84a9265eff47	\N	0	\N	f	\N	f	\N
9d9d8120-5bb7-4e0b-b70f-9f1e73c8c8ae	9d82aca1-b7de-4f82-a65e-b1d0ea0edcc9	\N	0	\N	f	\N	f	\N
9df3017a-e752-45a0-8a83-b311380f1c42	9d8a48dc-d519-44bf-a93b-76d09934f059	\N	0	\N	f	\N	f	\N
9e221c68-427d-4b8f-90ea-e0d8711b5c4c	9e1d45eb-c9f6-4403-8fb9-27503e293a2c	\N	0	\N	f	\N	f	\N
9e2c0c73-25db-42be-8995-6824bd31ee9a	9e197206-4838-45f3-8714-42a8f029ab5b	\N	0	\N	f	\N	f	\N
\.


--
-- Data for Name: acorn_user_user_group; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_user_user_group (user_id, user_group_id) FROM stdin;
2bc29c8f-e9b0-4bd4-8aff-e691b084a255	9d6d2bbb-447a-411f-99e3-72d2c1707f90
d57f552e-4ad2-4e9b-9055-d78bb377d1d6	b67909bf-af9c-44e6-9354-77b25f777aa7
d57f552e-4ad2-4e9b-9055-d78bb377d1d6	ec893bb1-27da-43ac-a4b4-a8960bba3dde
9d4a94b1-7932-4ec9-8e86-84a9265eff47	30d93c8e-ee66-44ea-8c73-fd0d032af319
9e197206-4838-45f3-8714-42a8f029ab5b	30d93c8e-ee66-44ea-8c73-fd0d032af319
9e197206-4838-45f3-8714-42a8f029ab5b	5ed0afd7-f025-43ef-82d7-a8229ca0d4af
\.


--
-- Data for Name: acorn_user_user_group_types; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_user_user_group_types (id, name, colour, image) FROM stdin;
9d6d277e-0cbd-4a8c-8483-04fadefd0a06	Weeee	#2980B9	/logo.png
\.


--
-- Data for Name: acorn_user_user_group_version_user; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_user_user_group_version_user (user_group_version_id, user_id, role_id, id) FROM stdin;
\.


--
-- Data for Name: acorn_user_user_group_versions; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_user_user_group_versions (id, user_group_id, created_at_event_id, from_user_group_version_id) FROM stdin;
cf0386e6-9782-4383-be26-3eac2e90bd16	01b4bb49-1df8-47a9-abae-0ceaf1a07b43	\N	\N
\.


--
-- Data for Name: acorn_user_user_groups; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_user_user_groups (id, name, code, description, created_at, updated_at, parent_user_group_id, nest_left, nest_right, nest_depth, type_id, colour, image, default_user_group_version_id, from_user_group_id) FROM stdin;
9d48334c-3138-48d1-b576-ccb7b90c30eb	Registered	registered	Default group for registered users.	2024-10-19 10:37:18	2024-11-06 19:41:46	9d48334c-300c-4970-9c35-be5206270507	2	2	0	\N	\N	\N	\N	\N
9d6d2bbb-447a-411f-99e3-72d2c1707f90	reg2	reg2		2024-11-06 19:41:46	2024-11-14 10:31:03	9d48334c-3138-48d1-b576-ccb7b90c30eb	0	1	0	9d6d277e-0cbd-4a8c-8483-04fadefd0a06	#E74C3C	/parcel.jpeg	\N	\N
3b91acb1-1db8-4b07-9720-51f884623bc3	Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Efrînê	\N	\N	\N	\N	a20378bc-17a3-46f3-bb9a-0909df637985	\N	\N	\N	\N	\N	\N	\N	\N
def87161-ead8-4846-b1b0-fd3413f1c84e	Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Tebqê	\N	\N	\N	\N	3b91acb1-1db8-4b07-9720-51f884623bc3	\N	\N	\N	\N	\N	\N	\N	\N
6af83dd7-0238-49dd-a168-9eaf14145b9b	Encumena Jinê Ya Dadgeriya Civakî Li Cizîrê	\N	\N	\N	\N	def87161-ead8-4846-b1b0-fd3413f1c84e	\N	\N	\N	\N	\N	\N	\N	\N
2a94894a-43d6-4132-b832-e52cabc35205	Encumena Dadgeriya Civakî Li Cizîrê, ji van beşan pêk tê	\N	\N	\N	\N	6af83dd7-0238-49dd-a168-9eaf14145b9b	\N	\N	\N	\N	\N	\N	\N	\N
94f996bb-985a-4203-9423-d517730ea9b4	Serokatiya Encumenê	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
2cfa6092-aef5-4d48-a8d4-c182407d7b40	Komîteya Cêgratiyan	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
589ad749-a607-4f09-a899-8bb5f764e06e	Komîteya Çavnêrî Ya Dadwerî	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
6bc95789-5381-46a2-b783-1b807ef06362	Komîteya Aştbûnê	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
3195e5a8-e5cd-4531-8dfc-a7ae7e7942aa	Komîteya Bi cihanînê	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
d8890e2a-0e58-4b72-a4be-764e620989e8	Nivîsgeha Darayî û Rêveberî	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
bfac0673-ff5c-46b7-9c7e-ff7e133a9a62	Dîwan û Cêgratiyên girêdayî Encumena Dadageriya Civakî li Cizîrê	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
e6b2d42c-9cdf-46d8-b672-007c0438a772	Dîwana Dadgeriya Civakî li Qamişlo	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
08572666-8bcf-4ea4-8c8b-5aee6bbecf04	Dîwana Dadgeriya Civakî li Hesîça	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
15bff36f-cc1b-4ff4-8a78-417588fcdd61	Dîwana Dadgeriya Civakî li Tirbespiyê	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
86a38003-65a7-4e8e-96e0-6b6adac7f733	Dîwana Dadgeriya Civakî li Derbasiyê	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
699149d6-28f5-4f81-a412-6b5103abb89c	Dîwana Dadgeriya Civakî li Amûdê	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
8c07673f-9824-4af2-807a-678613c6292d	Dîwana Dadgeriya Civakî li Til Temir	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
9b1f93c4-424b-4ec4-9cf5-43e23583ab0f	Dîwana Dadgeriya Civakî li Şedadê	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
6523c683-5873-463e-8995-9ebc153e2f0d	Dîwana Dadgeriya Civakî li Girkê Legê	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
d9209dd1-4769-41bd-ab05-9e2d4d4612e9	Dîwana Dadgeriya Civakî li Dêrikê	\N	\N	\N	\N	2a94894a-43d6-4132-b832-e52cabc35205	\N	\N	\N	\N	\N	\N	\N	\N
f95d1881-7959-4de3-93d6-f72aabfc73fd	Cêgratiya Giştî li Zerganê	\N	\N	\N	\N	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	\N	\N	\N	\N	\N	\N	\N	\N
ce3e70e9-c093-4b40-896d-e2b779c62096	Cêgratiya Giştî li Til Birakê	\N	\N	\N	\N	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	\N	\N	\N	\N	\N	\N	\N	\N
1d0759f7-6d6f-4fc2-b538-093db412cdd7	Cêgratiya Giştî li Holê	\N	\N	\N	\N	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	\N	\N	\N	\N	\N	\N	\N	\N
022a1e97-b3a1-4eb8-857e-22a7baf0b8c8	Cêgratiya Giştî li Til Hemîsê	\N	\N	\N	\N	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	\N	\N	\N	\N	\N	\N	\N	\N
9663e48b-0f3b-4ba3-b393-87dcc205e2ef	Cêgratiya Giştî li Çelaxa	\N	\N	\N	\N	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	\N	\N	\N	\N	\N	\N	\N	\N
6f85ac3c-912d-433a-b539-57261b4c901c	Cêgratiya Giştî li Til Koçerê	\N	\N	\N	\N	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	\N	\N	\N	\N	\N	\N	\N	\N
fcd0ba88-28d5-4e91-92dd-cbb133efab80	Serokatiya Encumenê	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
0d352f4a-f1b0-4b1d-a61f-1228b0bc46ca	Komîteya Cêgratiyan	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
51052b50-a5d8-46e5-8b88-b25fead94c78	Komîteya Çavnêrî Ya Dadwerî	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
bdc5d5c8-81f5-484a-9c49-0ab85bbb7426	Komîteya Aştbûnê	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
e8e7a6b7-4009-4c55-985c-e57d013f9858	Komîteya Bi cihanînê	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
f352f32b-0268-432f-8384-66db09e0f5a1	Nivîsgeha Darayî û Rêveberî	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
328f15a2-e416-4b9a-9482-492e1dcf57be	Dîwan û Cêgratiyên girêdayî Encumena Dadageriya Civakî li Cizîrê	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
ba36ee58-3d57-4522-8698-0f38d79a3eb2	Dîwana Dadgeriya Civakî li Qamişlo	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
5fc9a7df-e885-40d3-b93b-93068911cc06	Dîwana Dadgeriya Civakî li Hesîça	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
b9c99550-52a5-4eca-acf2-212b39f657a7	Dîwana Dadgeriya Civakî li Tirbespiyê	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
5c9fdd8a-de3f-4603-b845-f19f7487b84f	Dîwana Dadgeriya Civakî li Derbasiyê	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
b914dc60-52c0-4ce5-a27f-2971a99a1010	Dîwana Dadgeriya Civakî li Amûdê	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
c68e2584-5d57-483e-b992-daf5461d456d	Dîwana Dadgeriya Civakî li Til Temir	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
85eb99c3-990a-4383-836d-1aca4b896cda	Dîwana Dadgeriya Civakî li Şedadê	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
20bfb872-eac9-47cc-890c-7590529c4fca	Dîwana Dadgeriya Civakî li Girkê Legê	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
fd835492-6a72-4dfd-a4c4-1762f41efb50	Dîwana Dadgeriya Civakî li Dêrikê	\N	\N	\N	\N	2d5a8b54-033a-40fc-8502-85b738aea2e8	\N	\N	\N	\N	\N	\N	\N	\N
59dc2b48-348b-403b-9015-4026e94265fe	Cêgratiya Giştî li Zerganê	\N	\N	\N	\N	fd835492-6a72-4dfd-a4c4-1762f41efb50	\N	\N	\N	\N	\N	\N	\N	\N
7664a7c3-fb5d-4fb9-8920-3245779f4878	Cêgratiya Giştî li Til Birakê	\N	\N	\N	\N	fd835492-6a72-4dfd-a4c4-1762f41efb50	\N	\N	\N	\N	\N	\N	\N	\N
01b4bb49-1df8-47a9-abae-0ceaf1a07b43	Cêgratiya Giştî li Holê	\N	\N	\N	\N	fd835492-6a72-4dfd-a4c4-1762f41efb50	\N	\N	\N	\N	\N	\N	\N	\N
6a3b3023-0a7c-4436-931a-0f9f8873d9ae	Cêgratiya Giştî li Til Hemîsê	\N	\N	\N	\N	fd835492-6a72-4dfd-a4c4-1762f41efb50	\N	\N	\N	\N	\N	\N	\N	\N
6a0c79c5-b2a8-423c-9ff7-69e439bddff9	Cêgratiya Giştî li Çelaxa	\N	\N	\N	\N	fd835492-6a72-4dfd-a4c4-1762f41efb50	\N	\N	\N	\N	\N	\N	\N	\N
053d6688-555e-478a-ac94-a67700a5781b	Cêgratiya Giştî li Til Koçerê	\N	\N	\N	\N	fd835492-6a72-4dfd-a4c4-1762f41efb50	\N	\N	\N	\N	\N	\N	\N	\N
30d93c8e-ee66-44ea-8c73-fd0d032af319	Encumena Dadgeriya Civakî ya Rêveberiya Xweser Li Bakur û Rojhilatê Sûriyê	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5ed0afd7-f025-43ef-82d7-a8229ca0d4af	Encumena Jinê a Dadgeriya Civakî Ya Rêveberiya Xweser Li Bakur û Rojhilatê Sûriyê	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
96fd3444-424c-4348-8aee-b6037e98cd3f	Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Cizîrê	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4491670f-b9c1-44df-a8cd-f47b85464625	Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Reqayê	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1e382fe2-7d64-4398-aa5d-e7444c8b9fe6	Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Feratê	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
f2e202b2-62a5-46aa-bfdd-98b7806a558c	Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Dêra Zorê	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4d4e0670-f7f4-4ab9-95b6-74e1a3bac1ad	Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Munbicê	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8d7d0361-2e9f-40bc-8aa4-559d8f70c605	Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Efrînê	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8c832e96-70ab-40b2-bbba-01c6cb6695c1	Encumena Dadgeriya Civakî û Encumena Jinê Ya Dadgeriya Civakî Li Tebqê	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
cc8e599e-f8e1-4467-9125-d4e1020d284c	Encumena Jinê Ya Dadgeriya Civakî Li Cizîrê	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
b67909bf-af9c-44e6-9354-77b25f777aa7	Encumena Dadgeriya Civakî Li Cizîrê, ji van beşan pêk tê	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
0952d96e-0392-4f82-9687-44b88d2f71c3	Serokatiya Encumenê	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
edd91c15-116c-4b81-ba18-5095b355bcad	Komîteya Cêgratiyan	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
89adc57e-be52-4af6-8282-1c5d8bc2f103	Komîteya Çavnêrî Ya Dadwerî	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
e6f8a708-c4d3-4396-bef8-8d81eed86ea0	Komîteya Aştbûnê	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
0a556562-dc1e-4370-bf07-1ba41c22bd18	Komîteya Bi cihanînê	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
9999365c-34b7-4ff4-a36b-646405a9d947	Nivîsgeha Darayî û Rêveberî	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
3f5517b1-7a35-40c8-88ba-fd86811c7a31	Dîwan û Cêgratiyên girêdayî Encumena Dadageriya Civakî li Cizîrê	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
78bdd172-5173-4bf3-a044-85f67c74a990	Dîwana Dadgeriya Civakî li Qamişlo	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
20983187-a73f-4c7d-ae18-af363cb3b80f	Dîwana Dadgeriya Civakî li Hesîça	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
6dddede5-0ef6-4f33-b9dd-ca1295d8247c	Dîwana Dadgeriya Civakî li Tirbespiyê	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
ec893bb1-27da-43ac-a4b4-a8960bba3dde	Dîwana Dadgeriya Civakî li Derbasiyê	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
f689895a-9c43-4ba6-8459-3c60dfbf8b56	Dîwana Dadgeriya Civakî li Amûdê	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
e5e95b8f-dffd-4ed5-9c17-c87f62bebd0d	Dîwana Dadgeriya Civakî li Til Temir	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
19546528-f290-4a40-94d1-f886609a8b94	Dîwana Dadgeriya Civakî li Şedadê	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
9d3ad872-fc19-47fa-b51b-6262c77aeaaf	Dîwana Dadgeriya Civakî li Girkê Legê	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
2a849d98-35b5-4d84-9890-89a02efd49c6	Dîwana Dadgeriya Civakî li Dêrikê	\N	\N	\N	\N	b67909bf-af9c-44e6-9354-77b25f777aa7	\N	\N	\N	\N	\N	\N	\N	\N
56ebd118-2837-479e-a052-4b3b721b7083	Cêgratiya Giştî li Zerganê	\N	\N	\N	\N	2a849d98-35b5-4d84-9890-89a02efd49c6	\N	\N	\N	\N	\N	\N	\N	\N
3bbf645a-8e02-4c28-88a3-f386567fe2be	Cêgratiya Giştî li Til Birakê	\N	\N	\N	\N	2a849d98-35b5-4d84-9890-89a02efd49c6	\N	\N	\N	\N	\N	\N	\N	\N
93e4bc76-377e-4f0b-a57a-4a14518fa93e	Cêgratiya Giştî li Holê	\N	\N	\N	\N	2a849d98-35b5-4d84-9890-89a02efd49c6	\N	\N	\N	\N	\N	\N	\N	\N
c5adb730-1968-400e-af3d-37c8d32d8433	Cêgratiya Giştî li Til Hemîsê	\N	\N	\N	\N	2a849d98-35b5-4d84-9890-89a02efd49c6	\N	\N	\N	\N	\N	\N	\N	\N
9617afcd-11c8-481b-95ba-112f600eef3b	Cêgratiya Giştî li Çelaxa	\N	\N	\N	\N	2a849d98-35b5-4d84-9890-89a02efd49c6	\N	\N	\N	\N	\N	\N	\N	\N
738b0e85-0214-42e4-88fa-b6649e2d0a47	Cêgratiya Giştî li Til Koçerê	\N	\N	\N	\N	2a849d98-35b5-4d84-9890-89a02efd49c6	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: acorn_user_users; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.acorn_user_users (id, name, email, password, activation_code, persist_code, reset_password_code, permissions, is_activated, activated_at, last_login, created_at, updated_at, username, surname, deleted_at, last_seen, is_guest, is_superuser, created_ip_address, last_ip_address, acorn_imap_username, acorn_imap_password, acorn_imap_server, acorn_imap_port, acorn_imap_protocol, acorn_imap_encryption, acorn_imap_authentication, acorn_imap_validate_cert, acorn_smtp_server, acorn_smtp_port, acorn_smtp_encryption, acorn_smtp_authentication, acorn_smtp_username, acorn_smtp_password, acorn_messaging_sounds, acorn_messaging_email_notifications, acorn_messaging_autocreated, acorn_imap_last_fetch, acorn_default_calendar, acorn_start_of_week, acorn_default_event_time_from, acorn_default_event_time_to, is_system_user) FROM stdin;
9d4aa2bc-d139-4fb7-8764-c847acf8a62f	p99		\N	\N	\N	\N	\N	f	\N	\N	2024-10-20 15:40:34	2024-10-20 15:40:34			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-20	2024-10-20	\N
9d4aab74-a3e0-4fa6-bdd4-01e616d67db7	fgdfg		\N	\N	\N	\N	\N	f	\N	\N	2024-10-20 16:04:56	2024-10-20 16:04:56			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-20	2024-10-20	\N
9d4ab604-841e-4f10-9774-493ac4bed052	44		\N	\N	\N	\N	\N	f	\N	\N	2024-10-20 16:34:28	2024-10-20 16:34:28			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-20	2024-10-20	\N
9d4e6d31-b500-4570-9e27-c6ce7d32b927	sdfsdf		\N	\N	\N	\N	\N	f	\N	\N	2024-10-22 12:54:09	2024-10-22 12:54:09			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-22	2024-10-22	\N
9d4ff6c3-6f79-4965-8339-6916096b6455	rt		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 07:14:39	2024-10-23 07:14:39			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
9d4ff750-42d4-4929-b71f-5a27578f1973	sdsd		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 07:16:12	2024-10-23 07:16:12			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
9d4ff772-b2f7-47e4-8060-6a0654307e2f	w44		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 07:16:34	2024-10-23 07:16:34			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
9d4ff7a3-0307-478d-a884-4d7449a04f13	w446		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 07:17:06	2024-10-23 07:17:06			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
9d5036f3-669b-4790-afea-d7bd8f013db6	gggg		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 10:14:08	2024-10-23 10:14:08			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
9d5045c9-f43f-48c6-aed6-6e65d0cd84d6	weeeeeeeeee		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 10:55:38	2024-10-23 10:55:38			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
9d5074ca-f5a6-4231-afd4-9ee5e5e19b97	jj		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 13:07:04	2024-10-23 13:07:04			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
9d50b904-7777-4afc-90fc-c8f07d73f5c7	yankee		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 16:17:50	2024-10-23 16:17:50			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
9d50b9ce-e930-4945-a674-dace41b30aff	24		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 16:20:02	2024-10-23 16:20:02			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
9d50ba26-de7a-4c3a-8e2b-cfc959b8ccc7	67		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 16:21:00	2024-10-23 16:21:00			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
9d523e58-92c0-4c6b-856c-7c3ed3df95c8	hhhhhhhhhhhhh		\N	\N	\N	\N	\N	f	\N	\N	2024-10-24 10:26:28	2024-10-24 10:26:28			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-24	2024-10-24	\N
9d547101-5afb-4d3f-9fb4-3a97eea83915	bbbb		\N	\N	\N	\N	\N	f	\N	\N	2024-10-25 12:39:47	2024-10-25 12:39:47			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-25	2024-10-25	\N
9d58bde5-99f2-49a2-a281-3e805bb01224	b		\N	\N	\N	\N	\N	f	\N	\N	2024-10-27 15:58:06	2024-10-27 15:58:06			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-27	2024-10-27	\N
9d58bed9-1c00-4aef-9af7-d0ab54ce9489	kk		\N	\N	\N	\N	\N	f	\N	\N	2024-10-27 16:00:45	2024-10-27 16:00:45			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-27	2024-10-27	\N
9d4aa408-bcf3-4629-a1ae-cb1046a10e08	u8		\N	\N	\N	\N	\N	f	\N	\N	2024-10-20 15:44:11	2024-10-30 10:41:59			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-20	2024-10-20	\N
9d5e9251-d614-4fb9-87ac-f6569efe465b	ya		\N	\N	\N	\N	\N	f	\N	\N	2024-10-30 13:31:13	2024-10-30 13:31:13			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-30	2024-10-30	\N
9d8c5e62-84e1-4654-9619-d7c2ac04d3c3	hhhhhhhhhhhh			\N	\N	\N	\N	f	\N	\N	2024-11-22 07:54:04	2024-11-22 07:54:04			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9d626095-4ac7-42ee-a9df-020710ba9b36	weeeeeeeeeee			\N	\N	\N	\N	f	\N	\N	2024-11-01 10:55:27	2024-11-01 10:55:27			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9d4a94b1-7932-4ec9-8e86-84a9265eff47	p35		\N	\N	\N	\N	\N	f	\N	\N	2024-10-20 15:01:17	2024-11-09 12:08:08			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-20	2024-10-20	\N
9d8d2abf-aa1c-4fd1-9153-a90273180632	gggg			\N	\N	\N	\N	f	\N	\N	2024-11-22 17:25:31	2024-11-22 17:25:31			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9d7c7e22-de3b-4ecc-9bce-782634fac5a5	hhhh			\N	\N	\N	\N	f	\N	\N	2024-11-14 10:29:37	2024-11-14 10:29:37			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
2bc29c8f-e9b0-4bd4-8aff-e691b084a255	DEMO user	demo@user.com	password	\N	\N	\N	\N	f	\N	\N	\N	2024-11-17 10:57:25	demo@user.com		\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9d8a48dc-d519-44bf-a93b-76d09934f059	yay22			\N	\N	\N	\N	f	\N	\N	2024-11-21 07:02:14	2024-11-21 07:02:14			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9d7c791c-51ad-45ee-8f22-5bfa6a06139d	weeeeeeeeeee33			\N	\N	\N	\N	f	\N	\N	2024-11-14 10:15:34	2024-11-21 07:13:38			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9d8c5e5a-7572-4be9-a814-e3b7aeb72b28	hhhhhhhhhhhh			\N	\N	\N	\N	f	\N	\N	2024-11-22 07:53:59	2024-11-22 07:53:59			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9d8d3ad8-4d5d-44e6-85e8-e961c06ef53d	ert		\N	\N	\N	\N	\N	f	\N	\N	2024-11-22 18:10:32	2024-11-22 18:10:32			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
d57f552e-4ad2-4e9b-9055-d78bb377d1d6	admin		\N	\N	\N	\N	\N	f	\N	\N	\N	2024-11-26 18:24:13			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	\N	\N	\N
9d50c308-dcde-415d-b36e-4553ea3f99c9	yankee doodle		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 16:45:50	2024-11-29 09:46:47			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
9d82aca1-b7de-4f82-a65e-b1d0ea0edcc9	Test		\N	\N	\N	\N	\N	f	\N	\N	2024-11-17 12:14:35	2024-11-30 20:20:29			\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	\N	\N	f
9d4a923f-a606-4a03-ab05-1aeaf4877fec	p1		\N	\N	\N	\N	\N	f	\N	\N	2024-10-20 14:54:27	2024-12-02 11:11:09		w	\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-20	2024-10-20	\N
9da0c3f6-367a-402b-8d49-ef11333612e8	fff		\N	\N	\N	\N	\N	f	\N	\N	2024-12-02 11:14:40	2024-12-02 11:14:40		f	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9e197206-4838-45f3-8714-42a8f029ab5b	yay		$2y$10$SPgyly09h98tg4YE96ioAO99HXq3brZSAC6hBSB0rzNItYvrFFzMO	\N	\N	\N	\N	f	\N	\N	2025-01-31 11:00:43	2025-01-31 11:00:43			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9e1d409b-3a31-469e-92d9-b7d7c02cf51d	t			\N	\N	\N	\N	f	\N	\N	2025-02-02 08:25:51	2025-02-02 08:25:51			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9e1d45eb-c9f6-4403-8fb9-27503e293a2c	yy			\N	\N	\N	\N	f	\N	\N	2025-02-02 08:40:43	2025-02-02 08:40:43			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9e1d4614-059d-4e51-ad40-ef30deaad16c	yy			\N	\N	\N	\N	f	\N	\N	2025-02-02 08:41:09	2025-02-02 08:41:09			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9e1d46fa-9e3f-495b-b6e2-547b0ee7a5b0	u			\N	\N	\N	\N	f	\N	\N	2025-02-02 08:43:40	2025-02-02 08:43:40			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9e1d4a13-41fa-4571-99eb-7fd0758b3fa3	u			\N	\N	\N	\N	f	\N	\N	2025-02-02 08:52:20	2025-02-02 08:52:20			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9e1d4ab4-e547-4551-b4c8-83b37d6ca06f	yy			\N	\N	\N	\N	f	\N	\N	2025-02-02 08:54:06	2025-02-02 08:54:06			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9e1d5088-228e-44bb-aac3-1a86d7524e28	j			\N	\N	\N	\N	f	\N	\N	2025-02-02 09:10:23	2025-02-02 09:10:23			\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f
9d50b920-64ca-4e51-b8ad-bbc4e489e90c	2		\N	\N	\N	\N	\N	f	\N	\N	2024-10-23 16:18:08	2025-02-04 08:41:46			2025-02-04 08:41:46	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	37b605c0-6ed6-49ac-9a77-53901a051d3b	1	2024-10-23	2024-10-23	\N
\.


--
-- Data for Name: backend_access_log; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.backend_access_log (id, user_id, ip_address, created_at, updated_at) FROM stdin;
1	1	127.0.0.1	2024-10-19 10:38:02	2024-10-19 10:38:02
2	1	127.0.0.1	2024-10-20 14:31:40	2024-10-20 14:31:40
3	1	127.0.0.1	2024-10-20 16:55:16	2024-10-20 16:55:16
4	1	127.0.0.1	2024-10-23 06:29:22	2024-10-23 06:29:22
5	1	127.0.0.1	2024-10-23 06:37:10	2024-10-23 06:37:10
6	1	127.0.0.1	2024-10-23 06:40:57	2024-10-23 06:40:57
7	1	127.0.0.1	2024-10-23 06:41:35	2024-10-23 06:41:35
8	1	127.0.0.1	2024-10-23 06:46:49	2024-10-23 06:46:49
9	1	127.0.0.1	2024-10-23 06:47:21	2024-10-23 06:47:21
10	1	127.0.0.1	2024-10-23 10:14:55	2024-10-23 10:14:55
11	1	127.0.0.1	2024-10-23 16:48:59	2024-10-23 16:48:59
12	1	127.0.0.1	2024-10-23 18:24:01	2024-10-23 18:24:01
13	1	127.0.0.1	2024-10-24 08:52:18	2024-10-24 08:52:18
14	1	127.0.0.1	2024-10-24 18:14:24	2024-10-24 18:14:24
15	1	127.0.0.1	2024-10-24 19:48:17	2024-10-24 19:48:17
16	1	127.0.0.1	2024-10-25 07:09:15	2024-10-25 07:09:15
17	1	127.0.0.1	2024-10-25 09:53:37	2024-10-25 09:53:37
18	1	127.0.0.1	2024-10-25 14:31:17	2024-10-25 14:31:17
19	1	127.0.0.1	2024-10-27 16:05:16	2024-10-27 16:05:16
20	1	127.0.0.1	2024-10-27 17:17:32	2024-10-27 17:17:32
21	1	127.0.0.1	2024-10-28 09:31:48	2024-10-28 09:31:48
22	1	127.0.0.1	2024-10-30 08:07:32	2024-10-30 08:07:32
23	1	127.0.0.1	2024-10-30 12:49:42	2024-10-30 12:49:42
24	1	127.0.0.1	2024-10-31 14:08:20	2024-10-31 14:08:20
25	1	127.0.0.1	2024-11-03 07:19:06	2024-11-03 07:19:06
26	1	127.0.0.1	2024-11-04 10:31:58	2024-11-04 10:31:58
27	1	127.0.0.1	2024-11-05 11:00:57	2024-11-05 11:00:57
28	1	127.0.0.1	2024-11-19 14:17:18	2024-11-19 14:17:18
29	1	127.0.0.1	2024-11-21 12:24:38	2024-11-21 12:24:38
30	1	127.0.0.1	2024-11-23 13:39:44	2024-11-23 13:39:44
31	1	127.0.0.1	2024-11-25 12:16:41	2024-11-25 12:16:41
32	1	127.0.0.1	2024-11-26 14:43:34	2024-11-26 14:43:34
33	1	127.0.0.1	2024-11-29 09:42:33	2024-11-29 09:42:33
34	1	127.0.0.1	2024-12-03 09:27:05	2024-12-03 09:27:05
35	1	127.0.0.1	2024-12-05 10:07:51	2024-12-05 10:07:51
36	1	127.0.0.1	2024-12-31 15:21:10	2024-12-31 15:21:10
37	1	127.0.0.1	2025-01-10 14:21:59	2025-01-10 14:21:59
38	1	127.0.0.1	2025-01-24 10:26:27	2025-01-24 10:26:27
39	1	127.0.0.1	2025-01-24 10:38:57	2025-01-24 10:38:57
40	1	127.0.0.1	2025-02-07 10:51:06	2025-02-07 10:51:06
41	1	127.0.0.1	2025-02-08 09:08:12	2025-02-08 09:08:12
42	2	127.0.0.1	2025-02-18 08:47:10	2025-02-18 08:47:10
43	1	127.0.0.1	2025-02-18 09:35:32	2025-02-18 09:35:32
\.


--
-- Data for Name: backend_user_groups; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.backend_user_groups (id, name, created_at, updated_at, code, description, is_new_user_default) FROM stdin;
1	Owners	2024-10-19 10:37:18	2024-10-19 10:37:18	owners	Default group for website owners.	f
\.


--
-- Data for Name: backend_user_preferences; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.backend_user_preferences (id, user_id, namespace, "group", item, value) FROM stdin;
9	1	acorn_criminal	legalcases	lists-relationlegalcasejusticescanneddocumentslegalcaseviewlist	{"visible":["name","legalcase","_actions"],"order":["id","name","document","created_by_user","created_at_event","legalcase","_qrcode","_actions"],"per_page":"10"}
3	1	acorn_houseofpeace	legalcases	lists	{"visible":["legalcase_name","legalcase_closed_at_event","legalcase[justice_scanned_documents_legalcase]","legalcase[justice_legalcase_legalcase_category_legalcases]","houseofpeace_events_legalcase","_actions"],"order":["id","created_at_event","created_by_user","legalcase_name","legalcase_closed_at_event","legalcase[justice_scanned_documents_legalcase]","legalcase[justice_legalcase_identifiers_legalcase]","legalcase[justice_legalcase_legalcase_category_legalcases]","_qrcode","houseofpeace_events_legalcase","_actions"],"per_page":"20"}
4	1	acorn_criminal	appeals	lists	{"visible":["created_at_event","event","name"],"order":["id","legalcase","created_at_event","created_by_user","event","name","_qrcode"],"per_page":"20"}
8	1	acorn_user	usergroups	lists	{"visible":["name","type","type_colour","type_image","colour","code","users_count","created_at","auth_is_member"],"order":["id","name","type","type_colour","type_image","colour","image","parent_user_group","code","users_count","created_at","auth_is_member"],"per_page":20}
5	1	backend	backend	preferences	{"locale":"en","fallback_locale":"en","timezone":"UTC","editor_font_size":"12","editor_word_wrap":"fluid","editor_code_folding":"manual","editor_tab_size":"4","editor_theme":"twilight","editor_show_invisibles":"0","editor_highlight_active_line":"1","editor_use_hard_tabs":"0","editor_show_gutter":"1","editor_auto_closing":"0","editor_autocompletion":"manual","editor_enable_snippets":"0","editor_display_indent_guides":"0","editor_show_print_margin":"0","dark_mode":"light","menu_location":"","icon_location":"","user_id":1}
6	1	acorn_criminal	legalcases	lists-relationcriminallegalcaseprosecutorlegalcasesviewlist	{"visible":["name","surname","email","created_at","last_seen","groups","languages"],"order":["id","username","name","surname","email","created_at","last_seen","is_guest","created_ip_address","last_ip_address","groups","languages"],"per_page":false}
7	1	acorn_calendar	months	calendars-instance	{"visible":["eventPart[location][name]","instance_end","eventPart[name]","name","eventPart[repeatWithFrequency()]","instance_start","eventPart[attendees()]","eventPart[isLocked()]","eventPart[alarm]","name"],"order":["id","date","event_part_id","eventPart[location][name]","instance_num","instance_end","eventPart[name]","name","eventPart[repeatWithFrequency()]","instance_start","eventPart[attendees()]","created_at","updated_at","eventPart[canWrite()]","eventPart[isLocked()]","eventPart[alarm]","name"],"per_page":null}
11	1	acorn_user	languages	lists	{"visible":["id","name"],"order":["id","name"],"per_page":"20"}
12	1	acorn_criminal	legalcases	lists-relationcriminallegalcasedefendantslegalcaseviewlist	{"visible":["user","created_at_event","criminal_defendant_detentions_legalcase_defendant","criminal_defendant_crimes_legalcase_defendant","_actions","updated_at_event","updated_by_user","server"],"order":["id","legalcase","user","created_at_event","created_by_user","criminal_defendant_detentions_legalcase_defendant","criminal_defendant_crimes_legalcase_defendant","_qrcode","_actions","description","updated_at_event","updated_by_user","server"],"per_page":"10"}
10	1	acorn_criminal	legalcases	lists-relationcriminaltrialslegalcaseviewlist	{"visible":["legalcase","criminal_trial_judges_trial","criminal_trial_sessions_trial","_actions","calendar[name]","first_event_part[start]","first_event_part[repeat]","first_event_part[status][name]"],"order":["id","legalcase","created_at_event","created_by_user","criminal_trial_judges_trial","criminal_trial_sessions_trial","_qrcode","_actions","calendar[name]","first_event_part[type][name]","first_event_part[name]","first_event_part[start]","first_event_part[end]","first_event_part[alarm]","first_event_part[description]","first_event_part[repeat]","first_event_part[mask]","first_event_part[repeat_frequency]","first_event_part[mask_type]","first_event_part[parentEventPart][name]","first_event_part[until]","first_event_part[users]","first_event_part[groups]","first_event_part[status][name]","first_event_part[location][name]","owner_user_id","owner_user_group_id","permissions","created_at","updated_at"],"per_page":"10"}
2	1	backend	reportwidgets	dashboard	{"welcome":{"class":"Backend\\\\ReportWidgets\\\\Welcome","sortOrder":50,"configuration":{"ocWidgetWidth":7}},"systemStatus":{"class":"System\\\\ReportWidgets\\\\Status","sortOrder":60,"configuration":{"title":"System status","ocWidgetWidth":7,"ocWidgetNewRow":null}}}
1	1	acorn_criminal	legalcases	lists	{"visible":["legalcase_name","legalcase[owner_user_group][name]","criminal_legalcase_prosecutor_legalcases","criminal_legalcase_evidence_legalcase","criminal_trials_legalcase","legalcase[justice_scanned_documents_legalcase][name]","criminal_legalcase_plaintiffs_legalcase","legalcase_created_at_event","legalcase_updated_at_event","legalcase_type","_actions"],"order":["id","_qrcode","legalcase_name","legalcase[owner_user_group][name]","criminal_legalcase_prosecutor_legalcases","criminal_appeals_legalcase","criminal_legalcase_defendants_legalcase","criminal_legalcase_related_events_legalcase","criminal_legalcase_witnesses_legalcase","criminal_legalcase_evidence_legalcase","criminal_trials_legalcase","server","legalcase_closed_at_event","legalcase[justice_scanned_documents_legalcase][name]","legalcase[justice_legalcase_identifiers_legalcase][name]","legalcase[justice_warrants_legalcase][name]","legalcase[justice_legalcase_legalcase_category_legalcases][name]","judge_committee_user_group","criminal_legalcase_plaintiffs_legalcase","legalcase_created_at_event","legalcase_created_by_user","legalcase_description","legalcase_updated_at_event","legalcase_type","legalcase_updated_by_user","_actions"],"per_page":"20"}
13	1	acorn_criminal	legalcases	lists-relationcriminallegalcaserelatedeventslegalcaseviewlist	{"visible":["first_event_part[name]","first_event_part[start]","first_event_part[end]","first_event_part[alarm]","first_event_part[repeat]","first_event_part[repeat_frequency]","first_event_part[status][name]","first_event_part[location][name]","_actions"],"order":["legalcase","id","created_at","created_by_user","updated_at","owner_user_id","owner_user_group_id","permissions","_qrcode","calendar[name]","first_event_part[name]","first_event_part[type][name]","first_event_part[start]","first_event_part[end]","first_event_part[alarm]","first_event_part[description]","first_event_part[repeat]","first_event_part[mask]","first_event_part[repeat_frequency]","first_event_part[mask_type]","first_event_part[parentEventPart][name]","first_event_part[until]","first_event_part[status][name]","first_event_part[location][name]","_actions","first_event_part[users]","first_event_part[groups]"],"per_page":"10"}
\.


--
-- Data for Name: backend_user_roles; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.backend_user_roles (id, name, code, description, permissions, is_system, created_at, updated_at) FROM stdin;
1	Publisher	publisher	Site editor with access to publishing tools.		t	2024-10-19 10:37:18	2024-10-19 10:37:18
2	Developer	developer	Site administrator with access to developer tools.		t	2024-10-19 10:37:18	2024-10-19 10:37:18
\.


--
-- Data for Name: backend_user_throttle; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.backend_user_throttle (id, user_id, ip_address, attempts, last_attempt_at, is_suspended, suspended_at, is_banned, banned_at) FROM stdin;
1	1	127.0.0.1	0	\N	f	\N	f	\N
2	2	\N	0	\N	f	\N	f	\N
\.


--
-- Data for Name: backend_users; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.backend_users (id, first_name, last_name, login, email, password, activation_code, persist_code, reset_password_code, permissions, is_activated, role_id, activated_at, last_login, created_at, updated_at, deleted_at, is_superuser, metadata, acorn_url, acorn_user_user_id) FROM stdin;
1	Admin	Person	admin	admin@example.com	$2y$10$A487JegVfo9RmI9gD89kiuU0RHuj2sNKSAvu4ZXkMwA42JWAnecoS	\N	$2y$10$ijrJ234KkGAkO4Unp6uoOenr3AClxCDZq1s6VVmqhkNw.DX.AeV.u	\N		t	2	\N	2025-02-18 09:35:32	2024-10-19 10:37:18	2025-02-18 09:35:32	\N	t	\N	\N	d57f552e-4ad2-4e9b-9055-d78bb377d1d6
2	Demo		demo	demo@example.com	$2y$10$qXppZYCFKO3PBwI2JUZ0mORjrR/eOhLIkCdKe2U5aPsAWys.sr.Qy		$2y$10$DAiTJ/6Nz/inGIpDIRi1POcb8BQNZU80ev64QTKJeoVXqV51JxQvq		{"cms.manage_content":-1,"cms.manage_assets":-1,"cms.manage_pages":-1,"cms.manage_layouts":-1,"cms.manage_partials":-1,"cms.manage_themes":-1,"cms.manage_theme_options":-1,"backend.access_dashboard":1,"backend.manage_default_dashboard":-1,"backend.manage_users":-1,"backend.impersonate_users":-1,"backend.manage_preferences":1,"backend.manage_editor":-1,"backend.manage_own_editor":-1,"backend.manage_branding":1,"media.manage_media":-1,"backend.allow_unsafe_markdown":-1,"system.manage_updates":-1,"system.access_logs":-1,"system.manage_mail_settings":-1,"system.manage_mail_templates":-1,"acorn.rtler.change_settings":1,"acorn.users.access_users":1,"acorn.users.access_groups":1,"acorn.users.access_settings":1,"acorn.users.impersonate_user":-1,"winter.location.access_settings":1,"winter.tailwindui.manage_own_appearance.dark_mode":1,"winter.tailwindui.manage_own_appearance.menu_location":1,"winter.tailwindui.manage_own_appearance.item_location":1,"winter.translate.manage_locales":1,"winter.translate.manage_messages":1,"acorn_location":1,"acorn_messaging":-1,"calendar_view":1,"change_the_past":1,"access_settings":1,"acorn.criminal.legalcases__legalcase_name__update":-1,"acorn.criminal.legalcases__owner_user_group_id__update":-1,"acorn.criminal.legalcases__legalcase_type_id__update":-1}	t	\N	\N	2025-02-18 08:47:10	\N	2025-02-19 06:46:25	\N	f			d57f552e-4ad2-4e9b-9055-d78bb377d1d6
\.


--
-- Data for Name: backend_users_groups; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.backend_users_groups (user_id, user_group_id, deleted_at) FROM stdin;
1	1	\N
\.


--
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.cache (key, value, expiration) FROM stdin;
\.


--
-- Data for Name: cms_theme_data; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.cms_theme_data (id, theme, data, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cms_theme_logs; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.cms_theme_logs (id, type, theme, template, old_template, content, old_content, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cms_theme_templates; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.cms_theme_templates (id, source, path, content, file_size, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: deferred_bindings; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.deferred_bindings (id, master_type, master_field, slave_type, slave_id, session_key, is_bind, created_at, updated_at, pivot_data) FROM stdin;
1	Acorn\\Justice\\Models\\ScannedDocument	image	System\\Models\\File	1	Lcjktw19QO77feE3VHn1DVg7UCA4yW4vxm87iEz0	t	2024-10-20 18:06:08	2024-10-20 18:06:08	\N
60	Acorn\\Criminal\\Models\\LegalcaseDefendant	criminal_defendant_crimes_legalcase_defendant	Acorn\\Criminal\\Models\\DefendantCrime	9da0814a-858c-4db6-a642-dbd207749636	k3jWwTJdd9fceM80c0xMv4RJffuIH57eIp0vQep9	t	2024-12-02 08:08:14	2024-12-02 08:08:14	\N
61	Acorn\\Criminal\\Models\\LegalcaseDefendant	criminal_defendant_crimes_legalcase_defendant	Acorn\\Criminal\\Models\\DefendantCrime	9da081f1-d7b5-4a04-af31-79d5e3d923dd	qdEunt1t72KpVd4HxfU1ZJl8mK9rzs9uj9EwcrFM	t	2024-12-02 08:10:04	2024-12-02 08:10:04	\N
62	Acorn\\Criminal\\Models\\DefendantCrime	criminal_crime_sentences_defendant_crime	Acorn\\Criminal\\Models\\CrimeSentence	9da4789e-c6c4-4faa-8d1d-a686216fe476	WhVLdG3m8ywkiCq5P5OKwbfE6li3D7hZ10XtXFel	t	2024-12-04 07:27:18	2024-12-04 07:27:18	\N
64	Acorn\\Lojistiks\\Models\\ProductInstance	image	System\\Models\\File	82	TY6QFZ0XP3JvPJDXQMQlsXATVInykwzExvcxC1fM	t	2024-12-27 09:07:10	2024-12-27 09:07:10	\N
20	Acorn\\Justice\\Models\\ScannedDocument	image	System\\Models\\File	25	lbRIRUSl1aKRLPJLXK5DcD8gnL7oFhQSJICAWeYF	t	2024-10-27 16:29:28	2024-10-27 16:29:28	\N
21	Acorn\\Justice\\Models\\ScannedDocument	document	System\\Models\\File	26	GEDlfJslMe9EzHAqkbdO4ZancRuFHFuXZWlfwM1h	t	2024-10-27 16:31:47	2024-10-27 16:31:47	\N
29	Acorn\\Criminal\\Models\\Legalcase	criminal_legalcase_prosecutor_legalcases	Acorn\\User\\Models\\User	9d50b904-7777-4afc-90fc-c8f07d73f5c7	evHprewR3HJsSceuMA1Z8bE6EM7LpsyPKk7eJkkQ	t	2024-11-06 19:40:24	2024-11-06 19:40:24	\N
30	Acorn\\Criminal\\Models\\Legalcase	criminal_legalcase_prosecutor_legalcases	Acorn\\User\\Models\\User	9d626095-4ac7-42ee-a9df-020710ba9b36	evHprewR3HJsSceuMA1Z8bE6EM7LpsyPKk7eJkkQ	t	2024-11-06 19:40:24	2024-11-06 19:40:24	\N
57	Acorn\\Justice\\Models\\Legalcase	legalcase_justice_scanned_documents_legalcase	Acorn\\Justice\\Models\\ScannedDocument	9d8d3b6e-1131-402f-9955-b7317b4beb4b	jIJn2YU6YdN2gV8W9wSXkmFs60LSXNC03WNMkn8B	t	2024-11-22 18:12:10	2024-11-22 18:12:10	\N
68	Acorn\\Criminal\\Models\\LegalcaseDefendant	criminal_defendant_detentions_legalcase_defendant	Acorn\\Criminal\\Models\\DefendantDetention	9e0d37bf-13b6-4a8b-b3a8-12025372c510	s2eJXFOXJBwy5vKjvIzzAJFqUOsnC7PDsuYImfpo	t	2025-01-25 09:07:50	2025-01-25 09:07:50	\N
69	Acorn\\Justice\\Models\\LegalcaseCategory	children	Acorn\\Justice\\Models\\LegalcaseCategory	9e138105-d410-4cad-be90-2f5d9a01b0f3	4ocFSCqqPvPjlDw7nceNztCHGgbkwcZPuYTYqObV	t	2025-01-28 12:07:42	2025-01-28 12:07:42	\N
71	Acorn\\Criminal\\Models\\DefendantCrime	criminal_crime_sentences_defendant_crime	Acorn\\Criminal\\Models\\CrimeSentence	9e214b95-dbd2-4dd2-90e8-e3a89516bd32	9c5KshEoiBVEnHU17cj2fAIC5M99HwO3iVxQckBP	t	2025-02-04 08:39:52	2025-02-04 08:39:52	\N
72	Acorn\\Criminal\\Models\\LegalcaseEvidence	criminal_crime_evidence_legalcase_evidences	Acorn\\Criminal\\Models\\DefendantCrime	9da08032-8574-4b0f-91e2-3d04f87a48b6	FORS2U2TTKSl7HehyxysdR3ybOG4PHbR3KFXe6TX	t	2025-02-04 08:44:32	2025-02-04 08:44:32	\N
76	Acorn\\Justice\\Models\\ScannedDocument	document	System\\Models\\File	90	qr8Dy4xWJLfL0ly6qL63CY0mmX4nGV7ichqEJ7ht	t	2025-02-05 14:26:53	2025-02-05 14:26:53	\N
78	Acorn\\Criminal\\Models\\DefendantCrime	criminal_crime_evidence_defendant_crimes	Acorn\\Criminal\\Models\\LegalcaseEvidence	9e2423d2-2541-43fb-999f-68ebf0c8c71f	tdSgwhl8TAlSJ8Cc88dpqz9QmJjBS9iKHmbshrmj	t	2025-02-05 18:36:09	2025-02-05 18:36:09	\N
79	Acorn\\Criminal\\Models\\LegalcaseEvidence	criminal_crime_evidence_legalcase_evidences	Acorn\\Criminal\\Models\\DefendantCrime	9e2bc3de-c248-414a-ae83-9be0e4d704f6	VXyis208P4u1KNVA9Tqt3HlBrSNL7Xufe1XKEHFk	t	2025-02-09 13:34:29	2025-02-09 13:34:29	\N
84	Acorn\\Criminal\\Models\\Legalcase	criminal_legalcase_plaintiffs_legalcase	Acorn\\Criminal\\Models\\LegalcasePlaintiff	9e3fdfb0-aede-4e43-954b-43fb35151657	QmrL3mnq99VvNXXAki8yyN4umO6fixANHWBnM3uM	t	2025-02-19 13:28:50	2025-02-19 13:28:50	\N
\.


--
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.failed_jobs (id, connection, queue, payload, failed_at, exception, uuid) FROM stdin;
\.


--
-- Data for Name: job_batches; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.migrations (id, migration, batch) FROM stdin;
1	2013_10_01_000001_Db_Deferred_Bindings	1
2	2013_10_01_000002_Db_System_Files	1
3	2013_10_01_000003_Db_System_Plugin_Versions	1
4	2013_10_01_000004_Db_System_Plugin_History	1
5	2013_10_01_000005_Db_System_Settings	1
6	2013_10_01_000006_Db_System_Parameters	1
7	2013_10_01_000007_Db_System_Add_Disabled_Flag	1
8	2013_10_01_000008_Db_System_Mail_Templates	1
9	2013_10_01_000009_Db_System_Mail_Layouts	1
10	2014_10_01_000010_Db_Jobs	1
11	2014_10_01_000011_Db_System_Event_Logs	1
12	2014_10_01_000012_Db_System_Request_Logs	1
13	2014_10_01_000013_Db_System_Sessions	1
14	2015_10_01_000014_Db_System_Mail_Layout_Rename	1
15	2015_10_01_000015_Db_System_Add_Frozen_Flag	1
16	2015_10_01_000016_Db_Cache	1
17	2015_10_01_000017_Db_System_Revisions	1
18	2015_10_01_000018_Db_FailedJobs	1
19	2016_10_01_000019_Db_System_Plugin_History_Detail_Text	1
20	2016_10_01_000020_Db_System_Timestamp_Fix	1
21	2017_08_04_121309_Db_Deferred_Bindings_Add_Index_Session	1
22	2017_10_01_000021_Db_System_Sessions_Update	1
23	2017_10_01_000022_Db_Jobs_FailedJobs_Update	1
24	2017_10_01_000023_Db_System_Mail_Partials	1
25	2017_10_23_000024_Db_System_Mail_Layouts_Add_Options_Field	1
26	2021_10_01_000025_Db_Add_Pivot_Data_To_Deferred_Bindings	1
27	2022_08_06_000026_Db_System_Add_App_Birthday_Date	1
28	2022_10_14_000027_Db_Jobs_FailedJobs_Update	1
29	2023_09_24_000028_Db_System_Sessions_Indexes	1
30	2023_10_20_000029_Db_Jobs_Batches	1
31	2013_10_01_000001_Db_Backend_Users	2
32	2013_10_01_000002_Db_Backend_User_Groups	2
33	2013_10_01_000003_Db_Backend_Users_Groups	2
34	2013_10_01_000004_Db_Backend_User_Throttle	2
35	2014_01_04_000005_Db_Backend_User_Preferences	2
36	2014_10_01_000006_Db_Backend_Access_Log	2
37	2014_10_01_000007_Db_Backend_Add_Description_Field	2
38	2015_10_01_000008_Db_Backend_Add_Superuser_Flag	2
39	2016_10_01_000009_Db_Backend_Timestamp_Fix	2
40	2017_10_01_000010_Db_Backend_User_Roles	2
41	2018_12_16_000011_Db_Backend_Add_Deleted_At	2
42	2023_02_16_000012_Db_Backend_Add_User_Metadata	2
43	2023_09_09_000013_Db_Backend_Add_Users_Groups_Delete_At	2
44	2014_10_01_000001_Db_Cms_Theme_Data	3
45	2016_10_01_000002_Db_Cms_Timestamp_Fix	3
46	2017_10_01_000003_Db_Cms_Theme_Logs	3
47	2018_11_01_000001_Db_Cms_Theme_Templates	3
48	2024_01_01_000001_Db_Backend_Users_Url	4
49	2024_01_01_000001_Db_Functions	4
50	2024_01_01_000001_Db_Servers	4
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.sessions (id, payload, last_activity, user_id, ip_address, user_agent) FROM stdin;
\.


--
-- Data for Name: system_event_logs; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.system_event_logs (id, level, message, details, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_files; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.system_files (id, disk_name, file_name, file_size, content_type, title, description, field, attachment_id, attachment_type, is_public, sort_order, created_at, updated_at) FROM stdin;
1	671546902aaa4525429965.png	rtl.png	18920	image/png	\N	\N	\N	\N	\N	t	1	2024-10-20 18:06:08	2024-10-20 18:06:08
33	671e790163b0e669805409.jpg	clowns.jpg	110069	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	33	2024-10-27 17:31:45	2024-10-27 17:31:45
43	672086d293e26262276061.jpg	world.jpg	106551	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	43	2024-10-29 06:55:14	2024-10-29 06:55:14
34	671e7b05cb157672682907.png	rtl.png	18920	image/png	\N	\N	document	9d58e27e-b01e-4bdc-94c9-c63f5850f8b4	Acorn\\Justice\\Models\\ScannedDocument	t	34	2024-10-27 17:40:21	2024-10-27 17:40:26
20	671e6615cae58692184608.jpg	cat.jpg	990881	image/jpeg	\N	\N	image	\N	Acorn\\Justice\\Models\\ScannedDocument	t	20	2024-10-27 16:11:01	2024-10-27 16:11:01
35	671e7c0e3ae79147611799.png	padlock.png	103003	image/png	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	35	2024-10-27 17:44:46	2024-10-27 17:44:46
5	671897a1a2709654378369.png	logo.png	1853297	image/png	\N	\N	logo	1	Backend\\Models\\BrandSetting	t	5	2024-10-23 06:28:49	2024-10-23 06:29:02
52	6723ab1d997df696935298.png	logo.png	1853297	image/png	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	52	2024-10-31 16:06:53	2024-10-31 16:06:53
36	671e93d6e46f6203098906.jpg	foundation-arrows.jpg	72760	image/jpeg	\N	\N	document	9d59085b-1de7-46cd-907e-0880f58a7bd5	Acorn\\Justice\\Models\\ScannedDocument	t	36	2024-10-27 19:26:14	2024-10-27 19:26:18
44	672088442bd8b260439232.jpg	world.jpg	106551	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	44	2024-10-29 07:01:24	2024-10-29 07:01:24
21	671e665098cfd973633481.jpg	cat.jpg	990881	image/jpeg	\N	\N	image	\N	Acorn\\Justice\\Models\\ScannedDocument	t	21	2024-10-27 16:12:00	2024-10-27 16:12:00
37	671f87d9d7a46271013954.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	37	2024-10-28 12:47:21	2024-10-28 12:47:21
38	671f8ad4aa2c3704830849.png	reporting.png	86111	image/png	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	38	2024-10-28 13:00:04	2024-10-28 13:00:04
49	6722360387dbd719123179.png	transfer.png	5784	image/png	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	49	2024-10-30 13:34:59	2024-10-30 13:34:59
39	671f8afc20f27687012476.png	reporting.png	86111	image/png	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	39	2024-10-28 13:00:44	2024-10-28 13:00:44
22	671e67a169bd5746748209.jpg	cat.jpg	990881	image/jpeg	\N	\N	image	\N	Acorn\\Justice\\Models\\ScannedDocument	t	22	2024-10-27 16:17:37	2024-10-27 16:17:37
10	67189a8801112450785006.jpg	background.jpg	119963	image/jpeg	\N	\N	background_image	1	Backend\\Models\\BrandSetting	t	10	2024-10-23 06:41:12	2024-10-23 06:41:15
45	6720885fdeeb6262831406.jpg	world.jpg	106551	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	45	2024-10-29 07:01:51	2024-10-29 07:01:51
40	671f8b0e8df76165862877.png	translate.png	90146	image/png	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	40	2024-10-28 13:01:02	2024-10-28 13:01:02
12	67189bbe3aa75579314823.png	favicon2.png	27291	image/png	\N	\N	favicon	1	Backend\\Models\\BrandSetting	t	12	2024-10-23 06:46:22	2024-10-23 06:46:24
41	671fd41b9b3dd707844395.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	41	2024-10-28 18:12:43	2024-10-28 18:12:43
23	671e67bb83c5f343380682.jpg	cat.jpg	990881	image/jpeg	\N	\N	image	\N	Acorn\\Justice\\Models\\ScannedDocument	t	23	2024-10-27 16:18:03	2024-10-27 16:18:03
42	671fd430a5f84907822236.jpg	world.jpg	106551	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	42	2024-10-28 18:13:04	2024-10-28 18:13:04
46	672088f95e43a762838987.png	rtl.png	18920	image/png	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	46	2024-10-29 07:04:25	2024-10-29 07:04:25
47	67220d89ae8ba322800654.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	47	2024-10-30 10:42:17	2024-10-30 10:42:17
24	671e68332e8a7622372660.jpg	cat.jpg	990881	image/jpeg	\N	\N	image	\N	Acorn\\Justice\\Models\\ScannedDocument	t	24	2024-10-27 16:20:03	2024-10-27 16:20:03
50	6722363102238000694288.png	crime_type.png	6417	image/png	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	50	2024-10-30 13:35:45	2024-10-30 13:35:45
48	6722355dd5edd689847118.png	transfer.png	5784	image/png	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	48	2024-10-30 13:32:13	2024-10-30 13:32:13
25	671e6a684e676216446254.jpg	cat.jpg	990881	image/jpeg	\N	\N	\N	\N	\N	t	25	2024-10-27 16:29:28	2024-10-27 16:29:28
54	6724e0539571e036876416.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d62a4ce-fd35-4fda-afaf-c76d6dc0a04b	Acorn\\Justice\\Models\\ScannedDocument	t	54	2024-11-01 14:06:11	2024-11-01 14:06:13
51	67238915d1cab238732191.png	logo.png	1853297	image/png	\N	\N	avatar	1	Backend\\Models\\User	t	51	2024-10-31 13:41:41	2024-10-31 13:41:44
19	671a1f05ea0f1601944623.png	logo.png	1853297	image/png	\N	\N	image	9d4aab3a-4f6c-475b-9588-b04e35175d2f	Acorn\\Criminal\\Models\\Legalcase	t	19	2024-10-24 10:18:45	2024-10-24 10:18:45
26	671e6af347cd1920215136.jpg	cat.jpg	990881	image/jpeg	\N	\N	\N	\N	\N	t	26	2024-10-27 16:31:47	2024-10-27 16:31:47
27	671e75c5105e6330182577.jpg	cat.jpg	990881	image/jpeg	\N	\N	document	9d58da7f-dc4f-48a7-bb82-0667aaa076ca	Acorn\\Justice\\Models\\ScannedDocument	t	27	2024-10-27 17:17:57	2024-10-27 17:18:04
53	6723b3aab0c33851058099.png	logo.png	1853297	image/png	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	53	2024-10-31 16:43:22	2024-10-31 16:43:22
28	671e76b191d59947531993.jpg	cat.jpg	990881	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	28	2024-10-27 17:21:53	2024-10-27 17:21:53
55	67286302662fe270142590.png	rtl.png	18920	image/png	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	55	2024-11-04 06:00:34	2024-11-04 06:00:34
29	671e76cc4e706977933285.jpg	cat.jpg	990881	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	29	2024-10-27 17:22:20	2024-10-27 17:22:20
56	672868ce62f8d382453000.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	avatar	2	Backend\\Models\\User	t	56	2024-11-04 06:25:18	2024-11-04 06:25:21
30	671e76e64fc22482794743.jpg	cat.jpg	990881	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	30	2024-10-27 17:22:46	2024-10-27 17:22:46
57	67347d9070caf046849030.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a7820-e037-42f1-8e2a-4abeabddcb13	Acorn\\Justice\\Models\\ScannedDocument	t	57	2024-11-13 10:21:04	2024-11-13 10:21:09
31	671e78a576008043299364.jpg	cat.jpg	990881	image/jpeg	\N	\N	document	9d58dede-2691-4ab7-b3e9-a8f608fe9a4f	Acorn\\Justice\\Models\\ScannedDocument	t	31	2024-10-27 17:30:13	2024-10-27 17:30:17
58	67347dd4b4555597372634.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a788d-0408-4e8d-97b5-da8dd5a0ab73	Acorn\\Justice\\Models\\ScannedDocument	t	58	2024-11-13 10:22:12	2024-11-13 10:22:20
32	671e78b7cdc31145953831.jpg	cat.jpg	990881	image/jpeg	\N	\N	document	\N	Acorn\\Justice\\Models\\ScannedDocument	t	32	2024-10-27 17:30:31	2024-10-27 17:30:31
59	67347e8be6445676279963.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a79a0-3fa2-41b1-9923-f3927189531a	Acorn\\Justice\\Models\\ScannedDocument	t	59	2024-11-13 10:25:15	2024-11-13 10:25:21
60	67347ef68ce3b609635179.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a7a40-60b4-48ca-818d-85cbe2341f36	Acorn\\Justice\\Models\\ScannedDocument	t	60	2024-11-13 10:27:02	2024-11-13 10:27:06
61	673485dbe3a99042604637.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a84c9-38c3-4de0-9c1f-ccea266347e0	Acorn\\Justice\\Models\\ScannedDocument	t	61	2024-11-13 10:56:27	2024-11-13 10:56:33
62	673486cf95173667576419.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a8639-f9cd-4876-9b8c-e0c6d1d041a7	Acorn\\Justice\\Models\\ScannedDocument	t	62	2024-11-13 11:00:31	2024-11-13 11:00:35
77	673edd70bef3d416478586.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d8a4cae-0dc1-48d9-97f6-d6dca0e82ff9	Acorn\\Justice\\Models\\ScannedDocument	t	77	2024-11-21 07:12:48	2024-11-21 07:12:55
63	673487195676a276267396.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a86aa-78a1-4fe6-8a60-0657dfce6b04	Acorn\\Justice\\Models\\ScannedDocument	t	63	2024-11-13 11:01:45	2024-11-13 11:01:48
64	673489bb121c7220763957.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a8aaf-f97c-480e-b072-86a09074f0ee	Acorn\\Justice\\Models\\ScannedDocument	t	64	2024-11-13 11:12:59	2024-11-13 11:13:03
65	67348a4c15405771865257.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a8b92-a801-416e-a3eb-bca47e0250cd	Acorn\\Justice\\Models\\ScannedDocument	t	65	2024-11-13 11:15:24	2024-11-13 11:15:32
78	6740c96f195c9593186790.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d8d3b6e-1131-402f-9955-b7317b4beb4b	Acorn\\Justice\\Models\\ScannedDocument	t	78	2024-11-22 18:11:59	2024-11-22 18:12:10
66	67348b76868ba384275996.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a8d4f-c85b-4630-bcbd-27f7ff3a586a	Acorn\\Justice\\Models\\ScannedDocument	t	66	2024-11-13 11:20:22	2024-11-13 11:20:23
67	67348bdf54edf819637078.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a8df3-e043-4859-9cd4-3f50e446f4d1	Acorn\\Justice\\Models\\ScannedDocument	t	67	2024-11-13 11:22:07	2024-11-13 11:22:11
68	673494ba76e13548051383.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7a9b7b-39e7-48c1-a4d5-080308d08f1b	Acorn\\Justice\\Models\\ScannedDocument	t	68	2024-11-13 11:59:54	2024-11-13 12:00:01
79	6741adbd86c87956650353.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d8e97c3-363b-458b-8f43-664f20234a56	Acorn\\Justice\\Models\\ScannedDocument	t	79	2024-11-23 10:26:05	2024-11-23 10:26:10
69	6735afeba2d9d040851026.png	background.png	462101	image/png	\N	\N	document	9d7c4b98-3077-4f8b-8c3e-b4620ca060d2	Acorn\\Justice\\Models\\ScannedDocument	t	69	2024-11-14 08:08:11	2024-11-14 08:08:17
70	6735cecd90ec8766796006.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7c7ab0-69bb-4ef4-a59c-4152ca7361c8	Acorn\\Justice\\Models\\ScannedDocument	t	70	2024-11-14 10:19:57	2024-11-14 10:19:58
71	6735cee0cd264673106852.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7c7acd-9e73-46cd-a042-9af239ce5181	Acorn\\Justice\\Models\\ScannedDocument	t	71	2024-11-14 10:20:16	2024-11-14 10:20:18
80	67498d8448e24281886961.png	dadgeh.png	136156	image/png	\N	\N	avatar	9d50c308-dcde-415d-b36e-4553ea3f99c9	Acorn\\User\\Models\\User	t	80	2024-11-29 09:46:44	2024-11-29 09:46:47
72	6738925607fe9616883685.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d80b254-cdbe-4060-8611-9727a3abe982	Acorn\\Justice\\Models\\ScannedDocument	t	72	2024-11-16 12:38:46	2024-11-16 12:38:52
73	6739ccc20fac1226497665.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	avatar	2bc29c8f-e9b0-4bd4-8aff-e691b084a255	Acorn\\User\\Models\\User	t	73	2024-11-17 11:00:18	2024-11-17 11:00:20
74	6739de307badb479252604.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	avatar	9d82aca1-b7de-4f82-a65e-b1d0ea0edcc9	Acorn\\User\\Models\\User	t	74	2024-11-17 12:14:40	2024-11-17 12:14:42
81	6750a353648f7282201372.png	67189bbe3aa75579314823.png	27291	image/png	\N	\N	avatar	9d4a94b1-7932-4ec9-8e86-84a9265eff47	Acorn\\User\\Models\\User	t	81	2024-12-04 18:45:39	2024-12-04 18:45:41
75	673ed6f6bf931920353133.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d7c7ab6-1a72-4515-8a4a-9f0df0166324	Acorn\\Justice\\Models\\ScannedDocument	t	75	2024-11-21 06:45:10	2024-11-21 06:45:12
76	673ed7a5de9f1107108467.jpeg	parcel.jpeg	191278	image/jpeg	\N	\N	document	9d8a43d7-c284-4d84-b5f4-13577207a728	Acorn\\Justice\\Models\\ScannedDocument	t	76	2024-11-21 06:48:05	2024-11-21 06:48:12
82	676e6e3e234dd136192115.jpeg	park gates.jpeg	336305	image/jpeg	\N	\N	\N	\N	\N	t	82	2024-12-27 09:07:10	2024-12-27 09:07:10
83	676e820178d8f512635353.jpeg	park gates.jpeg	336305	image/jpeg	\N	\N	image	9dd2ff0e-aedd-47d6-80c6-0105effc416e	Acorn\\Lojistiks\\Models\\Product	t	83	2024-12-27 10:31:29	2024-12-27 10:31:31
84	676e82b0f1f6c263879977.jpeg	park gates.jpeg	336305	image/jpeg	\N	\N	image	9dd3001e-7c18-41e4-8eec-55b4d6494090	Acorn\\Lojistiks\\Models\\Vehicle	t	84	2024-12-27 10:34:24	2024-12-27 10:34:27
85	676e95f76d86c557348634.jpeg	pew pew.jpeg	67236	image/jpeg	\N	\N	document	9dd31d9f-875e-4588-a9e3-8be4a963eb41	Acorn\\Justice\\Models\\ScannedDocument	t	85	2024-12-27 11:56:39	2024-12-27 11:56:46
86	679fbcbfdbccb031522514.png	Screenshot_20250126_104822.png	266674	image/png	\N	\N	document	9e1e1d65-ac22-4bec-9453-b7a045d764ec	Acorn\\Justice\\Models\\ScannedDocument	t	86	2025-02-02 18:43:11	2025-02-02 18:43:14
87	67a1fc50844db286760186.png	Screenshot_20250126_104822.png	266674	image/png	\N	\N	document	9e218bb3-d452-4d6b-ad8b-8988ecf813b8	Acorn\\Justice\\Models\\ScannedDocument	t	87	2025-02-04 11:38:56	2025-02-04 11:39:09
91	67a3a87784a30077021952.png	Screenshot_20250127_122814.png	591126	image/png	\N	\N	document	9e2418f9-7d0d-4513-b1ad-d274015c84d0	Acorn\\Justice\\Models\\ScannedDocument	t	91	2025-02-05 18:05:43	2025-02-05 18:05:50
88	67a205745195a696626352.png	Screenshot_20250129_133506.png	681699	image/png	\N	\N	image	9e219c12-83d5-43f5-a4a8-35a411e4b00d	Acorn\\Lojistiks\\Models\\ProductInstance	t	88	2025-02-04 12:17:56	2025-02-04 12:24:55
89	67a25b918240d268174722.png	Screenshot_20250131_131806.png	580012	image/png	\N	\N	avatar	9e197206-4838-45f3-8714-42a8f029ab5b	Acorn\\User\\Models\\User	t	89	2025-02-04 18:25:21	2025-02-04 18:25:24
90	67a3752dd5f73846185380.png	Screenshot_20250126_104822.png	266674	image/png	\N	\N	\N	\N	\N	t	90	2025-02-05 14:26:53	2025-02-05 14:26:53
92	67adc22e67ac7927120941.png	Screenshot_20250131_131806.png	580012	image/png	\N	\N	document	9e338274-2698-41db-aeac-69394a8036b2	Acorn\\Justice\\Models\\ScannedDocument	t	92	2025-02-13 09:58:06	2025-02-13 09:58:11
94	67af179107b3e598174817.png	Screenshot_20250210_193154.png	241592	image/png	\N	\N	document	9e358b5a-e79d-4eaf-8b9e-7af1162a8a59	Acorn\\Justice\\Models\\ScannedDocument	t	94	2025-02-14 10:14:41	2025-02-14 10:14:44
\.


--
-- Data for Name: system_mail_layouts; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.system_mail_layouts (id, name, code, content_html, content_text, content_css, is_locked, created_at, updated_at, options) FROM stdin;
1	Default layout	default	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml">\n<head>\n    <meta name="viewport" content="width=device-width, initial-scale=1.0" />\n    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />\n    <style type="text/css" media="screen">\n        {{ brandCss|raw }}\n        {{ css|raw }}\n    </style>\n</head>\n<body>\n    <table class="wrapper layout-default" width="100%" cellpadding="0" cellspacing="0">\n\n        <!-- Header -->\n        {% partial 'header' body %}\n            {{ subject|raw }}\n        {% endpartial %}\n\n        <tr>\n            <td align="center">\n                <table class="content" width="100%" cellpadding="0" cellspacing="0">\n                    <!-- Email Body -->\n                    <tr>\n                        <td class="body" width="100%" cellpadding="0" cellspacing="0">\n                            <table class="inner-body" align="center" width="570" cellpadding="0" cellspacing="0">\n                                <!-- Body content -->\n                                <tr>\n                                    <td class="content-cell">\n                                        {{ content|raw }}\n                                    </td>\n                                </tr>\n                            </table>\n                        </td>\n                    </tr>\n                </table>\n            </td>\n        </tr>\n\n        <!-- Footer -->\n        {% partial 'footer' body %}\n            &copy; {{ "now"|date("Y") }} {{ appName }}. All rights reserved.\n        {% endpartial %}\n\n    </table>\n\n</body>\n</html>	{{ content|raw }}	@media only screen and (max-width: 600px) {\n    .inner-body {\n        width: 100% !important;\n    }\n\n    .footer {\n        width: 100% !important;\n    }\n}\n\n@media only screen and (max-width: 500px) {\n    .button {\n        width: 100% !important;\n    }\n}	t	2024-10-19 10:37:18	2024-10-19 10:37:18	\N
2	System layout	system	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml">\n<head>\n    <meta name="viewport" content="width=device-width, initial-scale=1.0" />\n    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />\n    <style type="text/css" media="screen">\n        {{ brandCss|raw }}\n        {{ css|raw }}\n    </style>\n</head>\n<body>\n    <table class="wrapper layout-system" width="100%" cellpadding="0" cellspacing="0">\n        <tr>\n            <td align="center">\n                <table class="content" width="100%" cellpadding="0" cellspacing="0">\n                    <!-- Email Body -->\n                    <tr>\n                        <td class="body" width="100%" cellpadding="0" cellspacing="0">\n                            <table class="inner-body" align="center" width="570" cellpadding="0" cellspacing="0">\n                                <!-- Body content -->\n                                <tr>\n                                    <td class="content-cell">\n                                        {{ content|raw }}\n\n                                        <!-- Subcopy -->\n                                        {% partial 'subcopy' body %}\n                                            **This is an automatic message. Please do not reply to it.**\n                                        {% endpartial %}\n                                    </td>\n                                </tr>\n                            </table>\n                        </td>\n                    </tr>\n                </table>\n            </td>\n        </tr>\n    </table>\n\n</body>\n</html>	{{ content|raw }}\n\n\n---\nThis is an automatic message. Please do not reply to it.	@media only screen and (max-width: 600px) {\n    .inner-body {\n        width: 100% !important;\n    }\n\n    .footer {\n        width: 100% !important;\n    }\n}\n\n@media only screen and (max-width: 500px) {\n    .button {\n        width: 100% !important;\n    }\n}	t	2024-10-19 10:37:18	2024-10-19 10:37:18	\N
\.


--
-- Data for Name: system_mail_partials; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.system_mail_partials (id, name, code, content_html, content_text, is_custom, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_mail_templates; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.system_mail_templates (id, code, subject, description, content_html, content_text, layout_id, is_custom, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_parameters; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.system_parameters (id, namespace, "group", item, value) FROM stdin;
1	system	app	birthday	"2024-10-19T10:37:18.076727Z"
2	system	update	count	0
4	system	core	build	"1.2.6"
5	system	core	modified	true
3	system	update	retry	1739954850
\.


--
-- Data for Name: system_plugin_history; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.system_plugin_history (id, code, type, version, detail, created_at) FROM stdin;
1	Acorn.Rtler	comment	1.0.1	First version of Rtler	2024-10-19 10:37:18
2	Acorn.Rtler	comment	1.0.2	Fix some bug	2024-10-19 10:37:18
3	Acorn.User	script	1.0.1	v1.0.1/create_users_table.php	2024-10-19 10:37:18
4	Acorn.User	script	1.0.1	v1.0.1/create_throttle_table.php	2024-10-19 10:37:18
5	Acorn.User	comment	1.0.1	Initialize plugin.	2024-10-19 10:37:18
6	Acorn.User	comment	1.0.2	Seed tables.	2024-10-19 10:37:18
7	Acorn.User	comment	1.0.3	Translated hard-coded text to language strings.	2024-10-19 10:37:18
8	Acorn.User	comment	1.0.4	Improvements to user-interface for Location manager.	2024-10-19 10:37:18
9	Acorn.User	comment	1.0.5	Added contact details for users.	2024-10-19 10:37:18
10	Acorn.User	script	1.0.6	v1.0.6/create_mail_blockers_table.php	2024-10-19 10:37:18
11	Acorn.User	comment	1.0.6	Added Mail Blocker utility so users can block specific mail templates.	2024-10-19 10:37:18
12	Acorn.User	comment	1.0.7	Add back-end Settings page.	2024-10-19 10:37:18
13	Acorn.User	comment	1.0.8	Updated the Settings page.	2024-10-19 10:37:18
14	Acorn.User	comment	1.0.9	Adds new welcome mail message for users and administrators.	2024-10-19 10:37:18
15	Acorn.User	comment	1.0.10	Adds administrator-only activation mode.	2024-10-19 10:37:18
16	Acorn.User	script	1.0.11	v1.0.11/users_add_login_column.php	2024-10-19 10:37:18
17	Acorn.User	comment	1.0.11	Users now have an optional login field that defaults to the email field.	2024-10-19 10:37:18
18	Acorn.User	script	1.0.12	v1.0.12/users_rename_login_to_username.php	2024-10-19 10:37:18
19	Acorn.User	comment	1.0.12	Create a dedicated setting for choosing the login mode.	2024-10-19 10:37:18
20	Acorn.User	comment	1.0.13	Minor fix to the Account sign in logic.	2024-10-19 10:37:18
21	Acorn.User	comment	1.0.14	Minor improvements to the code.	2024-10-19 10:37:18
22	Acorn.User	script	1.0.15	v1.0.15/users_add_surname.php	2024-10-19 10:37:18
23	Acorn.User	comment	1.0.15	Adds last name column to users table (surname).	2024-10-19 10:37:18
24	Acorn.User	comment	1.0.16	Require permissions for settings page too.	2024-10-19 10:37:18
25	Acorn.User	comment	1.1.0	!!! Profile fields and Locations have been removed.	2024-10-19 10:37:18
26	Acorn.User	script	1.1.1	v1.1.1/create_user_groups_table.php	2024-10-19 10:37:18
27	Acorn.User	script	1.1.1	v1.1.1/seed_user_groups_table.php	2024-10-19 10:37:18
28	Acorn.User	comment	1.1.1	Users can now be added to groups.	2024-10-19 10:37:18
29	Acorn.User	comment	1.1.2	A raw URL can now be passed as the redirect property in the Account component.	2024-10-19 10:37:18
30	Acorn.User	comment	1.1.3	Adds a super user flag to the users table, reserved for future use.	2024-10-19 10:37:18
31	Acorn.User	comment	1.1.4	User list can be filtered by the group they belong to.	2024-10-19 10:37:18
32	Acorn.User	comment	1.1.5	Adds a new permission to hide the User settings menu item.	2024-10-19 10:37:18
33	Acorn.User	script	1.2.0	v1.2.0/users_add_deleted_at.php	2024-10-19 10:37:18
34	Acorn.User	comment	1.2.0	Users can now deactivate their own accounts.	2024-10-19 10:37:18
35	Acorn.User	comment	1.2.1	New feature for checking if a user is recently active/online.	2024-10-19 10:37:18
36	Acorn.User	comment	1.2.2	Add bulk action button to user list.	2024-10-19 10:37:18
37	Acorn.User	comment	1.2.3	Included some descriptive paragraphs in the Reset Password component markup.	2024-10-19 10:37:18
38	Acorn.User	comment	1.2.4	Added a checkbox for blocking all mail sent to the user.	2024-10-19 10:37:18
39	Acorn.User	script	1.2.5	v1.2.5/update_timestamp_nullable.php	2024-10-19 10:37:18
40	Acorn.User	comment	1.2.5	Database maintenance. Updated all timestamp columns to be nullable.	2024-10-19 10:37:18
41	Acorn.User	script	1.2.6	v1.2.6/users_add_last_seen.php	2024-10-19 10:37:18
42	Acorn.User	comment	1.2.6	Add a dedicated last seen column for users.	2024-10-19 10:37:18
43	Acorn.User	comment	1.2.7	Minor fix to user timestamp attributes.	2024-10-19 10:37:18
44	Acorn.User	comment	1.2.8	Add date range filter to users list. Introduced a logout event.	2024-10-19 10:37:18
45	Acorn.User	comment	1.2.9	Add invitation mail for new accounts created in the back-end.	2024-10-19 10:37:18
46	Acorn.User	script	1.3.0	v1.3.0/users_add_guest_flag.php	2024-10-19 10:37:18
47	Acorn.User	script	1.3.0	v1.3.0/users_add_superuser_flag.php	2024-10-19 10:37:18
48	Acorn.User	comment	1.3.0	Introduced guest user accounts.	2024-10-19 10:37:18
49	Acorn.User	comment	1.3.1	User notification variables can now be extended.	2024-10-19 10:37:18
50	Acorn.User	comment	1.3.2	Minor fix to the Auth::register method.	2024-10-19 10:37:18
51	Acorn.User	comment	1.3.3	Allow prevention of concurrent user sessions via the user settings.	2024-10-19 10:37:18
52	Acorn.User	comment	1.3.4	Added force secure protocol property to the account component.	2024-10-19 10:37:18
53	Acorn.User	comment	1.4.0	!!! The Notifications tab in User settings has been removed.	2024-10-19 10:37:18
54	Acorn.User	comment	1.4.1	Added support for user impersonation.	2024-10-19 10:37:18
55	Acorn.User	comment	1.4.2	Fixes security bug in Password Reset component.	2024-10-19 10:37:18
56	Acorn.User	comment	1.4.3	Fixes session handling for AJAX requests.	2024-10-19 10:37:18
57	Acorn.User	comment	1.4.4	Fixes bug where impersonation touches the last seen timestamp.	2024-10-19 10:37:18
58	Acorn.User	comment	1.4.5	Added token fallback process to Account / Reset Password components when parameter is missing.	2024-10-19 10:37:18
59	Acorn.User	comment	1.4.6	Fixes Auth::register method signature mismatch with core Winter CMS Auth library	2024-10-19 10:37:18
60	Acorn.User	comment	1.4.7	Fixes redirect bug in Account component / Update translations and separate user and group management.	2024-10-19 10:37:18
61	Acorn.User	comment	1.4.8	Fixes a bug where calling MailBlocker::removeBlock could remove all mail blocks for the user.	2024-10-19 10:37:18
62	Acorn.User	comment	1.5.0	!!! Required password length is now a minimum of 8 characters. Previous passwords will not be affected until the next password change.	2024-10-19 10:37:18
63	Acorn.User	script	1.5.1	v1.5.1/users_add_ip_address.php	2024-10-19 10:37:18
64	Acorn.User	comment	1.5.1	User IP addresses are now logged. Introduce registration throttle.	2024-10-19 10:37:18
65	Acorn.User	comment	1.5.2	Whitespace from usernames is now trimmed, allowed for username to be added to Reset Password mail templates.	2024-10-19 10:37:18
66	Acorn.User	comment	1.5.3	Fixes a bug in the user update functionality if password is not changed. Added highlighting for banned users in user list.	2024-10-19 10:37:18
67	Acorn.User	comment	1.5.4	Multiple translation improvements. Added view events to extend user preview and user listing toolbars.	2024-10-19 10:37:18
68	Acorn.User	script	2.0.0	v2.0.0/rename_tables.php	2024-10-19 10:37:18
69	Acorn.User	comment	2.0.0	Rebrand to Acorn.User	2024-10-19 10:37:18
70	Acorn.User	comment	2.0.0	Update Russian language	2024-10-19 10:37:18
71	Acorn.User	script	2.0.1	v2.0.1/rename_indexes.php	2024-10-19 10:37:18
72	Acorn.User	comment	2.0.1	Rebrand table indexes	2024-10-19 10:37:18
73	Acorn.User	comment	2.1.0	Enforce password length rules on sign in. Compatibility fixes.	2024-10-19 10:37:18
74	Acorn.User	comment	2.2.0	Add avatar removal. Password resets will activate users if User activation mode is enabled.	2024-10-19 10:37:18
75	Acorn.User	comment	2.2.1	Fixes a bug introduced by the adoption of symfony/mime required since Laravel 7.x where sending an email to a blocked email address would not be prevented.	2024-10-19 10:37:18
76	Acorn.User	comment	2.2.2	Improved French translation, updated plugin icons, fixed migrations for Laravel 9	2024-10-19 10:37:18
77	Acorn.User	script	3.0.0	v3.0.0/create_user_roles_table.php	2024-10-19 10:37:18
78	Acorn.User	script	3.0.0	v3.0.0/add_backend_user_column.php	2024-10-19 10:37:18
79	Acorn.User	comment	3.0.0	User Roles	2024-10-19 10:37:18
80	Acorn.User	comment	3.0.0	Add Backend User column	2024-10-19 10:37:18
81	Winter.Demo	comment	1.0.1	First version of Demo	2024-10-19 10:37:18
82	Winter.Location	comment	1.0.1	Initialize plugin.	2024-10-19 10:37:18
83	Winter.Location	script	1.0.2	v1.0.2/create_states_table.php	2024-10-19 10:37:18
84	Winter.Location	script	1.0.2	v1.0.2/create_countries_table.php	2024-10-19 10:37:18
85	Winter.Location	comment	1.0.2	Create database tables.	2024-10-19 10:37:18
86	Winter.Location	script	1.0.3	v1.0.3/seed_all_tables.php	2024-10-19 10:37:19
87	Winter.Location	comment	1.0.3	Add seed data for countries and states.	2024-10-19 10:37:19
88	Winter.Location	comment	1.0.4	Satisfy the new Google API key requirement.	2024-10-19 10:37:19
89	Winter.Location	script	1.0.5	v1.0.5/add_country_pinned_flag.php	2024-10-19 10:37:19
90	Winter.Location	comment	1.0.5	Countries can now be pinned to make them appear at the top of the list.	2024-10-19 10:37:19
91	Winter.Location	comment	1.0.6	Added support for defining a default country and state.	2024-10-19 10:37:19
92	Winter.Location	comment	1.0.7	Added basic geocoding method to the Country model.	2024-10-19 10:37:19
93	Winter.Location	comment	1.0.8	Include Mexico states	2024-10-19 10:37:19
94	Winter.Location	comment	1.1.0	!!! Update requires Build 447. Fixed AddressFinder formwidget not working correctly in repeaters.	2024-10-19 10:37:19
95	Winter.Location	comment	1.1.1	Minor fix to AddressFinder formwidget for the change to the FormField API	2024-10-19 10:37:19
96	Winter.Location	comment	1.1.2	Yet another change to the AddressFinder for changes to the FormField API	2024-10-19 10:37:19
97	Winter.Location	script	1.1.3	v1.1.3/seed_ar_states.php	2024-10-19 10:37:19
98	Winter.Location	comment	1.1.3	Include Argentina states	2024-10-19 10:37:19
99	Winter.Location	comment	1.1.4	Added support for UK counties	2024-10-19 10:37:19
100	Winter.Location	script	1.1.5	v1.1.5/seed_it_states.php	2024-10-19 10:37:19
101	Winter.Location	comment	1.1.5	Include Italian states (province)	2024-10-19 10:37:19
102	Winter.Location	script	1.1.6	v1.1.6/add_enabled_states.php	2024-10-19 10:37:19
103	Winter.Location	comment	1.1.6	Added ability to disable specific states	2024-10-19 10:37:19
104	Winter.Location	script	2.0.0	v2.0.0/rename_tables.php	2024-10-19 10:37:19
105	Winter.Location	comment	2.0.0	Rebrand to Winter.location	2024-10-19 10:37:19
106	Winter.Location	script	2.0.1	v2.0.1/rename_indexes.php	2024-10-19 10:37:19
107	Winter.Location	script	2.0.1	v2.0.1/fix_translate_records.php	2024-10-19 10:37:19
108	Winter.Location	comment	2.0.1	Rebrand table indexes	2024-10-19 10:37:19
109	Winter.Location	comment	2.0.1	Add migrations for translate plugin attributes and indexes tables	2024-10-19 10:37:19
110	Winter.Location	script	2.0.2	v2.0.2/seed_ru_states.php	2024-10-19 10:37:19
111	Winter.Location	comment	2.0.2	Include Russian states (subjects)	2024-10-19 10:37:19
112	Winter.TailwindUI	comment	1.0.1	First version of TailwindUI	2024-10-19 10:37:19
113	Winter.Translate	script	1.0.1	v1.0.1/create_messages_table.php	2024-10-19 10:37:19
114	Winter.Translate	script	1.0.1	v1.0.1/create_attributes_table.php	2024-10-19 10:37:19
115	Winter.Translate	script	1.0.1	v1.0.1/create_locales_table.php	2024-10-19 10:37:19
116	Winter.Translate	comment	1.0.1	First version of Translate	2024-10-19 10:37:19
117	Winter.Translate	comment	1.0.2	Languages and Messages can now be deleted.	2024-10-19 10:37:19
118	Winter.Translate	comment	1.0.3	Minor updates for latest Winter CMS release.	2024-10-19 10:37:19
119	Winter.Translate	comment	1.0.4	Locale cache will clear when updating a language.	2024-10-19 10:37:19
120	Winter.Translate	comment	1.0.5	Add Spanish language and fix plugin config.	2024-10-19 10:37:19
121	Winter.Translate	comment	1.0.6	Minor improvements to the code.	2024-10-19 10:37:19
122	Winter.Translate	comment	1.0.7	Fixes major bug where translations are skipped entirely!	2024-10-19 10:37:19
123	Winter.Translate	comment	1.0.8	Minor bug fixes.	2024-10-19 10:37:19
124	Winter.Translate	comment	1.0.9	Fixes an issue where newly created models lose their translated values.	2024-10-19 10:37:19
125	Winter.Translate	comment	1.0.10	Minor fix for latest build.	2024-10-19 10:37:19
126	Winter.Translate	comment	1.0.11	Fix multilingual rich editor when used in stretch mode.	2024-10-19 10:37:19
127	Winter.Translate	comment	1.1.0	Introduce compatibility with Winter.Pages plugin.	2024-10-19 10:37:19
128	Winter.Translate	comment	1.1.1	Minor UI fix to the language picker.	2024-10-19 10:37:19
129	Winter.Translate	comment	1.1.2	Add support for translating Static Content files.	2024-10-19 10:37:19
130	Winter.Translate	comment	1.1.3	Improved support for the multilingual rich editor.	2024-10-19 10:37:19
131	Winter.Translate	comment	1.1.4	Adds new multilingual markdown editor.	2024-10-19 10:37:19
132	Winter.Translate	comment	1.1.5	Minor update to the multilingual control API.	2024-10-19 10:37:19
133	Winter.Translate	comment	1.1.6	Minor improvements in the message editor.	2024-10-19 10:37:19
134	Winter.Translate	comment	1.1.7	Fixes bug not showing content when first loading multilingual textarea controls.	2024-10-19 10:37:19
135	Winter.Translate	comment	1.2.0	CMS pages now support translating the URL.	2024-10-19 10:37:19
136	Winter.Translate	comment	1.2.1	Minor update in the rich editor and code editor language control position.	2024-10-19 10:37:19
137	Winter.Translate	comment	1.2.2	Static Pages now support translating the URL.	2024-10-19 10:37:19
138	Winter.Translate	comment	1.2.3	Fixes Rich Editor when inserting a page link.	2024-10-19 10:37:19
139	Winter.Translate	script	1.2.4	v1.2.4/create_indexes_table.php	2024-10-19 10:37:19
140	Winter.Translate	comment	1.2.4	Translatable attributes can now be declared as indexes.	2024-10-19 10:37:19
141	Winter.Translate	comment	1.2.5	Adds new multilingual repeater form widget.	2024-10-19 10:37:19
142	Winter.Translate	comment	1.2.6	Fixes repeater usage with static pages plugin.	2024-10-19 10:37:19
143	Winter.Translate	comment	1.2.7	Fixes placeholder usage with static pages plugin.	2024-10-19 10:37:19
144	Winter.Translate	comment	1.2.8	Improvements to code for latest Winter CMS build compatibility.	2024-10-19 10:37:19
145	Winter.Translate	comment	1.2.9	Fixes context for translated strings when used with Static Pages.	2024-10-19 10:37:19
146	Winter.Translate	comment	1.2.10	Minor UI fix to the multilingual repeater.	2024-10-19 10:37:19
147	Winter.Translate	comment	1.2.11	Fixes translation not working with partials loaded via AJAX.	2024-10-19 10:37:19
148	Winter.Translate	comment	1.2.12	Add support for translating the new grouped repeater feature.	2024-10-19 10:37:19
149	Winter.Translate	comment	1.3.0	Added search to the translate messages page.	2024-10-19 10:37:19
150	Winter.Translate	script	1.3.1	v1.3.1/add_sort_order.php	2024-10-19 10:37:19
151	Winter.Translate	script	1.3.1	v1.3.1/seed_all_tables.php	2024-10-19 10:37:19
152	Winter.Translate	comment	1.3.1	Added reordering to languages	2024-10-19 10:37:19
153	Winter.Translate	comment	1.3.2	Improved compatibility with Winter.Pages, added ability to scan Mail Messages for translatable variables.	2024-10-19 10:37:19
154	Winter.Translate	comment	1.3.3	Fix to the locale picker session handling in Build 420 onwards.	2024-10-19 10:37:19
155	Winter.Translate	comment	1.3.4	Add alternate hreflang elements and adds prefixDefaultLocale setting.	2024-10-19 10:37:19
156	Winter.Translate	comment	1.3.5	Fix MLRepeater bug when switching locales.	2024-10-19 10:37:19
157	Winter.Translate	comment	1.3.6	Fix Middleware to use the prefixDefaultLocale setting introduced in 1.3.4	2024-10-19 10:37:19
158	Winter.Translate	comment	1.3.7	Fix config reference in LocaleMiddleware	2024-10-19 10:37:19
159	Winter.Translate	comment	1.3.8	Keep query string when switching locales	2024-10-19 10:37:19
160	Winter.Translate	comment	1.4.0	Add importer and exporter for messages	2024-10-19 10:37:19
161	Winter.Translate	comment	1.4.1	Updated Hungarian translation. Added Arabic translation. Fixed issue where default texts are overwritten by import. Fixed issue where the language switcher for repeater fields would overlap with the first repeater row.	2024-10-19 10:37:19
162	Winter.Translate	comment	1.4.2	Add multilingual MediaFinder	2024-10-19 10:37:19
163	Winter.Translate	comment	1.4.3	!!! Please update Winter CMS to Build 444 before updating this plugin. Added ability to translate CMS Pages fields (e.g. title, description, meta-title, meta-description)	2024-10-19 10:37:19
164	Winter.Translate	comment	1.4.4	Minor improvements to compatibility with Laravel framework.	2024-10-19 10:37:19
165	Winter.Translate	comment	1.4.5	Fixed issue when using the language switcher	2024-10-19 10:37:19
166	Winter.Translate	comment	1.5.0	Compatibility fix with Build 451	2024-10-19 10:37:19
167	Winter.Translate	comment	1.6.0	Make File Upload widget properties translatable. Merge Repeater core changes into MLRepeater widget. Add getter method to retrieve original translate data.	2024-10-19 10:37:19
168	Winter.Translate	comment	1.6.1	Add ability for models to provide translated computed data, add option to disable locale prefix routing	2024-10-19 10:37:19
169	Winter.Translate	comment	1.6.2	Implement localeUrl filter, add per-locale theme configuration support	2024-10-19 10:37:19
170	Winter.Translate	comment	1.6.3	Add eager loading for translations, restore support for accessors & mutators	2024-10-19 10:37:19
171	Winter.Translate	comment	1.6.4	Fixes PHP 7.4 compatibility	2024-10-19 10:37:19
172	Winter.Translate	comment	1.6.5	Fixes compatibility issue when other plugins use a custom model morph map	2024-10-19 10:37:19
173	Winter.Translate	script	1.6.6	v1.6.6/migrate_morphed_attributes.php	2024-10-19 10:37:19
174	Winter.Translate	comment	1.6.6	Introduce migration to patch existing translations using morph map	2024-10-19 10:37:19
175	Winter.Translate	script	1.6.7	v1.6.7/migrate_morphed_indexes.php	2024-10-19 10:37:19
176	Winter.Translate	comment	1.6.7	Introduce migration to patch existing indexes using morph map	2024-10-19 10:37:19
177	Winter.Translate	comment	1.6.8	Add support for transOrderBy; Add translation support for ThemeData; Update russian localization.	2024-10-19 10:37:19
178	Winter.Translate	comment	1.6.9	Clear Static Page menu cache after saving the model; CSS fix for Text/Textarea input fields language selector.	2024-10-19 10:37:19
179	Winter.Translate	script	1.6.10	v1.6.10/update_messages_table.php	2024-10-19 10:37:19
180	Winter.Translate	comment	1.6.10	Add option to purge deleted messages when scanning messages	2024-10-19 10:37:19
181	Winter.Translate	comment	1.6.10	Add Scan error column on Messages page	2024-10-19 10:37:19
182	Winter.Translate	comment	1.6.10	Fix translations that were lost when clicking locale twice while holding ctrl key	2024-10-19 10:37:19
183	Winter.Translate	comment	1.6.10	Fix error with nested fields default locale value	2024-10-19 10:37:19
184	Winter.Translate	comment	1.6.10	Escape Message translate params value	2024-10-19 10:37:19
185	Winter.Translate	comment	1.7.0	!!! Breaking change for the Message::trans() method (params are now escaped)	2024-10-19 10:37:19
186	Winter.Translate	comment	1.7.0	fix message translation documentation	2024-10-19 10:37:19
187	Winter.Translate	comment	1.7.0	fix string translation key for scan errors column header	2024-10-19 10:37:19
188	Winter.Translate	comment	1.7.1	Fix YAML issue with previous tag/release.	2024-10-19 10:37:19
189	Winter.Translate	comment	1.7.2	Fix regex when "|_" filter is followed by another filter	2024-10-19 10:37:19
190	Winter.Translate	comment	1.7.2	Try locale without country before returning default translation	2024-10-19 10:37:19
191	Winter.Translate	comment	1.7.2	Allow exporting default locale	2024-10-19 10:37:19
192	Winter.Translate	comment	1.7.2	Fire 'winter.translate.themeScanner.afterScan' event in the theme scanner for extendability	2024-10-19 10:37:19
193	Winter.Translate	comment	1.7.3	Make plugin ready for Laravel 6 update	2024-10-19 10:37:19
194	Winter.Translate	comment	1.7.3	Add support for translating Winter.Pages MenuItem properties (requires Winter.Pages v1.3.6)	2024-10-19 10:37:19
195	Winter.Translate	comment	1.7.3	Restore multilingual button position for textarea	2024-10-19 10:37:19
196	Winter.Translate	comment	1.7.3	Fix translatableAttributes	2024-10-19 10:37:19
197	Winter.Translate	comment	1.7.4	Faster version of transWhere	2024-10-19 10:37:19
198	Winter.Translate	comment	1.7.4	Mail templates/views can now be localized	2024-10-19 10:37:19
199	Winter.Translate	comment	1.7.4	Fix messages table layout on mobile	2024-10-19 10:37:19
200	Winter.Translate	comment	1.7.4	Fix scopeTransOrderBy duplicates	2024-10-19 10:37:19
201	Winter.Translate	comment	1.7.4	Polish localization updates	2024-10-19 10:37:19
202	Winter.Translate	comment	1.7.4	Turkish localization updates	2024-10-19 10:37:19
203	Winter.Translate	comment	1.7.4	Add Greek language localization	2024-10-19 10:37:19
204	Winter.Translate	comment	1.8.0	Adds initial support for October v2.0	2024-10-19 10:37:19
205	Winter.Translate	comment	1.8.1	Minor bugfix	2024-10-19 10:37:19
206	Winter.Translate	comment	1.8.2	Fixes translated file models and theme data for v2.0. The parent model must implement translatable behavior for their related file models to be translated.	2024-10-19 10:37:19
207	Winter.Translate	script	2.0.0	v2.0.0/rename_tables.php	2024-10-19 10:37:19
208	Winter.Translate	comment	2.0.0	Rebrand to Winter.Translate	2024-10-19 10:37:19
209	Winter.Translate	comment	2.0.0	Fix location for dropdown-to in css file	2024-10-19 10:37:19
210	Winter.Translate	script	2.0.1	v2.0.1/rename_indexes.php	2024-10-19 10:37:19
211	Winter.Translate	comment	2.0.1	Rebrand table indexes	2024-10-19 10:37:19
212	Winter.Translate	comment	2.0.1	Remove deprecated methods (setTranslateAttribute/getTranslateAttribute)	2024-10-19 10:37:19
213	Winter.Translate	comment	2.0.2	Added Latvian translation. Fixed plugin replacement issues.	2024-10-19 10:37:19
214	Winter.Translate	script	2.1.0	v2.1.0/migrate_message_code.php	2024-10-19 10:37:19
215	Winter.Translate	comment	2.1.0	!!! Potential breaking change: Message codes are now MD5 hashed versions of the original string. See https://github.com/wintercms/wn-translate-plugin/pull/2	2024-10-19 10:37:19
216	Winter.Translate	comment	2.1.1	Added support for Winter CMS 1.2.	2024-10-19 10:37:19
217	Winter.Translate	comment	2.1.2	Add Vietnamese translations	2024-10-19 10:37:19
218	Winter.Translate	comment	2.1.2	Add composer replace config.	2024-10-19 10:37:19
219	Winter.Translate	comment	2.1.2	Add MultiLang capability to Winter.Sitemap.	2024-10-19 10:37:19
220	Winter.Translate	comment	2.1.2	Add addTranslatableAttributes() method to TranslatableBehavior.	2024-10-19 10:37:19
221	Winter.Translate	comment	2.1.2	Fix dynamically adding fields to non-existent tab.	2024-10-19 10:37:19
222	Winter.Translate	comment	2.1.2	Fix translations conflicting between nested fields and translatable root fields of the same name.	2024-10-19 10:37:19
223	Winter.Translate	comment	2.1.3	Fixed issue with translatable models	2024-10-19 10:37:19
224	Winter.Translate	comment	2.1.4	Fixed issue with broken imports in the backend Locales controller.	2024-10-19 10:37:19
225	Winter.Translate	comment	2.1.5	Add support for translatable nested forms	2024-10-19 10:37:19
226	Winter.Translate	comment	2.1.5	Add validation for translated string	2024-10-19 10:37:19
227	Winter.Translate	comment	2.1.5	Add setTranslatableUseFallback() / deprecate noFallbackLocale()	2024-10-19 10:37:19
228	Winter.Translate	comment	2.1.5	Only extend cms page if cms module is enabled	2024-10-19 10:37:19
229	Winter.Translate	comment	2.1.5	Prevent browser autofill for hidden locale inputs	2024-10-19 10:37:19
230	Winter.Translate	comment	2.1.5	System MailTemplate model is now translatable	2024-10-19 10:37:19
231	Winter.Translate	comment	2.1.5	Make fields using @context translatable	2024-10-19 10:37:19
232	Winter.Translate	comment	2.1.6	Improve ML button styling	2024-10-19 10:37:19
233	Winter.Translate	comment	2.1.6	Fix TranslatableBehavior::lang method signature	2024-10-19 10:37:19
234	Acorn.BackendLocalization	script	1.0.0	v1.1/seed_locale_backend.php	2024-10-19 10:37:19
235	Acorn.BackendLocalization	comment	1.0.0	Create special languages ​​for the backend 	2024-10-19 10:37:19
236	Acorn.Location	script	4.0.0	create_from_sql.php	2024-10-19 10:37:23
237	Acorn.Location	comment	4.0.0	Create from DB & seeder.sql	2024-10-19 10:37:23
238	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message.php	2024-10-19 10:37:23
239	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message_user.php	2024-10-19 10:37:23
240	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message_user_group.php	2024-10-19 10:37:23
241	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message_message.php	2024-10-19 10:37:23
242	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_action.php	2024-10-19 10:37:23
243	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_label.php	2024-10-19 10:37:23
244	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_status.php	2024-10-19 10:37:23
245	Acorn.Messaging	script	1.0.1	seed_status.php	2024-10-19 10:37:23
246	Acorn.Messaging	comment	1.0.1	Initialize plugin.	2024-10-19 10:37:23
247	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message	2024-10-19 10:37:23
248	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message_user	2024-10-19 10:37:23
249	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message_user_group	2024-10-19 10:37:23
250	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message_message	2024-10-19 10:37:23
251	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_action	2024-10-19 10:37:23
252	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_label	2024-10-19 10:37:23
253	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_status	2024-10-19 10:37:23
254	Acorn.Messaging	comment	1.0.1	Seeding message status	2024-10-19 10:37:23
255	Acorn.Messaging	script	2.0.0	create_acorn_users_extra_fields.php	2024-10-19 10:37:23
256	Acorn.Messaging	comment	2.0.0	Create acorn users extra fields	2024-10-19 10:37:23
257	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar.php	2024-10-19 10:37:23
258	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_type.php	2024-10-19 10:37:23
259	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_status.php	2024-10-19 10:37:23
260	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event.php	2024-10-19 10:37:23
261	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_part.php	2024-10-19 10:37:23
262	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_instance.php	2024-10-19 10:37:23
263	Acorn.Calendar	script	2.0.1	create_acorn_calendar_event_trigger.php	2024-10-19 10:37:23
264	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_user.php	2024-10-19 10:37:23
265	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_user_group.php	2024-10-19 10:37:23
266	Acorn.Calendar	script	2.0.1	table_create_acorn_messaging_instance.php	2024-10-19 10:37:23
267	Acorn.Calendar	script	2.0.1	seed_type_status.php	2024-10-19 10:37:23
268	Acorn.Calendar	script	2.0.1	seed_calendar.php	2024-10-19 10:37:23
269	Acorn.Calendar	comment	2.0.1	Initialize plugin.	2024-10-19 10:37:23
270	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar	2024-10-19 10:37:23
271	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_type	2024-10-19 10:37:23
272	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_status	2024-10-19 10:37:23
273	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event	2024-10-19 10:37:23
274	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_part	2024-10-19 10:37:23
275	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_instance	2024-10-19 10:37:23
276	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_trigger	2024-10-19 10:37:23
277	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_user	2024-10-19 10:37:23
278	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_usergroup	2024-10-19 10:37:23
279	Acorn.Calendar	comment	2.0.1	Created table acorn_messaging_message_instance	2024-10-19 10:37:23
280	Acorn.Calendar	comment	2.0.1	Seeding Type and Status defaults	2024-10-19 10:37:23
281	Acorn.Calendar	comment	2.0.1	Seeding default Calendar	2024-10-19 10:37:23
282	Acorn.Calendar	script	3.0.0	create_acorn_users_extra_fields.php	2024-10-19 10:37:23
283	Acorn.Calendar	comment	3.0.0	create_acorn_users_extra_fields	2024-10-19 10:37:23
284	Acorn.Justice	script	4.0.0	create_from_sql.php	2024-10-19 10:37:23
285	Acorn.Justice	comment	4.0.0	Create from DB & seeder.sql	2024-10-19 10:37:23
286	Acorn.Civil	script	4.0.0	create_from_sql.php	2024-10-19 10:37:23
287	Acorn.Civil	comment	4.0.0	Create from DB & seeder.sql	2024-10-19 10:37:23
288	Acorn.Criminal	script	4.0.0	create_from_sql.php	2024-10-19 10:37:23
289	Acorn.Criminal	comment	4.0.0	Create from DB & seeder.sql	2024-10-19 10:37:23
290	Acorn.Houseofpeace	script	4.0.0	create_from_sql.php	2024-10-19 10:37:23
291	Acorn.Houseofpeace	comment	4.0.0	Create from DB & seeder.sql	2024-10-19 10:37:23
292	Acorn.Lojistiks	auto-registration	1.0.0	acorn-create-system	\N
\.


--
-- Data for Name: system_plugin_versions; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.system_plugin_versions (id, code, version, created_at, is_disabled, is_frozen, acorn_infrastructure) FROM stdin;
1	Acorn.Rtler	1.0.2	2024-10-19 10:37:18	f	f	f
14	Acorn.Houseofpeace	4.0.0	2024-10-19 10:37:23	t	f	f
12	Acorn.Civil	4.0.0	2024-10-19 10:37:23	t	f	f
16	Acorn.University	1.0.0	2024-12-05 09:57:00	t	f	f
13	Acorn.Criminal	4.0.0	2024-10-19 10:37:23	f	f	f
2	Acorn.User	3.0.0	2024-10-19 10:37:18	f	f	f
3	Winter.Demo	1.0.1	2024-10-19 10:37:18	f	f	f
6	Winter.Translate	2.1.6	2024-10-19 10:37:19	f	f	f
7	Acorn.BackendLocalization	1.0.0	2024-10-19 10:37:19	f	f	f
8	Acorn.Location	4.0.0	2024-10-19 10:37:23	f	f	f
9	Acorn.Messaging	2.0.0	2024-10-19 10:37:23	f	f	f
10	Acorn.Calendar	3.0.0	2024-10-19 10:37:23	f	f	f
11	Acorn.Justice	4.0.0	2024-10-19 10:37:23	f	f	f
4	Winter.Location	2.0.2	2024-10-19 10:37:19	f	f	f
5	Winter.TailwindUI	1.0.1	2024-10-19 10:37:19	f	f	f
15	Acorn.Lojistiks	1.0.0	2024-12-05 09:55:56	f	f	f
17	Acorn.Finance	1.0.0	2024-12-05 09:57:18	f	f	t
\.


--
-- Data for Name: system_request_logs; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.system_request_logs (id, status_code, url, referer, count, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_revisions; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.system_revisions (id, user_id, field, "cast", old_value, new_value, revisionable_type, revisionable_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.system_settings (id, item, value) FROM stdin;
1	backend_brand_settings	{"app_name":"Justice","app_tagline":"Peace & Love","primary_color":"#34495E","secondary_color":"#E67E22","accent_color":"#3498DB","default_colors":[{"color":"#1ABC9C"},{"color":"#16A085"},{"color":"#2ECC71"},{"color":"#27AE60"},{"color":"#3498DB"},{"color":"#2980B9"},{"color":"#9B59B6"},{"color":"#8E44AD"},{"color":"#34495E"},{"color":"#2B3E50"},{"color":"#F1C40F"},{"color":"#F39C12"},{"color":"#E67E22"},{"color":"#D35400"},{"color":"#E74C3C"},{"color":"#C0392B"},{"color":"#ECF0F1"},{"color":"#BDC3C7"},{"color":"#95A5A6"},{"color":"#7F8C8D"}],"menu_mode":"inline","auth_layout":"split","menu_location":"top","icon_location":"inline","custom_css":""}
2	acorn_rtler	{"layout_mode":"never","editor_mode":"language","markdown_editor_mode":"language"}
3	user_settings	{"require_activation":"0","activate_mode":"auto","use_throttle":"0","block_persistence":"0","allow_registration":"0","login_attribute":"email","remember_login":"always","use_register_throttle":"0","has_front_end":"0"}
4	acorn_calendar_settings	{"days_before":"1 year","days_after":"1 year","default_event_time_from":"2024-11-12 09:00:00","default_event_time_to":"2024-11-12 10:00:00","default_time_zone":"AD","daylight_savings":"1"}
\.


--
-- Data for Name: winter_location_countries; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.winter_location_countries (id, is_enabled, name, code, is_pinned) FROM stdin;
5	f	Afghanistan	AF	f
6	f	Aland Islands 	AX	f
7	f	Albania	AL	f
8	f	Algeria	DZ	f
9	f	American Samoa	AS	f
10	f	Andorra	AD	f
11	f	Angola	AO	f
12	f	Anguilla	AI	f
13	f	Antarctica	AQ	f
14	f	Antigua and Barbuda	AG	f
15	f	Argentina	AR	f
16	f	Armenia	AM	f
17	f	Aruba	AW	f
18	f	Austria	AT	f
19	f	Azerbaijan	AZ	f
20	f	Bahamas	BS	f
21	f	Bahrain	BH	f
22	f	Bangladesh	BD	f
23	f	Barbados	BB	f
24	f	Belarus	BY	f
25	f	Belgium	BE	f
26	f	Belize	BZ	f
27	f	Benin	BJ	f
28	f	Bermuda	BM	f
29	f	Bhutan	BT	f
30	f	Bolivia, Plurinational State of	BO	f
31	f	Bonaire, Sint Eustatius and Saba	BQ	f
32	f	Bosnia and Herzegovina	BA	f
33	f	Botswana	BW	f
34	f	Bouvet Island	BV	f
35	f	Brazil	BR	f
36	f	British Indian Ocean Territory	IO	f
37	f	Brunei Darussalam	BN	f
38	f	Bulgaria	BG	f
39	f	Burkina Faso	BF	f
40	f	Burundi	BI	f
41	f	Cambodia	KH	f
42	f	Cameroon	CM	f
43	f	Cape Verde	CV	f
44	f	Cayman Islands	KY	f
45	f	Central African Republic	CF	f
46	f	Chad	TD	f
47	f	Chile	CL	f
48	f	China	CN	f
49	f	Christmas Island	CX	f
50	f	Cocos (Keeling) Islands	CC	f
51	f	Colombia	CO	f
52	f	Comoros	KM	f
53	f	Congo	CG	f
54	f	Congo, the Democratic Republic of the	CD	f
55	f	Cook Islands	CK	f
56	f	Costa Rica	CR	f
57	f	Cote d'Ivoire	CI	f
58	f	Croatia	HR	f
59	f	Cuba	CU	f
60	f	Curaçao	CW	f
61	f	Cyprus	CY	f
62	f	Czech Republic	CZ	f
63	f	Denmark	DK	f
64	f	Djibouti	DJ	f
65	f	Dominica	DM	f
66	f	Dominican Republic	DO	f
67	f	Ecuador	EC	f
68	f	Egypt	EG	f
69	f	El Salvador	SV	f
70	f	Equatorial Guinea	GQ	f
71	f	Eritrea	ER	f
72	f	Estonia	EE	f
73	f	Ethiopia	ET	f
74	f	Falkland Islands (Malvinas)	FK	f
75	f	Faroe Islands	FO	f
76	f	Finland	FI	f
77	f	Fiji	FJ	f
78	t	France	FR	f
79	f	French Guiana	GF	f
80	f	French Polynesia	PF	f
81	f	French Southern Territories	TF	f
82	f	Gabon	GA	f
83	f	Gambia	GM	f
84	f	Georgia	GE	f
85	f	Germany	DE	f
86	f	Ghana	GH	f
87	f	Gibraltar	GI	f
88	f	Greece	GR	f
89	f	Greenland	GL	f
90	f	Grenada	GD	f
91	f	Guadeloupe	GP	f
92	f	Guam	GU	f
93	f	Guatemala	GT	f
94	f	Guernsey	GG	f
95	f	Guinea	GN	f
96	f	Guinea-Bissau	GW	f
97	f	Guyana	GY	f
98	f	Haiti	HT	f
99	f	Heard Island and McDonald Islands	HM	f
100	f	Holy See (Vatican City State)	VA	f
101	f	Honduras	HN	f
102	f	Hong Kong	HK	f
103	t	Hungary	HU	f
104	f	Iceland	IS	f
105	t	India	IN	f
106	f	Indonesia	ID	f
107	f	Iran, Islamic Republic of	IR	f
108	f	Iraq	IQ	f
109	t	Ireland	IE	f
110	f	Isle of Man	IM	f
111	f	Israel	IL	f
112	f	Italy	IT	f
113	f	Jamaica	JM	f
114	f	Japan	JP	f
115	f	Jersey	JE	f
116	f	Jordan	JO	f
117	f	Kazakhstan	KZ	f
118	f	Kenya	KE	f
119	f	Kiribati	KI	f
120	f	Korea, Democratic People's Republic of	KP	f
121	f	Korea, Republic of	KR	f
122	f	Kuwait	KW	f
123	f	Kyrgyzstan	KG	f
124	f	Lao People's Democratic Republic	LA	f
125	f	Latvia	LV	f
126	f	Lebanon	LB	f
127	f	Lesotho	LS	f
128	f	Liberia	LR	f
129	f	Libyan Arab Jamahiriya	LY	f
130	f	Liechtenstein	LI	f
131	f	Lithuania	LT	f
132	f	Luxembourg	LU	f
133	f	Macao	MO	f
134	f	Macedonia	MK	f
135	f	Madagascar	MG	f
136	f	Malawi	MW	f
137	f	Malaysia	MY	f
138	f	Maldives	MV	f
139	f	Mali	ML	f
140	f	Malta	MT	f
141	f	Marshall Islands	MH	f
142	f	Martinique	MQ	f
143	f	Mauritania	MR	f
144	f	Mauritius	MU	f
145	f	Mayotte	YT	f
146	f	Mexico	MX	f
147	f	Micronesia, Federated States of	FM	f
148	f	Moldova, Republic of	MD	f
149	f	Monaco	MC	f
150	f	Mongolia	MN	f
151	f	Montenegro	ME	f
152	f	Montserrat	MS	f
153	f	Morocco	MA	f
154	f	Mozambique	MZ	f
155	f	Myanmar	MM	f
156	f	Namibia	NA	f
157	f	Nauru	NR	f
158	f	Nepal	NP	f
159	t	Netherlands	NL	f
160	f	New Caledonia	NC	f
161	t	New Zealand	NZ	f
2	t	Canada	CA	t
162	f	Nicaragua	NI	f
163	f	Niger	NE	f
164	f	Nigeria	NG	f
165	f	Niue	NU	f
166	f	Norfolk Island	NF	f
167	f	Northern Mariana Islands	MP	f
168	f	Norway	NO	f
169	f	Oman	OM	f
170	f	Pakistan	PK	f
171	f	Palau	PW	f
172	f	Palestine	PS	f
173	f	Panama	PA	f
174	f	Papua New Guinea	PG	f
175	f	Paraguay	PY	f
176	f	Peru	PE	f
177	f	Philippines	PH	f
178	f	Pitcairn	PN	f
179	f	Poland	PL	f
180	f	Portugal	PT	f
181	f	Puerto Rico	PR	f
182	f	Qatar	QA	f
183	f	Reunion	RE	f
184	t	Romania	RO	f
185	f	Russian Federation	RU	f
186	f	Rwanda	RW	f
187	f	Saint Barthélemy	BL	f
188	f	Saint Helena	SH	f
189	f	Saint Kitts and Nevis	KN	f
190	f	Saint Lucia	LC	f
191	f	Saint Martin (French part)	MF	f
192	f	Saint Pierre and Miquelon	PM	f
193	f	Saint Vincent and the Grenadines	VC	f
194	f	Samoa	WS	f
195	f	San Marino	SM	f
196	f	Sao Tome and Principe	ST	f
197	f	Saudi Arabia	SA	f
198	f	Senegal	SN	f
199	f	Serbia	RS	f
200	f	Seychelles	SC	f
201	f	Sierra Leone	SL	f
202	f	Singapore	SG	f
203	f	Sint Maarten (Dutch part)	SX	f
204	f	Slovakia	SK	f
205	f	Slovenia	SI	f
206	f	Solomon Islands	SB	f
207	f	Somalia	SO	f
208	f	South Africa	ZA	f
209	f	South Georgia and the South Sandwich Islands	GS	f
210	t	Spain	ES	f
211	f	Sri Lanka	LK	f
212	f	Sudan	SD	f
213	f	Suriname	SR	f
214	f	Svalbard and Jan Mayen	SJ	f
215	f	Swaziland	SZ	f
216	f	Sweden	SE	f
217	f	Switzerland	CH	f
218	f	Syrian Arab Republic	SY	f
219	f	Taiwan, Province of China	TW	f
220	f	Tajikistan	TJ	f
221	f	Tanzania, United Republic of	TZ	f
222	f	Thailand	TH	f
223	f	Timor-Leste	TL	f
224	f	Togo	TG	f
225	f	Tokelau	TK	f
226	f	Tonga	TO	f
227	f	Trinidad and Tobago	TT	f
228	f	Tunisia	TN	f
229	f	Turkey	TR	f
230	f	Turkmenistan	TM	f
231	f	Turks and Caicos Islands	TC	f
232	f	Tuvalu	TV	f
233	f	Uganda	UG	f
234	f	Ukraine	UA	f
235	f	United Arab Emirates	AE	f
236	f	United States Minor Outlying Islands	UM	f
237	f	Uruguay	UY	f
238	f	Uzbekistan	UZ	f
239	f	Vanuatu	VU	f
240	f	Venezuela, Bolivarian Republic of	VE	f
241	f	Viet Nam	VN	f
242	f	Virgin Islands, British	VG	f
243	f	Virgin Islands, U.S.	VI	f
244	f	Wallis and Futuna	WF	f
245	f	Western Sahara	EH	f
246	f	Yemen	YE	f
247	f	Zambia	ZM	f
248	f	Zimbabwe	ZW	f
1	t	Australia	AU	t
3	t	United Kingdom	GB	t
4	t	United States	US	t
\.


--
-- Data for Name: winter_location_states; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.winter_location_states (id, country_id, name, code, is_enabled) FROM stdin;
1	4	Alabama	AL	t
2	4	Alaska	AK	t
3	4	American Samoa	AS	t
4	4	Arizona	AZ	t
5	4	Arkansas	AR	t
6	4	California	CA	t
7	4	Colorado	CO	t
8	4	Connecticut	CT	t
9	4	Delaware	DE	t
10	4	Dist. of Columbia	DC	t
11	4	Florida	FL	t
12	4	Georgia	GA	t
13	4	Guam	GU	t
14	4	Hawaii	HI	t
15	4	Idaho	ID	t
16	4	Illinois	IL	t
17	4	Indiana	IN	t
18	4	Iowa	IA	t
19	4	Kansas	KS	t
20	4	Kentucky	KY	t
21	4	Louisiana	LA	t
22	4	Maine	ME	t
23	4	Maryland	MD	t
24	4	Marshall Islands	MH	t
25	4	Massachusetts	MA	t
26	4	Michigan	MI	t
27	4	Micronesia	FM	t
28	4	Minnesota	MN	t
29	4	Mississippi	MS	t
30	4	Missouri	MO	t
31	4	Montana	MT	t
32	4	Nebraska	NE	t
33	4	Nevada	NV	t
34	4	New Hampshire	NH	t
35	4	New Jersey	NJ	t
36	4	New Mexico	NM	t
37	4	New York	NY	t
38	4	North Carolina	NC	t
39	4	North Dakota	ND	t
40	4	Northern Marianas	MP	t
41	4	Ohio	OH	t
42	4	Oklahoma	OK	t
43	4	Oregon	OR	t
44	4	Palau	PW	t
45	4	Pennsylvania	PA	t
46	4	Puerto Rico	PR	t
47	4	Rhode Island	RI	t
48	4	South Carolina	SC	t
49	4	South Dakota	SD	t
50	4	Tennessee	TN	t
51	4	Texas	TX	t
52	4	Utah	UT	t
53	4	Vermont	VT	t
54	4	Virginia	VA	t
55	4	Virgin Islands	VI	t
56	4	Washington	WA	t
57	4	West Virginia	WV	t
58	4	Wisconsin	WI	t
59	4	Wyoming	WY	t
60	35	Acre	AC	t
61	35	Alagoas	AL	t
62	35	Amapá	AP	t
63	35	Amazonas	AM	t
64	35	Bahia	BA	t
65	35	Ceará	CE	t
66	35	Distrito Federal	DF	t
67	35	Espírito Santo	ES	t
68	35	Goiás	GO	t
69	35	Maranhão	MA	t
70	35	Mato Grosso	MT	t
71	35	Mato Grosso do Sul	MS	t
72	35	Minas Gerais	MG	t
73	35	Pará	PA	t
74	35	Paraíba	PB	t
75	35	Paraná	PR	t
76	35	Pernambuco	PE	t
77	35	Piauí	PI	t
78	35	Rio de Janeiro	RJ	t
79	35	Rio Grande do Norte	RN	t
80	35	Rio Grande do Sul	RS	t
81	35	Rondônia	RO	t
82	35	Roraima	RR	t
83	35	Santa Catarina	SC	t
84	35	São Paulo	SP	t
85	35	Sergipe	SE	t
86	35	Tocantins	TO	t
87	2	Alberta	AB	t
88	2	British Columbia	BC	t
89	2	Manitoba	MB	t
90	2	New Brunswick	NB	t
91	2	Newfoundland and Labrador	NL	t
92	2	Northwest Territories	NT	t
93	2	Nova Scotia	NS	t
94	2	Nunavut	NU	t
95	2	Ontario	ON	t
96	2	Prince Edward Island	PE	t
97	2	Quebec	QC	t
98	2	Saskatchewan	SK	t
99	2	Yukon	YT	t
100	217	Aargau	AG	t
101	217	Appenzell Innerrhoden	AI	t
102	217	Appenzell Ausserrhoden	AR	t
103	217	Bern	BE	t
104	217	Basel-Landschaft	BL	t
105	217	Basel-Stadt	BS	t
106	217	Fribourg	FR	t
107	217	Genève	GE	t
108	217	Glarus	GL	t
109	217	Graubünden	GR	t
110	217	Jura	JU	t
111	217	Luzern	LU	t
112	217	Neuchâtel	NE	t
113	217	Nidwalden	NW	t
114	217	Obwalden	OW	t
115	217	St. Gallen	SG	t
116	217	Solothurn	SO	t
117	217	Schwyz	SZ	t
118	217	Thurgau	TG	t
119	217	Ticino	TI	t
120	217	Uri	UR	t
121	217	Vaud	VD	t
122	217	Valais	VS	t
123	217	Zug	ZG	t
124	217	Zürich	ZH	t
125	1	New South Wales	NSW	t
126	1	Queensland	QLD	t
127	1	South Australia	SA	t
128	1	Tasmania	TAS	t
129	1	Victoria	VIC	t
130	1	Western Australia	WA	t
131	1	Northern Territory	NT	t
132	1	Australian Capital Territory	ACT	t
133	85	Baden-Württemberg	BW	t
134	85	Bayern	BY	t
135	85	Berlin	BE	t
136	85	Brandenburg	BB	t
137	85	Bremen	HB	t
138	85	Hamburg	HH	t
139	85	Hessen	HE	t
140	85	Mecklenburg-Vorpommern	MV	t
141	85	Niedersachsen	NI	t
142	85	Nordrhein-Westfalen	NW	t
143	85	Rheinland-Pfalz	RP	t
144	85	Saarland	SL	t
145	85	Sachsen	SN	t
146	85	Sachsen-Anhalt	ST	t
147	85	Schleswig-Holstein	SH	t
148	85	Thüringen	TH	t
149	72	Harju	HA	t
150	72	Hiiu	HI	t
151	72	Ida-Viru	IV	t
152	72	Jõgeva	JR	t
153	72	Järva	JN	t
154	72	Lääne	LN	t
155	72	Lääne-Viru	LV	t
156	72	Põlva	PL	t
157	72	Pärnu	PR	t
158	72	Rapla	RA	t
159	72	Saare	SA	t
160	72	Tartu	TA	t
161	72	Valga	VG	t
162	72	Viljandi	VD	t
163	72	Võru	VR	t
164	109	Dublin	D	t
165	109	Wicklow	WW	t
166	109	Wexford	WX	t
167	109	Carlow	CW	t
168	109	Kildare	KE	t
169	109	Meath	MH	t
170	109	Louth	LH	t
171	109	Monaghan	MN	t
172	109	Cavan	CN	t
173	109	Longford	LD	t
174	109	Westmeath	WH	t
175	109	Offaly	OY	t
176	109	Laois	LS	t
177	109	Kilkenny	KK	t
178	109	Waterford	WD	t
179	109	Cork	C	t
180	109	Kerry	KY	t
181	109	Limerick	LK	t
182	109	North Tipperary	TN	t
183	109	South Tipperary	TS	t
184	109	Clare	CE	t
185	109	Galway	G	t
186	109	Mayo	MO	t
187	109	Roscommon	RN	t
188	109	Sligo	SO	t
189	109	Leitrim	LM	t
190	109	Donegal	DL	t
191	159	Drenthe	DR	t
192	159	Flevoland	FL	t
193	159	Friesland	FR	t
194	159	Gelderland	GE	t
195	159	Groningen	GR	t
196	159	Limburg	LI	t
197	159	Noord-Brabant	NB	t
198	159	Noord-Holland	NH	t
199	159	Overijssel	OV	t
200	159	Utrecht	UT	t
201	159	Zeeland	ZE	t
202	159	Zuid-Holland	ZH	t
203	3	Aberdeenshire	ABE	t
204	3	Anglesey	ALY	t
205	3	Angus	ANG	t
206	3	Argyll	ARG	t
207	3	Ayrshire	AYR	t
208	3	Banffshire	BAN	t
209	3	Bedfordshire	BED	t
210	3	Berkshire	BER	t
211	3	Berwickshire	BWS	t
212	3	Brecknockshire	BRE	t
213	3	Buckinghamshire	BUC	t
214	3	Bute	BUT	t
215	3	Caernarfonshire	CAE	t
216	3	Caithness	CAI	t
217	3	Cambridgeshire	CAM	t
218	3	Cardiganshire	CAR	t
219	3	Carmarthenshire	CMS	t
220	3	Cheshire	CHE	t
221	3	Clackmannanshire	CLA	t
222	3	Cleveland	CLE	t
223	3	Cornwall	COR	t
224	3	Cromartyshire	CRO	t
225	3	Cumberland	CBR	t
226	3	Cumbria	CUM	t
227	3	Denbighshire	DEN	t
228	3	Derbyshire	DER	t
229	3	Devon	DEV	t
230	3	Dorset	DOR	t
231	3	Dumbartonshire	DBS	t
232	3	Dumfriesshire	DUM	t
233	3	Durham	DUR	t
234	3	East Lothian	ELO	t
235	3	Essex	ESS	t
236	3	Flintshire	FLI	t
237	3	Fife	FIF	t
238	3	Glamorgan	GLA	t
239	3	Gloucestershire	GLO	t
240	3	Hampshire	HAM	t
241	3	Herefordshire	HER	t
242	3	Hertfordshire	HTF	t
243	3	Huntingdonshire	HUN	t
244	3	Inverness	INV	t
245	3	Kent	KEN	t
246	3	Kincardineshire	KCD	t
247	3	Kinross-shire	KIN	t
248	3	Kirkcudbrightshire	KIR	t
249	3	Lanarkshire	LKS	t
250	3	Lancashire	LAN	t
251	3	Leicestershire	LEI	t
252	3	Lincolnshire	LIN	t
253	3	London	LON	t
254	3	Manchester	MAN	t
255	3	Merionethshire	MER	t
256	3	Merseyside	MSY	t
257	3	Middlesex	MDX	t
258	3	Midlands	MID	t
259	3	Midlothian	MLT	t
260	3	Monmouthshire	MON	t
261	3	Montgomeryshire	MGY	t
262	3	Moray	MOR	t
263	3	Nairnshire	NAI	t
264	3	Norfolk	NOR	t
265	3	Northamptonshire	NMP	t
266	3	Northumberland	NUM	t
267	3	Nottinghamshire	NOT	t
268	3	Orkney	ORK	t
269	3	Oxfordshire	OXF	t
270	3	Peebleshire	PEE	t
271	3	Pembrokeshire	PEM	t
272	3	Perthshire	PER	t
273	3	Radnorshire	RAD	t
274	3	Renfrewshire	REN	t
275	3	Ross & Cromarty	ROS	t
276	3	Roxburghshire	ROX	t
277	3	Rutland	RUT	t
278	3	Selkirkshire	SEL	t
279	3	Shetland	SHE	t
280	3	Shropshire	SHR	t
281	3	Somerset	SOM	t
282	3	Staffordshire	STA	t
283	3	Stirlingshire	STI	t
284	3	Suffolk	SUF	t
285	3	Surrey	SUR	t
286	3	Sussex	SUS	t
287	3	Sutherland	SUT	t
288	3	Tyne & Wear	TYN	t
289	3	Warwickshire	WAR	t
290	3	West Lothian	WLO	t
291	3	Westmorland	WES	t
292	3	Wigtownshire	WIG	t
293	3	Wiltshire	WIL	t
294	3	Worcestershire	WOR	t
295	3	Yorkshire	YOR	t
296	184	Alba	AB	t
297	184	Arad	AR	t
298	184	Arges	AG	t
299	184	Bacău	BC	t
300	184	Bihor	BH	t
301	184	Bistrita - Nasaud Bistrita	BN	t
302	184	Botosani	BT	t
303	184	Brasov	BV	t
304	184	Braila	BR	t
305	184	Bucuresti	B	t
306	184	Buzau	BZ	t
307	184	Caras - Severin	CS	t
308	184	Calarasi	CL	t
309	184	Cluj	CJ	t
310	184	Constanta	CT	t
311	184	Covasna Sfantu Gheorghe	CV	t
312	184	Dambovita	DB	t
313	184	Dolj	DJ	t
314	184	Galati	GL	t
315	184	Giurgiu	GR	t
316	184	Gorj	GJ	t
317	184	Harghita	HR	t
318	184	Hunedoara	HD	t
319	184	Ialomita	IL	t
320	184	Iasi	IS	t
321	184	Ilfov	IF	t
322	184	Maramures	MM	t
323	184	Mehedinti	MH	t
324	184	Mures	MS	t
325	184	Neamt	NT	t
326	184	Olt	OT	t
327	184	Prahova Ploiesti	PH	t
328	184	Satu Mare	SM	t
329	184	Salaj	SJ	t
330	184	Sibiu	SB	t
331	184	Suceava	SV	t
332	184	Teleorman	TR	t
333	184	Timis	TM	t
334	184	Tulcea	TL	t
335	184	Vaslui	VS	t
336	184	Valcea	VL	t
337	184	Vrancea	VN	t
338	103	Budapest	BUD	t
339	103	Baranya	BAR	t
340	103	Bács-Kiskun	BKM	t
341	103	Békés	BEK	t
342	103	Borsod-Abaúj-Zemplén	BAZ	t
343	103	Csongrád	CSO	t
344	103	Fejér	FEJ	t
345	103	Győr-Moson-Sopron	GMS	t
346	103	Hajdú-Bihar	HBM	t
347	103	Heves	HEV	t
348	103	Jász-Nagykun-Szolnok	JNS	t
349	103	Komárom-Esztergom	KEM	t
350	103	Nógrád	NOG	t
351	103	Pest	PES	t
352	103	Somogy	SOM	t
353	103	Szabolcs-Szatmár-Bereg	SSB	t
354	103	Tolna	TOL	t
355	103	Vas	VAS	t
356	103	Veszprém	VES	t
357	103	Zala	ZAL	t
358	105	Andhra Pradesh	AP	t
359	105	Arunachal Pradesh	AR	t
360	105	Assam	AS	t
361	105	Bihar	BR	t
362	105	Chhattisgarh	CT	t
363	105	Goa	GA	t
364	105	Gujarat	GJ	t
365	105	Haryana	HR	t
366	105	Himachal Pradesh	HP	t
367	105	Jammu and Kashmir	JK	t
368	105	Jharkhand	JH	t
369	105	Karnataka	KA	t
370	105	Kerala	KL	t
371	105	Madhya Pradesh	MP	t
372	105	Maharashtra	MH	t
373	105	Manipur	MN	t
374	105	Meghalaya	ML	t
375	105	Mizoram	MZ	t
376	105	Nagaland	NL	t
377	105	Odisha	OR	t
378	105	Punjab	PB	t
379	105	Rajasthan	RJ	t
380	105	Sikkim	SK	t
381	105	Tamil Nadu	TN	t
382	105	Telangana	TG	t
383	105	Tripura	TR	t
384	105	Uttarakhand	UT	t
385	105	Uttar Pradesh	UP	t
386	105	West Bengal	WB	t
387	105	Andaman and Nicobar Islands	AN	t
388	105	Chandigarh	CH	t
389	105	Dadra and Nagar Haveli	DN	t
390	105	Daman and Diu	DD	t
391	105	Delhi	DL	t
392	105	Lakshadweep	LD	t
393	105	Puducherry	PY	t
394	78	Auvergne-Rhône-Alpes	ARA	t
395	78	Bourgogne-Franche-Comté	BFC	t
396	78	Bretagne	BZH	t
397	78	Centre–Val-de-Loire	CVL	t
398	78	Corse	COR	t
399	78	Guadeloupe	GP	t
400	78	Guyane	GF	t
401	78	Grand-Est	GE	t
402	78	Hauts-de-France	HF	t
403	78	Île-de-France	IDF	t
404	78	Martinique	MQ	t
405	78	Mayotte	YT	t
406	78	Normandie	NOR	t
407	78	Pays-de-la-Loire	PL	t
408	78	Nouvelle-Aquitaine	NA	t
409	78	Occitanie	OCC	t
410	78	Provence-Alpes-Côte-d'Azur	PACA	t
411	78	Réunion	RE	t
412	161	Northland	NTL	t
413	161	Auckland	AUK	t
414	161	Waikato	WKO	t
415	161	Bay of Plenty	BOP	t
416	161	Gisborne	GIS	t
417	161	Hawke's Bay	HKB	t
418	161	Taranaki	TKI	t
419	161	Manawatu-Wanganui	MWT	t
420	161	Wellington	WGN	t
421	161	Tasman	TAS	t
422	161	Nelson	NSN	t
423	161	Marlborough	MBH	t
424	161	West Coast	WTC	t
425	161	Canterbury	CAN	t
426	161	Otago Otago	OTA	t
427	161	Southland	STL	t
428	210	A Coruña (gl) [La Coruña]	ES-C	t
429	210	Araba (eu)	ES-VI	t
430	210	Albacete	ES-AB	t
431	210	Alacant (ca)	ES-A	t
432	210	Almería	ES-AL	t
433	210	Asturias	ES-O	t
434	210	Ávila	ES-AV	t
435	210	Badajoz	ES-BA	t
436	210	Balears (ca) [Baleares]	ES-PM	t
437	210	Barcelona [Barcelona]	ES-B	t
438	210	Burgos	ES-BU	t
439	210	Cáceres	ES-CC	t
440	210	Cádiz	ES-CA	t
441	210	Cantabria	ES-S	t
442	210	Castelló (ca)	ES-CS	t
443	210	Ciudad Real	ES-CR	t
444	210	Córdoba	ES-CO	t
445	210	Cuenca	ES-CU	t
446	210	Girona (ca) [Gerona]	ES-GI	t
447	210	Granada	ES-GR	t
448	210	Guadalajara	ES-GU	t
449	210	Gipuzkoa (eu)	ES-SS	t
450	210	Huelva	ES-H	t
451	210	Huesca	ES-HU	t
452	210	Jaén	ES-J	t
453	210	La Rioja	ES-LO	t
454	210	Las Palmas	ES-GC	t
455	210	León	ES-LE	t
456	210	Lleida (ca) [Lérida]	ES-L	t
457	210	Lugo (gl) [Lugo]	ES-LU	t
458	210	Madrid	ES-M	t
459	210	Málaga	ES-MA	t
460	210	Murcia	ES-MU	t
461	210	Nafarroa (eu)	ES-NA	t
462	210	Ourense (gl) [Orense]	ES-OR	t
463	210	Palencia	ES-P	t
464	210	Pontevedra (gl) [Pontevedra]	ES-PO	t
465	210	Salamanca	ES-SA	t
466	210	Santa Cruz de Tenerife	ES-TF	t
467	210	Segovia	ES-SG	t
468	210	Sevilla	ES-SE	t
469	210	Soria	ES-SO	t
470	210	Tarragona (ca) [Tarragona]	ES-T	t
471	210	Teruel	ES-TE	t
472	210	Toledo	ES-TO	t
473	210	València (ca)	ES-V	t
474	210	Valladolid	ES-VA	t
475	210	Bizkaia (eu)	ES-BI	t
476	210	Zamora	ES-ZA	t
477	210	Zaragoza	ES-Z	t
478	146	Aguascalientes	MX-AGU	t
479	146	Baja California	MX-BCN	t
480	146	Baja California Sur	MX-BCS	t
481	146	Campeche	MX-CAM	t
482	146	Chiapas	MX-CHP	t
483	146	Chihuahua	MX-CHH	t
484	146	Coahuila	MX-COA	t
485	146	Colima	MX-COL	t
486	146	Ciudad de México	MX-CMX​	t
487	146	Durango	MX-DUR	t
488	146	Guanajuato	MX-GUA	t
489	146	Guerrero	MX-GRO	t
490	146	Hidalgo	MX-HID	t
491	146	Jalisco	MX-JAL	t
492	146	Estado de México	MX-MEX	t
493	146	Michoacán	MX-MIC	t
494	146	Morelos	MX-MOR	t
495	146	Nayarit	MX-NAY	t
496	146	Nuevo León	MX-NLE	t
497	146	Oaxaca	MX-OAX	t
498	146	Puebla	MX-PUE	t
499	146	Querétaro	MX-QUE	t
500	146	Quintana Roo	MX-ROO	t
501	146	San Luis Potosí	MX-SLP	t
502	146	Sinaloa	MX-SIN	t
503	146	Sonora	MX-SON	t
504	146	Tabasco	MX-TAB	t
505	146	Tamaulipas	MX-TAM	t
506	146	Tlaxcala	MX-TLA	t
507	146	Veracruz	MX-VER	t
508	146	Yucatán	MX-YUC	t
509	146	Zacatecas	MX-ZAC	t
510	15	Buenos Aires	BA	t
511	15	Catamarca	CA	t
512	15	Chaco	CH	t
513	15	Chubut	CT	t
514	15	Córdoba	CB	t
515	15	Corrientes	CR	t
516	15	Entre Ríos	ER	t
517	15	Formosa	FO	t
518	15	Jujuy	JY	t
519	15	La Pampa	LP	t
520	15	La Rioja	LR	t
521	15	Mendoza	MZ	t
522	15	Misiones	MI	t
523	15	Neuquén	NQ	t
524	15	Río Negro	RN	t
525	15	Salta	SA	t
526	15	San Juan	SJ	t
527	15	San Luis	SL	t
528	15	Santa Cruz	SC	t
529	15	Santa Fe	SF	t
530	15	Santiago del Estero	SE	t
531	15	Tierra del Fuego	TF	t
532	15	Tucumán	TU	t
533	112	Agrigento	AG	t
534	112	Alessandria	AL	t
535	112	Ancona	AN	t
536	112	Aosta	AO	t
537	112	Arezzo	AR	t
538	112	Ascoli Piceno	AP	t
539	112	Asti	AT	t
540	112	Avellino	AV	t
541	112	Bari	BA	t
542	112	Belluno	BL	t
543	112	Benevento	BN	t
544	112	Bergamo	BG	t
545	112	Biella	BI	t
546	112	Bologna	BO	t
547	112	Bolzano	BZ	t
548	112	Brescia	BS	t
549	112	Brindisi	BR	t
550	112	Cagliari	CA	t
551	112	Caltanissetta	CL	t
552	112	Campobasso	CB	t
553	112	Caserta	CE	t
554	112	Catania	CT	t
555	112	Catanzaro	CZ	t
556	112	Chieti	CH	t
557	112	Como	CO	t
558	112	Cosenza	CS	t
559	112	Cremona	CR	t
560	112	Crotone	KR	t
561	112	Cuneo	CN	t
562	112	Enna	EN	t
563	112	Ferrara	FE	t
564	112	Firenze	FI	t
565	112	Foggia	FG	t
566	112	Forli'-Cesena	FO	t
567	112	Frosinone	FR	t
568	112	Genova	GE	t
569	112	Gorizia	GO	t
570	112	Grosseto	GR	t
571	112	Imperia	IM	t
572	112	Isernia	IS	t
573	112	La Spezia	SP	t
574	112	L'Aquila	AQ	t
575	112	Latina	LT	t
576	112	Lecce	LE	t
577	112	Lecco	LC	t
578	112	Livorno	LI	t
579	112	Lodi	LO	t
580	112	Lucca	LU	t
581	112	Macerata	MC	t
582	112	Mantova	MN	t
583	112	Massa-Carrara	MS	t
584	112	Matera	MT	t
585	112	Messina	ME	t
586	112	Milano	MI	t
587	112	Modena	MO	t
588	112	Napoli	NA	t
589	112	Novara	NO	t
590	112	Nuoro	NU	t
591	112	Oristano	OR	t
592	112	Padova	PD	t
593	112	Palermo	PA	t
594	112	Parma	PR	t
595	112	Pavia	PV	t
596	112	Perugia	PG	t
597	112	Pesaro e Urbino	PS	t
598	112	Pescara	PE	t
599	112	Piacenza	PC	t
600	112	Pisa	PI	t
601	112	Pistoia	PT	t
602	112	Pordenone	PN	t
603	112	Potenza	PZ	t
604	112	Prato	PO	t
605	112	Ragusa	RG	t
606	112	Ravenna	RA	t
607	112	Reggio di Calabria	RC	t
608	112	Reggio nell'Emilia	RE	t
609	112	Rieti	RI	t
610	112	Rimini	RN	t
611	112	Roma	RM	t
612	112	Rovigo	RO	t
613	112	Salerno	SA	t
614	112	Sassari	SS	t
615	112	Savona	SV	t
616	112	Siena	SI	t
617	112	Siracusa	SR	t
618	112	Sondrio	SO	t
619	112	Taranto	TA	t
620	112	Teramo	TE	t
621	112	Terni	TR	t
622	112	Torino	TO	t
623	112	Trapani	TP	t
624	112	Trento	TN	t
625	112	Treviso	TV	t
626	112	Trieste	TS	t
627	112	Udine	UD	t
628	112	Varese	VA	t
629	112	Venezia	VE	t
630	112	Verbano-Cusio-Ossola	VB	t
631	112	Vercelli	VC	t
632	112	Verona	VR	t
633	112	Vibo Valentia	VV	t
634	112	Vicenza	VI	t
635	112	Viterbo	VT	t
636	185	Адыгея	RU-AD	t
637	185	Башкортостан	RU-BA	t
638	185	Бурятия	RU-BU	t
639	185	Республика Алтай	RU-AL	t
640	185	Дагестан	RU-DA	t
641	185	Ингушетия	RU-IN	t
642	185	Кабардино-Балкария	RU-KB	t
643	185	Калмыкия	RU-KL	t
644	185	Карачаево-Черкесия	RU-KC	t
645	185	Карелия	RU-KR	t
646	185	Республика Коми	RU-KO	t
647	185	Марий Эл	RU-ME	t
648	185	Мордовия	RU-MO	t
649	185	Якутия	RU-SA	t
650	185	Северная Осетия	RU-SE	t
651	185	Татарстан	RU-TA	t
652	185	Тыва	RU-TY	t
653	185	Удмуртия	RU-UD	t
654	185	Хакасия	RU-KK	t
655	185	Чувашия	RU-CU	t
656	185	Алтайский край	RU-ALT	t
657	185	Краснодарский край	RU-KDA	t
658	185	Красноярский край	RU-KYA	t
659	185	Приморский край	RU-PRI	t
660	185	Ставропольский край	RU-STA	t
661	185	Хабаровский край	RU-KHA	t
662	185	Амурская область	RU-AMU	t
663	185	Архангельская область	RU-ARK	t
664	185	Астраханская область	RU-AST	t
665	185	Белгородская область	RU-BEL	t
666	185	Брянская область	RU-BRY	t
667	185	Владимирская область	RU-VLA	t
668	185	Волгоградская область	RU-VGG	t
669	185	Вологодская область	RU-VLG	t
670	185	Воронежская область	RU-VOR	t
671	185	Ивановская область	RU-IVA	t
672	185	Иркутская область	RU-IRK	t
673	185	Калининградская область	RU-KGD	t
674	185	Калужская область	RU-KLU	t
675	185	Камчатский край	RU-KAM	t
676	185	Кемеровская область	RU-KEM	t
677	185	Кировская область	RU-KIR	t
678	185	Костромская область	RU-KOS	t
679	185	Курганская область	RU-KGN	t
680	185	Курская область	RU-KRS	t
681	185	Ленинградская область	RU-LEN	t
682	185	Липецкая область	RU-LIP	t
683	185	Магаданская область	RU-MAG	t
684	185	Московская область	RU-MOS	t
685	185	Мурманская область	RU-MUR	t
686	185	Нижегородская область	RU-NIZ	t
687	185	Новгородская область	RU-NGR	t
688	185	Новосибирская область	RU-NVS	t
689	185	Омская область	RU-OMS	t
690	185	Оренбургская область	RU-ORE	t
691	185	Орловская область	RU-ORL	t
692	185	Пензенская область	RU-PNZ	t
693	185	Пермский край	RU-PER	t
694	185	Псковская область	RU-PSK	t
695	185	Ростовская область	RU-ROS	t
696	185	Рязанская область	RU-RYA	t
697	185	Самарская область	RU-SAM	t
698	185	Саратовская область	RU-SAR	t
699	185	Сахалинская область	RU-SAK	t
700	185	Свердловская область	RU-SVE	t
701	185	Смоленская область	RU-SMO	t
702	185	Тамбовская область	RU-TAM	t
703	185	Тверская область	RU-TVE	t
704	185	Томская область	RU-TOM	t
705	185	Тульская область	RU-TUL	t
706	185	Тюменская область	RU-TYU	t
707	185	Ульяновская область	RU-ULY	t
708	185	Челябинская область	RU-CHE	t
709	185	Забайкальский край	RU-ZAB	t
710	185	Ярославская область	RU-YAR	t
711	185	Москва	RU-MOW	t
712	185	Санкт-Петербург	RU-SPE	t
713	185	Еврейская автономная область	RU-YEV	t
714	185	Крым	UA-43	t
715	185	Ненецкий автономный округ	RU-NEN	t
716	185	Ханты-Мансийский автономный округ - Югра	RU-KHM	t
717	185	Чукотский автономный округ	RU-CHU	t
718	185	Ямало-Ненецкий автономный округ	RU-YAN	t
719	185	Севастополь	UA-40	t
720	185	Чечня	RU-CE	t
\.


--
-- Data for Name: winter_translate_attributes; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.winter_translate_attributes (id, locale, model_id, model_type, attribute_data) FROM stdin;
1	ar	f7f8504d-7b6e-4083-b0f9-df0203c39d77	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
2	ku	f7f8504d-7b6e-4083-b0f9-df0203c39d77	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
3	ar	9d4a8a4c-93b5-4f0d-87b6-b428b24d47f5	Acorn\\Criminal\\Models\\Crime	{"name":""}
4	ku	9d4a8a4c-93b5-4f0d-87b6-b428b24d47f5	Acorn\\Criminal\\Models\\Crime	{"name":""}
5	ar	9d4a8d98-a8bd-4d4b-8ead-5317908869e8	Acorn\\Criminal\\Models\\Crime	{"name":""}
6	ku	9d4a8d98-a8bd-4d4b-8ead-5317908869e8	Acorn\\Criminal\\Models\\Crime	{"name":""}
7	ar	9d4a965a-f94e-4587-b270-da162e52db98	Acorn\\Criminal\\Models\\SentenceType	{"name":""}
8	ku	9d4a965a-f94e-4587-b270-da162e52db98	Acorn\\Criminal\\Models\\SentenceType	{"name":""}
9	ar	9d4a96d7-769f-435c-a6ca-f4870040ecc8	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
10	ku	9d4a96d7-769f-435c-a6ca-f4870040ecc8	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
11	ar	9d4aa211-34bd-4653-85b6-5ddb164440fe	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
12	ku	9d4aa211-34bd-4653-85b6-5ddb164440fe	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
13	ar	9d4c5b36-75b9-4123-acea-c85a306810ba	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
14	ku	9d4c5b36-75b9-4123-acea-c85a306810ba	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
15	ar	9d4c64fa-99c0-414f-af79-cc0eab861157	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
16	ku	9d4c64fa-99c0-414f-af79-cc0eab861157	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
17	ar	9d50329d-e584-4745-9407-e48082a25205	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
18	ku	9d50329d-e584-4745-9407-e48082a25205	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
19	ar	80e841e9-27f9-492b-abb7-bf5985aca118	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
20	ku	80e841e9-27f9-492b-abb7-bf5985aca118	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
21	ar	9d506cb4-c01e-43f0-8852-5e25e3b11910	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
22	ku	9d506cb4-c01e-43f0-8852-5e25e3b11910	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
23	ar	9d50b964-67d7-482a-b65b-bf0249124169	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
24	ku	9d50b964-67d7-482a-b65b-bf0249124169	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
25	ar	9d50ba9d-f66d-40df-b69c-6af31eb1b89e	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
26	ku	9d50ba9d-f66d-40df-b69c-6af31eb1b89e	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
27	ar	9d50bacd-e491-41e7-bc04-c709fc19a744	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
28	ku	9d50bacd-e491-41e7-bc04-c709fc19a744	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
29	ar	9d50baec-23b1-4b61-8227-73f40cc76717	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
30	ku	9d50baec-23b1-4b61-8227-73f40cc76717	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
31	ar	9d50bb79-4d26-4211-ae10-22e86b0fbfa3	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
32	ku	9d50bb79-4d26-4211-ae10-22e86b0fbfa3	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
33	ar	9d50c379-b23d-40ee-95b5-1f5f3e7ba223	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
34	ku	9d50c379-b23d-40ee-95b5-1f5f3e7ba223	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
35	ar	9d523e2f-5d41-417e-9339-9032cbaea5af	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
36	ku	9d523e2f-5d41-417e-9339-9032cbaea5af	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
37	ar	9d54363d-4c9a-4863-b82d-87c3c7f28300	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
38	ku	9d54363d-4c9a-4863-b82d-87c3c7f28300	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
39	ar	9d5470f2-844c-452f-8ec2-2476e872a56c	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
40	ku	9d5470f2-844c-452f-8ec2-2476e872a56c	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
41	ar	9d587bb4-3a40-461d-ad98-925e7fa0ea3a	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
42	ku	9d587bb4-3a40-461d-ad98-925e7fa0ea3a	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
43	ar	9d588269-47a6-4b73-93e0-28167637e584	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
44	ku	9d588269-47a6-4b73-93e0-28167637e584	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
45	ar	9d58838d-8508-49c3-b161-a515352e4c34	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
46	ku	9d58838d-8508-49c3-b161-a515352e4c34	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
47	ar	9d5883a8-5ef8-4019-a9dd-74c524b8e1a5	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
48	ku	9d5883a8-5ef8-4019-a9dd-74c524b8e1a5	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
49	ar	9d5884f8-14c3-4c54-b4bd-a5852df92969	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
50	ku	9d5884f8-14c3-4c54-b4bd-a5852df92969	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
51	ar	9d58bd5f-a462-4041-8ed3-338e5c480f8b	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
52	ku	9d58bd5f-a462-4041-8ed3-338e5c480f8b	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
53	ar	9d58bdb8-4fe3-43d5-8a24-2750e9df2371	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
54	ku	9d58bdb8-4fe3-43d5-8a24-2750e9df2371	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
55	ar	9d58bf06-b792-45d0-b39f-2114f3ed3915	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
56	ku	9d58bf06-b792-45d0-b39f-2114f3ed3915	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
57	ar	9d58bf1d-5987-4b45-9537-51375d9bee2c	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
58	ku	9d58bf1d-5987-4b45-9537-51375d9bee2c	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
59	ar	9d58bf2d-6225-4391-942f-901e10706b78	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
60	ku	9d58bf2d-6225-4391-942f-901e10706b78	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
61	ar	9d58da7f-dc4f-48a7-bb82-0667aaa076ca	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
62	ku	9d58da7f-dc4f-48a7-bb82-0667aaa076ca	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
63	ar	9d58dc36-8be7-43f7-8e94-78d57df57bec	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
64	ku	9d58dc36-8be7-43f7-8e94-78d57df57bec	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
65	ar	9d58dede-2691-4ab7-b3e9-a8f608fe9a4f	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
66	ku	9d58dede-2691-4ab7-b3e9-a8f608fe9a4f	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
67	ar	9d58defc-43b1-412f-970d-57d51da6d3da	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
68	ku	9d58defc-43b1-412f-970d-57d51da6d3da	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
69	ar	9d58df6e-7dca-4e28-8870-6e4b1136b422	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
70	ku	9d58df6e-7dca-4e28-8870-6e4b1136b422	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
71	ar	9d58e27e-b01e-4bdc-94c9-c63f5850f8b4	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
72	ku	9d58e27e-b01e-4bdc-94c9-c63f5850f8b4	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
73	ar	9d58e412-d52f-4ee1-8872-1f2c9a0735eb	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
74	ku	9d58e412-d52f-4ee1-8872-1f2c9a0735eb	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
75	ar	9d58e432-1a07-4f72-a293-4459a602352b	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
76	ku	9d58e432-1a07-4f72-a293-4459a602352b	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
77	ar	9d59085b-1de7-46cd-907e-0880f58a7bd5	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
78	ku	9d59085b-1de7-46cd-907e-0880f58a7bd5	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
79	ar	9d5a7cb4-e228-4785-9b5d-8a6a83a24092	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
80	ku	9d5a7cb4-e228-4785-9b5d-8a6a83a24092	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
81	ar	9d5a7cc6-f44b-45f5-b861-9236d89a233e	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
82	ku	9d5a7cc6-f44b-45f5-b861-9236d89a233e	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
83	ar	9d5a813e-3214-4323-b999-2b9529105e73	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
84	ku	9d5a813e-3214-4323-b999-2b9529105e73	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
85	ar	9d5a8196-9586-4985-bf49-176f5286c289	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
86	ku	9d5a8196-9586-4985-bf49-176f5286c289	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
87	ar	9d5aeee9-912d-49de-a1d0-8386c030bbe5	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
88	ku	9d5aeee9-912d-49de-a1d0-8386c030bbe5	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
89	ar	9d5af110-cf6c-429f-9891-e9a8af95f7e0	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
90	ku	9d5af110-cf6c-429f-9891-e9a8af95f7e0	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
91	ar	9d5af133-2abf-48ac-90bd-72fd196397c0	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
92	ku	9d5af133-2abf-48ac-90bd-72fd196397c0	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
93	ar	9d5c01c3-5d7f-463c-8ebd-01a1ec113358	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
94	ku	9d5c01c3-5d7f-463c-8ebd-01a1ec113358	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
95	ar	9d5c03d4-7563-42cb-8e57-0042e53848f1	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
96	ku	9d5c03d4-7563-42cb-8e57-0042e53848f1	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
97	ar	9d5c040b-9aa4-4c17-a74e-9d42c8541573	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
98	ku	9d5c040b-9aa4-4c17-a74e-9d42c8541573	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
99	ar	9d5c041d-5a51-4670-926b-c24dec20fe72	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
100	ku	9d5c041d-5a51-4670-926b-c24dec20fe72	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
101	ar	9d5c04a1-c7b6-453e-ac31-e585a3340cd5	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
102	ku	9d5c04a1-c7b6-453e-ac31-e585a3340cd5	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
103	ar	9d5c04b4-2638-4c3f-9291-41005324b9e9	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
104	ku	9d5c04b4-2638-4c3f-9291-41005324b9e9	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
105	ar	9d5c0506-f51f-4a8f-a9e5-100968302444	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
106	ku	9d5c0506-f51f-4a8f-a9e5-100968302444	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
107	ar	9d5c058c-1fc0-4d5c-b5d0-35dd6599b2d7	Acorn\\Houseofpeace\\Models\\Event	{"name":""}
108	ku	9d5c058c-1fc0-4d5c-b5d0-35dd6599b2d7	Acorn\\Houseofpeace\\Models\\Event	{"name":""}
109	ar	9d5c0600-bcf5-4cbe-8a54-b1ce50e6a833	Acorn\\Criminal\\Models\\Crime	{"name":""}
110	ku	9d5c0600-bcf5-4cbe-8a54-b1ce50e6a833	Acorn\\Criminal\\Models\\Crime	{"name":""}
111	ar	9d5c0627-63c5-434e-88f3-1eb4f1561982	Acorn\\Criminal\\Models\\SentenceType	{"name":""}
112	ku	9d5c0627-63c5-434e-88f3-1eb4f1561982	Acorn\\Criminal\\Models\\SentenceType	{"name":""}
113	ar	9d5d1527-90aa-4645-973b-2e5b39da18af	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
114	ku	9d5d1527-90aa-4645-973b-2e5b39da18af	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
115	ar	9d5e40a3-6dc2-464d-a41a-45163bcad32d	Acorn\\Justice\\Models\\Legalcase	{"name":""}
116	ku	9d5e40a3-6dc2-464d-a41a-45163bcad32d	Acorn\\Justice\\Models\\Legalcase	{"name":""}
117	ar	9d5e40d5-a867-4484-b557-f9d78f775b5c	Acorn\\Houseofpeace\\Models\\Event	{"name":""}
118	ku	9d5e40d5-a867-4484-b557-f9d78f775b5c	Acorn\\Houseofpeace\\Models\\Event	{"name":""}
119	ar	9d5e55f2-c221-4e46-9dff-d297e448c590	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
120	ku	9d5e55f2-c221-4e46-9dff-d297e448c590	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
121	ar	9d5e92b8-607b-4b8b-9d5d-708d19c49b55	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
122	ku	9d5e92b8-607b-4b8b-9d5d-708d19c49b55	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
123	ar	9d5e9327-1837-4518-8670-62b61d43465b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
124	ku	9d5e9327-1837-4518-8670-62b61d43465b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
125	ar	9d5e93b6-ac95-45a7-921a-6aad75673f2d	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
126	ku	9d5e93b6-ac95-45a7-921a-6aad75673f2d	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
127	ar	9d5e93f8-b29c-4f2b-9a4e-ef9dce629961	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
128	ku	9d5e93f8-b29c-4f2b-9a4e-ef9dce629961	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
129	ar	9d60da11-ba48-4055-89cd-be9a00c5db39	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
130	ku	9d60da11-ba48-4055-89cd-be9a00c5db39	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
131	ar	9d62a48f-1ca6-4295-98b5-42fb6a27efe0	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
132	ku	9d62a48f-1ca6-4295-98b5-42fb6a27efe0	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
133	ar	9d62a4ce-fd35-4fda-afaf-c76d6dc0a04b	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
134	ku	9d62a4ce-fd35-4fda-afaf-c76d6dc0a04b	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
135	ar	9d62a7b6-5e0a-441e-b732-d13e8460e59e	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
136	ku	9d62a7b6-5e0a-441e-b732-d13e8460e59e	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
137	ar	ddfe9196-9426-4e59-baa3-fd2eb62bf93f	Acorn\\Calendar\\Models\\Type	{"name":"Normal ar"}
138	ku	ddfe9196-9426-4e59-baa3-fd2eb62bf93f	Acorn\\Calendar\\Models\\Type	{"name":""}
139	ar	9d680027-1145-4be4-975c-ff085afbce34	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
140	ku	9d680027-1145-4be4-975c-ff085afbce34	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
141	ar	9d6a4b02-c5ae-467a-9749-c077820b4986	Acorn\\Location\\Models\\Location	{"name":""}
142	ku	9d6a4b02-c5ae-467a-9749-c077820b4986	Acorn\\Location\\Models\\Location	{"name":""}
145	ar	9d6c45dc-89a6-4f30-9374-2be4e7a2fa8a	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
146	ku	9d6c45dc-89a6-4f30-9374-2be4e7a2fa8a	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
147	ar	9d6c45f7-4377-4c4b-8bba-a11a6f5e0a62	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
148	ku	9d6c45f7-4377-4c4b-8bba-a11a6f5e0a62	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
149	ar	9d6d277e-0cbd-4a8c-8483-04fadefd0a06	Acorn\\User\\Models\\UserGroupType	{"name":""}
150	ku	9d6d277e-0cbd-4a8c-8483-04fadefd0a06	Acorn\\User\\Models\\UserGroupType	{"name":""}
151	ar	9d48334c-300c-4970-9c35-be5206270507	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
152	ku	9d48334c-300c-4970-9c35-be5206270507	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
153	ar	9d6d2bbb-447a-411f-99e3-72d2c1707f90	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
155	ar	d062abea-105d-4726-a6e8-e27aa6cd5d08	Acorn\\Location\\Models\\Type	{"name":""}
156	ku	d062abea-105d-4726-a6e8-e27aa6cd5d08	Acorn\\Location\\Models\\Type	{"name":""}
157	ar	ad1f8d2e-da3e-4d03-8bba-4d8ac72bc7a5	Acorn\\Location\\Models\\Type	{"name":""}
158	ku	ad1f8d2e-da3e-4d03-8bba-4d8ac72bc7a5	Acorn\\Location\\Models\\Type	{"name":""}
154	ku	9d6d2bbb-447a-411f-99e3-72d2c1707f90	Acorn\\User\\Models\\UserGroup	{"name":"Berx","description":""}
159	ar	9d763c8a-dc75-4ff3-ab51-125320eefb7d	Acorn\\Calendar\\Models\\Calendar	{"name":"","description":""}
160	ku	9d763c8a-dc75-4ff3-ab51-125320eefb7d	Acorn\\Calendar\\Models\\Calendar	{"name":"","description":""}
161	ar	9d7a7820-e037-42f1-8e2a-4abeabddcb13	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
162	ku	9d7a7820-e037-42f1-8e2a-4abeabddcb13	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
163	ar	9d7a788d-0408-4e8d-97b5-da8dd5a0ab73	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
164	ku	9d7a788d-0408-4e8d-97b5-da8dd5a0ab73	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
165	ar	9d7a79a0-3fa2-41b1-9923-f3927189531a	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
166	ku	9d7a79a0-3fa2-41b1-9923-f3927189531a	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
167	ar	9d7a7a40-60b4-48ca-818d-85cbe2341f36	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
168	ku	9d7a7a40-60b4-48ca-818d-85cbe2341f36	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
169	ar	9d7a7a4e-22c3-4cd5-ab7a-1bf9dde4e307	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
170	ku	9d7a7a4e-22c3-4cd5-ab7a-1bf9dde4e307	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
171	ar	9d7a7a63-7bb9-4000-839f-9e08b6f9f571	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
172	ku	9d7a7a63-7bb9-4000-839f-9e08b6f9f571	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
173	ar	9d7a8403-aaa6-4713-a7b6-aec1be0ff20e	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
174	ku	9d7a8403-aaa6-4713-a7b6-aec1be0ff20e	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
175	ar	9d7a84c9-38c3-4de0-9c1f-ccea266347e0	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
176	ku	9d7a84c9-38c3-4de0-9c1f-ccea266347e0	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
177	ar	9d7a8520-3f5e-4743-a853-c5a43c487d31	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
178	ku	9d7a8520-3f5e-4743-a853-c5a43c487d31	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
179	ar	9d7a8567-fbed-4859-882a-1a90c6638f7c	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
180	ku	9d7a8567-fbed-4859-882a-1a90c6638f7c	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
181	ar	9d7a8639-f9cd-4876-9b8c-e0c6d1d041a7	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
182	ku	9d7a8639-f9cd-4876-9b8c-e0c6d1d041a7	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
183	ar	9d7a86aa-78a1-4fe6-8a60-0657dfce6b04	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
184	ku	9d7a86aa-78a1-4fe6-8a60-0657dfce6b04	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
185	ar	9d7a8aaf-f97c-480e-b072-86a09074f0ee	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
186	ku	9d7a8aaf-f97c-480e-b072-86a09074f0ee	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
187	ar	9d7a8b92-a801-416e-a3eb-bca47e0250cd	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
188	ku	9d7a8b92-a801-416e-a3eb-bca47e0250cd	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
189	ar	9d7a8d4f-c85b-4630-bcbd-27f7ff3a586a	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
190	ku	9d7a8d4f-c85b-4630-bcbd-27f7ff3a586a	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
191	ar	9d7a8df3-e043-4859-9cd4-3f50e446f4d1	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
192	ku	9d7a8df3-e043-4859-9cd4-3f50e446f4d1	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
193	ar	9d7a9b7b-39e7-48c1-a4d5-080308d08f1b	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
194	ku	9d7a9b7b-39e7-48c1-a4d5-080308d08f1b	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
195	ar	9d7c4b98-3077-4f8b-8c3e-b4620ca060d2	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
196	ku	9d7c4b98-3077-4f8b-8c3e-b4620ca060d2	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
197	ar	9d7c7ab0-69bb-4ef4-a59c-4152ca7361c8	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
198	ku	9d7c7ab0-69bb-4ef4-a59c-4152ca7361c8	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
199	ar	9d7c7ab6-1a72-4515-8a4a-9f0df0166324	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
200	ku	9d7c7ab6-1a72-4515-8a4a-9f0df0166324	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
201	ar	9d7c7ab8-25bf-4045-b7a7-e0182bdf1770	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
202	ku	9d7c7ab8-25bf-4045-b7a7-e0182bdf1770	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
203	ar	9d7c7ab9-87f2-4895-ae5d-044866b6a139	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
204	ku	9d7c7ab9-87f2-4895-ae5d-044866b6a139	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
205	ar	9d7c7abb-31fb-461e-8418-39bee4b6c098	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
206	ku	9d7c7abb-31fb-461e-8418-39bee4b6c098	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
207	ar	9d7c7acd-9e73-46cd-a042-9af239ce5181	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
208	ku	9d7c7acd-9e73-46cd-a042-9af239ce5181	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
209	ar	9d7c7acf-03fb-4211-af6a-c64887cbb6e1	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
210	ku	9d7c7acf-03fb-4211-af6a-c64887cbb6e1	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
211	ar	9d7c7ad0-b310-4b2a-8520-8acaadf2fea9	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
212	ku	9d7c7ad0-b310-4b2a-8520-8acaadf2fea9	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
213	ar	9d7c7ad2-4939-4466-92fb-ed6c93386370	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
214	ku	9d7c7ad2-4939-4466-92fb-ed6c93386370	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
215	ar	9d7c7e64-3ea7-4cec-af7a-228ad81d3049	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
216	ku	9d7c7e64-3ea7-4cec-af7a-228ad81d3049	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
217	ar	e5aa0d61-8c70-4c74-99e6-4312ea063912	Acorn\\Location\\Models\\Location	{"name":""}
218	ku	e5aa0d61-8c70-4c74-99e6-4312ea063912	Acorn\\Location\\Models\\Location	{"name":""}
219	ar	9d80b254-cdbe-4060-8611-9727a3abe982	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
220	ku	9d80b254-cdbe-4060-8611-9727a3abe982	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
221	ar	9d80bc1a-4d9f-4ac3-bb7d-06982a68c566	Acorn\\University\\Models\\Course	{"name":""}
222	ku	9d80bc1a-4d9f-4ac3-bb7d-06982a68c566	Acorn\\University\\Models\\Course	{"name":""}
223	ar	9d8441a0-47b5-4a8e-8a74-519a4130d20e	Acorn\\University\\Models\\Course	{"name":""}
224	ku	9d8441a0-47b5-4a8e-8a74-519a4130d20e	Acorn\\University\\Models\\Course	{"name":""}
225	ar	9d844689-28e1-41ff-a588-9332ce953366	Acorn\\University\\Models\\Course	{"name":""}
226	ku	9d844689-28e1-41ff-a588-9332ce953366	Acorn\\University\\Models\\Course	{"name":""}
227	ar	9d8469c1-afee-4260-b9d5-73f716a5e76f	Acorn\\University\\Models\\Course	{"name":""}
228	ku	9d8469c1-afee-4260-b9d5-73f716a5e76f	Acorn\\University\\Models\\Course	{"name":""}
229	ar	9d8a43d7-c284-4d84-b5f4-13577207a728	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
230	ku	9d8a43d7-c284-4d84-b5f4-13577207a728	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
231	ar	9d8a4cae-0dc1-48d9-97f6-d6dca0e82ff9	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
233	ar	9d8a4cc4-0c6b-4eea-9807-3e3bc54ecec4	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
234	ku	9d8a4cc4-0c6b-4eea-9807-3e3bc54ecec4	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
235	ar	9d8a4dd2-2157-4bbd-b00f-31311d89854f	Acorn\\University\\Models\\Course	{"name":""}
236	ku	9d8a4dd2-2157-4bbd-b00f-31311d89854f	Acorn\\University\\Models\\Course	{"name":""}
232	ku	9d8a4cae-0dc1-48d9-97f6-d6dca0e82ff9	Acorn\\Justice\\Models\\ScannedDocument	{"name":"vvk"}
237	ar	9d8d3b6e-1131-402f-9955-b7317b4beb4b	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
238	ku	9d8d3b6e-1131-402f-9955-b7317b4beb4b	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
239	ar	9d8e97c3-363b-458b-8f43-664f20234a56	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
240	ku	9d8e97c3-363b-458b-8f43-664f20234a56	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
241	ar	9d907043-6ca9-4616-a9a7-56a7b35700db	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
242	ku	9d907043-6ca9-4616-a9a7-56a7b35700db	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
243	ar	dbf276c2-cdf9-44b6-97b0-14c5a8065c9f	"Acorn\\User\\Models\\UserGroup	{"name":"ايروس قزشو لامشل ةيتاذلا ةرادلإا يف ةيعامتجلاا ةلادعلا سلجم"}
244	ar	a2168564-34e2-4a09-a3eb-3a806f08e437	"Acorn\\User\\Models\\UserGroup	{"name":"ايرىس قزشو لامشن تيتاذنا ةرادلإا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}
245	ar	7aac8fe4-09cc-439f-8b70-3861dbfd79f4	"Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
246	ar	5b54136d-a4a2-4f02-a5bb-723c92252d6f	"Acorn\\User\\Models\\UserGroup	{"name":"تقزنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
247	ar	ad4a6dbe-fb58-4a5f-9297-5d604b36537c	"Acorn\\User\\Models\\UserGroup	{"name":"ثازفنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
248	ar	2f6ef2be-246c-48f7-9f83-b62b8eae7e39	"Acorn\\User\\Models\\UserGroup	{"name":"روشنا زيد يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
249	ar	a20378bc-17a3-46f3-bb9a-0909df637985	"Acorn\\User\\Models\\UserGroup	{"name":"جبنم يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
250	ar	3b91acb1-1db8-4b07-9720-51f884623bc3	"Acorn\\User\\Models\\UserGroup	{"name":"هيزفع يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
251	ar	def87161-ead8-4846-b1b0-fd3413f1c84e	"Acorn\\User\\Models\\UserGroup	{"name":"تقبطنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
252	ar	6af83dd7-0238-49dd-a168-9eaf14145b9b	"Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}
253	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"هم فنأتي ،ةزيشجنا يف تيعامتجلاا تنادعنا سهجم"}
254	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"سهجمنا تسائر"}
255	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"ثابايننا تنجن"}
256	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"يئاضقنا شيتفتنا تنجن"}
257	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"حهصنا تنجن"}
258	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"ذيفنتنا تنجن"}
259	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"يرادلإاو ينامنا بتكمنا"}
260	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعنا سهجمن تعباتنا ثاباينناو هيواودنا"}
261	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"ىهشماق يف تيعامتجلاا تنادعنا ناىيد"}
262	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"تكسحنا يف تيعامتجلاا تنادعنا ناىيد"}
263	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"هيبسبزت يف تيعامتجلاا تنادعنا ناىيد"}
264	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"هيسابرد يف تيعامتجلاا تنادعنا ناىيد"}
265	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"ادىماع يف تيعامتجلاا تنادعنا ناىيد"}
266	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"زمت مت يف تيعامتجلاا تنادعنا ناىيد"}
267	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"يدادشنا يف تيعامتجلاا تنادعنا ناىيد"}
268	ar	2a94894a-43d6-4132-b832-e52cabc35205	"Acorn\\User\\Models\\UserGroup	{"name":"يكن يكزك يف تيعامتجلاا تنادعنا ناىيد"}
269	ar	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	"Acorn\\User\\Models\\UserGroup	{"name":"كزيد يف تيعامتجلاا تنادعنا ناىيد"}
270	ar	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	"Acorn\\User\\Models\\UserGroup	{"name":"ناكرس يف تماعنا تبايننا"}
271	ar	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	"Acorn\\User\\Models\\UserGroup	{"name":"كازب مت يف تماعنا تبايننا"}
272	ar	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	"Acorn\\User\\Models\\UserGroup	{"name":"لىهنا يف تماعنا تبايننا"}
273	ar	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	"Acorn\\User\\Models\\UserGroup	{"name":"سيمح مت يف تماعنا تبايننا"}
274	ar	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	"Acorn\\User\\Models\\UserGroup	{"name":"اغآ مج يف تماعنا تبايننا"}
275	ar	d9209dd1-4769-41bd-ab05-9e2d4d4612e9	"Acorn\\User\\Models\\UserGroup	{"name":"زجىك مت يف تماعنا تبايننا"}
276	ar	80adc0a9-905d-41ce-9b81-27f3fdb74061	"Acorn\\User\\Models\\UserGroup	{"name":"ايروس قزشو لامشل ةيتاذلا ةرادلإا يف ةيعامتجلاا ةلادعلا سلجم"}
277	ar	fa982c23-4402-4e07-a7d4-c9314249feb4	"Acorn\\User\\Models\\UserGroup	{"name":"ايرىس قزشو لامشن تيتاذنا ةرادلإا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}
278	ar	6d345b4f-204e-4e42-af1f-8c9b4caff78f	"Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
279	ar	2208815c-9803-4260-9b32-bed1a5b0fe26	"Acorn\\User\\Models\\UserGroup	{"name":"تقزنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
280	ar	fb84a457-f6f2-450c-bb25-d7aa101147b7	"Acorn\\User\\Models\\UserGroup	{"name":"ثازفنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
281	ar	31e74742-5445-4d76-ae44-c2cd37395f41	"Acorn\\User\\Models\\UserGroup	{"name":"روشنا زيد يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
282	ar	224a0c53-d5b2-4ab7-847b-343e432b94b6	"Acorn\\User\\Models\\UserGroup	{"name":"جبنم يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
283	ar	989b56ae-52b5-43ea-887d-758d93ef8bb3	"Acorn\\User\\Models\\UserGroup	{"name":"هيزفع يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
284	ar	128e17da-ffda-4a49-b0a5-901d20a90ae7	"Acorn\\User\\Models\\UserGroup	{"name":"تقبطنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
285	ar	fa0d70c3-4427-42df-8943-d09eb2ec343d	"Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}
286	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"هم فنأتي ،ةزيشجنا يف تيعامتجلاا تنادعنا سهجم"}
287	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"سهجمنا تسائر"}
288	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"ثابايننا تنجن"}
289	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"يئاضقنا شيتفتنا تنجن"}
290	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"حهصنا تنجن"}
291	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"ذيفنتنا تنجن"}
292	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"يرادلإاو ينامنا بتكمنا"}
293	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعنا سهجمن تعباتنا ثاباينناو هيواودنا"}
294	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"ىهشماق يف تيعامتجلاا تنادعنا ناىيد"}
295	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"تكسحنا يف تيعامتجلاا تنادعنا ناىيد"}
296	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"هيبسبزت يف تيعامتجلاا تنادعنا ناىيد"}
297	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"هيسابرد يف تيعامتجلاا تنادعنا ناىيد"}
298	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"ادىماع يف تيعامتجلاا تنادعنا ناىيد"}
299	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"زمت مت يف تيعامتجلاا تنادعنا ناىيد"}
300	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"يدادشنا يف تيعامتجلاا تنادعنا ناىيد"}
301	ar	2d5a8b54-033a-40fc-8502-85b738aea2e8	"Acorn\\User\\Models\\UserGroup	{"name":"يكن يكزك يف تيعامتجلاا تنادعنا ناىيد"}
302	ar	fd835492-6a72-4dfd-a4c4-1762f41efb50	"Acorn\\User\\Models\\UserGroup	{"name":"كزيد يف تيعامتجلاا تنادعنا ناىيد"}
303	ar	fd835492-6a72-4dfd-a4c4-1762f41efb50	"Acorn\\User\\Models\\UserGroup	{"name":"ناكرس يف تماعنا تبايننا"}
304	ar	fd835492-6a72-4dfd-a4c4-1762f41efb50	"Acorn\\User\\Models\\UserGroup	{"name":"كازب مت يف تماعنا تبايننا"}
305	ar	fd835492-6a72-4dfd-a4c4-1762f41efb50	"Acorn\\User\\Models\\UserGroup	{"name":"لىهنا يف تماعنا تبايننا"}
306	ar	fd835492-6a72-4dfd-a4c4-1762f41efb50	"Acorn\\User\\Models\\UserGroup	{"name":"سيمح مت يف تماعنا تبايننا"}
307	ar	fd835492-6a72-4dfd-a4c4-1762f41efb50	"Acorn\\User\\Models\\UserGroup	{"name":"اغآ مج يف تماعنا تبايننا"}
308	ar	fd835492-6a72-4dfd-a4c4-1762f41efb50	"Acorn\\User\\Models\\UserGroup	{"name":"زجىك مت يف تماعنا تبايننا"}
309	ar	64a9f07a-80d7-40aa-aa5f-33bf0f049535	"Acorn\\User\\Models\\UserGroup	{"name":"ايروس قزشو لامشل ةيتاذلا ةرادلإا يف ةيعامتجلاا ةلادعلا سلجم"}
310	ar	0758f618-eeee-4313-b4b2-ed386351b0c7	"Acorn\\User\\Models\\UserGroup	{"name":"ايرىس قزشو لامشن تيتاذنا ةرادلإا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}
311	ar	c693f0cd-db03-463b-bba2-ed99333aa3ee	"Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
312	ar	05423cb7-cb03-4f5a-961e-ce40d40f687a	"Acorn\\User\\Models\\UserGroup	{"name":"تقزنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
313	ar	2f29c8ec-6224-4a29-bf82-a0ec26e3f07e	"Acorn\\User\\Models\\UserGroup	{"name":"ثازفنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
314	ar	4f801d1f-43e3-4dfc-bab3-27c3c6cc3d3b	"Acorn\\User\\Models\\UserGroup	{"name":"روشنا زيد يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
315	ar	7da813ab-6bd9-481a-b1e7-bd214a23c2ad	"Acorn\\User\\Models\\UserGroup	{"name":"جبنم يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
316	ar	39b70dc8-ad16-478a-86dc-6f22596ab6d6	"Acorn\\User\\Models\\UserGroup	{"name":"هيزفع يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
317	ar	51730a78-5d8a-4d35-9721-7b2d5de315b5	"Acorn\\User\\Models\\UserGroup	{"name":"تقبطنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
318	ar	e2715cc6-dc09-4546-be62-6c6bdd68dcc8	"Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}
319	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"هم فنأتي ،ةزيشجنا يف تيعامتجلاا تنادعنا سهجم"}
320	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"سهجمنا تسائر"}
321	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"ثابايننا تنجن"}
322	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"يئاضقنا شيتفتنا تنجن"}
323	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"حهصنا تنجن"}
324	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"ذيفنتنا تنجن"}
325	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"يرادلإاو ينامنا بتكمنا"}
326	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعنا سهجمن تعباتنا ثاباينناو هيواودنا"}
327	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"ىهشماق يف تيعامتجلاا تنادعنا ناىيد"}
328	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"تكسحنا يف تيعامتجلاا تنادعنا ناىيد"}
329	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"هيبسبزت يف تيعامتجلاا تنادعنا ناىيد"}
330	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"هيسابرد يف تيعامتجلاا تنادعنا ناىيد"}
331	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"ادىماع يف تيعامتجلاا تنادعنا ناىيد"}
332	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"زمت مت يف تيعامتجلاا تنادعنا ناىيد"}
333	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"يدادشنا يف تيعامتجلاا تنادعنا ناىيد"}
334	ar	3f351fc9-aea2-4dfb-b41f-2cbd3374f8fe	"Acorn\\User\\Models\\UserGroup	{"name":"يكن يكزك يف تيعامتجلاا تنادعنا ناىيد"}
335	ar	07f887d9-13c7-49fa-b3d3-2fe42f9a0ca6	"Acorn\\User\\Models\\UserGroup	{"name":"كزيد يف تيعامتجلاا تنادعنا ناىيد"}
336	ar	07f887d9-13c7-49fa-b3d3-2fe42f9a0ca6	"Acorn\\User\\Models\\UserGroup	{"name":"ناكرس يف تماعنا تبايننا"}
337	ar	07f887d9-13c7-49fa-b3d3-2fe42f9a0ca6	"Acorn\\User\\Models\\UserGroup	{"name":"كازب مت يف تماعنا تبايننا"}
338	ar	07f887d9-13c7-49fa-b3d3-2fe42f9a0ca6	"Acorn\\User\\Models\\UserGroup	{"name":"لىهنا يف تماعنا تبايننا"}
339	ar	07f887d9-13c7-49fa-b3d3-2fe42f9a0ca6	"Acorn\\User\\Models\\UserGroup	{"name":"سيمح مت يف تماعنا تبايننا"}
340	ar	07f887d9-13c7-49fa-b3d3-2fe42f9a0ca6	"Acorn\\User\\Models\\UserGroup	{"name":"اغآ مج يف تماعنا تبايننا"}
341	ar	07f887d9-13c7-49fa-b3d3-2fe42f9a0ca6	"Acorn\\User\\Models\\UserGroup	{"name":"زجىك مت يف تماعنا تبايننا"}
342	ar	30d93c8e-ee66-44ea-8c73-fd0d032af319	Acorn\\User\\Models\\UserGroup	{"name":"ايروس قزشو لامشل ةيتاذلا ةرادلإا يف ةيعامتجلاا ةلادعلا سلجم"}
343	ar	5ed0afd7-f025-43ef-82d7-a8229ca0d4af	Acorn\\User\\Models\\UserGroup	{"name":"ايرىس قزشو لامشن تيتاذنا ةرادلإا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}
344	ar	96fd3444-424c-4348-8aee-b6037e98cd3f	Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
345	ar	4491670f-b9c1-44df-a8cd-f47b85464625	Acorn\\User\\Models\\UserGroup	{"name":"تقزنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
346	ar	1e382fe2-7d64-4398-aa5d-e7444c8b9fe6	Acorn\\User\\Models\\UserGroup	{"name":"ثازفنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
347	ar	f2e202b2-62a5-46aa-bfdd-98b7806a558c	Acorn\\User\\Models\\UserGroup	{"name":"روشنا زيد يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
348	ar	4d4e0670-f7f4-4ab9-95b6-74e1a3bac1ad	Acorn\\User\\Models\\UserGroup	{"name":"جبنم يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
349	ar	8d7d0361-2e9f-40bc-8aa4-559d8f70c605	Acorn\\User\\Models\\UserGroup	{"name":"هيزفع يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
350	ar	8c832e96-70ab-40b2-bbba-01c6cb6695c1	Acorn\\User\\Models\\UserGroup	{"name":"تقبطنا يف تيعامتجلاا تنادعهن ةأزمنا سهجمو تيعامتجلاا تنادعنا سهجم"}
351	ar	cc8e599e-f8e1-4467-9125-d4e1020d284c	Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعهن ةأزمنا سهجم"}
352	ar	b67909bf-af9c-44e6-9354-77b25f777aa7	Acorn\\User\\Models\\UserGroup	{"name":"هم فنأتي ،ةزيشجنا يف تيعامتجلاا تنادعنا سهجم"}
353	ar	0952d96e-0392-4f82-9687-44b88d2f71c3	Acorn\\User\\Models\\UserGroup	{"name":"سهجمنا تسائر"}
354	ar	edd91c15-116c-4b81-ba18-5095b355bcad	Acorn\\User\\Models\\UserGroup	{"name":"ثابايننا تنجن"}
355	ar	89adc57e-be52-4af6-8282-1c5d8bc2f103	Acorn\\User\\Models\\UserGroup	{"name":"يئاضقنا شيتفتنا تنجن"}
356	ar	e6f8a708-c4d3-4396-bef8-8d81eed86ea0	Acorn\\User\\Models\\UserGroup	{"name":"حهصنا تنجن"}
357	ar	0a556562-dc1e-4370-bf07-1ba41c22bd18	Acorn\\User\\Models\\UserGroup	{"name":"ذيفنتنا تنجن"}
358	ar	9999365c-34b7-4ff4-a36b-646405a9d947	Acorn\\User\\Models\\UserGroup	{"name":"يرادلإاو ينامنا بتكمنا"}
359	ar	3f5517b1-7a35-40c8-88ba-fd86811c7a31	Acorn\\User\\Models\\UserGroup	{"name":"ةزيشجنا يف تيعامتجلاا تنادعنا سهجمن تعباتنا ثاباينناو هيواودنا"}
360	ar	78bdd172-5173-4bf3-a044-85f67c74a990	Acorn\\User\\Models\\UserGroup	{"name":"ىهشماق يف تيعامتجلاا تنادعنا ناىيد"}
361	ar	20983187-a73f-4c7d-ae18-af363cb3b80f	Acorn\\User\\Models\\UserGroup	{"name":"تكسحنا يف تيعامتجلاا تنادعنا ناىيد"}
362	ar	6dddede5-0ef6-4f33-b9dd-ca1295d8247c	Acorn\\User\\Models\\UserGroup	{"name":"هيبسبزت يف تيعامتجلاا تنادعنا ناىيد"}
363	ar	ec893bb1-27da-43ac-a4b4-a8960bba3dde	Acorn\\User\\Models\\UserGroup	{"name":"هيسابرد يف تيعامتجلاا تنادعنا ناىيد"}
364	ar	f689895a-9c43-4ba6-8459-3c60dfbf8b56	Acorn\\User\\Models\\UserGroup	{"name":"ادىماع يف تيعامتجلاا تنادعنا ناىيد"}
365	ar	e5e95b8f-dffd-4ed5-9c17-c87f62bebd0d	Acorn\\User\\Models\\UserGroup	{"name":"زمت مت يف تيعامتجلاا تنادعنا ناىيد"}
366	ar	19546528-f290-4a40-94d1-f886609a8b94	Acorn\\User\\Models\\UserGroup	{"name":"يدادشنا يف تيعامتجلاا تنادعنا ناىيد"}
367	ar	9d3ad872-fc19-47fa-b51b-6262c77aeaaf	Acorn\\User\\Models\\UserGroup	{"name":"يكن يكزك يف تيعامتجلاا تنادعنا ناىيد"}
368	ar	2a849d98-35b5-4d84-9890-89a02efd49c6	Acorn\\User\\Models\\UserGroup	{"name":"كزيد يف تيعامتجلاا تنادعنا ناىيد"}
369	ar	56ebd118-2837-479e-a052-4b3b721b7083	Acorn\\User\\Models\\UserGroup	{"name":"ناكرس يف تماعنا تبايننا"}
370	ar	3bbf645a-8e02-4c28-88a3-f386567fe2be	Acorn\\User\\Models\\UserGroup	{"name":"كازب مت يف تماعنا تبايننا"}
371	ar	93e4bc76-377e-4f0b-a57a-4a14518fa93e	Acorn\\User\\Models\\UserGroup	{"name":"لىهنا يف تماعنا تبايننا"}
372	ar	c5adb730-1968-400e-af3d-37c8d32d8433	Acorn\\User\\Models\\UserGroup	{"name":"سيمح مت يف تماعنا تبايننا"}
373	ar	9617afcd-11c8-481b-95ba-112f600eef3b	Acorn\\User\\Models\\UserGroup	{"name":"اغآ مج يف تماعنا تبايننا"}
374	ar	738b0e85-0214-42e4-88fa-b6649e2d0a47	Acorn\\User\\Models\\UserGroup	{"name":"زجىك مت يف تماعنا تبايننا"}
375	ar	9d948d82-68ae-46f0-94bb-3b2ef6604909	Acorn\\Criminal\\Models\\Crime	{"name":""}
376	ku	9d948d82-68ae-46f0-94bb-3b2ef6604909	Acorn\\Criminal\\Models\\Crime	{"name":""}
377	ar	9d969994-90cd-493b-a412-61a12d036667	Acorn\\Criminal\\Models\\SentenceType	{"name":""}
378	ku	9d969994-90cd-493b-a412-61a12d036667	Acorn\\Criminal\\Models\\SentenceType	{"name":""}
379	ar	9d9cdf96-9067-4f77-ab1a-662a8bf279be	Acorn\\Criminal\\Models\\DetentionReason	{"name":"","description":""}
380	ku	9d9cdf96-9067-4f77-ab1a-662a8bf279be	Acorn\\Criminal\\Models\\DetentionReason	{"name":"","description":""}
381	ar	9d9cdfa9-4611-4cc1-b2f1-e97a7b40b2b7	Acorn\\Criminal\\Models\\DetentionMethod	{"name":"","description":""}
382	ku	9d9cdfa9-4611-4cc1-b2f1-e97a7b40b2b7	Acorn\\Criminal\\Models\\DetentionMethod	{"name":"","description":""}
383	ar	9d9d3099-ce01-4042-9913-96c66b2aa2ef	Acorn\\Criminal\\Models\\Crime	{"name":""}
384	ku	9d9d3099-ce01-4042-9913-96c66b2aa2ef	Acorn\\Criminal\\Models\\Crime	{"name":""}
385	ar	9da6bd4b-890c-4051-87a1-0f92f5a2c0ed	Acorn\\Justice\\Models\\WarrantType	{"name":"","description":""}
386	ku	9da6bd4b-890c-4051-87a1-0f92f5a2c0ed	Acorn\\Justice\\Models\\WarrantType	{"name":"","description":""}
390	ar	9dc8c49d-5929-415e-9895-4303868845a7	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
391	ku	9dc8c49d-5929-415e-9895-4303868845a7	Acorn\\Criminal\\Models\\CrimeType	{"name":""}
392	ar	9dd0efee-d27e-455a-b976-28a5eb9e9c98	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
393	ku	9dd0efee-d27e-455a-b976-28a5eb9e9c98	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
394	ar	9dd10958-54be-486c-965c-413696946e89	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
395	ku	9dd10958-54be-486c-965c-413696946e89	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
396	ar	9dd10a38-cef5-456e-8c76-c86eb1ff453e	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
397	ku	9dd10a38-cef5-456e-8c76-c86eb1ff453e	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
398	ar	9dd140ca-6e64-4ed2-a53f-dedf06753dd5	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
399	ku	9dd140ca-6e64-4ed2-a53f-dedf06753dd5	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
400	ar	9dd1a197-ac8a-4469-a6da-e57250c63aae	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
401	ku	9dd1a197-ac8a-4469-a6da-e57250c63aae	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
402	ar	9dd2ff0e-aedd-47d6-80c6-0105effc416e	Acorn\\Lojistiks\\Models\\Product	{"name":""}
403	ku	9dd2ff0e-aedd-47d6-80c6-0105effc416e	Acorn\\Lojistiks\\Models\\Product	{"name":""}
404	ar	9dd30203-f755-4a28-9dea-db9b2fafe4a8	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
405	ku	9dd30203-f755-4a28-9dea-db9b2fafe4a8	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
406	ar	9dd30556-2c17-4c79-a54d-db6f5e017ab6	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
407	ku	9dd30556-2c17-4c79-a54d-db6f5e017ab6	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
408	ar	9dd3057d-620c-4a12-b2df-72f2578cad7a	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
409	ku	9dd3057d-620c-4a12-b2df-72f2578cad7a	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
410	ar	9dd30591-7e88-4565-9f33-325297ff4bc6	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
411	ku	9dd30591-7e88-4565-9f33-325297ff4bc6	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
412	ar	9dd305dc-2bf2-46aa-a73e-fce8ab7c0610	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
413	ku	9dd305dc-2bf2-46aa-a73e-fce8ab7c0610	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
414	ar	9dd30757-898e-4a42-b5bc-7434f9c80197	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
415	ku	9dd30757-898e-4a42-b5bc-7434f9c80197	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
416	ar	9dd30846-d17e-4e62-aa0f-13a82b1e133b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
417	ku	9dd30846-d17e-4e62-aa0f-13a82b1e133b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
418	ar	9dd30bfe-b21c-4f87-9dca-cc2da7ad6d3d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
419	ku	9dd30bfe-b21c-4f87-9dca-cc2da7ad6d3d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
420	ar	9dd30c2c-237d-402a-9d2a-9b5c8a933f52	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
421	ku	9dd30c2c-237d-402a-9d2a-9b5c8a933f52	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
422	ar	9dd31d9f-875e-4588-a9e3-8be4a963eb41	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
423	ku	9dd31d9f-875e-4588-a9e3-8be4a963eb41	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
424	ar	9dd31dbe-a2cd-4e4e-8719-d1a4c9391ecd	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
425	ku	9dd31dbe-a2cd-4e4e-8719-d1a4c9391ecd	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
426	ar	9dd31dc8-a4e4-46bf-b5cc-2ed7c2b20094	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
427	ku	9dd31dc8-a4e4-46bf-b5cc-2ed7c2b20094	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
428	ar	9dd31e00-e5d8-434d-bf61-0ee63b1eb0ca	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
429	ku	9dd31e00-e5d8-434d-bf61-0ee63b1eb0ca	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
430	ar	9dd31e83-32ed-490d-9100-da68362e83ca	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
431	ku	9dd31e83-32ed-490d-9100-da68362e83ca	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
432	ar	9dd31e95-b2bb-4ddb-9838-26132d7b9867	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
433	ku	9dd31e95-b2bb-4ddb-9838-26132d7b9867	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
434	ar	9dd31f90-4aba-48ad-a580-328a5e2fc0a0	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
435	ku	9dd31f90-4aba-48ad-a580-328a5e2fc0a0	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
436	ar	9dd32085-7f82-480d-be30-bfcaa04c1f03	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
437	ku	9dd32085-7f82-480d-be30-bfcaa04c1f03	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
438	ar	9de732bc-ef2c-417c-b625-4431e9c7d76a	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
439	ku	9de732bc-ef2c-417c-b625-4431e9c7d76a	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
440	ar	9de733ed-9e70-4567-9579-7d2aa8f18246	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
441	ku	9de733ed-9e70-4567-9579-7d2aa8f18246	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
442	ar	9df2fe7e-85e2-4fa8-bb09-ae31ffa3ea1e	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
443	ku	9df2fe7e-85e2-4fa8-bb09-ae31ffa3ea1e	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
444	ar	9df3078f-b876-48fb-9c86-059106e6298d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
445	ku	9df3078f-b876-48fb-9c86-059106e6298d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
446	ar	9e0d3832-6e6b-4e4e-b0d1-152951861b80	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
447	ku	9e0d3832-6e6b-4e4e-b0d1-152951861b80	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
448	ar	9e13629c-70a7-4a58-b9b1-01990fcee59f	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
449	ku	9e13629c-70a7-4a58-b9b1-01990fcee59f	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
450	ar	9e136f6d-be1f-4627-8d5a-71b831b00c7b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
451	ku	9e136f6d-be1f-4627-8d5a-71b831b00c7b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
452	ar	9e137a78-b870-4461-b5a9-dcebc6472ee8	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
453	ku	9e137a78-b870-4461-b5a9-dcebc6472ee8	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
454	ar	9e137abb-6768-42b7-9e95-eeece838d961	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
455	ku	9e137abb-6768-42b7-9e95-eeece838d961	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
456	ar	9e137b09-2d83-4aa0-8fa9-8c3dcb464143	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
457	ku	9e137b09-2d83-4aa0-8fa9-8c3dcb464143	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
458	ar	9e137e94-72b8-40f2-8808-b9c9b711af31	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
459	ku	9e137e94-72b8-40f2-8808-b9c9b711af31	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
460	ar	9e138105-d410-4cad-be90-2f5d9a01b0f3	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
461	ku	9e138105-d410-4cad-be90-2f5d9a01b0f3	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
462	ar	9e13810c-c00e-40e9-8602-99a2d51dbfc3	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
463	ku	9e13810c-c00e-40e9-8602-99a2d51dbfc3	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
464	ar	9e194c73-49a4-456c-9cac-3207a16ed36f	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
465	ku	9e194c73-49a4-456c-9cac-3207a16ed36f	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
466	ar	9e1961fa-711e-46b0-904f-312dfdcb3b82	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
467	ku	9e1961fa-711e-46b0-904f-312dfdcb3b82	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
468	ar	9e1971ac-aff4-4495-a67c-6ec1cd1d05a5	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
469	ku	9e1971ac-aff4-4495-a67c-6ec1cd1d05a5	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
470	ar	9e199ee7-6c1f-422c-a68d-e0f5f0ee93ea	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
471	ku	9e199ee7-6c1f-422c-a68d-e0f5f0ee93ea	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
474	ar	9e19a766-221d-4f83-94d1-5445a86e0e4d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
475	ku	9e19a766-221d-4f83-94d1-5445a86e0e4d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
472	ar	9e199f12-774c-4131-9d6c-a68e1aac5f42	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
473	ku	9e199f12-774c-4131-9d6c-a68e1aac5f42	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
476	ar	9e19a980-a2f6-4f49-b430-a403b3a07794	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
477	ku	9e19a980-a2f6-4f49-b430-a403b3a07794	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
478	ar	9e19aa54-0410-4d4f-8686-b3b946b1707d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
479	ku	9e19aa54-0410-4d4f-8686-b3b946b1707d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
481	ku	9e19aa80-99ed-4023-b728-9f559adc7b10	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
480	ar	9e19aa80-99ed-4023-b728-9f559adc7b10	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
482	ar	9e19aae0-21a1-44d4-b3f8-09e79cb752bc	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
483	ku	9e19aae0-21a1-44d4-b3f8-09e79cb752bc	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
484	ar	9e19b1ea-6d08-4c2d-af71-c6f9744ded75	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
485	ku	9e19b1ea-6d08-4c2d-af71-c6f9744ded75	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
486	ar	9e19b1f7-6388-406f-9527-3435d1148874	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
487	ku	9e19b1f7-6388-406f-9527-3435d1148874	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
488	ar	9e19b899-66e7-4e55-810d-ee74a5ee962b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
489	ku	9e19b899-66e7-4e55-810d-ee74a5ee962b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
490	ar	9e1a0319-6cd8-4208-8d3a-95a3834cd70b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
491	ku	9e1a0319-6cd8-4208-8d3a-95a3834cd70b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
492	ar	9e1a048e-f5d8-46a2-98ae-2a261f1e8168	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
493	ku	9e1a048e-f5d8-46a2-98ae-2a261f1e8168	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
494	ar	9e1a0bca-4f20-4d41-a4f4-c7375dec9e28	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
495	ku	9e1a0bca-4f20-4d41-a4f4-c7375dec9e28	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
496	ar	9e1a0c39-e273-4ff1-871f-322b6e11570e	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
497	ku	9e1a0c39-e273-4ff1-871f-322b6e11570e	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
498	ar	9e1a0cab-d6f8-44b4-aabe-5a036a2f5b71	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
499	ku	9e1a0cab-d6f8-44b4-aabe-5a036a2f5b71	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
500	ar	9e1d2e8b-e775-492a-b3be-b9574c84dbd1	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
501	ku	9e1d2e8b-e775-492a-b3be-b9574c84dbd1	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
502	ar	9e1d31a9-02dd-4cdc-b72e-1da5a71f4505	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
503	ku	9e1d31a9-02dd-4cdc-b72e-1da5a71f4505	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
504	ar	9e1d3326-5693-48ad-b84a-2d6fe7c59540	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
505	ku	9e1d3326-5693-48ad-b84a-2d6fe7c59540	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
506	ar	9e1d33f6-7475-45ef-a261-95034706d93d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
507	ku	9e1d33f6-7475-45ef-a261-95034706d93d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
508	ar	9e1d36d9-bb73-4321-98a7-68793a8a8a80	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
509	ku	9e1d36d9-bb73-4321-98a7-68793a8a8a80	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
510	ar	9e1d3a02-2366-4c30-a0cc-4f0eabfc26e0	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
511	ku	9e1d3a02-2366-4c30-a0cc-4f0eabfc26e0	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
512	ar	9e1d4047-68ec-4e27-aa62-20e7eabde552	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
513	ku	9e1d4047-68ec-4e27-aa62-20e7eabde552	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
514	ar	9e1d4387-8569-4e57-b022-cbab7660bc94	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
515	ku	9e1d4387-8569-4e57-b022-cbab7660bc94	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
516	ar	9e1d43be-e992-47c0-a9bd-2d8599a0d51b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
517	ku	9e1d43be-e992-47c0-a9bd-2d8599a0d51b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
518	ar	9e1d4491-4224-4dea-b99c-62d1c58600fe	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
519	ku	9e1d4491-4224-4dea-b99c-62d1c58600fe	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
520	ar	9e1d4b87-a6b6-48f6-a5e3-e1e5a99082da	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
521	ku	9e1d4b87-a6b6-48f6-a5e3-e1e5a99082da	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
522	ar	9e1d578e-0b29-4b38-9be6-daa31913873c	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
523	ku	9e1d578e-0b29-4b38-9be6-daa31913873c	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
524	ar	9e1d5e1b-c447-460c-afa5-b4e32876875e	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
525	ku	9e1d5e1b-c447-460c-afa5-b4e32876875e	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
526	ar	9e1d68f8-6293-4c8b-b72e-def4f489deee	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
527	ku	9e1d68f8-6293-4c8b-b72e-def4f489deee	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
528	ar	9e1d6cb6-3529-45c2-9fe3-deea66909d3a	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
529	ku	9e1d6cb6-3529-45c2-9fe3-deea66909d3a	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
530	ar	9e1d780f-a8fe-41a1-af9b-3c9aaeb88c07	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
531	ku	9e1d780f-a8fe-41a1-af9b-3c9aaeb88c07	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
532	ar	9e1d7d3c-6891-4555-ac5b-2143d085d7a3	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
533	ku	9e1d7d3c-6891-4555-ac5b-2143d085d7a3	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
534	ar	9e1d7f6a-eb79-4c4a-bdf3-cdae2d8d7b8f	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
535	ku	9e1d7f6a-eb79-4c4a-bdf3-cdae2d8d7b8f	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
536	ar	9e1d8393-fceb-45b7-b77a-eacaa4bab971	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
537	ku	9e1d8393-fceb-45b7-b77a-eacaa4bab971	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
538	ar	9e1d860e-2a4c-44d5-ab81-3ee000e7a368	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
539	ku	9e1d860e-2a4c-44d5-ab81-3ee000e7a368	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
540	ar	9e1d8678-ac95-4b2a-93cf-067635745063	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
541	ku	9e1d8678-ac95-4b2a-93cf-067635745063	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
542	ar	9e1d8890-2439-4f29-bac4-dfa1e1e75620	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
543	ku	9e1d8890-2439-4f29-bac4-dfa1e1e75620	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
544	ar	9e1d88ee-2c0e-4398-b8a8-d0c390eb917b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
545	ku	9e1d88ee-2c0e-4398-b8a8-d0c390eb917b	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
546	ar	9e1d895b-ba2d-4740-8d7b-5056102baff6	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
547	ku	9e1d895b-ba2d-4740-8d7b-5056102baff6	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
548	ar	9e1df121-6258-4226-99c5-63035635ca3d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
549	ku	9e1df121-6258-4226-99c5-63035635ca3d	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
550	ar	9e1e0f47-e8a2-4b36-b904-ce2a9613a69f	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
551	ku	9e1e0f47-e8a2-4b36-b904-ce2a9613a69f	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
552	ar	9e1e116b-b8f9-4b67-aaef-cb272da4efb9	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
553	ku	9e1e116b-b8f9-4b67-aaef-cb272da4efb9	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
554	ar	9e1e1445-de5e-4d4f-8962-e850df21afb5	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
555	ku	9e1e1445-de5e-4d4f-8962-e850df21afb5	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
556	ar	9e1e1808-4d06-41ae-9600-ac0a043ab80c	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
557	ku	9e1e1808-4d06-41ae-9600-ac0a043ab80c	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
558	ar	9e1e18f9-e64b-424b-ac0a-7addf1355c71	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
559	ku	9e1e18f9-e64b-424b-ac0a-7addf1355c71	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
560	ar	9e1e1982-5e15-4ef9-ad22-b922692d2af9	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
561	ku	9e1e1982-5e15-4ef9-ad22-b922692d2af9	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
562	ar	9e1e1b2f-3ab7-41cc-a85a-4b3c64ba82e7	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
563	ku	9e1e1b2f-3ab7-41cc-a85a-4b3c64ba82e7	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
564	ar	9e1e1b63-6d37-42db-a793-55d56bb39b5e	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
565	ku	9e1e1b63-6d37-42db-a793-55d56bb39b5e	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
566	ar	9e1e1b9d-16f4-46a5-b0e5-7055661ae0cb	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
567	ku	9e1e1b9d-16f4-46a5-b0e5-7055661ae0cb	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
568	ar	9e1e1bf3-3595-4e9a-995d-eb08519d510c	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
569	ku	9e1e1bf3-3595-4e9a-995d-eb08519d510c	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
570	ar	9e1e1c29-539c-40b5-859f-e8d6ab348f97	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
571	ku	9e1e1c29-539c-40b5-859f-e8d6ab348f97	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
572	ar	9e1e1d00-933a-4cad-bbd8-879926757a5a	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
573	ku	9e1e1d00-933a-4cad-bbd8-879926757a5a	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
574	ar	9e1e1d0e-9f6a-4812-9bc3-f36c613a8aa2	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
575	ku	9e1e1d0e-9f6a-4812-9bc3-f36c613a8aa2	Acorn\\Justice\\Models\\LegalcaseIdentifier	{"name":""}
576	ar	9e1e1d1a-ee26-4ca5-859f-156a2ea2288a	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
577	ku	9e1e1d1a-ee26-4ca5-859f-156a2ea2288a	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
578	ar	9e1e1d65-ac22-4bec-9453-b7a045d764ec	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
579	ku	9e1e1d65-ac22-4bec-9453-b7a045d764ec	Acorn\\Justice\\Models\\ScannedDocument	{"name":""}
580	ar	9d6e2cee-16f6-4e6b-beaf-c2c4d2677f75	Acorn\\Criminal\\Models\\Legalcase	{"description":""}
581	ku	9d6e2cee-16f6-4e6b-beaf-c2c4d2677f75	Acorn\\Criminal\\Models\\Legalcase	{"description":""}
582	ar	9e1f4c64-b19c-4d3c-a192-b0dda9156305	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
583	ku	9e1f4c64-b19c-4d3c-a192-b0dda9156305	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
584	ar	9d8c5e72-ca3e-43e8-9a70-aee628487f06	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
585	ku	9d8c5e72-ca3e-43e8-9a70-aee628487f06	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
586	ar	9e1f8600-cb85-4b1d-b9ab-88e27ca9166f	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
587	ku	9e1f8600-cb85-4b1d-b9ab-88e27ca9166f	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
588	ar	9e1f88e3-8a24-4b89-a09c-14beabc76319	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
589	ku	9e1f88e3-8a24-4b89-a09c-14beabc76319	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
590	ar	9e1f8bfb-ea3b-4335-b65e-0c92c603473a	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
591	ku	9e1f8bfb-ea3b-4335-b65e-0c92c603473a	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
592	ar	9e1f8c58-f150-4a1b-be7d-3e2fee746311	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
593	ku	9e1f8c58-f150-4a1b-be7d-3e2fee746311	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
594	ar	9da0814a-858c-4db6-a642-dbd207749636	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
595	ku	9da0814a-858c-4db6-a642-dbd207749636	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
596	ar	9e1fa3c3-55d4-4f28-84a2-4356919a380e	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
597	ku	9e1fa3c3-55d4-4f28-84a2-4356919a380e	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
598	ar	9e1fa592-7694-4f20-b41e-ee601e1641bd	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
599	ku	9e1fa592-7694-4f20-b41e-ee601e1641bd	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
600	ar	9e1fa5e8-5949-418d-aff8-e8ee3ce2b224	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
601	ku	9e1fa5e8-5949-418d-aff8-e8ee3ce2b224	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
602	ar	9e1fa639-47c8-4a6f-8b0c-39d2b5518d2d	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
603	ku	9e1fa639-47c8-4a6f-8b0c-39d2b5518d2d	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
604	ar	9e212d4f-06f9-4b42-8aa8-042f5ed5eae4	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
605	ku	9e212d4f-06f9-4b42-8aa8-042f5ed5eae4	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
606	ar	9e214b4b-1580-494b-9ab9-499912d8d700	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
607	ku	9e214b4b-1580-494b-9ab9-499912d8d700	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":""}
608	ar	9e214b95-dbd2-4dd2-90e8-e3a89516bd32	Acorn\\Criminal\\Models\\CrimeSentence	{"description":""}
609	ku	9e214b95-dbd2-4dd2-90e8-e3a89516bd32	Acorn\\Criminal\\Models\\CrimeSentence	{"description":""}
610	ar	9e214b9d-9a54-4563-b23a-c2ffef05dfed	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
611	ku	9e214b9d-9a54-4563-b23a-c2ffef05dfed	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
612	ar	9e214bfb-5721-4117-a08c-fbe0282ce0e7	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
613	ku	9e214bfb-5721-4117-a08c-fbe0282ce0e7	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
614	ar	9e218a8b-579f-4afb-b0fa-66a2570bf4b4	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
615	ku	9e218a8b-579f-4afb-b0fa-66a2570bf4b4	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
618	ar	9da4c03e-bc54-4f7d-87e3-d2a0d8c0519d	Acorn\\Criminal\\Models\\DefendantDetention	{"description":""}
619	ku	9da4c03e-bc54-4f7d-87e3-d2a0d8c0519d	Acorn\\Criminal\\Models\\DefendantDetention	{"description":""}
620	ar	9da4d23d-defb-46e5-917b-43e732bcec6f	Acorn\\Criminal\\Models\\DefendantDetention	{"description":""}
621	ku	9da4d23d-defb-46e5-917b-43e732bcec6f	Acorn\\Criminal\\Models\\DefendantDetention	{"description":""}
616	ar	9e218bb3-d452-4d6b-ad8b-8988ecf813b8	Acorn\\Justice\\Models\\ScannedDocument	{"name":"arab","description":""}
617	ku	9e218bb3-d452-4d6b-ad8b-8988ecf813b8	Acorn\\Justice\\Models\\ScannedDocument	{"name":"","description":""}
622	ar	9d8447c4-05b8-43b7-8151-34e2dbaaa286	Acorn\\Criminal\\Models\\LegalcaseRelatedEvent	{"description":""}
623	ku	9d8447c4-05b8-43b7-8151-34e2dbaaa286	Acorn\\Criminal\\Models\\LegalcaseRelatedEvent	{"description":""}
624	ar	9e23cac5-8e35-410f-a7b3-66de83db2a53	Acorn\\Criminal\\Models\\Legalcase	{"description":""}
625	ku	9e23cac5-8e35-410f-a7b3-66de83db2a53	Acorn\\Criminal\\Models\\Legalcase	{"description":""}
626	ar	9e23caeb-45ff-4f3f-9adc-247ba1041523	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
627	ku	9e23caeb-45ff-4f3f-9adc-247ba1041523	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
628	ar	9e2418d8-c254-4d1f-8dc4-d8b6224acc9c	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":"","description":""}
629	ku	9e2418d8-c254-4d1f-8dc4-d8b6224acc9c	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":"","description":""}
630	ar	9e2418f9-7d0d-4513-b1ad-d274015c84d0	Acorn\\Justice\\Models\\ScannedDocument	{"name":"","description":""}
631	ku	9e2418f9-7d0d-4513-b1ad-d274015c84d0	Acorn\\Justice\\Models\\ScannedDocument	{"name":"","description":""}
632	ar	9e242335-5944-4f3f-a8f2-0bf8400d304d	Acorn\\Criminal\\Models\\Crime	{"name":"","description":""}
633	ku	9e242335-5944-4f3f-a8f2-0bf8400d304d	Acorn\\Criminal\\Models\\Crime	{"name":"","description":""}
634	ar	9e242396-12a9-4387-ab25-f428b87115fc	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
635	ku	9e242396-12a9-4387-ab25-f428b87115fc	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
636	ar	9e2423a2-258d-481e-96f8-7b582e0fe533	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
637	ku	9e2423a2-258d-481e-96f8-7b582e0fe533	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
638	ar	9e2423d2-2541-43fb-999f-68ebf0c8c71f	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
639	ku	9e2423d2-2541-43fb-999f-68ebf0c8c71f	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
640	ar	9e2423d9-0e49-43a5-a432-c66d746f12ab	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
641	ku	9e2423d9-0e49-43a5-a432-c66d746f12ab	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
642	ar	9e255bf7-063b-42e4-a4c3-40c7d15051af	Acorn\\Calendar\\Models\\EventStatus	{"name":""}
643	ku	9e255bf7-063b-42e4-a4c3-40c7d15051af	Acorn\\Calendar\\Models\\EventStatus	{"name":""}
644	ar	9e255e16-9917-4e1e-9735-9bc828b1a255	Acorn\\Calendar\\Models\\EventType	{"name":""}
645	ku	9e255e16-9917-4e1e-9735-9bc828b1a255	Acorn\\Calendar\\Models\\EventType	{"name":""}
646	ar	9e279359-2e87-4dc6-93d6-d7637a2e8ad2	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
647	ku	9e279359-2e87-4dc6-93d6-d7637a2e8ad2	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
648	ar	9e279389-b66d-43c2-9665-243936bab3ee	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
649	ku	9e279389-b66d-43c2-9665-243936bab3ee	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
650	ar	9e27942d-52dc-40c8-9c9e-51342e385251	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
651	ku	9e27942d-52dc-40c8-9c9e-51342e385251	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
652	ar	9e27946f-ca70-419a-8d6e-cdd04b25efea	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
653	ku	9e27946f-ca70-419a-8d6e-cdd04b25efea	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
654	ar	9e279793-1359-419e-b38e-90ebfbf70e80	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
655	ku	9e279793-1359-419e-b38e-90ebfbf70e80	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
656	ar	9e279894-8fcb-4c7b-8ca8-84846229febc	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
657	ku	9e279894-8fcb-4c7b-8ca8-84846229febc	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
658	ar	9e27990d-351d-4173-a739-7903f497f27c	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
659	ku	9e27990d-351d-4173-a739-7903f497f27c	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
660	ar	9e279964-5602-4bc2-8497-49c19f5e2e86	Acorn\\Criminal\\Models\\Legalcase	{"description":""}
661	ku	9e279964-5602-4bc2-8497-49c19f5e2e86	Acorn\\Criminal\\Models\\Legalcase	{"description":""}
662	ar	9e27a134-3fcc-42c4-9437-3c291f1da4b8	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
663	ku	9e27a134-3fcc-42c4-9437-3c291f1da4b8	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
664	ar	9e27a15f-e34c-44c1-8d74-1d7592052656	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
665	ku	9e27a15f-e34c-44c1-8d74-1d7592052656	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
666	ar	9e27a223-c1be-48c1-9c7c-5f4023233ec7	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
667	ku	9e27a223-c1be-48c1-9c7c-5f4023233ec7	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
668	ar	9e27a312-e758-4261-847a-f9d4a7849f7e	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
669	ku	9e27a312-e758-4261-847a-f9d4a7849f7e	Acorn\\Criminal\\Models\\CrimeType	{"name":"","description":""}
670	ar	9e2bc3de-c248-414a-ae83-9be0e4d704f6	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
671	ku	9e2bc3de-c248-414a-ae83-9be0e4d704f6	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
672	ar	9e2bc3e9-3418-4004-b902-78e98645c761	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
673	ku	9e2bc3e9-3418-4004-b902-78e98645c761	Acorn\\Criminal\\Models\\LegalcaseEvidence	{"name":"","description":""}
674	ar	9e2fe19a-61cf-447e-8e74-ec309cad6ba3	Acorn\\Criminal\\Models\\Legalcase	{"description":""}
675	ku	9e2fe19a-61cf-447e-8e74-ec309cad6ba3	Acorn\\Criminal\\Models\\Legalcase	{"description":""}
676	ar	9e321198-a0bd-4e24-8f7f-c38507ae2df7	Acorn\\Criminal\\Models\\Legalcase	{"description":""}
677	ku	9e321198-a0bd-4e24-8f7f-c38507ae2df7	Acorn\\Criminal\\Models\\Legalcase	{"description":""}
678	ar	9e33822e-00b1-4795-9bbf-e1014e6b94e4	Acorn\\Criminal\\Models\\LegalcasePlaintiff	{"description":""}
679	ku	9e33822e-00b1-4795-9bbf-e1014e6b94e4	Acorn\\Criminal\\Models\\LegalcasePlaintiff	{"description":""}
680	ar	9e338252-a631-459e-a7d9-056087ab5819	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
681	ku	9e338252-a631-459e-a7d9-056087ab5819	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
682	ar	9e33825e-ba79-419d-b25c-62ebeb4ad2a9	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
683	ku	9e33825e-ba79-419d-b25c-62ebeb4ad2a9	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
684	ar	9e338274-2698-41db-aeac-69394a8036b2	Acorn\\Justice\\Models\\ScannedDocument	{"name":"","description":""}
685	ku	9e338274-2698-41db-aeac-69394a8036b2	Acorn\\Justice\\Models\\ScannedDocument	{"name":"","description":""}
686	ar	9e358b5a-e79d-4eaf-8b9e-7af1162a8a59	Acorn\\Justice\\Models\\ScannedDocument	{"name":"","description":""}
687	ku	9e358b5a-e79d-4eaf-8b9e-7af1162a8a59	Acorn\\Justice\\Models\\ScannedDocument	{"name":"","description":""}
688	ar	9e365652-a30f-4661-8c21-cea84eb1a4f3	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":"","description":""}
689	ku	9e365652-a30f-4661-8c21-cea84eb1a4f3	Acorn\\Justice\\Models\\LegalcaseCategory	{"name":"","description":""}
690	ar	9e3b6085-ea36-4cc4-bf0b-47bfca163baf	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
691	ku	9e3b6085-ea36-4cc4-bf0b-47bfca163baf	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
692	ar	9e3bbb14-124a-45d4-bbf0-cf547755a1e0	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
693	ku	9e3bbb14-124a-45d4-bbf0-cf547755a1e0	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
694	ar	9e3bc5ab-0166-455e-83ed-326c80a67d6c	Acorn\\Criminal\\Models\\DefendantDetention	{"description":""}
695	ku	9e3bc5ab-0166-455e-83ed-326c80a67d6c	Acorn\\Criminal\\Models\\DefendantDetention	{"description":""}
696	ar	9e3bc5fe-8e51-444c-b68a-a5ed0ce5f317	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
697	ku	9e3bc5fe-8e51-444c-b68a-a5ed0ce5f317	Acorn\\Criminal\\Models\\DefendantCrime	{"description":""}
698	ar	9e3bc62c-0d06-4a9b-8fe4-7bba50c51074	Acorn\\Criminal\\Models\\CrimeSentence	{"description":""}
699	ku	9e3bc62c-0d06-4a9b-8fe4-7bba50c51074	Acorn\\Criminal\\Models\\CrimeSentence	{"description":""}
700	ar	9e3fba82-c5df-4791-918c-50f6a393f0ff	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
701	ku	9e3fba82-c5df-4791-918c-50f6a393f0ff	Acorn\\Criminal\\Models\\LegalcaseDefendant	{"description":""}
702	ar	9e3fba90-3644-4e0c-900f-f7dd437ad66d	Acorn\\Criminal\\Models\\LegalcasePlaintiff	{"description":""}
703	ku	9e3fba90-3644-4e0c-900f-f7dd437ad66d	Acorn\\Criminal\\Models\\LegalcasePlaintiff	{"description":""}
704	ar	9e3fbaa3-42b9-4783-840e-d270e2a4f2d2	Acorn\\Criminal\\Models\\LegalcaseWitness	{"description":""}
705	ku	9e3fbaa3-42b9-4783-840e-d270e2a4f2d2	Acorn\\Criminal\\Models\\LegalcaseWitness	{"description":""}
706	ar	9e3fdfb0-aede-4e43-954b-43fb35151657	Acorn\\Criminal\\Models\\LegalcasePlaintiff	{"description":""}
707	ku	9e3fdfb0-aede-4e43-954b-43fb35151657	Acorn\\Criminal\\Models\\LegalcasePlaintiff	{"description":""}
708	ar	9e3fdfe0-8ebf-4990-bd29-df6f01382bea	Acorn\\Criminal\\Models\\LegalcasePlaintiff	{"description":""}
709	ku	9e3fdfe0-8ebf-4990-bd29-df6f01382bea	Acorn\\Criminal\\Models\\LegalcasePlaintiff	{"description":""}
\.


--
-- Data for Name: winter_translate_indexes; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.winter_translate_indexes (id, locale, model_id, model_type, item, value) FROM stdin;
\.


--
-- Data for Name: winter_translate_locales; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.winter_translate_locales (id, code, name, is_default, is_enabled, sort_order) FROM stdin;
1	en	English	t	t	1
2	ar	Arabic	f	t	2
3	ku	Kurdish	f	t	3
\.


--
-- Data for Name: winter_translate_messages; Type: TABLE DATA; Schema: public; Owner: justice
--

COPY public.winter_translate_messages (id, code, message_data, found, code_pre_2_1_0) FROM stdin;
\.


--
-- Name: backend_access_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.backend_access_log_id_seq', 43, true);


--
-- Name: backend_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.backend_user_groups_id_seq', 1, true);


--
-- Name: backend_user_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.backend_user_preferences_id_seq', 13, true);


--
-- Name: backend_user_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.backend_user_roles_id_seq', 2, true);


--
-- Name: backend_user_throttle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.backend_user_throttle_id_seq', 2, true);


--
-- Name: backend_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.backend_users_id_seq', 1, true);


--
-- Name: cms_theme_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.cms_theme_data_id_seq', 1, false);


--
-- Name: cms_theme_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.cms_theme_logs_id_seq', 1, false);


--
-- Name: cms_theme_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.cms_theme_templates_id_seq', 1, false);


--
-- Name: deferred_bindings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.deferred_bindings_id_seq', 86, true);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.migrations_id_seq', 50, true);


--
-- Name: rainlab_location_countries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.rainlab_location_countries_id_seq', 248, true);


--
-- Name: rainlab_location_states_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.rainlab_location_states_id_seq', 720, true);


--
-- Name: rainlab_translate_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.rainlab_translate_attributes_id_seq', 709, true);


--
-- Name: rainlab_translate_indexes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.rainlab_translate_indexes_id_seq', 1, false);


--
-- Name: rainlab_translate_locales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.rainlab_translate_locales_id_seq', 3, true);


--
-- Name: rainlab_translate_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.rainlab_translate_messages_id_seq', 1, false);


--
-- Name: system_event_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.system_event_logs_id_seq', 11981, true);


--
-- Name: system_files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.system_files_id_seq', 94, true);


--
-- Name: system_mail_layouts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.system_mail_layouts_id_seq', 2, true);


--
-- Name: system_mail_partials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.system_mail_partials_id_seq', 1, false);


--
-- Name: system_mail_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.system_mail_templates_id_seq', 1, false);


--
-- Name: system_parameters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.system_parameters_id_seq', 5, true);


--
-- Name: system_plugin_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.system_plugin_history_id_seq', 292, true);


--
-- Name: system_plugin_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.system_plugin_versions_id_seq', 17, true);


--
-- Name: system_request_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.system_request_logs_id_seq', 1, false);


--
-- Name: system_revisions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.system_revisions_id_seq', 1, false);


--
-- Name: system_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: justice
--

SELECT pg_catalog.setval('public.system_settings_id_seq', 4, true);


--
-- Name: acorn_lojistiks_computer_products computer_products_pkey; Type: CONSTRAINT; Schema: product; Owner: justice
--

ALTER TABLE ONLY product.acorn_lojistiks_computer_products
    ADD CONSTRAINT computer_products_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_electronic_products office_products_pkey; Type: CONSTRAINT; Schema: product; Owner: justice
--

ALTER TABLE ONLY product.acorn_lojistiks_electronic_products
    ADD CONSTRAINT office_products_pkey PRIMARY KEY (id);


--
-- Name: acorn_justice_legalcases acornassocaited_justice_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcases
    ADD CONSTRAINT acornassocaited_justice_cases_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_defendant_crimes acornassocaited_justice_defendant_crime_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_crimes
    ADD CONSTRAINT acornassocaited_justice_defendant_crime_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_part_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_part_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_events acorn_calendar_event_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_event_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_event_statuses acorn_calendar_event_status_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_statuses
    ADD CONSTRAINT acorn_calendar_event_status_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_event_types acorn_calendar_event_type_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_types
    ADD CONSTRAINT acorn_calendar_event_type_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_event_part_user_group acorn_calendar_event_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user_group
    ADD CONSTRAINT acorn_calendar_event_user_group_pkey PRIMARY KEY (event_part_id, user_group_id);


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_user_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_user_pkey PRIMARY KEY (event_part_id, user_id);


--
-- Name: acorn_calendar_instances acorn_calendar_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_instances
    ADD CONSTRAINT acorn_calendar_instance_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_calendars acorn_calendar_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_calendars
    ADD CONSTRAINT acorn_calendar_pkey PRIMARY KEY (id);


--
-- Name: acorn_justice_legalcase_identifiers acorn_case_identifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_identifiers
    ADD CONSTRAINT acorn_case_identifiers_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_appeals acorn_criminal_appeals_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_appeals
    ADD CONSTRAINT acorn_criminal_appeals_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_defendant_detentions acorn_criminal_defendant_detentions_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_detentions
    ADD CONSTRAINT acorn_criminal_defendant_detentions_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_detention_methods acorn_criminal_detention_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_methods
    ADD CONSTRAINT acorn_criminal_detention_methods_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_detention_reasons acorn_criminal_detention_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_reasons
    ADD CONSTRAINT acorn_criminal_detention_reasons_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_legalcase_types acorn_criminal_legalcase_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_types
    ADD CONSTRAINT acorn_criminal_legalcase_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_legalcases acorn_criminal_legalcases_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcases
    ADD CONSTRAINT acorn_criminal_legalcases_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_sentence_types acorn_criminal_sentence_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_sentence_types
    ADD CONSTRAINT acorn_criminal_sentence_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_session_recordings acorn_criminal_session_recordings_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_session_recordings
    ADD CONSTRAINT acorn_criminal_session_recordings_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_trial_judges acorn_criminal_trial_judge_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_judges
    ADD CONSTRAINT acorn_criminal_trial_judge_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_trial_sessions acorn_criminal_trial_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_sessions
    ADD CONSTRAINT acorn_criminal_trial_sessions_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_trials acorn_criminal_trials_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trials
    ADD CONSTRAINT acorn_criminal_trials_pkey PRIMARY KEY (id);


--
-- Name: acorn_finance_currencies acorn_finance_currency_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_currencies
    ADD CONSTRAINT acorn_finance_currency_pkey PRIMARY KEY (id);


--
-- Name: acorn_finance_invoices acorn_finance_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT acorn_finance_invoices_pkey PRIMARY KEY (id);


--
-- Name: acorn_finance_payments acorn_finance_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_payments
    ADD CONSTRAINT acorn_finance_payments_pkey PRIMARY KEY (id);


--
-- Name: acorn_finance_purchases acorn_finance_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_purchases
    ADD CONSTRAINT acorn_finance_purchases_pkey PRIMARY KEY (id);


--
-- Name: acorn_finance_receipts acorn_finance_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_receipts
    ADD CONSTRAINT acorn_finance_receipts_pkey PRIMARY KEY (id);


--
-- Name: acorn_justice_legalcase_categories acorn_justice_case_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_categories
    ADD CONSTRAINT acorn_justice_case_categories_pkey PRIMARY KEY (id);


--
-- Name: acorn_justice_legalcase_legalcase_category acorn_justice_case_category_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_legalcase_category
    ADD CONSTRAINT acorn_justice_case_category_pkey PRIMARY KEY (legalcase_id, legalcase_category_id);


--
-- Name: acorn_criminal_crime_evidence acorn_justice_crime_evidence_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_evidence
    ADD CONSTRAINT acorn_justice_crime_evidence_pkey PRIMARY KEY (defendant_crime_id, legalcase_evidence_id);


--
-- Name: acorn_criminal_crime_sentences acorn_justice_crime_sentences_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_sentences
    ADD CONSTRAINT acorn_justice_crime_sentences_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_crime_types acorn_justice_crime_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_types
    ADD CONSTRAINT acorn_justice_crime_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_crimes acorn_justice_crimes_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crimes
    ADD CONSTRAINT acorn_justice_crimes_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_legalcase_defendants acorn_justice_defendant_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_defendants
    ADD CONSTRAINT acorn_justice_defendant_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_legalcase_evidence acorn_justice_legalcase_evidence_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_evidence
    ADD CONSTRAINT acorn_justice_legalcase_evidence_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_legalcase_prosecutor acorn_justice_legalcase_prosecution_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_prosecutor
    ADD CONSTRAINT acorn_justice_legalcase_prosecution_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_legalcase_plaintiffs acorn_justice_legalcase_victims_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_plaintiffs
    ADD CONSTRAINT acorn_justice_legalcase_victims_pkey PRIMARY KEY (id);


--
-- Name: acorn_criminal_legalcase_witnesses acorn_justice_legalcase_witnesses_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_witnesses
    ADD CONSTRAINT acorn_justice_legalcase_witnesses_pkey PRIMARY KEY (id);


--
-- Name: acorn_justice_scanned_documents acorn_justice_scanned_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_scanned_documents
    ADD CONSTRAINT acorn_justice_scanned_documents_pkey PRIMARY KEY (id);


--
-- Name: acorn_justice_warrant_types acorn_justice_warrant_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrant_types
    ADD CONSTRAINT acorn_justice_warrant_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_justice_warrants acorn_justice_warrants_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrants
    ADD CONSTRAINT acorn_justice_warrants_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_lookup acorn_location_location_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_lookup
    ADD CONSTRAINT acorn_location_location_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_employees acorn_lojistiks_employees_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_employees
    ADD CONSTRAINT acorn_lojistiks_employees_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_product_products acorn_lojistiks_product_products_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_products
    ADD CONSTRAINT acorn_lojistiks_product_products_pkey PRIMARY KEY (product_id, sub_product_id);


--
-- Name: acorn_lojistiks_warehouses acorn_lojistiks_warehouses_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_warehouses
    ADD CONSTRAINT acorn_lojistiks_warehouses_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_label acorn_messaging_label_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_label
    ADD CONSTRAINT acorn_messaging_label_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_message acorn_messaging_message_externalid_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message
    ADD CONSTRAINT acorn_messaging_message_externalid_unique UNIQUE ("externalID");


--
-- Name: acorn_messaging_message_instance acorn_messaging_message_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message_instance
    ADD CONSTRAINT acorn_messaging_message_instance_pkey PRIMARY KEY (message_id, instance_id);


--
-- Name: acorn_messaging_message_message acorn_messaging_message_message_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message_message
    ADD CONSTRAINT acorn_messaging_message_message_pkey PRIMARY KEY (message1_id, message2_id, relationship);


--
-- Name: acorn_messaging_message acorn_messaging_message_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message
    ADD CONSTRAINT acorn_messaging_message_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_message_user_group acorn_messaging_message_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message_user_group
    ADD CONSTRAINT acorn_messaging_message_user_group_pkey PRIMARY KEY (message_id, user_group_id);


--
-- Name: acorn_messaging_message_user acorn_messaging_message_user_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message_user
    ADD CONSTRAINT acorn_messaging_message_user_pkey PRIMARY KEY (message_id, user_id);


--
-- Name: acorn_messaging_status acorn_messaging_status_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_status
    ADD CONSTRAINT acorn_messaging_status_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_pkey PRIMARY KEY (message_id, status_id);


--
-- Name: acorn_servers acorn_servers_hostname_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_servers
    ADD CONSTRAINT acorn_servers_hostname_unique UNIQUE (hostname);


--
-- Name: acorn_servers acorn_servers_id_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_servers
    ADD CONSTRAINT acorn_servers_id_unique UNIQUE (id);


--
-- Name: acorn_user_language_user acorn_user_language_user_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_language_user
    ADD CONSTRAINT acorn_user_language_user_pkey PRIMARY KEY (user_id, language_id);


--
-- Name: acorn_user_languages acorn_user_languages_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_languages
    ADD CONSTRAINT acorn_user_languages_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_roles acorn_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_roles
    ADD CONSTRAINT acorn_user_roles_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_throttle acorn_user_throttle_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_throttle
    ADD CONSTRAINT acorn_user_throttle_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_user_group acorn_user_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_group
    ADD CONSTRAINT acorn_user_user_group_pkey PRIMARY KEY (user_id, user_group_id);


--
-- Name: acorn_user_user_group_types acorn_user_user_group_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_group_types
    ADD CONSTRAINT acorn_user_user_group_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_user_group_versions acorn_user_user_group_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_group_versions
    ADD CONSTRAINT acorn_user_user_group_versions_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_user_groups acorn_user_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT acorn_user_user_groups_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_users acorn_user_users_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT acorn_user_users_pkey PRIMARY KEY (id);


--
-- Name: backend_access_log backend_access_log_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_access_log
    ADD CONSTRAINT backend_access_log_pkey PRIMARY KEY (id);


--
-- Name: backend_user_groups backend_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_groups
    ADD CONSTRAINT backend_user_groups_pkey PRIMARY KEY (id);


--
-- Name: backend_user_preferences backend_user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_preferences
    ADD CONSTRAINT backend_user_preferences_pkey PRIMARY KEY (id);


--
-- Name: backend_user_roles backend_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_roles
    ADD CONSTRAINT backend_user_roles_pkey PRIMARY KEY (id);


--
-- Name: backend_user_throttle backend_user_throttle_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_throttle
    ADD CONSTRAINT backend_user_throttle_pkey PRIMARY KEY (id);


--
-- Name: backend_users_groups backend_users_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_users_groups
    ADD CONSTRAINT backend_users_groups_pkey PRIMARY KEY (user_id, user_group_id);


--
-- Name: backend_users backend_users_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT backend_users_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_brands brands_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (id);


--
-- Name: cache cache_key_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_key_unique UNIQUE (key);


--
-- Name: cms_theme_data cms_theme_data_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_data
    ADD CONSTRAINT cms_theme_data_pkey PRIMARY KEY (id);


--
-- Name: cms_theme_logs cms_theme_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_logs
    ADD CONSTRAINT cms_theme_logs_pkey PRIMARY KEY (id);


--
-- Name: cms_theme_templates cms_theme_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.cms_theme_templates
    ADD CONSTRAINT cms_theme_templates_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_containers containers_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_containers
    ADD CONSTRAINT containers_pkey PRIMARY KEY (id);


--
-- Name: deferred_bindings deferred_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.deferred_bindings
    ADD CONSTRAINT deferred_bindings_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_drivers drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_drivers
    ADD CONSTRAINT drivers_pkey PRIMARY KEY (id);


--
-- Name: backend_users email_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT email_unique UNIQUE (email);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- Name: acorn_user_user_group_version_user id; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_group_version_user
    ADD CONSTRAINT id PRIMARY KEY (id);


--
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_addresses location_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT location_addresses_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_area_types location_area_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_area_types
    ADD CONSTRAINT location_area_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_areas location_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT location_areas_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_gps location_gps_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_gps
    ADD CONSTRAINT location_gps_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_locations location_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT location_locations_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_types location_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT location_types_pkey PRIMARY KEY (id);


--
-- Name: backend_users login_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT login_unique UNIQUE (login);


--
-- Name: acorn_lojistiks_measurement_units measurement_units_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_measurement_units
    ADD CONSTRAINT measurement_units_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: backend_user_groups name_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_groups
    ADD CONSTRAINT name_unique UNIQUE (name);


--
-- Name: acorn_lojistiks_offices office_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_offices
    ADD CONSTRAINT office_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_people person_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_people
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_product_attributes product_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_attributes
    ADD CONSTRAINT product_attributes_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_product_categories product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_categories
    ADD CONSTRAINT product_categories_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_product_category_types product_category_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_category_types
    ADD CONSTRAINT product_category_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_product_instances product_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instances
    ADD CONSTRAINT product_instances_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_products products_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_products_product_category products_product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products_product_category
    ADD CONSTRAINT products_product_categories_pkey PRIMARY KEY (id);


--
-- Name: winter_location_countries rainlab_location_countries_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_location_countries
    ADD CONSTRAINT rainlab_location_countries_pkey PRIMARY KEY (id);


--
-- Name: winter_location_states rainlab_location_states_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_location_states
    ADD CONSTRAINT rainlab_location_states_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_attributes rainlab_translate_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_attributes
    ADD CONSTRAINT rainlab_translate_attributes_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_indexes rainlab_translate_indexes_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_indexes
    ADD CONSTRAINT rainlab_translate_indexes_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_locales rainlab_translate_locales_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_locales
    ADD CONSTRAINT rainlab_translate_locales_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_messages rainlab_translate_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.winter_translate_messages
    ADD CONSTRAINT rainlab_translate_messages_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_mail_blockers rainlab_user_mail_blockers_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_mail_blockers
    ADD CONSTRAINT rainlab_user_mail_blockers_pkey PRIMARY KEY (id);


--
-- Name: backend_user_roles role_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.backend_user_roles
    ADD CONSTRAINT role_unique UNIQUE (name);


--
-- Name: sessions sessions_id_unique; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_id_unique UNIQUE (id);


--
-- Name: acorn_lojistiks_suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: system_event_logs system_event_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_event_logs
    ADD CONSTRAINT system_event_logs_pkey PRIMARY KEY (id);


--
-- Name: system_files system_files_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_files
    ADD CONSTRAINT system_files_pkey PRIMARY KEY (id);


--
-- Name: system_mail_layouts system_mail_layouts_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_layouts
    ADD CONSTRAINT system_mail_layouts_pkey PRIMARY KEY (id);


--
-- Name: system_mail_partials system_mail_partials_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_partials
    ADD CONSTRAINT system_mail_partials_pkey PRIMARY KEY (id);


--
-- Name: system_mail_templates system_mail_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_mail_templates
    ADD CONSTRAINT system_mail_templates_pkey PRIMARY KEY (id);


--
-- Name: system_parameters system_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_parameters
    ADD CONSTRAINT system_parameters_pkey PRIMARY KEY (id);


--
-- Name: system_plugin_history system_plugin_history_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_plugin_history
    ADD CONSTRAINT system_plugin_history_pkey PRIMARY KEY (id);


--
-- Name: system_plugin_versions system_plugin_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_plugin_versions
    ADD CONSTRAINT system_plugin_versions_pkey PRIMARY KEY (id);


--
-- Name: system_request_logs system_request_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_request_logs
    ADD CONSTRAINT system_request_logs_pkey PRIMARY KEY (id);


--
-- Name: system_revisions system_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_revisions
    ADD CONSTRAINT system_revisions_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_transfer_containers transfer_container_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_containers
    ADD CONSTRAINT transfer_container_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_transfer_container_product_instance transfer_container_products_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT transfer_container_products_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_product_instance_transfer transfer_product_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instance_transfer
    ADD CONSTRAINT transfer_product_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_transfers transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfers
    ADD CONSTRAINT transfers_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_vehicle_types vehicle_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicle_types
    ADD CONSTRAINT vehicle_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_lojistiks_vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: dr_acorn_lojistiks_computer_products_replica_identity; Type: INDEX; Schema: product; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_computer_products_replica_identity ON product.acorn_lojistiks_computer_products USING btree (server_id, id);

ALTER TABLE ONLY product.acorn_lojistiks_computer_products REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_computer_products_replica_identity;


--
-- Name: dr_acorn_lojistiks_electronic_products_replica_identi; Type: INDEX; Schema: product; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_electronic_products_replica_identi ON product.acorn_lojistiks_electronic_products USING btree (server_id, id);

ALTER TABLE ONLY product.acorn_lojistiks_electronic_products REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_electronic_products_replica_identi;


--
-- Name: fki_created_at_event_id; Type: INDEX; Schema: product; Owner: justice
--

CREATE INDEX fki_created_at_event_id ON product.acorn_lojistiks_electronic_products USING btree (created_at_event_id);


--
-- Name: fki_server_id; Type: INDEX; Schema: product; Owner: justice
--

CREATE INDEX fki_server_id ON product.acorn_lojistiks_computer_products USING btree (server_id);


--
-- Name: acorn_calendar_instance_date_event_part_id_instance_n; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acorn_calendar_instance_date_event_part_id_instance_n ON public.acorn_calendar_instances USING btree (date, event_part_id, instance_num);


--
-- Name: acorn_user_mail_blockers_email_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acorn_user_mail_blockers_email_index ON public.acorn_user_mail_blockers USING btree (email);


--
-- Name: acorn_user_mail_blockers_template_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acorn_user_mail_blockers_template_index ON public.acorn_user_mail_blockers USING btree (template);


--
-- Name: acorn_user_mail_blockers_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acorn_user_mail_blockers_user_id_index ON public.acorn_user_mail_blockers USING btree (user_id);


--
-- Name: acorn_user_throttle_ip_address_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acorn_user_throttle_ip_address_index ON public.acorn_user_throttle USING btree (ip_address);


--
-- Name: acorn_user_throttle_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acorn_user_throttle_user_id_index ON public.acorn_user_throttle USING btree (user_id);


--
-- Name: acorn_user_user_groups_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acorn_user_user_groups_code_index ON public.acorn_user_user_groups USING btree (code);


--
-- Name: acorn_user_users_activation_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acorn_user_users_activation_code_index ON public.acorn_user_users USING btree (activation_code);


--
-- Name: acorn_user_users_login_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acorn_user_users_login_index ON public.acorn_user_users USING btree (username);


--
-- Name: acorn_user_users_reset_password_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX acorn_user_users_reset_password_code_index ON public.acorn_user_users USING btree (reset_password_code);


--
-- Name: act_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX act_code_index ON public.backend_users USING btree (activation_code);


--
-- Name: admin_role_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX admin_role_index ON public.backend_users USING btree (role_id);


--
-- Name: backend_user_throttle_ip_address_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX backend_user_throttle_ip_address_index ON public.backend_user_throttle USING btree (ip_address);


--
-- Name: backend_user_throttle_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX backend_user_throttle_user_id_index ON public.backend_user_throttle USING btree (user_id);


--
-- Name: cms_theme_data_theme_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_data_theme_index ON public.cms_theme_data USING btree (theme);


--
-- Name: cms_theme_logs_theme_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_logs_theme_index ON public.cms_theme_logs USING btree (theme);


--
-- Name: cms_theme_logs_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_logs_type_index ON public.cms_theme_logs USING btree (type);


--
-- Name: cms_theme_logs_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_logs_user_id_index ON public.cms_theme_logs USING btree (user_id);


--
-- Name: cms_theme_templates_path_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_templates_path_index ON public.cms_theme_templates USING btree (path);


--
-- Name: cms_theme_templates_source_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX cms_theme_templates_source_index ON public.cms_theme_templates USING btree (source);


--
-- Name: code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX code_index ON public.backend_user_groups USING btree (code);


--
-- Name: deferred_bindings_master_field_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX deferred_bindings_master_field_index ON public.deferred_bindings USING btree (master_field);


--
-- Name: deferred_bindings_master_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX deferred_bindings_master_type_index ON public.deferred_bindings USING btree (master_type);


--
-- Name: deferred_bindings_session_key_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX deferred_bindings_session_key_index ON public.deferred_bindings USING btree (session_key);


--
-- Name: deferred_bindings_slave_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX deferred_bindings_slave_id_index ON public.deferred_bindings USING btree (slave_id);


--
-- Name: deferred_bindings_slave_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX deferred_bindings_slave_type_index ON public.deferred_bindings USING btree (slave_type);


--
-- Name: dr_acorn_location_addresses_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_location_addresses_replica_identity ON public.acorn_location_addresses USING btree (server_id, id);


--
-- Name: dr_acorn_location_area_types_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_location_area_types_replica_identity ON public.acorn_location_area_types USING btree (server_id, id);


--
-- Name: dr_acorn_location_areas_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_location_areas_replica_identity ON public.acorn_location_areas USING btree (server_id, id);


--
-- Name: dr_acorn_location_gps_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_location_gps_replica_identity ON public.acorn_location_gps USING btree (server_id, id);


--
-- Name: dr_acorn_location_location_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_location_location_replica_identity ON public.acorn_location_locations USING btree (server_id, id);


--
-- Name: dr_acorn_location_types_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_location_types_replica_identity ON public.acorn_location_types USING btree (server_id, id);


--
-- Name: dr_acorn_lojistiks_brands_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_brands_replica_identity ON public.acorn_lojistiks_brands USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_brands REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_brands_replica_identity;


--
-- Name: dr_acorn_lojistiks_containers_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_containers_replica_identity ON public.acorn_lojistiks_containers USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_containers REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_containers_replica_identity;


--
-- Name: dr_acorn_lojistiks_drivers_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_drivers_replica_identity ON public.acorn_lojistiks_drivers USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_drivers REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_drivers_replica_identity;


--
-- Name: dr_acorn_lojistiks_employees_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_employees_replica_identity ON public.acorn_lojistiks_employees USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_employees REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_employees_replica_identity;


--
-- Name: dr_acorn_lojistiks_measurement_units_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_measurement_units_replica_identity ON public.acorn_lojistiks_measurement_units USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_measurement_units REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_measurement_units_replica_identity;


--
-- Name: dr_acorn_lojistiks_office_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_office_replica_identity ON public.acorn_lojistiks_offices USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_offices REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_office_replica_identity;


--
-- Name: dr_acorn_lojistiks_people_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_people_replica_identity ON public.acorn_lojistiks_people USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_people REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_people_replica_identity;


--
-- Name: dr_acorn_lojistiks_product_attributes_replica_identit; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_product_attributes_replica_identit ON public.acorn_lojistiks_product_attributes USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_product_attributes REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_product_attributes_replica_identit;


--
-- Name: dr_acorn_lojistiks_product_categories_replica_identit; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_product_categories_replica_identit ON public.acorn_lojistiks_product_categories USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_product_categories REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_product_categories_replica_identit;


--
-- Name: dr_acorn_lojistiks_product_category_types_replica_ide; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_product_category_types_replica_ide ON public.acorn_lojistiks_product_category_types USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_product_category_types REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_product_category_types_replica_ide;


--
-- Name: dr_acorn_lojistiks_product_instance_transfer_replica_; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_product_instance_transfer_replica_ ON public.acorn_lojistiks_product_instance_transfer USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_product_instance_transfer REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_product_instance_transfer_replica_;


--
-- Name: dr_acorn_lojistiks_product_instances_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_product_instances_replica_identity ON public.acorn_lojistiks_product_instances USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_product_instances REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_product_instances_replica_identity;


--
-- Name: dr_acorn_lojistiks_product_products_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_product_products_replica_identity ON public.acorn_lojistiks_product_products USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_product_products REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_product_products_replica_identity;


--
-- Name: dr_acorn_lojistiks_products_product_categories_replic; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_products_product_categories_replic ON public.acorn_lojistiks_products_product_category USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_products_product_category REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_products_product_categories_replic;


--
-- Name: dr_acorn_lojistiks_products_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_products_replica_identity ON public.acorn_lojistiks_products USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_products REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_products_replica_identity;


--
-- Name: dr_acorn_lojistiks_suppliers_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_suppliers_replica_identity ON public.acorn_lojistiks_suppliers USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_suppliers REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_suppliers_replica_identity;


--
-- Name: dr_acorn_lojistiks_transfer_container_product_instanc; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_transfer_container_product_instanc ON public.acorn_lojistiks_transfer_container_product_instance USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_transfer_container_product_instance REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_transfer_container_product_instanc;


--
-- Name: dr_acorn_lojistiks_transfer_container_replica_identit; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_transfer_container_replica_identit ON public.acorn_lojistiks_transfer_containers USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_transfer_containers REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_transfer_container_replica_identit;


--
-- Name: dr_acorn_lojistiks_transfers_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_transfers_replica_identity ON public.acorn_lojistiks_transfers USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_transfers REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_transfers_replica_identity;


--
-- Name: dr_acorn_lojistiks_vehicle_types_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_vehicle_types_replica_identity ON public.acorn_lojistiks_vehicle_types USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_vehicle_types REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_vehicle_types_replica_identity;


--
-- Name: dr_acorn_lojistiks_vehicles_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_vehicles_replica_identity ON public.acorn_lojistiks_vehicles USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_vehicles REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_vehicles_replica_identity;


--
-- Name: dr_acorn_lojistiks_warehouses_replica_identity; Type: INDEX; Schema: public; Owner: justice
--

CREATE UNIQUE INDEX dr_acorn_lojistiks_warehouses_replica_identity ON public.acorn_lojistiks_warehouses USING btree (server_id, id);

ALTER TABLE ONLY public.acorn_lojistiks_warehouses REPLICA IDENTITY USING INDEX dr_acorn_lojistiks_warehouses_replica_identity;


--
-- Name: fki_ALTER TABLE IF EXISTS public.acorn_criminal_crime; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX "fki_ALTER TABLE IF EXISTS public.acorn_criminal_crime" ON public.acorn_criminal_crime_types USING btree (updated_at_event_id);


--
-- Name: fki_acorn_lojistiks_containers_created_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_containers_created_at_event_id ON public.acorn_lojistiks_containers USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_drivers_created_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_drivers_created_at_event_id ON public.acorn_lojistiks_drivers USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_offices_created_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_offices_created_at_event_id ON public.acorn_lojistiks_offices USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_people_created_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_people_created_at_event_id ON public.acorn_lojistiks_people USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_product_attributes_created_at_eve; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_product_attributes_created_at_eve ON public.acorn_lojistiks_product_attributes USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_product_categories_created_at_eve; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_product_categories_created_at_eve ON public.acorn_lojistiks_product_categories USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_product_category_types_created_at; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_product_category_types_created_at ON public.acorn_lojistiks_product_category_types USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_product_instance_transfer_created; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_product_instance_transfer_created ON public.acorn_lojistiks_product_instance_transfer USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_product_instances_created_at_even; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_product_instances_created_at_even ON public.acorn_lojistiks_product_instances USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_product_products_created_at_event; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_product_products_created_at_event ON public.acorn_lojistiks_product_products USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_products_created_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_products_created_at_event_id ON public.acorn_lojistiks_products USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_products_product_categories_creat; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_products_product_categories_creat ON public.acorn_lojistiks_products_product_category USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_suppliers_created_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_suppliers_created_at_event_id ON public.acorn_lojistiks_suppliers USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_vehicle_types_created_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_vehicle_types_created_at_event_id ON public.acorn_lojistiks_vehicle_types USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_vehicles_created_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_vehicles_created_at_event_id ON public.acorn_lojistiks_vehicles USING btree (created_at_event_id);


--
-- Name: fki_acorn_lojistiks_warehouses_created_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_acorn_lojistiks_warehouses_created_at_event_id ON public.acorn_lojistiks_warehouses USING btree (created_at_event_id);


--
-- Name: fki_actual_release_transfer_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_actual_release_transfer_id ON public.acorn_criminal_defendant_detentions USING btree (actual_release_transfer_id);


--
-- Name: fki_arrived_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_arrived_at_event_id ON public.acorn_lojistiks_transfers USING btree (arrived_at_event_id);


--
-- Name: fki_closed_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_closed_at_event_id ON public.acorn_justice_legalcases USING btree (closed_at_event_id);


--
-- Name: fki_created_at; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_created_at ON public.acorn_finance_invoices USING btree (created_event_id);


--
-- Name: fki_created_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_created_at_event_id ON public.acorn_lojistiks_transfer_container_product_instance USING btree (created_at_event_id);


--
-- Name: fki_created_by_user_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_created_by_user_id ON public.acorn_criminal_defendant_crimes USING btree (created_by_user_id);


--
-- Name: fki_crime_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_crime_id ON public.acorn_criminal_defendant_crimes USING btree (crime_id);


--
-- Name: fki_currency_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_currency_id ON public.acorn_finance_invoices USING btree (currency_id);


--
-- Name: fki_default_group_version_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_default_group_version_id ON public.acorn_user_user_groups USING btree (default_user_group_version_id);


--
-- Name: fki_defendant_crime_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_defendant_crime_id ON public.acorn_criminal_crime_evidence USING btree (defendant_crime_id);


--
-- Name: fki_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_event_id ON public.acorn_criminal_appeals USING btree (event_id);


--
-- Name: fki_event_part_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_event_part_id ON public.acorn_criminal_legalcase_related_events USING btree (event_id);


--
-- Name: fki_from_user_group_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_from_user_group_id ON public.acorn_user_user_groups USING btree (from_user_group_id);


--
-- Name: fki_from_user_group_version_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_from_user_group_version_id ON public.acorn_user_user_group_versions USING btree (from_user_group_version_id);


--
-- Name: fki_invoice_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_invoice_id ON public.acorn_lojistiks_transfer_invoice USING btree (invoice_id);


--
-- Name: fki_judge_committee_user_group_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_judge_committee_user_group_id ON public.acorn_criminal_legalcases USING btree (judge_committee_user_group_id);


--
-- Name: fki_last_product_instance_destination_location_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_last_product_instance_destination_location_id ON public.acorn_lojistiks_people USING btree (last_product_instance_location_id);


--
-- Name: fki_last_product_instance_location_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_last_product_instance_location_id ON public.acorn_lojistiks_people USING btree (last_product_instance_location_id);


--
-- Name: fki_last_transfer_destination_location_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_last_transfer_destination_location_id ON public.acorn_lojistiks_people USING btree (last_transfer_location_id);


--
-- Name: fki_last_transfer_location_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_last_transfer_location_id ON public.acorn_lojistiks_people USING btree (last_transfer_location_id);


--
-- Name: fki_legalcase_category_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_legalcase_category_id ON public.acorn_justice_legalcase_legalcase_category USING btree (legalcase_category_id);


--
-- Name: fki_legalcase_defendant_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_legalcase_defendant_id ON public.acorn_criminal_defendant_detentions USING btree (legalcase_defendant_id);


--
-- Name: fki_legalcase_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_legalcase_id ON public.acorn_justice_scanned_documents USING btree (legalcase_id);


--
-- Name: fki_legalcase_type_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_legalcase_type_id ON public.acorn_criminal_legalcases USING btree (legalcase_type_id);


--
-- Name: fki_location_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_location_id ON public.acorn_lojistiks_offices USING btree (location_id);


--
-- Name: fki_method_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_method_id ON public.acorn_criminal_defendant_detentions USING btree (detention_method_id);


--
-- Name: fki_owner_user_group_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_owner_user_group_id ON public.acorn_justice_legalcases USING btree (owner_user_group_id);


--
-- Name: fki_parent_legalcase_category_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_parent_legalcase_category_id ON public.acorn_justice_legalcase_categories USING btree (parent_legalcase_category_id);


--
-- Name: fki_parent_product_category_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_parent_product_category_id ON public.acorn_lojistiks_product_categories USING btree (parent_product_category_id);


--
-- Name: fki_payee_user_group_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_payee_user_group_id ON public.acorn_finance_invoices USING btree (payee_user_group_id);


--
-- Name: fki_payee_user_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_payee_user_id ON public.acorn_finance_invoices USING btree (payee_user_id);


--
-- Name: fki_purchase_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_purchase_id ON public.acorn_lojistiks_transfer_purchase USING btree (purchase_id);


--
-- Name: fki_reason_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_reason_id ON public.acorn_criminal_defendant_detentions USING btree (detention_reason_id);


--
-- Name: fki_revoked_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_revoked_at_event_id ON public.acorn_justice_warrants USING btree (revoked_at_event_id);


--
-- Name: fki_role_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_role_id ON public.acorn_user_user_group_version_user USING btree (role_id);


--
-- Name: fki_sent_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_sent_at_event_id ON public.acorn_lojistiks_transfers USING btree (sent_at_event_id);


--
-- Name: fki_sentence_type_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_sentence_type_id ON public.acorn_criminal_crime_sentences USING btree (sentence_type_id);


--
-- Name: fki_server_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_server_id ON public.acorn_criminal_legalcases USING btree (server_id);


--
-- Name: fki_transfer_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_transfer_id ON public.acorn_lojistiks_transfer_invoice USING btree (transfer_id);


--
-- Name: fki_trial_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_trial_id ON public.acorn_criminal_trial_judges USING btree (trial_id);


--
-- Name: fki_trial_session_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_trial_session_id ON public.acorn_criminal_session_recordings USING btree (trial_session_id);


--
-- Name: fki_type_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_type_id ON public.acorn_location_locations USING btree (type_id);


--
-- Name: fki_updated_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_updated_at_event_id ON public.acorn_justice_legalcases USING btree (updated_at_event_id);


--
-- Name: fki_updated_by_user_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_updated_by_user_id ON public.acorn_justice_legalcases USING btree (updated_by_user_id);


--
-- Name: fki_user_group_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_user_group_id ON public.acorn_finance_purchases USING btree (payer_user_group_id);


--
-- Name: fki_user_group_version_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_user_group_version_id ON public.acorn_user_user_group_version_user USING btree (user_group_version_id);


--
-- Name: fki_user_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_user_id ON public.acorn_finance_purchases USING btree (payer_user_id);


--
-- Name: item_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX item_index ON public.system_parameters USING btree (namespace, "group", item);


--
-- Name: jobs_queue_reserved_at_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX jobs_queue_reserved_at_index ON public.jobs USING btree (queue, reserved_at);


--
-- Name: rainlab_location_countries_name_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_location_countries_name_index ON public.winter_location_countries USING btree (name);


--
-- Name: rainlab_location_states_country_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_location_states_country_id_index ON public.winter_location_states USING btree (country_id);


--
-- Name: rainlab_location_states_name_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_location_states_name_index ON public.winter_location_states USING btree (name);


--
-- Name: rainlab_translate_attributes_locale_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_attributes_locale_index ON public.winter_translate_attributes USING btree (locale);


--
-- Name: rainlab_translate_attributes_model_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_attributes_model_id_index ON public.winter_translate_attributes USING btree (model_id);


--
-- Name: rainlab_translate_attributes_model_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_attributes_model_type_index ON public.winter_translate_attributes USING btree (model_type);


--
-- Name: rainlab_translate_indexes_item_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_indexes_item_index ON public.winter_translate_indexes USING btree (item);


--
-- Name: rainlab_translate_indexes_locale_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_indexes_locale_index ON public.winter_translate_indexes USING btree (locale);


--
-- Name: rainlab_translate_indexes_model_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_indexes_model_id_index ON public.winter_translate_indexes USING btree (model_id);


--
-- Name: rainlab_translate_indexes_model_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_indexes_model_type_index ON public.winter_translate_indexes USING btree (model_type);


--
-- Name: rainlab_translate_locales_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_locales_code_index ON public.winter_translate_locales USING btree (code);


--
-- Name: rainlab_translate_locales_name_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_locales_name_index ON public.winter_translate_locales USING btree (name);


--
-- Name: rainlab_translate_messages_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX rainlab_translate_messages_code_index ON public.winter_translate_messages USING btree (code);


--
-- Name: reset_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX reset_code_index ON public.backend_users USING btree (reset_password_code);


--
-- Name: role_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX role_code_index ON public.backend_user_roles USING btree (code);


--
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- Name: system_event_logs_level_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_event_logs_level_index ON public.system_event_logs USING btree (level);


--
-- Name: system_files_attachment_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_files_attachment_id_index ON public.system_files USING btree (attachment_id);


--
-- Name: system_files_attachment_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_files_attachment_type_index ON public.system_files USING btree (attachment_type);


--
-- Name: system_files_field_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_files_field_index ON public.system_files USING btree (field);


--
-- Name: system_mail_templates_layout_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_mail_templates_layout_id_index ON public.system_mail_templates USING btree (layout_id);


--
-- Name: system_plugin_history_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_plugin_history_code_index ON public.system_plugin_history USING btree (code);


--
-- Name: system_plugin_history_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_plugin_history_type_index ON public.system_plugin_history USING btree (type);


--
-- Name: system_plugin_versions_code_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_plugin_versions_code_index ON public.system_plugin_versions USING btree (code);


--
-- Name: system_revisions_field_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_revisions_field_index ON public.system_revisions USING btree (field);


--
-- Name: system_revisions_revisionable_id_revisionable_type_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_revisions_revisionable_id_revisionable_type_index ON public.system_revisions USING btree (revisionable_id, revisionable_type);


--
-- Name: system_revisions_user_id_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_revisions_user_id_index ON public.system_revisions USING btree (user_id);


--
-- Name: system_settings_item_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX system_settings_item_index ON public.system_settings USING btree (item);


--
-- Name: user_item_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX user_item_index ON public.backend_user_preferences USING btree (user_id, namespace, "group", item);


--
-- Name: winter_translate_messages_code_pre_2_1_0_index; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX winter_translate_messages_code_pre_2_1_0_index ON public.winter_translate_messages USING btree (code_pre_2_1_0);


--
-- Name: acorn_lojistiks_computer_products tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: product; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON product.acorn_lojistiks_computer_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_electronic_products tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: product; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON product.acorn_lojistiks_electronic_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_computer_products tr_acorn_lojistiks_computer_products_new_replicated_r; Type: TRIGGER; Schema: product; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_computer_products_new_replicated_r BEFORE INSERT ON product.acorn_lojistiks_computer_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE product.acorn_lojistiks_computer_products ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_computer_products_new_replicated_r;


--
-- Name: acorn_lojistiks_computer_products tr_acorn_lojistiks_computer_products_server_id; Type: TRIGGER; Schema: product; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_computer_products_server_id BEFORE INSERT ON product.acorn_lojistiks_computer_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_electronic_products tr_acorn_lojistiks_electronic_products_new_replicated; Type: TRIGGER; Schema: product; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_electronic_products_new_replicated BEFORE INSERT ON product.acorn_lojistiks_electronic_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE product.acorn_lojistiks_electronic_products ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_electronic_products_new_replicated;


--
-- Name: acorn_lojistiks_electronic_products tr_acorn_lojistiks_electronic_products_server_id; Type: TRIGGER; Schema: product; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_electronic_products_server_id BEFORE INSERT ON product.acorn_lojistiks_electronic_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_calendar_event_parts tr_acorn_calendar_events_generate_event_instances; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_events_generate_event_instances AFTER INSERT OR UPDATE ON public.acorn_calendar_event_parts FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_events_generate_event_instances();


--
-- Name: acorn_criminal_appeals tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_appeals FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_crime_sentences tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_crime_sentences FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_crimes tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_crimes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_defendant_crimes tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_defendant_crimes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_detention_methods tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_detention_methods FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_detention_reasons tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_detention_reasons FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_legalcase_defendants tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_defendants FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_legalcase_evidence tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_evidence FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_legalcase_plaintiffs tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_plaintiffs FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_legalcase_types tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_legalcase_witnesses tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_witnesses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_sentence_types tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_sentence_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_session_recordings tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_session_recordings FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_trial_judges tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_trial_judges FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_trial_sessions tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_trial_sessions FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_trials tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_trials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_finance_currencies tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_finance_currencies FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_finance_invoices tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_finance_invoices FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_finance_payments tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_finance_payments FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_finance_purchases tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_finance_purchases FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_finance_receipts tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_finance_receipts FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_justice_legalcase_categories tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_legalcase_categories FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_justice_legalcase_identifiers tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_legalcase_identifiers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_justice_scanned_documents tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_scanned_documents FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_justice_warrant_types tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_warrant_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_justice_warrants tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_warrants FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_brands tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_brands FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_containers tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_containers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_drivers tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_drivers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_employees tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_employees FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_measurement_units tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_measurement_units FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_offices tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_offices FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_people tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_people FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_product_attributes tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_product_attributes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_product_categories tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_product_categories FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_product_category_types tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_product_category_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_product_instances tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_product_instances FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_product_products tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_product_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_products tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_suppliers tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_suppliers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_transfers tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_transfers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_vehicle_types tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_vehicle_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_vehicles tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_vehicles FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_lojistiks_warehouses tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_warehouses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_crime_types tr_acorn_criminal_crime_types; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_criminal_crime_types BEFORE INSERT OR UPDATE ON public.acorn_criminal_crime_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_criminal_legalcase_prosecutor tr_acorn_criminal_legalcase_prosecutor; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_criminal_legalcase_prosecutor BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_prosecutor FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_justice_legalcases tr_acorn_justice_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_justice_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_legalcases FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_justice_legalcase_legalcase_category tr_acorn_justice_legalcase_legalcase_category; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_justice_legalcase_legalcase_category BEFORE INSERT OR UPDATE ON public.acorn_justice_legalcase_legalcase_category FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_created_at_event();


--
-- Name: acorn_justice_legalcases tr_acorn_justice_update_name_identifier; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_justice_update_name_identifier AFTER UPDATE ON public.acorn_justice_legalcases FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_justice_update_name_identifier();

ALTER TABLE public.acorn_justice_legalcases DISABLE TRIGGER tr_acorn_justice_update_name_identifier;


--
-- Name: acorn_location_addresses tr_acorn_location_addresses_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_addresses_new_replicated_row BEFORE INSERT ON public.acorn_location_addresses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_addresses ENABLE ALWAYS TRIGGER tr_acorn_location_addresses_new_replicated_row;


--
-- Name: acorn_location_addresses tr_acorn_location_addresses_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_addresses_server_id BEFORE INSERT ON public.acorn_location_addresses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_area_types tr_acorn_location_area_types_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_area_types_new_replicated_row BEFORE INSERT ON public.acorn_location_area_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_area_types ENABLE ALWAYS TRIGGER tr_acorn_location_area_types_new_replicated_row;


--
-- Name: acorn_location_area_types tr_acorn_location_area_types_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_area_types_server_id BEFORE INSERT ON public.acorn_location_area_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_areas tr_acorn_location_areas_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_areas_new_replicated_row BEFORE INSERT ON public.acorn_location_areas FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_areas ENABLE ALWAYS TRIGGER tr_acorn_location_areas_new_replicated_row;


--
-- Name: acorn_location_areas tr_acorn_location_areas_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_areas_server_id BEFORE INSERT ON public.acorn_location_areas FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_gps tr_acorn_location_gps_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_gps_new_replicated_row BEFORE INSERT ON public.acorn_location_gps FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_gps ENABLE ALWAYS TRIGGER tr_acorn_location_gps_new_replicated_row;


--
-- Name: acorn_location_gps tr_acorn_location_gps_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_gps_server_id BEFORE INSERT ON public.acorn_location_gps FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_locations tr_acorn_location_locations_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_locations_new_replicated_row BEFORE INSERT ON public.acorn_location_locations FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_locations ENABLE ALWAYS TRIGGER tr_acorn_location_locations_new_replicated_row;


--
-- Name: acorn_location_locations tr_acorn_location_locations_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_locations_server_id BEFORE INSERT ON public.acorn_location_locations FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_types tr_acorn_location_types_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_types_new_replicated_row BEFORE INSERT ON public.acorn_location_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_types ENABLE ALWAYS TRIGGER tr_acorn_location_types_new_replicated_row;


--
-- Name: acorn_location_types tr_acorn_location_types_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_location_types_server_id BEFORE INSERT ON public.acorn_location_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_brands tr_acorn_lojistiks_brands_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_brands_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_brands FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_brands ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_brands_new_replicated_row;


--
-- Name: acorn_lojistiks_brands tr_acorn_lojistiks_brands_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_brands_server_id BEFORE INSERT ON public.acorn_lojistiks_brands FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_containers tr_acorn_lojistiks_containers_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_containers_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_containers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_containers ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_containers_new_replicated_row;


--
-- Name: acorn_lojistiks_containers tr_acorn_lojistiks_containers_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_containers_server_id BEFORE INSERT ON public.acorn_lojistiks_containers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_drivers tr_acorn_lojistiks_drivers_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_drivers_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_drivers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_drivers ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_drivers_new_replicated_row;


--
-- Name: acorn_lojistiks_drivers tr_acorn_lojistiks_drivers_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_drivers_server_id BEFORE INSERT ON public.acorn_lojistiks_drivers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_employees tr_acorn_lojistiks_employees_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_employees_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_employees FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_employees ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_employees_new_replicated_row;


--
-- Name: acorn_lojistiks_employees tr_acorn_lojistiks_employees_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_employees_server_id BEFORE INSERT ON public.acorn_lojistiks_employees FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_measurement_units tr_acorn_lojistiks_measurement_units_new_replicated_r; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_measurement_units_new_replicated_r BEFORE INSERT ON public.acorn_lojistiks_measurement_units FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_measurement_units ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_measurement_units_new_replicated_r;


--
-- Name: acorn_lojistiks_measurement_units tr_acorn_lojistiks_measurement_units_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_measurement_units_server_id BEFORE INSERT ON public.acorn_lojistiks_measurement_units FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_offices tr_acorn_lojistiks_offices_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_offices_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_offices FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_offices ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_offices_new_replicated_row;


--
-- Name: acorn_lojistiks_offices tr_acorn_lojistiks_offices_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_offices_server_id BEFORE INSERT ON public.acorn_lojistiks_offices FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_people tr_acorn_lojistiks_people_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_people_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_people FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_people ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_people_new_replicated_row;


--
-- Name: acorn_lojistiks_people tr_acorn_lojistiks_people_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_people_server_id BEFORE INSERT ON public.acorn_lojistiks_people FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_product_attributes tr_acorn_lojistiks_product_attributes_new_replicated_; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_attributes_new_replicated_ BEFORE INSERT ON public.acorn_lojistiks_product_attributes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_product_attributes ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_product_attributes_new_replicated_;


--
-- Name: acorn_lojistiks_product_attributes tr_acorn_lojistiks_product_attributes_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_attributes_server_id BEFORE INSERT ON public.acorn_lojistiks_product_attributes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_product_categories tr_acorn_lojistiks_product_categories_new_replicated_; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_categories_new_replicated_ BEFORE INSERT ON public.acorn_lojistiks_product_categories FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_product_categories ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_product_categories_new_replicated_;


--
-- Name: acorn_lojistiks_product_categories tr_acorn_lojistiks_product_categories_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_categories_server_id BEFORE INSERT ON public.acorn_lojistiks_product_categories FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_product_category_types tr_acorn_lojistiks_product_category_types_new_replica; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_category_types_new_replica BEFORE INSERT ON public.acorn_lojistiks_product_category_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_product_category_types ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_product_category_types_new_replica;


--
-- Name: acorn_lojistiks_product_category_types tr_acorn_lojistiks_product_category_types_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_category_types_server_id BEFORE INSERT ON public.acorn_lojistiks_product_category_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_product_instance_transfer tr_acorn_lojistiks_product_instance_transfer_new_repl; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_instance_transfer_new_repl BEFORE INSERT ON public.acorn_lojistiks_product_instance_transfer FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_product_instance_transfer ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_product_instance_transfer_new_repl;


--
-- Name: acorn_lojistiks_product_instance_transfer tr_acorn_lojistiks_product_instance_transfer_server_i; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_instance_transfer_server_i BEFORE INSERT ON public.acorn_lojistiks_product_instance_transfer FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_product_instances tr_acorn_lojistiks_product_instances_new_replicated_r; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_instances_new_replicated_r BEFORE INSERT ON public.acorn_lojistiks_product_instances FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_product_instances ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_product_instances_new_replicated_r;


--
-- Name: acorn_lojistiks_product_instances tr_acorn_lojistiks_product_instances_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_instances_server_id BEFORE INSERT ON public.acorn_lojistiks_product_instances FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_product_products tr_acorn_lojistiks_product_products_new_replicated_ro; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_products_new_replicated_ro BEFORE INSERT ON public.acorn_lojistiks_product_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_product_products ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_product_products_new_replicated_ro;


--
-- Name: acorn_lojistiks_product_products tr_acorn_lojistiks_product_products_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_product_products_server_id BEFORE INSERT ON public.acorn_lojistiks_product_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_products tr_acorn_lojistiks_products_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_products_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_products ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_products_new_replicated_row;


--
-- Name: acorn_lojistiks_product_product_category tr_acorn_lojistiks_products_product_categories_new_re; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_products_product_categories_new_re BEFORE INSERT ON public.acorn_lojistiks_product_product_category FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_product_product_category ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_products_product_categories_new_re;


--
-- Name: acorn_lojistiks_products_product_category tr_acorn_lojistiks_products_product_categories_new_re; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_products_product_categories_new_re BEFORE INSERT ON public.acorn_lojistiks_products_product_category FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_products_product_category ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_products_product_categories_new_re;


--
-- Name: acorn_lojistiks_product_product_category tr_acorn_lojistiks_products_product_categories_server; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_products_product_categories_server BEFORE INSERT ON public.acorn_lojistiks_product_product_category FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_products_product_category tr_acorn_lojistiks_products_product_categories_server; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_products_product_categories_server BEFORE INSERT ON public.acorn_lojistiks_products_product_category FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_products tr_acorn_lojistiks_products_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_products_server_id BEFORE INSERT ON public.acorn_lojistiks_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_suppliers tr_acorn_lojistiks_suppliers_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_suppliers_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_suppliers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_suppliers ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_suppliers_new_replicated_row;


--
-- Name: acorn_lojistiks_suppliers tr_acorn_lojistiks_suppliers_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_suppliers_server_id BEFORE INSERT ON public.acorn_lojistiks_suppliers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_transfer_containers tr_acorn_lojistiks_transfer_container_new_replicated_; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_transfer_container_new_replicated_ BEFORE INSERT ON public.acorn_lojistiks_transfer_containers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_transfer_containers ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_transfer_container_new_replicated_;


--
-- Name: acorn_lojistiks_transfer_container_product_instance tr_acorn_lojistiks_transfer_container_product_instanc; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_transfer_container_product_instanc BEFORE INSERT ON public.acorn_lojistiks_transfer_container_product_instance FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_transfer_container_product_instance ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_transfer_container_product_instanc;


--
-- Name: acorn_lojistiks_transfer_containers tr_acorn_lojistiks_transfer_container_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_transfer_container_server_id BEFORE INSERT ON public.acorn_lojistiks_transfer_containers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_transfers tr_acorn_lojistiks_transfers_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_transfers_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_transfers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_transfers ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_transfers_new_replicated_row;


--
-- Name: acorn_lojistiks_transfers tr_acorn_lojistiks_transfers_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_transfers_server_id BEFORE INSERT ON public.acorn_lojistiks_transfers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_vehicle_types tr_acorn_lojistiks_vehicle_types_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_vehicle_types_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_vehicle_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_vehicle_types ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_vehicle_types_new_replicated_row;


--
-- Name: acorn_lojistiks_vehicle_types tr_acorn_lojistiks_vehicle_types_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_vehicle_types_server_id BEFORE INSERT ON public.acorn_lojistiks_vehicle_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_vehicles tr_acorn_lojistiks_vehicles_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_vehicles_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_vehicles FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_vehicles ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_vehicles_new_replicated_row;


--
-- Name: acorn_lojistiks_vehicles tr_acorn_lojistiks_vehicles_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_vehicles_server_id BEFORE INSERT ON public.acorn_lojistiks_vehicles FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_warehouses tr_acorn_lojistiks_warehouses_new_replicated_row; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_warehouses_new_replicated_row BEFORE INSERT ON public.acorn_lojistiks_warehouses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_lojistiks_warehouses ENABLE ALWAYS TRIGGER tr_acorn_lojistiks_warehouses_new_replicated_row;


--
-- Name: acorn_lojistiks_warehouses tr_acorn_lojistiks_warehouses_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_lojistiks_warehouses_server_id BEFORE INSERT ON public.acorn_lojistiks_warehouses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_crime_sentences tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_crime_sentences FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_crime_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_crime_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_crimes tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_crimes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_defendant_crimes tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_defendant_crimes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_detention_methods tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_detention_methods FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_detention_reasons tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_detention_reasons FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_legalcase_defendants tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_legalcase_defendants FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_legalcase_evidence tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_legalcase_evidence FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_legalcase_plaintiffs tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_legalcase_plaintiffs FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_legalcase_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_legalcase_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_legalcase_witnesses tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_legalcase_witnesses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_legalcases tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_legalcases FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_sentence_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_sentence_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_session_recordings tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_session_recordings FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_criminal_trial_judges tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_trial_judges FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_finance_currencies tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_finance_currencies FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_finance_invoices tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_finance_invoices FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_finance_payments tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_finance_payments FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_finance_purchases tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_finance_purchases FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_finance_receipts tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_finance_receipts FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_legalcase_categories tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_legalcase_categories FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_legalcase_identifiers tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_legalcase_identifiers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_legalcases tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_legalcases FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_scanned_documents tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_scanned_documents FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_warrant_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_warrant_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_warrants tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_warrants FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_lojistiks_computer_products computer_products_created_by_user; Type: FK CONSTRAINT; Schema: product; Owner: justice
--

ALTER TABLE ONLY product.acorn_lojistiks_computer_products
    ADD CONSTRAINT computer_products_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_lojistiks_electronic_products created_at_event_id; Type: FK CONSTRAINT; Schema: product; Owner: justice
--

ALTER TABLE ONLY product.acorn_lojistiks_electronic_products
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_computer_products created_at_event_id; Type: FK CONSTRAINT; Schema: product; Owner: justice
--

ALTER TABLE ONLY product.acorn_lojistiks_computer_products
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_computer_products electronic_product_id; Type: FK CONSTRAINT; Schema: product; Owner: justice
--

ALTER TABLE ONLY product.acorn_lojistiks_computer_products
    ADD CONSTRAINT electronic_product_id FOREIGN KEY (electronic_product_id) REFERENCES product.acorn_lojistiks_electronic_products(id) NOT VALID;


--
-- Name: CONSTRAINT electronic_product_id ON acorn_lojistiks_computer_products; Type: COMMENT; Schema: product; Owner: justice
--

COMMENT ON CONSTRAINT electronic_product_id ON product.acorn_lojistiks_computer_products IS 'type: 1to1
name-object: true';


--
-- Name: acorn_lojistiks_electronic_products electronic_products_created_by_user; Type: FK CONSTRAINT; Schema: product; Owner: justice
--

ALTER TABLE ONLY product.acorn_lojistiks_electronic_products
    ADD CONSTRAINT electronic_products_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_lojistiks_electronic_products product_id; Type: FK CONSTRAINT; Schema: product; Owner: justice
--

ALTER TABLE ONLY product.acorn_lojistiks_electronic_products
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.acorn_lojistiks_products(id);


--
-- Name: CONSTRAINT product_id ON acorn_lojistiks_electronic_products; Type: COMMENT; Schema: product; Owner: justice
--

COMMENT ON CONSTRAINT product_id ON product.acorn_lojistiks_electronic_products IS 'type: 1to1
name-object: true';


--
-- Name: acorn_lojistiks_computer_products server_id; Type: FK CONSTRAINT; Schema: product; Owner: justice
--

ALTER TABLE ONLY product.acorn_lojistiks_computer_products
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_lojistiks_electronic_products server_id; Type: FK CONSTRAINT; Schema: product; Owner: justice
--

ALTER TABLE ONLY product.acorn_lojistiks_electronic_products
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_calendar_events acorn_calendar_event_calendar_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_event_calendar_id_foreign FOREIGN KEY (calendar_id) REFERENCES public.acorn_calendar_calendars(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_events acorn_calendar_event_owner_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_event_owner_user_group_id_foreign FOREIGN KEY (owner_user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_events acorn_calendar_event_owner_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_event_owner_user_id_foreign FOREIGN KEY (owner_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_part_event_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_part_event_id_foreign FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_part_locked_by_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_part_locked_by_user_id_foreign FOREIGN KEY (locked_by_user_id) REFERENCES public.backend_users(id) ON DELETE SET NULL;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_part_parent_event_part_id_foreig; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_part_parent_event_part_id_foreig FOREIGN KEY (parent_event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_part_status_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_part_status_id_foreign FOREIGN KEY (status_id) REFERENCES public.acorn_calendar_event_statuses(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_part_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_part_type_id_foreign FOREIGN KEY (type_id) REFERENCES public.acorn_calendar_event_types(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_user_event_part_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_user_event_part_id_foreign FOREIGN KEY (event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user_group acorn_calendar_event_user_group_event_part_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user_group
    ADD CONSTRAINT acorn_calendar_event_user_group_event_part_id_foreign FOREIGN KEY (event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user_group acorn_calendar_event_user_group_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user_group
    ADD CONSTRAINT acorn_calendar_event_user_group_user_group_id_foreign FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_user_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_user_role_id_foreign FOREIGN KEY (role_id) REFERENCES public.acorn_user_roles(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_user_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_instances acorn_calendar_instance_event_part_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_instances
    ADD CONSTRAINT acorn_calendar_instance_event_part_id_foreign FOREIGN KEY (event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_calendars acorn_calendar_owner_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_calendars
    ADD CONSTRAINT acorn_calendar_owner_user_group_id_foreign FOREIGN KEY (owner_user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_calendars acorn_calendar_owner_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_calendars
    ADD CONSTRAINT acorn_calendar_owner_user_id_foreign FOREIGN KEY (owner_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_instance acorn_messaging_message_instance_instance_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message_instance
    ADD CONSTRAINT acorn_messaging_message_instance_instance_id_foreign FOREIGN KEY (instance_id) REFERENCES public.acorn_calendar_instances(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_instance acorn_messaging_message_instance_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message_instance
    ADD CONSTRAINT acorn_messaging_message_instance_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user_group acorn_messaging_message_user_group_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message_user_group
    ADD CONSTRAINT acorn_messaging_message_user_group_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user_group acorn_messaging_message_user_group_user_group_id_fore; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message_user_group
    ADD CONSTRAINT acorn_messaging_message_user_group_user_group_id_fore FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user acorn_messaging_message_user_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message_user
    ADD CONSTRAINT acorn_messaging_message_user_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user acorn_messaging_message_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_message_user
    ADD CONSTRAINT acorn_messaging_message_user_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_message_id_foreig; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_message_id_foreig FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_status_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_status_id_foreign FOREIGN KEY (status_id) REFERENCES public.acorn_messaging_status(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_criminal_defendant_detentions actual_release_transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_detentions
    ADD CONSTRAINT actual_release_transfer_id FOREIGN KEY (actual_release_transfer_id) REFERENCES public.acorn_lojistiks_transfers(id) NOT VALID;


--
-- Name: CONSTRAINT actual_release_transfer_id ON acorn_criminal_defendant_detentions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT actual_release_transfer_id ON public.acorn_criminal_defendant_detentions IS 'type: 1to1';


--
-- Name: acorn_location_locations address_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT address_id FOREIGN KEY (address_id) REFERENCES public.acorn_location_addresses(id) NOT VALID;


--
-- Name: acorn_location_addresses addresses_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT addresses_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_location_addresses area_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT area_id FOREIGN KEY (area_id) REFERENCES public.acorn_location_areas(id) NOT VALID;


--
-- Name: acorn_location_areas area_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT area_type_id FOREIGN KEY (area_type_id) REFERENCES public.acorn_location_area_types(id);


--
-- Name: acorn_location_area_types area_types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_area_types
    ADD CONSTRAINT area_types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_location_areas areas_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT areas_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_lojistiks_transfers arrived_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfers
    ADD CONSTRAINT arrived_at_event_id FOREIGN KEY (arrived_at_event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE SET NULL NOT VALID;


--
-- Name: acorn_lojistiks_products brand_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products
    ADD CONSTRAINT brand_id FOREIGN KEY (brand_id) REFERENCES public.acorn_lojistiks_brands(id) NOT VALID;


--
-- Name: acorn_lojistiks_brands brands_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_brands
    ADD CONSTRAINT brands_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_legalcases closed_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcases
    ADD CONSTRAINT closed_at_event_id FOREIGN KEY (closed_at_event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE SET NULL NOT VALID;


--
-- Name: acorn_lojistiks_transfer_containers container_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_containers
    ADD CONSTRAINT container_id FOREIGN KEY (container_id) REFERENCES public.acorn_lojistiks_containers(id);


--
-- Name: acorn_lojistiks_containers containers_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_containers
    ADD CONSTRAINT containers_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_invoices created_at; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT created_at FOREIGN KEY (created_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_legalcases created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcases
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: CONSTRAINT created_at_event_id ON acorn_justice_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT created_at_event_id ON public.acorn_justice_legalcases IS 'delete: true';


--
-- Name: acorn_justice_legalcase_identifiers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_identifiers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_justice_legalcase_legalcase_category created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_legalcase_category
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_crime_sentences created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_sentences
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_trial_judges created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_judges
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_sentence_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_sentence_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_legalcase_plaintiffs created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_plaintiffs
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_legalcase_evidence created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_evidence
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_crimes created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crimes
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_crime_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_defendant_crimes created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_crimes
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_appeals created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_appeals
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_legalcase_defendants created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_defendants
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_legalcase_prosecutor created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_prosecutor
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_legalcase_witnesses created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_witnesses
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_trial_sessions created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_sessions
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_trials created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trials
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_session_recordings created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_session_recordings
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_justice_scanned_documents created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_scanned_documents
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_lojistiks_transfer_container_product_instance created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfer_containers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_containers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_brands created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_brands
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_employees created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_employees
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_measurement_units created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_measurement_units
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_offices created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_offices
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_people created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_people
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_containers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_containers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_attributes created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_attributes
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_categories created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_categories
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_category_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_category_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_instance_transfer created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instance_transfer
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_instances created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instances
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_drivers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_drivers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_products_product_category created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products_product_category
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_vehicle_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicle_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_vehicles created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicles
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_warehouses created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_warehouses
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_products created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_suppliers created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_suppliers
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_products created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_products
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_warrants created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrants
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_finance_purchases created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_purchases
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_finance_invoices created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_finance_payments created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_payments
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_detention_methods created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_methods
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_detention_reasons created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_reasons
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_finance_currencies created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_currencies
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_categories created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_categories
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_warrant_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrant_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_finance_receipts created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_receipts
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_product_category created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_product_category
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_instance_transfer created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instance_transfer
    ADD CONSTRAINT created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_legalcases created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcases
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_legalcase_category created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_legalcase_category
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_identifiers created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_identifiers
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_crime_sentences created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_sentences
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_trial_judges created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_judges
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_sentence_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_sentence_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_legalcase_plaintiffs created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_plaintiffs
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_legalcase_evidence created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_evidence
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_crimes created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crimes
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_crime_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_defendant_crimes created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_crimes
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_appeals created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_appeals
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_legalcase_defendants created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_defendants
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_legalcase_prosecutor created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_prosecutor
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_legalcase_witnesses created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_witnesses
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_trial_sessions created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_sessions
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_trials created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trials
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_session_recordings created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_session_recordings
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_justice_scanned_documents created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_scanned_documents
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_justice_warrants created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrants
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_related_events created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_related_events
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_purchases created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_purchases
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_invoices created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_payments created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_payments
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_detention_methods created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_methods
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_detention_reasons created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_reasons
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_currencies created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_currencies
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_categories created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_categories
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_warrant_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrant_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_receipts created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_receipts
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_defendant_crimes crime_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_crimes
    ADD CONSTRAINT crime_id FOREIGN KEY (crime_id) REFERENCES public.acorn_criminal_crimes(id) NOT VALID;


--
-- Name: acorn_criminal_crimes crime_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crimes
    ADD CONSTRAINT crime_type_id FOREIGN KEY (crime_type_id) REFERENCES public.acorn_criminal_crime_types(id) NOT VALID;


--
-- Name: acorn_finance_invoices currency_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES public.acorn_finance_currencies(id) NOT VALID;


--
-- Name: acorn_finance_payments currency_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_payments
    ADD CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES public.acorn_finance_currencies(id) NOT VALID;


--
-- Name: acorn_finance_purchases currency_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_purchases
    ADD CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES public.acorn_finance_currencies(id) NOT VALID;


--
-- Name: acorn_finance_receipts currency_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_receipts
    ADD CONSTRAINT currency_id FOREIGN KEY (currency_id) REFERENCES public.acorn_finance_currencies(id) NOT VALID;


--
-- Name: acorn_user_user_groups default_group_version_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT default_group_version_id FOREIGN KEY (default_user_group_version_id) REFERENCES public.acorn_user_user_group_versions(id) NOT VALID;


--
-- Name: acorn_criminal_crime_evidence defendant_crime_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_evidence
    ADD CONSTRAINT defendant_crime_id FOREIGN KEY (defendant_crime_id) REFERENCES public.acorn_criminal_defendant_crimes(id) NOT VALID;


--
-- Name: CONSTRAINT defendant_crime_id ON acorn_criminal_crime_evidence; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT defendant_crime_id ON public.acorn_criminal_crime_evidence IS 'labels-plural:
  en: Evidence';


--
-- Name: acorn_criminal_crime_sentences defendant_crime_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_sentences
    ADD CONSTRAINT defendant_crime_id FOREIGN KEY (defendant_crime_id) REFERENCES public.acorn_criminal_defendant_crimes(id) NOT VALID;


--
-- Name: CONSTRAINT defendant_crime_id ON acorn_criminal_crime_sentences; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT defendant_crime_id ON public.acorn_criminal_crime_sentences IS 'labels-plural:
  en: Sentences
';


--
-- Name: acorn_lojistiks_transfers driver_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfers
    ADD CONSTRAINT driver_id FOREIGN KEY (driver_id) REFERENCES public.acorn_lojistiks_drivers(id) NOT VALID;


--
-- Name: acorn_lojistiks_drivers drivers_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_drivers
    ADD CONSTRAINT drivers_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_employees employees_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_employees
    ADD CONSTRAINT employees_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_related_events event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_related_events
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT event_id ON acorn_criminal_legalcase_related_events; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT event_id ON public.acorn_criminal_legalcase_related_events IS 'type: 1to1
delete: true
';


--
-- Name: acorn_criminal_trials event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trials
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT event_id ON acorn_criminal_trials; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT event_id ON public.acorn_criminal_trials IS 'type: 1to1
delete: true';


--
-- Name: acorn_criminal_appeals event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_appeals
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT event_id ON acorn_criminal_appeals; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT event_id ON public.acorn_criminal_appeals IS 'type: 1to1
delete: true';


--
-- Name: acorn_criminal_trial_sessions event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_sessions
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: CONSTRAINT event_id ON acorn_criminal_trial_sessions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT event_id ON public.acorn_criminal_trial_sessions IS 'type: 1to1
name-object: true';


--
-- Name: acorn_user_user_groups from_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT from_user_group_id FOREIGN KEY (from_user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_user_user_group_versions from_user_group_version_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_group_versions
    ADD CONSTRAINT from_user_group_version_id FOREIGN KEY (from_user_group_version_id) REFERENCES public.acorn_user_user_group_versions(id) NOT VALID;


--
-- Name: acorn_location_gps gps_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_gps
    ADD CONSTRAINT gps_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_location_areas gps_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT gps_id FOREIGN KEY (gps_id) REFERENCES public.acorn_location_gps(id);


--
-- Name: acorn_location_addresses gps_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT gps_id FOREIGN KEY (gps_id) REFERENCES public.acorn_location_gps(id) NOT VALID;


--
-- Name: acorn_finance_payments invoice_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_payments
    ADD CONSTRAINT invoice_id FOREIGN KEY (invoice_id) REFERENCES public.acorn_finance_invoices(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfer_invoice invoice_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_invoice
    ADD CONSTRAINT invoice_id FOREIGN KEY (invoice_id) REFERENCES public.acorn_finance_invoices(id) NOT VALID;


--
-- Name: acorn_criminal_legalcases judge_committee_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcases
    ADD CONSTRAINT judge_committee_user_group_id FOREIGN KEY (judge_committee_user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_user_language_user language_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_language_user
    ADD CONSTRAINT language_id FOREIGN KEY (language_id) REFERENCES public.acorn_user_languages(id);


--
-- Name: acorn_lojistiks_people last_product_instance_location_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_people
    ADD CONSTRAINT last_product_instance_location_id FOREIGN KEY (last_product_instance_location_id) REFERENCES public.acorn_location_locations(id) NOT VALID;


--
-- Name: acorn_lojistiks_people last_transfer_location_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_people
    ADD CONSTRAINT last_transfer_location_id FOREIGN KEY (last_transfer_location_id) REFERENCES public.acorn_location_locations(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_legalcase_category legalcase_category_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_legalcase_category
    ADD CONSTRAINT legalcase_category_id FOREIGN KEY (legalcase_category_id) REFERENCES public.acorn_justice_legalcase_categories(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_category_id ON acorn_justice_legalcase_legalcase_category; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_category_id ON public.acorn_justice_legalcase_legalcase_category IS 'type: XtoX';


--
-- Name: acorn_criminal_defendant_crimes legalcase_defendant_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_crimes
    ADD CONSTRAINT legalcase_defendant_id FOREIGN KEY (legalcase_defendant_id) REFERENCES public.acorn_criminal_legalcase_defendants(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_defendant_id ON acorn_criminal_defendant_crimes; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_defendant_id ON public.acorn_criminal_defendant_crimes IS 'labels-plural:
  en: Crimes';


--
-- Name: acorn_criminal_defendant_detentions legalcase_defendant_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_detentions
    ADD CONSTRAINT legalcase_defendant_id FOREIGN KEY (legalcase_defendant_id) REFERENCES public.acorn_criminal_legalcase_defendants(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_defendant_id ON acorn_criminal_defendant_detentions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_defendant_id ON public.acorn_criminal_defendant_detentions IS 'labels-plural:
  en: Detentions';


--
-- Name: acorn_criminal_crime_evidence legalcase_evidence_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_evidence
    ADD CONSTRAINT legalcase_evidence_id FOREIGN KEY (legalcase_evidence_id) REFERENCES public.acorn_criminal_legalcase_evidence(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_evidence_id ON acorn_criminal_crime_evidence; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_evidence_id ON public.acorn_criminal_crime_evidence IS 'labels:
  en: Evidence
labels-plural:
  en: Evidence';


--
-- Name: acorn_justice_legalcase_identifiers legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_identifiers
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_justice_legalcases(id);


--
-- Name: CONSTRAINT legalcase_id ON acorn_justice_legalcase_identifiers; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_justice_legalcase_identifiers IS 'tab-location: 3
type: Xto1
bootstraps:
  xs: 12';


--
-- Name: acorn_justice_legalcase_legalcase_category legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_legalcase_category
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_justice_legalcases(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_justice_legalcase_legalcase_category; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_justice_legalcase_legalcase_category IS 'tab-location: 3
bootstraps:
  xs: 12
type: XtoX
';


--
-- Name: acorn_criminal_legalcases legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcases
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_justice_legalcases(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_criminal_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_criminal_legalcases IS 'type: 1to1
nameObject: true';


--
-- Name: acorn_criminal_appeals legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_appeals
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_criminal_appeals; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_criminal_appeals IS 'tab-location: 2
order: 11';


--
-- Name: acorn_criminal_legalcase_defendants legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_defendants
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_criminal_legalcase_defendants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_criminal_legalcase_defendants IS 'labels-plural:
  en: Defendants
  ku: XweBiparastinêni';


--
-- Name: acorn_criminal_legalcase_evidence legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_evidence
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_criminal_legalcase_evidence; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_criminal_legalcase_evidence IS 'labels:
  en: Evidence
  ar: دليل القضايا الجنائية
labels-plural:
  en: Evidence
  ar: أدلة القضايا الجنائية
tab-location: 2
order: 4';


--
-- Name: acorn_criminal_legalcase_prosecutor legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_prosecutor
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_criminal_legalcase_prosecutor; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_criminal_legalcase_prosecutor IS 'labels:
  en: Prosecutor
  ar: المدعي العام للقضية الجنائية
labels-plural:
  en: Prosecutors
  ar: المدعون العامون للقضايا الجنائية
';


--
-- Name: acorn_criminal_legalcase_plaintiffs legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_plaintiffs
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_criminal_legalcase_plaintiffs; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_criminal_legalcase_plaintiffs IS 'labels:
  en: Plaintiff
  ar: ضحية القضية الجنائية
labels-plural:
  en: Plaintiffs
  ar: ضحايا القضية الجنائية
';


--
-- Name: acorn_criminal_legalcase_witnesses legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_witnesses
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_criminal_legalcase_witnesses; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_criminal_legalcase_witnesses IS 'labels:
  en: Witness
  ar: شاهد القضية الجنائية
labels-plural:
  en: Witnesses
  ar: شهود القضية الجنائية
';


--
-- Name: acorn_criminal_trials legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trials
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_criminal_trials; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_criminal_trials IS 'tab-location: 2
order: 10';


--
-- Name: acorn_justice_scanned_documents legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_scanned_documents
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_justice_legalcases(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_justice_scanned_documents; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_justice_scanned_documents IS 'tab-location: 3
type: Xto1
bootstraps:
  xs: 12';


--
-- Name: acorn_justice_warrants legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrants
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_justice_legalcases(id) NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_justice_warrants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_justice_warrants IS 'tab-location: 2
type: Xto1';


--
-- Name: acorn_criminal_legalcase_related_events legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_related_events
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT legalcase_id ON acorn_criminal_legalcase_related_events; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_criminal_legalcase_related_events IS 'tab-location: 2
labels:
  en: Event
  ar: الحدث المتعلقة بالقضاية الجنائية
labels-plural:
  en: Events
  ar: الأحداث المتعلقة بالقضايا الجنائية
';


--
-- Name: acorn_criminal_legalcases legalcase_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcases
    ADD CONSTRAINT legalcase_type_id FOREIGN KEY (legalcase_type_id) REFERENCES public.acorn_criminal_legalcase_types(id) NOT VALID;


--
-- Name: acorn_servers location_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_servers
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acorn_location_locations(id) ON DELETE SET NULL;


--
-- Name: acorn_lojistiks_offices location_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_offices
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acorn_location_locations(id) NOT VALID;


--
-- Name: CONSTRAINT location_id ON acorn_lojistiks_offices; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT location_id ON public.acorn_lojistiks_offices IS 'name-object: true';


--
-- Name: acorn_lojistiks_suppliers location_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_suppliers
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acorn_location_locations(id) NOT VALID;


--
-- Name: CONSTRAINT location_id ON acorn_lojistiks_suppliers; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT location_id ON public.acorn_lojistiks_suppliers IS 'name-object: true';


--
-- Name: acorn_lojistiks_transfers location_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfers
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acorn_location_locations(id) NOT VALID;


--
-- Name: acorn_lojistiks_warehouses location_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_warehouses
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acorn_location_locations(id) NOT VALID;


--
-- Name: CONSTRAINT location_id ON acorn_lojistiks_warehouses; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT location_id ON public.acorn_lojistiks_warehouses IS 'name-object: true';


--
-- Name: acorn_location_locations locations_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT locations_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_lojistiks_products measurement_unit_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products
    ADD CONSTRAINT measurement_unit_id FOREIGN KEY (measurement_unit_id) REFERENCES public.acorn_lojistiks_measurement_units(id);


--
-- Name: acorn_lojistiks_measurement_units measurement_units_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_measurement_units
    ADD CONSTRAINT measurement_units_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_defendant_detentions method_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_detentions
    ADD CONSTRAINT method_id FOREIGN KEY (detention_method_id) REFERENCES public.acorn_criminal_detention_methods(id) NOT VALID;


--
-- Name: acorn_lojistiks_offices offices_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_offices
    ADD CONSTRAINT offices_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_legalcases owner_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcases
    ADD CONSTRAINT owner_user_group_id FOREIGN KEY (owner_user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_location_areas parent_area_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT parent_area_id FOREIGN KEY (parent_area_id) REFERENCES public.acorn_location_areas(id) NOT VALID;


--
-- Name: acorn_criminal_crime_types parent_crime_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_types
    ADD CONSTRAINT parent_crime_type_id FOREIGN KEY (parent_crime_type_id) REFERENCES public.acorn_criminal_crime_types(id);


--
-- Name: CONSTRAINT parent_crime_type_id ON acorn_criminal_crime_types; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT parent_crime_type_id ON public.acorn_criminal_crime_types IS 'labels-plural:
  en: Child Types';


--
-- Name: acorn_justice_legalcase_categories parent_legalcase_category_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_categories
    ADD CONSTRAINT parent_legalcase_category_id FOREIGN KEY (parent_legalcase_category_id) REFERENCES public.acorn_justice_legalcase_categories(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_categories parent_product_category_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_categories
    ADD CONSTRAINT parent_product_category_id FOREIGN KEY (parent_product_category_id) REFERENCES public.acorn_lojistiks_product_categories(id) NOT VALID;


--
-- Name: acorn_location_types parent_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT parent_type_id FOREIGN KEY (parent_type_id) REFERENCES public.acorn_location_types(id);


--
-- Name: acorn_finance_invoices payee_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT payee_user_group_id FOREIGN KEY (payee_user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_finance_purchases payee_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_purchases
    ADD CONSTRAINT payee_user_group_id FOREIGN KEY (payee_user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_finance_invoices payee_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT payee_user_id FOREIGN KEY (payee_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_purchases payee_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_purchases
    ADD CONSTRAINT payee_user_id FOREIGN KEY (payee_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_purchases payer_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_purchases
    ADD CONSTRAINT payer_user_group_id FOREIGN KEY (payer_user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_finance_invoices payer_user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT payer_user_group_id FOREIGN KEY (payer_user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_finance_purchases payer_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_purchases
    ADD CONSTRAINT payer_user_id FOREIGN KEY (payer_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_invoices payer_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT payer_user_id FOREIGN KEY (payer_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_people people_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_people
    ADD CONSTRAINT people_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_drivers person_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_drivers
    ADD CONSTRAINT person_id FOREIGN KEY (person_id) REFERENCES public.acorn_lojistiks_people(id);


--
-- Name: CONSTRAINT person_id ON acorn_lojistiks_drivers; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT person_id ON public.acorn_lojistiks_drivers IS 'name-object: true';


--
-- Name: acorn_lojistiks_employees person_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_employees
    ADD CONSTRAINT person_id FOREIGN KEY (person_id) REFERENCES public.acorn_lojistiks_people(id);


--
-- Name: CONSTRAINT person_id ON acorn_lojistiks_employees; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT person_id ON public.acorn_lojistiks_employees IS 'name-object: true';


--
-- Name: acorn_lojistiks_product_attributes product_attributes_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_attributes
    ADD CONSTRAINT product_attributes_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_categories product_categories_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_categories
    ADD CONSTRAINT product_categories_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_products_product_category product_category_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products_product_category
    ADD CONSTRAINT product_category_id FOREIGN KEY (product_category_id) REFERENCES public.acorn_lojistiks_product_categories(id);


--
-- Name: acorn_lojistiks_product_product_category product_category_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_product_category
    ADD CONSTRAINT product_category_id FOREIGN KEY (product_category_id) REFERENCES public.acorn_lojistiks_product_categories(id);


--
-- Name: acorn_lojistiks_product_categories product_category_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_categories
    ADD CONSTRAINT product_category_type_id FOREIGN KEY (product_category_type_id) REFERENCES public.acorn_lojistiks_product_category_types(id);


--
-- Name: acorn_lojistiks_product_category_types product_category_types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_category_types
    ADD CONSTRAINT product_category_types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_products_product_category product_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products_product_category
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.acorn_lojistiks_products(id);


--
-- Name: acorn_lojistiks_product_instances product_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instances
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.acorn_lojistiks_products(id);


--
-- Name: acorn_lojistiks_product_products product_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_products
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.acorn_lojistiks_products(id);


--
-- Name: acorn_lojistiks_product_attributes product_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_attributes
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.acorn_lojistiks_products(id);


--
-- Name: acorn_lojistiks_product_product_category product_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_product_category
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.acorn_lojistiks_products(id);


--
-- Name: acorn_lojistiks_product_instance_transfer product_instance_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instance_transfer
    ADD CONSTRAINT product_instance_id FOREIGN KEY (product_instance_id) REFERENCES public.acorn_lojistiks_product_instances(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfer_container_product_instance product_instance_transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT product_instance_transfer_id FOREIGN KEY (product_instance_transfer_id) REFERENCES public.acorn_lojistiks_product_instance_transfer(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_instances product_instances_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instances
    ADD CONSTRAINT product_instances_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_products product_products_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_products
    ADD CONSTRAINT product_products_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_products products_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products
    ADD CONSTRAINT products_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_products_product_category products_product_categories_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products_product_category
    ADD CONSTRAINT products_product_categories_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_product_category products_product_categories_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_product_category
    ADD CONSTRAINT products_product_categories_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_receipts purchase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_receipts
    ADD CONSTRAINT purchase_id FOREIGN KEY (purchase_id) REFERENCES public.acorn_finance_purchases(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfer_purchase purchase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_purchase
    ADD CONSTRAINT purchase_id FOREIGN KEY (purchase_id) REFERENCES public.acorn_finance_purchases(id) NOT VALID;


--
-- Name: acorn_criminal_defendant_detentions reason_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_detentions
    ADD CONSTRAINT reason_id FOREIGN KEY (detention_reason_id) REFERENCES public.acorn_criminal_detention_reasons(id) NOT VALID;


--
-- Name: acorn_justice_warrants revoked_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrants
    ADD CONSTRAINT revoked_at_event_id FOREIGN KEY (revoked_at_event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE SET NULL NOT VALID;


--
-- Name: acorn_user_user_group_version_user role_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_group_version_user
    ADD CONSTRAINT role_id FOREIGN KEY (role_id) REFERENCES public.acorn_user_roles(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfers sent_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfers
    ADD CONSTRAINT sent_at_event_id FOREIGN KEY (sent_at_event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE SET NULL NOT VALID;


--
-- Name: acorn_criminal_crime_sentences sentence_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_sentences
    ADD CONSTRAINT sentence_type_id FOREIGN KEY (sentence_type_id) REFERENCES public.acorn_criminal_sentence_types(id) NOT VALID;


--
-- Name: acorn_location_locations server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_gps server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_gps
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_addresses server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_area_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_area_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_areas server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_criminal_legalcases server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcases
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_lojistiks_measurement_units server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_measurement_units
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_products server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_product_instance_transfer server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instance_transfer
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_people server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_people
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_vehicle_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicle_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_containers server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_containers
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_vehicles server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicles
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_drivers server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_drivers
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_transfer_containers server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_containers
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_transfer_container_product_instance server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_product_category_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_category_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_product_categories server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_categories
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_products_product_category server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products_product_category
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_transfers server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfers
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_brands server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_brands
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_lojistiks_employees server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_employees
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_lojistiks_offices server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_offices
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_attributes server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_attributes
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_instances server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instances
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_lojistiks_warehouses server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_warehouses
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_lojistiks_suppliers server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_suppliers
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_products server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_products
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_justice_legalcases server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcases
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_plaintiffs server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_plaintiffs
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_evidence server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_evidence
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_witnesses server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_witnesses
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_defendants server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_defendants
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_trial_judges server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_judges
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_session_recordings server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_session_recordings
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_crimes server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crimes
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_crime_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_crime_sentences server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_sentences
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_sentence_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_sentence_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_finance_purchases server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_purchases
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_finance_invoices server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_identifiers server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_identifiers
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_justice_scanned_documents server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_scanned_documents
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_justice_warrants server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrants
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_finance_payments server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_payments
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_detention_methods server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_methods
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_detention_reasons server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_reasons
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_defendant_crimes server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_crimes
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_finance_currencies server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_currencies
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_categories server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_categories
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_justice_warrant_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrant_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_finance_receipts server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_receipts
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_product_category server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_product_category
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_lojistiks_product_products sub_product_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_products
    ADD CONSTRAINT sub_product_id FOREIGN KEY (sub_product_id) REFERENCES public.acorn_lojistiks_products(id);


--
-- Name: acorn_lojistiks_suppliers suppliers_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_suppliers
    ADD CONSTRAINT suppliers_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfer_containers transfer_container_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_containers
    ADD CONSTRAINT transfer_container_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfer_container_product_instance transfer_container_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT transfer_container_id FOREIGN KEY (transfer_container_id) REFERENCES public.acorn_lojistiks_transfer_containers(id);


--
-- Name: CONSTRAINT transfer_container_id ON acorn_lojistiks_transfer_container_product_instance; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT transfer_container_id ON public.acorn_lojistiks_transfer_container_product_instance IS 'type: Xto1';


--
-- Name: acorn_lojistiks_transfer_container_product_instance transfer_container_product_instances_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_container_product_instance
    ADD CONSTRAINT transfer_container_product_instances_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_instance_transfer transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instance_transfer
    ADD CONSTRAINT transfer_id FOREIGN KEY (transfer_id) REFERENCES public.acorn_lojistiks_transfers(id);


--
-- Name: acorn_lojistiks_transfer_containers transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_containers
    ADD CONSTRAINT transfer_id FOREIGN KEY (transfer_id) REFERENCES public.acorn_lojistiks_transfers(id);


--
-- Name: acorn_lojistiks_transfer_invoice transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_invoice
    ADD CONSTRAINT transfer_id FOREIGN KEY (transfer_id) REFERENCES public.acorn_lojistiks_transfers(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfer_purchase transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfer_purchase
    ADD CONSTRAINT transfer_id FOREIGN KEY (transfer_id) REFERENCES public.acorn_lojistiks_transfers(id) NOT VALID;


--
-- Name: acorn_criminal_defendant_detentions transfer_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_detentions
    ADD CONSTRAINT transfer_id FOREIGN KEY (transfer_id) REFERENCES public.acorn_lojistiks_transfers(id) NOT VALID;


--
-- Name: CONSTRAINT transfer_id ON acorn_criminal_defendant_detentions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT transfer_id ON public.acorn_criminal_defendant_detentions IS 'type: 1to1';


--
-- Name: acorn_lojistiks_transfers transfers_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfers
    ADD CONSTRAINT transfers_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_trial_judges trial_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_judges
    ADD CONSTRAINT trial_id FOREIGN KEY (trial_id) REFERENCES public.acorn_criminal_trials(id) NOT VALID;


--
-- Name: acorn_criminal_trial_sessions trial_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_sessions
    ADD CONSTRAINT trial_id FOREIGN KEY (trial_id) REFERENCES public.acorn_criminal_trials(id) NOT VALID;


--
-- Name: acorn_criminal_session_recordings trial_session_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_session_recordings
    ADD CONSTRAINT trial_session_id FOREIGN KEY (trial_session_id) REFERENCES public.acorn_criminal_trial_sessions(id) NOT VALID;


--
-- Name: acorn_location_locations type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT type_id FOREIGN KEY (type_id) REFERENCES public.acorn_location_types(id) NOT VALID;


--
-- Name: acorn_user_user_groups type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT type_id FOREIGN KEY (type_id) REFERENCES public.acorn_user_user_group_types(id) NOT VALID;


--
-- Name: acorn_justice_warrants type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrants
    ADD CONSTRAINT type_id FOREIGN KEY (warrant_type_id) REFERENCES public.acorn_justice_warrant_types(id) NOT VALID;


--
-- Name: acorn_location_types types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_justice_legalcases updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcases
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: CONSTRAINT updated_at_event_id ON acorn_justice_legalcases; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT updated_at_event_id ON public.acorn_justice_legalcases IS 'delete: true';


--
-- Name: acorn_criminal_crime_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_prosecutor updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_prosecutor
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_legalcase_category updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_legalcase_category
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_plaintiffs updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_plaintiffs
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_evidence updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_evidence
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_witnesses updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_witnesses
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_defendants updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_defendants
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_trial_judges updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_judges
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_session_recordings updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_session_recordings
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_crimes updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crimes
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_crime_sentences updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_sentences
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_sentence_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_sentence_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_drivers updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_drivers
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_employees updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_employees
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_offices updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_offices
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_measurement_units updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_measurement_units
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_finance_purchases updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_purchases
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_attributes updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_attributes
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_categories updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_categories
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_category_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_category_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_finance_invoices updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_identifiers updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_identifiers
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_instances updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instances
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_products updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_products
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_products updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_scanned_documents updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_scanned_documents
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_suppliers updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_suppliers
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_warrants updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrants
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfers updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfers
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_vehicle_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicle_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_vehicles updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicles
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_warehouses updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_warehouses
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_brands updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_brands
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_finance_payments updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_payments
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_defendant_crimes updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_crimes
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_detention_methods updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_methods
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_detention_reasons updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_reasons
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_finance_currencies updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_currencies
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_categories updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_categories
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_warrant_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrant_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_finance_receipts updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_receipts
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_lojistiks_containers updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_containers
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_legalcases updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcases
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_plaintiffs updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_plaintiffs
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_evidence updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_evidence
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_witnesses updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_witnesses
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_defendants updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_defendants
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_trial_judges updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_judges
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_session_recordings updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_session_recordings
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_crimes updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crimes
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_crime_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_crime_sentences updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_crime_sentences
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_sentence_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_sentence_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_employees updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_employees
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_offices updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_offices
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_measurement_units updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_measurement_units
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_purchases updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_purchases
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_categories updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_categories
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_category_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_category_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_invoices updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_invoices
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_instances updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_instances
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_products updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_products
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_products updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_products
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_identifiers updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_identifiers
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_suppliers updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_suppliers
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_scanned_documents updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_scanned_documents
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_warrants updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrants
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfers updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfers
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_vehicle_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicle_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_vehicles updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicles
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_warehouses updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_warehouses
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_brands updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_brands
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_product_attributes updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_product_attributes
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_payments updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_payments
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_detention_methods updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_methods
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_detention_reasons updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_reasons
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_defendant_crimes updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_defendant_crimes
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_currencies updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_currencies
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_legalcase_categories updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_legalcase_categories
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_warrant_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrant_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_finance_receipts updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_finance_receipts
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_containers updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_containers
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_drivers updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_drivers
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_location_locations user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id);


--
-- Name: acorn_criminal_legalcase_prosecutor user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_prosecutor
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: CONSTRAINT user_group_id ON acorn_criminal_legalcase_prosecutor; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_group_id ON public.acorn_criminal_legalcase_prosecutor IS 'nameObject: true';


--
-- Name: acorn_criminal_trial_judges user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_judges
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_user_user_group_versions user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_group_versions
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_user_user_group_version_user user_group_version_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_group_version_user
    ADD CONSTRAINT user_group_version_id FOREIGN KEY (user_group_version_id) REFERENCES public.acorn_user_user_group_versions(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_defendants user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_defendants
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: CONSTRAINT user_id ON acorn_criminal_legalcase_defendants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_id ON public.acorn_criminal_legalcase_defendants IS 'name-object: true';


--
-- Name: acorn_criminal_legalcase_prosecutor user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_prosecutor
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: CONSTRAINT user_id ON acorn_criminal_legalcase_prosecutor; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_id ON public.acorn_criminal_legalcase_prosecutor IS 'nameObject: true';


--
-- Name: acorn_criminal_legalcase_plaintiffs user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_plaintiffs
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: CONSTRAINT user_id ON acorn_criminal_legalcase_plaintiffs; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_id ON public.acorn_criminal_legalcase_plaintiffs IS 'name-object: true';


--
-- Name: acorn_criminal_legalcase_witnesses user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_witnesses
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: CONSTRAINT user_id ON acorn_criminal_legalcase_witnesses; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_id ON public.acorn_criminal_legalcase_witnesses IS 'name-object: true';


--
-- Name: acorn_criminal_trial_judges user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_trial_judges
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: CONSTRAINT user_id ON acorn_criminal_trial_judges; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_id ON public.acorn_criminal_trial_judges IS 'name-object: true';


--
-- Name: acorn_user_language_user user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_language_user
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_lojistiks_people user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_people
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: CONSTRAINT user_id ON acorn_lojistiks_people; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT user_id ON public.acorn_lojistiks_people IS 'type: 1to1
name-object: true';


--
-- Name: acorn_justice_warrants user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrants
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_user_user_group_version_user user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_group_version_user
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_employees user_role_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_employees
    ADD CONSTRAINT user_role_id FOREIGN KEY (user_role_id) REFERENCES public.acorn_user_roles(id) NOT VALID;


--
-- Name: acorn_lojistiks_transfers vehicle_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_transfers
    ADD CONSTRAINT vehicle_id FOREIGN KEY (vehicle_id) REFERENCES public.acorn_lojistiks_vehicles(id) NOT VALID;


--
-- Name: acorn_lojistiks_drivers vehicle_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_drivers
    ADD CONSTRAINT vehicle_id FOREIGN KEY (vehicle_id) REFERENCES public.acorn_lojistiks_vehicles(id) NOT VALID;


--
-- Name: acorn_lojistiks_vehicles vehicle_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicles
    ADD CONSTRAINT vehicle_type_id FOREIGN KEY (vehicle_type_id) REFERENCES public.acorn_lojistiks_vehicle_types(id);


--
-- Name: acorn_lojistiks_vehicle_types vehicle_types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicle_types
    ADD CONSTRAINT vehicle_types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_vehicles vehicles_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_vehicles
    ADD CONSTRAINT vehicles_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_lojistiks_warehouses warehouses_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_warehouses
    ADD CONSTRAINT warehouses_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: justice
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

