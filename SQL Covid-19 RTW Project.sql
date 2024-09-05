-- At this stage, there are two Tables saved in the database.
-- Both Tables come from the CDC's COVID-19 data sets taht are available to the public.
-- The intention of this project is to demonstrate some simple to intermediate SQL skills

-- Checking tables to make sure they are saved/labelled correctly.
Select * 
From portfolio_db.covid_deaths
order by 3,4
;
-- Select * 
-- From portfolio_db.covid_vaccine
-- order by 3,4
-- ;

-- Selecting the data from the Tables for analysis
Select location, date, total_cases, new_cases, total_deaths, population
From portfolio_db.covid_deaths
order by 1,2
;

-- 1) Key Business Question: What is the death rate for new cases in the US?
-- 		This will yield the liklihood of dying from COVID if contracted within a specified country 
-- 		by a specified date, not controlling for other demographic factors.
Select location, date, total_cases, total_deaths, 
	(total_deaths/total_cases)*100 as death_rate_per_case
From portfolio_db.covid_deaths
Where location like '%states%' AND continent is not null
order by 1,2
;

-- 2) Key Business Quesiton: What percentage of the overall US population contracted COVID?
-- 		This will yield the percentage of those reproted to be infected within a specified nation.
Select location, date, total_cases, population, 
	(total_cases/population)*100 as cases_wtin_population
From portfolio_db.covid_deaths
Where location like '%states%' AND continent is not null
order by 1,2
;

-- 3) What countries have the highest reported infection rates compareed to the population?
Select location, population,
	MAX(total_cases) as max_infected, 
	MAX((total_cases/population))*100 as cases_wtin_population
From portfolio_db.covid_deaths
Where continent is not null
group by location, population
order by 4 desc
;

-- 4) What countries have the highest reported death counts compareed to the population?
Select location, population,
	MAX(total_deaths) as max_deaths, 
	MAX((total_deaths/population))*100 as deaths_wtin_population
From portfolio_db.covid_deaths
Where continent is not null
group by location, population
order by 4 desc
;

-- 5) Could you pull some global statistics please?
Select SUM(new_cases) as agg_new_cases, 
		SUM(CAST(new_deaths as SIGNED)) as agg_new_deaths,
		SUM(CAST(new_deaths as SIGNED))/SUM(new_cases)*100 as agg_death_rate
from portfolio_db.covid_deaths
where continent is not null
-- Group By date
order by 1,2
;

-- Merging the two tables
-- how many people globally have been vaccinated?
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vac_freq
From portfolio_db.covid_deaths dea
Join portfolio_db.covid_vaccine vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
order by 2,3
;

-- USE CTE
With VacPop (continent, location, date, population, new_vaccinations, rolling_vac_freq)
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vac_freq
From portfolio_db.covid_deaths dea
Join portfolio_db.covid_vaccine vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
-- order by 2,3
)
Select *, (rolling_vac_freq/population)*100
From VacPop
;

-- Temp Table
DROP Table if exists vaxed_population
Create Table vaxed_population
(
continent nvarchar(255),
location nvarchar(255),
date datetime, 
population numeric, 
new_vaccinations numeric,
rolling_vac_freq numeric
)
;
Insert into vaxed_population
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vac_freq
From portfolio_db.covid_deaths dea
Join portfolio_db.covid_vaccine vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
-- order by 2,3
;
Select *, (rolling_vac_freq/population)*100
from vaxed_population
;
-- Viz Views
Create View vaxed_population_vw as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vac_freq
From portfolio_db.covid_deaths dea
Join portfolio_db.covid_vaccine vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
-- order by 2,3 


