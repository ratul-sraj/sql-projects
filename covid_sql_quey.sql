
-- taking a look at the data provided
select * from portfolioproject..coviddeaths$

-- looking at the death rate 
--the likelihood of death over time if you contract the virus in India
select location,tdate,total_cases,total_deaths,(total_deaths/total_cases)*100 as percentage_death 
from portfolioproject..coviddeaths$
where location like 'India'
order by location,tdate

--total cases vs population in india
select location,tdate,total_cases,population,(total_cases/population)*100 as percentage_of_infected_pop
from portfolioproject..coviddeaths$
where location like 'India'
order by location,tdate

-- where is the highest infection rate globally?
select location,population,max(total_cases) as highestinfectioncount,max((total_cases/population))*100 as percentage_of_infected_pop
from portfolioproject..coviddeaths$
group by location,population
order by percentage_of_infected_pop desc

-- where is the highest death count globally?
select location,max(cast(total_deaths as int)) as max_death_count
from portfolioproject..coviddeaths$
where continent is not null
group by location,continent
order by max_death_count desc

-- where is the highest death in continents?
select continent,max(cast(total_deaths as int)) as max_death_count
from portfolioproject..coviddeaths$
where continent is not null
group by continent
order by max_death_count desc

--global numbers 
select sum(new_cases) as sum_cases,sum(cast(new_deaths as int)) as sum_deaths,(sum(cast(new_deaths as bigint))/sum(new_cases))*100 as death_rate
from portfolioproject..coviddeaths$
where continent is not null
order by 1

-- global population and vaccinations
with popvsvacc (continent,location,date,population,new_vaccinations,rolling_vaccine_count) as	
(
select dea.continent,dea.location,dea.tdate,dea.population,vacc.new_vaccinations,
sum(cast(vacc.new_vaccinations as bigint)) over (partition by dea.location order by dea.location,dea.tdate) as rolling_vaccine_count
from portfolioproject..coviddeaths$ dea
join  portfolioproject..coviddvaccinations$ vacc
on dea.location =  vacc.location
and dea.tdate = vacc.tdate
where dea.continent is not null
--order by  dea.location,dea.tdate
)

---- using cte to get population vs vaccination as rolling percentage.
select *,(rolling_vaccine_count/population)*100 as vaccination_with_resp_to_to_population from popvsvacc
order by  popvsvacc.location,popvsvacc.date

-- temporary table for vaccine proportion

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #vaccinate_temp_table
Create Table #vaccinate_temp_table
(
Continent nvarchar(255),
Location nvarchar(255),
tdate datetime,
Population numeric,
New_vaccinations bigint,
RollingPeopleVaccinated numeric
)
Insert into #vaccinate_temp_table
Select dea.continent, dea.location, dea.tdate, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.tDate) as rolling_people_vaccinated
From PortfolioProject..coviddeaths$ dea
Join PortfolioProject..coviddvaccinations$ vac
	On dea.location = vac.location
	and dea.tdate = vac.tdate
where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as Num_vaccines_givenout_with_respect_to_pop
From #vaccinate_temp_table
order by 2,3

-- creating a view for later analysis

create view Numvaccinesgivenoutwithrespecttopop as
Select dea.continent, dea.location, dea.tdate, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.tdate) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..coviddeaths$ dea
Join PortfolioProject..coviddvaccinations$ vac
	On dea.location = vac.location
	and dea.tdate = vac.tdate
where dea.continent is not null 