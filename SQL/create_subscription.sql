-- https://postgrespro.com/docs/postgresql/16/sql-altersubscription
select fn_acorn_lojistiks_truncate_database('product');
select fn_acorn_lojistiks_truncate_database('public');
select fn_acorn_lojistiks_reset_sequences('public');
select fn_acorn_lojistiks_reset_sequences('product');
-- TODO: programmatic sub/pub naming
-- select concat('sub_acorn_', current_database(), '_all_tables_', hostname());

--ALTER SUBSCRIPTION sub_acorn_lojistiks_all_tables REFRESH PUBLICATION WITH (COPY_DATA=false);
DROP SUBSCRIPTION IF EXISTS sub_acorn_lojistiks_all_tables;

CREATE SUBSCRIPTION sub_acorn_lojistiks_all_tables
  CONNECTION 'host=192.168.88.252 port=5433 dbname=acornlojistiks user=sz password=xxxxxx sslmode=disable'
  PUBLICATION pub_acorn_lojistiks_all_tables
  WITH (
		-- Custom
		-- By default, PG waits for the WAL log to fill (16MB) before updating subscribers
		-- Streaming ships each new WAL log entry (DB change) immediately
		streaming = 'True',
    	-- Replication slots provide an automated way to ensure that the primary does not remove WAL segments until they have been received by all standbys, and that the primary does not remove rows which could cause a recovery conflict even when the standby is disconnected.
		create_slot = true,
		slot_name = 'sub_acorn_lojistiks_all_tables_laptop',
		-- Binary requires exact column data type matching, whereas non-binary, for example, allows integer to be mapped to bigint
		binary = false,

    	-- The initial data in existing subscribed tables are snapshotted and copied in a parallel instance of a special kind of apply process. This process will create its own replication slot and copy the existing data. As soon as the copy is finished the table contents will become visible to other backends. Once existing data is copied, the worker enters synchronization mode, which ensures that the table is brought up to a synchronized state with the main apply process by streaming any changes that happened during the initial data copy using standard logical replication. During this synchronization phase, the changes are applied and committed in the same order as they happened on the publisher. Once synchronization is done, control of the replication of the table is given back to the main apply process where replication continues as normal.
		copy_data = true,

		-- Defaults
		connect = true,
		enabled = true,
		synchronous_commit = 'off',
		two_phase = false,
		disable_on_error = false,
		run_as_owner = false,
		password_required = true,
		origin = 'any'
	);

-- Reset sequences AFTER full COPY_DATA
select fn_acorn_lojistiks_reset_sequences('public');
select fn_acorn_lojistiks_reset_sequences('product');

select * from fn_acorn_lojistiks_table_counts('public') where "table" like('acorn%brands');
