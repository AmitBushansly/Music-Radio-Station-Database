#group u, participant ids: 537321, 537267
#DDL
create database MusicRadioStation; 
use MusicRadioStation;


CREATE TABLE `artists` 
(
	artist_id INT PRIMARY KEY AUTO_INCREMENT, 
	artist_name VARCHAR(50) not null unique,
    country VARCHAR(50),
    is_band bool,
    favorit_artist int,
	KEY idx_fk_favorit_artist (favorit_artist),
    CONSTRAINT fk_favorit_artist 
    FOREIGN KEY (favorit_artist)
    REFERENCES artists (artist_id)
);

CREATE TABLE `genres` 
(
	genre_id INT PRIMARY KEY AUTO_INCREMENT,
    genre_name VARCHAR(50) not null 
);


CREATE TABLE `albums` 
(
	album_id INT PRIMARY KEY AUTO_INCREMENT,
    album_name VARCHAR(50) not null,
    release_date date CHECK (release_date < '2023-08-10' and release_date > '1950-01-01'),
    artist_id int,
    KEY idx_fk_artist_albums(artist_id),
    CONSTRAINT fk_artist_albums 
    FOREIGN KEY (artist_id)
    REFERENCES artists (artist_id),
	total_duration time CHECK (total_duration < '02:00:00' and total_duration > '00:10:00'),
    num_of_songs int check (num_of_songs <= 20 and num_of_songs > 1)
);

CREATE TABLE `songs` 
(
	song_id INT PRIMARY KEY AUTO_INCREMENT, 
	song_name VARCHAR(50) not null ,
    duration time CHECK (duration < '00:10:00' and duration > '00:01:00'),
    album_id int,
	KEY idx_fk_song_albums(album_id),
    CONSTRAINT fk_song_albums 
    FOREIGN KEY (album_id)
    REFERENCES albums (album_id),
    release_date date CHECK (release_date < '2023-08-10' and release_date > '1950-01-01'),
    lyrics VARCHAR(200),
    languag VARCHAR(50)
);

CREATE TABLE `employees` 
(
    employee_id INT PRIMARY KEY AUTO_INCREMENT ,
    first_name VARCHAR(50) not null,
    last_name VARCHAR(50),
	job_title VARCHAR(50) default null,
    birth_date date default null,
    marital_status varchar(1) check (marital_status = 'S' or marital_status = 'M') default null,
    gender varchar(1) check (gender = 'F' or gender = 'M') default null,
    HireDate date default null,
    monthly_salary decimal (10,2) check (monthly_salary > 0) default null
);

CREATE TABLE `artist_song` 
(
  song_id INT not null,
  artist_id INT not null,
  PRIMARY KEY (`song_id`,`artist_id`),
  KEY `idx_fk_song_song` (`song_id`),
  CONSTRAINT fk_song_song
  FOREIGN KEY (song_id)
  REFERENCES songs (song_id),
  KEY `idx_fk_artist_artist` (`artist_id`),
  CONSTRAINT fk_artist_artist
  FOREIGN KEY (artist_id)
  REFERENCES artists (artist_id)  
);


CREATE TABLE `genre_song` 
(
    song_id INT not null,
	genre_id INT not null,
    PRIMARY KEY (`song_id`,`genre_id`),
	KEY idx_fk_genre_genre(genre_id),
    CONSTRAINT fk_genre_genre 
    FOREIGN KEY (genre_id)
    REFERENCES genres (genre_id),
    KEY idx_fk_song_genre(song_id),
    CONSTRAINT fk_song_genre 
    FOREIGN KEY (song_id)
    REFERENCES songs (song_id)
);

CREATE TABLE `presenters` 
(
    presenter_id INT not null PRIMARY KEY unique,
    KEY idx_fk_presenter_employee(presenter_id),
    CONSTRAINT fk_presenter_employee 
    FOREIGN KEY (presenter_id)
    REFERENCES employees(employee_id),
	`description` VARCHAR(200)
);


CREATE TABLE `shows` 
(
	show_id INT PRIMARY KEY AUTO_INCREMENT,
    show_name VARCHAR(50) not null,
    start_hour time check (start_hour > '00:00:00' and start_hour < '23:59:59'),
    end_hour time check (end_hour > '00:00:00' and end_hour < '23:59:59')
);

