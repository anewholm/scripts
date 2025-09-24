--
-- PostgreSQL database dump
--

\restrict hZqdKKVyspUjT1D6XBhh1nOTpUth2g2Q8eUw8NuBe3rJbIU2F2ogS1OhbF6vcas

-- Dumped from database version 16.10 (Ubuntu 16.10-1.pgdg24.04+1)
-- Dumped by pg_dump version 16.10 (Ubuntu 16.10-1.pgdg24.04+1)

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

DROP POLICY IF EXISTS "IsSuperUser" ON public.acorn_criminal_legalcases;
DROP POLICY IF EXISTS "IsInOwnerGroup" ON public.acorn_criminal_legalcases;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_warehouses DROP CONSTRAINT IF EXISTS warehouses_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicles DROP CONSTRAINT IF EXISTS vehicles_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicle_types DROP CONSTRAINT IF EXISTS vehicle_types_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicles DROP CONSTRAINT IF EXISTS vehicle_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_drivers DROP CONSTRAINT IF EXISTS vehicle_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfers DROP CONSTRAINT IF EXISTS vehicle_id;
ALTER TABLE IF EXISTS ONLY public.acorn_notary_requests DROP CONSTRAINT IF EXISTS validated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_notary_requests DROP CONSTRAINT IF EXISTS validated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_employees DROP CONSTRAINT IF EXISTS user_role_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_statements DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summons DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_version_user DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrants DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_people DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_language_user DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_judges DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_witnesses DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_plaintiffs DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_prosecutor DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_defendants DROP CONSTRAINT IF EXISTS user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_version_user DROP CONSTRAINT IF EXISTS user_group_version_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_versions DROP CONSTRAINT IF EXISTS user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_judges DROP CONSTRAINT IF EXISTS user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_prosecutor DROP CONSTRAINT IF EXISTS user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_periods DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_periods DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_witness_statement DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_statements DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summons DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summon_types DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_notary_requests DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_drivers DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_containers DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_receipts DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrant_types DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_categories DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_types DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_currencies DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_crimes DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_reasons DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_methods DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_payments DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_attributes DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_brands DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_warehouses DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicles DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicle_types DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfers DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrants DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_scanned_documents DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_suppliers DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_products DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instances DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_category_types DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_categories DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_purchases DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_measurement_units DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_offices DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_employees DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_sentence_types DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_sentences DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_types DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crimes DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_session_recordings DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_judges DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_defendants DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_witnesses DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_evidence DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_plaintiffs DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcases DROP CONSTRAINT IF EXISTS updated_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_periods DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_periods DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_witness_statement DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_statements DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summons DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summon_types DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_notary_requests DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_containers DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_receipts DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrant_types DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_categories DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_types DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_currencies DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_reasons DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_methods DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_crimes DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_payments DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_brands DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_warehouses DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicles DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicle_types DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfers DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrants DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_suppliers DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_scanned_documents DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_products DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instances DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_category_types DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_categories DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_attributes DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_purchases DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_measurement_units DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_offices DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_employees DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_drivers DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_sentence_types DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_sentences DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crimes DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_session_recordings DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_judges DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_defendants DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_witnesses DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_evidence DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_plaintiffs DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_legalcase_category DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_prosecutor DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_types DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcases DROP CONSTRAINT IF EXISTS updated_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_types DROP CONSTRAINT IF EXISTS types_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summons DROP CONSTRAINT IF EXISTS type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrants DROP CONSTRAINT IF EXISTS type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_groups DROP CONSTRAINT IF EXISTS type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_locations DROP CONSTRAINT IF EXISTS type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_session_recordings DROP CONSTRAINT IF EXISTS trial_session_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_sessions DROP CONSTRAINT IF EXISTS trial_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_judges DROP CONSTRAINT IF EXISTS trial_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfers DROP CONSTRAINT IF EXISTS transfers_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_detentions DROP CONSTRAINT IF EXISTS transfer_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_purchase DROP CONSTRAINT IF EXISTS transfer_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_invoice DROP CONSTRAINT IF EXISTS transfer_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_containers DROP CONSTRAINT IF EXISTS transfer_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instance_transfer DROP CONSTRAINT IF EXISTS transfer_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_container_product_instance DROP CONSTRAINT IF EXISTS transfer_container_product_instances_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_container_product_instance DROP CONSTRAINT IF EXISTS transfer_container_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_containers DROP CONSTRAINT IF EXISTS transfer_container_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_suppliers DROP CONSTRAINT IF EXISTS suppliers_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_products DROP CONSTRAINT IF EXISTS sub_product_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_witness_statement DROP CONSTRAINT IF EXISTS statement_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_periods DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_periods DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_statements DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summons DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summon_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_notary_requests DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_product_category DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_receipts DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrant_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_categories DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_currencies DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_crimes DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_reasons DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_methods DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_payments DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrants DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_scanned_documents DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_purchases DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_sentence_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_sentences DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crimes DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_session_recordings DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_judges DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_defendants DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_witnesses DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_evidence DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_plaintiffs DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcases DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_products DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_suppliers DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_warehouses DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instances DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_attributes DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_offices DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_employees DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_brands DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfers DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products_product_category DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_categories DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_category_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_container_product_instance DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_containers DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_drivers DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicles DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_containers DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicle_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_people DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instance_transfer DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_measurement_units DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcases DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_area_types DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_addresses DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_gps DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_locations DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_sentences DROP CONSTRAINT IF EXISTS sentence_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfers DROP CONSTRAINT IF EXISTS sent_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_version_user DROP CONSTRAINT IF EXISTS role_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summons DROP CONSTRAINT IF EXISTS revoked_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrants DROP CONSTRAINT IF EXISTS revoked_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_detentions DROP CONSTRAINT IF EXISTS reason_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_purchase DROP CONSTRAINT IF EXISTS purchase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_receipts DROP CONSTRAINT IF EXISTS purchase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_product_category DROP CONSTRAINT IF EXISTS products_product_categories_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products_product_category DROP CONSTRAINT IF EXISTS products_product_categories_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products DROP CONSTRAINT IF EXISTS products_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_products DROP CONSTRAINT IF EXISTS product_products_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instances DROP CONSTRAINT IF EXISTS product_instances_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_container_product_instance DROP CONSTRAINT IF EXISTS product_instance_transfer_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instance_transfer DROP CONSTRAINT IF EXISTS product_instance_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_product_category DROP CONSTRAINT IF EXISTS product_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_attributes DROP CONSTRAINT IF EXISTS product_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_products DROP CONSTRAINT IF EXISTS product_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instances DROP CONSTRAINT IF EXISTS product_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products_product_category DROP CONSTRAINT IF EXISTS product_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_category_types DROP CONSTRAINT IF EXISTS product_category_types_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_categories DROP CONSTRAINT IF EXISTS product_category_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_product_category DROP CONSTRAINT IF EXISTS product_category_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products_product_category DROP CONSTRAINT IF EXISTS product_category_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_categories DROP CONSTRAINT IF EXISTS product_categories_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_attributes DROP CONSTRAINT IF EXISTS product_attributes_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_employees DROP CONSTRAINT IF EXISTS person_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_drivers DROP CONSTRAINT IF EXISTS person_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_periods DROP CONSTRAINT IF EXISTS period_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_people DROP CONSTRAINT IF EXISTS people_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS payer_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_purchases DROP CONSTRAINT IF EXISTS payer_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS payer_user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_purchases DROP CONSTRAINT IF EXISTS payer_user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_purchases DROP CONSTRAINT IF EXISTS payee_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS payee_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_purchases DROP CONSTRAINT IF EXISTS payee_user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS payee_user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_types DROP CONSTRAINT IF EXISTS parent_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_categories DROP CONSTRAINT IF EXISTS parent_product_category_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_categories DROP CONSTRAINT IF EXISTS parent_legalcase_category_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_types DROP CONSTRAINT IF EXISTS parent_crime_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS parent_area_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcases DROP CONSTRAINT IF EXISTS owner_user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_offices DROP CONSTRAINT IF EXISTS offices_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summons DROP CONSTRAINT IF EXISTS notary_request_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrants DROP CONSTRAINT IF EXISTS notary_request_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_detentions DROP CONSTRAINT IF EXISTS method_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_measurement_units DROP CONSTRAINT IF EXISTS measurement_units_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products DROP CONSTRAINT IF EXISTS measurement_unit_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_locations DROP CONSTRAINT IF EXISTS locations_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_groups DROP CONSTRAINT IF EXISTS location_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_warehouses DROP CONSTRAINT IF EXISTS location_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfers DROP CONSTRAINT IF EXISTS location_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_suppliers DROP CONSTRAINT IF EXISTS location_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_offices DROP CONSTRAINT IF EXISTS location_id;
ALTER TABLE IF EXISTS ONLY public.acorn_servers DROP CONSTRAINT IF EXISTS location_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_witness_statement DROP CONSTRAINT IF EXISTS legalcase_witness_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcases DROP CONSTRAINT IF EXISTS legalcase_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_statements DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summons DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_related_events DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrants DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_scanned_documents DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trials DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_witnesses DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_plaintiffs DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_prosecutor DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_evidence DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_defendants DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_appeals DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcases DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_legalcase_category DROP CONSTRAINT IF EXISTS legalcase_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_evidence DROP CONSTRAINT IF EXISTS legalcase_evidence_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_detentions DROP CONSTRAINT IF EXISTS legalcase_defendant_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_crimes DROP CONSTRAINT IF EXISTS legalcase_defendant_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_legalcase_category DROP CONSTRAINT IF EXISTS legalcase_category_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_plaintiffs DROP CONSTRAINT IF EXISTS lawyer_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_defendants DROP CONSTRAINT IF EXISTS lawyer_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_people DROP CONSTRAINT IF EXISTS last_transfer_location_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_people DROP CONSTRAINT IF EXISTS last_product_instance_location_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_language_user DROP CONSTRAINT IF EXISTS language_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcases DROP CONSTRAINT IF EXISTS judge_committee_user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_invoice DROP CONSTRAINT IF EXISTS invoice_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_payments DROP CONSTRAINT IF EXISTS invoice_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_addresses DROP CONSTRAINT IF EXISTS gps_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS gps_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_gps DROP CONSTRAINT IF EXISTS gps_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_versions DROP CONSTRAINT IF EXISTS from_user_group_version_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_groups DROP CONSTRAINT IF EXISTS from_user_group_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_sessions DROP CONSTRAINT IF EXISTS event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_appeals DROP CONSTRAINT IF EXISTS event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trials DROP CONSTRAINT IF EXISTS event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_related_events DROP CONSTRAINT IF EXISTS event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_employees DROP CONSTRAINT IF EXISTS employees_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_drivers DROP CONSTRAINT IF EXISTS drivers_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfers DROP CONSTRAINT IF EXISTS driver_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_periods DROP CONSTRAINT IF EXISTS defendant_detention_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_sentences DROP CONSTRAINT IF EXISTS defendant_crime_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_evidence DROP CONSTRAINT IF EXISTS defendant_crime_id;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_groups DROP CONSTRAINT IF EXISTS default_group_version_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_receipts DROP CONSTRAINT IF EXISTS currency_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_purchases DROP CONSTRAINT IF EXISTS currency_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_payments DROP CONSTRAINT IF EXISTS currency_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS currency_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crimes DROP CONSTRAINT IF EXISTS crime_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_crimes DROP CONSTRAINT IF EXISTS crime_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_periods DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_periods DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_witness_statement DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_statements DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summons DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summon_types DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_notary_requests DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_receipts DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrant_types DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_categories DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_types DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_currencies DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_reasons DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_methods DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_payments DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_purchases DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_related_events DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrants DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_scanned_documents DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_session_recordings DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trials DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_sessions DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_witnesses DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_prosecutor DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_defendants DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_appeals DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_crimes DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_types DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crimes DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_evidence DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_plaintiffs DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_sentence_types DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_judges DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_sentences DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_legalcase_category DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcases DROP CONSTRAINT IF EXISTS created_by_user_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instance_transfer DROP CONSTRAINT IF EXISTS created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_periods DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_periods DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_witness_statement DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_statements DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summons DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summon_types DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_notary_requests DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_product_category DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_receipts DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrant_types DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_categories DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_types DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_currencies DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_reasons DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_methods DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_payments DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_purchases DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrants DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_products DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_suppliers DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_warehouses DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicles DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicle_types DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products_product_category DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_drivers DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instances DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instance_transfer DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_category_types DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_categories DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_attributes DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_containers DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_people DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_offices DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_measurement_units DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfers DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_employees DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_brands DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_containers DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_container_product_instance DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_scanned_documents DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_session_recordings DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trials DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_sessions DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_witnesses DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_prosecutor DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_defendants DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_appeals DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_crimes DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_types DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crimes DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_evidence DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_plaintiffs DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_sentence_types DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_judges DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_sentences DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_legalcase_category DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcases DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS created_at;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_containers DROP CONSTRAINT IF EXISTS containers_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_containers DROP CONSTRAINT IF EXISTS container_id;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcases DROP CONSTRAINT IF EXISTS closed_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_statuses DROP CONSTRAINT IF EXISTS calendar_id;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_types DROP CONSTRAINT IF EXISTS calendar_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_brands DROP CONSTRAINT IF EXISTS brands_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products DROP CONSTRAINT IF EXISTS brand_id;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfers DROP CONSTRAINT IF EXISTS arrived_at_event_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS areas_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_location_area_types DROP CONSTRAINT IF EXISTS area_types_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS area_type_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_addresses DROP CONSTRAINT IF EXISTS area_id;
ALTER TABLE IF EXISTS ONLY public.acorn_location_addresses DROP CONSTRAINT IF EXISTS addresses_created_by_user;
ALTER TABLE IF EXISTS ONLY public.acorn_location_locations DROP CONSTRAINT IF EXISTS address_id;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_detentions DROP CONSTRAINT IF EXISTS actual_release_transfer_id;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_user_message_status DROP CONSTRAINT IF EXISTS acorn_messaging_user_message_status_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_user_message_status DROP CONSTRAINT IF EXISTS acorn_messaging_user_message_status_status_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_user_message_status DROP CONSTRAINT IF EXISTS acorn_messaging_user_message_status_message_id_foreig;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_message_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user_group DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_group_user_group_id_fore;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user_group DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_group_message_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_instance DROP CONSTRAINT IF EXISTS acorn_messaging_message_instance_message_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_instance DROP CONSTRAINT IF EXISTS acorn_messaging_message_instance_instance_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_calendars DROP CONSTRAINT IF EXISTS acorn_calendar_owner_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_calendars DROP CONSTRAINT IF EXISTS acorn_calendar_owner_user_group_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_instances DROP CONSTRAINT IF EXISTS acorn_calendar_instance_event_part_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user DROP CONSTRAINT IF EXISTS acorn_calendar_event_user_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user DROP CONSTRAINT IF EXISTS acorn_calendar_event_user_role_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user_group DROP CONSTRAINT IF EXISTS acorn_calendar_event_user_group_user_group_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user_group DROP CONSTRAINT IF EXISTS acorn_calendar_event_user_group_event_part_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user DROP CONSTRAINT IF EXISTS acorn_calendar_event_user_event_part_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_type_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_status_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_parent_event_part_id_foreig;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_locked_by_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_event_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_events DROP CONSTRAINT IF EXISTS acorn_calendar_event_owner_user_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_events DROP CONSTRAINT IF EXISTS acorn_calendar_event_owner_user_group_id_foreign;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_events DROP CONSTRAINT IF EXISTS acorn_calendar_event_calendar_id_foreign;
ALTER TABLE IF EXISTS ONLY product.acorn_lojistiks_electronic_products DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY product.acorn_lojistiks_computer_products DROP CONSTRAINT IF EXISTS server_id;
ALTER TABLE IF EXISTS ONLY product.acorn_lojistiks_electronic_products DROP CONSTRAINT IF EXISTS product_id;
ALTER TABLE IF EXISTS ONLY product.acorn_lojistiks_electronic_products DROP CONSTRAINT IF EXISTS electronic_products_created_by_user;
ALTER TABLE IF EXISTS ONLY product.acorn_lojistiks_computer_products DROP CONSTRAINT IF EXISTS electronic_product_id;
ALTER TABLE IF EXISTS ONLY product.acorn_lojistiks_computer_products DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY product.acorn_lojistiks_electronic_products DROP CONSTRAINT IF EXISTS created_at_event_id;
ALTER TABLE IF EXISTS ONLY product.acorn_lojistiks_computer_products DROP CONSTRAINT IF EXISTS computer_products_created_by_user;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_notary_requests;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_justice_warrants;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_justice_warrant_types;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_justice_summons;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_justice_summon_types;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_justice_statements;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_justice_scanned_documents;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_justice_periods;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_justice_legalcases;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_justice_legalcase_categories;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_finance_receipts;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_finance_purchases;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_finance_payments;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_finance_invoices;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_finance_currencies;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_trial_judges;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_session_recordings;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_sentence_types;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_legalcases;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_legalcase_witnesses;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_legalcase_types;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_legalcase_plaintiffs;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_legalcase_evidence;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_legalcase_defendants;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_detention_reasons;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_detention_periods;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_detention_methods;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_defendant_crimes;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_crimes;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_crime_types;
DROP TRIGGER IF EXISTS tr_acorn_server_id ON public.acorn_criminal_crime_sentences;
DROP TRIGGER IF EXISTS tr_acorn_notary_trigger_validate ON public.acorn_notary_requests;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_warehouses_server_id ON public.acorn_lojistiks_warehouses;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_warehouses_new_replicated_row ON public.acorn_lojistiks_warehouses;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_vehicles_server_id ON public.acorn_lojistiks_vehicles;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_vehicles_new_replicated_row ON public.acorn_lojistiks_vehicles;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_vehicle_types_server_id ON public.acorn_lojistiks_vehicle_types;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_vehicle_types_new_replicated_row ON public.acorn_lojistiks_vehicle_types;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_transfers_server_id ON public.acorn_lojistiks_transfers;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_transfers_new_replicated_row ON public.acorn_lojistiks_transfers;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_transfer_container_server_id ON public.acorn_lojistiks_transfer_containers;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_transfer_container_product_instanc ON public.acorn_lojistiks_transfer_container_product_instance;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_transfer_container_new_replicated_ ON public.acorn_lojistiks_transfer_containers;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_suppliers_server_id ON public.acorn_lojistiks_suppliers;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_suppliers_new_replicated_row ON public.acorn_lojistiks_suppliers;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_products_server_id ON public.acorn_lojistiks_products;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_products_product_categories_server ON public.acorn_lojistiks_products_product_category;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_products_product_categories_server ON public.acorn_lojistiks_product_product_category;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_products_product_categories_new_re ON public.acorn_lojistiks_products_product_category;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_products_product_categories_new_re ON public.acorn_lojistiks_product_product_category;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_products_new_replicated_row ON public.acorn_lojistiks_products;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_products_server_id ON public.acorn_lojistiks_product_products;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_products_new_replicated_ro ON public.acorn_lojistiks_product_products;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_instances_server_id ON public.acorn_lojistiks_product_instances;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_instances_new_replicated_r ON public.acorn_lojistiks_product_instances;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_instance_transfer_server_i ON public.acorn_lojistiks_product_instance_transfer;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_instance_transfer_new_repl ON public.acorn_lojistiks_product_instance_transfer;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_category_types_server_id ON public.acorn_lojistiks_product_category_types;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_category_types_new_replica ON public.acorn_lojistiks_product_category_types;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_categories_server_id ON public.acorn_lojistiks_product_categories;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_categories_new_replicated_ ON public.acorn_lojistiks_product_categories;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_attributes_server_id ON public.acorn_lojistiks_product_attributes;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_product_attributes_new_replicated_ ON public.acorn_lojistiks_product_attributes;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_people_server_id ON public.acorn_lojistiks_people;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_people_new_replicated_row ON public.acorn_lojistiks_people;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_offices_server_id ON public.acorn_lojistiks_offices;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_offices_new_replicated_row ON public.acorn_lojistiks_offices;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_measurement_units_server_id ON public.acorn_lojistiks_measurement_units;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_measurement_units_new_replicated_r ON public.acorn_lojistiks_measurement_units;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_employees_server_id ON public.acorn_lojistiks_employees;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_employees_new_replicated_row ON public.acorn_lojistiks_employees;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_drivers_server_id ON public.acorn_lojistiks_drivers;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_drivers_new_replicated_row ON public.acorn_lojistiks_drivers;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_containers_server_id ON public.acorn_lojistiks_containers;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_containers_new_replicated_row ON public.acorn_lojistiks_containers;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_brands_server_id ON public.acorn_lojistiks_brands;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_brands_new_replicated_row ON public.acorn_lojistiks_brands;
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
DROP TRIGGER IF EXISTS tr_acorn_justice_legalcase_legalcase_category ON public.acorn_justice_legalcase_legalcase_category;
DROP TRIGGER IF EXISTS tr_acorn_justice_created_at_event ON public.acorn_justice_legalcases;
DROP TRIGGER IF EXISTS tr_acorn_criminal_witness_statement ON public.acorn_criminal_witness_statement;
DROP TRIGGER IF EXISTS tr_acorn_criminal_legalcase_prosecutor ON public.acorn_criminal_legalcase_prosecutor;
DROP TRIGGER IF EXISTS tr_acorn_criminal_crime_types ON public.acorn_criminal_crime_types;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_warehouses;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_vehicles;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_vehicle_types;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_transfers;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_suppliers;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_products;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_product_products;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_product_instances;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_product_category_types;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_product_categories;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_product_attributes;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_people;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_offices;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_measurement_units;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_employees;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_drivers;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_containers;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_lojistiks_brands;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_justice_warrants;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_justice_warrant_types;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_justice_summons;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_justice_summon_types;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_justice_statements;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_justice_scanned_documents;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_justice_legalcase_categories;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_finance_receipts;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_finance_purchases;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_finance_payments;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_finance_invoices;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_finance_currencies;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_trials;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_trial_sessions;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_trial_judges;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_session_recordings;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_sentence_types;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_legalcase_witnesses;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_legalcase_types;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_legalcase_plaintiffs;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_legalcase_evidence;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_legalcase_defendants;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_detention_reasons;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_detention_methods;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_defendant_crimes;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_crimes;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_crime_sentences;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON public.acorn_criminal_appeals;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_activity_event ON public.acorn_notary_requests;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_activity_event ON public.acorn_justice_periods;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_activity_event ON public.acorn_criminal_detention_periods;
DROP TRIGGER IF EXISTS tr_acorn_calendar_events_generate_event_instances ON public.acorn_calendar_event_parts;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_electronic_products_server_id ON product.acorn_lojistiks_electronic_products;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_electronic_products_new_replicated ON product.acorn_lojistiks_electronic_products;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_computer_products_server_id ON product.acorn_lojistiks_computer_products;
DROP TRIGGER IF EXISTS tr_acorn_lojistiks_computer_products_new_replicated_r ON product.acorn_lojistiks_computer_products;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON product.acorn_lojistiks_electronic_products;
DROP TRIGGER IF EXISTS tr_acorn_calendar_trigger_created_at_event ON product.acorn_lojistiks_computer_products;
DROP INDEX IF EXISTS public.winter_translate_messages_code_pre_2_1_0_index;
DROP INDEX IF EXISTS public.user_item_index;
DROP INDEX IF EXISTS public.system_settings_item_index;
DROP INDEX IF EXISTS public.system_revisions_user_id_index;
DROP INDEX IF EXISTS public.system_revisions_revisionable_id_revisionable_type_index;
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
DROP INDEX IF EXISTS public.rainlab_translate_messages_code_index;
DROP INDEX IF EXISTS public.rainlab_translate_locales_name_index;
DROP INDEX IF EXISTS public.rainlab_translate_locales_code_index;
DROP INDEX IF EXISTS public.rainlab_translate_indexes_model_type_index;
DROP INDEX IF EXISTS public.rainlab_translate_indexes_model_id_index;
DROP INDEX IF EXISTS public.rainlab_translate_indexes_locale_index;
DROP INDEX IF EXISTS public.rainlab_translate_indexes_item_index;
DROP INDEX IF EXISTS public.rainlab_translate_attributes_model_type_index;
DROP INDEX IF EXISTS public.rainlab_translate_attributes_model_id_index;
DROP INDEX IF EXISTS public.rainlab_translate_attributes_locale_index;
DROP INDEX IF EXISTS public.rainlab_location_states_name_index;
DROP INDEX IF EXISTS public.rainlab_location_states_country_id_index;
DROP INDEX IF EXISTS public.rainlab_location_countries_name_index;
DROP INDEX IF EXISTS public.jobs_queue_reserved_at_index;
DROP INDEX IF EXISTS public.item_index;
DROP INDEX IF EXISTS public.fki_validated_by_user_id;
DROP INDEX IF EXISTS public.fki_validated_at_event_id;
DROP INDEX IF EXISTS public.fki_user_id;
DROP INDEX IF EXISTS public.fki_user_group_version_id;
DROP INDEX IF EXISTS public.fki_user_group_id;
DROP INDEX IF EXISTS public.fki_updated_by_user_id;
DROP INDEX IF EXISTS public.fki_updated_at_event_id;
DROP INDEX IF EXISTS public.fki_type_id;
DROP INDEX IF EXISTS public.fki_trial_session_id;
DROP INDEX IF EXISTS public.fki_trial_id;
DROP INDEX IF EXISTS public.fki_transfer_id;
DROP INDEX IF EXISTS public.fki_summons_revoked_at_event_id;
DROP INDEX IF EXISTS public.fki_summons_notary_request_id;
DROP INDEX IF EXISTS public.fki_server_id;
DROP INDEX IF EXISTS public.fki_sentence_type_id;
DROP INDEX IF EXISTS public.fki_sent_at_event_id;
DROP INDEX IF EXISTS public.fki_role_id;
DROP INDEX IF EXISTS public.fki_revoked_at_event_id;
DROP INDEX IF EXISTS public.fki_reason_id;
DROP INDEX IF EXISTS public.fki_purchase_id;
DROP INDEX IF EXISTS public.fki_period_id;
DROP INDEX IF EXISTS public.fki_payee_user_id;
DROP INDEX IF EXISTS public.fki_payee_user_group_id;
DROP INDEX IF EXISTS public.fki_parent_product_category_id;
DROP INDEX IF EXISTS public.fki_parent_legalcase_category_id;
DROP INDEX IF EXISTS public.fki_owner_user_group_id;
DROP INDEX IF EXISTS public.fki_notary_request_id;
DROP INDEX IF EXISTS public.fki_method_id;
DROP INDEX IF EXISTS public.fki_location_id;
DROP INDEX IF EXISTS public.fki_legalcase_witness_id;
DROP INDEX IF EXISTS public.fki_legalcase_type_id;
DROP INDEX IF EXISTS public.fki_legalcase_id;
DROP INDEX IF EXISTS public.fki_legalcase_defendant_id;
DROP INDEX IF EXISTS public.fki_legalcase_category_id;
DROP INDEX IF EXISTS public.fki_lawyer_user_id;
DROP INDEX IF EXISTS public.fki_last_transfer_location_id;
DROP INDEX IF EXISTS public.fki_last_transfer_destination_location_id;
DROP INDEX IF EXISTS public.fki_last_product_instance_location_id;
DROP INDEX IF EXISTS public.fki_last_product_instance_destination_location_id;
DROP INDEX IF EXISTS public.fki_judge_committee_user_group_id;
DROP INDEX IF EXISTS public.fki_invoice_id;
DROP INDEX IF EXISTS public.fki_from_user_group_version_id;
DROP INDEX IF EXISTS public.fki_from_user_group_id;
DROP INDEX IF EXISTS public.fki_event_part_id;
DROP INDEX IF EXISTS public.fki_event_id;
DROP INDEX IF EXISTS public.fki_defendant_detention_id2;
DROP INDEX IF EXISTS public.fki_defendant_detention_id;
DROP INDEX IF EXISTS public.fki_defendant_crime_id;
DROP INDEX IF EXISTS public.fki_default_group_version_id;
DROP INDEX IF EXISTS public.fki_currency_id;
DROP INDEX IF EXISTS public.fki_crime_id;
DROP INDEX IF EXISTS public.fki_created_by_user_id;
DROP INDEX IF EXISTS public.fki_created_at_event_id;
DROP INDEX IF EXISTS public.fki_created_at;
DROP INDEX IF EXISTS public.fki_closed_at_event_id;
DROP INDEX IF EXISTS public.fki_calendar_id;
DROP INDEX IF EXISTS public.fki_arrived_at_event_id;
DROP INDEX IF EXISTS public.fki_actual_release_transfer_id;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_warehouses_created_at_event_id;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_vehicles_created_at_event_id;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_vehicle_types_created_at_event_id;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_suppliers_created_at_event_id;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_products_product_categories_creat;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_products_created_at_event_id;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_product_products_created_at_event;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_product_instances_created_at_even;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_product_instance_transfer_created;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_product_category_types_created_at;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_product_categories_created_at_eve;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_product_attributes_created_at_eve;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_people_created_at_event_id;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_offices_created_at_event_id;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_drivers_created_at_event_id;
DROP INDEX IF EXISTS public.fki_acorn_lojistiks_containers_created_at_event_id;
DROP INDEX IF EXISTS public."fki_ALTER TABLE IF EXISTS public.acorn_criminal_crime";
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_warehouses_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_vehicles_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_vehicle_types_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_transfers_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_transfer_container_replica_identit;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_transfer_container_product_instanc;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_suppliers_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_products_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_products_product_categories_replic;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_product_products_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_product_instances_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_product_instance_transfer_replica_;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_product_category_types_replica_ide;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_product_categories_replica_identit;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_product_attributes_replica_identit;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_people_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_office_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_measurement_units_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_employees_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_drivers_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_containers_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_lojistiks_brands_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_types_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_location_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_gps_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_areas_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_area_types_replica_identity;
DROP INDEX IF EXISTS public.dr_acorn_location_addresses_replica_identity;
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
DROP INDEX IF EXISTS public.acorn_user_user_groups_code_index;
DROP INDEX IF EXISTS public.acorn_user_throttle_user_id_index;
DROP INDEX IF EXISTS public.acorn_user_throttle_ip_address_index;
DROP INDEX IF EXISTS public.acorn_user_mail_blockers_user_id_index;
DROP INDEX IF EXISTS public.acorn_user_mail_blockers_template_index;
DROP INDEX IF EXISTS public.acorn_user_mail_blockers_email_index;
DROP INDEX IF EXISTS public.acorn_calendar_instance_date_event_part_id_instance_n;
DROP INDEX IF EXISTS product.fki_server_id;
DROP INDEX IF EXISTS product.fki_created_at_event_id;
DROP INDEX IF EXISTS product.dr_acorn_lojistiks_electronic_products_replica_identi;
DROP INDEX IF EXISTS product.dr_acorn_lojistiks_computer_products_replica_identity;
ALTER TABLE IF EXISTS public.acorn_criminal_legalcase_defendants DROP CONSTRAINT IF EXISTS verdict;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicles DROP CONSTRAINT IF EXISTS vehicles_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_vehicle_types DROP CONSTRAINT IF EXISTS vehicle_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfers DROP CONSTRAINT IF EXISTS transfers_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instance_transfer DROP CONSTRAINT IF EXISTS transfer_product_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_container_product_instance DROP CONSTRAINT IF EXISTS transfer_container_products_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_transfer_containers DROP CONSTRAINT IF EXISTS transfer_container_pkey;
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
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_suppliers DROP CONSTRAINT IF EXISTS suppliers_pkey;
ALTER TABLE IF EXISTS ONLY public.sessions DROP CONSTRAINT IF EXISTS sessions_id_unique;
ALTER TABLE IF EXISTS ONLY public.backend_user_roles DROP CONSTRAINT IF EXISTS role_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_user_mail_blockers DROP CONSTRAINT IF EXISTS rainlab_user_mail_blockers_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_translate_messages DROP CONSTRAINT IF EXISTS rainlab_translate_messages_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_translate_locales DROP CONSTRAINT IF EXISTS rainlab_translate_locales_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_translate_indexes DROP CONSTRAINT IF EXISTS rainlab_translate_indexes_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_translate_attributes DROP CONSTRAINT IF EXISTS rainlab_translate_attributes_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_location_states DROP CONSTRAINT IF EXISTS rainlab_location_states_pkey;
ALTER TABLE IF EXISTS ONLY public.winter_location_countries DROP CONSTRAINT IF EXISTS rainlab_location_countries_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products_product_category DROP CONSTRAINT IF EXISTS products_product_categories_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_products DROP CONSTRAINT IF EXISTS products_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_instances DROP CONSTRAINT IF EXISTS product_instances_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_category_types DROP CONSTRAINT IF EXISTS product_category_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_categories DROP CONSTRAINT IF EXISTS product_categories_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_attributes DROP CONSTRAINT IF EXISTS product_attributes_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_people DROP CONSTRAINT IF EXISTS person_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_offices DROP CONSTRAINT IF EXISTS office_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_user_groups DROP CONSTRAINT IF EXISTS name_unique;
ALTER TABLE IF EXISTS ONLY public.migrations DROP CONSTRAINT IF EXISTS migrations_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_measurement_units DROP CONSTRAINT IF EXISTS measurement_units_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_users DROP CONSTRAINT IF EXISTS login_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_location_types DROP CONSTRAINT IF EXISTS location_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_locations DROP CONSTRAINT IF EXISTS location_locations_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_gps DROP CONSTRAINT IF EXISTS location_gps_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_areas DROP CONSTRAINT IF EXISTS location_areas_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_area_types DROP CONSTRAINT IF EXISTS location_area_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_addresses DROP CONSTRAINT IF EXISTS location_addresses_pkey;
ALTER TABLE IF EXISTS ONLY public.jobs DROP CONSTRAINT IF EXISTS jobs_pkey;
ALTER TABLE IF EXISTS ONLY public.job_batches DROP CONSTRAINT IF EXISTS job_batches_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_version_user DROP CONSTRAINT IF EXISTS id;
ALTER TABLE IF EXISTS ONLY public.failed_jobs DROP CONSTRAINT IF EXISTS failed_jobs_uuid_unique;
ALTER TABLE IF EXISTS ONLY public.failed_jobs DROP CONSTRAINT IF EXISTS failed_jobs_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_users DROP CONSTRAINT IF EXISTS email_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_drivers DROP CONSTRAINT IF EXISTS drivers_pkey;
ALTER TABLE IF EXISTS ONLY public.deferred_bindings DROP CONSTRAINT IF EXISTS deferred_bindings_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_containers DROP CONSTRAINT IF EXISTS containers_pkey;
ALTER TABLE IF EXISTS ONLY public.cms_theme_templates DROP CONSTRAINT IF EXISTS cms_theme_templates_pkey;
ALTER TABLE IF EXISTS ONLY public.cms_theme_logs DROP CONSTRAINT IF EXISTS cms_theme_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.cms_theme_data DROP CONSTRAINT IF EXISTS cms_theme_data_pkey;
ALTER TABLE IF EXISTS ONLY public.cache DROP CONSTRAINT IF EXISTS cache_key_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_brands DROP CONSTRAINT IF EXISTS brands_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_users DROP CONSTRAINT IF EXISTS backend_users_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_users_groups DROP CONSTRAINT IF EXISTS backend_users_groups_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_user_throttle DROP CONSTRAINT IF EXISTS backend_user_throttle_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_user_roles DROP CONSTRAINT IF EXISTS backend_user_roles_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_user_preferences DROP CONSTRAINT IF EXISTS backend_user_preferences_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_user_groups DROP CONSTRAINT IF EXISTS backend_user_groups_pkey;
ALTER TABLE IF EXISTS ONLY public.backend_access_log DROP CONSTRAINT IF EXISTS backend_access_log_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_users DROP CONSTRAINT IF EXISTS acorn_user_users_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_groups DROP CONSTRAINT IF EXISTS acorn_user_user_groups_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_versions DROP CONSTRAINT IF EXISTS acorn_user_user_group_versions_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group_types DROP CONSTRAINT IF EXISTS acorn_user_user_group_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_user_group DROP CONSTRAINT IF EXISTS acorn_user_user_group_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_throttle DROP CONSTRAINT IF EXISTS acorn_user_throttle_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_roles DROP CONSTRAINT IF EXISTS acorn_user_roles_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_languages DROP CONSTRAINT IF EXISTS acorn_user_languages_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_user_language_user DROP CONSTRAINT IF EXISTS acorn_user_language_user_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_servers DROP CONSTRAINT IF EXISTS acorn_servers_id_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_servers DROP CONSTRAINT IF EXISTS acorn_servers_hostname_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_notary_requests DROP CONSTRAINT IF EXISTS acorn_notary_requests_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_user_message_status DROP CONSTRAINT IF EXISTS acorn_messaging_user_message_status_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_status DROP CONSTRAINT IF EXISTS acorn_messaging_status_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_user_group DROP CONSTRAINT IF EXISTS acorn_messaging_message_user_group_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message DROP CONSTRAINT IF EXISTS acorn_messaging_message_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_message DROP CONSTRAINT IF EXISTS acorn_messaging_message_message_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message_instance DROP CONSTRAINT IF EXISTS acorn_messaging_message_instance_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_message DROP CONSTRAINT IF EXISTS acorn_messaging_message_externalid_unique;
ALTER TABLE IF EXISTS ONLY public.acorn_messaging_label DROP CONSTRAINT IF EXISTS acorn_messaging_label_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_warehouses DROP CONSTRAINT IF EXISTS acorn_lojistiks_warehouses_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_product_products DROP CONSTRAINT IF EXISTS acorn_lojistiks_product_products_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_lojistiks_employees DROP CONSTRAINT IF EXISTS acorn_lojistiks_employees_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_location_lookup DROP CONSTRAINT IF EXISTS acorn_location_location_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrants DROP CONSTRAINT IF EXISTS acorn_justice_warrants_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_warrant_types DROP CONSTRAINT IF EXISTS acorn_justice_warrant_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summons DROP CONSTRAINT IF EXISTS acorn_justice_summons_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_summon_types DROP CONSTRAINT IF EXISTS acorn_justice_summon_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_statements DROP CONSTRAINT IF EXISTS acorn_justice_statements_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_scanned_documents DROP CONSTRAINT IF EXISTS acorn_justice_scanned_documents_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_periods DROP CONSTRAINT IF EXISTS acorn_justice_periods_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_witnesses DROP CONSTRAINT IF EXISTS acorn_justice_legalcase_witnesses_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_plaintiffs DROP CONSTRAINT IF EXISTS acorn_justice_legalcase_victims_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_prosecutor DROP CONSTRAINT IF EXISTS acorn_justice_legalcase_prosecution_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_evidence DROP CONSTRAINT IF EXISTS acorn_justice_legalcase_evidence_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_defendants DROP CONSTRAINT IF EXISTS acorn_justice_defendant_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crimes DROP CONSTRAINT IF EXISTS acorn_justice_crimes_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_types DROP CONSTRAINT IF EXISTS acorn_justice_crime_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_sentences DROP CONSTRAINT IF EXISTS acorn_justice_crime_sentences_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_crime_evidence DROP CONSTRAINT IF EXISTS acorn_justice_crime_evidence_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_legalcase_category DROP CONSTRAINT IF EXISTS acorn_justice_case_category_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcase_categories DROP CONSTRAINT IF EXISTS acorn_justice_case_categories_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_receipts DROP CONSTRAINT IF EXISTS acorn_finance_receipts_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_purchases DROP CONSTRAINT IF EXISTS acorn_finance_purchases_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_payments DROP CONSTRAINT IF EXISTS acorn_finance_payments_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_invoices DROP CONSTRAINT IF EXISTS acorn_finance_invoices_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_finance_currencies DROP CONSTRAINT IF EXISTS acorn_finance_currency_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_witness_statement DROP CONSTRAINT IF EXISTS acorn_criminal_witness_statement_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trials DROP CONSTRAINT IF EXISTS acorn_criminal_trials_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_sessions DROP CONSTRAINT IF EXISTS acorn_criminal_trial_sessions_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_trial_judges DROP CONSTRAINT IF EXISTS acorn_criminal_trial_judge_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_session_recordings DROP CONSTRAINT IF EXISTS acorn_criminal_session_recordings_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_sentence_types DROP CONSTRAINT IF EXISTS acorn_criminal_sentence_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcases DROP CONSTRAINT IF EXISTS acorn_criminal_legalcases_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_legalcase_types DROP CONSTRAINT IF EXISTS acorn_criminal_legalcase_types_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_reasons DROP CONSTRAINT IF EXISTS acorn_criminal_detention_reasons_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_periods DROP CONSTRAINT IF EXISTS acorn_criminal_detention_periods_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_detention_methods DROP CONSTRAINT IF EXISTS acorn_criminal_detention_methods_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_detentions DROP CONSTRAINT IF EXISTS acorn_criminal_defendant_detentions_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_appeals DROP CONSTRAINT IF EXISTS acorn_criminal_appeals_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_calendars DROP CONSTRAINT IF EXISTS acorn_calendar_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_instances DROP CONSTRAINT IF EXISTS acorn_calendar_instance_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user DROP CONSTRAINT IF EXISTS acorn_calendar_event_user_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_part_user_group DROP CONSTRAINT IF EXISTS acorn_calendar_event_user_group_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_types DROP CONSTRAINT IF EXISTS acorn_calendar_event_type_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_statuses DROP CONSTRAINT IF EXISTS acorn_calendar_event_status_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_events DROP CONSTRAINT IF EXISTS acorn_calendar_event_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_calendar_event_parts DROP CONSTRAINT IF EXISTS acorn_calendar_event_part_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_criminal_defendant_crimes DROP CONSTRAINT IF EXISTS acornassocaited_justice_defendant_crime_pkey;
ALTER TABLE IF EXISTS ONLY public.acorn_justice_legalcases DROP CONSTRAINT IF EXISTS acornassocaited_justice_cases_pkey;
ALTER TABLE IF EXISTS ONLY product.acorn_lojistiks_electronic_products DROP CONSTRAINT IF EXISTS office_products_pkey;
ALTER TABLE IF EXISTS ONLY product.acorn_lojistiks_computer_products DROP CONSTRAINT IF EXISTS computer_products_pkey;
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
DROP TABLE IF EXISTS public.backend_users;
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
DROP TABLE IF EXISTS public.acorn_user_users;
DROP TABLE IF EXISTS public.acorn_user_user_groups;
DROP TABLE IF EXISTS public.acorn_user_user_group_versions;
DROP TABLE IF EXISTS public.acorn_user_user_group_version_user;
DROP VIEW IF EXISTS public.acorn_user_user_group_version_usages;
DROP TABLE IF EXISTS public.acorn_user_user_group_types;
DROP TABLE IF EXISTS public.acorn_user_user_group;
DROP TABLE IF EXISTS public.acorn_user_throttle;
DROP TABLE IF EXISTS public.acorn_user_roles;
DROP TABLE IF EXISTS public.acorn_user_mail_blockers;
DROP TABLE IF EXISTS public.acorn_user_languages;
DROP TABLE IF EXISTS public.acorn_user_language_user;
DROP TABLE IF EXISTS public.acorn_servers;
DROP TABLE IF EXISTS public.acorn_notary_requests;
DROP TABLE IF EXISTS public.acorn_messaging_user_message_status;
DROP TABLE IF EXISTS public.acorn_messaging_status;
DROP TABLE IF EXISTS public.acorn_messaging_message_user_group;
DROP TABLE IF EXISTS public.acorn_messaging_message_user;
DROP TABLE IF EXISTS public.acorn_messaging_message_message;
DROP TABLE IF EXISTS public.acorn_messaging_message_instance;
DROP TABLE IF EXISTS public.acorn_messaging_message;
DROP TABLE IF EXISTS public.acorn_messaging_label;
DROP TABLE IF EXISTS public.acorn_messaging_action;
DROP TABLE IF EXISTS public.acorn_lojistiks_warehouses;
DROP TABLE IF EXISTS public.acorn_lojistiks_vehicles;
DROP TABLE IF EXISTS public.acorn_lojistiks_vehicle_types;
DROP TABLE IF EXISTS public.acorn_lojistiks_transfers;
DROP TABLE IF EXISTS public.acorn_lojistiks_transfer_purchase;
DROP TABLE IF EXISTS public.acorn_lojistiks_transfer_invoice;
DROP TABLE IF EXISTS public.acorn_lojistiks_transfer_containers;
DROP TABLE IF EXISTS public.acorn_lojistiks_transfer_container_product_instance;
DROP TABLE IF EXISTS public.acorn_lojistiks_suppliers;
DROP TABLE IF EXISTS public.acorn_lojistiks_products_product_category;
DROP TABLE IF EXISTS public.acorn_lojistiks_products;
DROP TABLE IF EXISTS public.acorn_lojistiks_product_products;
DROP TABLE IF EXISTS public.acorn_lojistiks_product_product_category;
DROP TABLE IF EXISTS public.acorn_lojistiks_product_instances;
DROP TABLE IF EXISTS public.acorn_lojistiks_product_instance_transfer;
DROP TABLE IF EXISTS public.acorn_lojistiks_product_category_types;
DROP TABLE IF EXISTS public.acorn_lojistiks_product_categories;
DROP TABLE IF EXISTS public.acorn_lojistiks_product_attributes;
DROP TABLE IF EXISTS public.acorn_lojistiks_people;
DROP TABLE IF EXISTS public.acorn_lojistiks_offices;
DROP TABLE IF EXISTS public.acorn_lojistiks_measurement_units;
DROP TABLE IF EXISTS public.acorn_lojistiks_employees;
DROP TABLE IF EXISTS public.acorn_lojistiks_drivers;
DROP TABLE IF EXISTS public.acorn_lojistiks_containers;
DROP TABLE IF EXISTS public.acorn_lojistiks_brands;
DROP TABLE IF EXISTS public.acorn_location_types;
DROP TABLE IF EXISTS public.acorn_location_lookup;
DROP TABLE IF EXISTS public.acorn_location_locations;
DROP TABLE IF EXISTS public.acorn_location_gps;
DROP TABLE IF EXISTS public.acorn_location_areas;
DROP TABLE IF EXISTS public.acorn_location_area_types;
DROP TABLE IF EXISTS public.acorn_location_addresses;
DROP TABLE IF EXISTS public.acorn_justice_warrants;
DROP TABLE IF EXISTS public.acorn_justice_warrant_types;
DROP TABLE IF EXISTS public.acorn_justice_summons;
DROP TABLE IF EXISTS public.acorn_justice_summon_types;
DROP TABLE IF EXISTS public.acorn_justice_statements;
DROP TABLE IF EXISTS public.acorn_justice_scanned_documents;
DROP TABLE IF EXISTS public.acorn_justice_periods;
DROP TABLE IF EXISTS public.acorn_justice_legalcases;
DROP TABLE IF EXISTS public.acorn_justice_legalcase_legalcase_category;
DROP TABLE IF EXISTS public.acorn_justice_legalcase_categories;
DROP TABLE IF EXISTS public.acorn_finance_receipts;
DROP TABLE IF EXISTS public.acorn_finance_purchases;
DROP TABLE IF EXISTS public.acorn_finance_payments;
DROP TABLE IF EXISTS public.acorn_finance_invoices;
DROP TABLE IF EXISTS public.acorn_finance_currencies;
DROP TABLE IF EXISTS public.acorn_criminal_witness_statement;
DROP TABLE IF EXISTS public.acorn_criminal_trials;
DROP TABLE IF EXISTS public.acorn_criminal_trial_sessions;
DROP TABLE IF EXISTS public.acorn_criminal_trial_judges;
DROP TABLE IF EXISTS public.acorn_criminal_session_recordings;
DROP TABLE IF EXISTS public.acorn_criminal_sentence_types;
DROP TABLE IF EXISTS public.acorn_criminal_legalcases;
DROP TABLE IF EXISTS public.acorn_criminal_legalcase_witnesses;
DROP TABLE IF EXISTS public.acorn_criminal_legalcase_types;
DROP TABLE IF EXISTS public.acorn_criminal_legalcase_related_events;
DROP TABLE IF EXISTS public.acorn_criminal_legalcase_prosecutor;
DROP TABLE IF EXISTS public.acorn_criminal_legalcase_plaintiffs;
DROP TABLE IF EXISTS public.acorn_criminal_legalcase_evidence;
DROP TABLE IF EXISTS public.acorn_criminal_legalcase_defendants;
DROP TABLE IF EXISTS public.acorn_criminal_detention_reasons;
DROP TABLE IF EXISTS public.acorn_criminal_detention_periods;
DROP TABLE IF EXISTS public.acorn_criminal_detention_methods;
DROP TABLE IF EXISTS public.acorn_criminal_defendant_detentions;
DROP TABLE IF EXISTS public.acorn_criminal_defendant_crimes;
DROP TABLE IF EXISTS public.acorn_criminal_crimes;
DROP TABLE IF EXISTS public.acorn_criminal_crime_types;
DROP TABLE IF EXISTS public.acorn_criminal_crime_sentences;
DROP TABLE IF EXISTS public.acorn_criminal_crime_evidence;
DROP TABLE IF EXISTS public.acorn_criminal_appeals;
DROP TABLE IF EXISTS public.acorn_calendar_instances;
DROP TABLE IF EXISTS public.acorn_calendar_events;
DROP TABLE IF EXISTS public.acorn_calendar_event_types;
DROP TABLE IF EXISTS public.acorn_calendar_event_statuses;
DROP TABLE IF EXISTS public.acorn_calendar_event_parts;
DROP TABLE IF EXISTS public.acorn_calendar_event_part_user_group;
DROP TABLE IF EXISTS public.acorn_calendar_event_part_user;
DROP TABLE IF EXISTS public.acorn_calendar_calendars;
DROP TABLE IF EXISTS product.acorn_lojistiks_electronic_products;
DROP TABLE IF EXISTS product.acorn_lojistiks_computer_products;
DROP AGGREGATE IF EXISTS public.agg_acorn_last(anyelement);
DROP AGGREGATE IF EXISTS public.agg_acorn_first(anyelement);
DROP FUNCTION IF EXISTS public.fn_acorn_user_get_seed_user();
DROP FUNCTION IF EXISTS public.fn_acorn_truncate_database(schema_like character varying, table_like character varying);
DROP FUNCTION IF EXISTS public.fn_acorn_table_counts(_schema character varying);
DROP FUNCTION IF EXISTS public.fn_acorn_server_id();
DROP FUNCTION IF EXISTS public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying);
DROP FUNCTION IF EXISTS public.fn_acorn_notary_trigger_validate();
DROP FUNCTION IF EXISTS public.fn_acorn_new_replicated_row();
DROP FUNCTION IF EXISTS public.fn_acorn_lojistiks_is_date(s character varying, d timestamp with time zone);
DROP FUNCTION IF EXISTS public.fn_acorn_lojistiks_distance(source_location_id uuid, destination_location_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_last(anyelement, anyelement);
DROP FUNCTION IF EXISTS public.fn_acorn_justice_warrants_state_indicator(warrant record);
DROP FUNCTION IF EXISTS public.fn_acorn_justice_seed_groups();
DROP FUNCTION IF EXISTS public.fn_acorn_justice_seed_calendar();
DROP FUNCTION IF EXISTS public.fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_justice_action_warrants_request_notary(model_id uuid, user_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_first(anyelement, anyelement);
DROP FUNCTION IF EXISTS public.fn_acorn_enrollment_enrollments_state_indicator(p_enrollment record);
DROP FUNCTION IF EXISTS public.fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid);
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_trigger_activity_event();
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_seed();
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying);
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_is_date(s character varying, d timestamp with time zone);
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record);
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_events_generate_event_instances();
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone);
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying);
DROP FUNCTION IF EXISTS public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying);
DROP FUNCTION IF EXISTS public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying);
DROP EXTENSION IF EXISTS http;
DROP EXTENSION IF EXISTS hostname;
DROP EXTENSION IF EXISTS earthdistance;
DROP EXTENSION IF EXISTS cube;
-- *not* dropping schema, since initdb creates it
DROP SCHEMA IF EXISTS product;
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
-- Name: fn_acorn_calendar_create_activity_log_event(uuid, uuid, uuid, character varying); Type: FUNCTION; Schema: public; Owner: justice
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


