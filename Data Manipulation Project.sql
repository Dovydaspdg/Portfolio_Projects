Select location, date, total_cases, new_cases, total_deaths, population
From portfolioproject..CovidDeaths
order by 1,2


--Total deats vs total cases / Death rate today in USA

Select location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)* 100, 2)AS death_percent
FROM portfolioproject..CovidDeaths
WHERE location like '%states%' AND total_deaths IS NOT NULL
ORDER BY total_cases DESC, death_percent DESC


-- Who has got covid? Total cases vs population in Denmark

Select location, date, total_cases, population, ROUND((total_cases/population)* 100, 2)AS total_popolation_got_covid
FROM portfolioproject..CovidDeaths
WHERE location ='Denmark' AND total_deaths IS NOT NULL
ORDER BY total_cases DESC, total_popolation_got_covid DESC

-- Which countries with highest infection rates?

SELECT location,population, MAX(total_cases) AS HighestInfectionCounted, ROUND(MAX(total_cases/population)* 100,2) AS max_popolation_got_covid
FROM portfolioproject..CovidDeaths
WHERE total_cases > 100000 AND total_deaths IS NOT NULL AND location NOT LIKE '%income%'
GROUP BY location, population
ORDER BY max_popolation_got_covid DESC

-- What are the countries with highest death count and total deaths percent to population ? 

SELECT location, MAX(CAST(total_deaths AS INT)) AS Total_deaths_count, ROUND(MAX(total_deaths/population)* 100,2) AS max_popolation_death_rate
FROM portfolioproject..CovidDeaths
WHERE total_cases > 100000 AND total_deaths IS NOT NULL AND location NOT LIKE '%income%' AND continent IS NOT NULL
GROUP BY location
ORDER BY Total_deaths_count DESC

-- What are the continents with highest death count and total deaths percent to population ? 

SELECT continent, MAX(CAST(total_deaths AS INT)) AS Total_deaths_count, ROUND(MAX(total_deaths/population)* 100,2) AS max_popolation_death_rate
FROM portfolioproject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_deaths_count DESC


-- Global tracking per date on cases, deaths, and lethality rate
SET ARITHABORT OFF
SET ANSI_WARNINGS OFF
SELECT Date, SUM(new_cases) AS Cases, SUM(cast(new_deaths AS INT)) AS Deaths, ROUND(SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100,2) AS Lethality_rate
FROM portfolioproject..CovidDeaths
WHERE new_cases IS NOT NULL AND new_cases !=0
GROUP BY date
ORDER BY date 


-- How many vacines where distributes through the entire population on average in Denmark ?

SELECT dea.location AS country, dea.population AS population, SUM(CAST(vac.new_vaccinations AS INT)) AS total_vacinations, ROUND(SUM(CAST(vac.new_vaccinations AS INT))/dea.population,2) AS vacine_per_pop
FROM portfolioproject..CovidDeaths AS dea
LEFT JOIN portfolioproject..CovidVacinations AS vac
on dea.location = vac.location AND dea.date = vac.date
WHERE dea.location = 'Denmark'
GROUP BY dea.location, dea.population

 

 --Vacination rate timeline
CREATE VIEW population_vacinated_percent AS
WITH percent_vac AS 
(
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(BIGINT,vac.new_vaccinations )) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vacinations
FROM portfolioproject..CovidDeaths AS dea
	LEFT JOIN portfolioproject..CovidVacinations as vac
	on dea.iso_code = vac.iso_code AND dea.date = vac.date
WHERE dea.continent  IS NOT NULL
)
SELECT *, ROUND((total_vacinations/2)/ population *100,2) AS vac_rate
FROM percent_vac

--Vacination rate timeline v2
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	vac.people_fully_vaccinated,
	(vac.people_fully_vaccinated / population) *100 AS dose2,
	SUM(CONVERT(BIGINT,vac.new_vaccinations )) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vacinations
FROM portfolioproject..CovidDeaths AS dea
	LEFT JOIN portfolioproject..CovidVacinations as vac
	on dea.iso_code = vac.iso_code AND dea.date = vac.date
WHERE dea.continent  IS NOT NULL



-- Whats the sum of deaths every month from covid in Denmark?

WITH serveris AS (
SELECT location,date, MONTH(date)AS month, YEAR(date) AS year,DAY(date) AS day, population, CONVERT(BIGINT,new_deaths) AS NewDeaths,
SUM(new_cases) OVER (PARTITION BY location ORDER BY date) AS CaseCount
FROM CovidDeaths
),
serveris2 AS (

SELECT s.location,s.year,s.month, s.day,
SUM(NewDeaths) OVER (Partition By s.location ORDER BY s.date) As Deaths,
SUM(NewDeaths/ s.CaseCount *100) OVER (PARTITION BY s.location ORDER BY s.date) AS Death_rate,
SUM(NewDeaths) OVER (PARTITION BY s.location ORDER BY s.month) AS Total_Deaths_this_month,
SUM(NewDeaths) OVER (Partition BY s.location ORDER BY s.year) AS Total_deaths_this_year
FROM CovidDeaths as c
LEFT JOIN serveris AS s
ON s.location = c.location AND s.date = c.date
WHERE s.location = 'Denmark'

)
Select *, 
  SUM(Total_Deaths_this_month) OVER (Partition BY location ORDER BY year) AS Total_deaths_this_year
FROM serveris2
WHERE location = 'Denmark'
ORDER BY year, month


-- Monthly stats in Denmark
WITH count_table AS (

SELECT location, YEAR(date) AS year, MONTH(date) AS month, 
sum(CAST(new_deaths AS INT)) AS monthly_deaths, 
(SUM(new_cases)) AS monthly_cases,
LAG(SUM(CAST(new_deaths AS INT))) OVER(ORDER BY YEAR(date),MONTH(date)) AS previous_month
FROM coviddeaths
WHERE location = 'Denmark'
GROUP BY location, YEAR(date), MONTH(date)

)
SELECT *, ROUND((monthly_deaths / monthly_cases * 100),2) AS monthly_death_rate,
(monthly_deaths - previous_month)  AS Monthly_difference_in_deaths	
FROM count_table

Order BY year, month