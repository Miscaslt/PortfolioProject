select *
from PortfolioProject.dbo.coviddeaths
WHERE continent is not null
order by 3,4


select *
from PortfolioProject.dbo.CovidVaccinations
order by 3,4

--select data we wil use
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases)/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
-- Where location like '%states%'
group by location, population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population
Select Location, MAX(cast(total_deaths as int)) as HighestDeathCount
From PortfolioProject..CovidDeaths
-- Where location like '%states%'
Where continent is not null
group by location
order by HighestDeathCount desc

-- BY CONTINENT

-- Countries with Highest Death Count per Population
Select continent, MAX(cast(total_deaths as int)) as HighestDeathCount
From PortfolioProject..CovidDeaths
-- Where location like '%states%'
Where continent is null
group by continent
order by HighestDeathCount desc

-- global numbers

Select  date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases) *100 as DeathPercentage
From PortfolioProject..CovidDeaths
-- Where location like '%states%'
where continent is not null
group by date
order by 1,2

-- global cases over all dates
Select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases) *100 as DeathPercentage
From PortfolioProject..CovidDeaths
-- Where location like '%states%'
where continent is not null
--group by date
order by 1,2


-- looking at total population vs vaccination
Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_number_vaccinations
-- we want (rolling_number_vaccinations/population)*100. to do this we'll use CTE or temp table
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- use CTE
with Pop_Vs_Vac (Continent, Location, Date, Population,new_vaccinations, rolling_number_vaccinations)
as
(
Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_number_vaccinations
-- (rolling_number_vaccinations/population)*100
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

Select *, (rolling_number_vaccinations/Population)*100
From Pop_Vs_Vac


--use TEMP TABLE
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255), location nvarchar(255), date datetime, population numeric, new_vaccinations numeric, rolling_number_vaccinations numeric)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_number_vaccinations
-- this will allow us to calculate (rolling_number_vaccinations/population)*100
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3


Select *, (rolling_number_vaccinations/Population)*100
From #PercentPopulationVaccinated


-- looking at total population vs tests
Select dea.continent, dea.location, dea.date, population, vac.new_tests
,SUM(cast(vac.new_tests as int)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_number_tests
-- (rolling_number_new_tests/population)*100
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- use CTE
with Pop_Vs_Test (Continent, Location, Date, Population,new_tests, rolling_number_tests)
as
(
Select dea.continent, dea.location, dea.date, population, vac.new_tests
,SUM(cast(vac.new_tests as int)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_number_tests
-- (rolling_number_vaccinations/population)*100
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

Select *, (rolling_number_tests/Population)*100 as RollingPercentTests
From Pop_Vs_Test

--Creating view to store data for later visualisation

Create view PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as rolling_number_vaccinations
-- (rolling_number_vaccinations/population)*100
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *
from PercentPopulationVaccinated