create table `show_presenter`
(
   show_presenter_id INT PRIMARY KEY AUTO_INCREMENT,
   show_id int not null,
   KEY idx_fk_show_presenter(show_id),
    CONSTRAINT fk_show_presenter 
    FOREIGN KEY (show_id)
    REFERENCES shows (show_id),
    presenter_id INT not null,
    KEY idx_fk_presenter_show(presenter_id),
    CONSTRAINT fk_presenter_show 
    FOREIGN KEY (presenter_id)
    REFERENCES presenters(presenter_id),
    week_day int check ( week_day > 0 and week_day < 8)
);

CREATE TABLE `DailySongs` 
(
	daily_song_id INT PRIMARY KEY AUTO_INCREMENT,
    song_id int,
	KEY idx_fk_song_daily(song_id),
    CONSTRAINT fk_song_daily 
    FOREIGN KEY (song_id)
    REFERENCES songs (song_id),
    start_time timestamp,
    end_time timestamp,
    show_id int, 
    KEY idx_fk_daily_shows(show_id),
    CONSTRAINT fk_daily_shows 
    FOREIGN KEY (show_id)
    REFERENCES shows (show_id),
    num_of_listeners int check (num_of_listeners > 0 )
);

#Triggers
-- Before

DELIMITER //
CREATE TRIGGER dailysongs_before_insert_wrong_time
    BEFORE INSERT ON dailysongs
    FOR EACH ROW
BEGIN
    IF NEW.start_time >= NEW.end_time
    THEN
       SIGNAL SQLSTATE '45000' 
       SET MESSAGE_TEXT = "End time of the song must be later than start time"; 
    END IF;
END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER artist_before_insert_uppercase_names
    BEFORE INSERT ON artists
    FOR EACH ROW
BEGIN
    SET NEW.artist_name = UPPER(NEW.artist_name);
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER employees_before_insert_wrong_dates
    BEFORE INSERT ON employees
    FOR EACH ROW
BEGIN
    IF NEW.birth_date >= NEW.HireDate
    THEN
       SIGNAL SQLSTATE '45000' 
       SET MESSAGE_TEXT = "Birth date must be lower than hire date"; 
    END IF;
END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER shows_before_insert_wrong_hours
    BEFORE INSERT ON shows
    FOR EACH ROW
BEGIN
    IF NEW.start_hour >= NEW.end_hour
    THEN
       SIGNAL SQLSTATE '45000' 
       SET MESSAGE_TEXT = "Start hour of the show must be lower than end hour"; 
    END IF;
END//
DELIMITER ;

#After
CREATE TABLE dailysongs_audit (
    `dailysongs_audit_id` INT AUTO_INCREMENT PRIMARY KEY,
    `daily_song_id` INT NOT NULL, 
    `who` VARCHAR(255), 
    `when` TIMESTAMP NOT NULL);
    
DELIMITER //
CREATE TRIGGER dailysongs_after_insert_audit
    AFTER INSERT ON dailysongs
    FOR EACH ROW
BEGIN
    INSERT INTO dailysongs_audit
        (daily_song_id, `who`, `when`)
    VALUES
        (NEW.daily_song_id, CURRENT_USER(), CURRENT_TIMESTAMP);
END//
DELIMITER ;

-- We suspect that someone is trying to change the songs playlist
CREATE TABLE songs_audit (
    `songs_audit_id` INT AUTO_INCREMENT PRIMARY KEY,
    `song_id` INT NOT NULL, 
    `who` VARCHAR(255), 
    `when` TIMESTAMP NOT NULL);
    
DELIMITER //
CREATE TRIGGER songs_after_insert_audit
    AFTER INSERT ON songs
    FOR EACH ROW
BEGIN
    INSERT INTO songs_audit
        (song_id, `who`, `when`)
    VALUES
        (NEW.song_id, CURRENT_USER(), CURRENT_TIMESTAMP);
END//
DELIMITER ;

-- We suspect that someone is trying to change the salaries of the employees
CREATE TABLE employees_audit (
    `employees_audit_id` INT AUTO_INCREMENT PRIMARY KEY,
    `employee_id` INT NOT NULL, 
    `who` VARCHAR(255), 
    `when` TIMESTAMP NOT NULL);
 
DELIMITER //
CREATE TRIGGER employees_after_insert_audit
    AFTER INSERT ON employees
    FOR EACH ROW
BEGIN
    INSERT INTO employees_audit
        (employee_id, `who`, `when`)
    VALUES
        (NEW.employee_id, CURRENT_USER(), CURRENT_TIMESTAMP);
END//
DELIMITER ;


CREATE TABLE shows_audit (
    `shows_audit_id` INT AUTO_INCREMENT PRIMARY KEY,
    `show_id` INT NOT NULL, 
    `who` VARCHAR(255), 
    `when` TIMESTAMP NOT NULL);
    
