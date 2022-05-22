 

SELECT TOP 10
FROM portfolioproject..housing_data

--Fixing up the SaleDate (Does not work with just an UPDATE, made a new column and added a new one, removing old one.

ALTER TABLE portfolioproject..housing_data
ADD Sale_Date DATE;

UPDATE housing_data
SET Sale_Date = CONVERT(DATE,SaleDate);

ALTER TABLE portfolioproject..housing_data
DROP COLUMN SaleDate;

Select Sale_Date
FROM portfolioproject..housing_data;

-- Property adress are missing, how should we do with it ?

SELECT ParcelID, PropertyAddress
FROM housing_data
WHERE PropertyAddress IS NULL ;

SELECT ParcelID, COUNT(ParcelID)
FROM housing_data
GROUP BY ParcelID
HAVING COUNT(ParcelID) > 1

-- From the above query we can see that there are duplicate ParcelId's, but only 30 with missing adress.
-- Make a assumption that 1 parcel id is for 1 adress. With this we can populate the adress where parcel id's are duplicate.
-- If the assumption turns out to be wrong, we can change the empty colums to what ever we want such as "No adress"
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM housing_data AS a
JOIN housing_data AS b
On a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- We are setting property adress rows with the same table on where parcel id are the same but unique id are different 
-- specifeclly setting rows where adress is null. Let's check if it worked

SELECT PropertyAddress
from housing_data
WHERE PropertyAddress is NULL


SELECT PropertyAddress
FROM housing_data
-- We can see that property adress includes street name and city, let's separate it into two different columns

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1), -- Adding the -1 to remove the comma, as CHARINDEX is return the position of ',' as a string, but we want to remove that so -1 does the trick
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) -- With this command: Were searching the position of ',' and were ending at the end of total length of characters with LEN() command, giving us the last position for SUBSTING()

FROM housing_data

-- Let's add the two new columns
ALTER TABLE housing_data
ADD Address NVARCHAR(255)

UPDATE housing_data
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

ALTER TABLE housing_data
ADD City NVARCHAR(255)

UPDATE housing_data
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));

SELECT City, Address
FROM housing_data

-- Let's drop the propertyadress table
ALTER TABLE housing_data
DROP COLUMN PropertyAddress
-- We can move the columns to a better position with object explored design option, but it's not advised as it can conflict with previous code.
Select * FROM housing_data 

-- Looks like OwenerAdress has the same problem, with an extra state in the whole adress
--We can use REPLACE() to replace the commas with dots, and can request PARSENAME 1,2,3 to retrieve every name after the dot. PARSENAME works backwards. PARSENAME(object,1) retrieves the last name.
SELECT PARSENAME(REPLACE(OwnerAddress, ',','.'),3 ) AS OwnerStreetAdress, -- PARSENAME returns us the object name after every dot(.), 
		PARSENAME(REPLACE(OwnerAddress, ',','.'),2 ) AS OwnerCity,
		PARSENAME(REPLACE(OwnerAddress, ',','.'),1 ) AS OwnerState
 
FROM housing_data;

-- Create new columns for seperated owner adress

ALTER TABLE portfolioproject..housing_data
ADD OwnerStreetAdress NVARCHAR(255);

UPDATE portfolioproject..housing_data
SET OwnerStreetAdress = PARSENAME(REPLACE(OwnerAddress, ',','.'),3 )

ALTER TABLE portfolioproject..housing_data
ADD OwnerCity NVARCHAR(255)

UPDATE portfolioproject..housing_data
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2 )

ALTER TABLE portfolioproject..housing_data
ADD OwnerState NVARCHAR(255)

UPDATE portfolioproject..housing_data
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1 )

SELECT OwnerStreetAdress, OwnerCity,OwnerState
FROM portfolioproject..housing_data


-- We can change SoldAsVacant to true or false rather then yes or no. The change can help us to compute with this column later on.

SELECT SoldAsVacant
FROM portfolioproject..housing_data

ALTER TABLE portfolioproject..housing_data
ADD SoldAsVacantBit BIT DEFAULT 'FALSE';

SELECT SoldAsVacant,SoldAsVacantBit
FROM portfolioproject..housing_data

UPDATE portfolioproject..housing_data
SET SoldAsVacantBit = CASE WHEN SoldAsVacant = 'Yes' OR SoldAsVacant ='Y' THEN 'TRUE' ELSE 'FALSE' END

-- Let's check for Duplicates
With RownumbCheck AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, SalePrice, LegalReference, Sale_Date, Address ORDER BY ParcelID) AS RowNumb 
FROM portfolioproject..housing_data
)
SELECT RowNumb
FROM RownumbCheck
WHERE RowNumb > 1

-- Identified 104 duplicate rows. Let's create another table without duplicate rows. Keep the orginal in tact.

USE portfolioproject
GO
CREATE VIEW NoDuplicates AS 
SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, SalePrice, LegalReference, Sale_Date, Address ORDER BY ParcelID) AS RowNumb 
FROM portfolioproject..housing_data

DELETE
FROM portfolioproject..NoDuplicates WHERE RowNumb > 1;

