
-- Create database and import the file

-- use the hr_database from this point
use hr_database;

-- Explore the loaded data
SELECT *
FROM hr_data;


-- explore table structure
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'hr_data';

-- termdate is nvarchar
-- Fix termdate column formatting
-- update data/time to date and format UTC values

update hr_data
SET termdate = FORMAT(CONVERT(DATETIME,LEFT(termdate,19),120),'yyyy-MM-dd');

-- converting termdate datatype (nvarchar) to date datatype
ALTER TABLE hr_data
ADD new_termdate DATE;

-- copy termdate column data to new_termdate column

update hr_data
SET new_termdate = CASE
	WHEN termdate IS NOT NULL AND ISDATE(termdate) = 1 THEN 
		CAST(termdate AS DATETIME) 
		ELSE NULL 
	END;
-- view new_termdate
SELECT new_termdate
FROM hr_data
ORDER BY new_termdate desc;

-- Create a new column 'age' and caluate the age of employees
ALTER TABLE hr_data
ADD age nvarchar(50);

update hr_data
SET age = DATEDIFF(YEAR,birthdate,GETDATE());

SELECT birthdate,age
FROM hr_data
ORDER BY age;

-- min and max ages

SELECT
	MIN(age) AS minimum_age,
	MAX(age) AS maximum_age
FROM hr_data;

-- KEY INQUIRIES TO ADDRESS USING THE HR_DATA DATASET
-- age demographics within the organization?

--- age demographics
SELECT 
	MIN(age) AS youngest,
	MAX(age) AS oldest
FROM hr_data;

--- age group by gender
SELECT
  age_group,gender,
  COUNT(*) AS count
FROM (
  SELECT
    CASE
      WHEN age >=21 AND age <=30 THEN '21 to 30'
	WHEN age >=31 AND age <=40 THEN '31 to 40'
	WHEN age >=41 AND age <=50 THEN '41 to 50'
      ELSE '50+'
    END AS age_group,gender
	
  FROM hr_data
  WHERE new_termdate IS NULL
) AS Subquery
GROUP BY age_group,gender
ORDER BY age_group,gender;


-- distribution of gender within the company?

SELECT gender,
	COUNT(*) AS Count
FROM hr_data
WHERE new_termdate is NULL
GROUP BY gender
ORDER BY gender;

-- How does gender distribution differ among various departments and job titles within the company?

SELECT gender,department,jobtitle,
	COUNT(*) AS Count
FROM hr_data
WHERE new_termdate is NULL
GROUP BY gender,department,jobtitle
ORDER BY gender,department,jobtitle;

-- What is the racial composition within the company?
SELECT race,
	COUNT(*) AS Count
FROM hr_data
WHERE new_termdate is NULL
GROUP BY race
ORDER BY count DESC;

-- What is the average duration of employment within the company?

SELECT
AVG(DATEDIFF(year,hire_date,new_termdate)) avg_duration

FROM hr_data
WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE();

-- Which department exhibits the highest turnover rate? 
--- Calculate the total number of employees, the count of terminated employees, 
--- and determine the turnover rate by dividing the terminated count by the total count.
SELECT department,total_count,terminated_count,
		(ROUND ((CAST(terminated_count AS FLOAT)/total_count),2)*100) turnover_rate
FROM
(
	SELECT department,
		count(*) total_count,
		SUM(CASE
			WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0
			END) terminated_count
	FROM hr_data
	GROUP BY department
) AS subquery
ORDER BY turnover_rate DESC

-- What is the distribution of tenure across each department?

SELECT department,
AVG(DATEDIFF(year,hire_date,new_termdate)) avg_duration

FROM hr_data
WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE()
GROUP BY department
order BY avg_duration DESC;

-- How many employees in each department work remotely?

SELECT location,
	COUNT(*) AS count
FROM hr_data
WHERE new_termdate IS NULL
GROUP BY location;

-- What is the geographic distribution of employees across various states?

SELECT location_state,
	COUNT(*) AS count
FROM hr_data
WHERE new_termdate is NULL
GROUP BY location_state
ORDER BY count DESC;

-- What is the distribution of job titles within the company?

SELECT jobtitle,
	count(*) AS count
FROM hr_data
GROUP BY jobtitle
ORDER BY count DESC;

-- How has the count of employee hires changed over time?
--- calculate hires
--- calculate terminations
--- (hires-terminations)/hires*100 --> percent hire change
SELECT
hire_year, hires, terminations,
(hires - terminations) AS net_change,
(ROUND(CAST(hires - terminations AS FLOAT)/hires,2))*100 AS percent_hire_change
FROM(
		SELECT 
			YEAR(hire_date) hire_year,
			COUNT(*) AS hires,
			SUM( CASE
				WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0
				END) AS terminations
		FROM hr_data
		GROUP BY YEAR(hire_date)
		) AS subquery
ORDER BY percent_hire_change;