DELIMITER //
CREATE TRIGGER shows_after_insert_audit
    AFTER INSERT ON shows
    FOR EACH ROW
BEGIN
    INSERT INTO shows_audit
        (show_id, `who`, `when`)
    VALUES
        (NEW.show_id, CURRENT_USER(), CURRENT_TIMESTAMP);
END//
DELIMITER ;

#DML
INSERT INTO `musicradiostation`.`artists`
(`artist_name`,
`country`,
`is_band`)
VALUES
('full trunk','ISRAEL', 1),
('ravid plotnik','ISRAEL', 0),
('tuna','ISRAEL', 0),
('coldplay','USA', 1),
('bruno mars','USA', 0),
('red band','ISRAEL', 1),
('enrique iglesias','SPAIN', 0),
('loreen','SWEDEN', 0);

update `artists`
set
    favorit_artist = 4
where
    artist_id = 1;
    
update `artists`
set
    favorit_artist = 3
where
    artist_id = 2;
update `artists`
set
    favorit_artist = 2
where
    artist_id = 3;
update `artists`
set
    favorit_artist = 5
where
    artist_id = 4;
update `artists`
set
    favorit_artist = 4
where
    artist_id = 5;
update `artists`
set
    favorit_artist = 4
where
    artist_id = 6;

INSERT INTO `musicradiostation`.`albums`
(`album_name`,
`release_date`,
`artist_id`,
`total_duration`,
`num_of_songs`)
VALUES
('MAMUTA','2022-02-11',1,'00:33:53',11),
('WELCOME TO PETAH TIKWA','2015-07-01',2,'00:43:09',12),
('TUNAPARK','2017-09-07',3,'00:56:35',12),
('VIVA LA VIDA','2008-05-26',4,'00:45:55',10),
('24K MAGIC','2016-11-17',5,'00:33:32',9);

INSERT INTO `musicradiostation`.`songs`
(`song_name`,
`duration`,
`album_id`,
`release_date`,
`lyrics`,
`languag`)
VALUES
('POWERFUL', '00:03:35', NULL,'2018-10-08',NULL, 'ENGLISH'),
('I AM HERE TO BREAK', '00:03:44', NULL,'2016-05-23',NULL, 'HEBREW'),
('THATS WHAT I LIKE', '00:03:26', 5 ,'2016-11-17',NULL, 'ENGLISH'),
('VIVA LA VIDA', '00:05:20', 4 ,'2008-05-26',NULL, 'ENGLISH'),
('DAMN RIGHT', '00:03:00', 1,'2022-02-11',NULL, 'ENGLISH'),
('BAILANDO', '00:04:03', NULL ,'2014-07-04',NULL, 'SPANISH'),
('TATTOO', '00:03:03', NULL ,'2023-02-23',NULL, 'ENGLISH');


INSERT INTO `musicradiostation`.`artist_song`
(`song_id`,
`artist_id`)
VALUES
(1,1),(1,6),(2,2),(2,3),(3,5),(4,4),(5,1), (6,7),(7, 8);

INSERT INTO `musicradiostation`.`genres`
(`genre_name`)
VALUES
('HARD ROCK'),('SOFT ROCK'),('POP'),('HIP-HOP'),('BLUES'),('MIDDLE EAST'),('RAP'), ('PHANK');

INSERT INTO `musicradiostation`.`genre_song`
(`song_id`,
`genre_id`)
VALUES
(1,1),(1,5),(2,4),(2,7),(3,8),(4,2),(5,1),(5,5),(5,6), (6,3), (7,3);

INSERT INTO `musicradiostation`.`employees`
(`first_name`,
 `last_name`,
`job_title`,
`birth_date`,
`marital_status`,
`gender`,
`HireDate`,
`monthly_salary`)
VALUES
('HADAR', 'MARKS', 'PRESENTER', '1985-06-13', 'M', 'F', '2003-06-13', 30500.23),
('OMER', 'GEFFEN', 'PRESENTER', '1988-07-21', 'M', 'M', '2006-07-27', 20500.23),
('SHIR', 'HADAS-MEIR', 'PRESENTER', '1997-08-19', 'S', 'F', '2015-06-13', 15500.57),
('DALIT', 'RECHESTER', 'PRESENTER', '1988-08-01', 'M', 'F', '2009-06-13', 25500.73),
('AHINOAM', 'BER', 'PRESENTER', '1997-12-26', 'S', 'F', '2016-04-18', 13500.23),
('BENI', 'KVODI', 'TRAFFIC REPORTING', '1985-03-13', 'M', 'M', '2003-06-13', 14500.23),
('NOY', 'BEN-HAIM', 'PRODUCER', '1990-12-26', 'S', 'F', '2016-04-18', 27500.23);

