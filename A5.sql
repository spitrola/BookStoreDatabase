/*
File: A5.sql, Winter 2014, Comp2521, A5
Prepared On: April 11, 2014
Prepared By: Sonia Pitrola
*/

\! rm -f A5.log
tee A5.log

-- setting foreign key checks to zero 
SET foreign_key_checks = 0;

-- Dropping tables 
DROP TABLE IF EXISTS User;
DROP TABLE IF EXISTS Book;
DROP TABLE IF EXISTS Author;
DROP TABLE IF EXISTS BookAuthor;
DROP TABLE IF EXISTS ReadBook;

-- setting foreign key checks to one 
SET foreign_key_checks = 1;

-- creating table User
CREATE TABLE User(
Email VARCHAR(100) PRIMARY KEY, 
DateAdded TIMESTAMP NOT NULL,
NickName VARCHAR(100) UNIQUE,
Profile VARCHAR (300)
);

-- creating table Book
CREATE TABLE Book(
BookID INT PRIMARY KEY AUTO_INCREMENT,
Title VARCHAR (200) NOT NULL,
Year INTEGER(4) NOT NULL,
NumRaters INT DEFAULT 0,
Rating DECIMAL(2,1)
);

-- creating table Author
CREATE TABLE Author(
AuthorID INT PRIMARY KEY AUTO_INCREMENT, 
LastName VARCHAR(100),
FirstName VARCHAR(100),
MiddleName VARCHAR(100),
DOB DATE NOT NULL
);

-- creating table BookAuthor
CREATE TABLE BookAuthor(
AuthorID INT,
BookID INT,
PRIMARY KEY (AuthorID, BookID)
);

-- creating table READBOOK
CREATE TABLE ReadBook(
BookID INT, 
Email VARCHAR(100),
DateRead DATE NOT NULL, 
Rating INT,
PRIMARY KEY (Email, BookID)
);

-- adding foreign key constraints 
ALTER TABLE BookAuthor
ADD CONSTRAINT FOREIGN KEY (AuthorID) REFERENCES Author(AuthorID);
ALTER TABLE BookAuthor
ADD CONSTRAINT FOREIGN KEY (BookID) REFERENCES Book(BookID);
ALTER TABLE ReadBook
ADD CONSTRAINT FOREIGN KEY (BookID) REFERENCES Book(BookID);
ALTER TABLE ReadBook
ADD CONSTRAINT FOREIGN KEY (Email) REFERENCES User(Email);

-- It is likely we will want to search by Book title so add a title index.
CREATE INDEX book_title ON Book(Title);

-- We may want to order/search by book year. So we want to add a year index. 
CREATE INDEX book_year ON Book(Year);

-- We may want to order/search when the user read the book. So we want to add a date index. 
CREATE INDEX readBook_date ON ReadBook(DateRead);

-- We may want to order the books read by the user by the rating. 
CREATE INDEX readBook_rate ON ReadBook(Rating);

-- USER insert trigger. 
-- This is a before insert row trigger. 
-- It is created to make sure that when a user is inserted that the email is valid. 
DELIMITER $$
CREATE TRIGGER user_bir
BEFORE INSERT ON User 
FOR EACH ROW
BEGIN 
-- declaring variables
DECLARE ok BOOLEAN;
DECLARE msg VARCHAR(200);
-- checking if the email is in correct format...example@example1.ca 
-- storing it in the ok boolean
SELECT NEW.Email REGEXP '^[A-Z0-9._%-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$' INTO ok;
-- if check to see if ok is true or not
-- if not ok then print msg else continue to insert email 
IF (NOT ok) THEN
     SET msg = CONCAT('Email Address: ', NEW.Email, ' Invalid.');
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
END IF;

SET NEW.DateAdded = NOW();
END$$
DELIMITER ;

-- USER update trigger. 
-- this is a before update row trigger
-- it is created to make sure the the email cannot be updated 
-- and dateAdded cannot be updated...if either are update a error msg will appear
DELIMITER $$
CREATE TRIGGER user_bur
BEFORE UPDATE ON User 
FOR EACH ROW
BEGIN
-- delcaring variables
DECLARE msg VARCHAR(200);
DECLARE ok BOOLEAN;
-- if check to see if new email is not equal to the old email
-- if it is then an error msg will appear asking the user to delele the account
IF(NEW.Email != OLD.Email) THEN
    SET msg = CONCAT ('Email Address ', OLD.Email, ' cannot be modified, please delete user if you wish');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
END IF;
-- if check to see if new DateAdded is not equal to the old DateAdded
-- if it is then an error msg will appear 
IF(NEW.DateAdded != OLD.DateAdded) THEN
    SET msg = 'DateAdded cannnot be modified';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
END IF;
END$$
DELIMITER ;

-- before delete row trigger on user
-- delete user but actually deleting the readbook records
DELIMITER $$
CREATE TRIGGER user_bdr
BEFORE DELETE ON User
FOR EACH ROW 
BEGIN
-- delete from ReadBook where the Email equals an old email
   DELETE FROM ReadBook 
   WHERE Email = OLD.Email;
END $$
DELIMITER ;

-- BOOK delete trigger
-- this is a before delete row trigger
-- it is created to make sure that NO books can be deleted
DELIMITER $$
CREATE TRIGGER book_bdr
BEFORE DELETE ON Book
FOR EACH ROW
BEGIN
-- declaring variables
DECLARE msg VARCHAR(200);
-- setting msg and displaying it when user tries to delete a book
   SET msg = 'Book cannot be deleted';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