ALTER FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) OWNER TO justice;

--
-- Name: fn_acorn_calendar_create_event(uuid, uuid, uuid, uuid, character varying); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
begin
	return public.fn_acorn_calendar_create_event(calendar_id, owner_user_id, type_id, status_id, name, now()::timestamp without time zone, now()::timestamp without time zone);
end;
$$;


ALTER FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) OWNER TO justice;

--
-- Name: fn_acorn_calendar_create_event(uuid, uuid, uuid, uuid, character varying, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: justice
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


ALTER FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) OWNER TO justice;

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
-- Name: fn_acorn_calendar_generate_event_instances(record, record); Type: FUNCTION; Schema: public; Owner: justice
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


ALTER FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) OWNER TO justice;

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
-- Name: fn_acorn_calendar_lazy_create_event(character varying, uuid, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: justice
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


ALTER FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) OWNER TO justice;

--
-- Name: fn_acorn_calendar_seed(); Type: FUNCTION; Schema: public; Owner: justice
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


ALTER FUNCTION public.fn_acorn_calendar_seed() OWNER TO justice;

--
-- Name: fn_acorn_calendar_trigger_activity_event(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_calendar_trigger_activity_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare 
	name_optional character varying(2048);
	soft_delete_optional boolean = false;
	table_comment character varying(2048);
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


ALTER FUNCTION public.fn_acorn_calendar_trigger_activity_event() OWNER TO justice;

--
-- Name: fn_acorn_criminal_action_legalcase_defendants_cs(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
	justice_legalcase_id uuid;
	summon_type_id uuid;
	owner_user_id uuid;
begin
	owner_user_id := user_id;
	
	-- Create Warrant
	select into justice_legalcase_id cl.legalcase_id 
		from public.acorn_criminal_legalcases cl
		inner join public.acorn_criminal_legalcase_defendants ld on cl.id = ld.legalcase_id
		where ld.id = model_id;
	select into summon_type_id id from public.acorn_justice_summon_types limit 1;
	
	insert into public.acorn_justice_summons(user_id, created_by_user_id, summon_type_id, legalcase_id)
		select ld.user_id,
			owner_user_id,
			summon_type_id,
			justice_legalcase_id
		from public.acorn_criminal_legalcase_defendants ld
		where id = model_id;
end;
$$;


ALTER FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid) OWNER TO justice;

--
-- Name: FUNCTION fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid) IS 'labels:
  en: Create Summons
  ku: Gazîkirin çêbikin';


