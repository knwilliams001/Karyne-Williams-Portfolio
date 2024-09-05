-- At this stage, there are two Tables saved in the database.
-- Both Tables come from the CDC's COVID-19 data sets that are available to the public.

-- Checking tables to make sure they are saved/labelled correctly.
Select * 
From portfolio_db.covid_deaths
order by 3,4
;
Select * 
From portfolio_db.covid_vaccine
order by 3,4
;

-- Selecting the data from the Tables for analysis
Select location, date, total_cases, new_cases, total_deaths, population
From portfolio_db.covid_deaths
Where continent is not null -- (will exclude regions, continents, and global aggriagtor variable)
order by 1,2
;

-- 1) Key Business Question (KBQ): What is the death rate for new cases in the US?

Select location, date, total_cases, total_deaths, 
	(total_deaths/total_cases)*100 as death_rate_per_case
From portfolio_db.covid_deaths
Where location like '%states%' AND continent is not null
order by 1,2
;

-- 2) KBQ: What percentage of the overall US population contracted COVID?

Select location, date, total_cases, population, 
	(total_cases/population)*100 as cases_wtin_population
From portfolio_db.covid_deaths
Where location like '%states%' AND continent is not null
order by 1,2
;

-- 3) KBQ: What countries have the highest reported infection rates compareed to the population?

Select location, population,
	MAX(total_cases) as max_infected, 
	MAX((total_cases/population))*100 as cases_wtin_population
From portfolio_db.covid_deaths
Where continent is not null
group by location, population
order by 4 desc
;

-- 4) KBQ: What countries have the highest percentage of reported death counts compareed to the population?

Select location, population,
	MAX(total_deaths) as max_deaths, 
	MAX((total_deaths/population))*100 as deaths_wtin_population
From portfolio_db.covid_deaths
Where continent is not null
group by location, population
order by 4 desc
;

-- 5) KBQ: What countries have the highest percentage of reported death counts within those infected?

Select location, population,
	MAX(total_deaths) as max_deaths,
    MAX(total_cases) as max_cases,
	(MAX(total_deaths)/MAX(total_cases))*100 as deaths_wtin_infected
From portfolio_db.covid_deaths
Where continent is not null
group by location, population
order by 5 desc
;

-- 6) What is the overall global reported death rate for those who contracted COVID-19?

Select SUM(new_cases) as agg_new_cases, 
		SUM(CAST(new_deaths as SIGNED)) as agg_new_deaths,
		SUM(CAST(new_deaths as SIGNED))/SUM(new_cases)*100 as agg_death_rate
from portfolio_db.covid_deaths
where continent is not null
-- Group By date
order by 1,2
;

-- Merging two tables for combined analysis
-- Getting a rolling total
-- 7) KBQ: How many people in the US have been vaccinated, and what is the rolling frequency up to that date?

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vac_freq
From portfolio_db.covid_deaths dea
Join portfolio_db.covid_vaccine vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.location like '%states%' and dea.continent is not null
order by 3
;

-- Common Table Expressions (CTEs)
-- KBQ: What is the rolling total frequency of new vaccinations by nation, and also show the percentage of those vaccinated by nation.

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

-- Using a Temp Table
DROP Table if exists vaxed_population
;
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
;

Select *, (rolling_vac_freq/population)*100
from vaxed_population
;

-- Creating Viz Views for later visualization in Tableau
Create View vaxed_population_vw as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vac_freq
From portfolio_db.covid_deaths dea
Join portfolio_db.covid_vaccine vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null





