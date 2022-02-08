-- taking a look at the data 
select * from portfolioproject..nashville_housing

-----------------------------------------
-- 1 standardizing Sale date

select SaleDate from portfolioproject..nashville_housing

alter table nashville_housing
add StandardizedSaleDate date

update nashville_housing
set StandardizedSaleDate = cast(SaleDate as date)

-- result:-
select cast(SaleDate as date) ,StandardizedSaleDate from nashville_housing


-----------------------------------------
-- 2 Populating Property address

-- finding null property values
select * from portfolioproject..nashville_housing
where PropertyAddress is null
-- finding same parcel ID and using them to populate property address
select initial.ParcelID,initial.PropertyAddress,same.ParcelID,same.PropertyAddress ,ISNULL(initial.PropertyAddress,same.PropertyAddress) as missing_prop_add
from portfolioproject..nashville_housing initial
join portfolioproject..nashville_housing same
	on initial.ParcelID = same.ParcelID
	and initial.[UniqueID ]  <> same.[UniqueID ]
where initial.PropertyAddress is null

update initial
set PropertyAddress = ISNULL(initial.PropertyAddress,same.PropertyAddress)
from portfolioproject..nashville_housing initial
join portfolioproject..nashville_housing same
	on initial.ParcelID = same.ParcelID
	and initial.[UniqueID ]  <> same.[UniqueID ]
where initial.PropertyAddress is null


--result:-
--nulls in property address are eliminated.
select * from portfolioproject..nashville_housing
where PropertyAddress is null

-----------------------------------------
-- 4 Property address broken out into different columns
select PropertyAddress from portfolioproject..nashville_housing

select 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as town 
from portfolioproject..nashville_housing

ALTER TABLE portfolioproject..nashville_housing
ADD PropertSplitAddress VARCHAR (255)

update portfolioproject..nashville_housing
set PropertSplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) 

ALTER TABLE portfolioproject..nashville_housing
ADD PropertSplitCity VARCHAR (255)

update portfolioproject..nashville_housing
set PropertSplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) 

select PropertSplitAddress,PropertSplitCity,PropertyAddress from portfolioproject..nashville_housing

-- splitting up the owner address
select 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
from portfolioproject..nashville_housing

ALTER TABLE portfolioproject..nashville_housing
ADD OwnerSplitAddress VARCHAR (255),OwnerSplitCity VARCHAR (255),OwnerSplitState VARCHAR (255)

update portfolioproject..nashville_housing
set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

update portfolioproject..nashville_housing
set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

update portfolioproject..nashville_housing
set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-- result:- the address has been split into mmultiple columns forneasier access..
select 
PropertyAddress,PropertSplitAddress,PropertSplitCity,OwnerAddress,OwnerSplitAddress,OwnerSplitCity,OwnerSplitState 
from portfolioproject..nashville_housing


-- changing y and n with yes and no.

select 
distinct(SoldAsVacant),count(SoldAsVacant) 
from portfolioproject..nashville_housing
group by SoldAsVacant
order by 2

select SoldAsVacant
	,case when SoldAsVacant = 'Y' THEN 'Yes'
	 when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 End
from portfolioproject..nashville_housing

Update portfolioproject..nashville_housing
set SoldAsVacant = case when SoldAsVacant = 'Y' THEN 'Yes'
	 when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 End

-- result:- all rows upadted with yes and no
select 
distinct(SoldAsVacant),count(SoldAsVacant) 
from portfolioproject..nashville_housing
group by SoldAsVacant
order by 2


-- removing all duplicates 
select * from portfolioproject..nashville_housing

with RowNumCTE as (
select *,
	ROW_NUMBER() over (
	partition by  ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					Order by UniqueID) row_num
from portfolioproject..nashville_housing
)

select * from RowNumCTE
where row_num > '1'

Delete 
from RowNumCTE
where row_num > '1'

--Deleting columns that seem less usefull for our puposes.
Alter table portfolioproject..nashville_housing
drop column TaxDistrict,OwnerAddress,PropertyAddress

Alter table portfolioproject..nashville_housing
drop column SaleDate

select *  from portfolioproject..nashville_housing