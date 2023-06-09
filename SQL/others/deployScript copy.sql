create database `overseas_travel_proto`;
USE overseas_travel_proto;

CREATE TABLE IF NOT EXISTS countries (
    countryCode char(2) not null, 
    countryName varchar(64) not null,
    aciCountry enum ('A', 'N') not null,
    PRIMARY KEY (countryCode)
);
CREATE TABLE IF NOT EXISTS pemGroup (
    pemGroupId char(6) not null,
    pemName varchar(64) not null,
    PRIMARY KEY (pemGroupId)
);
CREATE TABLE IF NOT EXISTS course (
    courseCode char(6) not null,
    courseName varchar(64) not null,
    courseManager varchar(64) not null,
    PRIMARY KEY (courseCode)
);
CREATE TABLE IF NOT EXISTS students (
    adminNo char(7) not null,
    name varchar(64) not null,
    citizenshipStatus enum ('Singapore citizen', 'Permanent resident', 'International Student') not null,
    stage tinyint not null,
    course char(6) not null,
    pemGroup char(6) not null,
    PRIMARY KEY (adminNo),
    FOREIGN KEY (course) REFERENCES course (courseCode),
    FOREIGN KEY (pemGroup) REFERENCES pemGroup (pemGroupId)
    );
CREATE TABLE IF NOT EXISTS overseasPrograms (
    programID CHAR(9) NOT NULL,
    programName VARCHAR(64) not null,
    programType ENUM (
        'Overseas educational trip',
        'Overseas internship program',
        'Overseas immersion program',
        'Overseas Competition/Exchange',
        'Overseas Leadership Training',
        'Overseas Leadership Training with Outward Bound',
        'Overseas Service Learning-Youth Expedition Programme'
    ) not null,
    startDate DATE not null,
    endDate DATE not null,
    estDate VARCHAR(64),
    countryCode char(2) not null,    
    city VARCHAR(64) not null,
    partnerName VARCHAR(64),
    overseasPartnerType ENUM ('Company', 'Institution', 'Others') not null,
    tripLeaders VARCHAR(255),
    estNumStudents smallint,
    -- approvalStatus ENUM('Approved', 'Rejected', 'Pending') not null,
    approved ENUM('Yes', 'No') not null,
    PRIMARY KEY (programID, countryCode, city),
    FOREIGN KEY (countryCode) REFERENCES countries (countryCode)
);
CREATE TABLE IF NOT EXISTS trips (
    studAdmin CHAR(7) NOT NULL,
    programID CHAR(9) NOT NULL,
    comments TEXT,
    PRIMARY KEY (studAdmin, programID),
    FOREIGN KEY (studAdmin) REFERENCES students (adminNo),
    FOREIGN KEY (programID) REFERENCES overseasPrograms (programID)
);
CREATE TABLE IF NOT EXISTS oimpDetails (
    gsmCode varchar(16) not null,
    courseCode char(6) not null,
    studAdmin char(7) not null,
    gsmName varchar(64) not null,
    PRIMARY KEY (studAdmin,gsmCode),
    FOREIGN KEY (courseCode) REFERENCES course (courseCode),
    FOREIGN KEY (studAdmin) REFERENCES students (adminNo)
);
CREATE TABLE IF NOT EXISTS users (
    username varchar(64) not null,
    password varchar(64) not null,
    accountType enum ('Admin', 'Teacher', 'Guest') not null,
    name varchar(64) not null,
    PRIMARY KEY (username)
);
CREATE TABLE auditTable (
    tableName VARCHAR(100) NOT NULL,
    columnName VARCHAR(100) NOT NULL,
    oldValue TEXT,
    newValue TEXT,
    programID CHAR(9) not null,
    timeStamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW KPI1 AS
SELECT COUNT(DISTINCT trips.studAdmin) AS `Number_of_Students`
FROM trips
JOIN students ON trips.studAdmin = students.adminNo
WHERE students.stage = 3 AND students.citizenshipStatus IN ('Permanent resident', 'Singapore citizen');

CREATE VIEW KPI2 AS
SELECT COUNT(DISTINCT t.studAdmin) AS `ACI_Student_Count`
FROM trips t
JOIN overseasPrograms op ON t.programID = op.programID
JOIN countries c ON op.countryCode = c.countryCode
JOIN students s ON t.studAdmin = s.adminNo
WHERE c.aciCountry = 'A' AND s.stage = 3 AND s.citizenshipStatus IN ('Permanent resident', 'Singapore citizen');

CREATE VIEW KPI3 AS
SELECT COUNT(DISTINCT t.studAdmin) AS `OITP_Student_Count`
FROM trips t
JOIN overseasPrograms op ON t.programID = op.programID
JOIN countries c ON op.countryCode = c.countryCode
JOIN students s ON t.studAdmin = s.adminNo
WHERE c.aciCountry = 'A' AND op.programType = 'Overseas internship program' AND s.stage = 3 AND s.citizenshipStatus IN ('Permanent resident', 'Singapore citizen');

CREATE VIEW KPI1courseLevel AS
SELECT c.courseCode AS CourseCode, 
c.courseName AS CourseName, COUNT(DISTINCT t.studAdmin) AS `Course_Level_Student_Count`
FROM trips t
JOIN students s ON t.studAdmin = s.adminNo
JOIN course c ON s.course = c.courseCode
WHERE s.stage = 3 AND s.citizenshipStatus IN ('Permanent resident', 'Singapore citizen')
GROUP BY c.courseCode, c.courseName;

CREATE VIEW KPI2courseLevel AS
SELECT co.courseCode AS CourseCode, 
co.courseName AS CourseName, COUNT(DISTINCT t.studAdmin) AS `Course_Level_ACI_Student_Count`
FROM trips t
JOIN overseasPrograms op ON t.programID = op.programID
JOIN countries c ON op.countryCode = c.countryCode
JOIN students s ON t.studAdmin = s.adminNo
JOIN course co ON s.course = co.courseCode
WHERE c.aciCountry = 'A' AND s.stage = 3 AND s.citizenshipStatus IN ('Permanent resident', 'Singapore citizen')
GROUP BY co.courseCode, co.courseName;

CREATE VIEW KPI3courseLevel AS
SELECT co.courseCode AS CourseCode, 
co.courseName AS CourseName, COUNT(DISTINCT t.studAdmin) AS `Course_Level_OITP_Student_Count`
FROM trips t
JOIN overseasPrograms op ON t.programID = op.programID
JOIN countries c ON op.countryCode = c.countryCode
JOIN students s ON t.studAdmin = s.adminNo
JOIN course co ON s.course = co.courseCode
WHERE c.aciCountry = 'A' AND op.programType = 'Overseas internship program' AND s.stage = 3 AND s.citizenshipStatus IN ('Permanent resident', 'Singapore citizen')
GROUP BY co.courseCode, co.courseName;

CREATE VIEW oimpDetailsView AS
SELECT
    trips.studAdmin AS StudentAdmin,
    trips.programID AS ProgramID,
    overseasPrograms.programName AS ProgramName,
    overseasPrograms.city AS City,
    overseasPrograms.partnerName AS PartnerName,
    students.course AS Course,
    oimpDetails.gsmCode AS GSMCode,
    oimpDetails.courseCode AS CourseCode,
    oimpDetails.gsmName AS GSMName
FROM trips
JOIN overseasPrograms ON trips.programID = overseasPrograms.programID
JOIN students ON trips.studAdmin = students.adminNo
JOIN oimpDetails ON trips.studAdmin = oimpDetails.studAdmin
WHERE students.stage = 3;



DELIMITER //
CREATE PROCEDURE getProgramAcronym(programType VARCHAR(64), OUT acronym CHAR(3))
BEGIN
    CASE programType
    WHEN 'Overseas educational trip' THEN SET acronym = 'OET';
    WHEN 'Overseas internship program' THEN SET acronym = 'OIP';
    WHEN 'Overseas immersion program' THEN SET acronym = 'IMP';
    WHEN 'Overseas Competition/Exchange' THEN SET acronym = 'OCP';
    WHEN 'Overseas Leadership Training' THEN SET acronym = 'OLT';
    WHEN 'Overseas Leadership Training with Outward Bound' THEN SET acronym = 'TOB';
    WHEN 'Overseas Service Learning-Youth Expedition Programme' THEN SET acronym = 'YEP';
    ELSE SET acronym = '';
    END CASE;
END//
DELIMITER;

DELIMITER //
CREATE TRIGGER programID_Before_Insert
BEFORE INSERT
ON overseasPrograms FOR EACH ROW
BEGIN
    DECLARE acronym CHAR(3);
    DECLARE year CHAR(4);
    DECLARE aciChar CHAR(1);
    DECLARE seqNum CHAR(3); -- change this line
    DECLARE newProgramID CHAR(9);

    -- Call the stored procedure to get the acronym
    CALL getProgramAcronym(NEW.programType, acronym);

    -- Get the year from the startDate
    SET year = SUBSTRING(YEAR(NEW.startDate), 3, 2);

    -- Get the ACI or NON-ACI character directly from the countries table
    SET aciChar = (SELECT aciCountry FROM countries WHERE countryCode = NEW.countryCode);

    -- Get the next sequence number
    SET seqNum = LPAD((SELECT COUNT(*) + 1 FROM overseasPrograms WHERE SUBSTRING(programID, 4, 2) = year), 3, '0');

    -- Construct the new programID
    SET newProgramID = CONCAT(acronym, year, aciChar, seqNum);

    -- Set the new programID
    SET NEW.programID = newProgramID;
END//
DELIMITER ;

CREATE VIEW plannedTrips AS
SELECT programName, programType, estDate, countryCode, city, partnerName, tripLeaders, estNumStudents, approved
FROM overseasPrograms;

DELIMITER //
CREATE TRIGGER overseasPrograms_update_trigger
AFTER UPDATE ON overseasPrograms
FOR EACH ROW
BEGIN
    IF NEW.programID != OLD.programID THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'programID', OLD.programID, NEW.programID, NEW.programID);
    END IF;
    
    IF NEW.programName != OLD.programName THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'programName', OLD.programName, NEW.programName, NEW.programID);
    END IF;
    
    IF NEW.programType != OLD.programType THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'programType', OLD.programType, NEW.programType, NEW.programID);
    END IF;
    
    IF NEW.startDate != OLD.startDate THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'startDate', OLD.startDate, NEW.startDate, NEW.programID);
    END IF;
    
    IF NEW.endDate != OLD.endDate THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'endDate', OLD.endDate, NEW.endDate, NEW.programID);
    END IF;
    
    IF NEW.estDate != OLD.estDate THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'estDate', OLD.estDate, NEW.estDate, NEW.programID);
    END IF;
    
    IF NEW.countryCode != OLD.countryCode THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'countryCode', OLD.countryCode, NEW.countryCode, NEW.programID);
    END IF;
    
    IF NEW.city != OLD.city THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'city', OLD.city, NEW.city, NEW.programID);
    END IF;
    
    IF NEW.partnerName != OLD.partnerName THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'partnerName', OLD.partnerName, NEW.partnerName, NEW.programID);
    END IF;
    
    IF NEW.overseasPartnerType != OLD.overseasPartnerType THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'overseasPartnerType', OLD.overseasPartnerType, NEW.overseasPartnerType, NEW.programID);
    END IF;
    
    IF NEW.tripLeaders != OLD.tripLeaders THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'tripLeaders', OLD.tripLeaders, NEW.tripLeaders, NEW.programID);
    END IF;
    
    IF NEW.estNumStudents != OLD.estNumStudents THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'estNumStudents', OLD.estNumStudents, NEW.estNumStudents, NEW.programID);
    END IF;
    
    IF NEW.approved != OLD.approved THEN
        INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
        VALUES ('overseasPrograms', 'approved', OLD.approved, NEW.approved, NEW.programID);
