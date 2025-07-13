SELECT wta.id, wta.model_id, ugs.name, ugs.code, wta.model_type, wta.locale, wta.attribute_data
FROM public.acorn_user_user_groups ugs
inner join acorn_university_entities en on en.user_group_id = ugs.id
inner join acorn_university_courses cs on cs.entity_id = en.id
inner join public.winter_translate_attributes wta 
	on (wta.model_type = 'Acorn\User\Models\UserGroup' and ugs.id = wta.model_id::uuid)
	or (wta.model_type = 'Acorn\University\Models\Course' and cs.id = wta.model_id::uuid)
where ugs.name like('%Ye%') or ugs.name like('%Sal%')
order by ugs.name, wta.locale

-- 10 الصف
-- Year 10
-- Salê 10

-- delete from winter_translate_attributes where model_id = '680546dc-5190-11f0-bc00-2b9974d04458'