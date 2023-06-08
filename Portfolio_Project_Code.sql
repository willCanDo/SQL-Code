SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM main.CovidDeaths ORDER BY 1,2;

--Looking at Total Cases vs Total Deaths 
--The percentage of people who actually die vs those who get infected
-- In the U.S.
SELECT location, date, total_cases, total_deaths, ROUND(CAST(total_deaths  AS REAL) /  total_cases, 5)  * 100  AS Death_Percentage
FROM main.CovidDeaths WHERE location like '%states' ORDER BY 1,2;

--In South Korea
SELECT location, date, total_cases, total_deaths, ROUND(CAST(total_deaths  AS REAL) /  total_cases, 5)  * 100  AS Death_Percentage
FROM main.CovidDeaths WHERE location = "Afghanistan" AND date = '2023/05/01';

--Total cases vs popluation
--Shows what percentage of population contracted covid in South Korea

SELECT location, date, population, total_cases, ROUND(CAST(total_cases  AS REAL) /  population, 5)  * 100  AS Death_Percentage
FROM main.CovidDeaths WHERE location = "South Korea";

--Looking at Countries with the Highest Infection Rate compared to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(ROUND(CAST(total_cases  AS REAL) /  population, 5))  * 100  AS PercentPopulationInfected
FROM main.CovidDeaths GROUP BY location, population ORDER BY PercentPopulationInfected DESC

--Showing the countries with the Highest Death Count per Population

SELECT location, MAX(total_deaths) as TotalDeathCount
FROM main.CovidDeaths GROUP BY location ORDER BY TotalDeathCount DESC

--The above code had to be changed to the below code because of a problem with the data type
--The data type is a varchar and it needed to be converted to an int

SELECT location, MAX(CAST(total_deaths as INT)) as TotalDeathCount
FROM main.CovidDeaths WHERE continent is NOT NULL GROUP BY location ORDER BY TotalDeathCount DESC

--Breakdown by continent but the numbers are not entirely accurate

SELECT continent, MAX(CAST(total_deaths as INT)) as TotalDeathCount
FROM main.CovidDeaths WHERE continent is NOT NULL GROUP BY continent ORDER BY TotalDeathCount DESC

--This is correct code to get the most accurate data
SELECT location, MAX(CAST(total_deaths as INT)) as TotalDeathCount
FROM main.CovidDeaths WHERE continent is NULL GROUP BY location ORDER BY TotalDeathCount DESC

--Showing the continents with the highest death counts

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM main.CovidDeaths WHERE continent IS NOT NULL GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global Numbers (with the help from chatgpt)

SELECT
  date,
  SUM(new_cases) AS total_cases,
  SUM(CAST(new_deaths AS INT)) as total_deaths,
  (SUM(CAST(new_deaths AS FLOAT)) / SUM(new_cases)) * 100 AS Death_Percentage
FROM
  main.CovidDeaths
WHERE
  continent IS NOT NULL
GROUP BY
  date
ORDER BY
  date;

  --Removing the date to get the total number of cases 

  SELECT
  SUM(new_cases) AS total_cases,
  SUM(CAST(new_deaths AS INT)) as total_deaths,
  (SUM(CAST(new_deaths AS FLOAT)) / SUM(new_cases)) * 100 AS Death_Percentage
FROM
  main.CovidDeaths
WHERE
  continent IS NOT NULL
--GROUP BY date
ORDER BY
  date;

--Joining the two tables together 
--Looking at total population vs vaccinations 

  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations FROM main.CovidDeaths dea
  Join main.CovidVaccinations vac 
  ON dea.location = vac.location 
  AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
  Order BY 1,2,3



--Using the OVER + Partition BY keywords
--CONVERT function doesn't work in sqlite
--the OVER clause defines a window or user-specified set of rows within a query result set
--Still looking at total population vs vaccinations 

  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS INT)) 
  OVER(Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
  --(RollingPeopleVaccinated/popluation)
  FROM main.CovidDeaths dea
  Join main.CovidVaccinations vac 
  ON dea.location = vac.location 
  AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
  Order BY 1,2,3

  --USE CTE
  With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
  AS
(
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS INT)) 
  OVER(Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  --(RollingPeopleVaccinated/popluation)
  FROM main.CovidDeaths dea
  Join main.CovidVaccinations vac 
  ON dea.location = vac.location 
  AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
  --Order BY 1,2,3
)

Select * , (RollingPeopleVaccinated/ population) * 100 FROM PopvsVac


-- Creating View to store data for later visualizations
--This will work but the results will be displayed in a different location 

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From main.CovidDeaths dea
Join main.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