--
-- Name: fn_acorn_criminal_action_legalcase_defendants_cw(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
	justice_legalcase_id uuid;
	warrant_type_id uuid;
	owner_user_id uuid;
begin
	owner_user_id := user_id;
	
	-- Create Warrant
	select into justice_legalcase_id cl.legalcase_id 
		from public.acorn_criminal_legalcases cl
		inner join public.acorn_criminal_legalcase_defendants ld on cl.id = ld.legalcase_id
		where ld.id = model_id;
	select into warrant_type_id id from public.acorn_justice_warrant_types limit 1;
	
	insert into public.acorn_justice_warrants(user_id, created_by_user_id, warrant_type_id, legalcase_id)
		select ld.user_id,
			owner_user_id,
			warrant_type_id,
			justice_legalcase_id
		from public.acorn_criminal_legalcase_defendants ld
		where id = model_id;
end;
$$;


ALTER FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid) OWNER TO justice;

--
-- Name: FUNCTION fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid) IS 'labels:
  en: Create Warrant
  ku: Fermanek çêbikin';


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
  en: Cancel
  ku: Bişûndekirin';


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
  ku: Derbaskirin Doza
result-action: model-uuid-redirect
condition: not id is null';


--
-- Name: fn_acorn_enrollment_enrollments_state_indicator(record); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_enrollment_enrollments_state_indicator(p_enrollment record) RETURNS character varying[]
    LANGUAGE plpgsql
    AS $$
declare
	state_indicator character varying[];
begin
	-- BEFORE update or insert
	-- Set the state_indicator for the row
	case
		when not p_enrollment.applied_at is null then state_indicator = '{applied, valid}'; 
		else state_indicator = '{new, valid}';
	end case;
	
	return state_indicator;
end;
$$;


ALTER FUNCTION public.fn_acorn_enrollment_enrollments_state_indicator(p_enrollment record) OWNER TO justice;

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
	-- An Activity log UPDATE event will also be created
	-- automatically by fn_acorn_calendar_trigger_activity_event()
	-- Here, we update the Legal calendar
	update public.acorn_justice_legalcases 
		set closed_at_event_id = public.fn_acorn_calendar_lazy_create_event('Legal', user_id, 'LegalCase', 'Close', name)
		where id = model_id;
end;
$$;


ALTER FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) OWNER TO justice;

--
-- Name: FUNCTION fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) IS 'labels:
  en: Close Case
  ku: Bigre Doza
