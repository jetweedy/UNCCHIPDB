
use chip490_instructor_jetweedy;
show tables;

/*
HEROES likes Superman, Wonder Woman, The Flash, etc...
PEOPLE/IDENTITIES like Clark Kent, Diana Prince, Barry Allen 
-- POWERS: flight, speed, strength...

POTENTIAL SIMPLE TABLE:
Superman        Clark Kent      Strength, Speed, Flight, Heat Vision, etc.
Superman        Clark Kent      Speed
Superman        Clark Kent      Flight
Wonder Woman    Diana Prince    Strength, Speed, (flight?), etc...
                Jimmy Olsen     ...?

SPLIT INTO SOME TABLES:
HEROES:
1 Superman
2 WW
3 Flash

PEOPLE:
1 Clark Kent
2 Jimmy Olsen
3 Barry Allen
4 Diana Prince

HERO_POWERS:
1 Strength
1 Speed
1 Flight

FORM:
Hero: ________________
Secret Identity: _____________
[Enter]

$hero
$secretid

*/




CREATE TABLE people (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, firstname VARCHAR(100), lastname VARCHAR(100));
INSERT INTO people (firstname, lastname) VALUES ('Barry', 'Allen'); -- 1
SET @barry_allen := last_insert_id();
INSERT INTO people (firstname, lastname) VALUES ('Diana', 'Prince'); -- 2
SET @diana_prince := last_insert_id();
INSERT INTO people (firstname, lastname) VALUES ('Jimmy', 'Olsen'); -- 3
SET @jimmy_olsen := last_insert_id();
SELECT @barry_allen, @diana_prince, @jimmy_olsen;


CREATE TABLE heroes (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY
    , name VARCHAR(100)
    , person_id INT
    , FOREIGN KEY (person_id) REFERENCES people(id)
    );
-- Let's insert our heroes.
-- Let's also use some variables to track the IDs that get entered so we don't have to remember specific numbers later in our script.
INSERT INTO heroes (name, person_id) VALUES ('Wonder Woman', @diana_prince);
SET @wonder_woman := last_insert_id();
INSERT INTO heroes (name, person_id) VALUES ('The Flash', @barry_allen);
SET @the_flash := last_insert_id();
-- And let's pretend we don't know the Martian Manhunter's identity in our database:
INSERT INTO heroes (name, person_id) VALUES ('Martian Manhunter', NULL);
SET @martian_manhunter := last_insert_id();
SELECT @wonder_woman, @the_flash, @martian_manhunter;


-- QUESTION: Can you tell me the names of heroes and their identities?
SELECT * FROM heroes;
SELECT * FROM people;

SELECT * 
    FROM people 
    JOIN heroes 
        ON heroes.person_id = people.id
    ;

SELECT heroes.name, people.firstname, people.lastname
    FROM people 
    JOIN heroes ON heroes.person_id = people.id
    ;


SELECT heroes.name as hero
    , CONCAT(people.firstname, ' ', people.lastname) as person 
    FROM people 
    JOIN heroes ON heroes.person_id = people.id
    ;
    



SELECT heroes.name as hero, CONCAT(people.firstname, ' ', people.lastname) as person 
    FROM heroes LEFT OUTER JOIN people ON heroes.person_id = people.id
    ;

SELECT heroes.name as hero, CONCAT(people.firstname, ' ', people.lastname) as person 
    FROM heroes RIGHT OUTER JOIN people ON heroes.person_id = people.id
    ;

-- This DOES NOT WORK:
SELECT heroes.name as hero, CONCAT(people.firstname, ' ', people.lastname) as person 
    FROM heroes FULL OUTER JOIN people ON heroes.person_id = people.id
    ;


-- Instead, use UNION
-- ex: (1,2,3) union (2,3,4) => (1,2,3,4)
SELECT heroes.name as hero, CONCAT(people.firstname, ' ', people.lastname) as person FROM people LEFT OUTER JOIN heroes ON heroes.person_id = people.id
UNION 
SELECT heroes.name as hero, CONCAT(people.firstname, ' ', people.lastname) as person FROM people RIGHT OUTER JOIN heroes ON heroes.person_id = people.id
;

SELECT heroes.name as hero, CONCAT(people.firstname, ' ', people.lastname) as person FROM people LEFT OUTER JOIN heroes ON heroes.person_id = people.id
UNION ALL
SELECT heroes.name as hero, CONCAT(people.firstname, ' ', people.lastname) as person FROM people RIGHT OUTER JOIN heroes ON heroes.person_id = people.id
;


CREATE TABLE hero_powers (hero_id int, power VARCHAR(200), FOREIGN KEY (hero_id) REFERENCES heroes(id));
INSERT INTO hero_powers (hero_id, power) VALUES (@the_flash, 'Speed');
INSERT INTO hero_powers (hero_id, power) VALUES (@wonder_woman, 'Strength');
INSERT INTO hero_powers (hero_id, power) VALUES (@wonder_woman, 'Flight');
SELECT * FROM hero_powers;
SELECT * FROM heroes 
    JOIN people ON people.id = heroes.person_id
    JOIN hero_powers ON heroes.id = hero_powers.hero_id
    ;
-- This gives us one row per pairing...
SELECT name, power FROM heroes JOIN hero_powers ON heroes.id = hero_powers.hero_id;
-- ... but what if we want one row per hero?
-- Couple of options: GROUP_CONCAT...
SELECT name, GROUP_CONCAT(power) as powers
	FROM heroes JOIN hero_powers ON heroes.id = hero_powers.hero_id
	GROUP BY name
