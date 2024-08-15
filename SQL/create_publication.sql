-- select concat(schemaname, '.', tablename) from pg_tables where tablename like('acorn_lojistiks_%') order by schemaname

-- DROP PUBLICATION pub_acorn_lojistiks_tables 

CREATE PUBLICATION pub_acorn_lojistiks_tables
    FOR TABLE 
		product.acorn_lojistiks_computer_products,
		product.acorn_lojistiks_electronic_products,
		
		public.acorn_lojistiks_addresses,
		public.acorn_lojistiks_area_types,
		public.acorn_lojistiks_areas,
		public.acorn_lojistiks_brands,
		public.acorn_lojistiks_containers,
		public.acorn_lojistiks_drivers,
		public.acorn_lojistiks_employees,
		public.acorn_lojistiks_gps,
		public.acorn_lojistiks_locations,
		public.acorn_lojistiks_measurement_units,
		public.acorn_lojistiks_offices,
		public.acorn_lojistiks_people,
		public.acorn_lojistiks_product_attributes,
		public.acorn_lojistiks_product_categories,
		public.acorn_lojistiks_product_category_types,
		public.acorn_lojistiks_product_instances,
		public.acorn_lojistiks_product_products,
		public.acorn_lojistiks_products_product_categories,
		public.acorn_lojistiks_products,
		public.acorn_lojistiks_suppliers,
		public.acorn_lojistiks_transfer_container_product_instances,
		public.acorn_lojistiks_transfer_container,
		public.acorn_lojistiks_product_instance_transfer,
		public.acorn_lojistiks_transfers,
		public.acorn_lojistiks_vehicle_types,
		public.acorn_lojistiks_vehicles,
		public.acorn_lojistiks_warehouses,
		public.acorn_lojistiks_servers
	WITH (publish = 'insert, update, delete, truncate', publish_via_partition_root = false);