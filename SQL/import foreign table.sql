CREATE EXTENSION postgres_fdw;
CREATE SERVER localserver_universityacceptance FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'localhost', dbname 'universityacceptance', port '5432');
CREATE USER MAPPING FOR sz SERVER localserver_universityacceptance OPTIONS ("user" 'sz', password '---');
IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_branches) FROM SERVER localserver_universityacceptance INTO public;
IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_departments) FROM SERVER localserver_universityacceptance INTO public;
IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_universities) FROM SERVER localserver_universityacceptance INTO public;
IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_university_categories) FROM SERVER localserver_universityacceptance INTO public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_location_areas) FROM SERVER live_university INTO live_public;

IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_exam_centers) FROM SERVER localserver_universityacceptance INTO public;
IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_student_desire_details) FROM SERVER localserver_universityacceptance INTO public;
IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_department_details) FROM SERVER localserver_universityacceptance INTO public;
IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_candidate_exams) FROM SERVER localserver_universityacceptance INTO public;
IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_candidate_exam_materials) FROM SERVER localserver_universityacceptance INTO public;
IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_candidate_exam_material_marks) FROM SERVER localserver_universityacceptance INTO public;
IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_type_certificates) FROM SERVER localserver_universityacceptance INTO public;

IMPORT FOREIGN SCHEMA public LIMIT TO (system_files) FROM SERVER localserver_universityacceptance INTO product;

-- Export to LIVE support
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_university_entities) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_user_user_groups) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (winter_translate_attributes) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_user_user_group_versions) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_university_courses) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_university_hierarchies) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_university_course_plans) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_university_course_specializations) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_university_material_topics) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_university_course_year_semesters) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_university_course_materials) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_university_materials) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_calendar_events) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_calendar_event_parts) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_university_lectures) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_calendar_calendars) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_calendar_event_statuses) FROM SERVER live_university INTO live_public;
IMPORT FOREIGN SCHEMA public LIMIT TO (acorn_calendar_event_types) FROM SERVER live_university INTO live_public;


