DROP DATABASE IF EXISTS iths;

CREATE DATABASE iths;

USE iths;

DROP TABLE IF EXISTS UNF;

CREATE TABLE UNF (
    	Id DECIMAL(38, 0) NOT NULL,
    	Name VARCHAR(26) NOT NULL,
    	Grade VARCHAR(11) NOT NULL,
    	Hobbies VARCHAR(25),
    	City VARCHAR(10) NOT NULL,
    	School VARCHAR(30) NOT NULL,
    	HomePhone VARCHAR(15),
    	JobPhone VARCHAR(15),
    	MobilePhone1 VARCHAR(15),
    	MobilePhone2 VARCHAR(15)
)  ENGINE=INNODB;

LOAD DATA INFILE '/var/lib/mysql-files/denormalized-data.csv'
	INTO TABLE UNF 
	CHARACTER SET latin1
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\n'
	IGNORE 1 ROWS;

DROP TABLE IF EXISTS Student;
CREATE TABLE Student (
	Id INT NOT NULL AUTO_INCREMENT,
	FirstName VARCHAR(255) NOT NULL,
	LastName VARCHAR(255) NOT NULL,
	CONSTRAINT PRIMARY KEY (Id)
) ENGINE=INNODB;

INSERT INTO Student (Id, FirstName, LastName)
	SELECT DISTINCT
	Id,
	SUBSTRING_INDEX(Name, ' ', 1) AS FirstName,
	SUBSTRING_INDEX(Name, ' ', -1) AS LastName
	FROM UNF;

DROP TABLE IF EXISTS Phone;
CREATE TABLE Phone (
    	PhoneId INT NOT NULL AUTO_INCREMENT,
    	StudentId INT NOT NULL,
    	Type VARCHAR(32),
    	Number VARCHAR(32) NOT NULL,
    	CONSTRAINT PRIMARY KEY(PhoneId)
) ENGINE=INNODB;

INSERT INTO Phone(StudentId, Type, Number) 
	SELECT Id As StudentId, "Home" AS Type, HomePhone as Number FROM UNF
	WHERE HomePhone IS NOT NULL AND HomePhone != ''
	UNION SELECT Id As StudentId, "Job" AS Type, JobPhone as Number FROM UNF
	WHERE JobPhone IS NOT NULL AND JobPhone != ''
	UNION SELECT Id As StudentId, "Mobile" AS Type, MobilePhone1 as Number FROM UNF
	WHERE MobilePhone1 IS NOT NULL AND MobilePhone1 != ''
	UNION SELECT Id As StudentId, "Mobile" AS Type, MobilePhone2 as Number FROM UNF
	WHERE MobilePhone2 IS NOT NULL AND MobilePhone2 != '';

DROP VIEW IF EXISTS PhoneList;
CREATE VIEW PhoneList AS SELECT
	Id AS StudentId,
	FirstName,
	LastName,
	group_concat(Number) AS PhoneNumber
	FROM Student
	JOIN Phone ON Id = StudentId
	GROUP BY StudentId;

DROP TABLE IF EXISTS School;
CREATE TABLE School (
	SchoolId INT NOT NULL AUTO_INCREMENT,
	Name VARCHAR(255) NOT NULL,
	City VARCHAR(255) NOT NULL,
	CONSTRAINT PRIMARY KEY (SchoolId)
) ENGINE=INNODB;

INSERT INTO School(Name, City)
	SELECT DISTINCT
	School,
	City
	FROM UNF;

DROP TABLE IF EXISTS StudentSchool;
CREATE TABLE StudentSchool (
	StudentId INT NOT NULL,
	SchoolId INT NOT NULL,
	CONSTRAINT PRIMARY KEY (StudentId, SchoolId)
) ENGINE=INNODB;

INSERT INTO StudentSchool
	SELECT Id AS StudentId, SchoolId FROM UNF
	JOIN School ON UNF.School = School.Name;