INSERT INTO `musicradiostation`.`presenters`
(`presenter_id`,
`description`)
VALUES
(1,
'The girl with the most beautiful voice in the country
 who speaks to you regularly even during the commercial break.'),
(2,
'The cool geek who loves Star Wars and majored in physics in high school,
 but has been playing bass guitar since he was 13.'),
(3,
'Already at the Arts High School in Ashkelon,
 Shir learned that if you want to get everything done,
 you have to give up something, like sleep for example.'),
(4,
'The red-haired girl from Holon is today the pop princess of Galgaletz,
 who dances every night in the most desirable clubs and events in Israel and abroad.'),
(5,
'"Give me 3 portions and another half portion without pickles" -
 this was the sentence that brought Ahinoam to the radio.');

INSERT INTO `musicradiostation`.`shows`
(`show_name`,
`start_hour`,
`end_hour`)
VALUES
('COUNTRY ON THE WAY','07:00:00','10:00:00'),
('VOICES OF THE SOLDIERS','10:00:00','12:00:00'),
('AFTERNOON','12:00:00','14:00:00'),
('DECADES','14:00:00','15:00:00'),
('EVENING','17:00:00','19:00:00');

INSERT INTO `musicradiostation`.`show_presenter`
(`show_id`, `presenter_id`,`week_day`)
VALUES
(1,1,1), (1,1,2), (1,1,3), (1,1,4), (1,2,5),
 (2,5,1), (2,5,2), (2,5,3), (2,5,4), (2,5,5),
(3,4,1), (3,4,2), (3,5,3), (3,4,4), (3,4,5),
(4,3,1), (4,3,2), (4,3,3), (4,3,4), (4,3,5),
(5,3,1), (5,3,2), (5,3,3), (5,3,4), (5,3,5);

INSERT INTO `musicradiostation`.`dailysongs`
(`song_id`, `start_time`,`end_time`,`show_id`,`num_of_listeners`)
VALUES
(1, '2023-08-01 08:10:00' , '2023-08-01 08:13:35',1, 6000),
(2, '2023-08-01 08:14:00' , '2023-08-01 08:17:44',1, 5700),
(3, '2023-08-01 10:30:00' , '2023-08-01 10:33:26',2, 7428),
(4, '2023-08-01 13:20' , '2023-08-01 13:25:20',3, 4500),
(1, '2023-08-01 14:45:00' , '2023-08-01 14:48:35',4, 3400),
(3, '2023-08-01 17:20' , '2023-08-01 17:23:26',5, 8500),
(6, '2023-08-01 17:25' , '2023-08-01 17:29:03',5, 5500);

#Views
-- Updatable
CREATE VIEW employees_ordered_by_salary AS
     SELECT employee_id, first_name, last_name, monthly_salary
     FROM employees
     order by monthly_salary desc;
-- Use it:
SELECT * from employees_ordered_by_salary;

-- Non-Updatable
CREATE VIEW artists_for_each_song AS
select s.song_name,
       group_concat( a.artist_name SEPARATOR ', ') as 'artists'
from songs s
	join artist_song ars using(song_id)
    join artists a using(artist_id)
group by s.song_name;

-- Use it:
SELECT * from artists_for_each_song;

CREATE VIEW genres_for_each_song AS
select s.song_name,
       group_concat( g.genre_name SEPARATOR ', ') as 'genres'
from songs s
	left join genre_song gs using(song_id)
    left join genres g using(genre_id)
group by s.song_name;

-- Use it:
SELECT * from genres_for_each_song;

create view presenter_for_each_show_and_day as
select s.show_name,  sp.week_day, concat(e.first_name,' ',e.last_name) as 'presenter'
from shows s
	 join show_presenter sp using(show_id)
     join presenters p using(presenter_id)
     join employees e on p.presenter_id = e.employee_id
order by week_day;
 -- Use it:
SELECT * from presenter_for_each_show_and_day;

#Query
-- The number of artists played in the radio, and the duration of the longest song,
-- for each origin countery of the artists
select  IF(GROUPING(a.country ) = 1, "TOTAL", a.country) AS 'Country',
	    count(*) as 'Num Of Artists',
		max(s.duration) as 'Duration Of Longest Song'
from dailysongs ds
       join songs s using(song_id)
       join artist_song ars using(song_id)
       join artists a using(artist_id)
where ds.num_of_listeners > 3500
group by a.country with rollup
having count(*) >=1
order by  count(*);







