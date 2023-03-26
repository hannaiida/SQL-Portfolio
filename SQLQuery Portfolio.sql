SELECT * 
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4



SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
ORDER BY 1,2;

SELECT Location, POPULATION,MAX(total_cases)
FROM dbo.CovidDeaths
GROUP BY LOCATION, POPULATION
--ORDER BY 1,2;

--TOTAL CASES VS TOTAL DEATH
SELECT Location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2;

--TOTAL CASES VS POPULATION
SELECT Location, date, total_cases, population,(total_cases/population)*100 AS CasesPercentage
FROM dbo.CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2;

--Countries with highest infection rate compared to population
SELECT Location, population,MAX(total_cases) AS HighestInfectionCount,MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM dbo.CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

--Countries with highest death count per poulation
-- Issue with data type
SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM dbo.CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Convert NVARCHAR to INT
SELECT Location, MAX(cast(total_deaths as INT)) AS TotalDeathCount
FROM dbo.CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

--DEATH COUNT BY CONTINENT
SELECT continent, MAX(cast(total_deaths as INT)) AS TotalDeathCount
FROM dbo.CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

SELECT location, MAX(cast(total_deaths as INT)) AS TotalDeathCount
FROM dbo.CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Global numbers
SELECT date, SUM(New_cases) AS Total_Cases, SUM(CAST(New_Deaths AS INT)) AS Total_Deaths, SUM(CAST(New_Deaths AS INT))/SUM(New_Cases) * 100 AS DeathPercentage
FROM dbo.CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

SELECT SUM(New_cases) AS Total_Cases, SUM(CAST(New_Deaths AS INT)) AS Total_Deaths, SUM(CAST(New_Deaths AS INT))/SUM(New_Cases) * 100 AS DeathPercentage
FROM dbo.CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;


--Join tables
SELECT *
FROM dbo.CovidDeaths AS Dea
JOIN dbo.CovidVaccinations AS Vac
	ON Dea.location =  Vac.location
	AND Dea.date = Vac.date

-- Total population vs vaccinations
SELECT Dea.Continent, Dea.Location, Dea.Date, Dea.Population, Vac.New_Vaccinations
FROM dbo.CovidDeaths AS Dea
JOIN dbo.CovidVaccinations AS Vac
	ON Dea.location =  Vac.location
	AND Dea.date = Vac.date
WHERE Dea.Continent IS NOT NULL
ORDER BY 2,3

--Roll up counts
SELECT Dea.Continent, Dea.Location, Dea.Date, Dea.Population, Vac.New_Vaccinations
,SUM(CONVERT(BIGINT,Vac.New_Vaccinations)) OVER (PARTITION BY Dea.Location ORDER BY Dea.Location, Dea.Date) AS Accumualated_Total
FROM dbo.CovidDeaths AS Dea
JOIN dbo.CovidVaccinations AS Vac
	ON Dea.location =  Vac.location
	AND Dea.date = Vac.date
WHERE Dea.Continent IS NOT NULL
ORDER BY 2,3

--CTE to calculate percentage of people vaccinated
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, Accumualated_Total)
AS
(
	SELECT Dea.Continent, Dea.Location, Dea.Date, Dea.Population, Vac.New_Vaccinations
	,SUM(CONVERT(BIGINT,Vac.New_Vaccinations)) OVER (PARTITION BY Dea.Location ORDER BY Dea.Location, Dea.Date) AS Accumualated_Total
	FROM dbo.CovidDeaths AS Dea
	JOIN dbo.CovidVaccinations AS Vac
		ON Dea.location =  Vac.location
		AND Dea.date = Vac.date
	WHERE Dea.Continent IS NOT NULL
	--ORDER BY 2,3
)
SELECT *,(Accumualated_Total/Population)*100 AS Percentage_Vaccinated
FROM PopVsVac


-- Temp table to calculate percentage of people vaccinated
DROP TABLE IF EXISTS #PercentPopVaccinated
CREATE TABLE #PercentPopVaccinated
(
	Continent NVARCHAR(255),
	Location NVARCHAR(255),
	Date DATETIME,
	Population NUMERIC,
	New_Vaccinations NUMERIC,
	AccumulatedPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopVaccinated
	SELECT Dea.Continent, Dea.Location, Dea.Date, Dea.Population, Vac.New_Vaccinations,
	SUM(CAST(Vac.New_Vaccinations AS BIGINT)) OVER (PARTITION BY Dea.Location ORDER BY Dea.Location, Dea.Date) AS Accumulated_People_Vaccinated
	FROM dbo.CovidDeaths AS Dea
	JOIN dbo.CovidVaccinations AS Vac
		ON Dea.location =  Vac.location
		AND Dea.date = Vac.date
	WHERE Dea.Continent IS NOT NULL
	--ORDER BY 2,3

SELECT *, (AccumulatedPeopleVaccinated/Population)*100
FROM #PercentPopVaccinated


-- Create Views to visualize in Tableau 

DROP VIEW IF EXISTS dbo.Accumualated_Total

CREATE VIEW Accumualated_Total AS
SELECT Dea.Continent, Dea.Location, Dea.Date, Dea.Population, Vac.New_Vaccinations
,SUM(CONVERT(BIGINT,Vac.New_Vaccinations)) OVER (PARTITION BY Dea.Location ORDER BY Dea.Location, Dea.Date) 
AS Accumualated_Total
FROM dbo.CovidDeaths AS Dea
JOIN dbo.CovidVaccinations AS Vac
	ON Dea.location =  Vac.location
	AND Dea.date = Vac.date
WHERE Dea.Continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM Accumualated_Total