-- Data Cleaning


SELECT *
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null values and Blank values
-- 4. Remove any Columns or Rows


-- a good practice to make a copy of the table in doing all the cleaning to maintain the raw data if there will be mistakes done
CREATE TABLE layoffs_copy LIKE layoffs;

INSERT layoffs_copy
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_copy;


-- 1. Remove Duplicates
-- make a ROW_NUMBER to easily identify if there are duplicates
SELECT *,
	   ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM layoffs_copy;

-- make a cte out of it to get row_num that is greater than 1, indicating the duplicates
WITH cte AS (
	SELECT *,
	   ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
	FROM layoffs_copy
)
SELECT *
FROM cte
WHERE row_num > 1;

-- now to delete the duplicates which are ROW_NUM > 1, make another copy table as layoffs_copy2 so you can easily DELETE the duplicates
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

INSERT INTO layoffs_copy2
SELECT *,
	   ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM layoffs_copy;

DELETE FROM layoffs_copy2
WHERE row_num > 1;


-- 2. Standardizing Data
-- company
SELECT company, TRIM(company)	-- there was a space before a value on some
FROM layoffs_copy2;

UPDATE layoffs_copy2
SET company = TRIM(company);

-- industry
SELECT DISTINCT(industry)	-- three distinct rows with 'Crypto' on that should be one same industry
FROM layoffs_copy2
ORDER BY 1;

SELECT *
FROM layoffs_copy2
WHERE industry LIKE '%Crypto%';

UPDATE layoffs_copy2
SET industry = 'Crypto'
WHERE industry LIKE '%Crypto%';

-- country
SELECT DISTINCT country	-- there is a dot after United States
FROM layoffs_copy2
ORDER BY 1;

UPDATE layoffs_copy2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE '%United States%';

-- date
SELECT date,					-- change the format from text to a date m/d/y format
STR_TO_DATE(date, '%m/%d/%Y')
FROM layoffs_copy2;

UPDATE layoffs_copy2
SET date = STR_TO_DATE(date, '%m/%d/%Y');

ALTER TABLE layoffs_copy2
MODIFY date DATE;


-- 3. Null values and Blank values
SELECT *
FROM layoffs_copy2
WHERE company IS NULL 
	OR location IS NULL
    OR industry IS NULL -- null and blank
    OR total_laid_off IS NULL -- null
    OR percentage_laid_off IS NULL -- null 
    OR date IS NULL -- null
    OR stage IS NULL -- null
    OR country IS NULL
    OR funds_raised_millions IS NULL; -- null and blank

SELECT *								-- some company has a blank industry but is obvious with a similar row that has the industry name	
FROM layoffs_copy2						-- we should make use of this blank and fill it up with the appropriate industry
WHERE industry IS NULL OR industry = '';

SELECT t1.industry, t2.industry			
FROM layoffs_copy2 t1
JOIN layoffs_copy2 t2
	ON t1.company = t2.company AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '') AND t2.industry IS NOT NULL;

UPDATE layoffs_copy2	-- setting the blanks to NULLs 
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_copy2 t1									-- populating the NULL values (replacing it with the corresponding obvious values)
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