END $$
DELIMITER ;

-- before insert row trigger on ReadBook
-- inserting ReadBook values
DELIMITER $$ 
CREATE TRIGGER readbook_bir 
BEFORE INSERT ON ReadBook 
FOR EACH ROW
BEGIN
DECLARE msg VARCHAR(200);
DECLARE num INT;
-- checking to see if Rating is between 1 and 10 
-- if not print out a msg
IF(new.Rating  > 10 OR NEW.Rating < 1) THEN
      SET msg = 'Rating not valid';
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
END IF;
-- if rating is a valid then set NumRaters plus 1
UPDATE Book 
SET NumRaters = NumRaters + 1 WHERE Book.BookID = NEW.BookID; 
END$$
DELIMITER ;

-- before delete trigger on ReadBook
-- Delete readbook updating book numRaters
DELIMITER $$
CREATE TRIGGER readbook_bdr
BEFORE DELETE ON ReadBook 
FOR EACH ROW 
BEGIN
-- update Book with NumRaters minus 1 where BookID equals old BookID
UPDATE Book
SET NumRaters = NumRaters - 1 WHERE Book.BookID = OLD.BookID;
END$$
DELIMITER ;

-- after delete trigger on row for ReadBook
-- update the Average rating after a book is deleted 
DELIMITER $$
CREATE TRIGGER readbook_adr
AFTER DELETE ON ReadBook
FOR EACH ROW
BEGIN
DECLARE num INT;
-- calculating the sum of ratings 
SELECT SUM(Rating) INTO num FROM ReadBook WHERE OLD.BookID = ReadBook.BookID;
-- update Book by taking the num divided by number of raters
UPDATE Book
SET Rating = num / NumRaters WHERE Book.BookID = OLD.BookID;
END$$
DELIMITER ;

-- after insert row trigger for readbook
-- once a row is inserted calculate the Average Rating
DELIMITER $$
CREATE TRIGGER readbook_air
AFTER INSERT ON ReadBook
FOR EACH ROW
BEGIN
DECLARE num INT;
-- calculating the sum of ratings
SELECT SUM(Rating) INTO num FROM ReadBook WHERE NEW.BookID = ReadBook.BookID;
-- update Book and set Rating to num divided by numRaters
UPDATE Book
SET Rating = num / NumRaters WHERE Book.BookID = NEW.BookID;
END$$
DELIMITER ;

-- before update row trigger for readbook
DELIMITER $$
CREATE TRIGGER readbook_bur
BEFORE UPDATE ON ReadBook
FOR EACH ROW 
BEGIN
DECLARE msg VARCHAR (200);
-- check if the rating is between 1 and 10
-- if not then print a msg
IF(new.Rating  > 10 OR NEW.Rating < 1) THEN
      SET msg = 'Rating not valid';
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
END IF;
END$$
DELIMITER ;

-- after update row trigger for readbook
-- calcualte the average rating after the update
DELIMITER $$
CREATE TRIGGER readbook_aur
AFTER UPDATE ON ReadBook
FOR EACH ROW
BEGIN
DECLARE num INT;
-- calculate the sum of the ratings
SELECT SUM(Rating) INTO num FROM ReadBook WHERE NEW.BookID = ReadBook.BookID;
-- update Book and set Rating to num divided by NumRaters
UPDATE Book
SET Rating = num/NumRaters WHERE Book.BookID = OLD.BookID;
END$$
DELIMITER ;

-- inserting Valid emails creating USERS
INSERT INTO User (Email, NickName, Profile) VALUES 
('spitr692@mtroyal.ca', 'user1', NULL), 
('spitrola27@gmail.com', NULL, 'user2'),
('hello@whatwhat.com', NULL, 'user3');

-- inserting Books into BOOK table
INSERT INTO Book (Title, Year) VALUES
('Book 1', 2010), 
('Book 2', 2013),
('Book 3', 1990),
('Book 4', 1764);

-- inserting Author into AUTHOR table
INSERT INTO Author (LastName, DOB) VALUES
('Author 1', date('1987-01-01')),
('Author 2', date('1992-02-20')),
('Author 3', date('1764-12-12')),
('Author 4', date('1993-06-06'));

-- inserting into BOOKAUTHOR
INSERT INTO BookAuthor (AuthorID, BookID) VALUES 
(1,1),
(2,1),
(3,1),
(4,4),
(1,2),
(2,3),
(2,2),
(3,3);

-- inserting into ReadBook
INSERT INTO ReadBook (BookID, Email, DateRead, Rating) VALUES
(1, 'spitr692@mtroyal.ca', date('2014-01-20'), 10), 
(1, 'spitrola27@gmail.com', date('2014-01-20'), 1),
(3, 'hello@whatwhat.com', date('2012-05-30'), 2),
(4, 'spitr692@mtroyal.ca', date('2013-05-06'), 5),
(1, 'hello@whatwhat.com', date('2002-10-10'),9),
(4, 'spitrola27@gmail.com',date('1990-09-09'),1);


-- Q2
CREATE OR REPLACE VIEW book_author AS
SELECT a.AuthorID, b.BookID, b.Title 
FROM Author a, Book b, BookAuthor c 
WHERE a.AuthorID=c.AuthorID 
   AND b.BookID=c.BookID 
ORDER BY 3;

-- Q3
CREATE OR REPLACE VIEW read_stats AS
SELECT a.Email, a.Rating, b.BookID, b.NumRaters, b.Rating AS 'averageRating' 
FROM ReadBook a, Book b 
WHERE a.BookID=b.BookID;

notee
