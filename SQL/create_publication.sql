-- select concat(schemaname, '.', tablename) from pg_tables where tablename like('acornassociated_lojistiks_%') order by schemaname

-- DROP PUBLICATION pub_acornassociated_lojistiks_tables 

CREATE PUBLICATION pub_acornassociated_lojistiks_tables
    FOR TABLE 
		product.acornassociated_lojistiks_computer_products,
		product.acornassociated_lojistiks_electronic_products,
		
		public.acornassociated_lojistiks_addresses,
		public.acornassociated_lojistiks_area_types,
		public.acornassociated_lojistiks_areas,
		public.acornassociated_lojistiks_brands,
		public.acornassociated_lojistiks_containers,
		public.acornassociated_lojistiks_drivers,
		public.acornassociated_lojistiks_employees,
		public.acornassociated_lojistiks_gps,
		public.acornassociated_lojistiks_locations,
		public.acornassociated_lojistiks_measurement_units,
		public.acornassociated_lojistiks_offices,
		public.acornassociated_lojistiks_people,
		public.acornassociated_lojistiks_product_attributes,
		public.acornassociated_lojistiks_product_categories,
		public.acornassociated_lojistiks_product_category_types,
		public.acornassociated_lojistiks_product_instances,
		public.acornassociated_lojistiks_product_products,
		public.acornassociated_lojistiks_products_product_categories,
		public.acornassociated_lojistiks_products,
		public.acornassociated_lojistiks_suppliers,
		public.acornassociated_lojistiks_transfer_container_product_instances,
		public.acornassociated_lojistiks_transfer_container,
		public.acornassociated_lojistiks_product_instance_transfer,
		public.acornassociated_lojistiks_transfers,
		public.acornassociated_lojistiks_vehicle_types,
		public.acornassociated_lojistiks_vehicles,
		public.acornassociated_lojistiks_warehouses,
		public.acornassociated_lojistiks_servers
	WITH (publish = 'insert, update, delete, truncate', publish_via_partition_root = false);