condition: closed_at_event_id is null';


--
-- Name: fn_acorn_justice_action_legalcases_reopen_case(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	-- TODO: Create an activity_log event for this
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
  ku: Doza ji nû ve veke
condition: not closed_at_event_id is null';


--
-- Name: fn_acorn_justice_action_warrants_request_notary(uuid, uuid); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_justice_action_warrants_request_notary(model_id uuid, user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
	new_notary_request_id uuid;
begin
	insert into acorn_notary_requests(created_by_user_id) values(user_id) returning id into new_notary_request_id;
	update acorn_justice_warrants set notary_request_id = new_notary_request_id where id = model_id;
end;
$$;


ALTER FUNCTION public.fn_acorn_justice_action_warrants_request_notary(model_id uuid, user_id uuid) OWNER TO justice;

--
-- Name: FUNCTION fn_acorn_justice_action_warrants_request_notary(model_id uuid, user_id uuid); Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON FUNCTION public.fn_acorn_justice_action_warrants_request_notary(model_id uuid, user_id uuid) IS 'labels:
  en: Request Notary
  ku: Diwan bipirsin
condition: notary_request_id is null';


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
  ku: Dûrxistin
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
		insert into public.acorn_calendar_calendars(id, name) 
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
-- Name: fn_acorn_justice_warrants_state_indicator(record); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_justice_warrants_state_indicator(warrant record) RETURNS character varying[]
    LANGUAGE plpgsql
    AS $$
declare
	state_indicator character varying[];
begin
	-- BEFORE update or insert
	-- Set the state_indicator for the row
	case
		when warrant.notary_request_id is null then state_indicator = '{notary_required, invalid}'; 
		when (select validated_by_notary_user_id from acorn_notary_requests where id = warrant.notary_request_id) is null then state_indicator = '{notary_awaiting, waiting}'; 
		else state_indicator = '{notary_validated, valid}';
	end case;
	
	return state_indicator;
end;
$$;


ALTER FUNCTION public.fn_acorn_justice_warrants_state_indicator(warrant record) OWNER TO justice;

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
-- Name: fn_acorn_notary_trigger_validate(); Type: FUNCTION; Schema: public; Owner: justice
--

CREATE FUNCTION public.fn_acorn_notary_trigger_validate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	new_event_id uuid;
begin
	-- If the request is being validated
	-- Auto-fill out the validation datetime
	if OLD.validated_by_notary_user_id is null and not NEW.validated_by_notary_user_id is NULL then
		if not OLD.validated_at_event_id is null then
			-- What to do in this case? Update or delete or error?
		end if;

		NEW.validated_at_event_id = public.fn_acorn_calendar_lazy_create_event(
			'Legal', NEW.validated_by_notary_user_id, 'NotaryRequest', 'Validate', coalesce(NEW.name, '')
		);
	end if;
	
	return NEW;
end;
$$;


ALTER FUNCTION public.fn_acorn_notary_trigger_validate() OWNER TO justice;

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
    system boolean DEFAULT false NOT NULL,
    calendar_id uuid
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
    colour character varying(16) DEFAULT '#333'::character varying,
    style character varying(2048),
    created_at timestamp(0) without time zone DEFAULT '2024-10-19 13:37:23.11728'::timestamp without time zone NOT NULL,
    updated_at timestamp(0) without time zone,
    system boolean DEFAULT false NOT NULL,
    activity_log_related_oid integer,
    calendar_id uuid
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
  ku: Temîz
labels-plural:
  en: Appeals
  ar: الاستئنافات الجنائية
  ku: Temîzan
methods:
  name: $this->load(''event''); return $this->event->start?->diffForHumans();
permission-settings:
  appeals__access:
    labels: 
      en: Create an Appeal
      ku: Îtirazek çêbikin
';


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
  en: Evidence
  ar: دليل الجريمة الجنائية
  ku: Delîl
labels-plural:
  en: Evidence
  ar: أدلة الجريمة الجنائية
  ku: Delîlên
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
  en: Sentence
  ar: حكم الجريمة الجنائية
  ku: Biryar
labels-plural:
  en: Sentences
  ar: أحكام الجرائم الجنائية
  ku: Biryarên
methods:
  name: return $this->sentence_type->name . '' ('' . $this->amount . '')'';';


--
-- Name: COLUMN acorn_criminal_crime_sentences.amount; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_crime_sentences.amount IS 'labels:
  en: Amount
  ku: Jimarî
labels-plural:
  en: Amounts
  ku: Jimarîyên
  ';


--
-- Name: COLUMN acorn_criminal_crime_sentences.suspended; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_crime_sentences.suspended IS 'labels:
  en: Suspended
  ku: Sekinandinê';


--
-- Name: COLUMN acorn_criminal_crime_sentences.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_crime_sentences.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
tab: acorn::lang.models.general.notes
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
  en: Crime Type
  ku: Cure Sûc
  ar: نوع الجريمة الجنائية
labels-plural:
  en: Crime Types
  ku: Cureyên Sûc
  ar: أنواع الجرائم الجنائية
';


--
-- Name: COLUMN acorn_criminal_crime_types.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_crime_types.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_criminal_crime_types.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_crime_types.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes
';


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
  en: Crime
  ku: Nebaşî
  ar: الجريمة الجنائية
labels-plural:
  en: Crimes
  ku: Nebaşîyên
  ar: الجرائم الجنائية
seeding:
  - [DEFAULT, ''Theft'', ''176d4d98-ed25-11ef-8f3a-e7099c31e054'']
  - [DEFAULT, ''Mysogyny'', ''176d4d98-ed25-11ef-8f3a-e7099c31e054'']';


--
-- Name: COLUMN acorn_criminal_crimes.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_crimes.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_criminal_crimes.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_crimes.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


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
  en: Crime
  ku: Nebaşî
  ar: جرائم المتهمين الجنائية
labels-plural:
  en: Crimes
  ku: Nebaşîyên
  ar: جرايمة المتهم الجنائية
methods:
  name: return $this->crime->name;';


--
-- Name: COLUMN acorn_criminal_defendant_crimes.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_defendant_crimes.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


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
    description text,
    allowed_notes_total interval
);


ALTER TABLE public.acorn_criminal_defendant_detentions OWNER TO justice;

--
-- Name: TABLE acorn_criminal_defendant_detentions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_defendant_detentions IS 'methods:
  name: return $this->transfer->location->name . '' ('' . $this->detention_reason?->name . '')'';
attribute-functions:
  allowed-notes-total: return new CarbonInterval($value);
labels:
  en: Detention
  ku: Girtî
labels-plural:
  en: Detentions
  ku: Girtîyên';


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

COMMENT ON COLUMN public.acorn_criminal_defendant_detentions.name IS 'hidden: true
invisible: true
labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_criminal_defendant_detentions.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_defendant_detentions.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: COLUMN acorn_criminal_defendant_detentions.allowed_notes_total; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_defendant_detentions.allowed_notes_total IS 'sql-select: (select sum("period") from acorn_criminal_detention_periods dps inner join acorn_justice_periods jp on dps.period_id = jp.id where dps.defendant_detention_id = acorn_criminal_defendant_detentions.id)';


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
  - [DEFAULT, ''Request'']
labels:
  en: Detention Method
  ku: Rêbaza binçavkirinê
labels-plural:
  en: Detention Methods
  ku: Rêbaza binçavkirinên';


--
-- Name: COLUMN acorn_criminal_detention_methods.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_detention_methods.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_criminal_detention_methods.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_detention_methods.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: acorn_criminal_detention_periods; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_detention_periods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    defendant_detention_id uuid NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS (id) STORED,
    description text,
    period_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_criminal_detention_periods OWNER TO justice;

--
-- Name: TABLE acorn_criminal_detention_periods; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_detention_periods IS 'labels:
  en: Allowed period note
labels-plural:
  en: Allowed period notes
methods:
  name: return $this->period->name;';


--
-- Name: COLUMN acorn_criminal_detention_periods.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_detention_periods.name IS 'hidden: true
invisible: true
labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_criminal_detention_periods.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_detention_periods.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


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
  - [DEFAULT, ''In danger'']
labels:
  en: Detention Reason
  ku: Sedema binçavkirinê
labels-plural:
  en: Detention Reasons
  ku: Sedema binçavkirinên';


--
-- Name: COLUMN acorn_criminal_detention_reasons.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_detention_reasons.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_criminal_detention_reasons.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_detention_reasons.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


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
    server_id uuid NOT NULL,
    lawyer_user_id uuid,
    verdict character(1)
);


ALTER TABLE public.acorn_criminal_legalcase_defendants OWNER TO justice;

--
-- Name: TABLE acorn_criminal_legalcase_defendants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_legalcase_defendants IS 'icon: robot
order: 6
menu: false
labels:
  en: Defendant
  ku: LeDozdar
  ar: المتهم في قضية جنائية
labels-plural:
  en: Defendants
  ku: LeDozdaran
  ar: المتهمين في قضية جنائية
';


--
-- Name: COLUMN acorn_criminal_legalcase_defendants.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_defendants.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: COLUMN acorn_criminal_legalcase_defendants.lawyer_user_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_defendants.lawyer_user_id IS 'labels:
  en: Lawyer
  ku: Parezir
labels-plural:
  en: Lawyers
  ku: Pareziran';


--
-- Name: COLUMN acorn_criminal_legalcase_defendants.verdict; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_defendants.verdict IS 'field-type: radio
field-options:
  G: 
    en: Guilty
    ku: Sucdar
  I: 
    en: Innocent
    ku: Bêsuc';


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
  en: Evidence
  ku: Delîl
  ar: دليل القضايا الجنائية
labels-plural:
  en: Evidence
  ku: Delîlên
  ar: أدلة القضايا الجنائية
';


--
-- Name: COLUMN acorn_criminal_legalcase_evidence.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_evidence.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_criminal_legalcase_evidence.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_evidence.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


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
    server_id uuid NOT NULL,
    lawyer_user_id uuid
);


ALTER TABLE public.acorn_criminal_legalcase_plaintiffs OWNER TO justice;

--
-- Name: TABLE acorn_criminal_legalcase_plaintiffs; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_legalcase_plaintiffs IS 'icon: address-book
order: 2
menu: false
labels:
  en: Plaintiff
  ku: Dozdar
  ar: ضحية القضية الجنائية
labels-plural:
  en: Plaintiffs
  ku: Dozdaran
  ar: ضحايا القضية الجنائية
';


--
-- Name: COLUMN acorn_criminal_legalcase_plaintiffs.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_plaintiffs.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: COLUMN acorn_criminal_legalcase_plaintiffs.lawyer_user_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_plaintiffs.lawyer_user_id IS 'labels:
  en: Lawyer
  ku: Parezir
labels-plural:
  en: Lawyers
  ku: Pareziran';


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
  en: Prosecutor
  ku: Dozger
  ar: المدعي العام للقضية الجنائية
labels-plural:
  en: Prosecutors
  ku: Dozgerên
  ar: المدعون العامون للقضايا الجنائية
';


--
-- Name: COLUMN acorn_criminal_legalcase_prosecutor.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_prosecutor.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


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
  en: Related Event
  ku: Bûyera têkildar
  ar: الحدث المتعلقة بالقضاية الجنائية
labels-plural:
  en: Related Events
  ku: Bûyera têkildarên
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
  - [''c7c11a48-f1d1-11ef-adb1-17df3598e69d'', ''Criminal'']
  - [''cecfc1a4-f1d1-11ef-82cf-0f7766f8c250'', ''Civil'']
labels:
  en: Type
  ku: Cure
labels-plural:
  en: Types
  ku: Cureyên';


--
-- Name: COLUMN acorn_criminal_legalcase_types.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_types.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_criminal_legalcase_types.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_types.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


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
  en: Witness
  ku: Şahîd
  ar: شاهد القضية الجنائية
labels-plural:
  en: Witnesses
  ku: Şahidên
  ar: شهود القضية الجنائية
';


--
-- Name: COLUMN acorn_criminal_legalcase_witnesses.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcase_witnesses.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


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
  ku: Doza
  ar: القضية الجنائية
labels-plural:
  en: LegalCases
  ku: Dozên
  ar: القضايا الجنائية
plugin-names:
  en: Legal Cases
  ku: Dozên
  ar: القضية الجنائية
filters:
  owner_user_group: id in(select cl.id from acorn_criminal_legalcases cl inner join acorn_justice_legalcases  jl on jl.id = cl.legalcase_id where jl.owner_user_group_id in(:filtered))
';


--
-- Name: COLUMN acorn_criminal_legalcases.legalcase_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcases.legalcase_id IS 'order: 1';


--
-- Name: COLUMN acorn_criminal_legalcases.judge_committee_user_group_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcases.judge_committee_user_group_id IS 'bootstraps:
  xs: 4
order: 11
labels:
  en: Judge Committee
  ku: Komîteya Dadweran
labels-plural:
  en: Judge Committies
  ku: Komîteyan Dadweran
column-type: partial
partial: owner
';


--
-- Name: COLUMN acorn_criminal_legalcases.legalcase_type_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_legalcases.legalcase_type_id IS 'field-type: radio
read-only: true
bootstraps:
  xs: 4
css-classes: 
  - inline-options
permission-settings:
  legalcase_type__create_criminal_only:
    field:
      field-type: dropdown
      default: c7c11a48-f1d1-11ef-adb1-17df3598e69d
    labels: 
      en: Create Criminal LegalCases only
      ku: Tenê Dozên Yasayî yên Cezayê biafirînin
  legalcase_type__create_civil_only:
    field:
      field-type: dropdown
      default: cecfc1a4-f1d1-11ef-82cf-0f7766f8c250
    labels: 
      en: Create Civil LegalCases only
      ku: Tenê Dozên Yasayî yên Sivîl biafirînin
  legalcase_type__create_any@create:
    field:
      read-only: false
    labels: 
      en: Create any LegalCase type
      ku: Cûreyek Doza Yasayî biafirînin
  legalcases__legalcase_type_id__update@update:
    field:
      read-only: false
      field-type: radio
    labels: 
      en: Update LegalCase type
      ku: Cureyê Doza biguherînin
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
  en: Sentence Type
  ku: Cura Biryar
  ar: نوع الحكم الجنائي
labels-plural:
  en: Sentence Types
  ku: Cureyên Biryar
  ar: أنواع الأحكام الجنائية
seeding:
  - [DEFAULT, ''Custodial'']
  - [DEFAULT, ''Fine'']
  - [DEFAULT, ''Community service'']';


--
-- Name: COLUMN acorn_criminal_sentence_types.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_sentence_types.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_criminal_sentence_types.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_sentence_types.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


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
    server_id uuid NOT NULL,
    audio_file path NOT NULL
);


ALTER TABLE public.acorn_criminal_session_recordings OWNER TO justice;

--
-- Name: TABLE acorn_criminal_session_recordings; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_session_recordings IS 'icon: map
order: 25
menu: false
labels:
  en: Session recording
  ku: Tomar Deng
  ar: تسجيل الجلسة جنائية
labels-plural:
  en: Session recordings
  ku: Tomarên Deng
  ar: تسجيلات الجلسة جنائية
';


--
-- Name: COLUMN acorn_criminal_session_recordings.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_session_recordings.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: COLUMN acorn_criminal_session_recordings.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_session_recordings.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_criminal_session_recordings.audio_file; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_session_recordings.audio_file IS 'labels:
  en: Audio file
  ku: Pelê deng
labels-plural:
  en: Audio files
  ku: Pelên deng
';


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
  en: Judge
  ku: Dadwer
  ar: قاضي المحكمة الجنائية
labels-plural:
  en: Judges
  ku: Dadweran
  ar: قضاة المحكمة الجنائية
methods:
  name: return $this->user->name;';


--
-- Name: COLUMN acorn_criminal_trial_judges.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_trial_judges.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: acorn_criminal_trial_sessions; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_trial_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trial_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    event_id uuid NOT NULL,
    description text
);


ALTER TABLE public.acorn_criminal_trial_sessions OWNER TO justice;

--
-- Name: TABLE acorn_criminal_trial_sessions; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_trial_sessions IS 'icon: meh
order: 21
labels:
  en: Session
  ku: Rûniştinî
  ar: جلسة المحكمة الجنائية
labels-plural:
  en: Sessions
  ku: Rûniştinên
  ar: جلسات المحكمة الجنائية
methods:
  name: return $this->created_at_event->start;';


--
-- Name: COLUMN acorn_criminal_trial_sessions.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_trial_sessions.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: acorn_criminal_trials; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_trials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_id uuid NOT NULL,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid NOT NULL,
    event_id uuid NOT NULL,
    description text
);


ALTER TABLE public.acorn_criminal_trials OWNER TO justice;

--
-- Name: TABLE acorn_criminal_trials; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_trials IS 'icon: ankh
order: 20
menuSplitter: yes
labels:
  en: Trial
  ku: Dadgehkirin
  ar: المحكمة الجنائية
labels-plural:
  en: Trials
  ku: Dadgehkirinên
  ar: المحاكم الجنائية
methods:
  name: $this->load(''event''); return $this->event->start?->diffForHumans();
permission-settings:
  trials__access:
    labels: 
      en: Create a Trial
      ku: Dadgehek çêbikin
';


--
-- Name: COLUMN acorn_criminal_trials.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_trials.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: acorn_criminal_witness_statement; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_criminal_witness_statement (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legalcase_witness_id uuid NOT NULL,
    statement_id uuid NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    created_by_user_id uuid DEFAULT public.fn_acorn_user_get_seed_user() NOT NULL,
    updated_at_event_id uuid,
    updated_by_user_id uuid
);


ALTER TABLE public.acorn_criminal_witness_statement OWNER TO justice;

--
-- Name: TABLE acorn_criminal_witness_statement; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_criminal_witness_statement IS 'order: 5
labels:
  en: Witness statement
  ku: Îfade şahid
labels-plural:
  en: Witness statements
  ku: Îfaden şahid
';


--
-- Name: COLUMN acorn_criminal_witness_statement.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_criminal_witness_statement.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


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
  en: Category
  ku: Kategorî
  ar: فئة القضية العدلية
labels-plural:
  en: Categories
  ku: Kategorîyên
  ar: فئات القضية العدلية
';


--
-- Name: COLUMN acorn_justice_legalcase_categories.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_legalcase_categories.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_justice_legalcase_categories.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_legalcase_categories.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes
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
  ku: Doz
  ar: قضية عدالة
labels-plural:
  en: Cases
  ku: Dozan
  ar: قضاية عدالة
plugin-names:
  en: Justice System
  ku: Dadmendî
  ar: قضية عدالة
order: 1
plugin-icon: adjust
';


--
-- Name: COLUMN acorn_justice_legalcases.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_legalcases.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên
order: 1
permission-settings:
  NOT=legalcases__legalcase_name__update@update:
    field:
      readOnly: true
      disabled: true
    labels: 
      en: Update LegalCase name
      ku: Navê Doza Hiqûqî nûve bikin';


--
-- Name: COLUMN acorn_justice_legalcases.closed_at_event_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_legalcases.closed_at_event_id IS 'labels:
  en: Closed at
  ku: Dema girtî