;
-- ... or in later versions (5.7+?) of MySQL: JSON_ARRAYAGG...
SELECT name, JSON_ARRAYAGG(power) as powers
	FROM heroes JOIN hero_powers ON heroes.id = hero_powers.hero_id
	GROUP BY name
;
    


CREATE TABLE yearly_saves (hero_id INT, year INT, num_saves INT, FOREIGN KEY (hero_id) REFERENCES heroes(id));
INSERT INTO yearly_saves (hero_id, year, num_saves) VALUES (@wonder_woman, 2020, 115);
INSERT INTO yearly_saves (hero_id, year, num_saves) VALUES (@wonder_woman, 2021, 37);
INSERT INTO yearly_saves (hero_id, year, num_saves) VALUES (@wonder_woman, 2022, 82);
INSERT INTO yearly_saves (hero_id, year, num_saves) VALUES (@the_flash, 2020, 15);
INSERT INTO yearly_saves (hero_id, year, num_saves) VALUES (@the_flash, 2021, 34);
INSERT INTO yearly_saves (hero_id, year, num_saves) VALUES (@the_flash, 2022, 87);
INSERT INTO yearly_saves (hero_id, year, num_saves) VALUES (@martian_manhunter, 2020, 1545);
INSERT INTO yearly_saves (hero_id, year, num_saves) VALUES (@martian_manhunter, 2021, 15);
INSERT INTO yearly_saves (hero_id, year, num_saves) VALUES (@martian_manhunter, 2022, 234);
SELECT * FROM yearly_saves;

-- We can get the maximum number of saves from our table altogether with MAX:
SELECT MAX(num_saves) as overall_record FROM yearly_saves;
-- Or we can get the max number of saves per hero if we use some grouping:
SELECT hero_id, MAX(num_saves) as personal_record FROM yearly_saves GROUP BY hero_id;
-- But how can we get more information about the record number of saves?
-- This doesn't give us the hero/year/record that we want:
SELECT year, hero_id, MAX(num_saves) as personal_record
    FROM yearly_saves
    GROUP BY hero_id, year;
-- This doesn't work because hero_id needs to be grouped:
SELECT year, hero_id, MAX(num_saves) as personal_record, year
    FROM yearly_saves
    GROUP BY hero_id;




SELECT heroes.name
    -- , heroes.id
    , MAX(num_saves) as personal_record
    FROM yearly_saves
    JOIN heroes ON yearly_saves.hero_id = heroes.id
    -- WHERE num_saves > 100
    GROUP BY heroes.name
;


-- This does the same thing, but a different way:
SELECT name, personal_record FROM
    (
        SELECT hero_id, MAX(num_saves) as personal_record FROM yearly_saves GROUP BY hero_id
    ) as personal_records
    JOIN heroes ON (heroes.id = personal_records.hero_id)
;
-- It's basically joining these:
-- SELECT hero_id, MAX(num_saves) as personal_record FROM yearly_saves GROUP BY hero_id;
-- SELECT * FROM heroes;


SELECT name, personal_record FROM
    (
        SELECT hero_id, MAX(num_saves) as personal_record FROM yearly_saves GROUP BY hero_id
    ) as personal_records
    JOIN heroes ON (heroes.id = personal_records.hero_id)
    WHERE (personal_record >= 100)
;
SELECT name, personal_record FROM
    (
        SELECT hero_id, MAX(num_saves) as personal_record 
        FROM yearly_saves
        WHERE (num_saves > 100)
        GROUP BY hero_id
    ) as personal_records
    JOIN heroes ON (heroes.id = personal_records.hero_id)
;



-- HERE WE COULD GET THE HERO DATA ABOUT THE HERO WITH THE MOST YEARLY SAVES:
SELECT heroes.name, yearly_saves.year, yearly_saves.num_saves FROM yearly_saves 
    -- The join gets me the hero names instead of just boring IDs
    JOIN heroes ON heroes.id = yearly_saves.hero_id
    -- The WHERE-clause with a sub-SELECT narrows it down to the actual max/record-holder:
    WHERE num_saves = (SELECT MAX(num_saves) FROM yearly_saves)
;








SELECT * FROM yearly_saves 
    WHERE yearly_saves.num_saves = (SELECT MAX(num_saves) FROM yearly_saves)
    ;
-- So now we have a hero_id to work with... we can join some stuff in there:
SELECT * FROM yearly_saves 
    JOIN heroes ON yearly_saves.hero_id = heroes.id
    WHERE yearly_saves.num_saves = (SELECT MAX(num_saves) FROM yearly_saves)
    ;
-- And then of course we might be more specific about what we want (not just using the wildcard *)
SELECT heroes.name, yearly_saves.num_saves FROM yearly_saves 
    JOIN heroes ON yearly_saves.hero_id = heroes.id
    WHERE yearly_saves.num_saves = (SELECT MAX(num_saves) FROM yearly_saves)
    ;
-- But what if Wonder Woman saved exactly that many people another year?:
INSERT INTO yearly_saves (hero_id, year, num_saves) VALUES (@wonder_woman, 2019, 1545);
-- No problem. We just get two rows back instead:
SELECT heroes.name, yearly_saves.num_saves FROM yearly_saves 
    JOIN heroes ON yearly_saves.hero_id = heroes.id
    WHERE yearly_saves.num_saves = (SELECT MAX(num_saves) FROM yearly_saves)
    ;


-- Now let's drop our tables:
-- What happens if we drop them in this order?
drop table heroes;
-- Wait. What happened?
-- Okay, let's drop them sequentially to eliminate dependencies:
drop table hero_powers;
drop table yearly_saves;
drop table heroes;
drop table people;























