DROP TABLE IF EXISTS t_film;

CREATE TABLE t_film (
       film_id INTEGER auto_increment,
       film_name VARCHAR(255) UNIQUE,
       film_zonemode INTEGER,
       film_speed INTEGER,
       film_type VARCHAR(255),
       film_size VARCHAR(255),
       film_devdate DATE,
       film_developer VARCHAR(255),
       film_devtime FLOAT,
       film_devtemp INTEGER,
       film_devdilution VARCHAR(255),
       film_devmode TEXT,
       film_scan TEXT,
       PRIMARY KEY (film_id));

DROP TABLE IF EXISTS t_negative;

CREATE TABLE t_negative (
       neg_id INTEGER auto_increment,
       neg_name VARCHAR(255) UNIQUE,
       neg_film_id INTEGER REFERENCES t_film (film_id),
       neg_date DATE,
       neg_aperture VARCHAR(255),
       neg_speed VARCHAR(255),
       neg_filter VARCHAR(255),
       neg_lens VARCHAR(255),
       neg_location TEXT,
       neg_description TEXT,
       neg_scan TEXT,
       PRIMARY KEY (neg_id));

DROP TABLE IF EXISTS t_print;

CREATE TABLE t_print (
       print_id INTEGER auto_increment,
       print_name VARCHAR(255) UNIQUE,
       print_neg_id INTEGER REFERENCES t_negative (neg_id),
       print_papertype VARCHAR(255),
       print_developer VARCHAR(255),
       print_devdate DATE,
       print_devtime FLOAT,
       print_devtemp INTEGER,
       print_devdilution VARCHAR(255),
       print_grade VARCHAR(255),
       print_size VARCHAR(255),
       print_exposure TEXT,
       print_developing TEXT,
       print_scan TEXT,
       PRIMARY KEY (print_id));

