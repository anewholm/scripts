CREATE EXTENSION postgres_fdw;
CREATE SERVER localserver_universityacceptance FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'localhost', dbname 'universityacceptance', port '5432');
CREATE USER MAPPING FOR sz SERVER localserver_universityacceptance OPTIONS ("user" 'sz', password '---');
IMPORT FOREIGN SCHEMA public LIMIT TO (university_mofadala_departments) FROM SERVER localserver_universityacceptance INTO public;