END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER overseasPrograms_delete_trigger
AFTER DELETE ON overseasPrograms
FOR EACH ROW
BEGIN
    DECLARE old_values TEXT;

    SET old_values = CONCAT(
        'programID:', COALESCE(OLD.programID, ''), ', ',
        'programName:', COALESCE(OLD.programName, ''), ', ',
        'programType:', COALESCE(OLD.programType, ''), ', ',
        'startDate:', COALESCE(OLD.startDate, ''), ', ',
        'endDate:', COALESCE(OLD.endDate, ''), ', ',
        'estDate:', COALESCE(OLD.estDate, ''), ', ',
        'countryCode:', COALESCE(OLD.countryCode, ''), ', ',
        'city:', COALESCE(OLD.city, ''), ', ',
        'partnerName:', COALESCE(OLD.partnerName, ''), ', ',
        'overseasPartnerType:', COALESCE(OLD.overseasPartnerType, ''), ', ',
        'tripLeaders:', COALESCE(OLD.tripLeaders, ''), ', ',
        'estNumStudents:', COALESCE(OLD.estNumStudents, ''), ', ',
        'approved:', COALESCE(OLD.approved, '')
    );
    
    INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
    VALUES ('overseasPrograms', 'FULL RECORD', old_values, 'data deleted', OLD.programID);
END //
DELIMITER ;



-- CREATE TRIGGER overseasPrograms_update_trigger
-- AFTER UPDATE ON overseasPrograms
-- FOR EACH ROW
-- BEGIN
--     IF NOT (
--         NEW.programID <=> OLD.programID AND
--         NEW.programName <=> OLD.programName AND
--         NEW.programType <=> OLD.programType AND
--         NEW.startDate <=> OLD.startDate AND
--         NEW.endDate <=> OLD.endDate AND
--         NEW.estDate <=> OLD.estDate AND
--         NEW.countryCode <=> OLD.countryCode AND
--         NEW.city <=> OLD.city AND
--         NEW.partnerName <=> OLD.partnerName AND
--         NEW.overseasPartnerType <=> OLD.overseasPartnerType AND
--         NEW.tripLeaders <=> OLD.tripLeaders AND
--         NEW.estNumStudents <=> OLD.estNumStudents AND
--         NEW.approved <=> OLD.approved
--     ) THEN
--         INSERT INTO auditTable (tableName, columnName, oldValue, newValue, programID)
--         VALUES ('overseasPrograms', 'row', 'old row values', 'new row values', NEW.programID);
--     END IF;
-- END;