DROP TABLE IF EXISTS Hobby;
CREATE TABLE Hobby (
	HobbyId INT NOT NULL AUTO_INCREMENT,
	Name VARCHAR(32) NOT NULL,
	CONSTRAINT PRIMARY KEY (HobbyId)
) ENGINE=INNODB;

INSERT INTO Hobby (Name)
	SELECT trim(SUBSTRING_INDEX(Hobbies, ',', 1)) AS Name FROM UNF
	WHERE Hobbies IS NOT NULL AND Hobbies != '' AND Hobbies != 'Nothing'
	UNION SELECT trim(SUBSTRING_INDEX(SUBSTRING_INDEX(Hobbies, ',', -2), ',', 1)) AS Name FROM UNF
	WHERE Hobbies IS NOT NULL AND Hobbies != '' AND Hobbies != 'Nothing'
	UNION SELECT trim(SUBSTRING_INDEX(Hobbies, ',', -1)) AS Name FROM UNF
	WHERE Hobbies IS NOT NULL AND Hobbies != '' AND Hobbies != 'Nothing';

DROP TABLE IF EXISTS StudentHobby;
CREATE TABLE StudentHobby (
	StudentId INT NOT NULL,
	HobbyId INT NOT NULL,
	CONSTRAINT PRIMARY KEY (StudentId, HobbyId)
) ENGINE=INNODB;

INSERT INTO StudentHobby (StudentId, HobbyId)
	SELECT DISTINCT StudentId, HobbyId FROM (
		SELECT Id AS StudentId, trim(SUBSTRING_INDEX(Hobbies, ',', 1)) AS Hobby FROM UNF
		WHERE Hobbies IS NOT NULL AND Hobbies != '' AND Hobbies != 'Nothing'
		UNION SELECT Id AS StudentId, trim(SUBSTRING_INDEX(SUBSTRING_INDEX(Hobbies, ',', -2), ',', 1)) AS Hobby FROM UNF
		WHERE Hobbies IS NOT NULL AND Hobbies != '' AND Hobbies != 'Nothing'
		UNION SELECT Id AS StudentId, trim(SUBSTRING_INDEX(Hobbies, ',', -1)) AS Hobby FROM UNF
		WHERE Hobbies IS NOT NULL AND Hobbies != '' AND Hobbies != 'Nothing'
	) AS Hobby2
	INNER JOIN Hobby ON Hobby2.Hobby = Hobby.Name;

DROP VIEW IF EXISTS HobbyList;
CREATE VIEW HobbyList AS SELECT
	Id AS StudentId,
	FirstName,
	LastName,
	group_concat(Name) AS Hobbies
	FROM Student
	JOIN StudentHobby ON Id = StudentId
	JOIN Hobby USING (HobbyId)
	GROUP BY StudentId;

DROP TABLE IF EXISTS Grade;
CREATE TABLE Grade (
	GradeId INT NOT NULL AUTO_INCREMENT,
	Name VARCHAR(255) NOT NULL,
	CONSTRAINT PRIMARY KEY (GradeId)
) ENGINE=INNODB;

INSERT INTO Grade (Name)
	SELECT DISTINCT Grade FROM UNF;

ALTER TABLE Student ADD COLUMN GradeId INT NOT NULL;

UPDATE Student JOIN UNF USING (Id)
	JOIN Grade ON Grade.Name = UNF.Grade
	SET Student.GradeId = Grade.GradeId;

DROP TABLE IF EXISTS StudentList;
CREATE VIEW StudentList AS SELECT
	StudentId as ID,
	Student.FirstName,
	Student.LastName,
	Grade.Name AS Grade,
	Hobbies,
	School.Name AS School,
	City,
	PhoneNumber
	FROM StudentSchool
	LEFT JOIN Student ON (StudentId = Id)
	LEFT JOIN Grade USING (GradeId)
	LEFT JOIN HobbyList USING (StudentId)
	LEFT JOIN School USING (SchoolId)
	LEFT JOIN PhoneList USING (StudentId);