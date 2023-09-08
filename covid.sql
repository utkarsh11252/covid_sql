create database covid;
use covid;

select * from deaths;

select * from vaccinations;

#converting date column to datetime format
UPDATE deaths
SET date = STR_TO_DATE(date, '%m/%d/%Y');

UPDATE vaccinations
SET date_ = STR_TO_DATE(date_, '%m/%d/%Y');

# total cases vs total deaths
select location, total_cases, total_deaths , 
(total_deaths/total_cases)*100 as death_percentage 
from deaths
where location like '%India%' and continent != "";

# total deaths vs population
select location, population, total_cases, 
(total_cases/population)*100 as infected_percentage
from deaths
where location like '%India%' and continent != "";

# countries with highest infection rate
select location, 
max((total_cases/population)*100) as infected_percentage
from deaths
where continent != ""
group by location
order by infected_percentage desc;

# countries with highest death rate
select location, 
max((total_deaths/population)*100) as death_percentage
from deaths
where continent != ""
group by location
order by death_percentage desc;

# by continent
select continent, max(cast(total_deaths as double)) as death_count
from deaths
where continent != ""
group by continent
order by death_count desc;

# continent with highest death count per population
select continent, round(max(cast(total_deaths as double))/avg(population),3) as death_count_per_population
from deaths
where continent != ""
group by continent
order by death_count_per_population desc;

# global numbers
select  date, max(total_cases) as total_cases, max(cast(total_deaths as double)) as total_deaths,round(max(cast(total_deaths as double))/max(total_cases),3)
from deaths
group by date
order by date;


# population vs vaccinations (CTE)
with popvsvac(continent, location, date_, population, new_vaccinations, cum_sum) as(
select deaths.continent, deaths.location, date_, deaths.population as population, cast(vaccinations.new_vaccinations as double) as new_vaccinations,
sum(cast(vaccinations.new_vaccinations as double)) 
over (partition by deaths.location order by deaths.date, deaths.location) as cum_sum
from deaths join vaccinations on
deaths.location = vaccinations.location and
deaths.date = vaccinations.date_
where deaths.continent!="")
#order by 2,3;
select *, round((cum_sum/population)*100,2) as percentage_vaccinated from popvsvac;

# population vs vaccinations (temp table)
drop table if exists popvac;
create table popvac(
continent varchar(20),
location varchar(50),
date datetime,
population double,
new_vaccinations double,
cum_sum double);

insert into popvac(
select deaths.continent, deaths.location, date_, deaths.population as population, cast(vaccinations.new_vaccinations as double) as new_vaccinations,
sum(cast(vaccinations.new_vaccinations as double)) 
over (partition by deaths.location order by deaths.date, deaths.location) as cum_sum
from deaths join vaccinations on
deaths.location = vaccinations.location and
deaths.date = vaccinations.date_
where deaths.continent!="");
#order by 2,3;

select *,round((cum_sum/population)*100,2) as percentage_vaccinated from popvac;

# population vs vaccinations (view)
create view pop_vs_vac as(
select deaths.continent, deaths.location, date_, deaths.population as population, cast(vaccinations.new_vaccinations as double) as new_vaccinations,
sum(cast(vaccinations.new_vaccinations as double)) 
over (partition by deaths.location order by deaths.date, deaths.location) as cum_sum
from deaths join vaccinations on
deaths.location = vaccinations.location and
deaths.date = vaccinations.date_
where deaths.continent!="");
#order by 2,3;