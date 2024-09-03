select *
from PortfolioProject.dbo.CovidDeaths
where continent is not null
order by 3, 4


--select *
--from PortfolioProject.dbo.CovidVaccination
--order by 3, 4

-- Select the data we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject.dbo.CovidDeaths
where continent is not null
order by 1,2


--lets calculate total_cases vs total_deaths
-- Likelihood of dying if you contract Covid in Nigeria

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths
where total_cases != 0 and total_deaths != 0 and location = 'Nigeria' and continent is not null
order by 1,2


--population of Nigeria that got Covid
select location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
where location = 'Nigeria' and continent is not null
order by 1,2


--Countries with the highest infection rate compared to population

select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
where continent is not null
group by location, population
order by 4 desc


--highest death count for every country

select location, MAX(total_deaths) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc


--Lets group it by Continent

select continent, MAX(total_deaths) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc


--GLOBAL NUMBERS
-- Global death rate per day
select date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/ SUM(new_cases))*100 as GlobalDeathPercentage
from PortfolioProject.dbo.CovidDeaths
where continent is not null and new_deaths != 0 and new_cases != 0
group by date
order by 1,2


--overall global death rate
select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/ SUM(new_cases))*100 as GlobalDeathPercentage
from PortfolioProject.dbo.CovidDeaths
where continent is not null and new_deaths != 0 and new_cases != 0
order by 1,2


select *
from PortfolioProject.dbo.CovidDeaths
join PortfolioProject.dbo.CovidVaccination
ON PortfolioProject.dbo.CovidDeaths.date = PortfolioProject.dbo.CovidVaccination.date
and PortfolioProject.dbo.CovidDeaths.location = PortfolioProject.dbo.CovidVaccination.location


--total population vs vacination

select dea.continent, dea.date, dea.location, dea.population, CAST(vac.new_vaccinations as float) AS new_vaccination,
-- Rolling sum of new vaccinations by location
SUM(CAST(vac.new_vaccinations as float)) OVER 
(partition by dea.location 
order by dea.location, dea.date
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Rolling_total_vaccination
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccination vac
ON dea.date = vac.date
and dea.location = vac.location
where dea.continent is not null
order by 3,2

--to work with the Rolling_total_vaccination column, i will use CTE

WITH PopvsVac (continent, date, location, population, new_vaccinations, Rolling_total_vaccination)
as
(
select dea.continent, dea.date, dea.location, dea.population, CAST(vac.new_vaccinations as float) AS new_vaccination,
-- Rolling sum of new vaccinations by location
SUM(CAST(vac.new_vaccinations as float)) OVER 
(partition by dea.location 
order by dea.location, dea.date
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Rolling_total_vaccination
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccination vac
ON dea.date = vac.date
and dea.location = vac.location
where dea.continent is not null
)

select *, (Rolling_total_vaccination/population)*100 as vaccinated_population_percentage
from PopvsVac



-- i can also achieve the above by using a TEMP TABLE
drop table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
Date datetime,
location nvarchar(255),
population numeric,
new_vaccinations numeric,
Rolling_total_vaccination numeric)



insert into #PercentPopulationVaccinated
select dea.continent, dea.date, dea.location, dea.population, CAST(vac.new_vaccinations as float) AS new_vaccination,
-- Rolling sum of new vaccinations by location
SUM(CAST(vac.new_vaccinations as float)) OVER 
(partition by dea.location 
order by dea.location, dea.date
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Rolling_total_vaccination
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccination vac
ON dea.date = vac.date
and dea.location = vac.location
where dea.continent is not null
order by 3,2

select *, (Rolling_total_vaccination/population)*100 as vaccinated_population_percentage
from #PercentPopulationVaccinated


--Creating view to store data for later visualization


CREATE View CasesvsDeaths As
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths
where total_cases != 0 and total_deaths != 0 and location = 'Nigeria' and continent is not null

CREATE View NigeriaCovidPopulation As
select location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
where location = 'Nigeria' and continent is not null

CREATE View InfectioRatePerCountry As
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
where continent is not null
group by location, population


CREATE View DeathCountPerCountry As
select location, MAX(total_deaths) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is not null
group by location


CREATE View DeathCountPerContinent As
select continent, MAX(total_deaths) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is not null
group by continent


CREATE View GlobalDeathRatePerDay As
select date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/ SUM(new_cases))*100 as GlobalDeathPercentage
from PortfolioProject.dbo.CovidDeaths
where continent is not null and new_deaths != 0 and new_cases != 0
group by date

CREATE View GlobalDeathRate As
select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/ SUM(new_cases))*100 as GlobalDeathPercentage
from PortfolioProject.dbo.CovidDeaths
where continent is not null and new_deaths != 0 and new_cases != 0


CREATE View RollingSumOfNewVaccination As
select dea.continent, dea.date, dea.location, dea.population, CAST(vac.new_vaccinations as float) AS new_vaccination,
-- Rolling sum of new vaccinations by location
SUM(CAST(vac.new_vaccinations as float)) OVER 
(partition by dea.location 
order by dea.location, dea.date
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Rolling_total_vaccination
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccination vac
ON dea.date = vac.date
and dea.location = vac.location
where dea.continent is not null


CREATE View VaccinatedPopulationPercentage As
WITH PopvsVac (continent, date, location, population, new_vaccinations, Rolling_total_vaccination)
as
(
select dea.continent, dea.date, dea.location, dea.population, CAST(vac.new_vaccinations as float) AS new_vaccination,
-- Rolling sum of new vaccinations by location
SUM(CAST(vac.new_vaccinations as float)) OVER 
(partition by dea.location 
order by dea.location, dea.date
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS Rolling_total_vaccination
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccination vac
ON dea.date = vac.date
and dea.location = vac.location
where dea.continent is not null
)

select *, (Rolling_total_vaccination/population)*100 as vaccinated_population_percentage
from PopvsVac