css-classes:
  - highlight-value
order: 2
';


--
-- Name: COLUMN acorn_justice_legalcases.owner_user_group_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_legalcases.owner_user_group_id IS 'labels:
  en: Owner Organisation
  ku: Rêxistina Xwedî
labels-plural:
  en: Owner Organisations
  ku: Rêxistinan Xwedî
bootstraps:
  xs: 4
column-type: partial
partial: owner
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

COMMENT ON COLUMN public.acorn_justice_legalcases.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînên
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: acorn_justice_periods; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_justice_periods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) GENERATED ALWAYS AS (period) STORED,
    description text,
    period interval NOT NULL,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_justice_periods OWNER TO justice;

--
-- Name: TABLE acorn_justice_periods; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_periods IS 'labels:
  en: Period
labels-plural:
  en: Periods
seeding:
  - [DEFAULT,DEFAULT,,24 hours]
  - [DEFAULT,DEFAULT,,7 days]
attribute-functions:
  period: return new CarbonInterval($value);';


--
-- Name: COLUMN acorn_justice_periods.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_periods.name IS 'hidden: true
invisible: true';


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
-- Name: TABLE acorn_justice_scanned_documents; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_scanned_documents IS 'labels:
  en: Scanned Document
  ku: Belge Kopî
labels-plural:
  en: Scanned Documents
  ku: Belgeyên Kopî';


--
-- Name: COLUMN acorn_justice_scanned_documents.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_scanned_documents.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_justice_scanned_documents.document; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_scanned_documents.document IS 'labels:
  en: Document
  ku: Belge
labels-plural:
  en: Documents
  ku: Belgên
required: true';


--
-- Name: COLUMN acorn_justice_scanned_documents.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_scanned_documents.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: acorn_justice_statements; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_justice_statements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    user_id uuid NOT NULL,
    legalcase_id uuid NOT NULL,
    name character varying(2048),
    description text,
    statement text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_justice_statements OWNER TO justice;

--
-- Name: TABLE acorn_justice_statements; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_statements IS 'labels:
  en: Statement
  ku: Îfade
labels-plural:
  en: Statements
  ku: Îfaden';


--
-- Name: COLUMN acorn_justice_statements.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_statements.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: COLUMN acorn_justice_statements.statement; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_statements.statement IS 'invisible: true';


--
-- Name: acorn_justice_summon_types; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_justice_summon_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(1024) NOT NULL,
    description text,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_justice_summon_types OWNER TO justice;

--
-- Name: TABLE acorn_justice_summon_types; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_summon_types IS 'seeding:
  - [DEFAULT, ''Normal'']
labels:
  en: Summon Type
  ku: Cure Fermana girtinê
labels-plural:
  en: Summon Types
  ku: Cureyên Fermana girtinê';


--
-- Name: COLUMN acorn_justice_summon_types.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_summon_types.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_justice_summon_types.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_summon_types.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: acorn_justice_summons; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_justice_summons (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at_event_id uuid,
    created_by_user_id uuid,
    user_id uuid NOT NULL,
    summon_type_id uuid,
    legalcase_id uuid NOT NULL,
    revoked_at_event_id uuid,
    description text,
    updated_at_event_id uuid,
    updated_by_user_id uuid,
    server_id uuid NOT NULL,
    state_indicator character varying(2048)[],
    notary_request_id uuid
);


ALTER TABLE public.acorn_justice_summons OWNER TO justice;

--
-- Name: TABLE acorn_justice_summons; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_summons IS 'methods:
  name: return $this->summon_type?->name;
labels:
  en: Summons
  ku: Gazîkirin
labels-plural:
  en: Summons
  ku: Gazîkirinan';


--
-- Name: COLUMN acorn_justice_summons.revoked_at_event_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_summons.revoked_at_event_id IS 'labels:
  en: Revoked at
  ku: Vekişandin';


--
-- Name: COLUMN acorn_justice_summons.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_summons.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: COLUMN acorn_justice_summons.state_indicator; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_summons.state_indicator IS 'sqlSelect: (select fn_acorn_justice_summons_state_indicator(acorn_justice_summons))
extra-translations:
  notary_required:
    en: Notary required
    ku: Diwan lazimî
  notary_awaiting:
    en: Awaiting Notary
    ku: Diwan bisekane';


--
-- Name: COLUMN acorn_justice_summons.notary_request_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_summons.notary_request_id IS 'hidden: true
invisible: true';


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
  - [DEFAULT, ''Search'']
labels:
  en: Warrant Type
  ku: Cure Fermana girtinê
labels-plural:
  en: Warrant Types
  ku: Cureyên Fermana girtinê';


--
-- Name: COLUMN acorn_justice_warrant_types.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_warrant_types.name IS 'labels:
  en: Name
  ku: Nav
labels-plural:
  en: Names
  ku: Navên';


--
-- Name: COLUMN acorn_justice_warrant_types.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_warrant_types.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


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
    server_id uuid NOT NULL,
    state_indicator character varying(2048)[],
    notary_request_id uuid
);


ALTER TABLE public.acorn_justice_warrants OWNER TO justice;

--
-- Name: TABLE acorn_justice_warrants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_justice_warrants IS 'printable:
  permissions:
    notary:
      labels:
        en: Notary
        ku: Diwan
methods:
  name: return $this->warrant_type?->name;
labels:
  en: Warrant
  ku: Fermana girtinê
labels-plural:
  en: Warrants
  ku: Fermanan girtinê';


--
-- Name: COLUMN acorn_justice_warrants.revoked_at_event_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_warrants.revoked_at_event_id IS 'labels:
  en: Revoked at
  ku: Vekişandin';


--
-- Name: COLUMN acorn_justice_warrants.description; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_warrants.description IS 'field-comment: Vê zeviyê bikar bînin da ku hûn notên din ên ku hêj di navberê de zeviyên wan tune ne zêde bikin. Rêvebirên pergalê dê vê yekê kontrol bikin û pêvekê berfireh bikin da ku hewcedariyên we bicîh bînin
labels:
  en: Notes
  ku: Têbînî
labels-plural:
  en: Notes
  ku: Têbînî
tab-location: 1
no-label: true
bootstraps:
  xs: 12
tab: acorn::lang.models.general.notes';


--
-- Name: COLUMN acorn_justice_warrants.state_indicator; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_warrants.state_indicator IS 'sqlSelect: (select fn_acorn_justice_warrants_state_indicator(acorn_justice_warrants))
extra-translations:
  notary_required:
    en: Notary required
    ku: Diwan lazimî
  notary_awaiting:
    en: Awaiting Notary
    ku: Diwan bisekane
  notary_validated:
    en: Notary validated
    ku: Diwan kabulkir';


--
-- Name: COLUMN acorn_justice_warrants.notary_request_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_justice_warrants.notary_request_id IS 'hidden: true
invisible: true';


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
-- Name: acorn_notary_requests; Type: TABLE; Schema: public; Owner: justice
--

CREATE TABLE public.acorn_notary_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    description text,
    validated_by_notary_user_id uuid,
    validated_at_event_id uuid,
    name character varying(1024) GENERATED ALWAYS AS ((id)::text) STORED,
    created_at_event_id uuid NOT NULL,
    updated_at_event_id uuid,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid,
    server_id uuid NOT NULL
);


ALTER TABLE public.acorn_notary_requests OWNER TO justice;

--
-- Name: TABLE acorn_notary_requests; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON TABLE public.acorn_notary_requests IS 'printable: true
plugin-names:
  en: Notary
  ku: Dîwan
labels:
  en: Request
  ku: Pirs
labels-plural:
  en: Requests
  ku: Pirsên
  ';


--
-- Name: COLUMN acorn_notary_requests.validated_at_event_id; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_notary_requests.validated_at_event_id IS 'hidden: true';


--
-- Name: COLUMN acorn_notary_requests.name; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON COLUMN public.acorn_notary_requests.name IS 'hidden: true';


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
    from_user_group_id uuid,
    location_id uuid
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
-- Name: acorn_criminal_detention_periods acorn_criminal_detention_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_periods
    ADD CONSTRAINT acorn_criminal_detention_periods_pkey PRIMARY KEY (id);


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
-- Name: acorn_criminal_witness_statement acorn_criminal_witness_statement_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_witness_statement
    ADD CONSTRAINT acorn_criminal_witness_statement_pkey PRIMARY KEY (id);


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
-- Name: acorn_justice_periods acorn_justice_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_periods
    ADD CONSTRAINT acorn_justice_periods_pkey PRIMARY KEY (id);


--
-- Name: acorn_justice_scanned_documents acorn_justice_scanned_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_scanned_documents
    ADD CONSTRAINT acorn_justice_scanned_documents_pkey PRIMARY KEY (id);


--
-- Name: acorn_justice_statements acorn_justice_statements_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_statements
    ADD CONSTRAINT acorn_justice_statements_pkey PRIMARY KEY (id);


--
-- Name: acorn_justice_summon_types acorn_justice_summon_types_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summon_types
    ADD CONSTRAINT acorn_justice_summon_types_pkey PRIMARY KEY (id);


--
-- Name: acorn_justice_summons acorn_justice_summons_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summons
    ADD CONSTRAINT acorn_justice_summons_pkey PRIMARY KEY (id);


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
-- Name: acorn_notary_requests acorn_notary_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_notary_requests
    ADD CONSTRAINT acorn_notary_requests_pkey PRIMARY KEY (id);


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
-- Name: acorn_criminal_legalcase_defendants verdict; Type: CHECK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE public.acorn_criminal_legalcase_defendants
    ADD CONSTRAINT verdict CHECK (((verdict = 'G'::bpchar) OR (verdict = 'I'::bpchar))) NOT VALID;


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
-- Name: fki_calendar_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_calendar_id ON public.acorn_calendar_event_types USING btree (calendar_id);


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
-- Name: fki_defendant_detention_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_defendant_detention_id ON public.acorn_criminal_detention_periods USING btree (defendant_detention_id);


--
-- Name: fki_defendant_detention_id2; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_defendant_detention_id2 ON public.acorn_criminal_detention_periods USING btree (defendant_detention_id);


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
-- Name: fki_lawyer_user_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_lawyer_user_id ON public.acorn_criminal_legalcase_defendants USING btree (lawyer_user_id);


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
-- Name: fki_legalcase_witness_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_legalcase_witness_id ON public.acorn_criminal_witness_statement USING btree (legalcase_witness_id);


--
-- Name: fki_location_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_location_id ON public.acorn_lojistiks_offices USING btree (location_id);


--
-- Name: fki_method_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_method_id ON public.acorn_criminal_defendant_detentions USING btree (detention_method_id);


--
-- Name: fki_notary_request_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_notary_request_id ON public.acorn_justice_warrants USING btree (notary_request_id);


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
-- Name: fki_period_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_period_id ON public.acorn_criminal_detention_periods USING btree (period_id);


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
-- Name: fki_summons_notary_request_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_summons_notary_request_id ON public.acorn_justice_summons USING btree (notary_request_id);


--
-- Name: fki_summons_revoked_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_summons_revoked_at_event_id ON public.acorn_justice_summons USING btree (revoked_at_event_id);


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
-- Name: fki_validated_at_event_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_validated_at_event_id ON public.acorn_notary_requests USING btree (validated_at_event_id);


--
-- Name: fki_validated_by_user_id; Type: INDEX; Schema: public; Owner: justice
--

CREATE INDEX fki_validated_by_user_id ON public.acorn_notary_requests USING btree (validated_by_notary_user_id);


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

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON product.acorn_lojistiks_computer_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_electronic_products tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: product; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON product.acorn_lojistiks_electronic_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


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
-- Name: acorn_criminal_detention_periods tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_detention_periods FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_justice_periods tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_justice_periods FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_notary_requests tr_acorn_calendar_trigger_activity_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_activity_event BEFORE INSERT OR UPDATE ON public.acorn_notary_requests FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_appeals tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_appeals FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_crime_sentences tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_crime_sentences FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_crimes tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_crimes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_defendant_crimes tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_defendant_crimes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_detention_methods tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_detention_methods FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_detention_reasons tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_detention_reasons FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_legalcase_defendants tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_defendants FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_legalcase_evidence tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_evidence FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_legalcase_plaintiffs tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_plaintiffs FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_legalcase_types tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_legalcase_witnesses tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_witnesses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_sentence_types tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_sentence_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_session_recordings tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_session_recordings FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_trial_judges tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_trial_judges FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_trial_sessions tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_trial_sessions FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_trials tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_criminal_trials FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_finance_currencies tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_finance_currencies FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_finance_invoices tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_finance_invoices FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_finance_payments tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_finance_payments FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_finance_purchases tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_finance_purchases FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_finance_receipts tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_finance_receipts FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_justice_legalcase_categories tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_legalcase_categories FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_justice_scanned_documents tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_scanned_documents FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_justice_statements tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_statements FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_justice_summon_types tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_summon_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_justice_summons tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_summons FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_justice_warrant_types tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_warrant_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_justice_warrants tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_warrants FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_brands tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_brands FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_containers tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_containers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_drivers tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_drivers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_employees tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_employees FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_measurement_units tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_measurement_units FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_offices tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_offices FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_people tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_people FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_product_attributes tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_product_attributes FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_product_categories tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_product_categories FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_product_category_types tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_product_category_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_product_instances tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_product_instances FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_product_products tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_product_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_products tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_products FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_suppliers tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_suppliers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_transfers tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_transfers FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_vehicle_types tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_vehicle_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_vehicles tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_vehicles FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_lojistiks_warehouses tr_acorn_calendar_trigger_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_calendar_trigger_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_lojistiks_warehouses FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_crime_types tr_acorn_criminal_crime_types; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_criminal_crime_types BEFORE INSERT OR UPDATE ON public.acorn_criminal_crime_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_legalcase_prosecutor tr_acorn_criminal_legalcase_prosecutor; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_criminal_legalcase_prosecutor BEFORE INSERT OR UPDATE ON public.acorn_criminal_legalcase_prosecutor FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_criminal_witness_statement tr_acorn_criminal_witness_statement; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_criminal_witness_statement BEFORE INSERT OR UPDATE ON public.acorn_criminal_witness_statement FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_justice_legalcases tr_acorn_justice_created_at_event; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_justice_created_at_event BEFORE INSERT OR UPDATE ON public.acorn_justice_legalcases FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


--
-- Name: acorn_justice_legalcase_legalcase_category tr_acorn_justice_legalcase_legalcase_category; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_justice_legalcase_legalcase_category BEFORE INSERT OR UPDATE ON public.acorn_justice_legalcase_legalcase_category FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_calendar_trigger_activity_event();


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
-- Name: acorn_notary_requests tr_acorn_notary_trigger_validate; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_notary_trigger_validate BEFORE UPDATE ON public.acorn_notary_requests FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_notary_trigger_validate();


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
-- Name: acorn_criminal_detention_periods tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_criminal_detention_periods FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


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
-- Name: acorn_justice_legalcases tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_legalcases FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_periods tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_periods FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_scanned_documents tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_scanned_documents FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_statements tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_statements FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_summon_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_summon_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_summons tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_summons FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_warrant_types tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_warrant_types FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_justice_warrants tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_justice_warrants FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


--
-- Name: acorn_notary_requests tr_acorn_server_id; Type: TRIGGER; Schema: public; Owner: justice
--

CREATE TRIGGER tr_acorn_server_id BEFORE INSERT ON public.acorn_notary_requests FOR EACH ROW EXECUTE FUNCTION public.fn_acorn_server_id();


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
-- Name: acorn_calendar_event_types calendar_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_types
    ADD CONSTRAINT calendar_id FOREIGN KEY (calendar_id) REFERENCES public.acorn_calendar_calendars(id) NOT VALID;


--
-- Name: acorn_calendar_event_statuses calendar_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_calendar_event_statuses
    ADD CONSTRAINT calendar_id FOREIGN KEY (calendar_id) REFERENCES public.acorn_calendar_calendars(id) NOT VALID;


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
-- Name: acorn_notary_requests created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_notary_requests
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_summon_types created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summon_types
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_justice_summons created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summons
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_justice_statements created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_statements
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_witness_statement created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_witness_statement
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_detention_periods created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_periods
    ADD CONSTRAINT created_at_event_id FOREIGN KEY (created_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_periods created_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_periods
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
-- Name: acorn_notary_requests created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_notary_requests
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_summon_types created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summon_types
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_justice_summons created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summons
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_justice_statements created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_statements
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_witness_statement created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_witness_statement
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_detention_periods created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_periods
    ADD CONSTRAINT created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_periods created_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_periods
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
-- Name: acorn_criminal_detention_periods defendant_detention_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_periods
    ADD CONSTRAINT defendant_detention_id FOREIGN KEY (defendant_detention_id) REFERENCES public.acorn_criminal_defendant_detentions(id);


--
-- Name: CONSTRAINT defendant_detention_id ON acorn_criminal_detention_periods; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT defendant_detention_id ON public.acorn_criminal_detention_periods IS 'multi:
  sum: period[period]';


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
-- Name: acorn_criminal_legalcase_defendants lawyer_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_defendants
    ADD CONSTRAINT lawyer_user_id FOREIGN KEY (lawyer_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_plaintiffs lawyer_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_plaintiffs
    ADD CONSTRAINT lawyer_user_id FOREIGN KEY (lawyer_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


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
-- Name: acorn_criminal_legalcase_evidence legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_evidence
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_prosecutor legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_prosecutor
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_plaintiffs legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_plaintiffs
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) NOT VALID;


--
-- Name: acorn_criminal_legalcase_witnesses legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcase_witnesses
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_criminal_legalcases(id) NOT VALID;


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
';


--
-- Name: acorn_justice_summons legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summons
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_justice_legalcases(id);


--
-- Name: CONSTRAINT legalcase_id ON acorn_justice_summons; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_justice_summons IS 'tab-location: 2
type: Xto1';


--
-- Name: acorn_justice_statements legalcase_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_statements
    ADD CONSTRAINT legalcase_id FOREIGN KEY (legalcase_id) REFERENCES public.acorn_justice_legalcases(id);


--
-- Name: CONSTRAINT legalcase_id ON acorn_justice_statements; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT legalcase_id ON public.acorn_justice_statements IS 'tab-location: 2
type: Xto1';


--
-- Name: acorn_criminal_legalcases legalcase_type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_legalcases
    ADD CONSTRAINT legalcase_type_id FOREIGN KEY (legalcase_type_id) REFERENCES public.acorn_criminal_legalcase_types(id) NOT VALID;


--
-- Name: acorn_criminal_witness_statement legalcase_witness_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_witness_statement
    ADD CONSTRAINT legalcase_witness_id FOREIGN KEY (legalcase_witness_id) REFERENCES public.acorn_criminal_legalcase_witnesses(id) NOT VALID;


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
-- Name: acorn_user_user_groups location_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_user_user_groups
    ADD CONSTRAINT location_id FOREIGN KEY (location_id) REFERENCES public.acorn_location_locations(id) NOT VALID;


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
-- Name: acorn_justice_warrants notary_request_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_warrants
    ADD CONSTRAINT notary_request_id FOREIGN KEY (notary_request_id) REFERENCES public.acorn_notary_requests(id) NOT VALID;


--
-- Name: CONSTRAINT notary_request_id ON acorn_justice_warrants; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT notary_request_id ON public.acorn_justice_warrants IS 'read-only: true
cssClasses: 
  - hide-empty 
  - single-tab
labels:
  en: Document
labels-plural:
  en: Documents';


--
-- Name: acorn_justice_summons notary_request_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summons
    ADD CONSTRAINT notary_request_id FOREIGN KEY (notary_request_id) REFERENCES public.acorn_notary_requests(id);


--
-- Name: CONSTRAINT notary_request_id ON acorn_justice_summons; Type: COMMENT; Schema: public; Owner: justice
--

COMMENT ON CONSTRAINT notary_request_id ON public.acorn_justice_summons IS 'read-only: true
cssClasses: 
  - hide-empty 
  - single-tab
labels:
  en: Document
labels-plural:
  en: Documents';


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
-- Name: acorn_criminal_detention_periods period_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_periods
    ADD CONSTRAINT period_id FOREIGN KEY (period_id) REFERENCES public.acorn_justice_periods(id) NOT VALID;


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
-- Name: acorn_justice_summons revoked_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summons
    ADD CONSTRAINT revoked_at_event_id FOREIGN KEY (revoked_at_event_id) REFERENCES public.acorn_calendar_events(id) ON DELETE SET NULL;


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
-- Name: acorn_notary_requests server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_notary_requests
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_justice_summon_types server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summon_types
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_justice_summons server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summons
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_justice_statements server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_statements
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id);


--
-- Name: acorn_criminal_detention_periods server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_periods
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_justice_periods server_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_periods
    ADD CONSTRAINT server_id FOREIGN KEY (server_id) REFERENCES public.acorn_servers(id) NOT VALID;


--
-- Name: acorn_criminal_witness_statement statement_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_witness_statement
    ADD CONSTRAINT statement_id FOREIGN KEY (statement_id) REFERENCES public.acorn_justice_statements(id);


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
-- Name: acorn_justice_summons type_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summons
    ADD CONSTRAINT type_id FOREIGN KEY (summon_type_id) REFERENCES public.acorn_justice_summon_types(id);


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
-- Name: acorn_notary_requests updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_notary_requests
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_summon_types updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summon_types
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_justice_summons updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summons
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_justice_statements updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_statements
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_witness_statement updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_witness_statement
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id);


