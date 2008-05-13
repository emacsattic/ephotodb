CREATE TABLE t_film (
       film_id INTEGER PRIMARY KEY,
       film_name TEXT,
       film_zonemode INTEGER,
       film_speed INTEGER,
       film_type TEXT,
       film_size TEXT,
       film_devdate DATE,
       film_developer TEXT,
       film_devtime FLOAT,
       film_devtemp INTEGER,
       film_devdilution TEXT,
       film_devmode TEXT,
       film_scan TEXT);

CREATE UNIQUE INDEX t_film_film_name ON t_film(film_name);

CREATE TABLE t_negative (
       neg_id INTEGER PRIMARY KEY,
       neg_name TEXT UNIQUE,
       neg_film_id INTEGER REFERENCES t_film (film_id),
       neg_date DATE,
       neg_aperture TEXT,
       neg_speed TEXT,
       neg_filter TEXT,
       neg_lens TEXT,
       neg_location TEXT,
       neg_description TEXT,
       neg_scan TEXT);

CREATE UNIQUE INDEX t_negative_neg_name ON t_negative(neg_name);

CREATE TABLE t_print (
       print_id INTEGER PRIMARY KEY,
       print_name TEXT UNIQUE,
       print_neg_id INTEGER REFERENCES t_negative (neg_id),
       print_papertype TEXT,
       print_developer TEXT,
       print_devdate DATE,
       print_devtime FLOAT,
       print_devtemp INTEGER,
       print_devdilution TEXT,
       print_grade TEXT,
       print_size TEXT,
       print_exposure TEXT,
       print_developing TEXT,
       print_scan TEXT);

CREATE UNIQUE INDEX t_print_print_name ON t_print(print_name);

