-- Data Cleaning
-- Dataset is about layoffs from around the world from 2020 to 2023


SELECT *		
FROM layoffs;

-- 1. Remove duplicates if there are any
-- 2. Standardize the Data from spelling to other issues
-- 3. Null values and/or blank values then try to populate the possible ones
-- 4. Remove any columns and/or rows that aren't necessary

-- It is a good practice to CREAT a copy of the table where we do all the cleaning steps to preserve the raw data if there are mistakes done
CREATE TABLE layoffs_copy LIKE layoffs;

-- Insert the data into the copy table
INSERT layoffs_copy		
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_copy;


-- 1. Removing duplicates

-- Make a ROW_NUMBER and PARTITION BY every column to easily identify if there are duplicates
SELECT *,					
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
					 date, stage, country, funds_raised_millions
	) AS row_num
FROM layoffs_copy;

-- Make a cte out of it to get row_num that is greater than 1, indicating the duplicates
WITH cte AS (
	SELECT *,
	   ROW_NUMBER() OVER(
			PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
						 date, stage, country, funds_raised_millions
	   ) AS row_num
	FROM layoffs_copy
)
SELECT *			-- If there are two or more under row_num, mean there are duplicates
FROM cte
WHERE row_num > 1;	

-- Now to delete the duplicates which are row_num > 1, CREATE another copy table as layoffs_copy2 and add a new column 'row_num' so we can easily DELETE the row that has duplicates  
CREATE TABLE `layoffs_copy2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert the data into the copy table
INSERT INTO layoffs_copy2
SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
					 date, stage, country, funds_raised_millions
	) AS row_num
FROM layoffs_copy;

DELETE FROM layoffs_copy2
WHERE row_num > 1;


-- 2. Standardizing Data

-- company
-- There was a space before a value on some
SELECT company, TRIM(company)	
FROM layoffs_copy2;

UPDATE layoffs_copy2
SET company = TRIM(company);

-- industry
SELECT DISTINCT industry 	
FROM layoffs_copy2
ORDER BY 1;

-- There are rows with different '%Crypto%' on its name that should be one same industry
UPDATE layoffs_copy2
SET industry = 'Crypto'
WHERE industry LIKE '%Crypto%';

-- country
SELECT DISTINCT country	
FROM layoffs_copy2
ORDER BY 1;

-- there is a dot after the value United States
UPDATE layoffs_copy2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE '%United States%';

-- date
-- Change the format from a text to a date 'm/d/y' format
SELECT date,					
STR_TO_DATE(date, '%m/%d/%Y')
FROM layoffs_copy2;

UPDATE layoffs_copy2
SET date = STR_TO_DATE(date, '%m/%d/%Y');

ALTER TABLE layoffs_copy2
MODIFY COLUMN date DATE;


-- 3. Null values and blank values

-- Some company has a blank industry but is obvious it has the same industry to a similar row that has the industry name
SELECT *									
FROM layoffs_copy2						
WHERE industry IS NULL OR industry = '';

-- We should make use of this blank and populate it with the appropriate industry name
SELECT t1.industry, t2.industry			
FROM layoffs_copy2 t1
JOIN layoffs_copy2 t2
	ON t1.company = t2.company AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '') AND t2.industry IS NOT NULL;

-- Setting the blanks to NULLs first 
UPDATE layoffs_copy2	
SET industry = NULL
WHERE industry = '';

-- Populating the NULL values (replacing it with the corresponding obvious values)
UPDATE layoffs_copy2 t1									
JOIN layoffs_copy2 t2
	ON t1.company = t2.company 
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;


-- 4. Remove Columns and Rows if need be

-- rows
SELECT *
FROM layoffs_copy2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

DELETE FROM layoffs_copy2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- columns
ALTER TABLE layoffs_copy2
DROP COLUMN row_num;


SELECT *
FROM layoffs_copy2;