--
-- Name: acorn_criminal_detention_periods updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_periods
    ADD CONSTRAINT updated_at_event_id FOREIGN KEY (updated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_justice_periods updated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_periods
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
-- Name: acorn_notary_requests updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_notary_requests
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_summon_types updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summon_types
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_justice_summons updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summons
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_justice_statements updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_statements
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_witness_statement updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_witness_statement
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_criminal_detention_periods updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_criminal_detention_periods
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


--
-- Name: acorn_justice_periods updated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_periods
    ADD CONSTRAINT updated_by_user_id FOREIGN KEY (updated_by_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


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
-- Name: acorn_justice_summons user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_summons
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_justice_statements user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_justice_statements
    ADD CONSTRAINT user_id FOREIGN KEY (user_id) REFERENCES public.acorn_user_users(id);


--
-- Name: acorn_lojistiks_employees user_role_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_lojistiks_employees
    ADD CONSTRAINT user_role_id FOREIGN KEY (user_role_id) REFERENCES public.acorn_user_roles(id) NOT VALID;


--
-- Name: acorn_notary_requests validated_at_event_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_notary_requests
    ADD CONSTRAINT validated_at_event_id FOREIGN KEY (validated_at_event_id) REFERENCES public.acorn_calendar_events(id) NOT VALID;


--
-- Name: acorn_notary_requests validated_by_user_id; Type: FK CONSTRAINT; Schema: public; Owner: justice
--

ALTER TABLE ONLY public.acorn_notary_requests
    ADD CONSTRAINT validated_by_user_id FOREIGN KEY (validated_by_notary_user_id) REFERENCES public.acorn_user_users(id) NOT VALID;


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
-- Name: acorn_criminal_legalcases IsInOwnerGroup; Type: POLICY; Schema: public; Owner: justice
--

CREATE POLICY "IsInOwnerGroup" ON public.acorn_criminal_legalcases FOR SELECT USING ((EXISTS ( SELECT jc.id
   FROM ((public.acorn_justice_legalcases jc
     JOIN public.acorn_user_user_group uug ON ((uug.user_group_id = jc.owner_user_group_id)))
     JOIN public.backend_users bu ON ((uug.user_id = bu.acorn_user_user_id)))
  WHERE ((jc.id = acorn_criminal_legalcases.legalcase_id) AND (('token_'::text || (bu.id)::text) = CURRENT_USER)))));


--
-- Name: acorn_criminal_legalcases IsSuperUser; Type: POLICY; Schema: public; Owner: justice
--

CREATE POLICY "IsSuperUser" ON public.acorn_criminal_legalcases FOR SELECT USING ((EXISTS ( SELECT u.id
   FROM public.acorn_user_users u
  WHERE (((u.name)::text = CURRENT_USER) AND u.is_superuser))));


--
-- Name: acorn_criminal_legalcases; Type: ROW SECURITY; Schema: public; Owner: justice
--

ALTER TABLE public.acorn_criminal_legalcases ENABLE ROW LEVEL SECURITY;

--
-- Name: SCHEMA product; Type: ACL; Schema: -; Owner: justice
--

GRANT ALL ON SCHEMA product TO demo;
GRANT USAGE ON SCHEMA product TO PUBLIC;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: justice
--

REVOKE ALL ON SCHEMA public FROM justice;
REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO justice WITH GRANT OPTION;
GRANT ALL ON SCHEMA public TO admin;
GRANT ALL ON SCHEMA public TO token_1 WITH GRANT OPTION;
GRANT ALL ON SCHEMA public TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SCHEMA public TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SCHEMA public TO test WITH GRANT OPTION;
GRANT ALL ON SCHEMA public TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_in(cstring); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_in(cstring) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_in(cstring) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_in(cstring) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_in(cstring) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_in(cstring) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_in(cstring) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_out(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_out(public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_out(public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_out(public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_out(public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_out(public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_out(public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_recv(internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_recv(internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_recv(internal) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_recv(internal) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_recv(internal) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_recv(internal) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_recv(internal) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_send(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_send(public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_send(public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_send(public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_send(public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_send(public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_send(public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION bytea_to_text(data bytea); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.bytea_to_text(data bytea) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.bytea_to_text(data bytea) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.bytea_to_text(data bytea) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.bytea_to_text(data bytea) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.bytea_to_text(data bytea) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.bytea_to_text(data bytea) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube(double precision[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision[]) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision[]) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube(double precision[]) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube(double precision[]) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision[]) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube(double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube(double precision) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube(double precision) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube(double precision[], double precision[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision[], double precision[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision[], double precision[]) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision[], double precision[]) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube(double precision[], double precision[]) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube(double precision[], double precision[]) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision[], double precision[]) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube(double precision, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(double precision, double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision, double precision) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision, double precision) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube(double precision, double precision) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube(double precision, double precision) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(double precision, double precision) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube(public.cube, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(public.cube, double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube(public.cube, double precision, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube(public.cube, double precision, double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision, double precision) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision, double precision) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision, double precision) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision, double precision) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube(public.cube, double precision, double precision) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_cmp(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_cmp(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_cmp(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_cmp(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_cmp(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_cmp(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_cmp(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_contained(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_contained(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_contained(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_contained(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_contained(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_contained(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_contained(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_contains(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_contains(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_contains(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_contains(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_contains(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_contains(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_contains(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_coord(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_coord(public.cube, integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_coord(public.cube, integer) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_coord(public.cube, integer) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_coord(public.cube, integer) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_coord(public.cube, integer) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_coord(public.cube, integer) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_coord_llur(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_coord_llur(public.cube, integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_coord_llur(public.cube, integer) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_coord_llur(public.cube, integer) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_coord_llur(public.cube, integer) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_coord_llur(public.cube, integer) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_coord_llur(public.cube, integer) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_dim(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_dim(public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_dim(public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_dim(public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_dim(public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_dim(public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_dim(public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_distance(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_distance(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_distance(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_distance(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_distance(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_distance(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_distance(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_enlarge(public.cube, double precision, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_enlarge(public.cube, double precision, integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_enlarge(public.cube, double precision, integer) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_enlarge(public.cube, double precision, integer) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_enlarge(public.cube, double precision, integer) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_enlarge(public.cube, double precision, integer) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_enlarge(public.cube, double precision, integer) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_eq(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_eq(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_eq(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_eq(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_eq(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_eq(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_eq(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_ge(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ge(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ge(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ge(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_ge(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_ge(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ge(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_gt(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_gt(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_gt(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_gt(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_gt(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_gt(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_gt(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_inter(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_inter(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_inter(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_inter(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_inter(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_inter(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_inter(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_is_point(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_is_point(public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_is_point(public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_is_point(public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_is_point(public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_is_point(public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_is_point(public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_le(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_le(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_le(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_le(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_le(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_le(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_le(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_ll_coord(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ll_coord(public.cube, integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ll_coord(public.cube, integer) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ll_coord(public.cube, integer) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_ll_coord(public.cube, integer) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_ll_coord(public.cube, integer) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ll_coord(public.cube, integer) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_lt(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_lt(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_lt(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_lt(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_lt(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_lt(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_lt(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_ne(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ne(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ne(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ne(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_ne(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_ne(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ne(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_overlap(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_overlap(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_overlap(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_overlap(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_overlap(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_overlap(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_overlap(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_size(public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_size(public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_size(public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_size(public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_size(public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_size(public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_size(public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_subset(public.cube, integer[]); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_subset(public.cube, integer[]) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_subset(public.cube, integer[]) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_subset(public.cube, integer[]) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_subset(public.cube, integer[]) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_subset(public.cube, integer[]) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_subset(public.cube, integer[]) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_union(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_union(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_union(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_union(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_union(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_union(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_union(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION cube_ur_coord(public.cube, integer); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.cube_ur_coord(public.cube, integer) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ur_coord(public.cube, integer) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ur_coord(public.cube, integer) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.cube_ur_coord(public.cube, integer) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.cube_ur_coord(public.cube, integer) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.cube_ur_coord(public.cube, integer) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION distance_chebyshev(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.distance_chebyshev(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.distance_chebyshev(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.distance_chebyshev(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.distance_chebyshev(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.distance_chebyshev(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.distance_chebyshev(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION distance_taxicab(public.cube, public.cube); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.distance_taxicab(public.cube, public.cube) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.distance_taxicab(public.cube, public.cube) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.distance_taxicab(public.cube, public.cube) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.distance_taxicab(public.cube, public.cube) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.distance_taxicab(public.cube, public.cube) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.distance_taxicab(public.cube, public.cube) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION earth(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.earth() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth() TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth() TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.earth() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.earth() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth() TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION earth_box(public.earth, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.earth_box(public.earth, double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth_box(public.earth, double precision) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth_box(public.earth, double precision) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.earth_box(public.earth, double precision) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.earth_box(public.earth, double precision) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth_box(public.earth, double precision) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION earth_distance(public.earth, public.earth); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.earth_distance(public.earth, public.earth) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth_distance(public.earth, public.earth) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth_distance(public.earth, public.earth) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.earth_distance(public.earth, public.earth) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.earth_distance(public.earth, public.earth) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.earth_distance(public.earth, public.earth) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_add_websockets_triggers(schema character varying, table_prefix character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO token_2;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_activity_log_event(owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying); Type: ACL; Schema: public; Owner: justice
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, type_id uuid, status_id uuid, name character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone); Type: ACL; Schema: public; Owner: justice
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_create_event(calendar_id uuid, owner_user_id uuid, event_type_id uuid, event_status_id uuid, name character varying, date_from timestamp without time zone, date_to timestamp without time zone) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_events_generate_event_instances(); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_calendar_events_generate_event_instances() FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_events_generate_event_instances() TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_events_generate_event_instances() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_events_generate_event_instances() TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_events_generate_event_instances() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_events_generate_event_instances() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_events_generate_event_instances() TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_generate_event_instances(new_event_part record, old_event_part record) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_is_date(s character varying, d timestamp with time zone); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp with time zone) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp with time zone) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp with time zone) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp with time zone) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp with time zone) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp with time zone) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_is_date(s character varying, d timestamp with time zone) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying); Type: ACL; Schema: public; Owner: justice
--

GRANT ALL ON FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_lazy_create_event(calendar_name character varying, owner_user_id uuid, type_name character varying, status_name character varying, event_name character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_seed(); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_calendar_seed() FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_seed() TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_seed() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_seed() TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_seed() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_seed() TO token_2;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_seed() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_seed() TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_calendar_trigger_activity_event(); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() TO token_2;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_calendar_trigger_activity_event() TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid) TO token_2;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cs(model_id uuid, user_id uuid) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid) TO token_2;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_defendants_cw(model_id uuid, user_id uuid) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcase_related_events_can(primary_id uuid, user_id uuid) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_criminal_action_legalcases_transfer_case(model_id uuid, user_id uuid, owner_user_group_id uuid) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_first(anyelement, anyelement); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_first(anyelement, anyelement) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_first(anyelement, anyelement) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_first(anyelement, anyelement) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_first(anyelement, anyelement) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_first(anyelement, anyelement) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_first(anyelement, anyelement) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_first(anyelement, anyelement) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) TO token_2;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_close_case(model_id uuid, user_id uuid) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_legalcases_reopen_case(model_id uuid, user_id uuid) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_justice_action_warrants_request_notary(model_id uuid, user_id uuid); Type: ACL; Schema: public; Owner: justice
--

GRANT ALL ON FUNCTION public.fn_acorn_justice_action_warrants_request_notary(model_id uuid, user_id uuid) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_warrants_request_notary(model_id uuid, user_id uuid) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_warrants_request_notary(model_id uuid, user_id uuid) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_warrants_request_notary(model_id uuid, user_id uuid) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_action_warrants_revoke(model_id uuid, p_user_id uuid) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_justice_seed_calendar(); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_justice_seed_calendar() FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_calendar() TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_calendar() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_calendar() TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_calendar() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_calendar() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_calendar() TO token_8_no WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_calendar() TO token_2;


--
-- Name: FUNCTION fn_acorn_justice_seed_groups(); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_justice_seed_groups() FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_groups() TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_groups() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_groups() TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_groups() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_groups() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_seed_groups() TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_justice_warrants_state_indicator(warrant record); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_justice_warrants_state_indicator(warrant record) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_justice_warrants_state_indicator(warrant record) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_warrants_state_indicator(warrant record) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_warrants_state_indicator(warrant record) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_warrants_state_indicator(warrant record) TO token_2;
GRANT ALL ON FUNCTION public.fn_acorn_justice_warrants_state_indicator(warrant record) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_justice_warrants_state_indicator(warrant record) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_last(anyelement, anyelement); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_last(anyelement, anyelement) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_last(anyelement, anyelement) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_last(anyelement, anyelement) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_last(anyelement, anyelement) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_last(anyelement, anyelement) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_last(anyelement, anyelement) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_last(anyelement, anyelement) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_lojistiks_distance(source_location_id uuid, destination_location_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_distance(source_location_id uuid, destination_location_id uuid) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_distance(source_location_id uuid, destination_location_id uuid) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_distance(source_location_id uuid, destination_location_id uuid) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_distance(source_location_id uuid, destination_location_id uuid) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_distance(source_location_id uuid, destination_location_id uuid) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_distance(source_location_id uuid, destination_location_id uuid) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_lojistiks_is_date(s character varying, d timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_is_date(s character varying, d timestamp with time zone) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_is_date(s character varying, d timestamp with time zone) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_is_date(s character varying, d timestamp with time zone) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_is_date(s character varying, d timestamp with time zone) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_is_date(s character varying, d timestamp with time zone) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_lojistiks_is_date(s character varying, d timestamp with time zone) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_new_replicated_row(); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_new_replicated_row() FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_new_replicated_row() TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_new_replicated_row() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_new_replicated_row() TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_new_replicated_row() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_new_replicated_row() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_new_replicated_row() TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_notary_trigger_validate(); Type: ACL; Schema: public; Owner: justice
--

GRANT ALL ON FUNCTION public.fn_acorn_notary_trigger_validate() TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_notary_trigger_validate() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_notary_trigger_validate() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_notary_trigger_validate() TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_reset_sequences(schema_like character varying, table_like character varying); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_reset_sequences(schema_like character varying, table_like character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_server_id(); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_server_id() FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_server_id() TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_server_id() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_server_id() TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_server_id() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_server_id() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_server_id() TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_table_counts(_schema character varying); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_table_counts(_schema character varying) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_table_counts(_schema character varying) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_table_counts(_schema character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_table_counts(_schema character varying) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_table_counts(_schema character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_table_counts(_schema character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_table_counts(_schema character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_truncate_database(schema_like character varying, table_like character varying); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_truncate_database(schema_like character varying, table_like character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION fn_acorn_user_get_seed_user(); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.fn_acorn_user_get_seed_user() FROM justice;
GRANT ALL ON FUNCTION public.fn_acorn_user_get_seed_user() TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_get_seed_user() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_get_seed_user() TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.fn_acorn_user_get_seed_user() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.fn_acorn_user_get_seed_user() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_get_seed_user() TO token_8_no WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.fn_acorn_user_get_seed_user() TO token_2;


--
-- Name: FUNCTION g_cube_consistent(internal, public.cube, smallint, oid, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_consistent(internal, public.cube, smallint, oid, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_consistent(internal, public.cube, smallint, oid, internal) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_consistent(internal, public.cube, smallint, oid, internal) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.g_cube_consistent(internal, public.cube, smallint, oid, internal) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.g_cube_consistent(internal, public.cube, smallint, oid, internal) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_consistent(internal, public.cube, smallint, oid, internal) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_distance(internal, public.cube, smallint, oid, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_distance(internal, public.cube, smallint, oid, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_distance(internal, public.cube, smallint, oid, internal) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_distance(internal, public.cube, smallint, oid, internal) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.g_cube_distance(internal, public.cube, smallint, oid, internal) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.g_cube_distance(internal, public.cube, smallint, oid, internal) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_distance(internal, public.cube, smallint, oid, internal) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_penalty(internal, internal, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_penalty(internal, internal, internal) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_penalty(internal, internal, internal) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.g_cube_penalty(internal, internal, internal) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.g_cube_penalty(internal, internal, internal) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_penalty(internal, internal, internal) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_picksplit(internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_picksplit(internal, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_picksplit(internal, internal) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_picksplit(internal, internal) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.g_cube_picksplit(internal, internal) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.g_cube_picksplit(internal, internal) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_picksplit(internal, internal) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_same(public.cube, public.cube, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_same(public.cube, public.cube, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_same(public.cube, public.cube, internal) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_same(public.cube, public.cube, internal) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.g_cube_same(public.cube, public.cube, internal) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.g_cube_same(public.cube, public.cube, internal) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_same(public.cube, public.cube, internal) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION g_cube_union(internal, internal); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.g_cube_union(internal, internal) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_union(internal, internal) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_union(internal, internal) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.g_cube_union(internal, internal) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.g_cube_union(internal, internal) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.g_cube_union(internal, internal) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION gc_to_sec(double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.gc_to_sec(double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.gc_to_sec(double precision) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.gc_to_sec(double precision) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.gc_to_sec(double precision) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.gc_to_sec(double precision) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.gc_to_sec(double precision) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION geo_distance(point, point); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.geo_distance(point, point) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.geo_distance(point, point) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.geo_distance(point, point) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.geo_distance(point, point) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.geo_distance(point, point) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.geo_distance(point, point) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION hostname(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.hostname() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.hostname() TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.hostname() TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.hostname() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.hostname() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.hostname() TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http(request public.http_request); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http(request public.http_request) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http(request public.http_request) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http(request public.http_request) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http(request public.http_request) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http(request public.http_request) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http(request public.http_request) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_delete(uri character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_delete(uri character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_delete(uri character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_delete(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_delete(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying, content character varying, content_type character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying, content character varying, content_type character varying) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_delete(uri character varying, content character varying, content_type character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying, content character varying, content_type character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_delete(uri character varying, content character varying, content_type character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_get(uri character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_get(uri character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_get(uri character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_get(uri character varying) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_get(uri character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_get(uri character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_get(uri character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_get(uri character varying, data jsonb); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_get(uri character varying, data jsonb) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_get(uri character varying, data jsonb) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_get(uri character varying, data jsonb) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_get(uri character varying, data jsonb) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_get(uri character varying, data jsonb) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_get(uri character varying, data jsonb) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_head(uri character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_head(uri character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_head(uri character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_head(uri character varying) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_head(uri character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_head(uri character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_head(uri character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_header(field character varying, value character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_header(field character varying, value character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_header(field character varying, value character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_header(field character varying, value character varying) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_header(field character varying, value character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_header(field character varying, value character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_header(field character varying, value character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_list_curlopt(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_list_curlopt() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_list_curlopt() TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_list_curlopt() TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_list_curlopt() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_list_curlopt() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_list_curlopt() TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_patch(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_patch(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_patch(uri character varying, content character varying, content_type character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_patch(uri character varying, content character varying, content_type character varying) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_patch(uri character varying, content character varying, content_type character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_patch(uri character varying, content character varying, content_type character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_patch(uri character varying, content character varying, content_type character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_post(uri character varying, data jsonb); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_post(uri character varying, data jsonb) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, data jsonb) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, data jsonb) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_post(uri character varying, data jsonb) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, data jsonb) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, data jsonb) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_post(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_post(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, content character varying, content_type character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, content character varying, content_type character varying) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_post(uri character varying, content character varying, content_type character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, content character varying, content_type character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_post(uri character varying, content character varying, content_type character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_put(uri character varying, content character varying, content_type character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_put(uri character varying, content character varying, content_type character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_put(uri character varying, content character varying, content_type character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_put(uri character varying, content character varying, content_type character varying) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_put(uri character varying, content character varying, content_type character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_put(uri character varying, content character varying, content_type character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_put(uri character varying, content character varying, content_type character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_reset_curlopt(); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_reset_curlopt() TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_reset_curlopt() TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_reset_curlopt() TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_reset_curlopt() TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_reset_curlopt() TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_reset_curlopt() TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION http_set_curlopt(curlopt character varying, value character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.http_set_curlopt(curlopt character varying, value character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_set_curlopt(curlopt character varying, value character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_set_curlopt(curlopt character varying, value character varying) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.http_set_curlopt(curlopt character varying, value character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.http_set_curlopt(curlopt character varying, value character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.http_set_curlopt(curlopt character varying, value character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION latitude(public.earth); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.latitude(public.earth) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.latitude(public.earth) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.latitude(public.earth) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.latitude(public.earth) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.latitude(public.earth) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.latitude(public.earth) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION ll_to_earth(double precision, double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.ll_to_earth(double precision, double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.ll_to_earth(double precision, double precision) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.ll_to_earth(double precision, double precision) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.ll_to_earth(double precision, double precision) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.ll_to_earth(double precision, double precision) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.ll_to_earth(double precision, double precision) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION longitude(public.earth); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.longitude(public.earth) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.longitude(public.earth) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.longitude(public.earth) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.longitude(public.earth) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.longitude(public.earth) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.longitude(public.earth) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION sec_to_gc(double precision); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.sec_to_gc(double precision) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.sec_to_gc(double precision) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.sec_to_gc(double precision) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.sec_to_gc(double precision) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.sec_to_gc(double precision) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.sec_to_gc(double precision) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION text_to_bytea(data text); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.text_to_bytea(data text) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.text_to_bytea(data text) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.text_to_bytea(data text) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.text_to_bytea(data text) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.text_to_bytea(data text) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.text_to_bytea(data text) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION urlencode(string bytea); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.urlencode(string bytea) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(string bytea) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(string bytea) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.urlencode(string bytea) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.urlencode(string bytea) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(string bytea) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION urlencode(data jsonb); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.urlencode(data jsonb) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(data jsonb) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(data jsonb) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.urlencode(data jsonb) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.urlencode(data jsonb) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(data jsonb) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION urlencode(string character varying); Type: ACL; Schema: public; Owner: sz
--

GRANT ALL ON FUNCTION public.urlencode(string character varying) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(string character varying) TO demo WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(string character varying) TO justice WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.urlencode(string character varying) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.urlencode(string character varying) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.urlencode(string character varying) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION agg_acorn_first(anyelement); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.agg_acorn_first(anyelement) FROM justice;
GRANT ALL ON FUNCTION public.agg_acorn_first(anyelement) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.agg_acorn_first(anyelement) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.agg_acorn_first(anyelement) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.agg_acorn_first(anyelement) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.agg_acorn_first(anyelement) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.agg_acorn_first(anyelement) TO token_8_no WITH GRANT OPTION;


--
-- Name: FUNCTION agg_acorn_last(anyelement); Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON FUNCTION public.agg_acorn_last(anyelement) FROM justice;
GRANT ALL ON FUNCTION public.agg_acorn_last(anyelement) TO justice WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.agg_acorn_last(anyelement) TO token_1 WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.agg_acorn_last(anyelement) TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON FUNCTION public.agg_acorn_last(anyelement) TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON FUNCTION public.agg_acorn_last(anyelement) TO test WITH GRANT OPTION;
GRANT ALL ON FUNCTION public.agg_acorn_last(anyelement) TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_computer_products; Type: ACL; Schema: product; Owner: justice
--

GRANT ALL ON TABLE product.acorn_lojistiks_computer_products TO demo;
GRANT SELECT ON TABLE product.acorn_lojistiks_computer_products TO PUBLIC;


--
-- Name: TABLE acorn_lojistiks_electronic_products; Type: ACL; Schema: product; Owner: justice
--

GRANT ALL ON TABLE product.acorn_lojistiks_electronic_products TO demo;
GRANT SELECT ON TABLE product.acorn_lojistiks_electronic_products TO PUBLIC;


--
-- Name: TABLE acorn_calendar_calendars; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_calendar_calendars FROM justice;
GRANT ALL ON TABLE public.acorn_calendar_calendars TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_calendars TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_calendars TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_calendar_calendars TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_calendar_calendars TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_calendars TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_event_part_user; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_calendar_event_part_user FROM justice;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_event_part_user_group; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_calendar_event_part_user_group FROM justice;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user_group TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user_group TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user_group TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user_group TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user_group TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_part_user_group TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_event_parts; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_calendar_event_parts FROM justice;
GRANT ALL ON TABLE public.acorn_calendar_event_parts TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_parts TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_parts TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_calendar_event_parts TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_calendar_event_parts TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_parts TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_event_statuses; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_calendar_event_statuses FROM justice;
GRANT ALL ON TABLE public.acorn_calendar_event_statuses TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_statuses TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_statuses TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_calendar_event_statuses TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_calendar_event_statuses TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_statuses TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_event_types; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_calendar_event_types FROM justice;
GRANT ALL ON TABLE public.acorn_calendar_event_types TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_types TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_calendar_event_types TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_calendar_event_types TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_event_types TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_events; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_calendar_events FROM justice;
GRANT ALL ON TABLE public.acorn_calendar_events TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_events TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_events TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_calendar_events TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_calendar_events TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_events TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_calendar_instances; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_calendar_instances FROM justice;
GRANT ALL ON TABLE public.acorn_calendar_instances TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_instances TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_instances TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_calendar_instances TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_calendar_instances TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_calendar_instances TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_appeals; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_appeals FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_appeals TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_appeals TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_appeals TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_appeals TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_appeals TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_appeals TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_crime_evidence; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_crime_evidence FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_crime_evidence TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crime_evidence TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crime_evidence TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_crime_evidence TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_crime_evidence TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crime_evidence TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_crime_sentences; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_crime_sentences FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_crime_sentences TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crime_sentences TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crime_sentences TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_crime_sentences TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_crime_sentences TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crime_sentences TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_crime_types; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_crime_types FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_crime_types TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crime_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crime_types TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_crime_types TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_crime_types TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crime_types TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_crimes; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_crimes FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_crimes TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crimes TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crimes TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_crimes TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_crimes TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_crimes TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_defendant_crimes; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_defendant_crimes FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_defendant_crimes TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_defendant_crimes TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_defendant_crimes TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_defendant_crimes TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_defendant_crimes TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_defendant_crimes TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_defendant_detentions; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_defendant_detentions FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_defendant_detentions TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_defendant_detentions TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_defendant_detentions TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_defendant_detentions TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_defendant_detentions TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_defendant_detentions TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_detention_methods; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_detention_methods FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_detention_methods TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_detention_methods TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_detention_methods TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_detention_methods TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_detention_methods TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_detention_methods TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_detention_periods; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_detention_periods FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_detention_periods TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_detention_periods TO demo WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_detention_periods TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_detention_periods TO token_2;
GRANT ALL ON TABLE public.acorn_criminal_detention_periods TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_detention_periods TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_detention_reasons; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_detention_reasons FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_detention_reasons TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_detention_reasons TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_detention_reasons TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_detention_reasons TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_detention_reasons TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_detention_reasons TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_legalcase_defendants; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_legalcase_defendants FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_defendants TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_defendants TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_defendants TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_defendants TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_defendants TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_defendants TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_legalcase_evidence; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_legalcase_evidence FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_evidence TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_evidence TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_evidence TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_evidence TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_evidence TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_evidence TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_legalcase_plaintiffs; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_legalcase_plaintiffs FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_plaintiffs TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_plaintiffs TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_plaintiffs TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_plaintiffs TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_plaintiffs TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_plaintiffs TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_legalcase_prosecutor; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_legalcase_prosecutor FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_prosecutor TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_prosecutor TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_prosecutor TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_prosecutor TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_prosecutor TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_prosecutor TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_legalcase_related_events; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_legalcase_related_events FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_related_events TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_related_events TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_related_events TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_related_events TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_related_events TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_related_events TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_legalcase_types; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_legalcase_types FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_types TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_types TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_types TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_types TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_types TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_legalcase_witnesses; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_legalcase_witnesses FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_witnesses TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_witnesses TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_witnesses TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_witnesses TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_witnesses TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcase_witnesses TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_legalcases; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_legalcases FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_legalcases TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcases TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcases TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_legalcases TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_legalcases TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_legalcases TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_sentence_types; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_sentence_types FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_sentence_types TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_sentence_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_sentence_types TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_sentence_types TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_sentence_types TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_sentence_types TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_session_recordings; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_session_recordings FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_session_recordings TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_session_recordings TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_session_recordings TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_session_recordings TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_session_recordings TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_session_recordings TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_trial_judges; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_trial_judges FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_trial_judges TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_trial_judges TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_trial_judges TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_trial_judges TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_trial_judges TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_trial_judges TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_trial_sessions; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_trial_sessions FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_trial_sessions TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_trial_sessions TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_trial_sessions TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_trial_sessions TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_trial_sessions TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_trial_sessions TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_trials; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_trials FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_trials TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_trials TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_trials TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_criminal_trials TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_criminal_trials TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_trials TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_criminal_witness_statement; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_criminal_witness_statement FROM justice;
GRANT ALL ON TABLE public.acorn_criminal_witness_statement TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_witness_statement TO demo WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_witness_statement TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_witness_statement TO token_2;
GRANT ALL ON TABLE public.acorn_criminal_witness_statement TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_criminal_witness_statement TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_finance_currencies; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_finance_currencies FROM justice;
GRANT ALL ON TABLE public.acorn_finance_currencies TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_currencies TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_currencies TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_finance_currencies TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_finance_currencies TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_currencies TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_finance_invoices; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_finance_invoices FROM justice;
GRANT ALL ON TABLE public.acorn_finance_invoices TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_invoices TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_invoices TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_finance_invoices TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_finance_invoices TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_invoices TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_finance_payments; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_finance_payments FROM justice;
GRANT ALL ON TABLE public.acorn_finance_payments TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_payments TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_payments TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_finance_payments TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_finance_payments TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_payments TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_finance_purchases; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_finance_purchases FROM justice;
GRANT ALL ON TABLE public.acorn_finance_purchases TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_purchases TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_purchases TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_finance_purchases TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_finance_purchases TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_purchases TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_finance_receipts; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_finance_receipts FROM justice;
GRANT ALL ON TABLE public.acorn_finance_receipts TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_receipts TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_receipts TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_finance_receipts TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_finance_receipts TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_finance_receipts TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_justice_legalcase_categories; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_justice_legalcase_categories FROM justice;
GRANT ALL ON TABLE public.acorn_justice_legalcase_categories TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_legalcase_categories TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_legalcase_categories TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_justice_legalcase_categories TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_justice_legalcase_categories TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_legalcase_categories TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_justice_legalcase_legalcase_category; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_justice_legalcase_legalcase_category FROM justice;
GRANT ALL ON TABLE public.acorn_justice_legalcase_legalcase_category TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_legalcase_legalcase_category TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_legalcase_legalcase_category TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_justice_legalcase_legalcase_category TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_justice_legalcase_legalcase_category TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_legalcase_legalcase_category TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_justice_legalcases; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_justice_legalcases FROM justice;
GRANT ALL ON TABLE public.acorn_justice_legalcases TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_legalcases TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_legalcases TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_justice_legalcases TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_justice_legalcases TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_legalcases TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_justice_periods; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_justice_periods FROM justice;
GRANT ALL ON TABLE public.acorn_justice_periods TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_periods TO demo WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_periods TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_periods TO token_2;
GRANT ALL ON TABLE public.acorn_justice_periods TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_periods TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_justice_scanned_documents; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_justice_scanned_documents FROM justice;
GRANT ALL ON TABLE public.acorn_justice_scanned_documents TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_scanned_documents TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_scanned_documents TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_justice_scanned_documents TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_justice_scanned_documents TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_scanned_documents TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_justice_statements; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_justice_statements FROM justice;
GRANT ALL ON TABLE public.acorn_justice_statements TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_statements TO demo WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_statements TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_statements TO token_2;
GRANT ALL ON TABLE public.acorn_justice_statements TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_statements TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_justice_summon_types; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_justice_summon_types FROM justice;
GRANT ALL ON TABLE public.acorn_justice_summon_types TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_summon_types TO demo WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_summon_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_summon_types TO token_2;
GRANT ALL ON TABLE public.acorn_justice_summon_types TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_summon_types TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_justice_summons; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_justice_summons FROM justice;
GRANT ALL ON TABLE public.acorn_justice_summons TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_summons TO demo WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_summons TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_summons TO token_2;
GRANT ALL ON TABLE public.acorn_justice_summons TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_summons TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_justice_warrant_types; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_justice_warrant_types FROM justice;
GRANT ALL ON TABLE public.acorn_justice_warrant_types TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_warrant_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_warrant_types TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_justice_warrant_types TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_justice_warrant_types TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_warrant_types TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_justice_warrants; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_justice_warrants FROM justice;
GRANT ALL ON TABLE public.acorn_justice_warrants TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_warrants TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_warrants TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_justice_warrants TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_justice_warrants TO PUBLIC;
GRANT ALL ON TABLE public.acorn_justice_warrants TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_justice_warrants TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_addresses; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_location_addresses FROM justice;
GRANT ALL ON TABLE public.acorn_location_addresses TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_addresses TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_addresses TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_location_addresses TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_location_addresses TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_addresses TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_area_types; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_location_area_types FROM justice;
GRANT ALL ON TABLE public.acorn_location_area_types TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_area_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_area_types TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_location_area_types TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_location_area_types TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_area_types TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_areas; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_location_areas FROM justice;
GRANT ALL ON TABLE public.acorn_location_areas TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_areas TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_areas TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_location_areas TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_location_areas TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_areas TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_gps; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_location_gps FROM justice;
GRANT ALL ON TABLE public.acorn_location_gps TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_gps TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_gps TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_location_gps TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_location_gps TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_gps TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_locations; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_location_locations FROM justice;
GRANT ALL ON TABLE public.acorn_location_locations TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_locations TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_locations TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_location_locations TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_location_locations TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_locations TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_lookup; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_location_lookup FROM justice;
GRANT ALL ON TABLE public.acorn_location_lookup TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_lookup TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_lookup TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_location_lookup TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_location_lookup TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_lookup TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_location_types; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_location_types FROM justice;
GRANT ALL ON TABLE public.acorn_location_types TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_types TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_location_types TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_location_types TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_location_types TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_brands; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_brands FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_brands TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_brands TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_brands TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_brands TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_brands TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_brands TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_containers; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_containers FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_containers TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_containers TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_containers TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_containers TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_containers TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_containers TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_drivers; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_drivers FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_drivers TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_drivers TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_drivers TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_drivers TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_drivers TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_drivers TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_employees; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_employees FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_employees TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_employees TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_employees TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_employees TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_employees TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_employees TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_measurement_units; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_measurement_units FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_measurement_units TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_measurement_units TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_measurement_units TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_measurement_units TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_measurement_units TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_measurement_units TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_offices; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_offices FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_offices TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_offices TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_offices TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_offices TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_offices TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_offices TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_people; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_people FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_people TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_people TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_people TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_people TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_people TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_people TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_product_attributes; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_product_attributes FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_product_attributes TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_attributes TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_attributes TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_product_attributes TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_attributes TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_attributes TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_product_categories; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_product_categories FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_product_categories TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_categories TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_categories TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_product_categories TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_categories TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_categories TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_product_category_types; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_product_category_types FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_product_category_types TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_category_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_category_types TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_product_category_types TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_category_types TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_category_types TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_product_instance_transfer; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_product_instance_transfer FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instance_transfer TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instance_transfer TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instance_transfer TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instance_transfer TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instance_transfer TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instance_transfer TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_product_instances; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_product_instances FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instances TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instances TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instances TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instances TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instances TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_instances TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_product_product_category; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_product_product_category FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_product_product_category TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_product_category TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_product_category TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_product_product_category TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_product_category TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_product_category TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_product_products; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_product_products FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_product_products TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_products TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_products TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_product_products TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_products TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_product_products TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_products; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_products FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_products TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_products TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_products TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_products TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_products TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_products TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_products_product_category; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_products_product_category FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_products_product_category TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_products_product_category TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_products_product_category TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_products_product_category TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_products_product_category TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_products_product_category TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_suppliers; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_suppliers FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_suppliers TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_suppliers TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_suppliers TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_suppliers TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_suppliers TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_suppliers TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_transfer_container_product_instance; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_transfer_container_product_instance FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_container_product_instance TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_container_product_instance TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_container_product_instance TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_container_product_instance TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_container_product_instance TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_container_product_instance TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_transfer_containers; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_transfer_containers FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_containers TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_containers TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_containers TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_containers TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_containers TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_containers TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_transfer_invoice; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_transfer_invoice FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_invoice TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_invoice TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_invoice TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_invoice TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_invoice TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_invoice TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_transfer_purchase; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_transfer_purchase FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_purchase TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_purchase TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_purchase TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_purchase TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_purchase TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfer_purchase TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_transfers; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_transfers FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_transfers TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfers TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfers TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_transfers TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfers TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_transfers TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_vehicle_types; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_vehicle_types FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicle_types TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicle_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicle_types TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicle_types TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicle_types TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicle_types TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_vehicles; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_vehicles FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicles TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicles TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicles TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicles TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicles TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_vehicles TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_lojistiks_warehouses; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_lojistiks_warehouses FROM justice;
GRANT ALL ON TABLE public.acorn_lojistiks_warehouses TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_warehouses TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_warehouses TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_lojistiks_warehouses TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_lojistiks_warehouses TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_lojistiks_warehouses TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_action; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_messaging_action FROM justice;
GRANT ALL ON TABLE public.acorn_messaging_action TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_action TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_action TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_messaging_action TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_messaging_action TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_action TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_label; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_messaging_label FROM justice;
GRANT ALL ON TABLE public.acorn_messaging_label TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_label TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_label TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_messaging_label TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_messaging_label TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_label TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_message; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_messaging_message FROM justice;
GRANT ALL ON TABLE public.acorn_messaging_message TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_messaging_message TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_messaging_message TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_message_instance; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_messaging_message_instance FROM justice;
GRANT ALL ON TABLE public.acorn_messaging_message_instance TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_instance TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_instance TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_messaging_message_instance TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_messaging_message_instance TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_instance TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_message_message; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_messaging_message_message FROM justice;
GRANT ALL ON TABLE public.acorn_messaging_message_message TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_message TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_message TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_messaging_message_message TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_messaging_message_message TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_message TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_message_user; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_messaging_message_user FROM justice;
GRANT ALL ON TABLE public.acorn_messaging_message_user TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_user TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_user TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_messaging_message_user TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_messaging_message_user TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_user TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_message_user_group; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_messaging_message_user_group FROM justice;
GRANT ALL ON TABLE public.acorn_messaging_message_user_group TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_user_group TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_user_group TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_messaging_message_user_group TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_messaging_message_user_group TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_message_user_group TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_status; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_messaging_status FROM justice;
GRANT ALL ON TABLE public.acorn_messaging_status TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_status TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_status TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_messaging_status TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_messaging_status TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_status TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_messaging_user_message_status; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_messaging_user_message_status FROM justice;
GRANT ALL ON TABLE public.acorn_messaging_user_message_status TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_user_message_status TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_user_message_status TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_messaging_user_message_status TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_messaging_user_message_status TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_messaging_user_message_status TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_notary_requests; Type: ACL; Schema: public; Owner: justice
--

GRANT ALL ON TABLE public.acorn_notary_requests TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_notary_requests TO PUBLIC;
GRANT ALL ON TABLE public.acorn_notary_requests TO demo WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_notary_requests TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_notary_requests TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_servers; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_servers FROM justice;
GRANT ALL ON TABLE public.acorn_servers TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_servers TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_servers TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_servers TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_servers TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_servers TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_language_user; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_language_user FROM justice;
GRANT ALL ON TABLE public.acorn_user_language_user TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_language_user TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_language_user TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_language_user TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_language_user TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_language_user TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_languages; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_languages FROM justice;
GRANT ALL ON TABLE public.acorn_user_languages TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_languages TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_languages TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_languages TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_languages TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_languages TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_mail_blockers; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_mail_blockers FROM justice;
GRANT ALL ON TABLE public.acorn_user_mail_blockers TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_mail_blockers TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_mail_blockers TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_mail_blockers TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_mail_blockers TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_mail_blockers TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_roles; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_roles FROM justice;
GRANT ALL ON TABLE public.acorn_user_roles TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_roles TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_roles TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_roles TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_roles TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_roles TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_throttle; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_throttle FROM justice;
GRANT ALL ON TABLE public.acorn_user_throttle TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_throttle TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_throttle TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_throttle TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_throttle TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_throttle TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_user_group; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_user_group FROM justice;
GRANT ALL ON TABLE public.acorn_user_user_group TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_user_group TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_user_group TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_user_group_types; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_user_group_types FROM justice;
GRANT ALL ON TABLE public.acorn_user_user_group_types TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_types TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_types TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_user_group_types TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_user_group_types TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_types TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_user_group_version_usages; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_user_group_version_usages FROM justice;
GRANT ALL ON TABLE public.acorn_user_user_group_version_usages TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_version_usages TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_version_usages TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_user_group_version_usages TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_user_group_version_usages TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_version_usages TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_user_group_version_user; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_user_group_version_user FROM justice;
GRANT ALL ON TABLE public.acorn_user_user_group_version_user TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_version_user TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_version_user TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_user_group_version_user TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_user_group_version_user TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_version_user TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_user_group_versions; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_user_group_versions FROM justice;
GRANT ALL ON TABLE public.acorn_user_user_group_versions TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_versions TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_versions TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_user_group_versions TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_user_group_versions TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_group_versions TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_user_groups; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_user_groups FROM justice;
GRANT ALL ON TABLE public.acorn_user_user_groups TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_groups TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_groups TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_user_groups TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_user_groups TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_user_groups TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE acorn_user_users; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.acorn_user_users FROM justice;
GRANT ALL ON TABLE public.acorn_user_users TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_users TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_users TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.acorn_user_users TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.acorn_user_users TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.acorn_user_users TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE backend_access_log; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.backend_access_log FROM justice;
GRANT ALL ON TABLE public.backend_access_log TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_access_log TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_access_log TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.backend_access_log TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.backend_access_log TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_access_log TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_access_log_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.backend_access_log_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.backend_access_log_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_access_log_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_access_log_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.backend_access_log_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.backend_access_log_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_access_log_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE backend_user_groups; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.backend_user_groups FROM justice;
GRANT ALL ON TABLE public.backend_user_groups TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_groups TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_groups TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.backend_user_groups TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.backend_user_groups TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_groups TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_user_groups_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.backend_user_groups_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.backend_user_groups_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_groups_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_groups_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.backend_user_groups_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.backend_user_groups_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_groups_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE backend_user_preferences; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.backend_user_preferences FROM justice;
GRANT ALL ON TABLE public.backend_user_preferences TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_preferences TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_preferences TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.backend_user_preferences TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.backend_user_preferences TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_preferences TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_user_preferences_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.backend_user_preferences_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.backend_user_preferences_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_preferences_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_preferences_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.backend_user_preferences_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.backend_user_preferences_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_preferences_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE backend_user_roles; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.backend_user_roles FROM justice;
GRANT ALL ON TABLE public.backend_user_roles TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_roles TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_roles TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.backend_user_roles TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.backend_user_roles TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_roles TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_user_roles_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.backend_user_roles_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.backend_user_roles_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_roles_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_roles_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.backend_user_roles_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.backend_user_roles_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_roles_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE backend_user_throttle; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.backend_user_throttle FROM justice;
GRANT ALL ON TABLE public.backend_user_throttle TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_throttle TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_throttle TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.backend_user_throttle TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.backend_user_throttle TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_user_throttle TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_user_throttle_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.backend_user_throttle_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.backend_user_throttle_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_throttle_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_throttle_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.backend_user_throttle_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.backend_user_throttle_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_user_throttle_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE backend_users; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.backend_users FROM justice;
GRANT ALL ON TABLE public.backend_users TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_users TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_users TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.backend_users TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.backend_users TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_users TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE backend_users_groups; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.backend_users_groups FROM justice;
GRANT ALL ON TABLE public.backend_users_groups TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_users_groups TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_users_groups TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.backend_users_groups TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.backend_users_groups TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.backend_users_groups TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE backend_users_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.backend_users_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.backend_users_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_users_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_users_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.backend_users_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.backend_users_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.backend_users_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE cache; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.cache FROM justice;
GRANT ALL ON TABLE public.cache TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.cache TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.cache TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.cache TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.cache TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.cache TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE cms_theme_data; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.cms_theme_data FROM justice;
GRANT ALL ON TABLE public.cms_theme_data TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_data TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_data TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.cms_theme_data TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.cms_theme_data TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_data TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE cms_theme_data_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.cms_theme_data_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.cms_theme_data_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_data_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_data_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.cms_theme_data_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.cms_theme_data_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_data_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE cms_theme_logs; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.cms_theme_logs FROM justice;
GRANT ALL ON TABLE public.cms_theme_logs TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_logs TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_logs TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.cms_theme_logs TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.cms_theme_logs TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_logs TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE cms_theme_logs_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.cms_theme_logs_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.cms_theme_logs_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_logs_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_logs_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.cms_theme_logs_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.cms_theme_logs_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_logs_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE cms_theme_templates; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.cms_theme_templates FROM justice;
GRANT ALL ON TABLE public.cms_theme_templates TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_templates TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_templates TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.cms_theme_templates TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.cms_theme_templates TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.cms_theme_templates TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE cms_theme_templates_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.cms_theme_templates_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.cms_theme_templates_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_templates_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_templates_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.cms_theme_templates_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.cms_theme_templates_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.cms_theme_templates_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE deferred_bindings; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.deferred_bindings FROM justice;
GRANT ALL ON TABLE public.deferred_bindings TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.deferred_bindings TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.deferred_bindings TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.deferred_bindings TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.deferred_bindings TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.deferred_bindings TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE deferred_bindings_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.deferred_bindings_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.deferred_bindings_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.deferred_bindings_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.deferred_bindings_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.deferred_bindings_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.deferred_bindings_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.deferred_bindings_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE failed_jobs; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.failed_jobs FROM justice;
GRANT ALL ON TABLE public.failed_jobs TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.failed_jobs TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.failed_jobs TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.failed_jobs TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.failed_jobs TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.failed_jobs TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE failed_jobs_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.failed_jobs_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.failed_jobs_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.failed_jobs_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.failed_jobs_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.failed_jobs_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.failed_jobs_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.failed_jobs_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE job_batches; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.job_batches FROM justice;
GRANT ALL ON TABLE public.job_batches TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.job_batches TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.job_batches TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.job_batches TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.job_batches TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.job_batches TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE jobs; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.jobs FROM justice;
GRANT ALL ON TABLE public.jobs TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.jobs TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.jobs TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.jobs TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.jobs TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.jobs TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE jobs_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.jobs_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.jobs_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.jobs_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.jobs_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.jobs_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.jobs_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.jobs_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE migrations; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.migrations FROM justice;
GRANT ALL ON TABLE public.migrations TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.migrations TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.migrations TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.migrations TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.migrations TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.migrations TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE migrations_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.migrations_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.migrations_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.migrations_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.migrations_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.migrations_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.migrations_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.migrations_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE winter_location_countries; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.winter_location_countries FROM justice;
GRANT ALL ON TABLE public.winter_location_countries TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_location_countries TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_location_countries TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.winter_location_countries TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.winter_location_countries TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_location_countries TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_location_countries_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.rainlab_location_countries_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.rainlab_location_countries_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_location_countries_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_location_countries_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.rainlab_location_countries_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.rainlab_location_countries_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_location_countries_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE winter_location_states; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.winter_location_states FROM justice;
GRANT ALL ON TABLE public.winter_location_states TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_location_states TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_location_states TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.winter_location_states TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.winter_location_states TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_location_states TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_location_states_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.rainlab_location_states_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.rainlab_location_states_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_location_states_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_location_states_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.rainlab_location_states_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.rainlab_location_states_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_location_states_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE winter_translate_attributes; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.winter_translate_attributes FROM justice;
GRANT ALL ON TABLE public.winter_translate_attributes TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_attributes TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_attributes TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.winter_translate_attributes TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.winter_translate_attributes TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_attributes TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_translate_attributes_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.rainlab_translate_attributes_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.rainlab_translate_attributes_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_attributes_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_attributes_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.rainlab_translate_attributes_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.rainlab_translate_attributes_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_attributes_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE winter_translate_indexes; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.winter_translate_indexes FROM justice;
GRANT ALL ON TABLE public.winter_translate_indexes TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_indexes TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_indexes TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.winter_translate_indexes TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.winter_translate_indexes TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_indexes TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_translate_indexes_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.rainlab_translate_indexes_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.rainlab_translate_indexes_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_indexes_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_indexes_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.rainlab_translate_indexes_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.rainlab_translate_indexes_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_indexes_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE winter_translate_locales; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.winter_translate_locales FROM justice;
GRANT ALL ON TABLE public.winter_translate_locales TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_locales TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_locales TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.winter_translate_locales TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.winter_translate_locales TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_locales TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_translate_locales_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.rainlab_translate_locales_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.rainlab_translate_locales_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_locales_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_locales_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.rainlab_translate_locales_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.rainlab_translate_locales_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_locales_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE winter_translate_messages; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.winter_translate_messages FROM justice;
GRANT ALL ON TABLE public.winter_translate_messages TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_messages TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_messages TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.winter_translate_messages TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.winter_translate_messages TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.winter_translate_messages TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE rainlab_translate_messages_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.rainlab_translate_messages_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.rainlab_translate_messages_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_messages_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_messages_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.rainlab_translate_messages_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.rainlab_translate_messages_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.rainlab_translate_messages_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE sessions; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.sessions FROM justice;
GRANT ALL ON TABLE public.sessions TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.sessions TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.sessions TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.sessions TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.sessions TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.sessions TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE system_event_logs; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.system_event_logs FROM justice;
GRANT ALL ON TABLE public.system_event_logs TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_event_logs TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_event_logs TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.system_event_logs TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.system_event_logs TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_event_logs TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE system_event_logs_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.system_event_logs_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.system_event_logs_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_event_logs_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_event_logs_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.system_event_logs_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.system_event_logs_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_event_logs_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE system_files; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.system_files FROM justice;
GRANT ALL ON TABLE public.system_files TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_files TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_files TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.system_files TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.system_files TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_files TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE system_files_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.system_files_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.system_files_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_files_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_files_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.system_files_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.system_files_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_files_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE system_mail_layouts; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.system_mail_layouts FROM justice;
GRANT ALL ON TABLE public.system_mail_layouts TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_layouts TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_layouts TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.system_mail_layouts TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.system_mail_layouts TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_layouts TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE system_mail_layouts_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.system_mail_layouts_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.system_mail_layouts_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_layouts_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_layouts_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.system_mail_layouts_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.system_mail_layouts_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_layouts_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE system_mail_partials; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.system_mail_partials FROM justice;
GRANT ALL ON TABLE public.system_mail_partials TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_partials TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_partials TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.system_mail_partials TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.system_mail_partials TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_partials TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE system_mail_partials_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.system_mail_partials_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.system_mail_partials_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_partials_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_partials_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.system_mail_partials_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.system_mail_partials_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_partials_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE system_mail_templates; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.system_mail_templates FROM justice;
GRANT ALL ON TABLE public.system_mail_templates TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_templates TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_templates TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.system_mail_templates TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.system_mail_templates TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_mail_templates TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE system_mail_templates_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.system_mail_templates_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.system_mail_templates_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_templates_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_templates_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.system_mail_templates_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.system_mail_templates_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_mail_templates_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE system_parameters; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.system_parameters FROM justice;
GRANT ALL ON TABLE public.system_parameters TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_parameters TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_parameters TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.system_parameters TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.system_parameters TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_parameters TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE system_parameters_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.system_parameters_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.system_parameters_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_parameters_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_parameters_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.system_parameters_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.system_parameters_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_parameters_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE system_plugin_history; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.system_plugin_history FROM justice;
GRANT ALL ON TABLE public.system_plugin_history TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_plugin_history TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_plugin_history TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.system_plugin_history TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.system_plugin_history TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_plugin_history TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE system_plugin_history_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.system_plugin_history_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.system_plugin_history_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_plugin_history_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_plugin_history_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.system_plugin_history_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.system_plugin_history_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_plugin_history_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE system_plugin_versions; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.system_plugin_versions FROM justice;
GRANT ALL ON TABLE public.system_plugin_versions TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_plugin_versions TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_plugin_versions TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.system_plugin_versions TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.system_plugin_versions TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_plugin_versions TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE system_plugin_versions_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.system_plugin_versions_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.system_plugin_versions_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_plugin_versions_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_plugin_versions_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.system_plugin_versions_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.system_plugin_versions_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_plugin_versions_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE system_request_logs; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.system_request_logs FROM justice;
GRANT ALL ON TABLE public.system_request_logs TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_request_logs TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_request_logs TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.system_request_logs TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.system_request_logs TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_request_logs TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE system_request_logs_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.system_request_logs_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.system_request_logs_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_request_logs_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_request_logs_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.system_request_logs_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.system_request_logs_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_request_logs_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE system_revisions; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.system_revisions FROM justice;
GRANT ALL ON TABLE public.system_revisions TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_revisions TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_revisions TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.system_revisions TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.system_revisions TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_revisions TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE system_revisions_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.system_revisions_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.system_revisions_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_revisions_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_revisions_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.system_revisions_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.system_revisions_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_revisions_id_seq TO token_8_no WITH GRANT OPTION;


--
-- Name: TABLE system_settings; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON TABLE public.system_settings FROM justice;
GRANT ALL ON TABLE public.system_settings TO justice WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_settings TO token_1 WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_settings TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON TABLE public.system_settings TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON TABLE public.system_settings TO test WITH GRANT OPTION;
GRANT ALL ON TABLE public.system_settings TO token_8_no WITH GRANT OPTION;


--
-- Name: SEQUENCE system_settings_id_seq; Type: ACL; Schema: public; Owner: justice
--

REVOKE ALL ON SEQUENCE public.system_settings_id_seq FROM justice;
GRANT ALL ON SEQUENCE public.system_settings_id_seq TO justice WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_settings_id_seq TO token_1 WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_settings_id_seq TO demo WITH GRANT OPTION;
SET SESSION AUTHORIZATION demo;
GRANT ALL ON SEQUENCE public.system_settings_id_seq TO token_2;
RESET SESSION AUTHORIZATION;
GRANT ALL ON SEQUENCE public.system_settings_id_seq TO test WITH GRANT OPTION;
GRANT ALL ON SEQUENCE public.system_settings_id_seq TO token_8_no WITH GRANT OPTION;


--
-- PostgreSQL database dump complete
--

\unrestrict hZqdKKVyspUjT1D6XBhh1nOTpUth2g2Q8eUw8NuBe3rJbIU2F2ogS1OhbF6vcas

