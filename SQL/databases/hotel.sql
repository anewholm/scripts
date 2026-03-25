--
-- PostgreSQL database dump
--

\restrict 0fsia21S2c3QCRf8vuZrT00kp8sj4lZVgcoBHaHuxIUcFkgmycyhQ4Zv9RDXIEX

-- Dumped from database version 16.13 (Ubuntu 16.13-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.13 (Ubuntu 16.13-0ubuntu0.24.04.1)

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

ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_version DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_role_user DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_user_addresses DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_people DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_version DROP CONSTRAINT IF EXISTS user_group_version_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_versions DROP CONSTRAINT IF EXISTS user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group DROP CONSTRAINT IF EXISTS user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_user_group_location DROP CONSTRAINT IF EXISTS user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_tasks DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_task_types DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_stages DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_stage_types DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_room_types DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_places DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_item_types DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_types DROP CONSTRAINT IF EXISTS types_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_location_locations DROP CONSTRAINT IF EXISTS type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_tasks DROP CONSTRAINT IF EXISTS task_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_stages DROP CONSTRAINT IF EXISTS task_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_stages DROP CONSTRAINT IF EXISTS stage_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_locations DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_gps DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_area_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_addresses DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_address_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_tasks DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_task_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_stages DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_stage_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_room_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_places DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_item_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_rooms DROP CONSTRAINT IF EXISTS room_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_role_user DROP CONSTRAINT IF EXISTS role_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_users DROP CONSTRAINT IF EXISTS religion_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_rooms DROP CONSTRAINT IF EXISTS place_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_items DROP CONSTRAINT IF EXISTS place_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_floors DROP CONSTRAINT IF EXISTS place_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_buildings DROP CONSTRAINT IF EXISTS place_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_areas DROP CONSTRAINT IF EXISTS place_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_types DROP CONSTRAINT IF EXISTS parent_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS parent_area_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_locations DROP CONSTRAINT IF EXISTS locations_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_servers DROP CONSTRAINT IF EXISTS location_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_user_group_location DROP CONSTRAINT IF EXISTS location_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_items DROP CONSTRAINT IF EXISTS item_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_tasks DROP CONSTRAINT IF EXISTS item_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS gps_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_addresses DROP CONSTRAINT IF EXISTS gps_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_gps DROP CONSTRAINT IF EXISTS gps_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_areas DROP CONSTRAINT IF EXISTS floor_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_tasks DROP CONSTRAINT IF EXISTS event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_users DROP CONSTRAINT IF EXISTS ethnicity_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_tasks DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_task_types DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_stages DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_stage_types DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_room_types DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_places DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_item_types DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_floors DROP CONSTRAINT IF EXISTS building_id;
ALTER TABLE IF EXISTS ONLY public.backend_users DROP CONSTRAINT IF EXISTS backend_users_acorn_user_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS areas_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_location_area_types DROP CONSTRAINT IF EXISTS area_types_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS area_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_addresses DROP CONSTRAINT IF EXISTS area_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_rooms DROP CONSTRAINT IF EXISTS area_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_addresses DROP CONSTRAINT IF EXISTS addresses_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_location_address_types DROP CONSTRAINT IF EXISTS addresses_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_location_user_addresses DROP CONSTRAINT IF EXISTS address_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_user_addresses DROP CONSTRAINT IF EXISTS address_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_locations DROP CONSTRAINT IF EXISTS address_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_groups DROP CONSTRAINT IF EXISTS acorn_user_user_groups_type_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_groups DROP CONSTRAINT IF EXISTS acorn_user_user_groups_parent_user_group_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_languages DROP CONSTRAINT IF EXISTS acorn_user_language_user_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_languages DROP CONSTRAINT IF EXISTS acorn_user_language_user_language_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_user_message_status DROP CONSTRAINT IF EXISTS acorn_messaging_user_message_status_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_user_message_status DROP CONSTRAINT IF EXISTS acorn_messaging_user_message_status_status_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_user_message_status DROP CONSTRAINT IF EXISTS acorn_messaging_user_message_status_message_id_foreig;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_message_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user_group DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_group_user_group_id_fore;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user_group DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_group_message_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_instance DROP CONSTRAINT IF EXISTS acorn_messaging_message_instance_message_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_instance DROP CONSTRAINT IF EXISTS acorn_messaging_message_instance_instance_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_instances DROP CONSTRAINT IF EXISTS acorn_calendar_instances_event_part_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_events DROP CONSTRAINT IF EXISTS acorn_calendar_events_owner_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_events DROP CONSTRAINT IF EXISTS acorn_calendar_events_owner_user_group_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_events DROP CONSTRAINT IF EXISTS acorn_calendar_events_calendar_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_types DROP CONSTRAINT IF EXISTS acorn_calendar_event_types_calendar_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_statuses DROP CONSTRAINT IF EXISTS acorn_calendar_event_statuses_calendar_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_parts_user_group_version_id_fore;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_parts_type_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_parts_status_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_parts_parent_event_part_id_forei;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_parts_locked_by_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_parts_event_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_user_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_user_role_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user_group DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_user_group_user_group_id_fo;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user_group DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_user_group_event_part_id_fo;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_user_event_part_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_calendars DROP CONSTRAINT IF EXISTS acorn_calendar_calendars_owner_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_calendars DROP CONSTRAINT IF EXISTS acorn_calendar_calendars_owner_user_group_id_foreign;
DROP TRIGGER IF EXISTS tr_acorn_user_user_languages_current ON public.acorn_user_user_languages;
DROP TRIGGER IF EXISTS tr_acorn_user_user_group_version_current ON public.acorn_user_user_group_versions;
DROP TRIGGER IF EXISTS tr_acorn_user_user_group_first_version ON public.acorn_user_user_groups;
DROP TRIGGER IF EXISTS tr_acorn_updated_by_user_id ON public.acorn_hotel_tasks;
DROP TRIGGER IF EXISTS tr_acorn_updated_by_user_id ON public.acorn_hotel_task_types;
DROP TRIGGER IF EXISTS tr_acorn_updated_by_user_id ON public.acorn_hotel_stages;
DROP TRIGGER IF EXISTS tr_acorn_updated_by_user_id ON public.acorn_hotel_stage_types;
DROP TRIGGER IF EXISTS tr_acorn_updated_by_user_id ON public.acorn_hotel_room_types;
DROP TRIGGER IF EXISTS tr_acorn_updated_by_user_id ON public.acorn_hotel_places;
DROP TRIGGER IF EXISTS tr_acorn_updated_by_user_id ON public.acorn_hotel_item_types;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_hotel_tasks;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_hotel_task_types;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_hotel_stages;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_hotel_stage_types;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_hotel_room_types;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_hotel_places;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_hotel_item_types;
DROP TRIGGER IF EXISTS tr_acorn_location_types_server_id ON public.acorn_location_types;
DROP TRIGGER IF EXISTS tr_acorn_location_types_new_replicated_row ON public.acorn_location_types;
DROP TRIGGER IF EXISTS tr_acorn_location_locations_server_id ON public.acorn_location_locations;
DROP TRIGGER IF EXISTS tr_acorn_location_locations_new_replicated_row ON public.acorn_location_locations;
DROP TRIGGER IF EXISTS tr_acorn_location_gps_server_id ON public.acorn_location_gps;
DROP TRIGGER IF EXISTS tr_acorn_location_gps_new_replicated_row ON public.acorn_location_gps;
DROP TRIGGER IF EXISTS tr_acorn_location_areas_server_id ON public.acorn_location_areas;
DROP TRIGGER IF EXISTS tr_acorn_location_areas_new_replicated_row ON public.acorn_location_areas;
DROP TRIGGER IF EXISTS tr_acorn_location_area_types_server_id ON public.acorn_location_area_types;
DROP TRIGGER IF EXISTS tr_acorn_location_area_types_new_replicated_row ON public.acorn_location_area_types;
DROP TRIGGER IF EXISTS tr_acorn_location_addresses_server_id ON public.acorn_location_addresses;
DROP TRIGGER IF EXISTS tr_acorn_location_addresses_new_replicated_row ON public.acorn_location_addresses;
DROP TRIGGER IF EXISTS tr_acorn_location_address_types_server_id ON public.acorn_location_address_types;
DROP TRIGGER IF EXISTS tr_acorn_location_address_types_new_replicated_row ON public.acorn_location_address_types;
DROP TRIGGER IF EXISTS tr_acorn_created_by_user_id ON public.acorn_hotel_tasks;
DROP TRIGGER IF EXISTS tr_acorn_created_by_user_id ON public.acorn_hotel_task_types;
DROP TRIGGER IF EXISTS tr_acorn_created_by_user_id ON public.acorn_hotel_stages;
DROP TRIGGER IF EXISTS tr_acorn_created_by_user_id ON public.acorn_hotel_stage_types;
DROP TRIGGER IF EXISTS tr_acorn_created_by_user_id ON public.acorn_hotel_room_types;
DROP TRIGGER IF EXISTS tr_acorn_created_by_user_id ON public.acorn_hotel_places;
DROP TRIGGER IF EXISTS tr_acorn_created_by_user_id ON public.acorn_hotel_item_types;
DROP TRIGGER IF EXISTS tr_acorn_calendar_events_generate_event_instances ON public.acorn_calendar_event_parts;
DROP INDEX IF EXISTS public.winter_translate_messages_code_pre_2_1_0_index;
DROP INDEX IF EXISTS public.winter_translate_messages_code_index;
DROP INDEX IF EXISTS public.winter_translate_locales_name_index;
DROP INDEX IF EXISTS public.winter_translate_locales_code_index;
DROP INDEX IF EXISTS public.winter_translate_indexes_model_type_index;
DROP INDEX IF EXISTS public.winter_translate_indexes_model_id_index;
DROP INDEX IF EXISTS public.winter_translate_indexes_locale_index;
DROP INDEX IF EXISTS public.winter_translate_indexes_item_index;
DROP INDEX IF EXISTS public.winter_translate_attributes_model_type_index;
DROP INDEX IF EXISTS public.winter_translate_attributes_model_id_index;
DROP INDEX IF EXISTS public.winter_translate_attributes_locale_index;
DROP INDEX IF EXISTS public.user_item_index;
DROP INDEX IF EXISTS public.system_settings_item_index;
DROP INDEX IF EXISTS public.system_revisions_user_id_index;
DROP INDEX IF EXISTS public.system_revisions_field_index;
DROP INDEX IF EXISTS public.system_plugin_versions_code_index;
DROP INDEX IF EXISTS public.system_plugin_history_type_index;
DROP INDEX IF EXISTS public.system_plugin_history_code_index;
DROP INDEX IF EXISTS public.system_mail_templates_layout_id_index;
DROP INDEX IF EXISTS public.system_files_field_index;
DROP INDEX IF EXISTS public.system_files_attachment_type_index;
DROP INDEX IF EXISTS public.system_files_attachment_id_index;
DROP INDEX IF EXISTS public.system_event_logs_level_index;
DROP INDEX IF EXISTS public.sessions_user_id_index;
DROP INDEX IF EXISTS public.sessions_last_activity_index;
DROP INDEX IF EXISTS public.role_code_index;
DROP INDEX IF EXISTS public.reset_code_index;
DROP INDEX IF EXISTS public.rainlab_location_states_name_index;
DROP INDEX IF EXISTS public.rainlab_location_states_country_id_index;
DROP INDEX IF EXISTS public.rainlab_location_countries_name_index;
DROP INDEX IF EXISTS public.jobs_queue_reserved_at_index;
DROP INDEX IF EXISTS public.item_index;
DROP INDEX IF EXISTS public.fki_user_id;
DROP INDEX IF EXISTS public.fki_updated_by_user_id;
DROP INDEX IF EXISTS public.fki_type_id;
DROP INDEX IF EXISTS public.fki_task_type_id;
DROP INDEX IF EXISTS public.fki_stage_type_id;
DROP INDEX IF EXISTS public.fki_server_id;
DROP INDEX IF EXISTS public.fki_room_type_id;
DROP INDEX IF EXISTS public.fki_religion_id;
DROP INDEX IF EXISTS public.fki_place_id;
DROP INDEX IF EXISTS public.fki_location_id;
DROP INDEX IF EXISTS public.fki_item_type_id;
DROP INDEX IF EXISTS public.fki_item_id;
DROP INDEX IF EXISTS public.fki_global_scope_entity_id;
DROP INDEX IF EXISTS public.fki_global_scope_academic_year_id;
DROP INDEX IF EXISTS public.fki_floor_id;
DROP INDEX IF EXISTS public.fki_event_id;
DROP INDEX IF EXISTS public.fki_ethnicity_id;
DROP INDEX IF EXISTS public.fki_created_by_user_id;
DROP INDEX IF EXISTS public.fki_building_id;
DROP INDEX IF EXISTS public.fki_area_id;
DROP INDEX IF EXISTS public.fki_address_type_id;
DROP INDEX IF EXISTS public.fki_address_id;
DROP INDEX IF EXISTS public.fki_acorn_calendar_event_parts_user_group_version_id_;
DROP INDEX IF EXISTS public.dr_acorn_location_types_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_location_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_gps_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_areas_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_area_types_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_addresses_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_address_types_replica_identity;
DROP INDEX IF EXISTS public.deferred_bindings_slave_type_index;
DROP INDEX IF EXISTS public.deferred_bindings_slave_id_index;
DROP INDEX IF EXISTS public.deferred_bindings_session_key_index;
DROP INDEX IF EXISTS public.deferred_bindings_master_type_index;
DROP INDEX IF EXISTS public.deferred_bindings_master_field_index;
DROP INDEX IF EXISTS public.code_index;
DROP INDEX IF EXISTS public.cms_theme_templates_source_index;
DROP INDEX IF EXISTS public.cms_theme_templates_path_index;
DROP INDEX IF EXISTS public.cms_theme_logs_user_id_index;
DROP INDEX IF EXISTS public.cms_theme_logs_type_index;
DROP INDEX IF EXISTS public.cms_theme_logs_theme_index;
DROP INDEX IF EXISTS public.cms_theme_data_theme_index;
DROP INDEX IF EXISTS public.backend_user_throttle_user_id_index;
DROP INDEX IF EXISTS public.backend_user_throttle_ip_address_index;
DROP INDEX IF EXISTS public.admin_role_index;
DROP INDEX IF EXISTS public.act_code_index;
DROP INDEX IF EXISTS public.acorn_user_users_reset_password_code_index;
DROP INDEX IF EXISTS public.acorn_user_users_login_index;
DROP INDEX IF EXISTS public.acorn_user_users_activation_code_index;
DROP INDEX IF EXISTS public.acorn_user_user_groups_name;
DROP INDEX IF EXISTS public.acorn_user_user_groups_code_index;
DROP INDEX IF EXISTS public.acorn_user_throttle_user_id_index;
DROP INDEX IF EXISTS public.acorn_user_throttle_ip_address_index;
DROP INDEX IF EXISTS public.acorn_user_mail_blockers_user_id_index;
DROP INDEX IF EXISTS public.acorn_user_mail_blockers_template_index;
DROP INDEX IF EXISTS public.acorn_user_mail_blockers_email_index;
DROP INDEX IF EXISTS public.acorn_calendar_instances_date_event_part_id_instance_;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_languages DROP CONSTRAINT IF EXISTS user_language;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_people DROP CONSTRAINT IF EXISTS unique_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_users DROP CONSTRAINT IF EXISTS unique_user;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_rooms DROP CONSTRAINT IF EXISTS unique_location_rooms_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_floors DROP CONSTRAINT IF EXISTS unique_location_floors_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_buildings DROP CONSTRAINT IF EXISTS unique_location_buildings_id;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_areas DROP CONSTRAINT IF EXISTS unique_location_areas_id;
ALTER TABLE IF EXISTS ONLY public.system_settings DROP CONSTRAINT IF EXISTS system_settings_pkey;
ALTER TABLE IF EXISTS ONLY public.system_revisions DROP CONSTRAINT IF EXISTS system_revisions_pkey;
ALTER TABLE IF EXISTS ONLY public.system_request_logs DROP CONSTRAINT IF EXISTS system_request_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.system_plugin_versions DROP CONSTRAINT IF EXISTS system_plugin_versions_pkey;
ALTER TABLE IF EXISTS ONLY public.system_plugin_history DROP CONSTRAINT IF EXISTS system_plugin_history_pkey;
ALTER TABLE IF EXISTS ONLY public.system_parameters DROP CONSTRAINT IF EXISTS system_parameters_pkey;
ALTER TABLE IF EXISTS ONLY public.system_mail_templates DROP CONSTRAINT IF EXISTS system_mail_templates_pkey;
ALTER TABLE IF EXISTS ONLY public.system_mail_partials DROP CONSTRAINT IF EXISTS system_mail_partials_pkey;
ALTER TABLE IF EXISTS ONLY public.system_mail_layouts DROP CONSTRAINT IF EXISTS system_mail_layouts_pkey;
ALTER TABLE IF EXISTS ONLY public.system_files DROP CONSTRAINT IF EXISTS system_files_pkey;
ALTER TABLE IF EXISTS ONLY public.system_event_logs DROP CONSTRAINT IF EXISTS system_event_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.sessions DROP CONSTRAINT IF EXISTS sessions_id_unique;
ALTER TABLE IF EXISTS ONLY public.backend_user_roles DROP CONSTRAINT IF EXISTS role_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_user_mail_blockers DROP CONSTRAINT IF EXISTS rainlab_user_mail_blockers_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_translate_messages DROP CONSTRAINT IF EXISTS rainlab_translate_messages_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_translate_locales DROP CONSTRAINT IF EXISTS rainlab_translate_locales_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_translate_indexes DROP CONSTRAINT IF EXISTS rainlab_translate_indexes_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_translate_attributes DROP CONSTRAINT IF EXISTS rainlab_translate_attributes_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_location_states DROP CONSTRAINT IF EXISTS rainlab_location_states_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_location_countries DROP CONSTRAINT IF EXISTS rainlab_location_countries_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_user_groups DROP CONSTRAINT IF EXISTS name_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_location_area_types DROP CONSTRAINT IF EXISTS name;
ALTER TABLE IF EXISTS ONLY public.winter_translate_attributes DROP CONSTRAINT IF EXISTS model_locale;
ALTER TABLE IF EXISTS ONLY public.migrations DROP CONSTRAINT IF EXISTS migrations_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_translate_messages DROP CONSTRAINT IF EXISTS messages_data;
ALTER TABLE IF EXISTS ONLY public.winter_translate_messages DROP CONSTRAINT IF EXISTS messages_code;
ALTER TABLE IF EXISTS ONLY public.backend_users DROP CONSTRAINT IF EXISTS login_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_location_types DROP CONSTRAINT IF EXISTS location_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_types DROP CONSTRAINT IF EXISTS location_type_name_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_location_locations DROP CONSTRAINT IF EXISTS location_locations_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_gps DROP CONSTRAINT IF EXISTS location_gps_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS location_areas_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_area_types DROP CONSTRAINT IF EXISTS location_area_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_addresses DROP CONSTRAINT IF EXISTS location_addresses_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_address_types DROP CONSTRAINT IF EXISTS location_address_types_pkey;
ALTER TABLE IF EXISTS ONLY public.jobs DROP CONSTRAINT IF EXISTS jobs_pkey;
ALTER TABLE IF EXISTS ONLY public.job_batches DROP CONSTRAINT IF EXISTS job_batches_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_users DROP CONSTRAINT IF EXISTS import_source_users;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_groups DROP CONSTRAINT IF EXISTS import_source_user_groups;
ALTER TABLE IF EXISTS ONLY public.failed_jobs DROP CONSTRAINT IF EXISTS failed_jobs_uuid_unique;
ALTER TABLE IF EXISTS ONLY public.failed_jobs DROP CONSTRAINT IF EXISTS failed_jobs_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_users DROP CONSTRAINT IF EXISTS email_unique;
ALTER TABLE IF EXISTS ONLY public.deferred_bindings DROP CONSTRAINT IF EXISTS deferred_bindings_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_groups DROP CONSTRAINT IF EXISTS code;
ALTER TABLE IF EXISTS ONLY public.cms_theme_templates DROP CONSTRAINT IF EXISTS cms_theme_templates_pkey;
ALTER TABLE IF EXISTS ONLY public.cms_theme_logs DROP CONSTRAINT IF EXISTS cms_theme_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.cms_theme_data DROP CONSTRAINT IF EXISTS cms_theme_data_pkey;
ALTER TABLE IF EXISTS ONLY public.cache DROP CONSTRAINT IF EXISTS cache_key_unique;
ALTER TABLE IF EXISTS ONLY public.backend_users DROP CONSTRAINT IF EXISTS backend_users_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_users_groups DROP CONSTRAINT IF EXISTS backend_users_groups_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_user_throttle DROP CONSTRAINT IF EXISTS backend_user_throttle_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_user_roles DROP CONSTRAINT IF EXISTS backend_user_roles_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_user_preferences DROP CONSTRAINT IF EXISTS backend_user_preferences_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_user_groups DROP CONSTRAINT IF EXISTS backend_user_groups_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_access_log DROP CONSTRAINT IF EXISTS backend_access_log_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS area_area_type;
ALTER TABLE IF EXISTS ONLY public.acorn_user_users DROP CONSTRAINT IF EXISTS acorn_user_users_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_users DROP CONSTRAINT IF EXISTS acorn_user_users_login_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_user_users DROP CONSTRAINT IF EXISTS acorn_user_users_email_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_groups DROP CONSTRAINT IF EXISTS acorn_user_user_groups_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_versions DROP CONSTRAINT IF EXISTS acorn_user_user_group_versions_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_version DROP CONSTRAINT IF EXISTS acorn_user_user_group_version_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_types DROP CONSTRAINT IF EXISTS acorn_user_user_group_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group DROP CONSTRAINT IF EXISTS acorn_user_user_group_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_throttle DROP CONSTRAINT IF EXISTS acorn_user_throttle_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_roles DROP CONSTRAINT IF EXISTS acorn_user_roles_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_role_user DROP CONSTRAINT IF EXISTS acorn_user_role_user_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_religions DROP CONSTRAINT IF EXISTS acorn_user_religions_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_user_religions DROP CONSTRAINT IF EXISTS acorn_user_religions_pk;
ALTER TABLE IF EXISTS ONLY public.acorn_user_languages DROP CONSTRAINT IF EXISTS acorn_user_languages_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_languages DROP CONSTRAINT IF EXISTS acorn_user_languages_name_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_languages DROP CONSTRAINT IF EXISTS acorn_user_language_user_pk;
ALTER TABLE IF EXISTS ONLY public.acorn_user_ethnicities DROP CONSTRAINT IF EXISTS acorn_user_ethnicitiess_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_user_ethnicities DROP CONSTRAINT IF EXISTS acorn_user_ethnicities_pk;
ALTER TABLE IF EXISTS ONLY public.acorn_servers DROP CONSTRAINT IF EXISTS acorn_servers_id_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_servers DROP CONSTRAINT IF EXISTS acorn_servers_hostname_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_reporting_reports DROP CONSTRAINT IF EXISTS acorn_reporting_reports_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_user_message_status DROP CONSTRAINT IF EXISTS acorn_messaging_user_message_status_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_status DROP CONSTRAINT IF EXISTS acorn_messaging_status_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user_group DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_group_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message DROP CONSTRAINT IF EXISTS acorn_messaging_message_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_message DROP CONSTRAINT IF EXISTS acorn_messaging_message_message_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_instance DROP CONSTRAINT IF EXISTS acorn_messaging_message_instance_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message DROP CONSTRAINT IF EXISTS acorn_messaging_message_externalid_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_label DROP CONSTRAINT IF EXISTS acorn_messaging_label_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_lookup DROP CONSTRAINT IF EXISTS acorn_location_location_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_task_types DROP CONSTRAINT IF EXISTS acorn_hotel_tasktypes_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_tasks DROP CONSTRAINT IF EXISTS acorn_hotel_tasks_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_stages DROP CONSTRAINT IF EXISTS acorn_hotel_stages_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_stage_types DROP CONSTRAINT IF EXISTS acorn_hotel_stage_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_room_types DROP CONSTRAINT IF EXISTS acorn_hotel_roomtypes_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_rooms DROP CONSTRAINT IF EXISTS acorn_hotel_rooms_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_places DROP CONSTRAINT IF EXISTS acorn_hotel_places_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_people DROP CONSTRAINT IF EXISTS acorn_hotel_people_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_item_types DROP CONSTRAINT IF EXISTS acorn_hotel_itemtypes_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_items DROP CONSTRAINT IF EXISTS acorn_hotel_items_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_floors DROP CONSTRAINT IF EXISTS acorn_hotel_floors_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_buildings DROP CONSTRAINT IF EXISTS acorn_hotel_building_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_hotel_areas DROP CONSTRAINT IF EXISTS acorn_hotel_areas_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_instances DROP CONSTRAINT IF EXISTS acorn_calendar_instances_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_events DROP CONSTRAINT IF EXISTS acorn_calendar_events_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_types DROP CONSTRAINT IF EXISTS acorn_calendar_event_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_statuses DROP CONSTRAINT IF EXISTS acorn_calendar_event_statuses_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_parts_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_user_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user_group DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_user_group_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_calendars DROP CONSTRAINT IF EXISTS acorn_calendar_calendars_pkey;
ALTER TABLE IF EXISTS public.winter_translate_messages ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.winter_translate_locales ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.winter_translate_indexes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.winter_translate_attributes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.winter_location_states ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.winter_location_countries ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_settings ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_revisions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_request_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_plugin_versions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_plugin_history ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_parameters ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_mail_templates ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_mail_partials ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_mail_layouts ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_files ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_event_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.migrations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.jobs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.failed_jobs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.deferred_bindings ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.cms_theme_templates ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.cms_theme_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.cms_theme_data ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.backend_users ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.backend_user_throttle ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.backend_user_roles ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.backend_user_preferences ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.backend_user_groups ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.backend_access_log ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.acorn_reporting_reports ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.system_settings_id_seq;
DROP TABLE IF EXISTS public.system_settings;
DROP SEQUENCE IF EXISTS public.system_revisions_id_seq;
DROP TABLE IF EXISTS public.system_revisions;
DROP SEQUENCE IF EXISTS public.system_request_logs_id_seq;
DROP TABLE IF EXISTS public.system_request_logs;
DROP SEQUENCE IF EXISTS public.system_plugin_versions_id_seq;
DROP TABLE IF EXISTS public.system_plugin_versions;
DROP SEQUENCE IF EXISTS public.system_plugin_history_id_seq;
DROP TABLE IF EXISTS public.system_plugin_history;
DROP SEQUENCE IF EXISTS public.system_parameters_id_seq;
DROP TABLE IF EXISTS public.system_parameters;
DROP SEQUENCE IF EXISTS public.system_mail_templates_id_seq;
DROP TABLE IF EXISTS public.system_mail_templates;
DROP SEQUENCE IF EXISTS public.system_mail_partials_id_seq;
DROP TABLE IF EXISTS public.system_mail_partials;
DROP SEQUENCE IF EXISTS public.system_mail_layouts_id_seq;
DROP TABLE IF EXISTS public.system_mail_layouts;
DROP SEQUENCE IF EXISTS public.system_files_id_seq;
DROP TABLE IF EXISTS public.system_files;
DROP SEQUENCE IF EXISTS public.system_event_logs_id_seq;
DROP TABLE IF EXISTS public.system_event_logs;
DROP TABLE IF EXISTS public.sessions;
DROP SEQUENCE IF EXISTS public.rainlab_translate_messages_id_seq;
DROP TABLE IF EXISTS public.winter_translate_messages;
DROP SEQUENCE IF EXISTS public.rainlab_translate_locales_id_seq;
DROP TABLE IF EXISTS public.winter_translate_locales;
DROP SEQUENCE IF EXISTS public.rainlab_translate_indexes_id_seq;
DROP TABLE IF EXISTS public.winter_translate_indexes;
DROP SEQUENCE IF EXISTS public.rainlab_translate_attributes_id_seq;
DROP TABLE IF EXISTS public.winter_translate_attributes;
DROP SEQUENCE IF EXISTS public.rainlab_location_states_id_seq;
DROP TABLE IF EXISTS public.winter_location_states;
DROP SEQUENCE IF EXISTS public.rainlab_location_countries_id_seq;
DROP TABLE IF EXISTS public.winter_location_countries;
DROP SEQUENCE IF EXISTS public.migrations_id_seq;
DROP TABLE IF EXISTS public.migrations;
DROP SEQUENCE IF EXISTS public.jobs_id_seq;
DROP TABLE IF EXISTS public.jobs;
DROP TABLE IF EXISTS public.job_batches;
DROP SEQUENCE IF EXISTS public.failed_jobs_id_seq;
DROP TABLE IF EXISTS public.failed_jobs;
DROP SEQUENCE IF EXISTS public.deferred_bindings_id_seq;
DROP TABLE IF EXISTS public.deferred_bindings;
DROP SEQUENCE IF EXISTS public.cms_theme_templates_id_seq;
DROP TABLE IF EXISTS public.cms_theme_templates;
DROP SEQUENCE IF EXISTS public.cms_theme_logs_id_seq;
DROP TABLE IF EXISTS public.cms_theme_logs;
DROP SEQUENCE IF EXISTS public.cms_theme_data_id_seq;
DROP TABLE IF EXISTS public.cms_theme_data;
DROP TABLE IF EXISTS public.cache;
DROP SEQUENCE IF EXISTS public.backend_users_id_seq;
DROP TABLE IF EXISTS public.backend_users_groups;
DROP SEQUENCE IF EXISTS public.backend_user_throttle_id_seq;
DROP TABLE IF EXISTS public.backend_user_throttle;
DROP SEQUENCE IF EXISTS public.backend_user_roles_id_seq;
DROP TABLE IF EXISTS public.backend_user_roles;
DROP SEQUENCE IF EXISTS public.backend_user_preferences_id_seq;
DROP TABLE IF EXISTS public.backend_user_preferences;
DROP SEQUENCE IF EXISTS public.backend_user_groups_id_seq;
DROP TABLE IF EXISTS public.backend_user_groups;
DROP SEQUENCE IF EXISTS public.backend_access_log_id_seq;
DROP TABLE IF EXISTS public.backend_access_log;
DROP TABLE IF EXISTS public.acorn_user_user_languages;
DROP TABLE IF EXISTS public.acorn_user_user_groups;
DROP TABLE IF EXISTS public.acorn_user_user_group_versions;
DROP VIEW IF EXISTS public.acorn_user_user_group_version_usages;
DROP TABLE IF EXISTS public.acorn_user_user_group_version;
DROP TABLE IF EXISTS public.acorn_user_user_group_types;
DROP TABLE IF EXISTS public.acorn_user_user_group;
DROP TABLE IF EXISTS public.acorn_user_throttle;
DROP TABLE IF EXISTS public.acorn_user_roles;
DROP TABLE IF EXISTS public.acorn_user_role_user;
DROP TABLE IF EXISTS public.acorn_user_religions;
DROP TABLE IF EXISTS public.acorn_user_mail_blockers;
DROP TABLE IF EXISTS public.acorn_user_languages;
DROP TABLE IF EXISTS public.acorn_user_ethnicities;
DROP SEQUENCE IF EXISTS public.acorn_reporting_reports_id_seq;
DROP TABLE IF EXISTS public.acorn_reporting_reports;
DROP VIEW IF EXISTS public.acorn_names;
DROP TABLE IF EXISTS public.acorn_messaging_user_message_status;
DROP TABLE IF EXISTS public.acorn_messaging_status;
DROP TABLE IF EXISTS public.acorn_messaging_message_user_group;
DROP TABLE IF EXISTS public.acorn_messaging_message_user;
DROP TABLE IF EXISTS public.acorn_messaging_message_message;
DROP TABLE IF EXISTS public.acorn_messaging_message_instance;
DROP TABLE IF EXISTS public.acorn_messaging_message;
DROP TABLE IF EXISTS public.acorn_messaging_label;
DROP TABLE IF EXISTS public.acorn_messaging_action;
DROP TABLE IF EXISTS public.acorn_location_types;
DROP TABLE IF EXISTS public.acorn_location_lookup;
DROP VIEW IF EXISTS public.acorn_location_location_links;
DROP TABLE IF EXISTS public.acorn_servers;
DROP TABLE IF EXISTS public.acorn_location_user_group_location;
DROP TABLE IF EXISTS public.acorn_location_gps;
DROP TABLE IF EXISTS public.acorn_location_areas;
DROP TABLE IF EXISTS public.acorn_location_area_types;
DROP TABLE IF EXISTS public.acorn_location_addresses;
DROP TABLE IF EXISTS public.acorn_location_address_types;
DROP VIEW IF EXISTS public.acorn_location_address_links;
DROP TABLE IF EXISTS public.acorn_location_user_addresses;
DROP TABLE IF EXISTS public.acorn_location_locations;
DROP TABLE IF EXISTS public.acorn_hotel_rooms;
DROP TABLE IF EXISTS public.acorn_hotel_people;
DROP TABLE IF EXISTS public.acorn_hotel_items;
DROP TABLE IF EXISTS public.acorn_hotel_floors;
DROP TABLE IF EXISTS public.acorn_hotel_buildings;
DROP TABLE IF EXISTS public.acorn_hotel_areas;
DROP VIEW IF EXISTS public.acorn_dbauth_user;
DROP TABLE IF EXISTS public.backend_users;
DROP TABLE IF EXISTS public.acorn_user_users;
DROP VIEW IF EXISTS public.acorn_created_bys;
DROP VIEW IF EXISTS public.acorn_calendar_upcreated_ats;
DROP TABLE IF EXISTS public.acorn_hotel_task_types;
DROP TABLE IF EXISTS public.acorn_hotel_stages;
DROP TABLE IF EXISTS public.acorn_hotel_stage_types;
DROP TABLE IF EXISTS public.acorn_hotel_room_types;
DROP TABLE IF EXISTS public.acorn_hotel_places;
DROP TABLE IF EXISTS public.acorn_hotel_item_types;
DROP VIEW IF EXISTS public.acorn_calendar_linked_events;
DROP TABLE IF EXISTS public.acorn_hotel_tasks;
DROP VIEW IF EXISTS public.acorn_calendar_linked_calendars;
DROP TABLE IF EXISTS public.acorn_calendar_instances;
DROP TABLE IF EXISTS public.acorn_calendar_events;
DROP TABLE IF EXISTS public.acorn_calendar_event_types;
DROP TABLE IF EXISTS public.acorn_calendar_event_statuses;
DROP TABLE IF EXISTS public.acorn_calendar_event_parts;
DROP TABLE IF EXISTS public.acorn_calendar_event_part_user_group;
DROP TABLE IF EXISTS public.acorn_calendar_event_part_user;
DROP TABLE IF EXISTS public.acorn_calendar_calendars;
DROP AGGREGATE IF EXISTS public.agg_acorn_last(anyelement);
DROP AGGREGATE IF EXISTS public.agg_acorn_first(anyelement);
DROP FUNCTION IF EXISTS public.fn_acorn_user_user_languages_current();
DROP FUNCTION IF EXISTS public.fn_acorn_user_user_group_version_current();
DROP FUNCTION IF EXISTS public.fn_acorn_user_user_group_first_version();
DROP FUNCTION IF EXISTS public.fn_acorn_user_get_seed_user();
DROP FUNCTION IF EXISTS public.fn_acorn_user_code_acronym(name character varying, word integer, length integer);
DROP FUNCTION IF EXISTS public.fn_acorn_user_code(name character varying, word integer, length integer);
DROP FUNCTION IF EXISTS public.fn_acorn_updated_by_user_id();
DROP FUNCTION IF EXISTS public.fn_acorn_truncate_database(schema_like character varying, table_like character varying);
DROP FUNCTION IF EXISTS public.fn_acorn_translate(p_fallback_name character varying, p_table character varying, p_id uuid, p_locale character);
DROP FUNCTION IF EXISTS public.fn_acorn_table_counts(_schema character varying);
DROP FUNCTION IF EXISTS public.fn_acorn_sumproduct(VARIADIC ints double precision[]);
DROP FUNCTION IF EXISTS public.fn_acorn_sumproduct();
DROP FUNCTION IF EXISTS public.fn_acorn_sum(ints character varying);
DROP FUNCTION IF EXISTS public.fn_acorn_sum(VARIADIC ints double precision[]);
DROP FUNCTION IF EXISTS public.fn_acorn_sum();
DROP FUNCTION IF EXISTS public.fn_acorn_server_id();
DROP FUNCTION IF EXISTS public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying);
DROP FUNCTION IF EXISTS public.fn_acorn_new_replicated_row();
DROP FUNCTION IF EXISTS public.fn_acorn_min(VARIADIC ints double precision[]);
DROP FUNCTION IF EXISTS public.fn_acorn_min();
DROP FUNCTION IF EXISTS public.fn_acorn_max(VARIADIC ints double precision[]);
DROP FUNCTION IF EXISTS public.fn_acorn_max();
DROP FUNCTION IF EXISTS public.fn_acorn_last(anyelement, anyelement);
DROP FUNCTION IF EXISTS public.fn_acorn_hotel_action_tasks_complete(model_id uuid, user_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_first(anyelement, anyelement);
DROP FUNCTION IF EXISTS public.fn_acorn_created_by_user_id();
DROP FUNCTION IF EXISTS public.fn_acorn_count(VARIADIC ints double precision[]);
DROP FUNCTION IF EXISTS public.fn_acorn_count();
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_seed();
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying);
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_is_date(s character varying, d timestamp without time zone);
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record);
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_events_generate_event_instances();
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_create_event(p_calendar_id uuid, p_owner_user_id uuid, p_type_id uuid, p_status_id uuid, p_name character varying, p_date_from timestamp without time zone, p_date_to timestamp without time zone, p_container_event_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_create_event(p_calendar_id uuid, p_owner_user_id uuid, p_type_id uuid, p_status_id uuid, p_name character varying, p_container_event_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_avg(VARIADIC ints double precision[]);
DROP FUNCTION IF EXISTS public.fn_acorn_avg();
DROP FUNCTION IF EXISTS public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying);
DROP EXTENSION IF EXISTS postgres_fdw;
DROP EXTENSION IF EXISTS pg_trgm;
DROP EXTENSION IF EXISTS hostname;
DROP EXTENSION IF EXISTS fuzzystrmatch;
DROP EXTENSION IF EXISTS earthdistance;
DROP EXTENSION IF EXISTS cube;
-- *not* dropping schema, since initdb creates it
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
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
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: hostname; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hostname WITH SCHEMA public;


--
-- Name: EXTENSION hostname; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hostname IS 'Get the server host name';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: postgres_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;


--
-- Name: EXTENSION postgres_fdw; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgres_fdw IS 'foreign-data wrapper for remote PostgreSQL servers';


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
-- Name: fn_acorn_avg(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_avg() RETURNS double precision
    LANGUAGE sql
    AS $$
	select NULL::int;
$$;


ALTER FUNCTION public.fn_acorn_avg() OWNER TO university;

--
-- Name: fn_acorn_avg(double precision[]); Type: FUNCTION; Schema: public; Owner: anewholm
--

CREATE FUNCTION public.fn_acorn_avg(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select avg(unnest) from (SELECT unnest(ints)) a;
$$;


ALTER FUNCTION public.fn_acorn_avg(VARIADIC ints double precision[]) OWNER TO anewholm;

--
-- Name: fn_acorn_calendar_create_event(uuid, uuid, uuid, uuid, character varying, uuid); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_create_event(p_calendar_id uuid, p_owner_user_id uuid, p_type_id uuid, p_status_id uuid, p_name character varying, p_container_event_id uuid DEFAULT NULL::uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
            
            begin
            return public.fn_acorn_calendar_create_event(calendar_id, owner_user_id, type_id, status_id, name, now()::timestamp without time zone, now()::timestamp without time zone, p_container_event_id);
end;
            
$$;


ALTER FUNCTION public.fn_acorn_calendar_create_event(p_calendar_id uuid, p_owner_user_id uuid, p_type_id uuid, p_status_id uuid, p_name character varying, p_container_event_id uuid) OWNER TO university;

--
-- Name: fn_acorn_calendar_create_event(uuid, uuid, uuid, uuid, character varying, timestamp without time zone, timestamp without time zone, uuid); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_calendar_create_event(p_calendar_id uuid, p_owner_user_id uuid, p_type_id uuid, p_status_id uuid, p_name character varying, p_date_from timestamp without time zone, p_date_to timestamp without time zone, p_container_event_id uuid DEFAULT NULL::uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
declare
	p_new_event_id uuid;
begin
	insert into public.acorn_calendar_events(calendar_id, owner_user_id) 
		values(p_calendar_id, p_owner_user_id) returning id into p_new_event_id;
	insert into public.acorn_calendar_event_parts(event_id, type_id, status_id, name, start, "end", parent_event_part_id)
		values(p_new_event_id, p_type_id, p_status_id, p_name, p_date_from, p_date_to, p_container_event_id);
	return p_new_event_id;
end;
            
$$;


ALTER FUNCTION public.fn_acorn_calendar_create_event(p_calendar_id uuid, p_owner_user_id uuid, p_type_id uuid, p_status_id uuid, p_name character varying, p_date_from timestamp without time zone, p_date_to timestamp without time zone, p_container_event_id uuid) OWNER TO university;

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
                        from public.system_settings where item = 'acorn_calendar_settings'), '1 year')
                        into days_before;
                    select coalesce((select substring("value" from '"days_after":"([^"]+)"')
                        from public.system_settings where item = 'acorn_calendar_settings'), '2 years')
                        into days_after;
                    select extract('epoch' from days_before + days_after)/3600/24.0
                        into days_count;
                    select today - days_before
                        into date_start;

                    -- For updates (id cannot change)
                    delete from public.acorn_calendar_instances where event_part_id = new_event_part.id;

                    -- For inserts
                    insert into public.acorn_calendar_instances("date", event_part_id, instance_start, instance_end, instance_num)
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
                        inner join public.acorn_calendar_instances pcc on new_event_part.parent_event_part_id = pcc.event_part_id
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
                    update public.acorn_calendar_event_parts set id = id
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
-- Name: fn_acorn_count(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_count() RETURNS integer
    LANGUAGE sql
    AS $$
	select 0;
$$;


ALTER FUNCTION public.fn_acorn_count() OWNER TO university;

--
-- Name: fn_acorn_count(double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_count(VARIADIC ints double precision[]) RETURNS integer
    LANGUAGE sql
    AS $$
	-- Do not count the NULLs
	select array_length(array_remove(ints, NULL),1);
$$;


ALTER FUNCTION public.fn_acorn_count(VARIADIC ints double precision[]) OWNER TO university;

--
-- Name: fn_acorn_created_by_user_id(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_created_by_user_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
declare
begin
	-- BEFORE INSERT on tables with created_by_user_id
	-- DBAuth required
	-- Will return NULL if not regexp_like(CURRENT_USER, '^token_[0-9]+$')
	if new.created_by_user_id is null then
		select u.id into new.created_by_user_id from acorn_dbauth_user u;
	end if;
    return new;
end;
            
$_$;


ALTER FUNCTION public.fn_acorn_created_by_user_id() OWNER TO university;

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
-- Name: fn_acorn_hotel_action_tasks_complete(uuid, uuid); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_hotel_action_tasks_complete(model_id uuid, user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	-- Add a new event_part
end;
$$;


ALTER FUNCTION public.fn_acorn_hotel_action_tasks_complete(model_id uuid, user_id uuid) OWNER TO university;

--
-- Name: FUNCTION fn_acorn_hotel_action_tasks_complete(model_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON FUNCTION public.fn_acorn_hotel_action_tasks_complete(model_id uuid, user_id uuid) IS 'labels:
  en: Complete
result-action: refresh
comment:
  en: Complete this instance and create a new instance in the future.
';


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
-- Name: fn_acorn_max(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_max() RETURNS double precision
    LANGUAGE sql
    AS $$
	select NULL::int;
$$;


ALTER FUNCTION public.fn_acorn_max() OWNER TO university;

--
-- Name: fn_acorn_max(double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_max(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select max(unnest) from (SELECT unnest(ints)) a;
$$;


ALTER FUNCTION public.fn_acorn_max(VARIADIC ints double precision[]) OWNER TO university;

--
-- Name: fn_acorn_min(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_min() RETURNS double precision
    LANGUAGE sql
    AS $$
	select NULL::int;
$$;


ALTER FUNCTION public.fn_acorn_min() OWNER TO university;

--
-- Name: fn_acorn_min(double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_min(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select min(unnest) from (SELECT unnest(ints)) a;
$$;


ALTER FUNCTION public.fn_acorn_min(VARIADIC ints double precision[]) OWNER TO university;

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
-- Name: fn_acorn_sum(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_sum() RETURNS double precision
    LANGUAGE sql
    AS $$
	select NULL::double precision;
$$;


ALTER FUNCTION public.fn_acorn_sum() OWNER TO university;

--
-- Name: fn_acorn_sum(double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_sum(VARIADIC ints double precision[]) RETURNS double precision
    LANGUAGE sql
    AS $$
	select sum(unnest) from (SELECT unnest(ints)) a;
$$;


ALTER FUNCTION public.fn_acorn_sum(VARIADIC ints double precision[]) OWNER TO university;

--
-- Name: fn_acorn_sum(character varying); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_sum(ints character varying) RETURNS integer
    LANGUAGE sql
    AS $$
	select sum(unnest) from (SELECT unnest(ints::integer[]))
$$;


ALTER FUNCTION public.fn_acorn_sum(ints character varying) OWNER TO university;

--
-- Name: fn_acorn_sumproduct(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_sumproduct() RETURNS double precision
    LANGUAGE plpgsql
    AS $$
declare
begin
	return NULL::int;
end
$$;


ALTER FUNCTION public.fn_acorn_sumproduct() OWNER TO university;

--
-- Name: fn_acorn_sumproduct(double precision[]); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_sumproduct(VARIADIC ints double precision[]) RETURNS double precision
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


ALTER FUNCTION public.fn_acorn_sumproduct(VARIADIC ints double precision[]) OWNER TO university;

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
-- Name: fn_acorn_translate(character varying, character varying, uuid, character); Type: FUNCTION; Schema: public; Owner: anewholm
--

CREATE FUNCTION public.fn_acorn_translate(p_fallback_name character varying, p_table character varying, p_id uuid, p_locale character) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
declare
	p_model_parts character varying(1024)[];
	p_author character varying(1024);
	p_plugin character varying(1024);
	p_class  character varying(1024);
	p_model character varying(1024);
	p_translated_name character varying(1024);
begin
	-- Failover translateable attribute
	if p_locale = 'en' then
		p_translated_name := p_fallback_name;
	else
		-- acorn_university_students => Acorn\Uniersity\Models\Student
		p_model_parts := regexp_split_to_array(p_table, '_');
		p_author := initcap(p_model_parts[1]);
		p_plugin := initcap(p_model_parts[2]);
		p_class  := initcap(p_model_parts[3]);
		
		p_author := replace(p_author, 'Acorn', 'Acorn');
		p_class  := regexp_replace(p_class, 'ies$', 'y');
		p_class  := regexp_replace(p_class, 's$', '');
		
		p_model_parts := ARRAY[p_author, p_plugin, 'Models', p_class];
		p_model := array_to_string(p_model_parts, '\');
	
		p_translated_name := (
			select json_extract_path_text(attribute_data::json, 'name')
			from winter_translate_attributes
			where model_type = p_model and model_id = p_id::text and locale = p_locale
		);

		if p_translated_name is null or p_translated_name = '' then
			p_translated_name := p_fallback_name;
		end if;
	end if;

	return p_translated_name;
end;
$_$;


ALTER FUNCTION public.fn_acorn_translate(p_fallback_name character varying, p_table character varying, p_id uuid, p_locale character) OWNER TO anewholm;

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
-- Name: fn_acorn_updated_by_user_id(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_updated_by_user_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
declare
begin
	-- BEFORE UPDATE on tables with updated_by_user_id
	-- DBAuth required
	-- Will return NULL if not regexp_like(CURRENT_USER, '^token_[0-9]+$')
	if new.updated_by_user_id is null then
		select u.id into new.updated_by_user_id from public.acorn_dbauth_user u;
	end if;
    return new;
end;
            
$_$;


ALTER FUNCTION public.fn_acorn_updated_by_user_id() OWNER TO university;

--
-- Name: fn_acorn_user_code(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_user_code(name character varying, word integer DEFAULT 0, length integer DEFAULT 3) RETURNS character varying
    LANGUAGE sql
    AS $$
	select substr(upper(
		case word
			when 0 then
				regexp_replace(name, '[^a-zA-Z0-9]', '')
			when 1 then
				regexp_replace(regexp_replace(name, '^[^ ]* ', ''), '[^a-zA-Z0-9]', '')
			else
				regexp_replace(regexp_replace(name, '^[^ ]* [^ ]* ', ''), '[^a-zA-Z0-9]', '')
		end), 1, length);
$$;


ALTER FUNCTION public.fn_acorn_user_code(name character varying, word integer, length integer) OWNER TO university;

--
-- Name: fn_acorn_user_code_acronym(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_user_code_acronym(name character varying, word integer DEFAULT 0, length integer DEFAULT 3) RETURNS character varying
    LANGUAGE sql
    AS $$
	select 
		substr(upper(
			regexp_replace(regexp_replace(regexp_replace(name, 
			'[^a-zA-Z0-9 ]', '', 'g'),
			'([^ ])[^ ]+', '\1', 'g'),
			' +', '', 'g')
		), word+1, length);
$$;


ALTER FUNCTION public.fn_acorn_user_code_acronym(name character varying, word integer, length integer) OWNER TO university;

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
-- Name: fn_acorn_user_user_group_first_version(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_user_user_group_first_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	-- On INSERT on acorn_user_user_groups
	-- The CASCADE FK delete should remove them
	if strpos(new.import_source, 'no_trigger') = 0 then
		insert into public.acorn_user_user_group_versions(user_group_id)
			values(new.id);
	end if;
	return new;
end;
$$;


ALTER FUNCTION public.fn_acorn_user_user_group_first_version() OWNER TO university;

--
-- Name: fn_acorn_user_user_group_version_current(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_user_user_group_version_current() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	-- BEFORE INSERT OR UPDATE on acorn_user_user_group_versions
	-- version column is NOT NULL, DEFAULT 1
	if strpos(new.import_source, 'no_trigger') = 0 then
		if TG_OP = 'INSERT' then
			-- Enforce the version number
			select coalesce(max(ugv.version), 0) + 1 into new.version
				from public.acorn_user_user_group_versions ugv
				where ugv.user_group_id = new.user_group_id;
		end if;
		
		if exists(select * from public.acorn_user_user_group_versions ugv
			where ugv.user_group_id = new.user_group_id
			and ugv.version = new.version
			and not ugv.id = new.id
		) then
			raise exception 'Duplicate version number % not allowed in acorn_user_user_group_versions id %', new.version, new.id;
		end if;
			
		-- Enforce only one current
		-- False may be explicitly specified, for example, importing old codes
		-- Column default should be true on inserts
		if new.current then
			-- Unset the old current(s)
			update public.acorn_user_user_group_versions 
				set "current" = false
				where user_group_id = new.user_group_id 
				and not id = new.id
				and "current";
		end if;
	end if;
	
	return new;
end;
$$;


ALTER FUNCTION public.fn_acorn_user_user_group_version_current() OWNER TO university;

--
-- Name: fn_acorn_user_user_languages_current(); Type: FUNCTION; Schema: public; Owner: university
--

CREATE FUNCTION public.fn_acorn_user_user_languages_current() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	-- Enforce only one current
	-- False may be explicitly specified, for example, importing old codes
	-- Column default should be true on inserts
	if new.current then
		-- Unset the old current(s)
		update acorn_user_user_languages
			set "current" = false
			where user_id = new.user_id
			and "current"
			and id != new.id; 
	end if;
	return new;
end;
$$;


ALTER FUNCTION public.fn_acorn_user_user_languages_current() OWNER TO university;

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
    permissions integer DEFAULT 1 NOT NULL,
    show_on_front_end boolean DEFAULT true NOT NULL
);


ALTER TABLE public.acorn_calendar_calendars OWNER TO university;

--
-- Name: TABLE acorn_calendar_calendars; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON TABLE public.acorn_calendar_calendars IS 'package-type: plugin
table-type: content';


--
-- Name: COLUMN acorn_calendar_calendars.sync_file; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_calendar_calendars.sync_file IS 'tab-location: 3';


--
-- Name: COLUMN acorn_calendar_calendars.sync_format; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_calendar_calendars.sync_format IS 'tab-location: 3';


--
-- Name: COLUMN acorn_calendar_calendars.show_on_front_end; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_calendar_calendars.show_on_front_end IS 'tab-location: 3';


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
    instances_deleted integer[],
    user_group_version_id uuid,
    user_group_version_locked_external boolean DEFAULT false NOT NULL
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
-- Name: acorn_calendar_linked_calendars; Type: VIEW; Schema: public; Owner: createsystem
--

CREATE VIEW public.acorn_calendar_linked_calendars AS
 SELECT acorn_calendar_event_statuses.calendar_id,
    'public'::character varying(2048) AS schema,
    'acorn_calendar_event_statuses'::character varying(2048) AS "table",
    'calendar_id'::character varying(2048) AS "column",
    'Acorn\Calendar\Models\EventStatus'::text AS model_type,
    acorn_calendar_event_statuses.id AS model_id
   FROM public.acorn_calendar_event_statuses
UNION ALL
 SELECT acorn_calendar_event_types.calendar_id,
    'public'::character varying(2048) AS schema,
    'acorn_calendar_event_types'::character varying(2048) AS "table",
    'calendar_id'::character varying(2048) AS "column",
    'Acorn\Calendar\Models\EventType'::text AS model_type,
    acorn_calendar_event_types.id AS model_id
   FROM public.acorn_calendar_event_types
UNION ALL
 SELECT acorn_calendar_events.calendar_id,
    'public'::character varying(2048) AS schema,
    'acorn_calendar_events'::character varying(2048) AS "table",
    'calendar_id'::character varying(2048) AS "column",
    'Acorn\Calendar\Models\Event'::text AS model_type,
    acorn_calendar_events.id AS model_id
   FROM public.acorn_calendar_events;


ALTER VIEW public.acorn_calendar_linked_calendars OWNER TO createsystem;

--
-- Name: acorn_hotel_tasks; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid,
    on_hold boolean DEFAULT false NOT NULL,
    defer_until timestamp without time zone,
    task_type_id uuid NOT NULL,
    item_id uuid NOT NULL,
    sticky integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(0) without time zone,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_tasks OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_tasks; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_tasks IS 'order: 10';


--
-- Name: COLUMN acorn_hotel_tasks.event_id; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON COLUMN public.acorn_hotel_tasks.event_id IS 'field-key-qualifier: "[last_start]"';


--
-- Name: COLUMN acorn_hotel_tasks.on_hold; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON COLUMN public.acorn_hotel_tasks.on_hold IS 'tab-location: 3';


--
-- Name: COLUMN acorn_hotel_tasks.defer_until; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON COLUMN public.acorn_hotel_tasks.defer_until IS 'tab-location: 3';


--
-- Name: COLUMN acorn_hotel_tasks.sticky; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON COLUMN public.acorn_hotel_tasks.sticky IS 'tab-location: 3
field-comment:
  en: Tasks are view in order of sticky, then due date. Negative sticky values will place the task at the end of the list.';


--
-- Name: acorn_calendar_linked_events; Type: VIEW; Schema: public; Owner: createsystem
--

CREATE VIEW public.acorn_calendar_linked_events AS
 SELECT event_id,
    'public'::character varying(2048) AS schema,
    'acorn_hotel_tasks'::character varying(2048) AS "table",
    'event_id'::character varying(2048) AS "column",
    'Acorn\Hotel\Models\Task'::text AS model_type,
    id AS model_id
   FROM public.acorn_hotel_tasks;


ALTER VIEW public.acorn_calendar_linked_events OWNER TO createsystem;

--
-- Name: acorn_hotel_item_types; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_item_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    description text,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(0) without time zone,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_item_types OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_item_types; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_item_types IS 'order: 1300';


--
-- Name: acorn_hotel_places; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_places (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    description text,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(0) without time zone,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_places OWNER TO hotel;

--
-- Name: acorn_hotel_room_types; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_room_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(0) without time zone,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_room_types OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_room_types; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_room_types IS 'order: 1200
menu-splitter: true';


--
-- Name: acorn_hotel_stage_types; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_stage_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(0) without time zone,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_stage_types OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_stage_types; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_stage_types IS 'order: 1400';


--
-- Name: acorn_hotel_stages; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_stages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_type_id uuid NOT NULL,
    "interval" interval NOT NULL,
    stage_type_id uuid NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(0) without time zone,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_stages OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_stages; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_stages IS 'order: 1450
menu: false';


--
-- Name: COLUMN acorn_hotel_stages."interval"; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON COLUMN public.acorn_hotel_stages."interval" IS 'field-comment:
  en: For example, P1W means Period 1 Week. They always start with P. D = day, W = week, H = Hour. Negative values are also allowed. See the <a target="_blank" href="https://www.postgresql.org/docs/current/datatype-datetime.html#DATATYPE-INTERVAL-INPUT">documentation</a> for more details.
comment-html: true';


--
-- Name: acorn_hotel_task_types; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_task_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(2048) NOT NULL,
    description text,
    repeat_interval interval,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(0) without time zone,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_task_types OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_task_types; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_task_types IS 'order: 20
';


--
-- Name: COLUMN acorn_hotel_task_types.description; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON COLUMN public.acorn_hotel_task_types.description IS 'tab: acorn::lang.models.general.description';


--
-- Name: COLUMN acorn_hotel_task_types.repeat_interval; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON COLUMN public.acorn_hotel_task_types.repeat_interval IS 'field-comment:
  en: This will cause the task to get re-created every time it is marked as completed this period in the future. For example, P1W means Period 1 Week. They always start with P. D = day, W = week, H = Hour. See the <a target="_blank" href="https://www.postgresql.org/docs/current/datatype-datetime.html#DATATYPE-INTERVAL-INPUT">documentation</a> for more details.
comment-html: true';


--
-- Name: acorn_calendar_upcreated_ats; Type: VIEW; Schema: public; Owner: createsystem
--

CREATE VIEW public.acorn_calendar_upcreated_ats AS
 SELECT 'Acorn\Hotel\Models\Task'::text AS model_type,
    acorn_hotel_tasks.id AS model_id,
    'acorn_hotel_tasks'::text AS "table",
    NULL::text AS name,
    0 AS update,
    acorn_hotel_tasks.created_at AS datetime
   FROM public.acorn_hotel_tasks
UNION ALL
 SELECT 'Acorn\Hotel\Models\Task'::text AS model_type,
    acorn_hotel_tasks.id AS model_id,
    'acorn_hotel_tasks'::text AS "table",
    NULL::text AS name,
    1 AS update,
    acorn_hotel_tasks.updated_at AS datetime
   FROM public.acorn_hotel_tasks
UNION ALL
 SELECT 'Acorn\Hotel\Models\TaskType'::text AS model_type,
    acorn_hotel_task_types.id AS model_id,
    'acorn_hotel_task_types'::text AS "table",
    (acorn_hotel_task_types.name)::character varying(1024) AS name,
    0 AS update,
    acorn_hotel_task_types.created_at AS datetime
   FROM public.acorn_hotel_task_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\TaskType'::text AS model_type,
    acorn_hotel_task_types.id AS model_id,
    'acorn_hotel_task_types'::text AS "table",
    (acorn_hotel_task_types.name)::character varying(1024) AS name,
    1 AS update,
    acorn_hotel_task_types.updated_at AS datetime
   FROM public.acorn_hotel_task_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\RoomType'::text AS model_type,
    acorn_hotel_room_types.id AS model_id,
    'acorn_hotel_room_types'::text AS "table",
    acorn_hotel_room_types.name,
    0 AS update,
    acorn_hotel_room_types.created_at AS datetime
   FROM public.acorn_hotel_room_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\RoomType'::text AS model_type,
    acorn_hotel_room_types.id AS model_id,
    'acorn_hotel_room_types'::text AS "table",
    acorn_hotel_room_types.name,
    1 AS update,
    acorn_hotel_room_types.updated_at AS datetime
   FROM public.acorn_hotel_room_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\ItemType'::text AS model_type,
    acorn_hotel_item_types.id AS model_id,
    'acorn_hotel_item_types'::text AS "table",
    (acorn_hotel_item_types.name)::character varying(1024) AS name,
    0 AS update,
    acorn_hotel_item_types.created_at AS datetime
   FROM public.acorn_hotel_item_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\ItemType'::text AS model_type,
    acorn_hotel_item_types.id AS model_id,
    'acorn_hotel_item_types'::text AS "table",
    (acorn_hotel_item_types.name)::character varying(1024) AS name,
    1 AS update,
    acorn_hotel_item_types.updated_at AS datetime
   FROM public.acorn_hotel_item_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\StageType'::text AS model_type,
    acorn_hotel_stage_types.id AS model_id,
    'acorn_hotel_stage_types'::text AS "table",
    acorn_hotel_stage_types.name,
    0 AS update,
    acorn_hotel_stage_types.created_at AS datetime
   FROM public.acorn_hotel_stage_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\StageType'::text AS model_type,
    acorn_hotel_stage_types.id AS model_id,
    'acorn_hotel_stage_types'::text AS "table",
    acorn_hotel_stage_types.name,
    1 AS update,
    acorn_hotel_stage_types.updated_at AS datetime
   FROM public.acorn_hotel_stage_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\Stage'::text AS model_type,
    acorn_hotel_stages.id AS model_id,
    'acorn_hotel_stages'::text AS "table",
    NULL::text AS name,
    0 AS update,
    acorn_hotel_stages.created_at AS datetime
   FROM public.acorn_hotel_stages
UNION ALL
 SELECT 'Acorn\Hotel\Models\Stage'::text AS model_type,
    acorn_hotel_stages.id AS model_id,
    'acorn_hotel_stages'::text AS "table",
    NULL::text AS name,
    1 AS update,
    acorn_hotel_stages.updated_at AS datetime
   FROM public.acorn_hotel_stages
UNION ALL
 SELECT 'Acorn\Hotel\Models\Place'::text AS model_type,
    acorn_hotel_places.id AS model_id,
    'acorn_hotel_places'::text AS "table",
    (acorn_hotel_places.name)::character varying(1024) AS name,
    0 AS update,
    acorn_hotel_places.created_at AS datetime
   FROM public.acorn_hotel_places
UNION ALL
 SELECT 'Acorn\Hotel\Models\Place'::text AS model_type,
    acorn_hotel_places.id AS model_id,
    'acorn_hotel_places'::text AS "table",
    (acorn_hotel_places.name)::character varying(1024) AS name,
    1 AS update,
    acorn_hotel_places.updated_at AS datetime
   FROM public.acorn_hotel_places;


ALTER VIEW public.acorn_calendar_upcreated_ats OWNER TO createsystem;

--
-- Name: acorn_created_bys; Type: VIEW; Schema: public; Owner: createsystem
--

CREATE VIEW public.acorn_created_bys AS
 SELECT 'Acorn\Hotel\Models\Task'::text AS model_type,
    acorn_hotel_tasks.id AS model_id,
    'acorn_hotel_tasks'::text AS "table",
    0 AS update,
    acorn_hotel_tasks.created_by_user_id AS by
   FROM public.acorn_hotel_tasks
UNION ALL
 SELECT 'Acorn\Hotel\Models\Task'::text AS model_type,
    acorn_hotel_tasks.id AS model_id,
    'acorn_hotel_tasks'::text AS "table",
    1 AS update,
    acorn_hotel_tasks.updated_by_user_id AS by
   FROM public.acorn_hotel_tasks
UNION ALL
 SELECT 'Acorn\Hotel\Models\TaskType'::text AS model_type,
    acorn_hotel_task_types.id AS model_id,
    'acorn_hotel_task_types'::text AS "table",
    0 AS update,
    acorn_hotel_task_types.created_by_user_id AS by
   FROM public.acorn_hotel_task_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\TaskType'::text AS model_type,
    acorn_hotel_task_types.id AS model_id,
    'acorn_hotel_task_types'::text AS "table",
    1 AS update,
    acorn_hotel_task_types.updated_by_user_id AS by
   FROM public.acorn_hotel_task_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\RoomType'::text AS model_type,
    acorn_hotel_room_types.id AS model_id,
    'acorn_hotel_room_types'::text AS "table",
    0 AS update,
    acorn_hotel_room_types.created_by_user_id AS by
   FROM public.acorn_hotel_room_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\RoomType'::text AS model_type,
    acorn_hotel_room_types.id AS model_id,
    'acorn_hotel_room_types'::text AS "table",
    1 AS update,
    acorn_hotel_room_types.updated_by_user_id AS by
   FROM public.acorn_hotel_room_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\ItemType'::text AS model_type,
    acorn_hotel_item_types.id AS model_id,
    'acorn_hotel_item_types'::text AS "table",
    0 AS update,
    acorn_hotel_item_types.created_by_user_id AS by
   FROM public.acorn_hotel_item_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\ItemType'::text AS model_type,
    acorn_hotel_item_types.id AS model_id,
    'acorn_hotel_item_types'::text AS "table",
    1 AS update,
    acorn_hotel_item_types.updated_by_user_id AS by
   FROM public.acorn_hotel_item_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\StageType'::text AS model_type,
    acorn_hotel_stage_types.id AS model_id,
    'acorn_hotel_stage_types'::text AS "table",
    0 AS update,
    acorn_hotel_stage_types.created_by_user_id AS by
   FROM public.acorn_hotel_stage_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\StageType'::text AS model_type,
    acorn_hotel_stage_types.id AS model_id,
    'acorn_hotel_stage_types'::text AS "table",
    1 AS update,
    acorn_hotel_stage_types.updated_by_user_id AS by
   FROM public.acorn_hotel_stage_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\Stage'::text AS model_type,
    acorn_hotel_stages.id AS model_id,
    'acorn_hotel_stages'::text AS "table",
    0 AS update,
    acorn_hotel_stages.created_by_user_id AS by
   FROM public.acorn_hotel_stages
UNION ALL
 SELECT 'Acorn\Hotel\Models\Stage'::text AS model_type,
    acorn_hotel_stages.id AS model_id,
    'acorn_hotel_stages'::text AS "table",
    1 AS update,
    acorn_hotel_stages.updated_by_user_id AS by
   FROM public.acorn_hotel_stages
UNION ALL
 SELECT 'Acorn\Hotel\Models\Place'::text AS model_type,
    acorn_hotel_places.id AS model_id,
    'acorn_hotel_places'::text AS "table",
    0 AS update,
    acorn_hotel_places.created_by_user_id AS by
   FROM public.acorn_hotel_places
UNION ALL
 SELECT 'Acorn\Hotel\Models\Place'::text AS model_type,
    acorn_hotel_places.id AS model_id,
    'acorn_hotel_places'::text AS "table",
    1 AS update,
    acorn_hotel_places.updated_by_user_id AS by
   FROM public.acorn_hotel_places;


ALTER VIEW public.acorn_created_bys OWNER TO createsystem;

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
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
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
    birth_date timestamp without time zone,
    import_source character varying(1024),
    fathers_name character varying(1024),
    mothers_name character varying(1024),
    gender "char",
    marital_status "char",
    religion_id uuid,
    ethnicity_id uuid,
    global_scope_entity_id uuid,
    global_scope_academic_year_id uuid,
    CONSTRAINT gender_enum CHECK (((gender IS NULL) OR (gender = ANY (ARRAY['M'::"char", 'F'::"char", 'O'::"char", 'N'::"char"])))),
    CONSTRAINT marital_status_enum CHECK (((marital_status IS NULL) OR (marital_status = ANY (ARRAY['M'::"char", 'S'::"char", 'O'::"char", 'N'::"char"]))))
);


ALTER TABLE public.acorn_user_users OWNER TO university;

--
-- Name: COLUMN acorn_user_users.created_at; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_user_users.created_at IS 'disabled: true';


--
-- Name: backend_users; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.backend_users (
    id integer NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    login character varying(255) NOT NULL,
    email character varying(255),
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
    acorn_user_user_id uuid,
    acorn_create_sync_user boolean DEFAULT true NOT NULL,
    acorn_create_and_sync_aa_user boolean DEFAULT true
);


ALTER TABLE public.backend_users OWNER TO university;

--
-- Name: acorn_dbauth_user; Type: VIEW; Schema: public; Owner: anewholm
--

CREATE VIEW public.acorn_dbauth_user AS
 SELECT bk.id AS backend_id,
    bk.login AS backend_login,
    u.id,
    u.name,
    u.email,
    u.password,
    u.activation_code,
    u.persist_code,
    u.reset_password_code,
    u.permissions,
    u.is_activated,
    u.is_system_user,
    u.activated_at,
    u.last_login,
    u.created_at,
    u.updated_at,
    u.username,
    u.surname,
    u.deleted_at,
    u.last_seen,
    u.is_guest,
    u.is_superuser,
    u.created_ip_address,
    u.last_ip_address,
    u.acorn_imap_username,
    u.acorn_imap_password,
    u.acorn_imap_server,
    u.acorn_imap_port,
    u.acorn_imap_protocol,
    u.acorn_imap_encryption,
    u.acorn_imap_authentication,
    u.acorn_imap_validate_cert,
    u.acorn_smtp_server,
    u.acorn_smtp_port,
    u.acorn_smtp_encryption,
    u.acorn_smtp_authentication,
    u.acorn_smtp_username,
    u.acorn_smtp_password,
    u.acorn_messaging_sounds,
    u.acorn_messaging_email_notifications,
    u.acorn_messaging_autocreated,
    u.acorn_imap_last_fetch,
    u.acorn_default_calendar,
    u.acorn_start_of_week,
    u.acorn_default_event_time_from,
    u.acorn_default_event_time_to,
    u.birth_date,
    u.import_source,
    u.fathers_name,
    u.mothers_name,
    u.gender,
    u.marital_status,
    u.religion_id,
    u.ethnicity_id,
    u.global_scope_entity_id,
    u.global_scope_academic_year_id
   FROM (public.backend_users bk
     JOIN public.acorn_user_users u ON ((bk.acorn_user_user_id = u.id)))
  WHERE (bk.id =
        CASE
            WHEN (CURRENT_USER ~ (('^token_'::text || (current_database())::text) || '_[0-9]+$'::text)) THEN (replace((CURRENT_USER)::text, (('token_'::text || (current_database())::text) || '_'::text), ''::text))::integer
            ELSE NULL::integer
        END);


ALTER VIEW public.acorn_dbauth_user OWNER TO anewholm;

--
-- Name: acorn_hotel_areas; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_areas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    place_id uuid NOT NULL,
    floor_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_areas OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_areas; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_areas IS 'add-missing-columns: false
order: 2100';


--
-- Name: acorn_hotel_buildings; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_buildings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    place_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_buildings OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_buildings; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_buildings IS 'add-missing-columns: false
menu-splitter: true
order: 2000';


--
-- Name: acorn_hotel_floors; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_floors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    place_id uuid,
    building_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_floors OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_floors; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_floors IS 'add-missing-columns: false
order: 2050';


--
-- Name: acorn_hotel_items; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    place_id uuid NOT NULL,
    item_type_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_items OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_items; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_items IS 'add-missing-columns: false
menu: false';


--
-- Name: acorn_hotel_people; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_people (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid
);


ALTER TABLE public.acorn_hotel_people OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_people; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_people IS 'add-missing-columns: false
menu: false';


--
-- Name: acorn_hotel_rooms; Type: TABLE; Schema: public; Owner: hotel
--

CREATE TABLE public.acorn_hotel_rooms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    place_id uuid NOT NULL,
    area_id uuid NOT NULL,
    size double precision,
    has_balcony boolean DEFAULT false,
    is_public boolean DEFAULT false NOT NULL,
    room_type_id uuid NOT NULL
);


ALTER TABLE public.acorn_hotel_rooms OWNER TO hotel;

--
-- Name: TABLE acorn_hotel_rooms; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON TABLE public.acorn_hotel_rooms IS 'add-missing-columns: false
order: 2500';


--
-- Name: COLUMN acorn_hotel_rooms.has_balcony; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON COLUMN public.acorn_hotel_rooms.has_balcony IS 'tab-location: 3';


--
-- Name: COLUMN acorn_hotel_rooms.is_public; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON COLUMN public.acorn_hotel_rooms.is_public IS 'tab-location: 3';


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
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    type_id uuid
);


ALTER TABLE public.acorn_location_locations OWNER TO university;

--
-- Name: acorn_location_user_addresses; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_user_addresses (
    user_id uuid NOT NULL,
    address_id uuid NOT NULL,
    current boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    address_type_id uuid,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public.acorn_location_user_addresses OWNER TO university;

--
-- Name: acorn_location_address_links; Type: VIEW; Schema: public; Owner: createsystem
--

CREATE VIEW public.acorn_location_address_links AS
 SELECT acorn_location_user_addresses.address_id AS event_id,
    'public'::character varying(2048) AS schema,
    'acorn_location_user_addresses'::character varying(2048) AS "table",
    'address_id'::character varying(2048) AS "column",
    'Acorn\Location\Models\UserAddress'::text AS model_type,
    acorn_location_user_addresses.id AS model_id
   FROM public.acorn_location_user_addresses
UNION ALL
 SELECT acorn_location_locations.address_id AS event_id,
    'public'::character varying(2048) AS schema,
    'acorn_location_locations'::character varying(2048) AS "table",
    'address_id'::character varying(2048) AS "column",
    'Acorn\Location\Models\Location'::text AS model_type,
    acorn_location_locations.id AS model_id
   FROM public.acorn_location_locations;


ALTER VIEW public.acorn_location_address_links OWNER TO createsystem;

--
-- Name: acorn_location_address_types; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_address_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    number character varying(1024),
    image character varying(2048),
    description text,
    server_id uuid NOT NULL,
    created_by_user_id uuid,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    import_source text,
    response text
);


ALTER TABLE public.acorn_location_address_types OWNER TO university;

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
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    response text,
    lookup_id uuid,
    import_source text
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
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
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
    parent_id uuid,
    gps_id uuid,
    server_id uuid NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    is_current_version boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text,
    import_source text,
    nest_left integer,
    nest_right integer,
    nest_depth integer
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
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    response text
);


ALTER TABLE public.acorn_location_gps OWNER TO university;

--
-- Name: acorn_location_user_group_location; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_location_user_group_location (
    user_group_id uuid NOT NULL,
    location_id uuid NOT NULL,
    current boolean DEFAULT true NOT NULL
);


ALTER TABLE public.acorn_location_user_group_location OWNER TO university;

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
-- Name: acorn_location_location_links; Type: VIEW; Schema: public; Owner: createsystem
--

CREATE VIEW public.acorn_location_location_links AS
 SELECT acorn_location_user_group_location.location_id AS event_id,
    'public'::character varying(2048) AS schema,
    'acorn_location_user_group_location'::character varying(2048) AS "table",
    'location_id'::character varying(2048) AS "column",
    'Acorn\Location\Models\UserGroupLocation'::text AS model_type,
    NULL::uuid AS model_id
   FROM public.acorn_location_user_group_location
UNION ALL
 SELECT acorn_servers.location_id AS event_id,
    'public'::character varying(2048) AS schema,
    'acorn_servers'::character varying(2048) AS "table",
    'location_id'::character varying(2048) AS "column",
    'Acorn\\Models\Server'::text AS model_type,
    acorn_servers.id AS model_id
   FROM public.acorn_servers;


ALTER VIEW public.acorn_location_location_links OWNER TO createsystem;

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
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL
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
    created_at timestamp(0) without time zone DEFAULT now() NOT NULL,
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
-- Name: acorn_names; Type: VIEW; Schema: public; Owner: createsystem
--

CREATE VIEW public.acorn_names AS
 SELECT 'Acorn\Hotel\Models\TaskType'::text AS model_type,
    acorn_hotel_task_types.id AS model_id,
    'acorn_hotel_task_types'::text AS "table",
    'name'::text AS field,
    (acorn_hotel_task_types.name)::text AS content
   FROM public.acorn_hotel_task_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\TaskType'::text AS model_type,
    acorn_hotel_task_types.id AS model_id,
    'acorn_hotel_task_types'::text AS "table",
    'description'::text AS field,
    acorn_hotel_task_types.description AS content
   FROM public.acorn_hotel_task_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\RoomType'::text AS model_type,
    acorn_hotel_room_types.id AS model_id,
    'acorn_hotel_room_types'::text AS "table",
    'name'::text AS field,
    (acorn_hotel_room_types.name)::text AS content
   FROM public.acorn_hotel_room_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\RoomType'::text AS model_type,
    acorn_hotel_room_types.id AS model_id,
    'acorn_hotel_room_types'::text AS "table",
    'description'::text AS field,
    acorn_hotel_room_types.description AS content
   FROM public.acorn_hotel_room_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\ItemType'::text AS model_type,
    acorn_hotel_item_types.id AS model_id,
    'acorn_hotel_item_types'::text AS "table",
    'name'::text AS field,
    (acorn_hotel_item_types.name)::text AS content
   FROM public.acorn_hotel_item_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\ItemType'::text AS model_type,
    acorn_hotel_item_types.id AS model_id,
    'acorn_hotel_item_types'::text AS "table",
    'description'::text AS field,
    acorn_hotel_item_types.description AS content
   FROM public.acorn_hotel_item_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\StageType'::text AS model_type,
    acorn_hotel_stage_types.id AS model_id,
    'acorn_hotel_stage_types'::text AS "table",
    'name'::text AS field,
    (acorn_hotel_stage_types.name)::text AS content
   FROM public.acorn_hotel_stage_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\StageType'::text AS model_type,
    acorn_hotel_stage_types.id AS model_id,
    'acorn_hotel_stage_types'::text AS "table",
    'description'::text AS field,
    acorn_hotel_stage_types.description AS content
   FROM public.acorn_hotel_stage_types
UNION ALL
 SELECT 'Acorn\Hotel\Models\Place'::text AS model_type,
    acorn_hotel_places.id AS model_id,
    'acorn_hotel_places'::text AS "table",
    'name'::text AS field,
    (acorn_hotel_places.name)::text AS content
   FROM public.acorn_hotel_places
UNION ALL
 SELECT 'Acorn\Hotel\Models\Place'::text AS model_type,
    acorn_hotel_places.id AS model_id,
    'acorn_hotel_places'::text AS "table",
    'description'::text AS field,
    acorn_hotel_places.description AS content
   FROM public.acorn_hotel_places;


ALTER VIEW public.acorn_names OWNER TO createsystem;

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
-- Name: acorn_user_ethnicities; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_ethnicities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL
);


ALTER TABLE public.acorn_user_ethnicities OWNER TO university;

--
-- Name: acorn_user_languages; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_languages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    locale character varying(10) NOT NULL,
    rtl boolean DEFAULT false NOT NULL
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
-- Name: acorn_user_religions; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_religions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL
);


ALTER TABLE public.acorn_user_religions OWNER TO university;

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
-- Name: acorn_user_user_group; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_group (
    user_id uuid NOT NULL,
    user_group_id uuid NOT NULL
);


ALTER TABLE public.acorn_user_user_group OWNER TO university;

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
-- Name: acorn_user_user_group_version; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_group_version (
    user_id uuid NOT NULL,
    user_group_version_id uuid NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_user_user_group_version OWNER TO university;

--
-- Name: acorn_user_user_group_version_usages; Type: VIEW; Schema: public; Owner: university
--

CREATE VIEW public.acorn_user_user_group_version_usages AS
 SELECT NULL::uuid AS user_group_version_id,
    NULL::character varying(1024) AS "table",
    NULL::uuid AS id;


ALTER VIEW public.acorn_user_user_group_version_usages OWNER TO university;

--
-- Name: acorn_user_user_group_versions; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_group_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_group_id uuid NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    current boolean DEFAULT true NOT NULL,
    import_source character varying(1024),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.acorn_user_user_group_versions OWNER TO university;

--
-- Name: acorn_user_user_groups; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(2048) NOT NULL,
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
    import_source character varying(1024),
    CONSTRAINT name_valid CHECK (((name)::text <> ''::text))
);


ALTER TABLE public.acorn_user_user_groups OWNER TO university;

--
-- Name: COLUMN acorn_user_user_groups.colour; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_user_user_groups.colour IS 'tab-location: 3';


--
-- Name: COLUMN acorn_user_user_groups.import_source; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_user_user_groups.import_source IS 'advanced: true
invisible: true';


--
-- Name: acorn_user_user_languages; Type: TABLE; Schema: public; Owner: university
--

CREATE TABLE public.acorn_user_user_languages (
    user_id uuid NOT NULL,
    language_id uuid NOT NULL,
    current boolean DEFAULT true NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public.acorn_user_user_languages OWNER TO university;

--
-- Name: COLUMN acorn_user_user_languages.user_id; Type: COMMENT; Schema: public; Owner: university
--

COMMENT ON COLUMN public.acorn_user_user_languages.user_id IS 'no-relation-manager: true';


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
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    revisionable_id uuid NOT NULL
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
-- Name: acorn_hotel_areas acorn_hotel_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_areas
    ADD CONSTRAINT acorn_hotel_areas_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_buildings acorn_hotel_building_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_buildings
    ADD CONSTRAINT acorn_hotel_building_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_floors acorn_hotel_floors_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_floors
    ADD CONSTRAINT acorn_hotel_floors_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_items acorn_hotel_items_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_items
    ADD CONSTRAINT acorn_hotel_items_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_item_types acorn_hotel_itemtypes_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_item_types
    ADD CONSTRAINT acorn_hotel_itemtypes_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_people acorn_hotel_people_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_people
    ADD CONSTRAINT acorn_hotel_people_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_places acorn_hotel_places_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_places
    ADD CONSTRAINT acorn_hotel_places_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_rooms acorn_hotel_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_rooms
    ADD CONSTRAINT acorn_hotel_rooms_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_room_types acorn_hotel_roomtypes_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_room_types
    ADD CONSTRAINT acorn_hotel_roomtypes_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_stage_types acorn_hotel_stage_types_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_stage_types
    ADD CONSTRAINT acorn_hotel_stage_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_stages acorn_hotel_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_stages
    ADD CONSTRAINT acorn_hotel_stages_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_tasks acorn_hotel_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_tasks
    ADD CONSTRAINT acorn_hotel_tasks_pkey PRIMARY KEY (id);


--
-- Name: acorn_hotel_task_types acorn_hotel_tasktypes_pkey; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_task_types
    ADD CONSTRAINT acorn_hotel_tasktypes_pkey PRIMARY KEY (id);


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
-- Name: acorn_user_ethnicities acorn_user_ethnicities_pk; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_ethnicities
    ADD CONSTRAINT acorn_user_ethnicities_pk PRIMARY KEY (id);


--
-- Name: acorn_user_ethnicities acorn_user_ethnicitiess_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_ethnicities
    ADD CONSTRAINT acorn_user_ethnicitiess_unique UNIQUE (name);


--
-- Name: acorn_user_user_languages acorn_user_language_user_pk; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_languages
    ADD CONSTRAINT acorn_user_language_user_pk PRIMARY KEY (id);


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
-- Name: acorn_user_religions acorn_user_religions_pk; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_religions
    ADD CONSTRAINT acorn_user_religions_pk PRIMARY KEY (id);


--
-- Name: acorn_user_religions acorn_user_religions_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_religions
    ADD CONSTRAINT acorn_user_religions_unique UNIQUE (name);


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
-- Name: acorn_user_user_group_version acorn_user_user_group_version_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_version
    ADD CONSTRAINT acorn_user_user_group_version_pkey PRIMARY KEY (user_id, user_group_version_id);


--
-- Name: acorn_user_user_group_versions acorn_user_user_group_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_versions
    ADD CONSTRAINT acorn_user_user_group_versions_pkey PRIMARY KEY (id);


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
-- Name: acorn_location_areas area_area_type; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT area_area_type UNIQUE (name, area_type_id);


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
-- Name: acorn_user_user_groups code; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT code UNIQUE (code);


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
-- Name: acorn_user_user_groups import_source_user_groups; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT import_source_user_groups UNIQUE (import_source);


--
-- Name: acorn_user_users import_source_users; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT import_source_users UNIQUE (import_source);


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
-- Name: acorn_location_address_types location_address_types_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_address_types
    ADD CONSTRAINT location_address_types_pkey PRIMARY KEY (id);


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
-- Name: acorn_location_types location_type_name_unique; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT location_type_name_unique UNIQUE (name);


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
-- Name: winter_translate_messages messages_code; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_messages
    ADD CONSTRAINT messages_code UNIQUE (code);


--
-- Name: winter_translate_messages messages_data; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_messages
    ADD CONSTRAINT messages_data UNIQUE (message_data);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: winter_translate_attributes model_locale; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.winter_translate_attributes
    ADD CONSTRAINT model_locale UNIQUE NULLS NOT DISTINCT (model_id, model_type, locale);


--
-- Name: acorn_location_area_types name; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_area_types
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
-- Name: acorn_hotel_areas unique_location_areas_id; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_areas
    ADD CONSTRAINT unique_location_areas_id UNIQUE (place_id);


--
-- Name: acorn_hotel_buildings unique_location_buildings_id; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_buildings
    ADD CONSTRAINT unique_location_buildings_id UNIQUE (place_id);


--
-- Name: acorn_hotel_floors unique_location_floors_id; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_floors
    ADD CONSTRAINT unique_location_floors_id UNIQUE (place_id);


--
-- Name: acorn_hotel_rooms unique_location_rooms_id; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_rooms
    ADD CONSTRAINT unique_location_rooms_id UNIQUE (place_id);


--
-- Name: acorn_user_users unique_user; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT unique_user UNIQUE (name, surname, birth_date, fathers_name, mothers_name, gender);


--
-- Name: acorn_hotel_people unique_user_id; Type: CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_people
    ADD CONSTRAINT unique_user_id UNIQUE (user_id);


--
-- Name: acorn_user_user_languages user_language; Type: CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_languages
    ADD CONSTRAINT user_language UNIQUE (user_id, language_id);


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
-- Name: acorn_user_user_groups_name; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX acorn_user_user_groups_name ON public.acorn_user_user_groups USING btree (name) WITH (deduplicate_items='true');


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
-- Name: dr_acorn_location_address_types_replica_identity; Type: INDEX; Schema: public; Owner: university
--

CREATE UNIQUE INDEX dr_acorn_location_address_types_replica_identity ON public.acorn_location_address_types USING btree (server_id, id) WITH (fillfactor='100', deduplicate_items='true');


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
-- Name: fki_acorn_calendar_event_parts_user_group_version_id_; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_acorn_calendar_event_parts_user_group_version_id_ ON public.acorn_calendar_event_parts USING btree (user_group_version_id);


--
-- Name: fki_address_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_address_id ON public.acorn_location_user_addresses USING btree (address_id);


--
-- Name: fki_address_type_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_address_type_id ON public.acorn_location_user_addresses USING btree (address_type_id);


--
-- Name: fki_area_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_area_id ON public.acorn_hotel_rooms USING btree (area_id);


--
-- Name: fki_building_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_building_id ON public.acorn_hotel_floors USING btree (building_id);


--
-- Name: fki_created_by_user_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_created_by_user_id ON public.acorn_hotel_stage_types USING btree (created_by_user_id);


--
-- Name: fki_ethnicity_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_ethnicity_id ON public.acorn_user_users USING btree (ethnicity_id);


--
-- Name: fki_event_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_event_id ON public.acorn_hotel_tasks USING btree (event_id);


--
-- Name: fki_floor_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_floor_id ON public.acorn_hotel_areas USING btree (floor_id);


--
-- Name: fki_global_scope_academic_year_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_global_scope_academic_year_id ON public.acorn_user_users USING btree (global_scope_academic_year_id);


--
-- Name: fki_global_scope_entity_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_global_scope_entity_id ON public.acorn_user_users USING btree (global_scope_entity_id);


--
-- Name: fki_item_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_item_id ON public.acorn_hotel_tasks USING btree (item_id);


--
-- Name: fki_item_type_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_item_type_id ON public.acorn_hotel_items USING btree (item_type_id);


--
-- Name: fki_location_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_location_id ON public.acorn_location_user_group_location USING btree (location_id);


--
-- Name: fki_place_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_place_id ON public.acorn_hotel_areas USING btree (place_id);


--
-- Name: fki_religion_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_religion_id ON public.acorn_user_users USING btree (religion_id);


--
-- Name: fki_room_type_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_room_type_id ON public.acorn_hotel_rooms USING btree (room_type_id);


--
-- Name: fki_server_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_server_id ON public.acorn_hotel_stage_types USING btree (server_id);


--
-- Name: fki_stage_type_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_stage_type_id ON public.acorn_hotel_stages USING btree (stage_type_id);


--
-- Name: fki_task_type_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_task_type_id ON public.acorn_hotel_stages USING btree (task_type_id);


--
-- Name: fki_type_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_type_id ON public.acorn_location_locations USING btree (type_id);


--
-- Name: fki_updated_by_user_id; Type: INDEX; Schema: public; Owner: hotel
--

CREATE INDEX fki_updated_by_user_id ON public.acorn_hotel_stage_types USING btree (updated_by_user_id);


--
-- Name: fki_user_id; Type: INDEX; Schema: public; Owner: university
--

CREATE INDEX fki_user_id ON public.acorn_user_user_group_version USING btree (user_id);


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
-- Name: acorn_calendar_event_parts tr_acorn_calendar_events_generate_event_instances; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_calendar_events_generate_event_instances AFTER INSERT OR UPDATE ON public.acorn_calendar_event_parts FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_events_generate_event_instances();


--
-- Name: acorn_hotel_item_types tr_acorn_created_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_created_by_user_id BEFORE INSERT ON public.acorn_hotel_item_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_created_by_user_id();


--
-- Name: acorn_hotel_places tr_acorn_created_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_created_by_user_id BEFORE INSERT ON public.acorn_hotel_places FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_created_by_user_id();


--
-- Name: acorn_hotel_room_types tr_acorn_created_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_created_by_user_id BEFORE INSERT ON public.acorn_hotel_room_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_created_by_user_id();


--
-- Name: acorn_hotel_stage_types tr_acorn_created_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_created_by_user_id BEFORE INSERT ON public.acorn_hotel_stage_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_created_by_user_id();


--
-- Name: acorn_hotel_stages tr_acorn_created_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_created_by_user_id BEFORE INSERT ON public.acorn_hotel_stages FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_created_by_user_id();


--
-- Name: acorn_hotel_task_types tr_acorn_created_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_created_by_user_id BEFORE INSERT ON public.acorn_hotel_task_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_created_by_user_id();


--
-- Name: acorn_hotel_tasks tr_acorn_created_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_created_by_user_id BEFORE INSERT ON public.acorn_hotel_tasks FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_created_by_user_id();


--
-- Name: acorn_location_address_types tr_acorn_location_address_types_new_replicated_row; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_address_types_new_replicated_row BEFORE INSERT ON public.acorn_location_address_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_new_replicated_row();

ALTER TABLE public.acorn_location_address_types ENABLE ALWAYS TRIGGER tr_acorn_location_address_types_new_replicated_row;


--
-- Name: acorn_location_address_types tr_acorn_location_address_types_server_id; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_location_address_types_server_id BEFORE INSERT ON public.acorn_location_address_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


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
-- Name: acorn_hotel_item_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_hotel_item_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_hotel_places tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_hotel_places FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_hotel_room_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_hotel_room_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_hotel_stage_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_hotel_stage_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_hotel_stages tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_hotel_stages FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_hotel_task_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_hotel_task_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_hotel_tasks tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_hotel_tasks FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_hotel_item_types tr_acorn_updated_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_updated_by_user_id BEFORE UPDATE ON public.acorn_hotel_item_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_updated_by_user_id();


--
-- Name: acorn_hotel_places tr_acorn_updated_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_updated_by_user_id BEFORE UPDATE ON public.acorn_hotel_places FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_updated_by_user_id();


--
-- Name: acorn_hotel_room_types tr_acorn_updated_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_updated_by_user_id BEFORE UPDATE ON public.acorn_hotel_room_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_updated_by_user_id();


--
-- Name: acorn_hotel_stage_types tr_acorn_updated_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_updated_by_user_id BEFORE UPDATE ON public.acorn_hotel_stage_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_updated_by_user_id();


--
-- Name: acorn_hotel_stages tr_acorn_updated_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_updated_by_user_id BEFORE UPDATE ON public.acorn_hotel_stages FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_updated_by_user_id();


--
-- Name: acorn_hotel_task_types tr_acorn_updated_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_updated_by_user_id BEFORE UPDATE ON public.acorn_hotel_task_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_updated_by_user_id();


--
-- Name: acorn_hotel_tasks tr_acorn_updated_by_user_id; Type: TRIGGER; Schema: public; Owner: hotel
--

CREATE TRIGGER tr_acorn_updated_by_user_id BEFORE UPDATE ON public.acorn_hotel_tasks FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_updated_by_user_id();


--
-- Name: acorn_user_user_groups tr_acorn_user_user_group_first_version; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_user_user_group_first_version AFTER INSERT ON public.acorn_user_user_groups FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_user_user_group_first_version();


--
-- Name: acorn_user_user_group_versions tr_acorn_user_user_group_version_current; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_user_user_group_version_current BEFORE INSERT OR UPDATE ON public.acorn_user_user_group_versions FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_user_user_group_version_current();


--
-- Name: acorn_user_user_languages tr_acorn_user_user_languages_current; Type: TRIGGER; Schema: public; Owner: university
--

CREATE TRIGGER tr_acorn_user_user_languages_current AFTER INSERT OR UPDATE ON public.acorn_user_user_languages FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_user_user_languages_current();


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
-- Name: acorn_calendar_event_parts acorn_calendar_event_parts_user_group_version_id_fore; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_calendar_event_parts
    ADD CONSTRAINT acorn_calendar_event_parts_user_group_version_id_fore FOREIGN KEY (user_group_version_id) REFERENCES public.acorn_user_user_group_versions(id) ON DELETE CASCADE NOT VALID;


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
-- Name: acorn_user_user_languages acorn_user_language_user_language_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_languages
    ADD CONSTRAINT acorn_user_language_user_language_id_foreign FOREIGN KEY (language_id) REFERENCES public.acorn_user_languages(id) ON DELETE CASCADE;


--
-- Name: acorn_user_user_languages acorn_user_language_user_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_languages
    ADD CONSTRAINT acorn_user_language_user_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE;


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
-- Name: acorn_location_user_addresses address_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_user_addresses
    ADD CONSTRAINT address_id FOREIGN KEY (address_id) REFERENCES public.acorn_location_addresses(id) NOT VALID;


--
-- Name: acorn_location_user_addresses address_type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_user_addresses
    ADD CONSTRAINT address_type_id FOREIGN KEY (address_type_id) REFERENCES public.acorn_location_address_types(id) NOT VALID;


--
-- Name: acorn_location_address_types addresses_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_address_types
    ADD CONSTRAINT addresses_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_location_addresses addresses_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT addresses_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_hotel_rooms area_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_rooms
    ADD CONSTRAINT area_id FOREIGN KEY (area_id) REFERENCES public.acorn_hotel_areas(id) ON DELETE CASCADE NOT VALID;


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
-- Name: acorn_hotel_floors building_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_floors
    ADD CONSTRAINT building_id FOREIGN KEY (building_id) REFERENCES public.acorn_hotel_buildings(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_item_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_item_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_places created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_places
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_room_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_room_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_stage_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_stage_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_stages created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_stages
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_task_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_task_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_tasks created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_tasks
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_user_users ethnicity_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT ethnicity_id FOREIGN KEY (ethnicity_id) REFERENCES public.acorn_user_ethnicities(id) ON DELETE SET NULL NOT VALID;


--
-- Name: acorn_hotel_tasks event_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_tasks
    ADD CONSTRAINT event_id FOREIGN KEY (event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT event_id ON acorn_hotel_tasks; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON CONSTRAINT event_id ON public.acorn_hotel_tasks IS '# Unique but we want the last-start field only
# type: 1toX';


--
-- Name: acorn_hotel_areas floor_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_areas
    ADD CONSTRAINT floor_id FOREIGN KEY (floor_id) REFERENCES public.acorn_hotel_floors(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_location_gps gps_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_gps
    ADD CONSTRAINT gps_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_location_addresses gps_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_addresses
    ADD CONSTRAINT gps_id FOREIGN KEY (gps_id) REFERENCES public.acorn_location_gps(id) NOT VALID;


--
-- Name: acorn_location_areas gps_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT gps_id FOREIGN KEY (gps_id) REFERENCES public.acorn_location_gps(id);


--
-- Name: acorn_hotel_tasks item_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_tasks
    ADD CONSTRAINT item_id FOREIGN KEY (item_id) REFERENCES public.acorn_hotel_items(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_items item_type_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_items
    ADD CONSTRAINT item_type_id FOREIGN KEY (item_type_id) REFERENCES public.acorn_hotel_item_types(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT item_type_id ON acorn_hotel_items; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON CONSTRAINT item_type_id ON public.acorn_hotel_items IS 'name-object: true';


--
-- Name: acorn_location_user_group_location location_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_user_group_location
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
-- Name: acorn_location_areas parent_area_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_areas
    ADD CONSTRAINT parent_area_id FOREIGN KEY (parent_id) REFERENCES public.acorn_location_areas(id) NOT VALID;


--
-- Name: acorn_location_types parent_type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT parent_type_id FOREIGN KEY (parent_type_id) REFERENCES public.acorn_location_types(id);


--
-- Name: acorn_hotel_areas place_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_areas
    ADD CONSTRAINT place_id FOREIGN KEY (place_id) REFERENCES public.acorn_hotel_places(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT place_id ON acorn_hotel_areas; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON CONSTRAINT place_id ON public.acorn_hotel_areas IS 'name-object: true';


--
-- Name: acorn_hotel_buildings place_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_buildings
    ADD CONSTRAINT place_id FOREIGN KEY (place_id) REFERENCES public.acorn_hotel_places(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT place_id ON acorn_hotel_buildings; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON CONSTRAINT place_id ON public.acorn_hotel_buildings IS 'name-object: true';


--
-- Name: acorn_hotel_floors place_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_floors
    ADD CONSTRAINT place_id FOREIGN KEY (place_id) REFERENCES public.acorn_hotel_places(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT place_id ON acorn_hotel_floors; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON CONSTRAINT place_id ON public.acorn_hotel_floors IS 'name-object: true';


--
-- Name: acorn_hotel_items place_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_items
    ADD CONSTRAINT place_id FOREIGN KEY (place_id) REFERENCES public.acorn_hotel_places(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT place_id ON acorn_hotel_items; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON CONSTRAINT place_id ON public.acorn_hotel_items IS 'name-object: true';


--
-- Name: acorn_hotel_rooms place_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_rooms
    ADD CONSTRAINT place_id FOREIGN KEY (place_id) REFERENCES public.acorn_hotel_places(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT place_id ON acorn_hotel_rooms; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON CONSTRAINT place_id ON public.acorn_hotel_rooms IS 'name-object: true';


--
-- Name: acorn_user_users religion_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_users
    ADD CONSTRAINT religion_id FOREIGN KEY (religion_id) REFERENCES public.acorn_user_religions(id) ON DELETE SET NULL NOT VALID;


--
-- Name: acorn_user_role_user role_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_role_user
    ADD CONSTRAINT role_id FOREIGN KEY (role_id) REFERENCES public.acorn_user_roles(id);


--
-- Name: acorn_hotel_rooms room_type_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_rooms
    ADD CONSTRAINT room_type_id FOREIGN KEY (room_type_id) REFERENCES public.acorn_hotel_room_types(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_item_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_item_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_places server_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_places
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_room_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_room_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_stage_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_stage_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_stages server_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_stages
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_task_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_task_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_tasks server_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_tasks
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_location_address_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_address_types
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
-- Name: acorn_location_gps server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_gps
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_locations server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_location_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_hotel_stages stage_type_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_stages
    ADD CONSTRAINT stage_type_id FOREIGN KEY (stage_type_id) REFERENCES public.acorn_hotel_stage_types(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT stage_type_id ON acorn_hotel_stages; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON CONSTRAINT stage_type_id ON public.acorn_hotel_stages IS 'name-object: true';


--
-- Name: acorn_hotel_stages task_type_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_stages
    ADD CONSTRAINT task_type_id FOREIGN KEY (task_type_id) REFERENCES public.acorn_hotel_task_types(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_tasks task_type_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_tasks
    ADD CONSTRAINT task_type_id FOREIGN KEY (task_type_id) REFERENCES public.acorn_hotel_task_types(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT task_type_id ON acorn_hotel_tasks; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON CONSTRAINT task_type_id ON public.acorn_hotel_tasks IS 'name-object: true';


--
-- Name: acorn_location_locations type_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_locations
    ADD CONSTRAINT type_id FOREIGN KEY (type_id) REFERENCES public.acorn_location_types(id) NOT VALID;


--
-- Name: acorn_location_types types_created_by_user; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_types
    ADD CONSTRAINT types_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_hotel_item_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_item_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_places updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_places
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_room_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_room_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_stage_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_stage_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_stages updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_stages
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_task_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_task_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_tasks updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_tasks
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_location_user_group_location user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_user_group_location
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_user_user_group user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) NOT VALID;


--
-- Name: acorn_user_user_group_versions user_group_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_versions
    ADD CONSTRAINT user_group_id FOREIGN KEY (user_group_id) REFERENCES public.acorn_user_user_groups(id) ON DELETE CASCADE;


--
-- Name: acorn_user_user_group_version user_group_version_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_version
    ADD CONSTRAINT user_group_version_id FOREIGN KEY (user_group_version_id) REFERENCES public.acorn_user_user_group_versions(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_hotel_people user_id; Type: FK CONSTRAINT; Schema: public; Owner: hotel
--

ALTER TABLE ONLY public.acorn_hotel_people
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT user_id ON acorn_hotel_people; Type: COMMENT; Schema: public; Owner: hotel
--

COMMENT ON CONSTRAINT user_id ON public.acorn_hotel_people IS 'name-object: true';


--
-- Name: acorn_location_user_addresses user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_location_user_addresses
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_user_role_user user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_role_user
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_user_user_group user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: acorn_user_user_group_version user_id; Type: FK CONSTRAINT; Schema: public; Owner: university
--

ALTER TABLE ONLY public.acorn_user_user_group_version
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id) ON DELETE CASCADE NOT VALID;


--
-- Name: TABLE acorn_calendar_calendars; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_calendars TO PUBLIC;


--
-- Name: TABLE acorn_calendar_event_part_user; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_part_user TO PUBLIC;


--
-- Name: TABLE acorn_calendar_event_part_user_group; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_part_user_group TO PUBLIC;


--
-- Name: TABLE acorn_calendar_event_parts; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_parts TO PUBLIC;


--
-- Name: TABLE acorn_calendar_event_statuses; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_statuses TO PUBLIC;


--
-- Name: TABLE acorn_calendar_event_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_event_types TO PUBLIC;


--
-- Name: TABLE acorn_calendar_events; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_events TO PUBLIC;


--
-- Name: TABLE acorn_calendar_instances; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_calendar_instances TO PUBLIC;


--
-- Name: TABLE acorn_calendar_linked_calendars; Type: ACL; Schema: public; Owner: createsystem
--

GRANT ALL ON TABLE public.acorn_calendar_linked_calendars TO PUBLIC;


--
-- Name: TABLE acorn_hotel_tasks; Type: ACL; Schema: public; Owner: hotel
--

GRANT ALL ON TABLE public.acorn_hotel_tasks TO PUBLIC;


--
-- Name: TABLE acorn_calendar_linked_events; Type: ACL; Schema: public; Owner: createsystem
--

GRANT ALL ON TABLE public.acorn_calendar_linked_events TO PUBLIC;


--
-- Name: TABLE acorn_hotel_item_types; Type: ACL; Schema: public; Owner: hotel
--

GRANT ALL ON TABLE public.acorn_hotel_item_types TO PUBLIC;


--
-- Name: TABLE acorn_hotel_room_types; Type: ACL; Schema: public; Owner: hotel
--

GRANT ALL ON TABLE public.acorn_hotel_room_types TO PUBLIC;


--
-- Name: TABLE acorn_hotel_stage_types; Type: ACL; Schema: public; Owner: hotel
--

GRANT ALL ON TABLE public.acorn_hotel_stage_types TO PUBLIC;


--
-- Name: TABLE acorn_hotel_stages; Type: ACL; Schema: public; Owner: hotel
--

GRANT ALL ON TABLE public.acorn_hotel_stages TO PUBLIC;


--
-- Name: TABLE acorn_hotel_task_types; Type: ACL; Schema: public; Owner: hotel
--

GRANT ALL ON TABLE public.acorn_hotel_task_types TO PUBLIC;


--
-- Name: TABLE acorn_created_bys; Type: ACL; Schema: public; Owner: createsystem
--

GRANT ALL ON TABLE public.acorn_created_bys TO PUBLIC;


--
-- Name: TABLE acorn_user_users; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_users TO PUBLIC;


--
-- Name: TABLE backend_users; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_users TO PUBLIC;


--
-- Name: TABLE acorn_dbauth_user; Type: ACL; Schema: public; Owner: anewholm
--

GRANT ALL ON TABLE public.acorn_dbauth_user TO PUBLIC;


--
-- Name: TABLE acorn_hotel_areas; Type: ACL; Schema: public; Owner: hotel
--

GRANT ALL ON TABLE public.acorn_hotel_areas TO PUBLIC;


--
-- Name: TABLE acorn_hotel_floors; Type: ACL; Schema: public; Owner: hotel
--

GRANT ALL ON TABLE public.acorn_hotel_floors TO PUBLIC;


--
-- Name: TABLE acorn_hotel_items; Type: ACL; Schema: public; Owner: hotel
--

GRANT ALL ON TABLE public.acorn_hotel_items TO PUBLIC;


--
-- Name: TABLE acorn_hotel_people; Type: ACL; Schema: public; Owner: hotel
--

GRANT ALL ON TABLE public.acorn_hotel_people TO PUBLIC;


--
-- Name: TABLE acorn_hotel_rooms; Type: ACL; Schema: public; Owner: hotel
--

GRANT ALL ON TABLE public.acorn_hotel_rooms TO PUBLIC;


--
-- Name: TABLE acorn_location_locations; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_locations TO PUBLIC;


--
-- Name: TABLE acorn_location_user_addresses; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_user_addresses TO PUBLIC;


--
-- Name: TABLE acorn_location_address_links; Type: ACL; Schema: public; Owner: createsystem
--

GRANT ALL ON TABLE public.acorn_location_address_links TO PUBLIC;


--
-- Name: TABLE acorn_location_address_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_address_types TO PUBLIC;


--
-- Name: TABLE acorn_location_addresses; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_addresses TO PUBLIC;


--
-- Name: TABLE acorn_location_area_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_area_types TO PUBLIC;


--
-- Name: TABLE acorn_location_areas; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_areas TO PUBLIC;


--
-- Name: TABLE acorn_location_gps; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_gps TO PUBLIC;


--
-- Name: TABLE acorn_location_user_group_location; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_user_group_location TO PUBLIC;


--
-- Name: TABLE acorn_servers; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_servers TO PUBLIC;


--
-- Name: TABLE acorn_location_location_links; Type: ACL; Schema: public; Owner: createsystem
--

GRANT ALL ON TABLE public.acorn_location_location_links TO PUBLIC;


--
-- Name: TABLE acorn_location_lookup; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_lookup TO PUBLIC;


--
-- Name: TABLE acorn_location_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_location_types TO PUBLIC;


--
-- Name: TABLE acorn_messaging_action; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_action TO PUBLIC;


--
-- Name: TABLE acorn_messaging_label; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_label TO PUBLIC;


--
-- Name: TABLE acorn_messaging_message; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message TO PUBLIC;


--
-- Name: TABLE acorn_messaging_message_instance; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_instance TO PUBLIC;


--
-- Name: TABLE acorn_messaging_message_message; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_message TO PUBLIC;


--
-- Name: TABLE acorn_messaging_message_user; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_user TO PUBLIC;


--
-- Name: TABLE acorn_messaging_message_user_group; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_message_user_group TO PUBLIC;


--
-- Name: TABLE acorn_messaging_status; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_status TO PUBLIC;


--
-- Name: TABLE acorn_messaging_user_message_status; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_messaging_user_message_status TO PUBLIC;


--
-- Name: TABLE acorn_reporting_reports; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_reporting_reports TO PUBLIC;


--
-- Name: SEQUENCE acorn_reporting_reports_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.acorn_reporting_reports_id_seq TO PUBLIC;


--
-- Name: TABLE acorn_user_ethnicities; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_ethnicities TO PUBLIC;


--
-- Name: TABLE acorn_user_languages; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_languages TO PUBLIC;


--
-- Name: TABLE acorn_user_mail_blockers; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_mail_blockers TO PUBLIC;


--
-- Name: TABLE acorn_user_religions; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_religions TO PUBLIC;


--
-- Name: TABLE acorn_user_role_user; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_role_user TO PUBLIC;


--
-- Name: TABLE acorn_user_roles; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_roles TO PUBLIC;


--
-- Name: TABLE acorn_user_throttle; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_throttle TO PUBLIC;


--
-- Name: TABLE acorn_user_user_group; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group TO PUBLIC;


--
-- Name: TABLE acorn_user_user_group_types; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group_types TO PUBLIC;


--
-- Name: TABLE acorn_user_user_group_version; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group_version TO PUBLIC;


--
-- Name: TABLE acorn_user_user_group_version_usages; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group_version_usages TO PUBLIC;


--
-- Name: TABLE acorn_user_user_group_versions; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_group_versions TO PUBLIC;


--
-- Name: TABLE acorn_user_user_groups; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_groups TO PUBLIC;


--
-- Name: TABLE acorn_user_user_languages; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.acorn_user_user_languages TO PUBLIC;


--
-- Name: TABLE backend_access_log; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_access_log TO PUBLIC;


--
-- Name: SEQUENCE backend_access_log_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_access_log_id_seq TO PUBLIC;


--
-- Name: TABLE backend_user_groups; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_groups TO PUBLIC;


--
-- Name: SEQUENCE backend_user_groups_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_groups_id_seq TO PUBLIC;


--
-- Name: TABLE backend_user_preferences; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_preferences TO PUBLIC;


--
-- Name: SEQUENCE backend_user_preferences_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_preferences_id_seq TO PUBLIC;


--
-- Name: TABLE backend_user_roles; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_roles TO PUBLIC;


--
-- Name: SEQUENCE backend_user_roles_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_roles_id_seq TO PUBLIC;


--
-- Name: TABLE backend_user_throttle; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_user_throttle TO PUBLIC;


--
-- Name: SEQUENCE backend_user_throttle_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_user_throttle_id_seq TO PUBLIC;


--
-- Name: TABLE backend_users_groups; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.backend_users_groups TO PUBLIC;


--
-- Name: SEQUENCE backend_users_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.backend_users_id_seq TO PUBLIC;


--
-- Name: TABLE cache; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cache TO PUBLIC;


--
-- Name: TABLE cms_theme_data; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cms_theme_data TO PUBLIC;


--
-- Name: SEQUENCE cms_theme_data_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.cms_theme_data_id_seq TO PUBLIC;


--
-- Name: TABLE cms_theme_logs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cms_theme_logs TO PUBLIC;


--
-- Name: SEQUENCE cms_theme_logs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.cms_theme_logs_id_seq TO PUBLIC;


--
-- Name: TABLE cms_theme_templates; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.cms_theme_templates TO PUBLIC;


--
-- Name: SEQUENCE cms_theme_templates_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.cms_theme_templates_id_seq TO PUBLIC;


--
-- Name: TABLE deferred_bindings; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.deferred_bindings TO PUBLIC;


--
-- Name: SEQUENCE deferred_bindings_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.deferred_bindings_id_seq TO PUBLIC;


--
-- Name: TABLE failed_jobs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.failed_jobs TO PUBLIC;


--
-- Name: SEQUENCE failed_jobs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.failed_jobs_id_seq TO PUBLIC;


--
-- Name: TABLE job_batches; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.job_batches TO PUBLIC;


--
-- Name: TABLE jobs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.jobs TO PUBLIC;


--
-- Name: SEQUENCE jobs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.jobs_id_seq TO PUBLIC;


--
-- Name: TABLE migrations; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.migrations TO PUBLIC;


--
-- Name: SEQUENCE migrations_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.migrations_id_seq TO PUBLIC;


--
-- Name: TABLE winter_location_countries; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_location_countries TO PUBLIC;


--
-- Name: SEQUENCE rainlab_location_countries_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_location_countries_id_seq TO PUBLIC;


--
-- Name: TABLE winter_location_states; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_location_states TO PUBLIC;


--
-- Name: SEQUENCE rainlab_location_states_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_location_states_id_seq TO PUBLIC;


--
-- Name: TABLE winter_translate_attributes; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_attributes TO PUBLIC;


--
-- Name: SEQUENCE rainlab_translate_attributes_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_attributes_id_seq TO PUBLIC;


--
-- Name: TABLE winter_translate_indexes; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_indexes TO PUBLIC;


--
-- Name: SEQUENCE rainlab_translate_indexes_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_indexes_id_seq TO PUBLIC;


--
-- Name: TABLE winter_translate_locales; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_locales TO PUBLIC;


--
-- Name: SEQUENCE rainlab_translate_locales_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_locales_id_seq TO PUBLIC;


--
-- Name: TABLE winter_translate_messages; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.winter_translate_messages TO PUBLIC;


--
-- Name: SEQUENCE rainlab_translate_messages_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.rainlab_translate_messages_id_seq TO PUBLIC;


--
-- Name: TABLE sessions; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.sessions TO PUBLIC;


--
-- Name: TABLE system_event_logs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_event_logs TO PUBLIC;


--
-- Name: SEQUENCE system_event_logs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_event_logs_id_seq TO PUBLIC;


--
-- Name: TABLE system_files; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_files TO PUBLIC;


--
-- Name: SEQUENCE system_files_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_files_id_seq TO PUBLIC;


--
-- Name: TABLE system_mail_layouts; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_mail_layouts TO PUBLIC;


--
-- Name: SEQUENCE system_mail_layouts_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_mail_layouts_id_seq TO PUBLIC;


--
-- Name: TABLE system_mail_partials; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_mail_partials TO PUBLIC;


--
-- Name: SEQUENCE system_mail_partials_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_mail_partials_id_seq TO PUBLIC;


--
-- Name: TABLE system_mail_templates; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_mail_templates TO PUBLIC;


--
-- Name: SEQUENCE system_mail_templates_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_mail_templates_id_seq TO PUBLIC;


--
-- Name: TABLE system_parameters; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_parameters TO PUBLIC;


--
-- Name: SEQUENCE system_parameters_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_parameters_id_seq TO PUBLIC;


--
-- Name: TABLE system_plugin_history; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_plugin_history TO PUBLIC;


--
-- Name: SEQUENCE system_plugin_history_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_plugin_history_id_seq TO PUBLIC;


--
-- Name: TABLE system_plugin_versions; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_plugin_versions TO PUBLIC;


--
-- Name: SEQUENCE system_plugin_versions_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_plugin_versions_id_seq TO PUBLIC;


--
-- Name: TABLE system_request_logs; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_request_logs TO PUBLIC;


--
-- Name: SEQUENCE system_request_logs_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_request_logs_id_seq TO PUBLIC;


--
-- Name: TABLE system_revisions; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_revisions TO PUBLIC;


--
-- Name: SEQUENCE system_revisions_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_revisions_id_seq TO PUBLIC;


--
-- Name: TABLE system_settings; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON TABLE public.system_settings TO PUBLIC;


--
-- Name: SEQUENCE system_settings_id_seq; Type: ACL; Schema: public; Owner: university
--

GRANT ALL ON SEQUENCE public.system_settings_id_seq TO PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict 0fsia21S2c3QCRf8vuZrT00kp8sj4lZVgcoBHaHuxIUcFkgmycyhQ4Zv9RDXIEX

