--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Ubuntu 16.9-1.pgdg24.04+1)
-- Dumped by pg_dump version 16.9 (Ubuntu 16.9-1.pgdg24.04+1)

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
-- Name: product; Type: SCHEMA; Schema: -; Owner: university
--

CREATE SCHEMA product;


ALTER SCHEMA product OWNER TO university;

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
-- Name: avg(double precision[]); Type: FUNCTION; Schema: public; Owner: sz
--

CREATE FUNCTION public.avg(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select avg(unnest) from (SELECT unnest(ints));
$$;


ALTER FUNCTION public.avg(VARIADIC ints double precision[]) OWNER TO sz;

--
-- Name: avg(integer[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.avg(VARIADIC ints integer[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select avg(unnest) from (SELECT unnest(ints));
$$;


ALTER FUNCTION public.avg(VARIADIC ints integer[]) OWNER TO university;

--
-- Name: count(double precision, double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.count(dp1 double precision, VARIADIC ints double precision[]) RETURNS integer
    LANGUAGE sql
    AS $$
	select array_length(ints,1) + 1;
$$;


ALTER FUNCTION public.count(dp1 double precision, VARIADIC ints double precision[]) OWNER TO university;

--
-- Name: count(integer, integer[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.count(i1 integer, VARIADIC ints integer[]) RETURNS integer
    LANGUAGE sql
    AS $$
	select array_length(ints,1) + 1;
$$;


ALTER FUNCTION public.count(i1 integer, VARIADIC ints integer[]) OWNER TO university;

--
-- Name: fn_acorn_add_websockets_triggers(character varying, character varying); Type: FUNCTION; Schema: public; Owner: university
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


ALTER FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) OWNER TO university;

--
-- Name: fn_acorn_calendar_create_activity_log_event(uuid, uuid, uuid, character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
            declare
calendar_id uuid;
            begin
            -- Calendar (system): acorn.justice::lang.plugin.activity_log
            -- Type: indicates the Model
            -- Status: indicates the action: create, update, delete, etc.
            calendar_id   := 'f3bc49bc-eac7-11ef-9e4a-1740a039dada';
            if not exists(select * from acorn_calendar_calendars where "id" = 'f3bc49bc-eac7-11ef-9e4a-1740a039dada'::uuid) then
                -- Just in case database seeding is happening before calendar seeding, or the system types have been deleted
                perform public.fn_acorn_calendar_seed();
            end if;
	
            return public.fn_acorn_calendar_create_event(calendar_id, owner_user_id, type_id, status_id, name);
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) OWNER TO university;

--
-- Name: fn_acorn_calendar_create_event(uuid, uuid, uuid, uuid, character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
            
            begin
            return public.fn_acorn_calendar_create_event(calendar_id, owner_user_id, type_id, status_id, name, now()::timestamp without time zone, now()::timestamp without time zone);
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) OWNER TO university;

--
-- Name: fn_acorn_calendar_create_event(uuid, uuid, uuid, uuid, character varying, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
            declare

                new_event_id uuid;
            begin
            insert into public.acorn_calendar_events(calendar_id, owner_user_id) 
                values(calendar_id, owner_user_id) returning id into new_event_id;
            insert into public.acorn_calendar_event_parts(event_id, type_id, status_id, name, start, "end") 
                values(new_event_id, event_type_id, event_status_id, name, date_from, date_to);
            return new_event_id;
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) OWNER TO university;

--
-- Name: fn_acorn_calendar_events_generate_event_instances(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_events_generate_event_instances() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            
            begin
            return public.fn_acorn_calendar_generate_event_instances(NEW, OLD);
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_events_generate_event_instances() OWNER TO university;

--
-- Name: fn_acorn_calendar_generate_event_instances(record, record); Type: FUNCTION; Schema: public; Owner: university
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


ALTER FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) OWNER TO university;

--
-- Name: fn_acorn_calendar_is_date(character varying, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
            
            begin

                if s is null then
                    return d;
                end if;
                perform s::timestamp without time zone;
                    return s;
                exception when others then
                    return d;
            
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp without time zone) OWNER TO university;

--
-- Name: fn_acorn_calendar_lazy_create_event(character varying, uuid, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
            declare
event_calendar_id uuid;
event_type_id uuid;
event_status_id  uuid;
            begin
            -- Lazy creates
            select into event_calendar_id id from acorn_calendar_calendars where name = calendar_name;
            if event_calendar_id is null then
                insert into acorn_calendar_calendars(name) values(calendar_name) returning id into event_calendar_id;
            end if;
        
            select into event_type_id id from acorn_calendar_event_types where name = type_name;
            if event_type_id is null then
                insert into acorn_calendar_event_types(name, calendar_id) values(type_name, event_calendar_id) returning id into event_type_id;
            end if;
        
            select into event_status_id id from acorn_calendar_event_statuses where name = status_name;
            if event_status_id is null then
                insert into acorn_calendar_event_statuses(name, calendar_id) values(status_name, event_calendar_id) returning id into event_status_id;
            end if;
        
            return public.fn_acorn_calendar_create_event(event_calendar_id, owner_user_id, event_type_id, event_status_id, event_name);
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) OWNER TO university;

--
-- Name: fn_acorn_calendar_seed(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_seed() RETURNS void
    LANGUAGE plpgsql
    AS $$
            
            begin
            -- Default calendars, with hardcoded ids
            if not exists(select * from acorn_calendar_calendars where "id" = 'ceea8856-e4c8-11ef-8719-5f58c97885a2'::uuid) then
                insert into acorn_calendar_calendars(id, "name", "system") 
                    values('ceea8856-e4c8-11ef-8719-5f58c97885a2'::uuid, 'Default', true);
            end if;
            if not exists(select * from acorn_calendar_calendars where "id" = 'f3bc49bc-eac7-11ef-9e4a-1740a039dada'::uuid) then
                insert into acorn_calendar_calendars(id, "name", "system") 
                    values('f3bc49bc-eac7-11ef-9e4a-1740a039dada'::uuid, 'Activity Log', true);
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
            -- Types for each table in the activity log are lazy created
            if not exists(select * from acorn_calendar_event_types where "id" = '2f766546-e4c9-11ef-be8c-1f2daa98a10f'::uuid) then
                insert into acorn_calendar_event_types(id, "name", "system", "colour", "style") 
                    values('2f766546-e4c9-11ef-be8c-1f2daa98a10f'::uuid, 'Normal', TRUE, '#091386', 'color:#fff');
            end if;
            if not exists(select * from acorn_calendar_event_types where "name" = 'Meeting') then
                insert into acorn_calendar_event_types("name", "system", "colour", "style") 
                    values('Meeting', TRUE, '#C0392B', 'color:#fff');
            end if;

            -- Activity log statuses: TG_OP / Soft DELETE
            if not exists(select * from acorn_calendar_event_statuses where "id" = '7b432540-eac8-11ef-a9bc-434841a9f67b'::uuid) then
                insert into acorn_calendar_event_statuses(id, "name", "system", "style") 
                    values('7b432540-eac8-11ef-a9bc-434841a9f67b'::uuid, 'acorn.calendar::lang.models.general.insert', TRUE, 'color:#fff');
            end if;
            if not exists(select * from acorn_calendar_event_statuses where "id" = '7c18bb7e-eac8-11ef-b4f2-ffae3296f461'::uuid) then
                insert into acorn_calendar_event_statuses(id, "name", "system", "style") 
                    values('7c18bb7e-eac8-11ef-b4f2-ffae3296f461'::uuid, 'acorn.calendar::lang.models.general.update', TRUE, 'color:#fff');
            end if;
            -- Soft DELETE (Actually an UPDATE TG_OP)
            if not exists(select * from acorn_calendar_event_statuses where "id" = '7ceca4c0-eac8-11ef-b685-f7f3f278f676'::uuid) then
                insert into acorn_calendar_event_statuses(id, "name", "system", "style") 
                    values('7ceca4c0-eac8-11ef-b685-f7f3f278f676'::uuid, 'acorn.calendar::lang.models.general.soft_delete', TRUE, 'color:#fff');
            end if;
            if not exists(select * from acorn_calendar_event_statuses where "id" = 'f9690600-eac9-11ef-8002-5b2cbe0c12c0'::uuid) then
                insert into acorn_calendar_event_statuses(id, "name", "system", "style") 
                    values('f9690600-eac9-11ef-8002-5b2cbe0c12c0'::uuid, 'acorn.calendar::lang.models.general.soft_undelete', TRUE, 'color:#fff');
            end if;
end;
            $$;


ALTER FUNCTION public.fn_acorn_calendar_seed() OWNER TO university;

--
-- Name: fn_acorn_calendar_trigger_activity_event(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_trigger_activity_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            declare
name_optional character varying(2048);
soft_delete_optional boolean = false;
table_comment character varying(16384);
type_name character varying(1024);
title character varying(1024);
owner_user_id uuid;
event_type_id uuid;
event_status_id uuid;
activity_log_calendar_id uuid = 'f3bc49bc-eac7-11ef-9e4a-1740a039dada';
            begin
            -- See also: fn_acorn_calendar_create_activity_log_event()
            -- Calendar (system): acorn.justice::lang.plugin.activity_log
            -- Type: indicates the Plugin & Model, e.g. "Criminal Trials"
            -- Status: indicates the action: INSERT, UPDATE, DELETE, or other custom

            -- This trigger function should only be used on final content tables
            -- This is a generic trigger. Some fields are required, others optional
            -- We use PG system catalogs because they are faster
            -- TODO: Process name-object linkage
            
            if not exists(select * from acorn_calendar_calendars where "id" = 'f3bc49bc-eac7-11ef-9e4a-1740a039dada'::uuid) then
                -- Just in case database seeding is happening before calendar seeding, or the system types have been deleted
                perform public.fn_acorn_calendar_seed();
            end if;
            
            -- Required fields
            -- created_at_event_id
            -- updated_at_event_id
            owner_user_id := NEW.created_by_user_id; -- NOT NULL
            type_name     := initcap(replace(replace(TG_TABLE_NAME, 'acorn_', ''), '_', ' '));
            title         := initcap(TG_OP) || ' ' || type_name;

            -- Optional fields
            if exists(SELECT * FROM pg_attribute WHERE attrelid = TG_RELID AND attname = 'name') then name_optional := NEW.name; end if;
            if not name_optional is null then title = title || ':' || name_optional; end if;
            if exists(SELECT * FROM pg_attribute WHERE attrelid = TG_RELID AND attname = 'deleted_at') then soft_delete_optional := true; end if;

            -- TODO: Allow control from the table comment over event creation
            table_comment := obj_description(concat(TG_TABLE_SCHEMA, '.', TG_TABLE_NAME)::regclass, 'pg_class');

            -- Type: lang TG_TABLE_SCHEMA.TG_TABLE_NAME, acorn.justice::lang.models.related_events.label
            select into event_type_id id from acorn_calendar_event_types 
                where activity_log_related_oid = TG_RELID;
            if event_type_id is null then
                -- TODO: Colour?
                -- TODO: acorn.?::lang.models.?.label
                insert into public.acorn_calendar_event_types(name, activity_log_related_oid, calendar_id) 
                    values(type_name, TG_RELID, activity_log_calendar_id) returning id into event_type_id;
            end if;

            -- Scenarios
            case 
                when TG_OP = 'INSERT' then
                    -- Just in case the framework has specified it
                    if NEW.created_at_event_id is null then
                        -- Create event
                        event_status_id         := '7b432540-eac8-11ef-a9bc-434841a9f67b'; -- INSERT
                        NEW.created_at_event_id := public.fn_acorn_calendar_create_activity_log_event(owner_user_id, event_type_id, event_status_id, title);
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
                    
                    -- Update event
                    if NEW.updated_at_event_id is null then
                        -- Create the initial Update event for this item
                        NEW.created_at_event_id := public.fn_acorn_calendar_create_activity_log_event(owner_user_id, event_type_id, event_status_id, title);
                    else
                        -- Add a new event part to the same updated event
                        insert into public.acorn_calendar_event_parts(event_id, type_id, status_id, name, start, "end")
                            select event_id, type_id, status_id, name, now(), now() 
                            from public.acorn_calendar_event_parts 
                            where event_id = NEW.updated_at_event_id limit 1;
                    end if;
            end case;

            return NEW;
end;
            
$$;


ALTER FUNCTION public.fn_acorn_calendar_trigger_activity_event() OWNER TO university;

--
-- Name: fn_acorn_exam_token_name(character varying[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_exam_token_name(VARIADIC p_titles character varying[]) RETURNS character varying
    LANGUAGE sql
    AS $$
select fn_acorn_exam_token_name_internal(p_titles);
$$;


ALTER FUNCTION public.fn_acorn_exam_token_name(VARIADIC p_titles character varying[]) OWNER TO university;

--
-- Name: fn_acorn_exam_token_name(uuid, character varying[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_exam_token_name(p_id uuid, VARIADIC p_titles character varying[]) RETURNS character varying
    LANGUAGE sql
    AS $$
select fn_acorn_exam_token_name_internal(array_prepend(p_id::character varying, p_titles));
$$;


ALTER FUNCTION public.fn_acorn_exam_token_name(p_id uuid, VARIADIC p_titles character varying[]) OWNER TO university;

--
-- Name: fn_acorn_exam_token_name_internal(character varying[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_exam_token_name_internal(p_titles character varying[]) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
	token character varying = '';
	record record;
begin
	for record in select unnest as title from unnest(p_titles) loop
		if not record.title is null and length(record.title) > 0 then
			if length(token) > 0 then token := token || '/'; end if;
			token := token || regexp_replace(lower(record.title), '[^a-z0-9:.]+', '-', 1, 0, 'g');
		end if;
	end loop;

	return token;
end;
$$;


ALTER FUNCTION public.fn_acorn_exam_token_name_internal(p_titles character varying[]) OWNER TO university;

--
-- Name: fn_acorn_exam_tokenize(character varying, integer); Type: FUNCTION; Schema: public; Owner: sz
--

CREATE FUNCTION public.fn_acorn_exam_tokenize(p_expr character varying, level integer DEFAULT 0) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
declare
	token_record record;
	expression_record record;
	is_multiple bool;
	result1 double precision;
	results double precision[];
	"result" double precision;
begin
	-- Recursively replace all the tokens in the expr with the final value
	-- Only running the eval for the selected tokens, not the whole view
	raise notice '%: Expression(%)', level, p_expr;
	
	for token_record in select 
			array_agg(regexp_replace(id, '^[^:]*::', '')) as name, 
			array_agg("expression") as expressions, 
			regexp_matches[1] as match, 
			regexp_matches[2] as match_name
		from acorn_exam_tokens est, 
		regexp_matches(p_expr, '(:([^ )(:=]+)=?([0-9.]*):)', 'g')
		where regexp_like(regexp_replace(id, '^[^:]*::', ''), concat('^', regexp_matches[2], '$'))
		group by match, match_name
	loop
		-- Now we have 1/multiple expressions for each :token.*:
		-- some of which will lead to a recursive evaluation, some not
		results := '{}';
		raise notice '  matched(%, %)', token_record.name, token_record.match_name;
		
		for expression_record in select unnest as "expression" from unnest(token_record.expressions)
		loop
			raise notice '    Sub-Expression(%)', expression_record.expression;
			result1 := fn_acorn_exam_tokenize(expression_record.expression, "level"+1);
			raise notice '      => %', result1;
			results := array_append(results, result1);
		end loop;
		
		p_expr := replace(p_expr, token_record.match, array_to_string(results, ','));
	end loop;

	-- Defaults
	for token_record in select regexp_matches[1] as match, regexp_matches[2] as match_default
		from regexp_matches(p_expr, '(:[^ )(:=]+=([0-9.]+):)', 'g')
		group by match, match_default
	loop
		p_expr := replace(p_expr, token_record.match, token_record.match_default);
	end loop;

	-- NULL if un-resolved tokens remain
	if array_length(regexp_match(p_expr, '(:([^ )(:]+):)'), 1) != 0 then
		p_expr := 'NULL';
	end if;

	-- No replacements, no tokens
	-- Run the eval
	raise notice '  No match, evaluating(%)', p_expr;
	execute concat('select ', p_expr) into "result";

	return "result";
end;
$_$;


ALTER FUNCTION public.fn_acorn_exam_tokenize(p_expr character varying, level integer) OWNER TO sz;

--
-- Name: fn_acorn_first(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_first(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
            
            SELECT $1;
            $_$;


ALTER FUNCTION public.fn_acorn_first(anyelement, anyelement) OWNER TO university;

--
-- Name: fn_acorn_last(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_last(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
            
            SELECT $2;
            $_$;


ALTER FUNCTION public.fn_acorn_last(anyelement, anyelement) OWNER TO university;

--
-- Name: fn_acorn_new_replicated_row(); Type: FUNCTION; Schema: public; Owner: university
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


ALTER FUNCTION public.fn_acorn_new_replicated_row() OWNER TO university;

--
-- Name: fn_acorn_reset_sequences(character varying, character varying); Type: FUNCTION; Schema: public; Owner: university
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


ALTER FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) OWNER TO university;

--
-- Name: fn_acorn_server_id(); Type: FUNCTION; Schema: public; Owner: university
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


ALTER FUNCTION public.fn_acorn_server_id() OWNER TO university;

--
-- Name: fn_acorn_table_counts(character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_table_counts(_schema character varying) RETURNS TABLE("table" text, count bigint)
    LANGUAGE plpgsql
    AS $$
            
            begin
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


ALTER FUNCTION public.fn_acorn_table_counts(_schema character varying) OWNER TO university;

--
-- Name: fn_acorn_truncate_database(character varying, character varying); Type: FUNCTION; Schema: public; Owner: university
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


ALTER FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) OWNER TO university;

--
-- Name: fn_acorn_user_get_seed_user(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_user_get_seed_user() RETURNS uuid
    LANGUAGE plpgsql
    AS $$
            declare
user_id uuid;
            begin
            -- Lazy create the seeder user
            select into user_id uu.id 
                from public.acorn_user_users uu
                where name = 'seeder' and is_system_user limit 1;
            if user_id is null then
                insert into public.acorn_user_users(name, is_system_user)
                    values('seeder', true) 
                    returning id into user_id;
            end if;
            
            
            return user_id;
end;
            $$;


ALTER FUNCTION public.fn_acorn_user_get_seed_user() OWNER TO university;

--
-- Name: max(double precision[]); Type: FUNCTION; Schema: public; Owner: sz
--

CREATE FUNCTION public.max(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select max(unnest) from (SELECT unnest(ints));
$$;


ALTER FUNCTION public.max(VARIADIC ints double precision[]) OWNER TO sz;

--
-- Name: max(integer[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.max(VARIADIC ints integer[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select max(unnest) from (SELECT unnest(ints));
$$;


ALTER FUNCTION public.max(VARIADIC ints integer[]) OWNER TO university;

--
-- Name: min(double precision[]); Type: FUNCTION; Schema: public; Owner: sz
--

CREATE FUNCTION public.min(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select min(unnest) from (SELECT unnest(ints));
$$;


ALTER FUNCTION public.min(VARIADIC ints double precision[]) OWNER TO sz;

--
-- Name: min(integer[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.min(VARIADIC ints integer[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select min(unnest) from (SELECT unnest(ints));
$$;


ALTER FUNCTION public.min(VARIADIC ints integer[]) OWNER TO university;

--
-- Name: sum(double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.sum(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select sum(unnest) from unnest(ints);
$$;


ALTER FUNCTION public.sum(VARIADIC ints double precision[]) OWNER TO university;

--
-- Name: sum(integer[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.sum(VARIADIC ints integer[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select sum(unnest) from unnest(ints);
$$;


ALTER FUNCTION public.sum(VARIADIC ints integer[]) OWNER TO university;

--
-- Name: sum(character varying); Type: FUNCTION; Schema: public; Owner: sz
--

CREATE FUNCTION public.sum(ints character varying) RETURNS integer
    LANGUAGE sql
    AS $$
	select sum(unnest) from (SELECT unnest(ints::integer[]))
$$;


ALTER FUNCTION public.sum(ints character varying) OWNER TO sz;

--
-- Name: sumproduct(double precision[]); Type: FUNCTION; Schema: public; Owner: sz
--

CREATE FUNCTION public.sumproduct(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
declare
	len int;
	result double precision;
	values double precision[];
	weights double precision[];
begin
	len     := array_upper(ints,1) / 2;
	values  := ints[1:len];
	weights := ints[len+1:];

	result := 0;
	for i in 1..len loop
		result := result + (values[i] * weights[i]);
	end loop;

	return result;
end
$$;


ALTER FUNCTION public.sumproduct(VARIADIC ints double precision[]) OWNER TO sz;

--
-- Name: sumproduct(integer[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.sumproduct(VARIADIC ints integer[]) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
declare
	len int;
	result int;
	values int[];
	weights int[];
begin
	len     := array_upper(ints,1) / 2;
	values  := ints[1:len];
	weights := ints[len+1:];

	result := 0;
	for i in 1..len loop
		result := result + (values[i] * weights[i]);
	end loop;

	return result;
end
$$;


ALTER FUNCTION public.sumproduct(VARIADIC ints integer[]) OWNER TO university;

--
-- Name: sums(integer[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.sums(VARIADIC ints integer[]) RETURNS integer
    LANGUAGE sql
    AS $$
select sum(unnest) from unnest(ints);
$$;


ALTER FUNCTION public.sums(VARIADIC ints integer[]) OWNER TO university;

--
-- Name: agg_acorn_first(anyelement); Type: AGGREGATE; Schema: public; Owner: university
--

CREATE AGGREGATE public.agg_acorn_first(anyelement) (
    SFUNC = public.fn_acorn_first,
    STYPE = anyelement,
    PARALLEL = safe
);


ALTER AGGREGATE public.agg_acorn_first(anyelement) OWNER TO university;

--
-- Name: agg_acorn_last(anyelement); Type: AGGREGATE; Schema: public; Owner: university
--

CREATE AGGREGATE public.agg_acorn_last(anyelement) (
    SFUNC = public.fn_acorn_last,
    STYPE = anyelement,
    PARALLEL = safe
);


ALTER AGGREGATE public.agg_acorn_last(anyelement) OWNER TO university;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acorn_calendar_calendars; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_calendars (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    system boolean DEFAULT false NOT NULL,
    sync_file character varying(4096),
    sync_format integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:14.674386'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    owner_user_id uuid,
    owner_user_group_id uuid,
    permissions integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.acorn_calendar_calendars OWNER TO university;

--
-- Name: TABLE acorn_calendar_calendars; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_calendars IS 'package-type: plugin
table-type: content';


--
-- Name: acorn_calendar_event_part_user; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_event_part_user (
    event_part_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:15.233983'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_calendar_event_part_user OWNER TO university;

--
-- Name: TABLE acorn_calendar_event_part_user; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_event_part_user IS 'table-type: content';


--
-- Name: acorn_calendar_event_part_user_group; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_event_part_user_group (
    event_part_id uuid NOT NULL,
    user_group_id uuid NOT NULL
);


ALTER TABLE public.acorn_calendar_event_part_user_group OWNER TO university;

--
-- Name: acorn_calendar_event_parts; Type: TABLE; Schema: public; Owner: university
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
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:15.006774'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    repeat interval,
    alarm interval,
    instances_deleted integer[]
);


ALTER TABLE public.acorn_calendar_event_parts OWNER TO university;

--
-- Name: TABLE acorn_calendar_event_parts; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_event_parts IS 'table-type: content';


--
-- Name: acorn_calendar_event_statuses; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_event_statuses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    style character varying(255),
    system boolean DEFAULT false NOT NULL,
    calendar_id uuid,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_calendar_event_statuses OWNER TO university;

--
-- Name: TABLE acorn_calendar_event_statuses; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_event_statuses IS 'table-type: content';


--
-- Name: acorn_calendar_event_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_event_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    description text,
    whole_day boolean DEFAULT false NOT NULL,
    colour character varying(16) DEFAULT '#333'::character varying,
    style character varying(2048),
    system boolean DEFAULT false NOT NULL,
    activity_log_related_oid integer,
    calendar_id uuid,
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:14.760966'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_calendar_event_types OWNER TO university;

--
-- Name: TABLE acorn_calendar_event_types; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_event_types IS 'table-type: content';


--
-- Name: acorn_calendar_events; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    calendar_id uuid NOT NULL,
    external_url character varying(2048),
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:14.902277'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    owner_user_id uuid NOT NULL,
    owner_user_group_id uuid,
    permissions integer DEFAULT 79 NOT NULL
);


ALTER TABLE public.acorn_calendar_events OWNER TO university;

--
-- Name: TABLE acorn_calendar_events; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_events IS 'table-type: content';


--
-- Name: acorn_calendar_instances; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_calendar_instances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    date date NOT NULL,
    event_part_id uuid NOT NULL,
    instance_num integer NOT NULL,
    instance_start timestamp(0) without time zone NOT NULL,
    instance_end timestamp(0) without time zone NOT NULL
);


ALTER TABLE public.acorn_calendar_instances OWNER TO university;

--
-- Name: TABLE acorn_calendar_instances; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_instances IS 'table-type: content';


--
-- Name: acorn_exam_calculations; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_calculations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) DEFAULT 'calculation'::character varying NOT NULL,
    description text,
    expression character varying(2048) NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_calculations OWNER TO university;

--
-- Name: TABLE acorn_exam_calculations; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_calculations IS 'seeding:
  - [''15f02b5c-2bff-11f0-8074-4bf737ba6a74'', ''avg'', NULL, ''avg(:<student>.*.result:)'']';


--
-- Name: acorn_exam_data_entry_scores; Type: VIEW; Schema: public; Owner: university
--

CREATE VIEW public.acorn_exam_data_entry_scores AS
SELECT
    NULL::uuid AS student_user_id,
    NULL::uuid AS student_id,
    NULL::character varying(1024) AS student_code,
    NULL::uuid AS course_user_group_id,
    NULL::character varying(255) AS course_code,
    NULL::uuid AS exam_id,
    NULL::json AS ids,
    NULL::json AS student_ids,
    NULL::json AS exam_material_ids,
    NULL::json AS titles,
    NULL::json AS scores;


ALTER VIEW public.acorn_exam_data_entry_scores OWNER TO university;

--
-- Name: COLUMN acorn_exam_data_entry_scores.student_user_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.student_user_id IS 'extra-foreign-key: 
  table: acorn_user_users
  comment:
    tab-location: 2
labels:
  en: Student
labels-plural:
  en: Students';


--
-- Name: COLUMN acorn_exam_data_entry_scores.student_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.student_id IS 'extra-foreign-key: 
  table: acorn_university_students
  comment:
    tab-location: 2
labels:
  en: Student
labels-plural:
  en: Students';


--
-- Name: COLUMN acorn_exam_data_entry_scores.student_code; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.student_code IS 'sortable: true
sql-select: acorn_exam_data_entry_scores.student_code';


--
-- Name: COLUMN acorn_exam_data_entry_scores.course_user_group_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.course_user_group_id IS 'extra-foreign-key: 
  table: acorn_user_user_groups
  comment:
    tab-location: 2
labels:
  en: Course
labels-plural:
  en: Courses';


--
-- Name: COLUMN acorn_exam_data_entry_scores.course_code; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.course_code IS 'sortable: true
sql-select: acorn_exam_data_entry_scores.course_code';


--
-- Name: COLUMN acorn_exam_data_entry_scores.exam_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.exam_id IS 'extra-foreign-key: 
  table: acorn_exam_exams
  comment:
    tab-location: 2';


--
-- Name: COLUMN acorn_exam_data_entry_scores.ids; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.ids IS 'invisible: true';


--
-- Name: COLUMN acorn_exam_data_entry_scores.student_ids; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.student_ids IS 'invisible: true';


--
-- Name: COLUMN acorn_exam_data_entry_scores.exam_material_ids; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.exam_material_ids IS 'invisible: true';


--
-- Name: COLUMN acorn_exam_data_entry_scores.titles; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.titles IS 'invisible: true';


--
-- Name: COLUMN acorn_exam_data_entry_scores.scores; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_data_entry_scores.scores IS 'list-editable: delete-on-null';


--
-- Name: acorn_exam_exam_materials; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_exam_materials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    exam_id uuid NOT NULL,
    course_material_id uuid NOT NULL,
    required boolean DEFAULT false NOT NULL,
    minimum integer DEFAULT 0 NOT NULL,
    maximum integer DEFAULT 100 NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    weight double precision,
    interview_id uuid,
    project_id uuid
);


ALTER TABLE public.acorn_exam_exam_materials OWNER TO university;

--
-- Name: TABLE acorn_exam_exam_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_exam_materials IS 'menu: false
attribute-functions:
  name: return $this->course_material->name . ''::'' . $this->exam->name;
labels:
  en: Material Exam
labels-plural:
  en: Material Exams';


--
-- Name: COLUMN acorn_exam_exam_materials.minimum; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_exam_materials.minimum IS 'list-editable: true';


--
-- Name: COLUMN acorn_exam_exam_materials.maximum; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_exam_materials.maximum IS 'list-editable: true';


--
-- Name: acorn_exam_exams; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_exams (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) DEFAULT 'exam'::character varying NOT NULL,
    description text,
    type_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_exams OWNER TO university;

--
-- Name: TABLE acorn_exam_exams; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_exams IS 'order: 10
seeding:
  - [''0816bbee-2bdd-11f0-8400-57e43cb8bcc9'', ''Theory'', '''', ''cb58f452-28e3-11f0-bf77-eb3094eae79e'']
  - [''fb9806d4-2beb-11f0-9893-2ba7af07260a'', ''Laboratory'', '''', ''c2975b06-28e3-11f0-a996-1f7fab9642e9'']';


--
-- Name: acorn_exam_interview_students; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_interview_students (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    interview_id uuid NOT NULL,
    student_id uuid NOT NULL,
    teacher_id uuid,
    event_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    score double precision,
    course_material_id uuid
);


ALTER TABLE public.acorn_exam_interview_students OWNER TO university;

--
-- Name: TABLE acorn_exam_interview_students; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_interview_students IS 'menu: false
attribute-functions:
  name: return $this->interview->name;
labels:
  en: Student Interview
labels-plural:
  en: Student Interviews';


--
-- Name: COLUMN acorn_exam_interview_students.score; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_interview_students.score IS 'list-editable: true';


--
-- Name: acorn_exam_interviews; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_interviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying DEFAULT 'interview'::character varying NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_interviews OWNER TO university;

--
-- Name: TABLE acorn_exam_interviews; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_interviews IS 'seeding:
  - [''24dfbe1a-2bec-11f0-b616-ff9185a69d8b'', ''Example Interview'']';


--
-- Name: acorn_exam_scores; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_scores (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    exam_material_id uuid NOT NULL,
    score double precision NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    student_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_scores OWNER TO university;

--
-- Name: TABLE acorn_exam_scores; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_scores IS 'order: 35
attribute-functions:
  name: return $this->exam_material->name;';


--
-- Name: COLUMN acorn_exam_scores.score; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_scores.score IS 'list-editable: true';


--
-- Name: acorn_exam_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_exam_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) DEFAULT 'exam'::character varying NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_exam_types OWNER TO university;

--
-- Name: TABLE acorn_exam_types; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_exam_types IS 'order: 40
menu-splitter: true
seeding:
  - [''c2975b06-28e3-11f0-a996-1f7fab9642e9'', ''laboratory'']
  - [''cb58f452-28e3-11f0-bf77-eb3094eae79e'', ''theory'']
labels:
  en: Exam Type
labels-plural:
  en: Exam Types';


--
-- Name: acorn_university_course_materials; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_course_materials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    course_id uuid NOT NULL,
    material_id uuid NOT NULL,
    required boolean DEFAULT false NOT NULL,
    minimum integer DEFAULT 0 NOT NULL,
    maximum integer DEFAULT 100 NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    weight double precision,
    semester_year_id uuid NOT NULL,
    academic_year_id uuid NOT NULL,
    calculation_id uuid
);


ALTER TABLE public.acorn_university_course_materials OWNER TO university;

--
-- Name: TABLE acorn_university_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_course_materials IS 'attribute-functions:
  name: return $this->course?->entity->user_group->name . ''::'' . $this->material?->name;
seeding:
  # Jineologi
  - [''7250f0de-2be6-11f0-8437-3f38a27f0d25'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''005bba60-28bf-11f0-bf7f-cff663f8102b'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''72f6f98e-2be6-11f0-95e8-5feec68b4c60'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''cdc800ae-28be-11f0-a8a6-334555029afd'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''7336f566-2be6-11f0-b65c-377fa17f9a2c'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''d43af2a2-2bd9-11f0-b08b-5fd59b502470'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''737250c0-2be6-11f0-832f-9f9b2f075784'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''d675a530-28be-11f0-a2c9-9bb10fa15bd3'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''73ab76c0-2be6-11f0-bbac-dfa07554b168'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''d8168f4e-2bd9-11f0-97a5-1b42cf640b5b'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''73e00d9a-2be6-11f0-bf6f-5f78a750b209'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''d84f8434-2bd9-11f0-bfa1-7b92380571bd'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''7419875a-2be6-11f0-bf3e-13eea1a5d3c8'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''d88f0f6e-2bd9-11f0-8846-8bc9dcb96017'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''745124c6-2be6-11f0-801e-ff295edc2ab4'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''dd494c0e-28be-11f0-94e1-a7b2083dd749'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''9eae5f86-2be6-11f0-b57a-f7e9398cd276'', ''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''e427a282-28be-11f0-8856-a7abd8a449c5'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  # Bakeloria - Science
  - [''d60faf78-2d91-11f0-91b5-4ba74601f388'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''005bba60-28bf-11f0-bf7f-cff663f8102b'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d7166b8c-2d91-11f0-8b19-e7d49c2e84f1'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''cdc800ae-28be-11f0-a8a6-334555029afd'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d73d936a-2d91-11f0-8dd0-ffdc026241e6'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''d43af2a2-2bd9-11f0-b08b-5fd59b502470'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d7613d74-2d91-11f0-a545-27a082b4a92e'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''d675a530-28be-11f0-a2c9-9bb10fa15bd3'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d781623e-2d91-11f0-9bd6-b7cc61913303'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''d8168f4e-2bd9-11f0-97a5-1b42cf640b5b'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d7a990f6-2d91-11f0-95db-c330df9f103b'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''d84f8434-2bd9-11f0-bfa1-7b92380571bd'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d7ceec66-2d91-11f0-b5d5-db13369d9435'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''d88f0f6e-2bd9-11f0-8846-8bc9dcb96017'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d7f26d1c-2d91-11f0-a26f-f3e5473b3167'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''dd494c0e-28be-11f0-94e1-a7b2083dd749'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d815764a-2d91-11f0-a5ef-777bd9a16cd2'', ''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''e427a282-28be-11f0-8856-a7abd8a449c5'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  # Bakeloria - Literature
  - [''d83b7214-2d91-11f0-81ee-973d6ea6519e'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''005bba60-28bf-11f0-bf7f-cff663f8102b'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d85ee15e-2d91-11f0-9803-377e2ac811b1'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''cdc800ae-28be-11f0-a8a6-334555029afd'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d882e05e-2d91-11f0-90fa-83869ea90163'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''d43af2a2-2bd9-11f0-b08b-5fd59b502470'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d8a62a8c-2d91-11f0-92aa-97044e472505'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''d675a530-28be-11f0-a2c9-9bb10fa15bd3'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d8c70de2-2d91-11f0-adfc-f320089c0508'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''d8168f4e-2bd9-11f0-97a5-1b42cf640b5b'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d8ed5b64-2d91-11f0-a8f4-d31ec556c6aa'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''d84f8434-2bd9-11f0-bfa1-7b92380571bd'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d912a6bc-2d91-11f0-800e-6f442946f1de'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''d88f0f6e-2bd9-11f0-8846-8bc9dcb96017'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d93839f4-2d91-11f0-8f84-6ba6e9d7e17e'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''dd494c0e-28be-11f0-94e1-a7b2083dd749'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']
  - [''d95cc1d4-2d91-11f0-9084-33d5bf8f0fe0'', ''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''e427a282-28be-11f0-8856-a7abd8a449c5'', false, 0, 100, 50, ''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'']

';


--
-- Name: COLUMN acorn_university_course_materials.minimum; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_materials.minimum IS 'list-editable: true';


--
-- Name: COLUMN acorn_university_course_materials.maximum; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_materials.maximum IS 'list-editable: true';


--
-- Name: COLUMN acorn_university_course_materials.weight; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_course_materials.weight IS 'list-editable: true';


--
-- Name: acorn_university_courses; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_courses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    weight double precision,
    calculation_id uuid
);


ALTER TABLE public.acorn_university_courses OWNER TO university;

--
-- Name: TABLE acorn_university_courses; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_courses IS 'order: 60
seeding:
  - [''66d3ca90-1b6c-11f0-90cc-a77dd8e640be'', ''204c8a80-1b5d-11f0-9a78-07337e2f1cca'']
  - [''ffc92184-2d8f-11f0-9f2f-af2e2a870b91'', ''c555e604-2d8f-11f0-b535-bb3e95f882b4'']
  - [''001382ce-2d90-11f0-b3fe-bf0261495ded'', ''c5b7ccb6-2d8f-11f0-9338-4fa17b2a6436'']
';


--
-- Name: acorn_university_entities; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_entities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_group_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_entities OWNER TO university;

--
-- Name: TABLE acorn_university_entities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_entities IS 'menu: false
order: -100
seeding-other:
  acorn_user_user_groups:
    - [''2c4251c8-2cf9-11f0-bbd1-3370778ee65e'', ''Education Committee'', ''EDU'', NULL, NULL, NULL, NULL, 0, 0, 0]
    - [''cae7ba7c-1b63-11f0-8a05-c36be60d3d46'', ''Rojava'', ''ROJ'', NULL, NULL, NULL, NULL, 0, 0, 0]
    - [''f2c7a61a-1b63-11f0-9899-2b70d1861dd4'', ''Kobani'', ''KOB'', NULL, NULL, NULL, NULL, 0, 0, 0]
    - [''f334763c-1b63-11f0-aab4-4f7e5f7e30cb'', ''Jineologi'', ''JIN'', NULL, NULL, NULL, ''cae7ba7c-1b63-11f0-8a05-c36be60d3d46'', 0, 0, 1]
    - [''505282d6-2cf9-11f0-8450-87f83af99ff9'', ''Til Maroof school'', ''MAR'', NULL, NULL, NULL, NULL, 0, 0, 0]
    # Bakeloria
    - [''a7237520-2d8f-11f0-a834-2b294fbfca54'', ''Science'', ''SCI'', NULL, NULL, NULL, NULL, 0, 0, 0]
    - [''a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b'', ''Literature'', ''LIT'', NULL, NULL, NULL, NULL, 0, 0, 0]
seeding:
  - [''5a722502-2cfc-11f0-8fc6-4f662cb2699a'', ''2c4251c8-2cf9-11f0-bbd1-3370778ee65e'']
  - [''e985ddc6-1b5c-11f0-9787-2b6b92ddc057'', ''cae7ba7c-1b63-11f0-8a05-c36be60d3d46'']
  - [''f4c3a7cc-1b5c-11f0-8158-d7027851c1cd'', ''f2c7a61a-1b63-11f0-9899-2b70d1861dd4'']
  - [''204c8a80-1b5d-11f0-9a78-07337e2f1cca'', ''f334763c-1b63-11f0-aab4-4f7e5f7e30cb'']
  - [''4b38af66-2cfc-11f0-b608-2b766ae5cd8d'', ''505282d6-2cf9-11f0-8450-87f83af99ff9'']
    # Bakeloria
  - [''c555e604-2d8f-11f0-b535-bb3e95f882b4'', ''a7237520-2d8f-11f0-a834-2b294fbfca54'']
  - [''c5b7ccb6-2d8f-11f0-9338-4fa17b2a6436'', ''a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b'']
attribute-functions:
  name: "return $this->user_group->name;"
';


--
-- Name: acorn_university_material_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_material_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) DEFAULT 'test'::character varying NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    calculation_id uuid
);


ALTER TABLE public.acorn_university_material_types OWNER TO university;

--
-- Name: TABLE acorn_university_material_types; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_material_types IS 'order: 25
seeding:
  - [''6b4bae9a-149f-11f0-a4e5-779d31ace22e'', ''Material'']';


--
-- Name: acorn_university_materials; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_materials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    material_type_id uuid,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_materials OWNER TO university;

--
-- Name: TABLE acorn_university_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_materials IS 'order: 30
seeding:
  - [''cdc800ae-28be-11f0-a8a6-334555029afd'', ''Math'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''d675a530-28be-11f0-a2c9-9bb10fa15bd3'', ''Biology'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''dd494c0e-28be-11f0-94e1-a7b2083dd749'', ''Physics'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''e427a282-28be-11f0-8856-a7abd8a449c5'', ''Geography'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''ecf3dae8-28be-11f0-91f7-f31527b6ca23'', ''Chemistry'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''f3c853a8-28be-11f0-8938-73b157eb85a1'', ''Kurdish'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''fa61ead0-28be-11f0-9fb3-2bbf7e1c7c7c'', ''English'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''005bba60-28bf-11f0-bf7f-cff663f8102b'', ''Arabic'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''d43af2a2-2bd9-11f0-b08b-5fd59b502470'', ''History'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''d8168f4e-2bd9-11f0-97a5-1b42cf640b5b'', ''Philosophy'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''d84f8434-2bd9-11f0-bfa1-7b92380571bd'', ''Sociology'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']
  - [''d88f0f6e-2bd9-11f0-8846-8bc9dcb96017'', ''Jineologi'', NULL, ''6b4bae9a-149f-11f0-a4e5-779d31ace22e'']';


--
-- Name: acorn_university_project_students; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_project_students (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    owner_student_id uuid,
    user_group_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    score double precision,
    course_material_id uuid,
    project_id uuid NOT NULL,
    description text
);


ALTER TABLE public.acorn_university_project_students OWNER TO university;

--
-- Name: TABLE acorn_university_project_students; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_project_students IS 'labels:
  en: Student Project
labels-plural:
  en: Student Projects';


--
-- Name: COLUMN acorn_university_project_students.score; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_university_project_students.score IS 'list-editable: true';


--
-- Name: acorn_university_students; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_students (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    code character varying(1024) NOT NULL
);


ALTER TABLE public.acorn_university_students OWNER TO university;

--
-- Name: TABLE acorn_university_students; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_students IS 'order: 500
menu-splitter: true';


--
-- Name: acorn_user_user_group; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_group (
    user_id uuid NOT NULL,
    user_group_id uuid NOT NULL
);


ALTER TABLE public.acorn_user_user_group OWNER TO university;

--
-- Name: acorn_user_user_groups; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255),
    description text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    parent_user_group_id uuid,
    nest_left integer DEFAULT 0 NOT NULL,
    nest_right integer DEFAULT 0 NOT NULL,
    nest_depth integer DEFAULT 0 NOT NULL,
    image character varying(1024),
    colour character varying(1024),
    type_id uuid,
    location_id uuid
);


ALTER TABLE public.acorn_user_user_groups OWNER TO university;

--
-- Name: acorn_user_users; Type: TABLE; Schema: public; Owner: university
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
    is_system_user boolean DEFAULT false NOT NULL,
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
    birth_date timestamp without time zone
);


ALTER TABLE public.acorn_user_users OWNER TO university;

--
-- Name: acorn_exam_tokens; Type: VIEW; Schema: public; Owner: university
--

CREATE VIEW public.acorn_exam_tokens AS
 SELECT (concat(sc.student_id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['score'::character varying, ug.name, m.name, mt.name, e.name, et.name, s.code, (
        CASE
            WHEN em.required THEN 'required'::text
            ELSE NULL::text
        END)::character varying])))::character varying AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['score'::character varying, ug.name, m.name, mt.name, e.name, et.name, s.code, (
        CASE
            WHEN em.required THEN 'required'::text
            ELSE NULL::text
        END)::character varying]) AS name,
    sc.student_id,
    em.exam_id,
    em.course_material_id,
    cm.course_id,
    NULL::uuid AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    (sc.score)::character varying AS expression,
    'data'::text AS expression_type,
    false AS needs_evaluate
   FROM ((((((((((public.acorn_exam_scores sc
     JOIN public.acorn_university_students s ON ((sc.student_id = s.id)))
     JOIN public.acorn_exam_exam_materials em ON ((sc.exam_material_id = em.id)))
     JOIN public.acorn_exam_exams e ON ((em.exam_id = e.id)))
     JOIN public.acorn_exam_types et ON ((e.type_id = et.id)))
     JOIN public.acorn_university_course_materials cm ON ((em.course_material_id = cm.id)))
     JOIN public.acorn_university_courses c ON ((cm.course_id = c.id)))
     JOIN public.acorn_university_entities en ON ((c.entity_id = en.id)))
     JOIN public.acorn_user_user_groups ug ON ((en.user_group_id = ug.id)))
     JOIN public.acorn_university_materials m ON ((cm.material_id = m.id)))
     JOIN public.acorn_university_material_types mt ON ((m.material_type_id = mt.id)))
UNION ALL
 SELECT concat(s.id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['material'::character varying, ugs.name, m.name, mt.name, s.code, 'result'::character varying])) AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['material'::character varying, ugs.name, m.name, mt.name, s.code, 'result'::character varying]) AS name,
    s.id AS student_id,
    NULL::uuid AS exam_id,
    cm.id AS course_material_id,
    cm.course_id,
        CASE
            WHEN (NOT (cacm.expression IS NULL)) THEN cacm.id
            WHEN (NOT (camt.expression IS NULL)) THEN camt.id
            WHEN (NOT (cac.expression IS NULL)) THEN cac.id
            ELSE NULL::uuid
        END AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    replace(replace(replace((
        CASE
            WHEN (NOT (cacm.expression IS NULL)) THEN cacm.expression
            WHEN (NOT (camt.expression IS NULL)) THEN camt.expression
            WHEN (NOT (cac.expression IS NULL)) THEN cac.expression
            ELSE NULL::character varying
        END)::text, ('<course>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[ugs.name]))::text), ('<material>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[m.name]))::text), ('<student>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[s.code]))::text) AS expression,
    'expression'::text AS expression_type,
    true AS needs_evaluate
   FROM ((((((((((public.acorn_university_course_materials cm
     JOIN public.acorn_university_courses c ON ((cm.course_id = c.id)))
     JOIN public.acorn_university_entities en ON ((c.entity_id = en.id)))
     JOIN public.acorn_user_user_groups ugs ON ((en.user_group_id = ugs.id)))
     JOIN public.acorn_user_user_group ug ON ((en.user_group_id = ug.user_group_id)))
     JOIN public.acorn_university_students s ON ((ug.user_id = s.user_id)))
     JOIN public.acorn_university_materials m ON ((cm.material_id = m.id)))
     JOIN public.acorn_university_material_types mt ON ((m.material_type_id = mt.id)))
     LEFT JOIN public.acorn_exam_calculations cacm ON ((cm.calculation_id = cacm.id)))
     LEFT JOIN public.acorn_exam_calculations camt ON ((mt.calculation_id = camt.id)))
     LEFT JOIN public.acorn_exam_calculations cac ON ((c.calculation_id = cac.id)))
UNION ALL
 SELECT (concat(s.id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['student'::character varying, s.code, 'age'::character varying])))::character varying AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['student'::character varying, s.code, 'age'::character varying]) AS name,
    s.id AS student_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    NULL::uuid AS course_id,
    NULL::uuid AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    (EXTRACT(year FROM age(u.birth_date)))::character varying AS expression,
    'formulae'::text AS expression_type,
    false AS needs_evaluate
   FROM (public.acorn_university_students s
     JOIN public.acorn_user_users u ON ((s.user_id = u.id)))
UNION ALL
 SELECT (concat('::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['course'::character varying, ug.name, 'count'::character varying])))::character varying AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['course'::character varying, ug.name, 'count'::character varying]) AS name,
    NULL::uuid AS student_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    c.id AS course_id,
    NULL::uuid AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    (count(uug.user_id))::character varying AS expression,
    'formulae'::text AS expression_type,
    false AS needs_evaluate
   FROM (((public.acorn_university_courses c
     JOIN public.acorn_university_entities en ON ((c.entity_id = en.id)))
     JOIN public.acorn_user_user_groups ug ON ((en.user_group_id = ug.id)))
     LEFT JOIN public.acorn_user_user_group uug ON ((ug.id = uug.user_group_id)))
  GROUP BY c.id, en.id, ug.name
UNION ALL
 SELECT concat(s.id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['calculation'::character varying, s.code, c.name])) AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['calculation'::character varying, s.code, c.name]) AS name,
    s.id AS student_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    NULL::uuid AS course_id,
    c.id AS calculation_id,
    NULL::uuid AS project_id,
    NULL::uuid AS interview_id,
    replace((c.expression)::text, ('<student>'::character varying)::text, (public.fn_acorn_exam_token_name(VARIADIC ARRAY[s.code]))::text) AS expression,
    'expression'::text AS expression_type,
    true AS needs_evaluate
   FROM public.acorn_exam_calculations c,
    public.acorn_university_students s
UNION ALL
 SELECT concat(s.id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['project'::character varying, s.code, p.name])) AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['project'::character varying, s.code, p.name]) AS name,
    s.id AS student_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    NULL::uuid AS course_id,
    NULL::uuid AS calculation_id,
    p.id AS project_id,
    NULL::uuid AS interview_id,
    (p.score)::character varying AS expression,
    'data'::text AS expression_type,
    false AS needs_evaluate
   FROM (public.acorn_university_project_students p
     JOIN public.acorn_university_students s ON ((p.owner_student_id = s.id)))
UNION ALL
 SELECT concat(s.id, '::', public.fn_acorn_exam_token_name(VARIADIC ARRAY['interview'::character varying, s.code, i.name])) AS id,
    public.fn_acorn_exam_token_name(VARIADIC ARRAY['interview'::character varying, s.code, i.name]) AS name,
    s.id AS student_id,
    NULL::uuid AS exam_id,
    NULL::uuid AS course_material_id,
    NULL::uuid AS course_id,
    NULL::uuid AS calculation_id,
    NULL::uuid AS project_id,
    i.id AS interview_id,
    (iss.score)::character varying AS expression,
    'data'::text AS expression_type,
    false AS needs_evaluate
   FROM ((public.acorn_exam_interview_students iss
     JOIN public.acorn_university_students s ON ((iss.student_id = s.id)))
     JOIN public.acorn_exam_interviews i ON ((iss.interview_id = i.id)));


ALTER VIEW public.acorn_exam_tokens OWNER TO university;

--
-- Name: VIEW acorn_exam_tokens; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON VIEW public.acorn_exam_tokens IS 'menu: false';


--
-- Name: COLUMN acorn_exam_tokens.student_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.student_id IS 'extra-foreign-key: 
  table: acorn_university_students
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.exam_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.exam_id IS 'extra-foreign-key: 
  table: acorn_exam_exams
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.course_material_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.course_material_id IS 'extra-foreign-key: 
  table: acorn_university_course_materials
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.course_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.course_id IS 'extra-foreign-key: 
  table: acorn_university_courses
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.calculation_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.calculation_id IS 'extra-foreign-key: 
  table: acorn_exam_calculations
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.project_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.project_id IS 'extra-foreign-key: 
  table: acorn_university_projects
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: COLUMN acorn_exam_tokens.interview_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_exam_tokens.interview_id IS 'extra-foreign-key: 
  table: acorn_exam_interviews
  comment:
    tab-location: 2
    field-exclude: true
    invisible: true';


--
-- Name: acorn_exam_results; Type: VIEW; Schema: public; Owner: sz
--

CREATE VIEW public.acorn_exam_results AS
 SELECT id,
    name,
    student_id,
    exam_id,
    course_material_id,
    course_id,
    calculation_id,
    project_id,
    interview_id,
    expression,
    expression_type,
    needs_evaluate,
    public.fn_acorn_exam_tokenize(expression) AS result
   FROM public.acorn_exam_tokens;


ALTER VIEW public.acorn_exam_results OWNER TO sz;

--
-- Name: COLUMN acorn_exam_results.student_id; Type: COMMENT; Schema: public; Owner: sz
--

COMMENT ON COLUMN public.acorn_exam_results.student_id IS 'extra-foreign-key: 
  table: acorn_university_students
  comment:
    tab-location: 2
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.exam_id; Type: COMMENT; Schema: public; Owner: sz
--

COMMENT ON COLUMN public.acorn_exam_results.exam_id IS 'extra-foreign-key: 
  table: acorn_exam_exams
  comment:
    tab-location: 2
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.course_material_id; Type: COMMENT; Schema: public; Owner: sz
--

COMMENT ON COLUMN public.acorn_exam_results.course_material_id IS 'extra-foreign-key: 
  table: acorn_university_course_materials
  comment:
    tab-location: 2
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.course_id; Type: COMMENT; Schema: public; Owner: sz
--

COMMENT ON COLUMN public.acorn_exam_results.course_id IS 'extra-foreign-key: 
  table: acorn_university_courses
  comment:
    tab-location: 2
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.calculation_id; Type: COMMENT; Schema: public; Owner: sz
--

COMMENT ON COLUMN public.acorn_exam_results.calculation_id IS 'extra-foreign-key: 
  table: acorn_exam_calculations
  comment:
    tab-location: 2';


--
-- Name: COLUMN acorn_exam_results.project_id; Type: COMMENT; Schema: public; Owner: sz
--

COMMENT ON COLUMN public.acorn_exam_results.project_id IS 'extra-foreign-key: 
  table: acorn_university_projects
  comment:
    tab-location: 2
    invisible: true';


--
-- Name: COLUMN acorn_exam_results.interview_id; Type: COMMENT; Schema: public; Owner: sz
--

COMMENT ON COLUMN public.acorn_exam_results.interview_id IS 'extra-foreign-key: 
  table: acorn_exam_interviews
  comment:
    tab-location: 2
    invisible: true';


--
-- Name: acorn_location_addresses; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_addresses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    number character varying(1024),
    image character varying(2048),
    description text,
    area_id uuid NOT NULL,
    gps_id uuid,
    server_id uuid NOT NULL,
    created_by_user_id uuid,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    response text,
    lookup_id uuid
);


ALTER TABLE public.acorn_location_addresses OWNER TO university;

--
-- Name: acorn_location_area_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_area_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    server_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acorn_location_area_types OWNER TO university;

--
-- Name: acorn_location_areas; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_areas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    area_type_id uuid NOT NULL,
    parent_area_id uuid,
    gps_id uuid,
    server_id uuid NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    is_current_version boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acorn_location_areas OWNER TO university;

--
-- Name: acorn_location_gps; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_gps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    longitude double precision,
    latitude double precision,
    server_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acorn_location_gps OWNER TO university;

--
-- Name: acorn_location_locations; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    address_id uuid NOT NULL,
    name character varying(2048) NOT NULL,
    description text,
    image character varying(2048),
    server_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    type_id uuid
);


ALTER TABLE public.acorn_location_locations OWNER TO university;

--
-- Name: acorn_location_lookup; Type: TABLE; Schema: public; Owner: university
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
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.acorn_location_lookup OWNER TO university;

--
-- Name: acorn_location_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    parent_type_id uuid,
    server_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    colour character varying(1024),
    image character varying(1024)
);


ALTER TABLE public.acorn_location_types OWNER TO university;

--
-- Name: acorn_messaging_action; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_action (
    message_id uuid NOT NULL,
    action character varying(1024) NOT NULL,
    settings text NOT NULL,
    status uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_action OWNER TO university;

--
-- Name: acorn_messaging_label; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_label (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_label OWNER TO university;

--
-- Name: acorn_messaging_message; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.acorn_messaging_message OWNER TO university;

--
-- Name: TABLE acorn_messaging_message; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_messaging_message IS 'table-type: content';


--
-- Name: acorn_messaging_message_instance; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_message_instance (
    message_id uuid NOT NULL,
    instance_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:43:15.373287'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_instance OWNER TO university;

--
-- Name: acorn_messaging_message_message; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_message_message (
    message1_id uuid NOT NULL,
    message2_id uuid NOT NULL,
    relationship integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_message OWNER TO university;

--
-- Name: acorn_messaging_message_user; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_message_user (
    message_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_user OWNER TO university;

--
-- Name: acorn_messaging_message_user_group; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_message_user_group (
    message_id uuid NOT NULL,
    user_group_id uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_message_user_group OWNER TO university;

--
-- Name: acorn_messaging_status; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_status (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_status OWNER TO university;

--
-- Name: TABLE acorn_messaging_status; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_messaging_status IS 'table-type: content';


--
-- Name: acorn_messaging_user_message_status; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_messaging_user_message_status (
    user_id uuid NOT NULL,
    message_id uuid NOT NULL,
    status_id uuid NOT NULL,
    value character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_messaging_user_message_status OWNER TO university;

--
-- Name: TABLE acorn_messaging_user_message_status; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_messaging_user_message_status IS 'table-type: content';


--
-- Name: acorn_reporting_reports; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_reporting_reports (
    id integer NOT NULL,
    settings text NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_reporting_reports OWNER TO university;

--
-- Name: acorn_reporting_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.acorn_reporting_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.acorn_reporting_reports_id_seq OWNER TO university;

--
-- Name: acorn_reporting_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.acorn_reporting_reports_id_seq OWNED BY public.acorn_reporting_reports.id;


--
-- Name: acorn_servers; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_servers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    hostname character varying(1024) DEFAULT 'hostname()'::character varying NOT NULL,
    domain character varying(1024),
    response text,
    created_at timestamp(0) without time zone DEFAULT '2025-04-03 08:42:56.917994'::timestamp without time zone NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS (hostname) STORED,
    location_id uuid
);


ALTER TABLE public.acorn_servers OWNER TO university;

--
-- Name: acorn_university_academic_years; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_academic_years (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_academic_years OWNER TO university;

--
-- Name: TABLE acorn_university_academic_years; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_academic_years IS 'seeding:
  - [''5afc781c-2b47-11f0-bc2a-0bdc97d6ed09'', ''1'']
  - [''607dd68c-2b47-11f0-a57e-5f9aa740c8dc'', ''2'']
  - [''60dc4aaa-2b47-11f0-83f4-7f2b70ba9b18'', ''3'']
  - [''6118ff22-2b47-11f0-80a4-a7c3a85423e6'', ''4'']
  - [''61495bc2-2b47-11f0-b804-6317f8482a6b'', ''10'']
  - [''61733dca-2b47-11f0-b084-23828f21ea2c'', ''11'']
  - [''619bd3d4-2b47-11f0-9c1e-8b0e1b85bf28'', ''12'']';


--
-- Name: acorn_university_course_language; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_course_language (
    course_id uuid NOT NULL,
    language_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_course_language OWNER TO university;

--
-- Name: acorn_university_departments; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_departments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_departments OWNER TO university;

--
-- Name: TABLE acorn_university_departments; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_departments IS 'order: 50';


--
-- Name: acorn_university_education_authorities; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_education_authorities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_education_authorities OWNER TO university;

--
-- Name: TABLE acorn_university_education_authorities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_education_authorities IS 'order: 10
seeding:
  - [''783f2678-2cf9-11f0-a5b2-bbfb9ff0186a'', ''5a722502-2cfc-11f0-8fc6-4f662cb2699a'']';


--
-- Name: acorn_university_faculties; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_faculties (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_faculties OWNER TO university;

--
-- Name: TABLE acorn_university_faculties; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_faculties IS 'order: 40';


--
-- Name: acorn_university_hierarchies; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_hierarchies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    year_id uuid NOT NULL,
    parent_id uuid,
    server_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    nest_left integer DEFAULT 0 NOT NULL,
    nest_right integer DEFAULT 0 NOT NULL,
    nest_depth integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.acorn_university_hierarchies OWNER TO university;

--
-- Name: TABLE acorn_university_hierarchies; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_hierarchies IS 'order: 1000
menu-splitter: true
attribute-functions:
  name: 
    - $name   = '''';
    - if ($entity = Entity::find($this->entity_id)) $name .= $entity->name;
    - if ($year   = Year::find($this->year_id))     $name .= " ($year->name)";
    - return $name;
seeding:
  # 2024
  - [''0ceec500-2be0-11f0-a1ba-abdbde63a860'', ''e985ddc6-1b5c-11f0-9787-2b6b92ddc057'', ''529bd45a-1b6c-11f0-99b6-b7f647885dbc'']
  - [''0d616290-2be0-11f0-8dc5-ab7f8b80419b'', ''f4c3a7cc-1b5c-11f0-8158-d7027851c1cd'', ''529bd45a-1b6c-11f0-99b6-b7f647885dbc'']
  # 2025
  - [''0da577c8-2be0-11f0-848f-577d1a1a8da3'', ''e985ddc6-1b5c-11f0-9787-2b6b92ddc057'', ''543d0928-1b6c-11f0-abc1-8bd8fff1240d'']
  - [''0ded31f8-2be0-11f0-b58f-63d2d9622b6b'', ''f4c3a7cc-1b5c-11f0-8158-d7027851c1cd'', ''543d0928-1b6c-11f0-abc1-8bd8fff1240d'']';


--
-- Name: acorn_university_projects; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_projects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_projects OWNER TO university;

--
-- Name: TABLE acorn_university_projects; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_projects IS 'seeding:
  - [''5fcc2166-2bed-11f0-ae13-87be01ade284'', ''Example Project'']';


--
-- Name: acorn_university_schools; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_schools (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_schools OWNER TO university;

--
-- Name: TABLE acorn_university_schools; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_schools IS 'order: 30
seeding:
  - [''98870568-2cf9-11f0-8594-6b81dcd42328'', ''4b38af66-2cfc-11f0-b608-2b766ae5cd8d'']';


--
-- Name: acorn_university_semester_years; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_semester_years (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    year_id uuid NOT NULL,
    semester_id uuid NOT NULL,
    event_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_semester_years OWNER TO university;

--
-- Name: TABLE acorn_university_semester_years; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_semester_years IS 'attribute-functions:
  name: return $this->year?->name . '' ::'' . $this->semester?->name;
seeding:
  # Year 2024
  - [''9c6e1d20-2bd1-11f0-8119-93a057070d34'', ''529bd45a-1b6c-11f0-99b6-b7f647885dbc'', ''61c051fa-2b47-11f0-bc0f-ab4c8b696730'', EVENT(Default;Year 2024 Semester 1)]
  - [''9dd3c21e-2bd1-11f0-8ec0-530fd1227857'', ''529bd45a-1b6c-11f0-99b6-b7f647885dbc'', ''61eb583c-2b47-11f0-adc3-ef976031065b'', EVENT(Default;Year 2024 Semester 2)]
  - [''9e5bbd72-2bd1-11f0-9dcc-83b88755cb62'', ''529bd45a-1b6c-11f0-99b6-b7f647885dbc'', ''6212587e-2b47-11f0-b854-631a30042bb5'', EVENT(Default;Year 2024 Semester 3)]
  # Year 2025
  - [''9ea2909e-2bd1-11f0-9b80-f797a81e82a4'', ''543d0928-1b6c-11f0-abc1-8bd8fff1240d'', ''61c051fa-2b47-11f0-bc0f-ab4c8b696730'', EVENT(Default;Year 2025 Semester 1)]
  - [''9ee7d67c-2bd1-11f0-aba9-97727bc0b413'', ''543d0928-1b6c-11f0-abc1-8bd8fff1240d'', ''61eb583c-2b47-11f0-adc3-ef976031065b'', EVENT(Default;Year 2025 Semester 2)]
  - [''9f227dea-2bd1-11f0-bd27-c7d903e9ad4d'', ''543d0928-1b6c-11f0-abc1-8bd8fff1240d'', ''6212587e-2b47-11f0-b854-631a30042bb5'', EVENT(Default;Year 2025 Semester 3)]
';


--
-- Name: acorn_university_semesters; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_semesters (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_semesters OWNER TO university;

--
-- Name: TABLE acorn_university_semesters; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_semesters IS 'seeding:
  - [''61c051fa-2b47-11f0-bc0f-ab4c8b696730'', ''Semester 1'']
  - [''61eb583c-2b47-11f0-adc3-ef976031065b'', ''Semester 2'']
  - [''6212587e-2b47-11f0-b854-631a30042bb5'', ''Semester 3'']
';


--
-- Name: acorn_university_teachers; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_teachers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_teachers OWNER TO university;

--
-- Name: TABLE acorn_university_teachers; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_teachers IS 'order: 510';


--
-- Name: acorn_university_universities; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_universities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_universities OWNER TO university;

--
-- Name: TABLE acorn_university_universities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_universities IS 'plugin-icon: book
order: 20
seeding:
  - [''204c8a80-1b5d-11f0-9a78-07337e2f1cca'', ''e985ddc6-1b5c-11f0-9787-2b6b92ddc057'']
  - [''11ad9e2e-1b6c-11f0-9008-4f702d5c7ef2'', ''f4c3a7cc-1b5c-11f0-8158-d7027851c1cd'']';


--
-- Name: acorn_university_years; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_university_years (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name integer NOT NULL,
    start timestamp without time zone NOT NULL,
    "end" timestamp without time zone NOT NULL,
    current boolean DEFAULT true NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_university_years OWNER TO university;

--
-- Name: TABLE acorn_university_years; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_university_years IS 'global-scope: true
order: 1010
seeding:
  - [''529bd45a-1b6c-11f0-99b6-b7f647885dbc'', 2024, 01/01/2024, 30/12/2024, false]
  - [''543d0928-1b6c-11f0-abc1-8bd8fff1240d'', 2025, 01/01/2025, 30/12/2025, true]';


--
-- Name: acorn_user_language_user; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_language_user (
    user_id uuid NOT NULL,
    language_id uuid NOT NULL
);


ALTER TABLE public.acorn_user_language_user OWNER TO university;

--
-- Name: acorn_user_languages; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_languages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL
);


ALTER TABLE public.acorn_user_languages OWNER TO university;

--
-- Name: acorn_user_mail_blockers; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_mail_blockers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255),
    template character varying(255),
    user_id uuid,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_user_mail_blockers OWNER TO university;

--
-- Name: acorn_user_role_user; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_role_user (
    user_id uuid NOT NULL,
    role_id uuid NOT NULL
);


ALTER TABLE public.acorn_user_role_user OWNER TO university;

--
-- Name: acorn_user_roles; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255),
    permissions text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_user_roles OWNER TO university;

--
-- Name: acorn_user_throttle; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.acorn_user_throttle OWNER TO university;

--
-- Name: acorn_user_user_group_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_group_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255),
    description character varying(255),
    colour character varying(1024),
    image character varying(1024),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_user_user_group_types OWNER TO university;

--
-- Name: acorn_user_user_group_version_usages; Type: VIEW; Schema: public; Owner: university
--

CREATE VIEW public.acorn_user_user_group_version_usages AS
 SELECT NULL::uuid AS user_group_version_id,
    NULL::character varying(1024) AS "table",
    NULL::uuid AS id;


ALTER VIEW public.acorn_user_user_group_version_usages OWNER TO university;

--
-- Name: backend_access_log; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.backend_access_log (
    id integer NOT NULL,
    user_id integer NOT NULL,
    ip_address character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.backend_access_log OWNER TO university;

--
-- Name: backend_access_log_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_access_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_access_log_id_seq OWNER TO university;

--
-- Name: backend_access_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_access_log_id_seq OWNED BY public.backend_access_log.id;


--
-- Name: backend_user_groups; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.backend_user_groups OWNER TO university;

--
-- Name: backend_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_user_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_groups_id_seq OWNER TO university;

--
-- Name: backend_user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_user_groups_id_seq OWNED BY public.backend_user_groups.id;


--
-- Name: backend_user_preferences; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.backend_user_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    namespace character varying(100) NOT NULL,
    "group" character varying(50) NOT NULL,
    item character varying(150) NOT NULL,
    value text
);


ALTER TABLE public.backend_user_preferences OWNER TO university;

--
-- Name: backend_user_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_user_preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_preferences_id_seq OWNER TO university;

--
-- Name: backend_user_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_user_preferences_id_seq OWNED BY public.backend_user_preferences.id;


--
-- Name: backend_user_roles; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.backend_user_roles OWNER TO university;

--
-- Name: backend_user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_roles_id_seq OWNER TO university;

--
-- Name: backend_user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_user_roles_id_seq OWNED BY public.backend_user_roles.id;


--
-- Name: backend_user_throttle; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.backend_user_throttle OWNER TO university;

--
-- Name: backend_user_throttle_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_user_throttle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_user_throttle_id_seq OWNER TO university;

--
-- Name: backend_user_throttle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_user_throttle_id_seq OWNED BY public.backend_user_throttle.id;


--
-- Name: backend_users; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.backend_users OWNER TO university;

--
-- Name: backend_users_groups; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.backend_users_groups (
    user_id integer NOT NULL,
    user_group_id integer NOT NULL,
    deleted_at timestamp(0) without time zone
);


ALTER TABLE public.backend_users_groups OWNER TO university;

--
-- Name: backend_users_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.backend_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backend_users_id_seq OWNER TO university;

--
-- Name: backend_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.backend_users_id_seq OWNED BY public.backend_users.id;


--
-- Name: cache; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache OWNER TO university;

--
-- Name: cms_theme_data; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.cms_theme_data (
    id integer NOT NULL,
    theme character varying(255),
    data text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.cms_theme_data OWNER TO university;

--
-- Name: cms_theme_data_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.cms_theme_data_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_data_id_seq OWNER TO university;

--
-- Name: cms_theme_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.cms_theme_data_id_seq OWNED BY public.cms_theme_data.id;


--
-- Name: cms_theme_logs; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.cms_theme_logs OWNER TO university;

--
-- Name: cms_theme_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.cms_theme_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_logs_id_seq OWNER TO university;

--
-- Name: cms_theme_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.cms_theme_logs_id_seq OWNED BY public.cms_theme_logs.id;


--
-- Name: cms_theme_templates; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.cms_theme_templates OWNER TO university;

--
-- Name: cms_theme_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.cms_theme_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cms_theme_templates_id_seq OWNER TO university;

--
-- Name: cms_theme_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.cms_theme_templates_id_seq OWNED BY public.cms_theme_templates.id;


--
-- Name: deferred_bindings; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.deferred_bindings OWNER TO university;

--
-- Name: deferred_bindings_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.deferred_bindings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.deferred_bindings_id_seq OWNER TO university;

--
-- Name: deferred_bindings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.deferred_bindings_id_seq OWNED BY public.deferred_bindings.id;


--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.failed_jobs OWNER TO university;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.failed_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.failed_jobs_id_seq OWNER TO university;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: job_batches; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.job_batches OWNER TO university;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.jobs OWNER TO university;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_id_seq OWNER TO university;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO university;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO university;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: winter_location_countries; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_location_countries (
    id integer NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    is_pinned boolean DEFAULT false NOT NULL
);


ALTER TABLE public.winter_location_countries OWNER TO university;

--
-- Name: rainlab_location_countries_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_location_countries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_location_countries_id_seq OWNER TO university;

--
-- Name: rainlab_location_countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_location_countries_id_seq OWNED BY public.winter_location_countries.id;


--
-- Name: winter_location_states; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_location_states (
    id integer NOT NULL,
    country_id integer NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL
);


ALTER TABLE public.winter_location_states OWNER TO university;

--
-- Name: rainlab_location_states_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_location_states_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_location_states_id_seq OWNER TO university;

--
-- Name: rainlab_location_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_location_states_id_seq OWNED BY public.winter_location_states.id;


--
-- Name: winter_translate_attributes; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_translate_attributes (
    id integer NOT NULL,
    locale character varying(255) NOT NULL,
    model_id character varying(255),
    model_type character varying(255),
    attribute_data text
);


ALTER TABLE public.winter_translate_attributes OWNER TO university;

--
-- Name: rainlab_translate_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_translate_attributes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_attributes_id_seq OWNER TO university;

--
-- Name: rainlab_translate_attributes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_translate_attributes_id_seq OWNED BY public.winter_translate_attributes.id;


--
-- Name: winter_translate_indexes; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_translate_indexes (
    id integer NOT NULL,
    locale character varying(255) NOT NULL,
    model_id character varying(255),
    model_type character varying(255),
    item character varying(255),
    value text
);


ALTER TABLE public.winter_translate_indexes OWNER TO university;

--
-- Name: rainlab_translate_indexes_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_translate_indexes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_indexes_id_seq OWNER TO university;

--
-- Name: rainlab_translate_indexes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_translate_indexes_id_seq OWNED BY public.winter_translate_indexes.id;


--
-- Name: winter_translate_locales; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_translate_locales (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255),
    is_default boolean DEFAULT false NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.winter_translate_locales OWNER TO university;

--
-- Name: rainlab_translate_locales_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_translate_locales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_locales_id_seq OWNER TO university;

--
-- Name: rainlab_translate_locales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_translate_locales_id_seq OWNED BY public.winter_translate_locales.id;


--
-- Name: winter_translate_messages; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.winter_translate_messages (
    id integer NOT NULL,
    code character varying(255),
    message_data text,
    found boolean DEFAULT true NOT NULL,
    code_pre_2_1_0 character varying(255)
);


ALTER TABLE public.winter_translate_messages OWNER TO university;

--
-- Name: rainlab_translate_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.rainlab_translate_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rainlab_translate_messages_id_seq OWNER TO university;

--
-- Name: rainlab_translate_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.rainlab_translate_messages_id_seq OWNED BY public.winter_translate_messages.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    payload text,
    last_activity integer,
    user_id integer,
    ip_address character varying(45),
    user_agent text
);


ALTER TABLE public.sessions OWNER TO university;

--
-- Name: system_event_logs; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.system_event_logs (
    id integer NOT NULL,
    level character varying(255),
    message text,
    details text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.system_event_logs OWNER TO university;

--
-- Name: system_event_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_event_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_event_logs_id_seq OWNER TO university;

--
-- Name: system_event_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_event_logs_id_seq OWNED BY public.system_event_logs.id;


--
-- Name: system_files; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_files OWNER TO university;

--
-- Name: system_files_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_files_id_seq OWNER TO university;

--
-- Name: system_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_files_id_seq OWNED BY public.system_files.id;


--
-- Name: system_mail_layouts; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_mail_layouts OWNER TO university;

--
-- Name: system_mail_layouts_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_mail_layouts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_layouts_id_seq OWNER TO university;

--
-- Name: system_mail_layouts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_mail_layouts_id_seq OWNED BY public.system_mail_layouts.id;


--
-- Name: system_mail_partials; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_mail_partials OWNER TO university;

--
-- Name: system_mail_partials_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_mail_partials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_partials_id_seq OWNER TO university;

--
-- Name: system_mail_partials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_mail_partials_id_seq OWNED BY public.system_mail_partials.id;


--
-- Name: system_mail_templates; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_mail_templates OWNER TO university;

--
-- Name: system_mail_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_mail_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_mail_templates_id_seq OWNER TO university;

--
-- Name: system_mail_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_mail_templates_id_seq OWNED BY public.system_mail_templates.id;


--
-- Name: system_parameters; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.system_parameters (
    id integer NOT NULL,
    namespace character varying(100) NOT NULL,
    "group" character varying(50) NOT NULL,
    item character varying(150) NOT NULL,
    value text
);


ALTER TABLE public.system_parameters OWNER TO university;

--
-- Name: system_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_parameters_id_seq OWNER TO university;

--
-- Name: system_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_parameters_id_seq OWNED BY public.system_parameters.id;


--
-- Name: system_plugin_history; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.system_plugin_history (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    type character varying(20) NOT NULL,
    version character varying(50) NOT NULL,
    detail text,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.system_plugin_history OWNER TO university;

--
-- Name: system_plugin_history_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_plugin_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_plugin_history_id_seq OWNER TO university;

--
-- Name: system_plugin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_plugin_history_id_seq OWNED BY public.system_plugin_history.id;


--
-- Name: system_plugin_versions; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_plugin_versions OWNER TO university;

--
-- Name: system_plugin_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_plugin_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_plugin_versions_id_seq OWNER TO university;

--
-- Name: system_plugin_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_plugin_versions_id_seq OWNED BY public.system_plugin_versions.id;


--
-- Name: system_request_logs; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_request_logs OWNER TO university;

--
-- Name: system_request_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_request_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_request_logs_id_seq OWNER TO university;

--
-- Name: system_request_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_request_logs_id_seq OWNED BY public.system_request_logs.id;


--
-- Name: system_revisions; Type: TABLE; Schema: public; Owner: university
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


ALTER TABLE public.system_revisions OWNER TO university;

--
-- Name: system_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_revisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_revisions_id_seq OWNER TO university;

--
-- Name: system_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_revisions_id_seq OWNED BY public.system_revisions.id;


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.system_settings (
    id integer NOT NULL,
    item character varying(255),
    value text
);


ALTER TABLE public.system_settings OWNER TO university;

--
-- Name: system_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: university
--

CREATE SEQUENCE public.system_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_settings_id_seq OWNER TO university;

--
-- Name: system_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: university
--

ALTER SEQUENCE public.system_settings_id_seq OWNED BY public.system_settings.id;


--
-- Name: acorn_reporting_reports id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_reporting_reports ALTER COLUMN id SET DEFAULT nextval('public.acorn_reporting_reports_id_seq'::regclass);


--
-- Name: backend_access_log id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_access_log ALTER COLUMN id SET DEFAULT nextval('public.backend_access_log_id_seq'::regclass);


--
-- Name: backend_user_groups id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_groups ALTER COLUMN id SET DEFAULT nextval('public.backend_user_groups_id_seq'::regclass);


--
-- Name: backend_user_preferences id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_preferences ALTER COLUMN id SET DEFAULT nextval('public.backend_user_preferences_id_seq'::regclass);


--
-- Name: backend_user_roles id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_roles ALTER COLUMN id SET DEFAULT nextval('public.backend_user_roles_id_seq'::regclass);


--
-- Name: backend_user_throttle id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_throttle ALTER COLUMN id SET DEFAULT nextval('public.backend_user_throttle_id_seq'::regclass);


--
-- Name: backend_users id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users ALTER COLUMN id SET DEFAULT nextval('public.backend_users_id_seq'::regclass);


--
-- Name: cms_theme_data id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_data ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_data_id_seq'::regclass);


--
-- Name: cms_theme_logs id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_logs ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_logs_id_seq'::regclass);


--
-- Name: cms_theme_templates id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_templates ALTER COLUMN id SET DEFAULT nextval('public.cms_theme_templates_id_seq'::regclass);


--
-- Name: deferred_bindings id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.deferred_bindings ALTER COLUMN id SET DEFAULT nextval('public.deferred_bindings_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: system_event_logs id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_event_logs ALTER COLUMN id SET DEFAULT nextval('public.system_event_logs_id_seq'::regclass);


--
-- Name: system_files id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_files ALTER COLUMN id SET DEFAULT nextval('public.system_files_id_seq'::regclass);


--
-- Name: system_mail_layouts id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_layouts ALTER COLUMN id SET DEFAULT nextval('public.system_mail_layouts_id_seq'::regclass);


--
-- Name: system_mail_partials id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_partials ALTER COLUMN id SET DEFAULT nextval('public.system_mail_partials_id_seq'::regclass);


--
-- Name: system_mail_templates id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_templates ALTER COLUMN id SET DEFAULT nextval('public.system_mail_templates_id_seq'::regclass);


--
-- Name: system_parameters id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_parameters ALTER COLUMN id SET DEFAULT nextval('public.system_parameters_id_seq'::regclass);


--
-- Name: system_plugin_history id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_plugin_history ALTER COLUMN id SET DEFAULT nextval('public.system_plugin_history_id_seq'::regclass);


--
-- Name: system_plugin_versions id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_plugin_versions ALTER COLUMN id SET DEFAULT nextval('public.system_plugin_versions_id_seq'::regclass);


--
-- Name: system_request_logs id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_request_logs ALTER COLUMN id SET DEFAULT nextval('public.system_request_logs_id_seq'::regclass);


--
-- Name: system_revisions id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_revisions ALTER COLUMN id SET DEFAULT nextval('public.system_revisions_id_seq'::regclass);


--
-- Name: system_settings id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_settings ALTER COLUMN id SET DEFAULT nextval('public.system_settings_id_seq'::regclass);


--
-- Name: winter_location_countries id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_location_countries ALTER COLUMN id SET DEFAULT nextval('public.rainlab_location_countries_id_seq'::regclass);


--
-- Name: winter_location_states id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_location_states ALTER COLUMN id SET DEFAULT nextval('public.rainlab_location_states_id_seq'::regclass);


--
-- Name: winter_translate_attributes id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_attributes ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_attributes_id_seq'::regclass);


--
-- Name: winter_translate_indexes id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_indexes ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_indexes_id_seq'::regclass);


--
-- Name: winter_translate_locales id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_locales ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_locales_id_seq'::regclass);


--
-- Name: winter_translate_messages id; Type: DEFAULT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_messages ALTER COLUMN id SET DEFAULT nextval('public.rainlab_translate_messages_id_seq'::regclass);


--
-- Data for Name: acorn_calendar_calendars; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_calendars (id, name, description, system, sync_file, sync_format, created_at, updated_at, owner_user_id, owner_user_group_id, permissions) FROM stdin;
ceea8856-e4c8-11ef-8719-5f58c97885a2	Default	\N	t	\N	0	2025-04-03 08:43:15	\N	\N	\N	1
f3bc49bc-eac7-11ef-9e4a-1740a039dada	Activity Log	\N	t	\N	0	2025-04-03 08:43:15	\N	\N	\N	1
\.


--
-- Data for Name: acorn_calendar_event_part_user; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_event_part_user (event_part_id, user_id, role_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_event_part_user_group; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_event_part_user_group (event_part_id, user_group_id) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_event_parts; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_event_parts (id, event_id, name, description, start, "end", until, mask, mask_type, type_id, status_id, repeat_frequency, parent_event_part_id, location_id, locked_by_user_id, created_at, updated_at, repeat, alarm, instances_deleted) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_event_statuses; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_event_statuses (id, name, description, style, system, calendar_id, created_at, updated_at) FROM stdin;
27446472-e4c9-11ef-bde0-9b663c96a619	Normal	\N	\N	t	\N	\N	\N
fb2392de-e62e-11ef-b202-5fe79ff1071f	Cancelled	\N	text-decoration:line-through;border:1px dotted #fff;	t	\N	\N	\N
9c914367-bb6e-4b4c-b60d-d2de11ba0d67	Tentative	\N	opacity:0.7;	t	\N	\N	\N
0d846325-d836-4f5e-a723-5e4878e76fe9	Conflict	\N	border:1px solid red;background-color:#fff;color:#000;font-weight:bold;	t	\N	\N	\N
7b432540-eac8-11ef-a9bc-434841a9f67b	acorn.calendar::lang.models.general.insert	\N	color:#fff	t	\N	\N	\N
7c18bb7e-eac8-11ef-b4f2-ffae3296f461	acorn.calendar::lang.models.general.update	\N	color:#fff	t	\N	\N	\N
7ceca4c0-eac8-11ef-b685-f7f3f278f676	acorn.calendar::lang.models.general.soft_delete	\N	color:#fff	t	\N	\N	\N
f9690600-eac9-11ef-8002-5b2cbe0c12c0	acorn.calendar::lang.models.general.soft_undelete	\N	color:#fff	t	\N	\N	\N
\.


--
-- Data for Name: acorn_calendar_event_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_event_types (id, name, description, whole_day, colour, style, system, activity_log_related_oid, calendar_id, created_at, updated_at) FROM stdin;
2f766546-e4c9-11ef-be8c-1f2daa98a10f	Normal	\N	f	#091386	color:#fff	t	\N	\N	2025-04-03 08:43:15	\N
90675595-d8e9-45f0-b5b4-6e4dea848d50	Meeting	\N	f	#C0392B	color:#fff	t	\N	\N	2025-04-03 08:43:15	\N
6867d1bc-bcc0-40fa-a78f-e02762e33dd6	University Entities	\N	f	#333	\N	f	127565	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
f4511a42-177e-4b4f-815c-97bc62a7faec	University Years	\N	f	#333	\N	f	127498	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
736718a8-fd8e-4277-a7e5-d5f4c6d75f58	University Hierarchies	\N	f	#333	\N	f	127559	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
23b39dc4-c9ca-45a0-ac7d-5ceb9e5364e9	Exam Types	\N	f	#333	\N	f	130187	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
414d6fca-a3b9-4f16-81fb-16294ec0d8e0	Exam Material Types	\N	f	#333	\N	f	130231	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
dd927991-1b02-4659-96ec-00626e9afc5b	Exam Materials	\N	f	#333	\N	f	130202	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
e3d8874c-e1b5-4bea-a4eb-9c9f7bd378c1	Exam Exams	\N	f	#333	\N	f	130168	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
ae39a756-1988-4fc4-9f61-27c4e79f1c21	Exam Exam Materials	\N	f	#333	\N	f	130210	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
e90d2e25-a11e-46bc-8c0f-c2e441737d4b	Exam Results	\N	f	#333	\N	f	130360	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
c17e3dfd-f4b1-4e8e-a80b-5a499068e92e	University Years	\N	f	#333	\N	f	141180	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
7989413a-b4ca-4b11-9899-0366af60e6b6	Exam Material Types	\N	f	#333	\N	f	141034	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
9bb48e76-69fa-4108-808e-b281c24a37f0	Exam Materials	\N	f	#333	\N	f	141015	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
259112f5-5a87-45a8-9484-634fe93ba2fd	Exam Types	\N	f	#333	\N	f	141002	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
7f8556ac-88aa-44ab-a3d8-b92f826fd3a7	University Entities	\N	f	#333	\N	f	141157	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
e1cd4897-23bb-4492-b230-9d4e4820a8ea	Exam Exams	\N	f	#333	\N	f	140991	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
f3861664-97bb-469d-a47f-bd5082c8dcda	Exam Exam Materials	\N	f	#333	\N	f	140984	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
171d152d-cde2-4c11-92fe-9d371d1929ea	Exam Scores	\N	f	#333	\N	f	140998	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
9d9e45b6-2aed-4071-ba12-359359a36486	Exam Calculations	\N	f	#333	\N	f	140962	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
9f4415a1-7bf9-4af5-a154-1b999a029baf	Exam Scores	\N	f	#333	\N	f	143542	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
8c604e8e-b860-4bfd-898a-461703b57ff4	Exam Interviews	\N	f	#333	\N	f	148386	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
d4b30352-82e8-4c50-b0ef-dcb2dc2b9c9b	University Course Materials	\N	f	#333	\N	f	148335	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
f12691d2-5fbc-46ca-bb43-598a131893d1	University Hierarchies	\N	f	#333	\N	f	141168	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
0deccc54-7462-4f9e-801e-e00eda89cf56	University Semesters	\N	f	#333	\N	f	176467	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
6c8665e3-802f-4b18-9654-2da936d703b9	University Academic Years	\N	f	#333	\N	f	176460	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
4da3e8c4-5bd6-4219-a5c0-722c2e999a79	University Semester Years	\N	f	#333	\N	f	176482	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
b4f0f2a9-4858-49e8-99bf-9543e53cdee1	University Projects	\N	f	#333	\N	f	148424	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
1e34069e-7a17-40ef-9ae0-f983e7faf8db	Exam Interview Students	\N	f	#333	\N	f	148395	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
502ade43-df3d-4b31-9a29-43a92bc0f06c	University Projects	\N	f	#333	\N	f	177224	f3bc49bc-eac7-11ef-9e4a-1740a039dada	2025-04-03 08:43:15	\N
\.


--
-- Data for Name: acorn_calendar_events; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_events (id, calendar_id, external_url, created_at, updated_at, owner_user_id, owner_user_group_id, permissions) FROM stdin;
\.


--
-- Data for Name: acorn_calendar_instances; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_calendar_instances (id, date, event_part_id, instance_num, instance_start, instance_end) FROM stdin;
\.


--
-- Data for Name: acorn_exam_calculations; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_calculations (id, name, description, expression, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_exam_materials; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_exam_materials (id, exam_id, course_material_id, required, minimum, maximum, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, weight, interview_id, project_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_exams; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_exams (id, name, description, type_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_interview_students; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_interview_students (id, interview_id, student_id, teacher_id, event_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, score, course_material_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_interviews; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_interviews (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_scores; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_scores (id, exam_material_id, score, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, student_id) FROM stdin;
\.


--
-- Data for Name: acorn_exam_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_exam_types (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_location_addresses; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_addresses (id, name, number, image, description, area_id, gps_id, server_id, created_by_user_id, created_at, response, lookup_id) FROM stdin;
9e95fe34-42dd-4787-bf5d-11a20cb08d9b			\N	\N	11e62964-3046-4ea3-aa58-9a409322fe60	9e95fe34-362a-4077-8b7b-1156903f41f6	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	\N	2025-04-03 09:55:21.497978	No domain specified	\N
\.


--
-- Data for Name: acorn_location_area_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_area_types (id, name, description, server_id, created_at, created_by_user_id, response) FROM stdin;
9543b0ea-f4ed-4d01-867c-b8ae8c538f99	Country	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
705acf46-9875-428a-b5ee-557b3bbccf4b	Canton	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
77dab170-e9e8-43c1-a957-71fc0ce17d78	City	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
6df36782-529a-45a9-825a-6870f17b96b2	Village	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
ef15d7d0-eef2-4904-a596-c1b7270a50bf	Town	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
6d693694-ae57-451d-9ceb-0c71a968c1a8	Comune	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
\.


--
-- Data for Name: acorn_location_areas; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_areas (id, name, description, area_type_id, parent_area_id, gps_id, server_id, version, is_current_version, created_at, created_by_user_id, response) FROM stdin;
52e3448d-dc20-441d-a424-501df1853843	Syria	\N	9543b0ea-f4ed-4d01-867c-b8ae8c538f99	\N	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	1	t	2025-04-03 08:43:13.735603	\N	No domain specified
c290c871-bd35-4205-a839-da7ac29a080d	Cezîra	\N	705acf46-9875-428a-b5ee-557b3bbccf4b	52e3448d-dc20-441d-a424-501df1853843	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	1	t	2025-04-03 08:43:13.735603	\N	No domain specified
11e62964-3046-4ea3-aa58-9a409322fe60	Qamişlo	\N	77dab170-e9e8-43c1-a957-71fc0ce17d78	c290c871-bd35-4205-a839-da7ac29a080d	ab7e8e74-65e2-46dd-b43e-d1260fb35f41	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	1	t	2025-04-03 08:43:13.735603	\N	No domain specified
c2059e44-095a-470a-a1fd-05a53f26966b	Al Hêseke	\N	77dab170-e9e8-43c1-a957-71fc0ce17d78	c290c871-bd35-4205-a839-da7ac29a080d	b2e6dc49-acb5-4afe-9e10-484a7729e02d	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	1	t	2025-04-03 08:43:13.735603	\N	No domain specified
\.


--
-- Data for Name: acorn_location_gps; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_gps (id, longitude, latitude, server_id, created_at, created_by_user_id, response) FROM stdin;
ab7e8e74-65e2-46dd-b43e-d1260fb35f41	37.0343936	41.2146239	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
b2e6dc49-acb5-4afe-9e10-484a7729e02d	36.5166478	40.7416334	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified
9e95fe34-362a-4077-8b7b-1156903f41f6	\N	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 09:55:21.497978	\N	No domain specified
\.


--
-- Data for Name: acorn_location_locations; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_locations (id, address_id, name, description, image, server_id, created_at, created_by_user_id, response, type_id) FROM stdin;
9e95fe34-4596-4431-865c-a5a8d2a638c4	9e95fe34-42dd-4787-bf5d-11a20cb08d9b	Court buildings	\N		cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 09:55:21.497978	\N	No domain specified	\N
\.


--
-- Data for Name: acorn_location_lookup; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_lookup (id, address, city, zip, country_code, state_code, latitude, longitude, vicinity, created_at) FROM stdin;
\.


--
-- Data for Name: acorn_location_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_location_types (id, name, description, parent_type_id, server_id, created_at, created_by_user_id, response, colour, image) FROM stdin;
669565d6-4a61-4ee4-b0c7-c515cda939fe	Office	\N	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified	\N	\N
62bcfe95-0ce1-4410-8557-e69a79f9bff9	Warehouse	\N	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified	\N	\N
4d0ef489-11b2-4631-a588-d499c86d5ac5	Supplier	\N	\N	cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	2025-04-03 08:43:13.735603	\N	No domain specified	\N	\N
\.


--
-- Data for Name: acorn_messaging_action; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_action (message_id, action, settings, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_label; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_label (id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_message (id, user_from_id, subject, body, labels, "externalID", source, mime_type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message_instance; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_message_instance (message_id, instance_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message_message; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_message_message (message1_id, message2_id, relationship, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message_user; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_message_user (message_id, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_message_user_group; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_message_user_group (message_id, user_group_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_messaging_status; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_status (id, name, description, created_at, updated_at) FROM stdin;
b22ad830-c533-45b3-a785-bcd560a61a26	Arrived	For external messages only, like email.	\N	\N
a92b4430-24dc-41ac-8483-aff392aab116	Seen	In a list	\N	\N
47b7bed3-8216-4e3b-83f9-d5e708e82979	Read	In full view, or if not truncated in a list	\N	\N
3c78554e-1551-439c-9555-0edfad45abfd	Important	User Action	\N	\N
ff3b282d-6941-4aee-8d8a-db1b8bcee14e	Hidden	User Action	\N	\N
\.


--
-- Data for Name: acorn_messaging_user_message_status; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_messaging_user_message_status (user_id, message_id, status_id, value, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_reporting_reports; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_reporting_reports (id, settings, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_servers; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_servers (id, hostname, domain, response, created_at, location_id) FROM stdin;
cf9c9fa5-349c-4b42-a4af-ffac2a7c98bc	laptop	\N	\N	2025-04-03 08:42:57	\N
\.


--
-- Data for Name: acorn_university_academic_years; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_academic_years (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_course_language; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_course_language (course_id, language_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_course_materials; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_course_materials (id, course_id, material_id, required, minimum, maximum, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, weight, semester_year_id, academic_year_id, calculation_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_courses; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_courses (id, entity_id, weight, calculation_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_departments; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_departments (id, entity_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_education_authorities; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_education_authorities (id, entity_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_entities; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_entities (id, user_group_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_faculties; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_faculties (id, entity_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_hierarchies; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_hierarchies (id, entity_id, year_id, parent_id, server_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, nest_left, nest_right, nest_depth) FROM stdin;
\.


--
-- Data for Name: acorn_university_material_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_material_types (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, calculation_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_materials; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_materials (id, name, description, material_type_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_project_students; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_project_students (id, name, owner_student_id, user_group_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id, score, course_material_id, project_id, description) FROM stdin;
\.


--
-- Data for Name: acorn_university_projects; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_projects (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_schools; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_schools (id, entity_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_semester_years; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_semester_years (id, year_id, semester_id, event_id, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_semesters; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_semesters (id, name, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_students; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_students (id, user_id, code) FROM stdin;
9ea61aa6-e7cf-4e71-b2d5-9375b103374f	9ea61aa6-e680-484d-9d30-aba185c5b329	KOB99
9ea61ac5-d366-40f0-a172-4585931faa1f	9ea61ac5-d211-4e52-86f5-10c6d4dbe688	ROJ01
\.


--
-- Data for Name: acorn_university_teachers; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_teachers (id, user_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_universities; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_universities (id, entity_id) FROM stdin;
\.


--
-- Data for Name: acorn_university_years; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_university_years (id, name, start, "end", current, description, created_at_event_id, updated_at_event_id, created_by_user_id, updated_by_user_id, server_id) FROM stdin;
\.


--
-- Data for Name: acorn_user_language_user; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_language_user (user_id, language_id) FROM stdin;
9ea61aa6-e680-484d-9d30-aba185c5b329	9eaa5c43-db07-4597-ac8c-156253e84376
9ed4aad8-b9a4-44b6-82ae-3d80b981cbd5	9eaa5c43-db07-4597-ac8c-156253e84376
9ed4aad8-b9a4-44b6-82ae-3d80b981cbd5	9eaa5c4d-9080-4799-afa7-3741349b5beb
9eda3ec9-0240-4f44-8f58-ff497c3845d3	9eaa5c43-db07-4597-ac8c-156253e84376
\.


--
-- Data for Name: acorn_user_languages; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_languages (id, name) FROM stdin;
9eaa5c43-db07-4597-ac8c-156253e84376	Kurdish
9eaa5c4d-9080-4799-afa7-3741349b5beb	English
\.


--
-- Data for Name: acorn_user_mail_blockers; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_mail_blockers (id, email, template, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_user_role_user; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_role_user (user_id, role_id) FROM stdin;
\.


--
-- Data for Name: acorn_user_roles; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_roles (id, name, permissions, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: acorn_user_throttle; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_throttle (id, user_id, ip_address, attempts, last_attempt_at, is_suspended, suspended_at, is_banned, banned_at) FROM stdin;
9ea0e068-32b3-4f4e-b4ac-6f2c0101019a	9e95e47b-46dc-492d-8ffa-1954bc3f1611	\N	0	\N	f	\N	f	\N
9ea8645a-2223-40ae-a4e7-d220afbb5f70	9ea61ac5-d211-4e52-86f5-10c6d4dbe688	\N	0	\N	f	\N	f	\N
9ed51c00-b00d-49b2-b119-233b8823a538	9ea61aa6-e680-484d-9d30-aba185c5b329	\N	0	\N	f	\N	f	\N
9ed51c21-82b4-4eba-b2d9-84c4712987f0	9e95e47c-db72-48ec-8c0c-908592ebf59c	\N	0	\N	f	\N	f	\N
\.


--
-- Data for Name: acorn_user_user_group; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_user_group (user_id, user_group_id) FROM stdin;
9ea61ac5-d211-4e52-86f5-10c6d4dbe688	cae7ba7c-1b63-11f0-8a05-c36be60d3d46
9ea61aa6-e680-484d-9d30-aba185c5b329	cae7ba7c-1b63-11f0-8a05-c36be60d3d46
9ea61aa6-e680-484d-9d30-aba185c5b329	f2c7a61a-1b63-11f0-9899-2b70d1861dd4
9ed4aad8-b9a4-44b6-82ae-3d80b981cbd5	f334763c-1b63-11f0-aab4-4f7e5f7e30cb
9ea61ac5-d211-4e52-86f5-10c6d4dbe688	f334763c-1b63-11f0-aab4-4f7e5f7e30cb
9ea61aa6-e680-484d-9d30-aba185c5b329	f334763c-1b63-11f0-aab4-4f7e5f7e30cb
9e95e47c-db72-48ec-8c0c-908592ebf59c	f334763c-1b63-11f0-aab4-4f7e5f7e30cb
9eda3ec9-0240-4f44-8f58-ff497c3845d3	f334763c-1b63-11f0-aab4-4f7e5f7e30cb
9eda41e0-abe7-4899-8d7b-bcfa2fd7bd8c	f334763c-1b63-11f0-aab4-4f7e5f7e30cb
9e95e477-1d74-4314-8ae8-4dbb605cb027	f334763c-1b63-11f0-aab4-4f7e5f7e30cb
9e95e475-919e-472a-b1e3-65d83adee981	f334763c-1b63-11f0-aab4-4f7e5f7e30cb
a11d6172-6565-4195-a62e-038358aa9fa9	f334763c-1b63-11f0-aab4-4f7e5f7e30cb
9e95e47b-46dc-492d-8ffa-1954bc3f1611	f334763c-1b63-11f0-aab4-4f7e5f7e30cb
9ea61aa6-e680-484d-9d30-aba185c5b329	505282d6-2cf9-11f0-8450-87f83af99ff9
9ea61ac5-d211-4e52-86f5-10c6d4dbe688	505282d6-2cf9-11f0-8450-87f83af99ff9
\.


--
-- Data for Name: acorn_user_user_group_types; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_user_group_types (id, name, description, colour, image, created_at, updated_at) FROM stdin;
9ec2de06-399d-4bc4-8cb0-e641a39aef1d	Test	\N	\N		\N	\N
\.


--
-- Data for Name: acorn_user_user_groups; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_user_groups (id, name, code, description, created_at, updated_at, parent_user_group_id, nest_left, nest_right, nest_depth, image, colour, type_id, location_id) FROM stdin;
9e95e450-a158-42c4-a1ea-fddb46b67e7e	Registered	registered	Default group for registered users.	2025-04-03 07:42:58	2025-05-07 08:56:03	\N	2	10	0	\N	\N	\N	\N
f2c7a61a-1b63-11f0-9899-2b70d1861dd4	Kobani	\N	\N	\N	2025-05-07 08:56:03	\N	9	9	0	\N	\N	\N	\N
cae7ba7c-1b63-11f0-8a05-c36be60d3d46	Rojava	ROJ	test	\N	2025-05-07 08:56:03	9e95e450-a158-42c4-a1ea-fddb46b67e7e	9	9	3	/logo.png	#F1C40F	9ec2de06-399d-4bc4-8cb0-e641a39aef1d	9e95fe34-4596-4431-865c-a5a8d2a638c4
f334763c-1b63-11f0-aab4-4f7e5f7e30cb	Jineologi	JIN		\N	2025-05-07 08:56:03	cae7ba7c-1b63-11f0-8a05-c36be60d3d46	9	9	3		#34495E	\N	\N
9eda63ea-1b4f-4e2e-bb54-3dcb69d08f1e	Wibble	wibble		2025-05-07 08:56:03	2025-05-07 08:56:03	f334763c-1b63-11f0-aab4-4f7e5f7e30cb	7	8	1		\N	9ec2de06-399d-4bc4-8cb0-e641a39aef1d	\N
9e95e450-97ee-40a8-a55e-4eb76beaf9ae	Guest	guest	Default group for guest users.	2025-04-03 07:42:58	2025-04-25 16:48:45	\N	0	1	0	\N	\N	\N	\N
9e95fdfa-b625-41d9-8f01-15d71f6b7552	weeee	weeee		2025-04-03 08:54:43	2025-04-25 16:48:45	9e95e450-a158-42c4-a1ea-fddb46b67e7e	3	4	1		\N	\N	9e95fe34-4596-4431-865c-a5a8d2a638c4
2c4251c8-2cf9-11f0-bbd1-3370778ee65e	Education Committee	EDU	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N
505282d6-2cf9-11f0-8450-87f83af99ff9	Til Maroof school	MAR	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N
a7237520-2d8f-11f0-a834-2b294fbfca54	Science	SCI	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N
a828ffc6-2d8f-11f0-9495-9bc5bbe65e8b	Literature	LIT	\N	\N	\N	\N	0	0	0	\N	\N	\N	\N
9ec87e7c-cb27-4774-a024-6f4df6b3c61e	Jineologi2	jineologi2		2025-04-28 11:25:27	2025-04-28 11:25:27	cae7ba7c-1b63-11f0-8a05-c36be60d3d46	5	6	1		#2ECC71	9ec2de06-399d-4bc4-8cb0-e641a39aef1d	\N
\.


--
-- Data for Name: acorn_user_users; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.acorn_user_users (id, name, email, password, activation_code, persist_code, reset_password_code, permissions, is_activated, is_system_user, activated_at, last_login, created_at, updated_at, username, surname, deleted_at, last_seen, is_guest, is_superuser, created_ip_address, last_ip_address, acorn_imap_username, acorn_imap_password, acorn_imap_server, acorn_imap_port, acorn_imap_protocol, acorn_imap_encryption, acorn_imap_authentication, acorn_imap_validate_cert, acorn_smtp_server, acorn_smtp_port, acorn_smtp_encryption, acorn_smtp_authentication, acorn_smtp_username, acorn_smtp_password, acorn_messaging_sounds, acorn_messaging_email_notifications, acorn_messaging_autocreated, acorn_imap_last_fetch, acorn_default_calendar, acorn_start_of_week, acorn_default_event_time_from, acorn_default_event_time_to, birth_date) FROM stdin;
9e95e475-919e-472a-b1e3-65d83adee981	Artisan	artisan@nowhere.org	$2y$10$04rS6CabSidfoSyFEwaOGeuv0SvRfwEySaQuyPFH0Szw2UnO5FoIS	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:22	2025-04-03 07:43:22	artisan	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9e95e477-1d74-4314-8ae8-4dbb605cb027	Createsystem	createsystem@nowhere.org	$2y$10$xELVx7Ue7aLR2ffoLahdz.8nQsrCJu3uVZq3b2DRd4OV/zWPGBcWC	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:23	2025-04-03 07:43:23	createsystem	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9e95e478-70c6-49a6-a82c-47f3639fc748	Seeder	seeder@nowhere.org	$2y$10$jnVJoLvkr0UMQ59RN6oZc.bFWyB0oVcteNUQ80N0EcAjv2xbAprpG	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:24	2025-04-03 07:43:24	seeder	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9e95e479-9690-4091-a730-aecdf51f9258	Admin	admin@nowhere.org	$2y$10$CYphtl51Fbdv2TZcNZdtrezTwWNw0qeGfSc6oiuYEpE/pOK4gupYy	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:24	2025-04-03 07:43:24	admin	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
a11d6172-6565-4195-a62e-038358aa9fa9	seeder	\N	\N	\N	\N	\N	\N	f	t	\N	\N	\N	\N	\N	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9e95e47b-46dc-492d-8ffa-1954bc3f1611	sz	sz@nowhere.org	$2y$10$lta6VXUFah18WoaE0L6/2eNtXxV1pJ14tG4juSxDF5QOlGq6C86zu	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:26	2025-04-03 07:43:26	sz	\N	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1971-08-11 00:00:00
9ed4aad8-b9a4-44b6-82ae-3d80b981cbd5	Weeeeeee	a@we22.com	\N	\N	\N	\N	\N	f	f	\N	\N	2025-05-04 12:39:25	2025-05-04 12:39:25	a@we22.com	w	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9ea61ac5-d211-4e52-86f5-10c6d4dbe688	You	a	\N	\N	\N	\N	\N	f	f	\N	\N	2025-04-11 09:08:29	2025-05-04 17:52:21	a	1	\N	\N	f	f	\N	\N	a		imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal	a		f	N	\N	\N	ceea8856-e4c8-11ef-8719-5f58c97885a2	1	\N	\N	2001-10-10 00:00:00
9ea61aa6-e680-484d-9d30-aba185c5b329	Me		\N	\N	\N	\N	\N	f	f	\N	\N	2025-04-11 09:08:09	2025-05-04 17:55:58		1to1	\N	\N	f	f	\N	\N			imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal			f	N	\N	\N	ceea8856-e4c8-11ef-8719-5f58c97885a2	1	\N	\N	1971-08-11 00:00:00
9e95e47c-db72-48ec-8c0c-908592ebf59c	Demo	demo@nowhere.org	$2y$10$fXtS/tknV8gTiWiKWD4NEuYaGRQ.aMaTKLjYUlko6bkH7V2JZq7Oa	\N	\N	\N	\N	f	f	\N	\N	2025-04-03 07:43:27	2025-05-04 17:56:19	demo		\N	\N	f	f	\N	\N	demo@nowhere.org		imap.stackmail.com	993	imap	ssl		t	smtp.stackmail.com	465	ssl	normal	demo@nowhere.org		f	N	\N	\N	ceea8856-e4c8-11ef-8719-5f58c97885a2	1	\N	\N	2001-10-10 00:00:00
9eda3ec9-0240-4f44-8f58-ff497c3845d3	Yani	r@a.com	\N	\N	\N	\N	\N	f	f	\N	\N	2025-05-07 07:12:14	2025-05-07 07:12:14	r@a.com		\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9eda41e0-abe7-4899-8d7b-bcfa2fd7bd8c	a	a@b.com44	\N	\N	\N	\N	\N	f	f	\N	\N	2025-05-07 07:20:53	2025-05-07 07:20:53	a@b.com44	s	\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9eda61e1-2736-4187-bb6f-8ed20e6cc171	Yippee 38745	y@hhh.com	\N	\N	\N	\N	\N	f	f	\N	\N	2025-05-07 08:50:22	2025-05-07 08:50:22	y@hhh.com		\N	\N	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: backend_access_log; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_access_log (id, user_id, ip_address, created_at, updated_at) FROM stdin;
1	1	127.0.0.1	2025-04-03 07:44:19	2025-04-03 07:44:19
2	1	127.0.0.1	2025-04-08 11:22:57	2025-04-08 11:22:57
3	1	127.0.0.1	2025-04-08 13:35:30	2025-04-08 13:35:30
4	1	127.0.0.1	2025-04-08 13:36:45	2025-04-08 13:36:45
5	1	127.0.0.1	2025-04-17 09:10:43	2025-04-17 09:10:43
6	1	127.0.0.1	2025-04-22 07:33:37	2025-04-22 07:33:37
7	1	127.0.0.1	2025-04-23 13:32:41	2025-04-23 13:32:41
\.


--
-- Data for Name: backend_user_groups; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_user_groups (id, name, created_at, updated_at, code, description, is_new_user_default) FROM stdin;
1	Owners	2025-04-03 07:39:25	2025-04-03 07:39:25	owners	Default group for website owners.	f
\.


--
-- Data for Name: backend_user_preferences; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_user_preferences (id, user_id, namespace, "group", item, value) FROM stdin;
2	5	backend	backend	preferences	{"locale":"ku","fallback_locale":"en","timezone":"Europe\\/Istanbul","icon_location":"inline","menu_location":"top"}
3	6	backend	backend	preferences	{"locale":"ku","fallback_locale":"en","timezone":"Europe\\/Istanbul","icon_location":"inline","menu_location":"top"}
1	1	backend	backend	preferences	{"locale":"en","fallback_locale":"en","timezone":"Europe\\/Istanbul","icon_location":"inline","menu_location":"top","dark_mode":"light","editor_theme":"twilight","editor_word_wrap":"off","editor_font_size":"11","editor_tab_size":"2","editor_code_folding":"manual","editor_autocompletion":"manual","editor_show_gutter":"0","editor_highlight_active_line":"0","editor_use_hard_tabs":"0","editor_display_indent_guides":"0","editor_show_invisibles":"0","editor_show_print_margin":"0","editor_auto_closing":"0","editor_enable_snippets":"0","user_id":1}
11	1	acorn_university	students	lists-relationexamdataentryscoresstudentviewlist	{"visible":["scores","_actions","course_user_group","exam"],"order":["student","scores","_qrcode","_actions","ids","exam_material_ids","student_user","student_code","course_user_group","course_code","exam","student_ids","titles"],"per_page":"10"}
5	1	acorn_exam	exams	lists-relationexamresultsexamviewlist	{"visible":["id","student","calculation","entity","expression","expression_type","needs_evaluate","result","_actions"],"order":["id","student","exam","calculation","entity","expression","expression_type","needs_evaluate","result","_qrcode","_actions"],"per_page":"10"}
10	1	acorn_university	courses	lists-relationuniversitycoursematerialscourseviewlist	{"visible":["course","material","required","minimum","maximum","weight","exam_exam_materials__course_material","_actions"],"order":["id","course","material","required","minimum","maximum","created_at_event","updated_at_event","created_by_user","updated_by_user","server","weight","exam_exam_materials__course_material","_qrcode","_actions"],"per_page":"10"}
4	1	acorn_university	students	lists-relationexamresultsstudentviewlist	{"visible":["student","exam","calculation","expression","expression_type","needs_evaluate","result","_actions","course"],"order":["id","student","exam","calculation","expression","expression_type","needs_evaluate","result","_qrcode","_actions","name","course_material","course","project","interview"],"per_page":"10"}
6	1	acorn_exam	tokens	lists	{"visible":["name","student","exam","calculation","entity","expression","expression_type","needs_evaluate","_actions"],"order":["id","name","student","exam","calculation","entity","expression","expression_type","needs_evaluate","_qrcode","_actions"],"per_page":"20"}
7	1	acorn_university	universities	lists	{"visible":["name","_actions","code","colour","image","description","parent_user_group"],"order":["id","name","_qrcode","_actions","code","colour","image","description","parent_user_group"],"per_page":"20"}
8	1	acorn_university	courses	lists	{"visible":["name","code","colour","university_course_materials__course","_actions","weight"],"order":["id","name","code","colour","image","university_course_materials__course","_qrcode","_actions","created_at_event","updated_at_event","result_expression","weight","exam_results__course"],"per_page":"20"}
9	1	acorn_university	students	lists	{"visible":["name","surname","email","username","created_ip_address","code","exam_scores__student","exam_interview_students__student","_actions","university_project_students__owner_student"],"order":["id","name","surname","email","username","created_ip_address","last_ip_address","code","exam_scores__student","exam_interview_students__student","exam_results__student","_qrcode","_actions","university_project_students__owner_student"],"per_page":"20"}
\.


--
-- Data for Name: backend_user_roles; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_user_roles (id, name, code, description, permissions, is_system, created_at, updated_at) FROM stdin;
1	Publisher	publisher	Site editor with access to publishing tools.		t	2025-04-03 07:39:25	2025-04-03 07:39:25
2	Developer	developer	Site administrator with access to developer tools.		t	2025-04-03 07:39:25	2025-04-03 07:39:25
\.


--
-- Data for Name: backend_user_throttle; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_user_throttle (id, user_id, ip_address, attempts, last_attempt_at, is_suspended, suspended_at, is_banned, banned_at) FROM stdin;
1	1	127.0.0.1	0	\N	f	\N	f	\N
2	5	\N	0	\N	f	\N	f	\N
3	4	\N	0	\N	f	\N	f	\N
\.


--
-- Data for Name: backend_users; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_users (id, first_name, last_name, login, email, password, activation_code, persist_code, reset_password_code, permissions, is_activated, role_id, activated_at, last_login, created_at, updated_at, deleted_at, is_superuser, metadata, acorn_url, acorn_user_user_id) FROM stdin;
2	\N	\N	artisan	artisan@nowhere.org	$2y$10$ChjYqkUapNB3KsaekjQJGu1zgrgW7O.ru9QdlngpWvtrHSMUFvGnC	\N	\N	\N	\N	f	\N	\N	\N	2025-04-03 07:43:21	2025-04-03 07:43:22	\N	f	\N	\N	9e95e475-919e-472a-b1e3-65d83adee981
3	\N	\N	createsystem	createsystem@nowhere.org	$2y$10$ZqIy57H.7gf1NW8KyJ0ykOKXnn/AtOJO3IZEZFVk6bcVX7fQFODi6	\N	\N	\N	\N	f	\N	\N	\N	2025-04-03 07:43:23	2025-04-03 07:43:23	\N	f	\N	\N	9e95e477-1d74-4314-8ae8-4dbb605cb027
4	\N	\N	seeder	seeder@nowhere.org	$2y$10$HJ1ZIEc4od1rqY9awLMeeulTb91fIOuQup1MnLtVkaqR2o6.etILu	\N	\N	\N	\N	f	\N	\N	\N	2025-04-03 07:43:23	2025-04-03 07:43:24	\N	f	\N	\N	9e95e478-70c6-49a6-a82c-47f3639fc748
5	\N	\N	sz	sz@nowhere.org	$2y$10$r5Zck2dEs35hFYhepIOFeOKrp3CfQ5u.vlTew04YgIaumzY8uq1Uu	\N	\N	\N	\N	f	\N	\N	\N	2025-04-03 07:43:25	2025-04-03 07:43:26	\N	f	\N	\N	9e95e47b-46dc-492d-8ffa-1954bc3f1611
6	\N	\N	demo	demo@nowhere.org	$2y$10$iDWeqZhd1b/q.naIRMthX.wNkPXpdqVCP3FwLOSIyxlnJmKevMney	\N	\N	\N	\N	f	\N	\N	\N	2025-04-03 07:43:26	2025-04-03 07:43:27	\N	f	\N	\N	9e95e47c-db72-48ec-8c0c-908592ebf59c
1	Admin	Person	admin	admin@example.com	$2y$10$WE.zLZTDg7WGnQphFr431.dSBCDebgw/QbRNYzhnhI7OuliWyv8/C	\N	$2y$10$IV0RC1KM6rbmD.DtR.9PjeK7e2irMLAtesTME1d.ID3C0IbLDPQre	\N		t	2	\N	2025-04-23 13:32:41	2025-04-03 07:39:25	2025-04-23 13:32:41	\N	t	\N	\N	9e95e479-9690-4091-a730-aecdf51f9258
\.


--
-- Data for Name: backend_users_groups; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.backend_users_groups (user_id, user_group_id, deleted_at) FROM stdin;
1	1	\N
\.


--
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.cache (key, value, expiration) FROM stdin;
\.


--
-- Data for Name: cms_theme_data; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.cms_theme_data (id, theme, data, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cms_theme_logs; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.cms_theme_logs (id, type, theme, template, old_template, content, old_content, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cms_theme_templates; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.cms_theme_templates (id, source, path, content, file_size, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: deferred_bindings; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.deferred_bindings (id, master_type, master_field, slave_type, slave_id, session_key, is_bind, created_at, updated_at, pivot_data) FROM stdin;
1	Acorn\\Exam\\Models\\Exam	exam_exam_material_exams	Acorn\\Exam\\Models\\Material	5d92a794-e582-41af-9c63-076c3c5ec7ad	czDZYDTSfY1jczSDQWtT1o8aSpfw6nPikpRvIONN	t	2025-04-08 17:44:10	2025-04-08 17:44:10	\N
2	Acorn\\Exam\\Models\\Exam	exam_exam_material_exams	Acorn\\Exam\\Models\\Material	4ceccaec-a157-4e28-8aa4-e8be31a461e1	czDZYDTSfY1jczSDQWtT1o8aSpfw6nPikpRvIONN	t	2025-04-08 17:44:10	2025-04-08 17:44:10	\N
\.


--
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.failed_jobs (id, connection, queue, payload, failed_at, exception, uuid) FROM stdin;
\.


--
-- Data for Name: job_batches; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: university
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
50	2024_01_01_000001_Db_PluginMenuControl	4
51	2024_01_01_000001_Db_Servers	4
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.sessions (id, payload, last_activity, user_id, ip_address, user_agent) FROM stdin;
\.


--
-- Data for Name: system_event_logs; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_event_logs (id, level, message, details, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_files; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_files (id, disk_name, file_name, file_size, content_type, title, description, field, attachment_id, attachment_type, is_public, sort_order, created_at, updated_at) FROM stdin;
1	68174cfc92925152822883.png	Screenshot_20250317_231933.png	1174067	image/png	\N	\N	avatar	9ea61aa6-e680-484d-9d30-aba185c5b329	Acorn\\User\\Models\\User	t	1	2025-05-04 11:18:20	2025-05-04 11:18:25
\.


--
-- Data for Name: system_mail_layouts; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_mail_layouts (id, name, code, content_html, content_text, content_css, is_locked, created_at, updated_at, options) FROM stdin;
1	Default layout	default	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml">\n<head>\n    <meta name="viewport" content="width=device-width, initial-scale=1.0" />\n    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />\n    <style type="text/css" media="screen">\n        {{ brandCss|raw }}\n        {{ css|raw }}\n    </style>\n</head>\n<body>\n    <table class="wrapper layout-default" width="100%" cellpadding="0" cellspacing="0">\n\n        <!-- Header -->\n        {% partial 'header' body %}\n            {{ subject|raw }}\n        {% endpartial %}\n\n        <tr>\n            <td align="center">\n                <table class="content" width="100%" cellpadding="0" cellspacing="0">\n                    <!-- Email Body -->\n                    <tr>\n                        <td class="body" width="100%" cellpadding="0" cellspacing="0">\n                            <table class="inner-body" align="center" width="570" cellpadding="0" cellspacing="0">\n                                <!-- Body content -->\n                                <tr>\n                                    <td class="content-cell">\n                                        {{ content|raw }}\n                                    </td>\n                                </tr>\n                            </table>\n                        </td>\n                    </tr>\n                </table>\n            </td>\n        </tr>\n\n        <!-- Footer -->\n        {% partial 'footer' body %}\n            &copy; {{ "now"|date("Y") }} {{ appName }}. All rights reserved.\n        {% endpartial %}\n\n    </table>\n\n</body>\n</html>	{{ content|raw }}	@media only screen and (max-width: 600px) {\n    .inner-body {\n        width: 100% !important;\n    }\n\n    .footer {\n        width: 100% !important;\n    }\n}\n\n@media only screen and (max-width: 500px) {\n    .button {\n        width: 100% !important;\n    }\n}	t	2025-04-03 07:39:25	2025-04-03 07:39:25	\N
2	System layout	system	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml">\n<head>\n    <meta name="viewport" content="width=device-width, initial-scale=1.0" />\n    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />\n    <style type="text/css" media="screen">\n        {{ brandCss|raw }}\n        {{ css|raw }}\n    </style>\n</head>\n<body>\n    <table class="wrapper layout-system" width="100%" cellpadding="0" cellspacing="0">\n        <tr>\n            <td align="center">\n                <table class="content" width="100%" cellpadding="0" cellspacing="0">\n                    <!-- Email Body -->\n                    <tr>\n                        <td class="body" width="100%" cellpadding="0" cellspacing="0">\n                            <table class="inner-body" align="center" width="570" cellpadding="0" cellspacing="0">\n                                <!-- Body content -->\n                                <tr>\n                                    <td class="content-cell">\n                                        {{ content|raw }}\n\n                                        <!-- Subcopy -->\n                                        {% partial 'subcopy' body %}\n                                            **This is an automatic message. Please do not reply to it.**\n                                        {% endpartial %}\n                                    </td>\n                                </tr>\n                            </table>\n                        </td>\n                    </tr>\n                </table>\n            </td>\n        </tr>\n    </table>\n\n</body>\n</html>	{{ content|raw }}\n\n\n---\nThis is an automatic message. Please do not reply to it.	@media only screen and (max-width: 600px) {\n    .inner-body {\n        width: 100% !important;\n    }\n\n    .footer {\n        width: 100% !important;\n    }\n}\n\n@media only screen and (max-width: 500px) {\n    .button {\n        width: 100% !important;\n    }\n}	t	2025-04-03 07:39:25	2025-04-03 07:39:25	\N
\.


--
-- Data for Name: system_mail_partials; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_mail_partials (id, name, code, content_html, content_text, is_custom, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_mail_templates; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_mail_templates (id, code, subject, description, content_html, content_text, layout_id, is_custom, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_parameters; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_parameters (id, namespace, "group", item, value) FROM stdin;
1	system	app	birthday	"2025-04-03T07:39:23.508552Z"
2	system	update	count	0
4	system	core	modified	true
3	system	core	build	"1.2.6"
5	system	update	retry	1746868419
\.


--
-- Data for Name: system_plugin_history; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_plugin_history (id, code, type, version, detail, created_at) FROM stdin;
1	Winter.Demo	comment	1.0.1	First version of Demo	2025-04-03 07:39:25
2	Acorn.User	script	1.0.1	v1.0.1/create_users_table.php	2025-04-03 07:42:57
3	Acorn.User	script	1.0.1	v1.0.1/create_throttle_table.php	2025-04-03 07:42:57
4	Acorn.User	comment	1.0.1	Initialize plugin.	2025-04-03 07:42:57
5	Acorn.User	comment	1.0.2	Seed tables.	2025-04-03 07:42:57
6	Acorn.User	comment	1.0.3	Translated hard-coded text to language strings.	2025-04-03 07:42:57
7	Acorn.User	comment	1.0.4	Improvements to user-interface for Location manager.	2025-04-03 07:42:57
8	Acorn.User	comment	1.0.5	Added contact details for users.	2025-04-03 07:42:57
9	Acorn.User	script	1.0.6	v1.0.6/create_mail_blockers_table.php	2025-04-03 07:42:57
10	Acorn.User	comment	1.0.6	Added Mail Blocker utility so users can block specific mail templates.	2025-04-03 07:42:57
11	Acorn.User	comment	1.0.7	Add back-end Settings page.	2025-04-03 07:42:57
12	Acorn.User	comment	1.0.8	Updated the Settings page.	2025-04-03 07:42:57
13	Acorn.User	comment	1.0.9	Adds new welcome mail message for users and administrators.	2025-04-03 07:42:57
14	Acorn.User	comment	1.0.10	Adds administrator-only activation mode.	2025-04-03 07:42:57
15	Acorn.User	script	1.0.11	v1.0.11/users_add_login_column.php	2025-04-03 07:42:57
16	Acorn.User	comment	1.0.11	Users now have an optional login field that defaults to the email field.	2025-04-03 07:42:57
17	Acorn.User	script	1.0.12	v1.0.12/users_rename_login_to_username.php	2025-04-03 07:42:57
18	Acorn.User	comment	1.0.12	Create a dedicated setting for choosing the login mode.	2025-04-03 07:42:57
19	Acorn.User	comment	1.0.13	Minor fix to the Account sign in logic.	2025-04-03 07:42:57
20	Acorn.User	comment	1.0.14	Minor improvements to the code.	2025-04-03 07:42:57
21	Acorn.User	script	1.0.15	v1.0.15/users_add_surname.php	2025-04-03 07:42:57
22	Acorn.User	comment	1.0.15	Adds last name column to users table (surname).	2025-04-03 07:42:57
23	Acorn.User	comment	1.0.16	Require permissions for settings page too.	2025-04-03 07:42:57
24	Acorn.User	comment	1.1.0	!!! Profile fields and Locations have been removed.	2025-04-03 07:42:57
25	Acorn.User	script	1.1.1	v1.1.1/create_user_groups_table.php	2025-04-03 07:42:57
26	Acorn.User	script	1.1.1	v1.1.1/seed_user_groups_table.php	2025-04-03 07:42:58
27	Acorn.User	comment	1.1.1	Users can now be added to groups.	2025-04-03 07:42:58
28	Acorn.User	comment	1.1.2	A raw URL can now be passed as the redirect property in the Account component.	2025-04-03 07:42:58
29	Acorn.User	comment	1.1.3	Adds a super user flag to the users table, reserved for future use.	2025-04-03 07:42:58
30	Acorn.User	comment	1.1.4	User list can be filtered by the group they belong to.	2025-04-03 07:42:58
31	Acorn.User	comment	1.1.5	Adds a new permission to hide the User settings menu item.	2025-04-03 07:42:58
32	Acorn.User	script	1.2.0	v1.2.0/users_add_deleted_at.php	2025-04-03 07:42:58
33	Acorn.User	comment	1.2.0	Users can now deactivate their own accounts.	2025-04-03 07:42:58
34	Acorn.User	comment	1.2.1	New feature for checking if a user is recently active/online.	2025-04-03 07:42:58
35	Acorn.User	comment	1.2.2	Add bulk action button to user list.	2025-04-03 07:42:58
36	Acorn.User	comment	1.2.3	Included some descriptive paragraphs in the Reset Password component markup.	2025-04-03 07:42:58
37	Acorn.User	comment	1.2.4	Added a checkbox for blocking all mail sent to the user.	2025-04-03 07:42:58
38	Acorn.User	script	1.2.5	v1.2.5/update_timestamp_nullable.php	2025-04-03 07:42:58
39	Acorn.User	comment	1.2.5	Database maintenance. Updated all timestamp columns to be nullable.	2025-04-03 07:42:58
40	Acorn.User	script	1.2.6	v1.2.6/users_add_last_seen.php	2025-04-03 07:42:58
41	Acorn.User	comment	1.2.6	Add a dedicated last seen column for users.	2025-04-03 07:42:58
42	Acorn.User	comment	1.2.7	Minor fix to user timestamp attributes.	2025-04-03 07:42:58
43	Acorn.User	comment	1.2.8	Add date range filter to users list. Introduced a logout event.	2025-04-03 07:42:58
44	Acorn.User	comment	1.2.9	Add invitation mail for new accounts created in the back-end.	2025-04-03 07:42:58
45	Acorn.User	script	1.3.0	v1.3.0/users_add_guest_flag.php	2025-04-03 07:42:58
46	Acorn.User	script	1.3.0	v1.3.0/users_add_superuser_flag.php	2025-04-03 07:42:58
47	Acorn.User	comment	1.3.0	Introduced guest user accounts.	2025-04-03 07:42:58
48	Acorn.User	comment	1.3.1	User notification variables can now be extended.	2025-04-03 07:42:58
49	Acorn.User	comment	1.3.2	Minor fix to the Auth::register method.	2025-04-03 07:42:58
50	Acorn.User	comment	1.3.3	Allow prevention of concurrent user sessions via the user settings.	2025-04-03 07:42:58
51	Acorn.User	comment	1.3.4	Added force secure protocol property to the account component.	2025-04-03 07:42:58
52	Acorn.User	comment	1.4.0	!!! The Notifications tab in User settings has been removed.	2025-04-03 07:42:58
53	Acorn.User	comment	1.4.1	Added support for user impersonation.	2025-04-03 07:42:58
54	Acorn.User	comment	1.4.2	Fixes security bug in Password Reset component.	2025-04-03 07:42:58
55	Acorn.User	comment	1.4.3	Fixes session handling for AJAX requests.	2025-04-03 07:42:58
56	Acorn.User	comment	1.4.4	Fixes bug where impersonation touches the last seen timestamp.	2025-04-03 07:42:58
57	Acorn.User	comment	1.4.5	Added token fallback process to Account / Reset Password components when parameter is missing.	2025-04-03 07:42:58
58	Acorn.User	comment	1.4.6	Fixes Auth::register method signature mismatch with core Winter CMS Auth library	2025-04-03 07:42:58
59	Acorn.User	comment	1.4.7	Fixes redirect bug in Account component / Update translations and separate user and group management.	2025-04-03 07:42:58
60	Acorn.User	comment	1.4.8	Fixes a bug where calling MailBlocker::removeBlock could remove all mail blocks for the user.	2025-04-03 07:42:58
61	Acorn.User	comment	1.5.0	!!! Required password length is now a minimum of 8 characters. Previous passwords will not be affected until the next password change.	2025-04-03 07:42:58
62	Acorn.User	script	1.5.1	v1.5.1/users_add_ip_address.php	2025-04-03 07:42:58
63	Acorn.User	comment	1.5.1	User IP addresses are now logged. Introduce registration throttle.	2025-04-03 07:42:58
64	Acorn.User	comment	1.5.2	Whitespace from usernames is now trimmed, allowed for username to be added to Reset Password mail templates.	2025-04-03 07:42:58
65	Acorn.User	comment	1.5.3	Fixes a bug in the user update functionality if password is not changed. Added highlighting for banned users in user list.	2025-04-03 07:42:58
66	Acorn.User	comment	1.5.4	Multiple translation improvements. Added view events to extend user preview and user listing toolbars.	2025-04-03 07:42:58
67	Acorn.User	script	2.0.0	v2.0.0/rename_tables.php	2025-04-03 07:42:58
68	Acorn.User	comment	2.0.0	Rebrand to Acorn.User	2025-04-03 07:42:58
69	Acorn.User	comment	2.0.0	Update Russian language	2025-04-03 07:42:58
70	Acorn.User	script	2.0.1	v2.0.1/rename_indexes.php	2025-04-03 07:42:59
71	Acorn.User	comment	2.0.1	Rebrand table indexes	2025-04-03 07:42:59
72	Acorn.User	comment	2.1.0	Enforce password length rules on sign in. Compatibility fixes.	2025-04-03 07:42:59
73	Acorn.User	comment	2.2.0	Add avatar removal. Password resets will activate users if User activation mode is enabled.	2025-04-03 07:42:59
74	Acorn.User	comment	2.2.1	Fixes a bug introduced by the adoption of symfony/mime required since Laravel 7.x where sending an email to a blocked email address would not be prevented.	2025-04-03 07:42:59
75	Acorn.User	comment	2.2.2	Improved French translation, updated plugin icons, fixed migrations for Laravel 9	2025-04-03 07:42:59
76	Acorn.User	script	3.0.0	v3.0.0/create_user_roles_table.php	2025-04-03 07:42:59
77	Acorn.User	script	3.0.0	v3.0.0/add_backend_user_column.php	2025-04-03 07:42:59
78	Acorn.User	script	3.0.0	v3.0.0/create_user_languages.php	2025-04-03 07:42:59
79	Acorn.User	script	3.0.0	v3.0.0/create_user_group_types_table.php	2025-04-03 07:42:59
80	Acorn.User	comment	3.0.0	User Roles	2025-04-03 07:42:59
81	Acorn.User	comment	3.0.0	Add Backend User column	2025-04-03 07:42:59
82	Acorn.User	comment	3.0.0	Create user languages XtoX	2025-04-03 07:42:59
83	Acorn.User	comment	3.0.0	Create User Group Types	2025-04-03 07:42:59
84	Acorn.User	script	3.0.2	v3.0.2/create_usage_view.php	2025-04-03 07:42:59
85	Acorn.User	script	3.0.2	v3.0.2/create_functions.php	2025-04-03 07:42:59
86	Acorn.User	comment	3.0.2	Create Usage view	2025-04-03 07:42:59
87	Acorn.User	comment	3.0.2	Create Functions	2025-04-03 07:42:59
88	Winter.Location	comment	1.0.1	Initialize plugin.	2025-04-03 07:42:59
89	Winter.Location	script	1.0.2	v1.0.2/create_states_table.php	2025-04-03 07:42:59
90	Winter.Location	script	1.0.2	v1.0.2/create_countries_table.php	2025-04-03 07:42:59
91	Winter.Location	comment	1.0.2	Create database tables.	2025-04-03 07:42:59
92	Winter.Location	script	1.0.3	v1.0.3/seed_all_tables.php	2025-04-03 07:43:06
93	Winter.Location	comment	1.0.3	Add seed data for countries and states.	2025-04-03 07:43:06
94	Winter.Location	comment	1.0.4	Satisfy the new Google API key requirement.	2025-04-03 07:43:06
95	Winter.Location	script	1.0.5	v1.0.5/add_country_pinned_flag.php	2025-04-03 07:43:06
96	Winter.Location	comment	1.0.5	Countries can now be pinned to make them appear at the top of the list.	2025-04-03 07:43:06
97	Winter.Location	comment	1.0.6	Added support for defining a default country and state.	2025-04-03 07:43:06
98	Winter.Location	comment	1.0.7	Added basic geocoding method to the Country model.	2025-04-03 07:43:06
99	Winter.Location	comment	1.0.8	Include Mexico states	2025-04-03 07:43:06
100	Winter.Location	comment	1.1.0	!!! Update requires Build 447. Fixed AddressFinder formwidget not working correctly in repeaters.	2025-04-03 07:43:06
101	Winter.Location	comment	1.1.1	Minor fix to AddressFinder formwidget for the change to the FormField API	2025-04-03 07:43:06
102	Winter.Location	comment	1.1.2	Yet another change to the AddressFinder for changes to the FormField API	2025-04-03 07:43:06
103	Winter.Location	script	1.1.3	v1.1.3/seed_ar_states.php	2025-04-03 07:43:06
104	Winter.Location	comment	1.1.3	Include Argentina states	2025-04-03 07:43:06
105	Winter.Location	comment	1.1.4	Added support for UK counties	2025-04-03 07:43:06
106	Winter.Location	script	1.1.5	v1.1.5/seed_it_states.php	2025-04-03 07:43:07
107	Winter.Location	comment	1.1.5	Include Italian states (province)	2025-04-03 07:43:07
108	Winter.Location	script	1.1.6	v1.1.6/add_enabled_states.php	2025-04-03 07:43:07
109	Winter.Location	comment	1.1.6	Added ability to disable specific states	2025-04-03 07:43:07
110	Winter.Location	script	2.0.0	v2.0.0/rename_tables.php	2025-04-03 07:43:07
111	Winter.Location	comment	2.0.0	Rebrand to Winter.location	2025-04-03 07:43:07
112	Winter.Location	script	2.0.1	v2.0.1/rename_indexes.php	2025-04-03 07:43:07
113	Winter.Location	script	2.0.1	v2.0.1/fix_translate_records.php	2025-04-03 07:43:07
114	Winter.Location	comment	2.0.1	Rebrand table indexes	2025-04-03 07:43:07
115	Winter.Location	comment	2.0.1	Add migrations for translate plugin attributes and indexes tables	2025-04-03 07:43:07
116	Winter.Location	script	2.0.2	v2.0.2/seed_ru_states.php	2025-04-03 07:43:09
117	Winter.Location	comment	2.0.2	Include Russian states (subjects)	2025-04-03 07:43:09
118	Winter.TailwindUI	comment	1.0.1	First version of TailwindUI	2025-04-03 07:43:09
119	Winter.Translate	script	1.0.1	v1.0.1/create_messages_table.php	2025-04-03 07:43:09
120	Winter.Translate	script	1.0.1	v1.0.1/create_attributes_table.php	2025-04-03 07:43:09
121	Winter.Translate	script	1.0.1	v1.0.1/create_locales_table.php	2025-04-03 07:43:09
122	Winter.Translate	comment	1.0.1	First version of Translate	2025-04-03 07:43:09
123	Winter.Translate	comment	1.0.2	Languages and Messages can now be deleted.	2025-04-03 07:43:09
124	Winter.Translate	comment	1.0.3	Minor updates for latest Winter CMS release.	2025-04-03 07:43:09
125	Winter.Translate	comment	1.0.4	Locale cache will clear when updating a language.	2025-04-03 07:43:09
126	Winter.Translate	comment	1.0.5	Add Spanish language and fix plugin config.	2025-04-03 07:43:09
127	Winter.Translate	comment	1.0.6	Minor improvements to the code.	2025-04-03 07:43:09
128	Winter.Translate	comment	1.0.7	Fixes major bug where translations are skipped entirely!	2025-04-03 07:43:09
129	Winter.Translate	comment	1.0.8	Minor bug fixes.	2025-04-03 07:43:09
130	Winter.Translate	comment	1.0.9	Fixes an issue where newly created models lose their translated values.	2025-04-03 07:43:09
131	Winter.Translate	comment	1.0.10	Minor fix for latest build.	2025-04-03 07:43:09
132	Winter.Translate	comment	1.0.11	Fix multilingual rich editor when used in stretch mode.	2025-04-03 07:43:09
133	Winter.Translate	comment	1.1.0	Introduce compatibility with Winter.Pages plugin.	2025-04-03 07:43:10
134	Winter.Translate	comment	1.1.1	Minor UI fix to the language picker.	2025-04-03 07:43:10
135	Winter.Translate	comment	1.1.2	Add support for translating Static Content files.	2025-04-03 07:43:10
136	Winter.Translate	comment	1.1.3	Improved support for the multilingual rich editor.	2025-04-03 07:43:10
137	Winter.Translate	comment	1.1.4	Adds new multilingual markdown editor.	2025-04-03 07:43:10
138	Winter.Translate	comment	1.1.5	Minor update to the multilingual control API.	2025-04-03 07:43:10
139	Winter.Translate	comment	1.1.6	Minor improvements in the message editor.	2025-04-03 07:43:10
140	Winter.Translate	comment	1.1.7	Fixes bug not showing content when first loading multilingual textarea controls.	2025-04-03 07:43:10
141	Winter.Translate	comment	1.2.0	CMS pages now support translating the URL.	2025-04-03 07:43:10
142	Winter.Translate	comment	1.2.1	Minor update in the rich editor and code editor language control position.	2025-04-03 07:43:10
143	Winter.Translate	comment	1.2.2	Static Pages now support translating the URL.	2025-04-03 07:43:10
144	Winter.Translate	comment	1.2.3	Fixes Rich Editor when inserting a page link.	2025-04-03 07:43:10
145	Winter.Translate	script	1.2.4	v1.2.4/create_indexes_table.php	2025-04-03 07:43:10
146	Winter.Translate	comment	1.2.4	Translatable attributes can now be declared as indexes.	2025-04-03 07:43:10
147	Winter.Translate	comment	1.2.5	Adds new multilingual repeater form widget.	2025-04-03 07:43:10
148	Winter.Translate	comment	1.2.6	Fixes repeater usage with static pages plugin.	2025-04-03 07:43:10
149	Winter.Translate	comment	1.2.7	Fixes placeholder usage with static pages plugin.	2025-04-03 07:43:10
150	Winter.Translate	comment	1.2.8	Improvements to code for latest Winter CMS build compatibility.	2025-04-03 07:43:10
151	Winter.Translate	comment	1.2.9	Fixes context for translated strings when used with Static Pages.	2025-04-03 07:43:10
152	Winter.Translate	comment	1.2.10	Minor UI fix to the multilingual repeater.	2025-04-03 07:43:10
153	Winter.Translate	comment	1.2.11	Fixes translation not working with partials loaded via AJAX.	2025-04-03 07:43:10
154	Winter.Translate	comment	1.2.12	Add support for translating the new grouped repeater feature.	2025-04-03 07:43:10
155	Winter.Translate	comment	1.3.0	Added search to the translate messages page.	2025-04-03 07:43:10
156	Winter.Translate	script	1.3.1	v1.3.1/add_sort_order.php	2025-04-03 07:43:10
157	Winter.Translate	script	1.3.1	v1.3.1/seed_all_tables.php	2025-04-03 07:43:10
158	Winter.Translate	comment	1.3.1	Added reordering to languages	2025-04-03 07:43:10
159	Winter.Translate	comment	1.3.2	Improved compatibility with Winter.Pages, added ability to scan Mail Messages for translatable variables.	2025-04-03 07:43:10
160	Winter.Translate	comment	1.3.3	Fix to the locale picker session handling in Build 420 onwards.	2025-04-03 07:43:10
161	Winter.Translate	comment	1.3.4	Add alternate hreflang elements and adds prefixDefaultLocale setting.	2025-04-03 07:43:10
162	Winter.Translate	comment	1.3.5	Fix MLRepeater bug when switching locales.	2025-04-03 07:43:10
163	Winter.Translate	comment	1.3.6	Fix Middleware to use the prefixDefaultLocale setting introduced in 1.3.4	2025-04-03 07:43:10
164	Winter.Translate	comment	1.3.7	Fix config reference in LocaleMiddleware	2025-04-03 07:43:10
165	Winter.Translate	comment	1.3.8	Keep query string when switching locales	2025-04-03 07:43:10
166	Winter.Translate	comment	1.4.0	Add importer and exporter for messages	2025-04-03 07:43:10
167	Winter.Translate	comment	1.4.1	Updated Hungarian translation. Added Arabic translation. Fixed issue where default texts are overwritten by import. Fixed issue where the language switcher for repeater fields would overlap with the first repeater row.	2025-04-03 07:43:10
168	Winter.Translate	comment	1.4.2	Add multilingual MediaFinder	2025-04-03 07:43:10
169	Winter.Translate	comment	1.4.3	!!! Please update Winter CMS to Build 444 before updating this plugin. Added ability to translate CMS Pages fields (e.g. title, description, meta-title, meta-description)	2025-04-03 07:43:11
170	Winter.Translate	comment	1.4.4	Minor improvements to compatibility with Laravel framework.	2025-04-03 07:43:11
171	Winter.Translate	comment	1.4.5	Fixed issue when using the language switcher	2025-04-03 07:43:11
172	Winter.Translate	comment	1.5.0	Compatibility fix with Build 451	2025-04-03 07:43:11
173	Winter.Translate	comment	1.6.0	Make File Upload widget properties translatable. Merge Repeater core changes into MLRepeater widget. Add getter method to retrieve original translate data.	2025-04-03 07:43:11
174	Winter.Translate	comment	1.6.1	Add ability for models to provide translated computed data, add option to disable locale prefix routing	2025-04-03 07:43:11
175	Winter.Translate	comment	1.6.2	Implement localeUrl filter, add per-locale theme configuration support	2025-04-03 07:43:11
176	Winter.Translate	comment	1.6.3	Add eager loading for translations, restore support for accessors & mutators	2025-04-03 07:43:11
177	Winter.Translate	comment	1.6.4	Fixes PHP 7.4 compatibility	2025-04-03 07:43:11
178	Winter.Translate	comment	1.6.5	Fixes compatibility issue when other plugins use a custom model morph map	2025-04-03 07:43:11
179	Winter.Translate	script	1.6.6	v1.6.6/migrate_morphed_attributes.php	2025-04-03 07:43:11
180	Winter.Translate	comment	1.6.6	Introduce migration to patch existing translations using morph map	2025-04-03 07:43:11
181	Winter.Translate	script	1.6.7	v1.6.7/migrate_morphed_indexes.php	2025-04-03 07:43:11
182	Winter.Translate	comment	1.6.7	Introduce migration to patch existing indexes using morph map	2025-04-03 07:43:11
183	Winter.Translate	comment	1.6.8	Add support for transOrderBy; Add translation support for ThemeData; Update russian localization.	2025-04-03 07:43:11
184	Winter.Translate	comment	1.6.9	Clear Static Page menu cache after saving the model; CSS fix for Text/Textarea input fields language selector.	2025-04-03 07:43:11
185	Winter.Translate	script	1.6.10	v1.6.10/update_messages_table.php	2025-04-03 07:43:11
186	Winter.Translate	comment	1.6.10	Add option to purge deleted messages when scanning messages	2025-04-03 07:43:11
187	Winter.Translate	comment	1.6.10	Add Scan error column on Messages page	2025-04-03 07:43:11
188	Winter.Translate	comment	1.6.10	Fix translations that were lost when clicking locale twice while holding ctrl key	2025-04-03 07:43:11
189	Winter.Translate	comment	1.6.10	Fix error with nested fields default locale value	2025-04-03 07:43:11
190	Winter.Translate	comment	1.6.10	Escape Message translate params value	2025-04-03 07:43:11
191	Winter.Translate	comment	1.7.0	!!! Breaking change for the Message::trans() method (params are now escaped)	2025-04-03 07:43:11
192	Winter.Translate	comment	1.7.0	fix message translation documentation	2025-04-03 07:43:11
193	Winter.Translate	comment	1.7.0	fix string translation key for scan errors column header	2025-04-03 07:43:11
194	Winter.Translate	comment	1.7.1	Fix YAML issue with previous tag/release.	2025-04-03 07:43:11
195	Winter.Translate	comment	1.7.2	Fix regex when "|_" filter is followed by another filter	2025-04-03 07:43:11
196	Winter.Translate	comment	1.7.2	Try locale without country before returning default translation	2025-04-03 07:43:11
197	Winter.Translate	comment	1.7.2	Allow exporting default locale	2025-04-03 07:43:11
198	Winter.Translate	comment	1.7.2	Fire 'winter.translate.themeScanner.afterScan' event in the theme scanner for extendability	2025-04-03 07:43:11
199	Winter.Translate	comment	1.7.3	Make plugin ready for Laravel 6 update	2025-04-03 07:43:11
200	Winter.Translate	comment	1.7.3	Add support for translating Winter.Pages MenuItem properties (requires Winter.Pages v1.3.6)	2025-04-03 07:43:11
201	Winter.Translate	comment	1.7.3	Restore multilingual button position for textarea	2025-04-03 07:43:11
202	Winter.Translate	comment	1.7.3	Fix translatableAttributes	2025-04-03 07:43:11
203	Winter.Translate	comment	1.7.4	Faster version of transWhere	2025-04-03 07:43:11
204	Winter.Translate	comment	1.7.4	Mail templates/views can now be localized	2025-04-03 07:43:11
205	Winter.Translate	comment	1.7.4	Fix messages table layout on mobile	2025-04-03 07:43:11
206	Winter.Translate	comment	1.7.4	Fix scopeTransOrderBy duplicates	2025-04-03 07:43:11
207	Winter.Translate	comment	1.7.4	Polish localization updates	2025-04-03 07:43:11
208	Winter.Translate	comment	1.7.4	Turkish localization updates	2025-04-03 07:43:11
209	Winter.Translate	comment	1.7.4	Add Greek language localization	2025-04-03 07:43:11
210	Winter.Translate	comment	1.8.0	Adds initial support for October v2.0	2025-04-03 07:43:11
211	Winter.Translate	comment	1.8.1	Minor bugfix	2025-04-03 07:43:11
212	Winter.Translate	comment	1.8.2	Fixes translated file models and theme data for v2.0. The parent model must implement translatable behavior for their related file models to be translated.	2025-04-03 07:43:11
213	Winter.Translate	script	2.0.0	v2.0.0/rename_tables.php	2025-04-03 07:43:11
214	Winter.Translate	comment	2.0.0	Rebrand to Winter.Translate	2025-04-03 07:43:11
215	Winter.Translate	comment	2.0.0	Fix location for dropdown-to in css file	2025-04-03 07:43:11
216	Winter.Translate	script	2.0.1	v2.0.1/rename_indexes.php	2025-04-03 07:43:12
217	Winter.Translate	comment	2.0.1	Rebrand table indexes	2025-04-03 07:43:12
218	Winter.Translate	comment	2.0.1	Remove deprecated methods (setTranslateAttribute/getTranslateAttribute)	2025-04-03 07:43:12
219	Winter.Translate	comment	2.0.2	Added Latvian translation. Fixed plugin replacement issues.	2025-04-03 07:43:12
220	Winter.Translate	script	2.1.0	v2.1.0/migrate_message_code.php	2025-04-03 07:43:13
221	Winter.Translate	comment	2.1.0	!!! Potential breaking change: Message codes are now MD5 hashed versions of the original string. See https://github.com/wintercms/wn-translate-plugin/pull/2	2025-04-03 07:43:13
222	Winter.Translate	comment	2.1.1	Added support for Winter CMS 1.2.	2025-04-03 07:43:13
223	Winter.Translate	comment	2.1.2	Add Vietnamese translations	2025-04-03 07:43:13
224	Winter.Translate	comment	2.1.2	Add composer replace config.	2025-04-03 07:43:13
225	Winter.Translate	comment	2.1.2	Add MultiLang capability to Winter.Sitemap.	2025-04-03 07:43:13
226	Winter.Translate	comment	2.1.2	Add addTranslatableAttributes() method to TranslatableBehavior.	2025-04-03 07:43:13
227	Winter.Translate	comment	2.1.2	Fix dynamically adding fields to non-existent tab.	2025-04-03 07:43:13
228	Winter.Translate	comment	2.1.2	Fix translations conflicting between nested fields and translatable root fields of the same name.	2025-04-03 07:43:13
229	Winter.Translate	comment	2.1.3	Fixed issue with translatable models	2025-04-03 07:43:13
230	Winter.Translate	comment	2.1.4	Fixed issue with broken imports in the backend Locales controller.	2025-04-03 07:43:13
231	Winter.Translate	comment	2.1.5	Add support for translatable nested forms	2025-04-03 07:43:13
232	Winter.Translate	comment	2.1.5	Add validation for translated string	2025-04-03 07:43:13
233	Winter.Translate	comment	2.1.5	Add setTranslatableUseFallback() / deprecate noFallbackLocale()	2025-04-03 07:43:13
234	Winter.Translate	comment	2.1.5	Only extend cms page if cms module is enabled	2025-04-03 07:43:13
235	Winter.Translate	comment	2.1.5	Prevent browser autofill for hidden locale inputs	2025-04-03 07:43:13
236	Winter.Translate	comment	2.1.5	System MailTemplate model is now translatable	2025-04-03 07:43:13
237	Winter.Translate	comment	2.1.5	Make fields using @context translatable	2025-04-03 07:43:13
238	Winter.Translate	comment	2.1.6	Improve ML button styling	2025-04-03 07:43:13
239	Winter.Translate	comment	2.1.6	Fix TranslatableBehavior::lang method signature	2025-04-03 07:43:13
240	Winter.Translate	comment	2.1.7	Only set alternateLinks if more than one locale is used	2025-04-03 07:43:13
241	Winter.Translate	comment	2.1.7	Cleanup after model is deleted	2025-04-03 07:43:13
242	Winter.Translate	comment	2.1.7	Add missing french translations	2025-04-03 07:43:13
243	Winter.Translate	comment	2.2.0	Fix translating pages on Winter v1.2.7+	2025-04-03 07:43:13
244	Acorn.BackendLocalization	script	1.0.0	v1.1/seed_locale_backend.php	2025-04-03 07:43:13
245	Acorn.BackendLocalization	comment	1.0.0	Create special languages ​​for the backend 	2025-04-03 07:43:13
246	Acorn.Location	script	4.0.0	create_from_sql.php	2025-04-03 07:43:13
247	Acorn.Location	comment	4.0.0	Create from DB & seeder.sql	2025-04-03 07:43:13
248	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message.php	2025-04-03 07:43:13
249	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message_user.php	2025-04-03 07:43:13
250	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message_user_group.php	2025-04-03 07:43:13
251	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_message_message.php	2025-04-03 07:43:13
252	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_action.php	2025-04-03 07:43:14
253	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_label.php	2025-04-03 07:43:14
254	Acorn.Messaging	script	1.0.1	builder_table_create_acorn_messaging_status.php	2025-04-03 07:43:14
255	Acorn.Messaging	script	1.0.1	seed_status.php	2025-04-03 07:43:14
256	Acorn.Messaging	comment	1.0.1	Initialize plugin.	2025-04-03 07:43:14
257	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message	2025-04-03 07:43:14
258	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message_user	2025-04-03 07:43:14
259	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message_user_group	2025-04-03 07:43:14
260	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_message_message	2025-04-03 07:43:14
261	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_action	2025-04-03 07:43:14
262	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_label	2025-04-03 07:43:14
263	Acorn.Messaging	comment	1.0.1	Created table acorn_messaging_status	2025-04-03 07:43:14
264	Acorn.Messaging	comment	1.0.1	Seeding message status	2025-04-03 07:43:14
265	Acorn.Messaging	script	2.0.0	create_acorn_users_extra_fields.php	2025-04-03 07:43:14
266	Acorn.Messaging	comment	2.0.0	Create acorn users extra fields	2025-04-03 07:43:14
267	Acorn.Reporting	script	1.0.1	builder_table_create_acorn_reporting_reports.php	2025-04-03 07:43:14
268	Acorn.Reporting	comment	1.0.1	Initialize plugin.	2025-04-03 07:43:14
269	Acorn.Reporting	comment	1.0.1	Created table acorn_reporting_reports	2025-04-03 07:43:14
270	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_calendars.php	2025-04-03 07:43:14
271	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_types.php	2025-04-03 07:43:14
272	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_statuses.php	2025-04-03 07:43:14
273	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_events.php	2025-04-03 07:43:14
274	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_parts.php	2025-04-03 07:43:15
275	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_instances.php	2025-04-03 07:43:15
276	Acorn.Calendar	script	2.0.1	create_acorn_calendar_event_trigger.php	2025-04-03 07:43:15
277	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_part_user.php	2025-04-03 07:43:15
278	Acorn.Calendar	script	2.0.1	builder_table_create_acorn_calendar_event_part_user_group.php	2025-04-03 07:43:15
279	Acorn.Calendar	script	2.0.1	table_create_acorn_messaging_instance.php	2025-04-03 07:43:15
280	Acorn.Calendar	script	2.0.1	create_acorn_users_extra_fields.php	2025-04-03 07:43:15
281	Acorn.Calendar	script	2.0.1	create_functions.php	2025-04-03 07:43:15
282	Acorn.Calendar	script	2.0.1	seed_calendar.php	2025-04-03 07:43:15
283	Acorn.Calendar	comment	2.0.1	Initialize plugin.	2025-04-03 07:43:15
284	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_calendars	2025-04-03 07:43:15
285	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_types	2025-04-03 07:43:15
286	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_statuses	2025-04-03 07:43:15
287	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_events	2025-04-03 07:43:15
288	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_parts	2025-04-03 07:43:15
289	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_instances	2025-04-03 07:43:15
290	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_trigger	2025-04-03 07:43:15
291	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_part_user	2025-04-03 07:43:15
292	Acorn.Calendar	comment	2.0.1	Created table acorn_calendar_event_part_user_group	2025-04-03 07:43:15
293	Acorn.Calendar	comment	2.0.1	Created table acorn_messaging_message_instance	2025-04-03 07:43:15
294	Acorn.Calendar	comment	2.0.1	Create acorn users extra fields	2025-04-03 07:43:15
295	Acorn.Calendar	comment	2.0.1	Create functions, including fn_acorn_calendar_seed()	2025-04-03 07:43:15
296	Acorn.Calendar	comment	2.0.1	Seeding default Calendar, Types and Statuses	2025-04-03 07:43:15
297	Winter.Debugbar	comment	1.0.1	First version of Debugbar	2025-04-23 11:38:27
298	Winter.Debugbar	comment	1.0.2	Debugbar facade aliased (Alxy)	2025-04-23 11:38:27
299	Winter.Debugbar	comment	1.0.3	Added ajax debugging	2025-04-23 11:38:27
300	Winter.Debugbar	comment	1.0.4	Only display to backend authenticated users	2025-04-23 11:38:27
301	Winter.Debugbar	comment	1.0.5	Use elevated privileges	2025-04-23 11:38:27
302	Winter.Debugbar	comment	1.0.6	Fix fatal error when cms.page.beforeDisplay is fired multiple times (mnishihan)	2025-04-23 11:38:27
303	Winter.Debugbar	comment	1.0.7	Allow plugin to be installed via Composer (tim0991)	2025-04-23 11:38:27
304	Winter.Debugbar	comment	1.0.8	Fix debugbar dependency	2025-04-23 11:38:27
305	Winter.Debugbar	comment	2.0.0	!!! Upgrade for compatibility with Laravel 5.5 (PHP 7+, October 420+)	2025-04-23 11:38:27
306	Winter.Debugbar	comment	2.0.1	Add config file to prevent exceptions from being thrown (credit alxy)	2025-04-23 11:38:27
307	Winter.Debugbar	comment	3.0.0	Switched vendor to RainLab from Bedard, upgraded for compatibility with Laravel 6.x	2025-04-23 11:38:27
308	Winter.Debugbar	comment	3.0.1	Fixed bug that caused 502 errors on AJAX requests	2025-04-23 11:38:27
309	Winter.Debugbar	comment	3.1.0	Important security update and improved styling.	2025-04-23 11:38:27
310	Winter.Debugbar	comment	3.1.1	Added new "store all requests" config option. Added Slovenian translations.	2025-04-23 11:38:27
311	Winter.Debugbar	comment	4.0.0	Switched vendor to Winter from RainLab	2025-04-23 11:38:27
312	Winter.Debugbar	comment	4.0.1	Added Russian translation, added support for Twig v3 / Winter v1.2 / Laravel 9	2025-04-23 11:38:27
313	Winter.Debugbar	comment	4.0.2	Adds new collectors for Twig, CMS and Backend. Updated styling to match Winter branding	2025-04-23 11:38:27
314	Winter.Debugbar	comment	4.0.3	Improved compatibility with latest version of dependencies	2025-04-23 11:38:27
315	Winter.Debugbar	comment	4.0.4	Align styling with barryvdh/laravel-debugbar v3.15.x dependency	2025-04-23 11:38:27
316	Winter.Debugbar	comment	4.0.5	Styling / branding improvements	2025-04-23 11:38:27
\.


--
-- Data for Name: system_plugin_versions; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_plugin_versions (id, code, version, created_at, is_disabled, is_frozen, acorn_infrastructure) FROM stdin;
1	Winter.Demo	1.0.1	2025-04-03 07:39:25	f	f	f
11	Acorn.University	1.0.0	2025-04-03 12:27:46	f	f	f
12	Acorn.Exam	1.0.0	2025-04-08 18:24:18	f	f	f
2	Acorn.User	3.0.2	2025-04-03 07:42:59	f	f	f
6	Acorn.BackendLocalization	1.0.0	2025-04-03 07:43:13	f	f	f
7	Acorn.Location	4.0.0	2025-04-03 07:43:13	f	f	f
8	Acorn.Messaging	2.0.0	2025-04-03 07:43:14	f	f	f
9	Acorn.Reporting	1.0.1	2025-04-03 07:43:14	f	f	f
10	Acorn.Calendar	2.0.1	2025-04-03 07:43:15	f	f	f
3	Winter.Location	2.0.2	2025-04-03 07:43:09	f	f	f
4	Winter.TailwindUI	1.0.1	2025-04-03 07:43:09	f	f	f
5	Winter.Translate	2.1.6	2025-04-23 11:38:27	f	f	f
13	Winter.Debugbar	4.0.5	2025-04-23 11:38:27	f	f	f
\.


--
-- Data for Name: system_request_logs; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_request_logs (id, status_code, url, referer, count, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_revisions; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_revisions (id, user_id, field, "cast", old_value, new_value, revisionable_type, revisionable_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.system_settings (id, item, value) FROM stdin;
\.


--
-- Data for Name: winter_location_countries; Type: TABLE DATA; Schema: public; Owner: university
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
-- Data for Name: winter_location_states; Type: TABLE DATA; Schema: public; Owner: university
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
-- Data for Name: winter_translate_attributes; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.winter_translate_attributes (id, locale, model_id, model_type, attribute_data) FROM stdin;
1	ar	9e95fdfa-b625-41d9-8f01-15d71f6b7552	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
2	ku	9e95fdfa-b625-41d9-8f01-15d71f6b7552	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
3	ar	9e95fe34-4596-4431-865c-a5a8d2a638c4	Acorn\\Location\\Models\\Location	{"name":""}
4	ku	9e95fe34-4596-4431-865c-a5a8d2a638c4	Acorn\\Location\\Models\\Location	{"name":""}
7	ar	9ea0cebf-6a5c-4ab8-9912-a387123f1c02	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
8	ku	9ea0cebf-6a5c-4ab8-9912-a387123f1c02	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
9	ar	9ea1ed07-6885-4b3f-b37c-1482c1a21624	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
10	ku	9ea1ed07-6885-4b3f-b37c-1482c1a21624	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
11	ar	9ea47ad3-7e86-4dde-8cd4-b63f1990ca35	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
12	ku	9ea47ad3-7e86-4dde-8cd4-b63f1990ca35	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
13	ar	c6bb2023-22d1-4f10-8767-89e159b618a6	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
14	ku	c6bb2023-22d1-4f10-8767-89e159b618a6	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
15	ar	076c0630-99cc-4324-9f67-c1c202a19b58	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
16	ku	076c0630-99cc-4324-9f67-c1c202a19b58	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
17	ar	996bf95c-e86b-4653-8d1d-440923f12cfd	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
18	ku	996bf95c-e86b-4653-8d1d-440923f12cfd	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
19	ar	a582b1ba-5d71-42d2-b776-46de370b3575	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
20	ku	a582b1ba-5d71-42d2-b776-46de370b3575	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
21	ar	9ea60a63-4050-466c-9947-d6a335a2f7bf	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
22	ku	9ea60a63-4050-466c-9947-d6a335a2f7bf	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
23	ar	9ea60bc4-324d-4091-baf9-6666d6183078	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
24	ku	9ea60bc4-324d-4091-baf9-6666d6183078	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
25	ar	9ea60dbe-8014-467f-ae96-b6083f2325c0	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
26	ku	9ea60dbe-8014-467f-ae96-b6083f2325c0	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
27	ar	9ea60dd4-96f6-457c-a10b-19d4ed657d40	Acorn\\Exam\\Models\\Material	{"name":"","description":""}
28	ku	9ea60dd4-96f6-457c-a10b-19d4ed657d40	Acorn\\Exam\\Models\\Material	{"name":"","description":""}
29	ar	9ea63f4c-7743-4a49-9963-856f0e1e4e9d	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
30	ku	9ea63f4c-7743-4a49-9963-856f0e1e4e9d	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
31	ar	9ea6417c-516e-4a0e-9637-924101c5b9b1	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
32	ku	9ea6417c-516e-4a0e-9637-924101c5b9b1	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
33	ar	9ea68ea6-ed7b-42c2-bc30-37c10be1c285	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
34	ku	9ea68ea6-ed7b-42c2-bc30-37c10be1c285	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
35	ar	9ea6ec5b-91fc-4629-bfa4-d218886b6c22	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
36	ku	9ea6ec5b-91fc-4629-bfa4-d218886b6c22	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
37	ar	9ea84304-5bc0-41a4-aa63-6269ed01a9bf	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
38	ku	9ea84304-5bc0-41a4-aa63-6269ed01a9bf	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
39	ar	9ea8435c-603a-4e8e-a422-b074ad26b59c	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
40	ku	9ea8435c-603a-4e8e-a422-b074ad26b59c	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
41	ar	9ea85983-2cd8-4e46-8aa6-d3691f2d9a84	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
42	ku	9ea85983-2cd8-4e46-8aa6-d3691f2d9a84	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
43	ar	d21483ec-5840-4894-9dbc-40125ed96835	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
44	ku	d21483ec-5840-4894-9dbc-40125ed96835	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
45	ar	9ea85e96-a848-4004-a4a8-48cb18f7f6ec	Acorn\\Exam\\Models\\Material	{"name":"","description":""}
46	ku	9ea85e96-a848-4004-a4a8-48cb18f7f6ec	Acorn\\Exam\\Models\\Material	{"name":"","description":""}
47	ar	9ea85f4e-0909-4534-975b-067544d30e86	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
48	ku	9ea85f4e-0909-4534-975b-067544d30e86	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
49	ar	9ea85f73-cca5-4aca-9d7e-55f9f5ab1409	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
50	ku	9ea85f73-cca5-4aca-9d7e-55f9f5ab1409	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
51	ar	9eaaacf0-a713-4b6b-9a72-4570887c83fe	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
52	ku	9eaaacf0-a713-4b6b-9a72-4570887c83fe	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
53	ar	9eac0755-4691-4f86-acab-8e1e10649245	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
54	ku	9eac0755-4691-4f86-acab-8e1e10649245	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
55	ar	5efa30cd-a16f-4d94-b8ec-604b4625b516	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
56	ku	5efa30cd-a16f-4d94-b8ec-604b4625b516	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
57	ar	a7d5143d-7e99-4d2b-92c9-86e7429adfa7	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
58	ku	a7d5143d-7e99-4d2b-92c9-86e7429adfa7	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
59	ar	9eac27c4-7d21-4424-b54c-80e036f939cd	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
60	ku	9eac27c4-7d21-4424-b54c-80e036f939cd	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
61	ar	f5b2f310-2118-4a93-b7b9-2ae9c7d7925a	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
62	ku	f5b2f310-2118-4a93-b7b9-2ae9c7d7925a	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
63	ar	9eb2644c-d933-45f7-8d7b-53305a08d026	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
64	ku	9eb2644c-d933-45f7-8d7b-53305a08d026	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
65	ar	cae7ba7c-1b63-11f0-8a05-c36be60d3d46	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
66	ku	cae7ba7c-1b63-11f0-8a05-c36be60d3d46	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
75	ar	f334763c-1b63-11f0-aab4-4f7e5f7e30cb	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
76	ku	f334763c-1b63-11f0-aab4-4f7e5f7e30cb	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
77	ar	9ec2de06-399d-4bc4-8cb0-e641a39aef1d	Acorn\\User\\Models\\UserGroupType	{"name":""}
78	ku	9ec2de06-399d-4bc4-8cb0-e641a39aef1d	Acorn\\User\\Models\\UserGroupType	{"name":""}
79	ar	9ec87e7c-cb27-4774-a024-6f4df6b3c61e	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
80	ku	9ec87e7c-cb27-4774-a024-6f4df6b3c61e	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
82	ku	69e907ec-edce-4e2a-ba01-31628baf447d	Acorn\\Exam\\Models\\Interview	{"name":"","description":""}
81	ar	69e907ec-edce-4e2a-ba01-31628baf447d	Acorn\\Exam\\Models\\Interview	{"name":"Arab","description":""}
83	ar	9ecef4a3-734e-4193-9e2e-f2b04c46349b	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
84	ku	9ecef4a3-734e-4193-9e2e-f2b04c46349b	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
85	ar	9ed44ac1-8455-45b2-a2f3-1164622ec5a1	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
86	ku	9ed44ac1-8455-45b2-a2f3-1164622ec5a1	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
87	ar	68a980b0-012b-4703-9bf4-938548b64a1a	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
88	ku	68a980b0-012b-4703-9bf4-938548b64a1a	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
89	ar	37a9ae02-76c1-4396-b2a3-c2fc5357caef	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
90	ku	37a9ae02-76c1-4396-b2a3-c2fc5357caef	Acorn\\Exam\\Models\\Type	{"name":"","description":""}
91	ar	9ed8b261-9ba8-4cb7-9008-7e77068afd1b	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
92	ku	9ed8b261-9ba8-4cb7-9008-7e77068afd1b	Acorn\\Exam\\Models\\Exam	{"name":"","description":""}
93	ar	9eda63ea-1b4f-4e2e-bb54-3dcb69d08f1e	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
94	ku	9eda63ea-1b4f-4e2e-bb54-3dcb69d08f1e	Acorn\\User\\Models\\UserGroup	{"name":"","description":""}
95	ar	9edac54f-2fb0-413d-83a2-7fa7ca5e7423	Acorn\\University\\Models\\Semester	{"name":"","description":""}
96	ku	9edac54f-2fb0-413d-83a2-7fa7ca5e7423	Acorn\\University\\Models\\Semester	{"name":"","description":""}
97	ar	9edac55d-ff15-4982-915c-2835df07cb12	Acorn\\University\\Models\\Semester	{"name":"","description":""}
98	ku	9edac55d-ff15-4982-915c-2835df07cb12	Acorn\\University\\Models\\Semester	{"name":"","description":""}
99	ar	9edac56c-d36b-4495-a2c2-2d96e75de113	Acorn\\University\\Models\\Semester	{"name":"","description":""}
100	ku	9edac56c-d36b-4495-a2c2-2d96e75de113	Acorn\\University\\Models\\Semester	{"name":"","description":""}
101	ar	9edac808-adee-45fe-a394-6a769b772b83	Acorn\\University\\Models\\AcademicYear	{"name":"","description":""}
102	ku	9edac808-adee-45fe-a394-6a769b772b83	Acorn\\University\\Models\\AcademicYear	{"name":"","description":""}
103	ar	9edac813-5423-417c-8b8b-020606b35a76	Acorn\\University\\Models\\AcademicYear	{"name":"","description":""}
104	ku	9edac813-5423-417c-8b8b-020606b35a76	Acorn\\University\\Models\\AcademicYear	{"name":"","description":""}
105	ar	9edacc87-72c5-4a18-aa3d-5bd94fd64909	Acorn\\University\\Models\\Project	{"name":"","description":""}
106	ku	9edacc87-72c5-4a18-aa3d-5bd94fd64909	Acorn\\University\\Models\\Project	{"name":"","description":""}
107	ar	9edc994f-ecc0-485d-9f7a-0e36a186dbc5	Acorn\\University\\Models\\Project	{"name":"","description":""}
108	ku	9edc994f-ecc0-485d-9f7a-0e36a186dbc5	Acorn\\University\\Models\\Project	{"name":"","description":""}
109	ar	9edc9b31-1b8a-49a2-9b4e-41d732015290	Acorn\\University\\Models\\ProjectStudent	{"name":"","description":""}
110	ku	9edc9b31-1b8a-49a2-9b4e-41d732015290	Acorn\\University\\Models\\ProjectStudent	{"name":"","description":""}
111	ar	9ede9377-9aa9-4b3f-9d61-3b5de579ae9e	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
112	ku	9ede9377-9aa9-4b3f-9d61-3b5de579ae9e	Acorn\\Exam\\Models\\Calculation	{"name":"","description":""}
113	ar	6b4bae9a-149f-11f0-a4e5-779d31ace22e	Acorn\\University\\Models\\MaterialType	{"name":"","description":""}
114	ku	6b4bae9a-149f-11f0-a4e5-779d31ace22e	Acorn\\University\\Models\\MaterialType	{"name":"","description":""}
\.


--
-- Data for Name: winter_translate_indexes; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.winter_translate_indexes (id, locale, model_id, model_type, item, value) FROM stdin;
\.


--
-- Data for Name: winter_translate_locales; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.winter_translate_locales (id, code, name, is_default, is_enabled, sort_order) FROM stdin;
1	en	English	t	t	1
2	ar	Arabic	f	t	2
3	ku	Kurdish	f	t	3
\.


--
-- Data for Name: winter_translate_messages; Type: TABLE DATA; Schema: public; Owner: university
--

COPY public.winter_translate_messages (id, code, message_data, found, code_pre_2_1_0) FROM stdin;
\.


--
-- Name: acorn_reporting_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.acorn_reporting_reports_id_seq', 1, false);


--
-- Name: backend_access_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_access_log_id_seq', 7, true);


--
-- Name: backend_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_user_groups_id_seq', 1, true);


--
-- Name: backend_user_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_user_preferences_id_seq', 12, true);


--
-- Name: backend_user_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_user_roles_id_seq', 2, true);


--
-- Name: backend_user_throttle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_user_throttle_id_seq', 3, true);


--
-- Name: backend_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.backend_users_id_seq', 6, true);


--
-- Name: cms_theme_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.cms_theme_data_id_seq', 1, false);


--
-- Name: cms_theme_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.cms_theme_logs_id_seq', 1, false);


--
-- Name: cms_theme_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.cms_theme_templates_id_seq', 1, false);


--
-- Name: deferred_bindings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.deferred_bindings_id_seq', 5, true);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.migrations_id_seq', 51, true);


--
-- Name: rainlab_location_countries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_location_countries_id_seq', 248, true);


--
-- Name: rainlab_location_states_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_location_states_id_seq', 720, true);


--
-- Name: rainlab_translate_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_translate_attributes_id_seq', 114, true);


--
-- Name: rainlab_translate_indexes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_translate_indexes_id_seq', 1, false);


--
-- Name: rainlab_translate_locales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_translate_locales_id_seq', 3, true);


--
-- Name: rainlab_translate_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.rainlab_translate_messages_id_seq', 1, false);


--
-- Name: system_event_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_event_logs_id_seq', 696, true);


--
-- Name: system_files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_files_id_seq', 1, true);


--
-- Name: system_mail_layouts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_mail_layouts_id_seq', 2, true);


--
-- Name: system_mail_partials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_mail_partials_id_seq', 1, false);


--
-- Name: system_mail_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_mail_templates_id_seq', 1, false);


--
-- Name: system_parameters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_parameters_id_seq', 5, true);


--
-- Name: system_plugin_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_plugin_history_id_seq', 316, true);


--
-- Name: system_plugin_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_plugin_versions_id_seq', 13, true);


--
-- Name: system_request_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_request_logs_id_seq', 1, false);


--
-- Name: system_revisions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_revisions_id_seq', 1, false);


--
-- Name: system_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: university
--

SELECT pg_catalog.setval('public.system_settings_id_seq', 1, false);


--
-- Name: acorn_calendar_calendars acorn_calendar_calendars_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_calendars
    ADD CONSTRAINT acorn_calendar_calendars_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_event_part_user_group acorn_calendar_event_part_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user_group
    ADD CONSTRAINT acorn_calendar_event_part_user_group_pkey PRIMARY KEY (event_part_id, user_group_id);


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_part_user_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_part_user_pkey PRIMARY KEY (event_part_id, user_id, role_id);


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_event_statuses acorn_calendar_event_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_statuses
    ADD CONSTRAINT acorn_calendar_event_statuses_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_event_types acorn_calendar_event_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_types
    ADD CONSTRAINT acorn_calendar_event_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_events acorn_calendar_events_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_events_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_instances acorn_calendar_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_instances
    ADD CONSTRAINT acorn_calendar_instances_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_calculations acorn_exam_calculations_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT acorn_exam_calculations_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_exam_materials acorn_exam_exam_material_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT acorn_exam_exam_material_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_exams acorn_exam_exams_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT acorn_exam_exams_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_interview_students acorn_exam_interview_student_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT acorn_exam_interview_student_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_interviews acorn_exam_interviews_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT acorn_exam_interviews_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_material_types acorn_exam_material_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT acorn_exam_material_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_materials acorn_exam_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT acorn_exam_materials_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_scores acorn_exam_results_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT acorn_exam_results_pkey PRIMARY KEY (id);


--
-- Name: acorn_exam_types acorn_exam_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT acorn_exam_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_lookup acorn_location_location_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_lookup
    ADD CONSTRAINT acorn_location_location_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_label acorn_messaging_label_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_label
    ADD CONSTRAINT acorn_messaging_label_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_message acorn_messaging_message_externalid_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message
    ADD CONSTRAINT acorn_messaging_message_externalid_unique UNIQUE ("externalID");


--
-- Name: acorn_messaging_message_instance acorn_messaging_message_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_instance
    ADD CONSTRAINT acorn_messaging_message_instance_pkey PRIMARY KEY (message_id, instance_id);


--
-- Name: acorn_messaging_message_message acorn_messaging_message_message_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_message
    ADD CONSTRAINT acorn_messaging_message_message_pkey PRIMARY KEY (message1_id, message2_id, relationship);


--
-- Name: acorn_messaging_message acorn_messaging_message_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message
    ADD CONSTRAINT acorn_messaging_message_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_message_user_group acorn_messaging_message_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user_group
    ADD CONSTRAINT acorn_messaging_message_user_group_pkey PRIMARY KEY (message_id, user_group_id);


--
-- Name: acorn_messaging_message_user acorn_messaging_message_user_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user
    ADD CONSTRAINT acorn_messaging_message_user_pkey PRIMARY KEY (message_id, user_id);


--
-- Name: acorn_messaging_status acorn_messaging_status_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_status
    ADD CONSTRAINT acorn_messaging_status_pkey PRIMARY KEY (id);


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_pkey PRIMARY KEY (message_id, status_id);


--
-- Name: acorn_reporting_reports acorn_reporting_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_reporting_reports
    ADD CONSTRAINT acorn_reporting_reports_pkey PRIMARY KEY (id);


--
-- Name: acorn_servers acorn_servers_hostname_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_servers
    ADD CONSTRAINT acorn_servers_hostname_unique UNIQUE (hostname);


--
-- Name: acorn_servers acorn_servers_id_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_servers
    ADD CONSTRAINT acorn_servers_id_unique UNIQUE (id);


--
-- Name: acorn_university_academic_years acorn_university_academic_years_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT acorn_university_academic_years_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_course_language acorn_university_course_language_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_language
    ADD CONSTRAINT acorn_university_course_language_pkey PRIMARY KEY (course_id, language_id);


--
-- Name: acorn_university_course_materials acorn_university_course_material_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT acorn_university_course_material_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_courses acorn_university_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_courses
    ADD CONSTRAINT acorn_university_courses_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_departments acorn_university_departments_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_departments
    ADD CONSTRAINT acorn_university_departments_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_education_authorities acorn_university_education_authorities_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_education_authorities
    ADD CONSTRAINT acorn_university_education_authorities_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_entities acorn_university_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT acorn_university_entities_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_faculties acorn_university_faculties_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_faculties
    ADD CONSTRAINT acorn_university_faculties_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_hierarchies acorn_university_hierarchies_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT acorn_university_hierarchies_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_project_students acorn_university_project_students_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT acorn_university_project_students_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_projects acorn_university_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT acorn_university_projects_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_schools acorn_university_schools_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_schools
    ADD CONSTRAINT acorn_university_schools_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_semester_years acorn_university_semester_year_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semester_years
    ADD CONSTRAINT acorn_university_semester_year_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_semesters acorn_university_semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT acorn_university_semesters_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_students acorn_university_students_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_students
    ADD CONSTRAINT acorn_university_students_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_teachers acorn_university_teachers_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_teachers
    ADD CONSTRAINT acorn_university_teachers_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_universities acorn_university_universities_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_universities
    ADD CONSTRAINT acorn_university_universities_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_years acorn_university_years_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_years
    ADD CONSTRAINT acorn_university_years_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_language_user acorn_user_language_user_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_language_user
    ADD CONSTRAINT acorn_user_language_user_pkey PRIMARY KEY (user_id, language_id);


--
-- Name: acorn_user_languages acorn_user_languages_name_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_languages
    ADD CONSTRAINT acorn_user_languages_name_unique UNIQUE (name);


--
-- Name: acorn_user_languages acorn_user_languages_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_languages
    ADD CONSTRAINT acorn_user_languages_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_role_user acorn_user_role_user_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_role_user
    ADD CONSTRAINT acorn_user_role_user_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: acorn_user_roles acorn_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_roles
    ADD CONSTRAINT acorn_user_roles_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_throttle acorn_user_throttle_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_throttle
    ADD CONSTRAINT acorn_user_throttle_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_user_group acorn_user_user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group
    ADD CONSTRAINT acorn_user_user_group_pkey PRIMARY KEY (user_id, user_group_id);


--
-- Name: acorn_user_user_group_types acorn_user_user_group_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_types
    ADD CONSTRAINT acorn_user_user_group_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_user_groups acorn_user_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT acorn_user_user_groups_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_users acorn_user_users_email_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT acorn_user_users_email_unique UNIQUE (email);


--
-- Name: acorn_user_users acorn_user_users_login_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT acorn_user_users_login_unique UNIQUE (username);


--
-- Name: acorn_user_users acorn_user_users_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT acorn_user_users_pkey PRIMARY KEY (id);


--
-- Name: backend_access_log backend_access_log_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_access_log
    ADD CONSTRAINT backend_access_log_pkey PRIMARY KEY (id);


--
-- Name: backend_user_groups backend_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_groups
    ADD CONSTRAINT backend_user_groups_pkey PRIMARY KEY (id);


--
-- Name: backend_user_preferences backend_user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_preferences
    ADD CONSTRAINT backend_user_preferences_pkey PRIMARY KEY (id);


--
-- Name: backend_user_roles backend_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_roles
    ADD CONSTRAINT backend_user_roles_pkey PRIMARY KEY (id);


--
-- Name: backend_user_throttle backend_user_throttle_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_throttle
    ADD CONSTRAINT backend_user_throttle_pkey PRIMARY KEY (id);


--
-- Name: backend_users_groups backend_users_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users_groups
    ADD CONSTRAINT backend_users_groups_pkey PRIMARY KEY (user_id, user_group_id);


--
-- Name: backend_users backend_users_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT backend_users_pkey PRIMARY KEY (id);


--
-- Name: cache cache_key_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_key_unique UNIQUE (key);


--
-- Name: cms_theme_data cms_theme_data_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_data
    ADD CONSTRAINT cms_theme_data_pkey PRIMARY KEY (id);


--
-- Name: cms_theme_logs cms_theme_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_logs
    ADD CONSTRAINT cms_theme_logs_pkey PRIMARY KEY (id);


--
-- Name: cms_theme_templates cms_theme_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.cms_theme_templates
    ADD CONSTRAINT cms_theme_templates_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_course_materials course_semester_year_academic_year_material; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT course_semester_year_academic_year_material UNIQUE (course_id, semester_year_id, academic_year_id, material_id);


--
-- Name: deferred_bindings deferred_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.deferred_bindings
    ADD CONSTRAINT deferred_bindings_pkey PRIMARY KEY (id);


--
-- Name: backend_users email_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT email_unique UNIQUE (email);


--
-- Name: acorn_university_hierarchies entity_year; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT entity_year UNIQUE (entity_id, year_id);


--
-- Name: acorn_exam_exam_materials exam_course_material; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT exam_course_material UNIQUE (exam_id, course_material_id);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_addresses location_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT location_addresses_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_area_types location_area_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_area_types
    ADD CONSTRAINT location_area_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_areas location_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT location_areas_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_gps location_gps_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_gps
    ADD CONSTRAINT location_gps_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_locations location_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT location_locations_pkey PRIMARY KEY (id);


--
-- Name: acorn_location_types location_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT location_types_pkey PRIMARY KEY (id);


--
-- Name: backend_users login_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT login_unique UNIQUE (login);


--
-- Name: acorn_university_materials material_name; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT material_name UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: acorn_university_years name; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_years
    ADD CONSTRAINT name UNIQUE (name);


--
-- Name: backend_user_groups name_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_groups
    ADD CONSTRAINT name_unique UNIQUE (name);


--
-- Name: winter_location_countries rainlab_location_countries_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_location_countries
    ADD CONSTRAINT rainlab_location_countries_pkey PRIMARY KEY (id);


--
-- Name: winter_location_states rainlab_location_states_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_location_states
    ADD CONSTRAINT rainlab_location_states_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_attributes rainlab_translate_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_attributes
    ADD CONSTRAINT rainlab_translate_attributes_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_indexes rainlab_translate_indexes_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_indexes
    ADD CONSTRAINT rainlab_translate_indexes_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_locales rainlab_translate_locales_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_locales
    ADD CONSTRAINT rainlab_translate_locales_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_messages rainlab_translate_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_messages
    ADD CONSTRAINT rainlab_translate_messages_pkey PRIMARY KEY (id);


--
-- Name: acorn_user_mail_blockers rainlab_user_mail_blockers_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_mail_blockers
    ADD CONSTRAINT rainlab_user_mail_blockers_pkey PRIMARY KEY (id);


--
-- Name: backend_user_roles role_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_user_roles
    ADD CONSTRAINT role_unique UNIQUE (name);


--
-- Name: sessions sessions_id_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_id_unique UNIQUE (id);


--
-- Name: acorn_exam_scores student_exam_material; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT student_exam_material UNIQUE (student_id, exam_material_id);


--
-- Name: system_event_logs system_event_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_event_logs
    ADD CONSTRAINT system_event_logs_pkey PRIMARY KEY (id);


--
-- Name: system_files system_files_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_files
    ADD CONSTRAINT system_files_pkey PRIMARY KEY (id);


--
-- Name: system_mail_layouts system_mail_layouts_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_layouts
    ADD CONSTRAINT system_mail_layouts_pkey PRIMARY KEY (id);


--
-- Name: system_mail_partials system_mail_partials_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_partials
    ADD CONSTRAINT system_mail_partials_pkey PRIMARY KEY (id);


--
-- Name: system_mail_templates system_mail_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_mail_templates
    ADD CONSTRAINT system_mail_templates_pkey PRIMARY KEY (id);


--
-- Name: system_parameters system_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_parameters
    ADD CONSTRAINT system_parameters_pkey PRIMARY KEY (id);


--
-- Name: system_plugin_history system_plugin_history_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_plugin_history
    ADD CONSTRAINT system_plugin_history_pkey PRIMARY KEY (id);


--
-- Name: system_plugin_versions system_plugin_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_plugin_versions
    ADD CONSTRAINT system_plugin_versions_pkey PRIMARY KEY (id);


--
-- Name: system_request_logs system_request_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_request_logs
    ADD CONSTRAINT system_request_logs_pkey PRIMARY KEY (id);


--
-- Name: system_revisions system_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_revisions
    ADD CONSTRAINT system_revisions_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- Name: acorn_calendar_instances_date_event_part_id_instance_; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_calendar_instances_date_event_part_id_instance_ ON public.acorn_calendar_instances USING btree (date, event_part_id, instance_num);


--
-- Name: acorn_user_mail_blockers_email_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_mail_blockers_email_index ON public.acorn_user_mail_blockers USING btree (email);


--
-- Name: acorn_user_mail_blockers_template_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_mail_blockers_template_index ON public.acorn_user_mail_blockers USING btree (template);


--
-- Name: acorn_user_mail_blockers_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_mail_blockers_user_id_index ON public.acorn_user_mail_blockers USING btree (user_id);


--
-- Name: acorn_user_throttle_ip_address_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_throttle_ip_address_index ON public.acorn_user_throttle USING btree (ip_address);


--
-- Name: acorn_user_throttle_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_throttle_user_id_index ON public.acorn_user_throttle USING btree (user_id);


--
-- Name: acorn_user_user_groups_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_user_groups_code_index ON public.acorn_user_user_groups USING btree (code);


--
-- Name: acorn_user_users_activation_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_users_activation_code_index ON public.acorn_user_users USING btree (activation_code);


--
-- Name: acorn_user_users_login_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_users_login_index ON public.acorn_user_users USING btree (username);


--
-- Name: acorn_user_users_reset_password_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_users_reset_password_code_index ON public.acorn_user_users USING btree (reset_password_code);


--
-- Name: act_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX act_code_index ON public.backend_users USING btree (activation_code);


--
-- Name: admin_role_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX admin_role_index ON public.backend_users USING btree (role_id);


--
-- Name: backend_user_throttle_ip_address_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX backend_user_throttle_ip_address_index ON public.backend_user_throttle USING btree (ip_address);


--
-- Name: backend_user_throttle_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX backend_user_throttle_user_id_index ON public.backend_user_throttle USING btree (user_id);


--
-- Name: cms_theme_data_theme_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_data_theme_index ON public.cms_theme_data USING btree (theme);


--
-- Name: cms_theme_logs_theme_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_logs_theme_index ON public.cms_theme_logs USING btree (theme);


--
-- Name: cms_theme_logs_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_logs_type_index ON public.cms_theme_logs USING btree (type);


--
-- Name: cms_theme_logs_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_logs_user_id_index ON public.cms_theme_logs USING btree (user_id);


--
-- Name: cms_theme_templates_path_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_templates_path_index ON public.cms_theme_templates USING btree (path);


--
-- Name: cms_theme_templates_source_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX cms_theme_templates_source_index ON public.cms_theme_templates USING btree (source);


--
-- Name: code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX code_index ON public.backend_user_groups USING btree (code);


--
-- Name: deferred_bindings_master_field_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX deferred_bindings_master_field_index ON public.deferred_bindings USING btree (master_field);


--
-- Name: deferred_bindings_master_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX deferred_bindings_master_type_index ON public.deferred_bindings USING btree (master_type);


--
-- Name: deferred_bindings_session_key_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX deferred_bindings_session_key_index ON public.deferred_bindings USING btree (session_key);


--
-- Name: deferred_bindings_slave_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX deferred_bindings_slave_id_index ON public.deferred_bindings USING btree (slave_id);


--
-- Name: deferred_bindings_slave_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX deferred_bindings_slave_type_index ON public.deferred_bindings USING btree (slave_type);


--
-- Name: dr_acorn_location_addresses_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_addresses_replica_identity ON public.acorn_location_addresses USING btree (server_id, id);


--
-- Name: dr_acorn_location_area_types_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_area_types_replica_identity ON public.acorn_location_area_types USING btree (server_id, id);


--
-- Name: dr_acorn_location_areas_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_areas_replica_identity ON public.acorn_location_areas USING btree (server_id, id);


--
-- Name: dr_acorn_location_gps_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_gps_replica_identity ON public.acorn_location_gps USING btree (server_id, id);


--
-- Name: dr_acorn_location_location_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_location_replica_identity ON public.acorn_location_locations USING btree (server_id, id);


--
-- Name: dr_acorn_location_types_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_types_replica_identity ON public.acorn_location_types USING btree (server_id, id);


--
-- Name: fki_academic_year_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_academic_year_id ON public.acorn_university_course_materials USING btree (academic_year_id);


--
-- Name: fki_calculation_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_calculation_id ON public.acorn_university_course_materials USING btree (calculation_id);


--
-- Name: fki_course_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_course_id ON public.acorn_university_course_language USING btree (course_id);


--
-- Name: fki_course_material_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_course_material_id ON public.acorn_exam_exam_materials USING btree (course_material_id);


--
-- Name: fki_created_at_event_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_created_at_event_id ON public.acorn_university_entities USING btree (created_at_event_id);


--
-- Name: fki_created_by_user_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_created_by_user_id ON public.acorn_university_entities USING btree (created_by_user_id);


--
-- Name: fki_entity_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_entity_id ON public.acorn_university_universities USING btree (id);


--
-- Name: fki_event_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_event_id ON public.acorn_exam_interview_students USING btree (event_id);


--
-- Name: fki_exam_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_exam_id ON public.acorn_exam_exam_materials USING btree (exam_id);


--
-- Name: fki_exam_material_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_exam_material_id ON public.acorn_exam_scores USING btree (exam_material_id);


--
-- Name: fki_interview_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_interview_id ON public.acorn_exam_interview_students USING btree (interview_id);


--
-- Name: fki_language_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_language_id ON public.acorn_university_course_language USING btree (language_id);


--
-- Name: fki_material_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_material_id ON public.acorn_exam_exam_materials USING btree (course_material_id);


--
-- Name: fki_owner_student_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_owner_student_id ON public.acorn_university_project_students USING btree (owner_student_id);


--
-- Name: fki_owner_user_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_owner_user_id ON public.acorn_university_project_students USING btree (owner_student_id);


--
-- Name: fki_parent_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_parent_id ON public.acorn_university_hierarchies USING btree (parent_id);


--
-- Name: fki_project_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_project_id ON public.acorn_exam_exam_materials USING btree (project_id);


--
-- Name: fki_semester_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_semester_id ON public.acorn_university_semester_years USING btree (semester_id);


--
-- Name: fki_semester_year_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_semester_year_id ON public.acorn_university_course_materials USING btree (semester_year_id);


--
-- Name: fki_server_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_server_id ON public.acorn_university_entities USING btree (server_id);


--
-- Name: fki_student_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_student_id ON public.acorn_exam_scores USING btree (student_id);


--
-- Name: fki_teacher_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_teacher_id ON public.acorn_exam_interview_students USING btree (teacher_id);


--
-- Name: fki_type_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_type_id ON public.acorn_location_locations USING btree (type_id);


--
-- Name: fki_updated_at_event_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_updated_at_event_id ON public.acorn_university_entities USING btree (updated_at_event_id);


--
-- Name: fki_updated_by_user_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_updated_by_user_id ON public.acorn_university_entities USING btree (updated_by_user_id);


--
-- Name: fki_user_group_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_user_group_id ON public.acorn_university_entities USING btree (user_group_id);


--
-- Name: fki_year_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_year_id ON public.acorn_university_hierarchies USING btree (year_id);


--
-- Name: item_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX item_index ON public.system_parameters USING btree (namespace, "group", item);


--
-- Name: jobs_queue_reserved_at_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX jobs_queue_reserved_at_index ON public.jobs USING btree (queue, reserved_at);


--
-- Name: rainlab_location_countries_name_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX rainlab_location_countries_name_index ON public.winter_location_countries USING btree (name);


--
-- Name: rainlab_location_states_country_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX rainlab_location_states_country_id_index ON public.winter_location_states USING btree (country_id);


--
-- Name: rainlab_location_states_name_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX rainlab_location_states_name_index ON public.winter_location_states USING btree (name);


--
-- Name: reset_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX reset_code_index ON public.backend_users USING btree (reset_password_code);


--
-- Name: role_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX role_code_index ON public.backend_user_roles USING btree (code);


--
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- Name: system_event_logs_level_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_event_logs_level_index ON public.system_event_logs USING btree (level);


--
-- Name: system_files_attachment_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_files_attachment_id_index ON public.system_files USING btree (attachment_id);


--
-- Name: system_files_attachment_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_files_attachment_type_index ON public.system_files USING btree (attachment_type);


--
-- Name: system_files_field_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_files_field_index ON public.system_files USING btree (field);


--
-- Name: system_mail_templates_layout_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_mail_templates_layout_id_index ON public.system_mail_templates USING btree (layout_id);


--
-- Name: system_plugin_history_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_plugin_history_code_index ON public.system_plugin_history USING btree (code);


--
-- Name: system_plugin_history_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_plugin_history_type_index ON public.system_plugin_history USING btree (type);


--
-- Name: system_plugin_versions_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_plugin_versions_code_index ON public.system_plugin_versions USING btree (code);


--
-- Name: system_revisions_field_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_revisions_field_index ON public.system_revisions USING btree (field);


--
-- Name: system_revisions_revisionable_id_revisionable_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_revisions_revisionable_id_revisionable_type_index ON public.system_revisions USING btree (revisionable_id, revisionable_type);


--
-- Name: system_revisions_user_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_revisions_user_id_index ON public.system_revisions USING btree (user_id);


--
-- Name: system_settings_item_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX system_settings_item_index ON public.system_settings USING btree (item);


--
-- Name: user_item_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX user_item_index ON public.backend_user_preferences USING btree (user_id, namespace, "group", item);


--
-- Name: winter_translate_attributes_locale_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_attributes_locale_index ON public.winter_translate_attributes USING btree (locale);


--
-- Name: winter_translate_attributes_model_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_attributes_model_id_index ON public.winter_translate_attributes USING btree (model_id);


--
-- Name: winter_translate_attributes_model_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_attributes_model_type_index ON public.winter_translate_attributes USING btree (model_type);


--
-- Name: winter_translate_indexes_item_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_indexes_item_index ON public.winter_translate_indexes USING btree (item);


--
-- Name: winter_translate_indexes_locale_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_indexes_locale_index ON public.winter_translate_indexes USING btree (locale);


--
-- Name: winter_translate_indexes_model_id_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_indexes_model_id_index ON public.winter_translate_indexes USING btree (model_id);


--
-- Name: winter_translate_indexes_model_type_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_indexes_model_type_index ON public.winter_translate_indexes USING btree (model_type);


--
-- Name: winter_translate_locales_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_locales_code_index ON public.winter_translate_locales USING btree (code);


--
-- Name: winter_translate_locales_name_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_locales_name_index ON public.winter_translate_locales USING btree (name);


--
-- Name: winter_translate_messages_code_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_messages_code_index ON public.winter_translate_messages USING btree (code);


--
-- Name: winter_translate_messages_code_pre_2_1_0_index; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX winter_translate_messages_code_pre_2_1_0_index ON public.winter_translate_messages USING btree (code_pre_2_1_0);


--
-- Name: acorn_exam_data_entry_scores _RETURN; Type: RULE; Schema: public; Owner: university
--

CREATE OR REPLACE VIEW public.acorn_exam_data_entry_scores AS
 SELECT s.user_id AS student_user_id,
    s.id AS student_id,
    s.code AS student_code,
    en.user_group_id AS course_user_group_id,
    ugs.code AS course_code,
    em.exam_id,
    json_agg(es.id) AS ids,
    json_agg(s.id) AS student_ids,
    json_agg(em.id) AS exam_material_ids,
    json_agg(m.name) AS titles,
    json_agg(es.score) AS scores
   FROM (((((((((((public.acorn_university_courses c
     JOIN public.acorn_university_course_materials cm ON ((cm.course_id = c.id)))
     JOIN public.acorn_exam_exam_materials em ON ((em.course_material_id = cm.id)))
     JOIN public.acorn_university_entities en ON ((c.entity_id = en.id)))
     JOIN public.acorn_user_user_groups ugs ON ((en.user_group_id = ugs.id)))
     JOIN public.acorn_university_materials m ON ((cm.material_id = m.id)))
     JOIN public.acorn_exam_exams e ON ((em.exam_id = e.id)))
     JOIN public.acorn_exam_types et ON ((e.type_id = et.id)))
     JOIN public.acorn_user_user_group ug ON ((ug.user_group_id = ugs.id)))
     JOIN public.acorn_user_users u ON ((u.id = ug.user_id)))
     JOIN public.acorn_university_students s ON ((s.user_id = u.id)))
     LEFT JOIN public.acorn_exam_scores es ON (((es.exam_material_id = em.id) AND (es.student_id = s.id))))
  GROUP BY s.id, en.user_group_id, ugs.code, em.exam_id;


--
-- Name: acorn_calendar_event_parts tr_acorn_calendar_events_generate_event_instances; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_events_generate_event_instances AFTER INSERT OR UPDATE ON public.acorn_calendar_event_parts FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_events_generate_event_instances();


--
-- Name: acorn_exam_calculations tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_calculations FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_exam_materials tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_exam_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_exams tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_exams FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_interview_students tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_interview_students FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_interviews tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_interviews FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_scores tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_scores FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_exam_types tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_exam_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_academic_years tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_academic_years FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_course_materials tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_course_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_entities tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_entities FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_hierarchies tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_hierarchies FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_material_types tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_material_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_materials tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_project_students tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_project_students FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_projects tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_projects FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_semester_years tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_semester_years FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_semesters tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_semesters FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_university_years tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_university_years FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_location_addresses tr_acorn_location_addresses_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_addresses_new_replicated_row BEFORE INSERT ON public.acorn_location_addresses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_addresses ENABLE ALWAYS TRIGGER tr_acorn_location_addresses_new_replicated_row;


--
-- Name: acorn_location_addresses tr_acorn_location_addresses_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_addresses_server_id BEFORE INSERT ON public.acorn_location_addresses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_area_types tr_acorn_location_area_types_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_area_types_new_replicated_row BEFORE INSERT ON public.acorn_location_area_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_area_types ENABLE ALWAYS TRIGGER tr_acorn_location_area_types_new_replicated_row;


--
-- Name: acorn_location_area_types tr_acorn_location_area_types_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_area_types_server_id BEFORE INSERT ON public.acorn_location_area_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_areas tr_acorn_location_areas_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_areas_new_replicated_row BEFORE INSERT ON public.acorn_location_areas FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_areas ENABLE ALWAYS TRIGGER tr_acorn_location_areas_new_replicated_row;


--
-- Name: acorn_location_areas tr_acorn_location_areas_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_areas_server_id BEFORE INSERT ON public.acorn_location_areas FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_gps tr_acorn_location_gps_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_gps_new_replicated_row BEFORE INSERT ON public.acorn_location_gps FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_gps ENABLE ALWAYS TRIGGER tr_acorn_location_gps_new_replicated_row;


--
-- Name: acorn_location_gps tr_acorn_location_gps_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_gps_server_id BEFORE INSERT ON public.acorn_location_gps FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_locations tr_acorn_location_locations_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_locations_new_replicated_row BEFORE INSERT ON public.acorn_location_locations FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_locations ENABLE ALWAYS TRIGGER tr_acorn_location_locations_new_replicated_row;


--
-- Name: acorn_location_locations tr_acorn_location_locations_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_locations_server_id BEFORE INSERT ON public.acorn_location_locations FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_location_types tr_acorn_location_types_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_types_new_replicated_row BEFORE INSERT ON public.acorn_location_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_types ENABLE ALWAYS TRIGGER tr_acorn_location_types_new_replicated_row;


--
-- Name: acorn_location_types tr_acorn_location_types_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_types_server_id BEFORE INSERT ON public.acorn_location_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_calculations tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_calculations FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_exam_materials tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_exam_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_exams tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_exams FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_interview_students tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_interview_students FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_interviews tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_interviews FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_scores tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_scores FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_exam_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_exam_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_academic_years tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_academic_years FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_course_materials tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_course_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_entities tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_entities FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_hierarchies tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_hierarchies FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_material_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_material_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_materials tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_materials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_project_students tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_project_students FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_projects tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_projects FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_semester_years tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_semester_years FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_semesters tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_semesters FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_years tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_university_years FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_university_course_materials academic_year_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT academic_year_id FOREIGN KEY (academic_year_id) REFERENCES public.acorn_university_academic_years(id) NOT VALID;


--
-- Name: acorn_calendar_calendars acorn_calendar_calendars_owner_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_calendars
    ADD CONSTRAINT acorn_calendar_calendars_owner_user_group_id_foreign FOREIGN KEY (owner_user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_calendars acorn_calendar_calendars_owner_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_calendars
    ADD CONSTRAINT acorn_calendar_calendars_owner_user_id_foreign FOREIGN KEY (owner_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_part_user_event_part_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_part_user_event_part_id_foreign FOREIGN KEY (event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user_group acorn_calendar_event_part_user_group_event_part_id_fo; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user_group
    ADD CONSTRAINT acorn_calendar_event_part_user_group_event_part_id_fo FOREIGN KEY (event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user_group acorn_calendar_event_part_user_group_user_group_id_fo; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user_group
    ADD CONSTRAINT acorn_calendar_event_part_user_group_user_group_id_fo FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_part_user_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_part_user_role_id_foreign FOREIGN KEY (role_id) REFERENCES public.acorn_user_roles(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_part_user acorn_calendar_event_part_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_part_user
    ADD CONSTRAINT acorn_calendar_event_part_user_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_event_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_event_id_foreign FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_locked_by_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_locked_by_user_id_foreign FOREIGN KEY (locked_by_user_id) REFERENCES public.backend_users(id) ON DELETE SET NULL;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_parent_event_part_id_forei; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_parent_event_part_id_forei FOREIGN KEY (parent_event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_status_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_status_id_foreign FOREIGN KEY (status_id) REFERENCES public.acorn_calendar_event_statuses(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_type_id_foreign FOREIGN KEY (type_id) REFERENCES public.acorn_calendar_event_types(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_statuses acorn_calendar_event_statuses_calendar_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_statuses
    ADD CONSTRAINT acorn_calendar_event_statuses_calendar_id_foreign FOREIGN KEY (calendar_id) REFERENCES public.acorn_calendar_calendars(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_event_types acorn_calendar_event_types_calendar_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_types
    ADD CONSTRAINT acorn_calendar_event_types_calendar_id_foreign FOREIGN KEY (calendar_id) REFERENCES public.acorn_calendar_calendars(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_events acorn_calendar_events_calendar_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_events_calendar_id_foreign FOREIGN KEY (calendar_id) REFERENCES public.acorn_calendar_calendars(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_events acorn_calendar_events_owner_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_events_owner_user_group_id_foreign FOREIGN KEY (owner_user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_events acorn_calendar_events_owner_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_events
    ADD CONSTRAINT acorn_calendar_events_owner_user_id_foreign FOREIGN KEY (owner_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_calendar_instances acorn_calendar_instances_event_part_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_instances
    ADD CONSTRAINT acorn_calendar_instances_event_part_id_foreign FOREIGN KEY (event_part_id) REFERENCES public.acorn_calendar_event_parts(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_instance acorn_messaging_message_instance_instance_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_instance
    ADD CONSTRAINT acorn_messaging_message_instance_instance_id_foreign FOREIGN KEY (instance_id) REFERENCES public.acorn_calendar_instances(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_instance acorn_messaging_message_instance_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_instance
    ADD CONSTRAINT acorn_messaging_message_instance_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user_group acorn_messaging_message_user_group_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user_group
    ADD CONSTRAINT acorn_messaging_message_user_group_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user_group acorn_messaging_message_user_group_user_group_id_fore; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user_group
    ADD CONSTRAINT acorn_messaging_message_user_group_user_group_id_fore FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user acorn_messaging_message_user_message_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user
    ADD CONSTRAINT acorn_messaging_message_user_message_id_foreign FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_message_user acorn_messaging_message_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_message_user
    ADD CONSTRAINT acorn_messaging_message_user_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_message_id_foreig; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_message_id_foreig FOREIGN KEY (message_id) REFERENCES public.acorn_messaging_message(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_status_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_status_id_foreign FOREIGN KEY (status_id) REFERENCES public.acorn_messaging_status(id) ON DELETE CASCADE;


--
-- Name: acorn_messaging_user_message_status acorn_messaging_user_message_status_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_messaging_user_message_status
    ADD CONSTRAINT acorn_messaging_user_message_status_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


--
-- Name: acorn_user_language_user acorn_user_language_user_language_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_language_user
    ADD CONSTRAINT acorn_user_language_user_language_id_foreign FOREIGN KEY (language_id) REFERENCES public.acorn_user_languages(id);


--
-- Name: acorn_user_language_user acorn_user_language_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_language_user
    ADD CONSTRAINT acorn_user_language_user_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_user_user_groups acorn_user_user_groups_parent_user_group_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT acorn_user_user_groups_parent_user_group_id_foreign FOREIGN KEY (parent_user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE SET NULL;


--
-- Name: acorn_user_user_groups acorn_user_user_groups_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT acorn_user_user_groups_type_id_foreign FOREIGN KEY (type_id) REFERENCES public.acorn_user_user_group_types(id) ON DELETE SET NULL;


--
-- Name: acorn_location_locations address_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT address_id FOREIGN KEY (address_id) REFERENCES public.acorn_location_addresses(id) NOT VALID;


--
-- Name: acorn_location_addresses addresses_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT addresses_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_location_addresses area_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT area_id FOREIGN KEY (area_id) REFERENCES public.acorn_location_areas(id) NOT VALID;


--
-- Name: acorn_location_areas area_type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT area_type_id FOREIGN KEY (area_type_id) REFERENCES public.acorn_location_area_types(id);


--
-- Name: acorn_location_area_types area_types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_area_types
    ADD CONSTRAINT area_types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_location_areas areas_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT areas_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: backend_users backend_users_acorn_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.backend_users
    ADD CONSTRAINT backend_users_acorn_user_user_id_foreign FOREIGN KEY (acorn_user_user_id) REFERENCES public.acorn_user_users(id) ON DELETE SET NULL;


--
-- Name: acorn_university_course_materials calculation_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT calculation_id FOREIGN KEY (calculation_id) REFERENCES public.acorn_exam_calculations(id) NOT VALID;


--
-- Name: acorn_university_courses calculation_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_courses
    ADD CONSTRAINT calculation_id FOREIGN KEY (calculation_id) REFERENCES public.acorn_exam_calculations(id) NOT VALID;


--
-- Name: acorn_university_material_types calculation_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT calculation_id FOREIGN KEY (calculation_id) REFERENCES public.acorn_exam_calculations(id) NOT VALID;


--
-- Name: acorn_university_course_materials course_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT course_id FOREIGN KEY (course_id) REFERENCES public.acorn_university_courses(id);


--
-- Name: acorn_university_course_language course_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_language
    ADD CONSTRAINT course_id FOREIGN KEY (course_id) REFERENCES public.acorn_university_courses(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials course_material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT course_material_id FOREIGN KEY (course_material_id) REFERENCES public.acorn_university_course_materials(id) NOT VALID;


--
-- Name: acorn_exam_interview_students course_material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT course_material_id FOREIGN KEY (course_material_id) REFERENCES public.acorn_university_course_materials(id) NOT VALID;


--
-- Name: acorn_university_project_students course_material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT course_material_id FOREIGN KEY (course_material_id) REFERENCES public.acorn_university_course_materials(id) NOT VALID;


--
-- Name: acorn_university_years created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_years
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_hierarchies created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_material_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_materials created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_exams created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_calculations created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_scores created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_university_course_materials created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_university_project_students created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_interviews created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_interview_students created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_entities created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_semester_years created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semester_years
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_academic_years created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_semesters created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_projects created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_university_years created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_years
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_hierarchies created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_material_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_materials created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_exams created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_calculations created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_scores created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_course_materials created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_project_students created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_interviews created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_interview_students created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_entities created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_semester_years created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semester_years
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_academic_years created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_semesters created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_projects created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_education_authorities entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_education_authorities
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_education_authorities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_education_authorities IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_courses entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_courses
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_courses; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_courses IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_departments entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_departments
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_departments; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_departments IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_faculties entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_faculties
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_faculties; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_faculties IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_schools entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_schools
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_schools; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_schools IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_universities entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_universities
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_universities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_universities IS 'type: leaf
global-scope: to';


--
-- Name: acorn_university_hierarchies entity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT entity_id FOREIGN KEY (entity_id) REFERENCES public.acorn_university_entities(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT entity_id ON acorn_university_hierarchies; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT entity_id ON public.acorn_university_hierarchies IS 'global-scope: from
tab-location: 3';


--
-- Name: acorn_exam_interview_students event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_semester_years event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semester_years
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials exam_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT exam_id FOREIGN KEY (exam_id) REFERENCES public.acorn_exam_exams(id) NOT VALID;


--
-- Name: acorn_exam_scores exam_material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT exam_material_id FOREIGN KEY (exam_material_id) REFERENCES public.acorn_exam_exam_materials(id);


--
-- Name: CONSTRAINT exam_material_id ON acorn_exam_scores; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT exam_material_id ON public.acorn_exam_scores IS 'type: Xto1';


--
-- Name: acorn_location_gps gps_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_gps
    ADD CONSTRAINT gps_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_location_areas gps_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT gps_id FOREIGN KEY (gps_id) REFERENCES public.acorn_location_gps(id);


--
-- Name: acorn_location_addresses gps_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT gps_id FOREIGN KEY (gps_id) REFERENCES public.acorn_location_gps(id) NOT VALID;


--
-- Name: acorn_exam_interview_students interview_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT interview_id FOREIGN KEY (interview_id) REFERENCES public.acorn_exam_interviews(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials interview_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT interview_id FOREIGN KEY (interview_id) REFERENCES public.acorn_exam_interviews(id) NOT VALID;


--
-- Name: acorn_university_course_language language_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_language
    ADD CONSTRAINT language_id FOREIGN KEY (language_id) REFERENCES public.acorn_user_languages(id) NOT VALID;


--
-- Name: acorn_user_user_groups location_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acorn_location_locations(id) ON DELETE SET NULL NOT VALID;


--
-- Name: acorn_servers location_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_servers
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acorn_location_locations(id) ON DELETE SET NULL;


--
-- Name: acorn_location_locations locations_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT locations_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_course_materials material_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT material_id FOREIGN KEY (material_id) REFERENCES public.acorn_university_materials(id);


--
-- Name: acorn_university_project_students owner_student_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT owner_student_id FOREIGN KEY (owner_student_id) REFERENCES public.acorn_university_students(id) NOT VALID;


--
-- Name: acorn_location_areas parent_area_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT parent_area_id FOREIGN KEY (parent_area_id) REFERENCES public.acorn_location_areas(id) NOT VALID;


--
-- Name: acorn_university_hierarchies parent_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT parent_id FOREIGN KEY (parent_id) REFERENCES public.acorn_university_hierarchies(id) ON DELETE SET NULL NOT VALID;


--
-- Name: acorn_location_types parent_type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT parent_type_id FOREIGN KEY (parent_type_id) REFERENCES public.acorn_location_types(id);


--
-- Name: acorn_university_project_students project_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT project_id FOREIGN KEY (project_id) REFERENCES public.acorn_university_projects(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials project_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT project_id FOREIGN KEY (project_id) REFERENCES public.acorn_university_projects(id) NOT VALID;


--
-- Name: acorn_user_role_user role_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_role_user
    ADD CONSTRAINT role_id FOREIGN KEY (role_id) REFERENCES public.acorn_user_roles(id);


--
-- Name: acorn_university_semester_years semester_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semester_years
    ADD CONSTRAINT semester_id FOREIGN KEY (semester_id) REFERENCES public.acorn_university_semesters(id) NOT VALID;


--
-- Name: acorn_university_course_materials semester_year_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT semester_year_id FOREIGN KEY (semester_year_id) REFERENCES public.acorn_university_semester_years(id) NOT VALID;


--
-- Name: CONSTRAINT semester_year_id ON acorn_university_course_materials; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT semester_year_id ON public.acorn_university_course_materials IS 'global-scope: to';


--
-- Name: acorn_location_locations server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_gps server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_gps
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_addresses server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_area_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_area_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_areas server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_university_hierarchies server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_years server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_years
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_material_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_materials server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_exams server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_calculations server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_scores server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_university_course_materials server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_university_project_students server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_interviews server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_exam_interview_students server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_entities server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_semester_years server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semester_years
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_academic_years server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_semesters server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_university_projects server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_exam_scores student_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT student_id FOREIGN KEY (student_id) REFERENCES public.acorn_university_students(id) NOT VALID;


--
-- Name: CONSTRAINT student_id ON acorn_exam_scores; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT student_id ON public.acorn_exam_scores IS 'field-exclude: true';


--
-- Name: acorn_exam_interview_students student_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT student_id FOREIGN KEY (student_id) REFERENCES public.acorn_university_students(id) NOT VALID;


--
-- Name: acorn_exam_interview_students teacher_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT teacher_id FOREIGN KEY (teacher_id) REFERENCES public.acorn_university_teachers(id) NOT VALID;


--
-- Name: acorn_location_locations type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT type_id FOREIGN KEY (type_id) REFERENCES public.acorn_location_types(id) NOT VALID;


--
-- Name: acorn_exam_exams type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT type_id FOREIGN KEY (type_id) REFERENCES public.acorn_exam_types(id) NOT VALID;


--
-- Name: acorn_university_materials type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT type_id FOREIGN KEY (material_type_id) REFERENCES public.acorn_university_material_types(id) NOT VALID;


--
-- Name: acorn_location_types types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_years updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_years
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_hierarchies updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_material_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_materials updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_exams updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_calculations updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_scores updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_university_course_materials updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_university_project_students updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_interviews updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_exam_interview_students updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_entities updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_semester_years updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semester_years
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_academic_years updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_semesters updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_university_projects updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_university_years updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_years
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_hierarchies updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_material_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_material_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_materials updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_materials
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_exams updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exams
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_exam_materials updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_exam_materials
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_calculations updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_calculations
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_scores updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_scores
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_course_materials updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_course_materials
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_project_students updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_interviews updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interviews
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_exam_interview_students updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_exam_interview_students
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_entities updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_semester_years updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semester_years
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_academic_years updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_academic_years
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_semesters updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semesters
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_university_projects updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_projects
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_entities user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_entities
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: CONSTRAINT user_group_id ON acorn_university_entities; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT user_group_id ON public.acorn_university_entities IS 'type: 1to1
name-object: true';


--
-- Name: acorn_university_project_students user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_project_students
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_university_students user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_students
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: CONSTRAINT user_id ON acorn_university_students; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT user_id ON public.acorn_university_students IS 'type: leaf';


--
-- Name: acorn_university_teachers user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_teachers
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: CONSTRAINT user_id ON acorn_university_teachers; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT user_id ON public.acorn_university_teachers IS 'type: leaf';


--
-- Name: acorn_user_role_user user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_role_user
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_university_hierarchies year_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_hierarchies
    ADD CONSTRAINT year_id FOREIGN KEY (year_id) REFERENCES public.acorn_university_years(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT year_id ON acorn_university_hierarchies; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT year_id ON public.acorn_university_hierarchies IS 'global-scope: to';


--
-- Name: acorn_university_semester_years year_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_university_semester_years
    ADD CONSTRAINT year_id FOREIGN KEY (year_id) REFERENCES public.acorn_university_years(id) NOT VALID;


--
-- Name: CONSTRAINT year_id ON acorn_university_semester_years; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON CONSTRAINT year_id ON public.acorn_university_semester_years IS 'global-scope: to';


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_in(cstring); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_in(cstring) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_out(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_out(public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_recv(internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_recv(internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_send(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_send(public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION avg(VARIADIC ints double precision[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.avg(VARIADIC ints double precision[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION avg(VARIADIC ints integer[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.avg(VARIADIC ints integer[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION bytea_to_text(data bytea); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.bytea_to_text(data bytea) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION count(dp1 double precision, VARIADIC ints double precision[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.count(dp1 double precision, VARIADIC ints double precision[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION count(i1 integer, VARIADIC ints integer[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.count(i1 integer, VARIADIC ints integer[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube(double precision[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube(double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube(double precision[], double precision[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision[], double precision[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube(double precision, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision, double precision) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube(public.cube, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(public.cube, double precision) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube(public.cube, double precision, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(public.cube, double precision, double precision) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_cmp(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_cmp(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_contained(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_contained(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_contains(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_contains(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_coord(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_coord(public.cube, integer) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_coord_llur(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_coord_llur(public.cube, integer) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_dim(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_dim(public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_distance(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_distance(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_enlarge(public.cube, double precision, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_enlarge(public.cube, double precision, integer) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_eq(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_eq(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_ge(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ge(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_gt(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_gt(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_inter(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_inter(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_is_point(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_is_point(public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_le(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_le(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_ll_coord(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ll_coord(public.cube, integer) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_lt(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_lt(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_ne(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ne(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_overlap(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_overlap(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_size(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_size(public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_subset(public.cube, integer[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_subset(public.cube, integer[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_union(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_union(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION cube_ur_coord(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ur_coord(public.cube, integer) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION distance_chebyshev(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.distance_chebyshev(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION distance_taxicab(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.distance_taxicab(public.cube, public.cube) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION earth(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.earth() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION gc_to_sec(double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gc_to_sec(double precision) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION earth_box(public.earth, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.earth_box(public.earth, double precision) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION sec_to_gc(double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.sec_to_gc(double precision) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION earth_distance(public.earth, public.earth); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.earth_distance(public.earth, public.earth) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_events_generate_event_instances(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_events_generate_event_instances() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_is_date(s character varying, d timestamp without time zone); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp without time zone) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_seed(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_seed() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_trigger_activity_event(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_exam_token_name(VARIADIC p_titles character varying[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name(VARIADIC p_titles character varying[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_exam_token_name(p_id uuid, VARIADIC p_titles character varying[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name(p_id uuid, VARIADIC p_titles character varying[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_exam_token_name_internal(p_titles character varying[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_exam_token_name_internal(p_titles character varying[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_exam_tokenize(p_expr character varying, level integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.fn_acorn_exam_tokenize(p_expr character varying, level integer) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_first(anyelement, anyelement); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_first(anyelement, anyelement) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_last(anyelement, anyelement); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_last(anyelement, anyelement) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_new_replicated_row(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_new_replicated_row() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_reset_sequences(schema_like character varying, table_like character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_server_id(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_server_id() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_table_counts(_schema character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_table_counts(_schema character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_truncate_database(schema_like character varying, table_like character varying); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_user_get_seed_user(); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.fn_acorn_user_get_seed_user() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_consistent(internal, public.cube, smallint, oid, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_consistent(internal, public.cube, smallint, oid, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_distance(internal, public.cube, smallint, oid, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_distance(internal, public.cube, smallint, oid, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_penalty(internal, internal, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_picksplit(internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_picksplit(internal, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_same(public.cube, public.cube, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_same(public.cube, public.cube, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_union(internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_union(internal, internal) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION geo_distance(point, point); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.geo_distance(point, point) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION hostname(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.hostname() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http(request public.http_request); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http(request public.http_request) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_delete(uri character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_delete(uri character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_delete(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_delete(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_get(uri character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_get(uri character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_get(uri character varying, data jsonb); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_get(uri character varying, data jsonb) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_head(uri character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_head(uri character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_header(field character varying, value character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_header(field character varying, value character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_list_curlopt(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_list_curlopt() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_patch(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_patch(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_post(uri character varying, data jsonb); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_post(uri character varying, data jsonb) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_post(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_post(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_put(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_put(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_reset_curlopt(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_reset_curlopt() TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION http_set_curlopt(curlopt character varying, value character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_set_curlopt(curlopt character varying, value character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION latitude(public.earth); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.latitude(public.earth) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION ll_to_earth(double precision, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.ll_to_earth(double precision, double precision) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION longitude(public.earth); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.longitude(public.earth) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION max(VARIADIC ints double precision[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.max(VARIADIC ints double precision[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION min(VARIADIC ints double precision[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.min(VARIADIC ints double precision[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION sum(VARIADIC ints double precision[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.sum(VARIADIC ints double precision[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION sum(VARIADIC ints integer[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.sum(VARIADIC ints integer[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION sum(ints character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.sum(ints character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION sums(VARIADIC ints integer[]); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.sums(VARIADIC ints integer[]) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION text_to_bytea(data text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.text_to_bytea(data text) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION urlencode(string bytea); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.urlencode(string bytea) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION urlencode(data jsonb); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.urlencode(data jsonb) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION urlencode(string character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.urlencode(string character varying) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION agg_acorn_first(anyelement); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.agg_acorn_first(anyelement) TO token_1 WITH GRANT OPTION;


--
-- Name: FUNCTION agg_acorn_last(anyelement); Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON FUNCTION public.agg_acorn_last(anyelement) TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_calendars; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_calendars TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_event_part_user; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_part_user TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_event_part_user_group; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_part_user_group TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_event_parts; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_parts TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_event_statuses; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_statuses TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_event_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_types TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_events; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_events TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_instances; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_instances TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_exam_calculations; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_calculations TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_exam_exam_materials; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_exam_materials TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_exam_exams; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_exams TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_exam_interview_students; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_interview_students TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_exam_interviews; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_interviews TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_exam_scores; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_scores TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_exam_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_types TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_course_materials; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_course_materials TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_courses; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_courses TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_entities; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_entities TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_material_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_material_types TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_materials; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_materials TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_project_students; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_project_students TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_students; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_students TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_user_group; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_user_groups; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_groups TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_users; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_users TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_exam_tokens; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_exam_tokens TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_exam_results; Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON TABLE public.acorn_exam_results TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_addresses; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_addresses TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_area_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_area_types TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_areas; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_areas TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_gps; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_gps TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_locations; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_locations TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_lookup; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_lookup TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_types TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_action; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_action TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_label; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_label TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_message; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_message_instance; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_instance TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_message_message; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_message TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_message_user; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_user TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_message_user_group; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_user_group TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_status; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_status TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_user_message_status; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_user_message_status TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_reporting_reports; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_reporting_reports TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE acorn_reporting_reports_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.acorn_reporting_reports_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_servers; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_servers TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_departments; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_departments TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_education_authorities; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_education_authorities TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_faculties; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_faculties TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_hierarchies; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_hierarchies TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_projects; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_projects TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_schools; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_schools TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_teachers; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_teachers TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_universities; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_universities TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_university_years; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_university_years TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_language_user; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_language_user TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_languages; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_languages TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_mail_blockers; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_mail_blockers TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_roles; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_roles TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_throttle; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_throttle TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_user_group_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group_types TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_user_group_version_usages; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group_version_usages TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE backend_access_log; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_access_log TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_access_log_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_access_log_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE backend_user_groups; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_groups TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_user_groups_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_groups_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE backend_user_preferences; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_preferences TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_user_preferences_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_preferences_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE backend_user_roles; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_roles TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_user_roles_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_roles_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE backend_user_throttle; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_throttle TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_user_throttle_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_throttle_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE backend_users; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_users TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE backend_users_groups; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_users_groups TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_users_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_users_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE cache; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cache TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE cms_theme_data; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cms_theme_data TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE cms_theme_data_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.cms_theme_data_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE cms_theme_logs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cms_theme_logs TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE cms_theme_logs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.cms_theme_logs_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE cms_theme_templates; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cms_theme_templates TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE cms_theme_templates_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.cms_theme_templates_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE deferred_bindings; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.deferred_bindings TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE deferred_bindings_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.deferred_bindings_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE failed_jobs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.failed_jobs TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE failed_jobs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.failed_jobs_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE job_batches; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.job_batches TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE jobs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.jobs TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE jobs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.jobs_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE migrations; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.migrations TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE migrations_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.migrations_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE winter_location_countries; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_location_countries TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_location_countries_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_location_countries_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE winter_location_states; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_location_states TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_location_states_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_location_states_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE winter_translate_attributes; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_attributes TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_translate_attributes_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_attributes_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE winter_translate_indexes; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_indexes TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_translate_indexes_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_indexes_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE winter_translate_locales; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_locales TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_translate_locales_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_locales_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE winter_translate_messages; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_messages TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_translate_messages_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_messages_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE sessions; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.sessions TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE system_event_logs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_event_logs TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE system_event_logs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_event_logs_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE system_files; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_files TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE system_files_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_files_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE system_mail_layouts; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_mail_layouts TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE system_mail_layouts_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_mail_layouts_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE system_mail_partials; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_mail_partials TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE system_mail_partials_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_mail_partials_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE system_mail_templates; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_mail_templates TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE system_mail_templates_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_mail_templates_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE system_parameters; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_parameters TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE system_parameters_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_parameters_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE system_plugin_history; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_plugin_history TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE system_plugin_history_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_plugin_history_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE system_plugin_versions; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_plugin_versions TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE system_plugin_versions_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_plugin_versions_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE system_request_logs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_request_logs TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE system_request_logs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_request_logs_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE system_revisions; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_revisions TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE system_revisions_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_revisions_id_seq TO token_1 WITH GRANT OPTION;


--
-- Name: TABLE system_settings; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_settings TO token_1 WITH GRANT OPTION;


--
-- Name: SEQUENCE system_settings_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_settings_id_seq TO token_1 WITH GRANT OPTION;


--
-- PostgreSQL database dump complete
--

