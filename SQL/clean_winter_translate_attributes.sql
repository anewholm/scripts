select model_type, model_id, t.table_name,
	'delete from winter_translate_attributes where model_type = ''' || model_type || ''' and model_id = ''' || model_id 
	|| ''' and not exists(select id from ' || t.table_name || ' where id=''' || model_id || '''::uuid);' as sql
from (
	select model_type, model_id,
	lower(replace(regexp_replace(replace(replace(regexp_replace(regexp_replace(
		model_type, 
		's$', 'se'), -- status
		'y$', 'ie'), -- hierachy
		'Acorn', 'acorn'), 
		'\Models', ''), 
		'([A-Z])','_\1', 'g'), 
		'\', ''))
		|| 's' 
		as table_name 
	from winter_translate_attributes
) wta
left outer join information_schema.tables t
on  t.table_catalog = current_database()
and t.table_schema = 'public'
and t.table_type = 'BASE TABLE'
and t.table_name = wta.table_name
