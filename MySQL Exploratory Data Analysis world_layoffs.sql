-- Exploratory Data Analysis
-- Dataset is about layoffs from around the world from 2020 to 2023


-- 'percentage_laid_off' doesn't give us that much information because we don't know how big each company is
-- However we can explore on which company has 100% laid off
SELECT	company, location, industry, total_laid_off, 
	MAX(percentage_laid_off) AS max_perc_laid
FROM layoffs_copy2
GROUP BY company, location, industry, total_laid_off
	HAVING max_perc_laid = 1
ORDER BY total_laid_off DESC;

-- See the total of laid off per company
SELECT	company, 
		SUM(total_laid_off) AS sum_tot_laid
FROM layoffs_copy2
GROUP BY company
ORDER BY sum_tot_laid DESC;

-- See the range of the dates on the data
SELECT	MIN(date), 
		MAX(date)
FROM layoffs_copy2;

-- See what industry hit the most during the recent covid pandemic
SELECT	industry, 
		SUM(total_laid_off) AS sum_tot_laid
FROM layoffs_copy2
GROUP BY industry
ORDER BY sum_tot_laid DESC;

-- Which country got hit the most
SELECT	country, 
		SUM(total_laid_off) AS sum_tot_laid
FROM layoffs_copy2
GROUP BY country
ORDER BY sum_tot_laid DESC;

-- See year by year with the total lay offs
SELECT	YEAR(date) AS year, 
		SUM(total_laid_off) AS sum_tot_laid
FROM layoffs_copy2
GROUP BY YEAR(date)
ORDER BY year DESC;

-- See how many lay offs during different stages or phases of the company
SELECT	stage, 
		SUM(total_laid_off) AS sum_tot_laid
FROM layoffs_copy2
GROUP BY stage
ORDER BY sum_tot_laid DESC;

-- See the progression of lay offs base on months with its year
SELECT	SUBSTR(date, 1, 7) AS per_month, 
		SUM(total_laid_off) AS sum_tot_laid
FROM layoffs_copy2
WHERE SUBSTR(date, 1, 7) IS NOT NULL
GROUP BY per_month
ORDER BY per_month;

-- See the rolling sum of the previous query
WITH cte AS
(	SELECT	SUBSTR(date, 1, 7) AS per_month, 
			SUM(total_laid_off) AS sum_tot_laid
	FROM layoffs_copy2
	WHERE SUBSTR(date, 1, 7) IS NOT NULL
	GROUP BY per_month
	ORDER BY per_month
)
SELECT	per_month, sum_tot_laid,
		SUM(sum_tot_laid) OVER(ORDER BY per_month) AS rolling_sum_laid
FROM cte;

-- See what company laid off the most per year 
WITH cte1 AS (
	SELECT	company, YEAR(date) AS year, 
			SUM(total_laid_off) AS sum_tot_laid
	FROM layoffs_copy2
	GROUP BY company, year
), cte2 AS (
	SELECT	company, year, sum_tot_laid,
			DENSE_RANK() OVER(PARTITION BY year ORDER BY sum_tot_laid DESC) AS most_laid_rank
	FROM cte1
	WHERE year IS NOT NULL
)
SELECT *
FROM cte2
WHERE most_laid_rank <= 5;

-- The previous query seems to be interesting, so we'll observe base on industry
WITH cte1 AS (
	SELECT	industry, 
			YEAR(date) AS year, 
			SUM(total_laid_off) AS sum_tot_laid
	FROM layoffs_copy2
	GROUP BY industry, year
), cte2 AS (
	SELECT	*,
			DENSE_RANK() OVER(PARTITION BY year ORDER BY sum_tot_laid DESC) AS most_laid_rank
	FROM cte1
	WHERE year IS NOT NULL
)
SELECT *
FROM cte2
WHERE most_laid_rank <= 5;

