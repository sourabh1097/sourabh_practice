Create DataBase RailwayInfo;   --- Creating a Database 'RailwayInfo'

Use RailwayInfo;   ---Using the same Database.

Create Table Railway  -- Creating a Table 'Railway' for the bulk insertion in this table
(
 TransactionID NVARCHAR(255),  --Nvarchar as it contain special symbol
    DateofPurchase NVARCHAR(255),
    TimeofPurchase TIME,
    PurchaseType VARCHAR(20),
    PaymentMethod VARCHAR(20),
    Railcard VARCHAR(30),
    TicketClass VARCHAR(20),
    TicketType VARCHAR(30),
    Price NVARCHAR(10),
    DepartureStation VARCHAR(80),
    ArrivalDestination VARCHAR(60),
    DateofJourney NVARCHAR(40),
    DepartureTime NVARCHAR(40),
    ArrivalTime TIME,
    ActualArrivalTime NVARCHAR(40),
    JourneyStatus VARCHAR(20),
    ReasonforDelay VARCHAR(40),
    RefundRequest VARCHAR(4)
);



BULK INSERT railway   ---using bulk insertion 
FROM 'C:\Users\Sourabh\Downloads\railway.csv'  ---for inserting from csv file
WITH (
    FIELDTERMINATOR = ',', --- to separate the field based on delimiter in this case ','.
    ROWTERMINATOR = '\n',  --- to separate the row 
    FIRSTROW = 2,          --- as the first row is header
    KEEPNULLS              --- to keep null values
);

Select * from Railway;-- to fetch all the data from Railway table


-- Cleaning the table using function
--Date of Purchase
CREATE FUNCTION dbo.RW0546 (@DateofPurchase NVARCHAR(255))    ---Creating a function
RETURNS DATE                                                  ---returns a Datatype Date
AS
BEGIN
    DECLARE @Result DATE;                                      ---Declaring variable with Datatype
    DECLARE @CleanedDate NVARCHAR(255);                        ---Declaring variable with Datatype
    
    SET @CleanedDate = REPLACE(@DateofPurchase, '%', '-');  --- Replace '%' with '-' and handle common date formats

    SET @Result = TRY_CONVERT(DATE, @CleanedDate);   --- Trying to convert directly

    --- As direct conversion fails, handling specific formats
    IF @Result IS NULL
    BEGIN
	      
        SET @Result = TRY_CONVERT(DATE, @CleanedDate, 105); --- 105 is the style for 'dd-mm-yyyy'

        IF @Result IS NULL
            SET @Result = TRY_CONVERT(DATE, @CleanedDate, 23); --- 23 is the style for 'yyyy-mm-dd'
    END

    RETURN @Result;
END;



--Price
CREATE FUNCTION RW0547(@Price AS NVARCHAR(10))
RETURNS INT
AS
BEGIN 
     DECLARE @Result INT; 
	 
	 --Using Case as to handle error.
	 SET @Result = CASE                                                
		             WHEN ISNUMERIC(@Price)=1 THEN CAST(@Price as INT) -- Trying to Convert based on Values
				     ELSE NULL
				   END;

	 Return @Result;
  End;

-- Creating Function to clean DateofJourney
CREATE FUNCTION RW0548(@DateofJourney NVARCHAR(40))
RETURNS DATE
AS
BEGIN 
	DECLARE @Result DATE;
	
	SET @Result= TRY_CONVERT(DATE,@DateofJourney);  --Trying to convert directly.

	---As direct conversion fails, handling specific format.
	IF @Result IS NULL
	BEGIN 
	    
		SET @Result = TRY_CONVERT(DATE,@DateofJourney,105); -- 105 is the style for 'dd-mm-yyyy'
	END

RETURN @Result;
END;

--Creating a Function to clean Departure Time
CREATE FUNCTION RW0549(@DepartureTime NVarChar(40))
RETURNS TIME                                           
AS 
BEGIN
   DECLARE @Result TIME;

   SET @Result = TRY_CONVERT(TIME,@DepartureTime);     ---Converting Departure Time from NVarchar to Varchar

RETURN @Result;
END;

--Creating a Function to clean Actual Arrival Time
CREATE FUNCTION RW0550(@ActualArrivalTime NVarChar(40))
RETURNS TIME                                           
AS 
BEGIN
   DECLARE @Result TIME;

   SET @Result = TRY_CONVERT(TIME,@ActualArrivalTime);     ---Converting Actual Arrival Time from NVarchar to Varchar

RETURN @Result;
END;

--- Creating a New Table for Clean Data
Create Table Railway_New  
(
 TransactionID NVARCHAR(255),  
    DateofPurchase DATE,
    TimeofPurchase TIME,
    PurchaseType VARCHAR(20),
    PaymentMethod VARCHAR(20),
    Railcard VARCHAR(30),
    TicketClass VARCHAR(20),
    TicketType VARCHAR(30),
    Price INT,
    DepartureStation VARCHAR(80),
    ArrivalDestination VARCHAR(60),
    DateofJourney DATE,
    DepartureTime TIME,
    ArrivalTime TIME,
    ActualArrivalTime TIME,
    JourneyStatus VARCHAR(20),
    ReasonforDelay VARCHAR(40),
    RefundRequest VARCHAR(4)
);
--- Inserting the values into it.
INSERT INTO Railway_New 
(
    TransactionID,  
    DateofPurchase,
    TimeofPurchase,
    PurchaseType,
    PaymentMethod,
    Railcard,
    TicketClass,
    TicketType,
    Price,
    DepartureStation,
    ArrivalDestination,
    DateofJourney,
    DepartureTime,
    ArrivalTime,
    ActualArrivalTime,
    JourneyStatus,
    ReasonforDelay,
    RefundRequest
)
SELECT 
                  TransactionID,
                  dbo.RW0546(DateofPurchase),
                  TimeofPurchase,
                  PurchaseType,
                  PaymentMethod,
                  Railcard,
                  TicketClass,
                  TicketType,
                  dbo.RW0547(Price),
                  DepartureStation,
                  ArrivalDestination,
                  dbo.RW0548(DateofJourney),
                  dbo.RW0549(DepartureTime),
                  ArrivalTime,
                  dbo.RW0550(ActualArrivalTime),
                  JourneyStatus,
                  ReasonforDelay,
                  RefundRequest

FROM Railway;

DROP TABLE Railway; ---- Dropping the old table

EXEC sp_rename 'Railway_New', 'Railway';  --- Renaming the new table

---After Cleaning and preprocessing, Retriving all the Data
Select * from Railway;


---Identify Peak Purchase Time and Their Impact on Delays
SELECT TimeofPurchase,COUNT(TransactionID) As 'TransactionCount',JourneyStatus 
FROM Railway
GROUP BY TimeofPurchase,JourneyStatus
ORDER BY TransactionCount DESC;


--Analyze Journey pattern of Frequent Travelers
SELECT DepartureStation, ArrivalDestination, COUNT(TransactionID) As 'TransactionCount'
FROM Railway
GROUP BY DepartureStation, ArrivalDestination
HAVING COUNT(TransactionID)> 3
ORDER BY TransactionCount DESC;

--Revenue Loss Due to Delay with Refund Request
SELECT SUM(Price)
FROM Railway
WHERE RefundRequest = 'Yes' AND JourneyStatus = 'Delayed';

--Impact of Railcards on Ticket Prices and Journey Delays.
Select Railcard, AVG(Price) as 'AveragePrice', 
       CAST(SUM(CASE WHEN JourneyStatus = 'Delayed' THEN 1 ELSE 0 END) AS DECIMAL)/ COUNT(*) * 100 AS 'DelayRate'
FROM Railway
GROUP BY Railcard;

--Journey Performance by Departure and Arrival Stations.
SELECT AVG(DATEDIFF(MINUTE,ArrivalTime,ActualArrivalTime)) AS 'AverageDelayTime',DepartureStation, ArrivalDestination
FROM Railway
GROUP BY DepartureStation, ArrivalDestination; 

-- Revenue and Delay Analysis by Railcard and Station.
SELECT Railcard,DepartureStation,ArrivalDestination,  ---Groups the results by different types of Railcards,departure station,arrival station.
SUM(Price) AS TotalRevenue,  ---Calculates the total revenue for each group.
AVG(Price) AS AverageTicketPrice,  ---Calculates the average ticket price for each group.
COUNT(*) AS JourneyCount,  ---Counts the total number of journeys for each group.
CAST(SUM(CASE WHEN JourneyStatus = 'Delayed' THEN 1 ELSE 0 END) AS DECIMAL) / COUNT(*) * 100 AS DelayRate  ---Count the number of delay and divide it by total count of delay then convert it into percentage
FROM Railway  ------Table to fetch the data from
GROUP BY Railcard, DepartureStation, ArrivalDestination  ---Grouping the query based on Following group
ORDER BY TotalRevenue DESC;  --- Arranging the same on the basis of TotalRevenue in Descending order.


--Journey Delay Impact Analysis by Hour of Day
SELECT DATEPART(HOUR, DepartureTime) AS HourOfDay, ---Extracts the hour from the DepartureTime to group data by the hour of the day.
AVG(DATEDIFF(MINUTE, ArrivalTime, ActualArrivalTime)) AS AverageDelayMinutes,  ---Calculates the average delay in minutes for each hour of the day.
COUNT(*) AS TotalJourneys, ---Counts the total number of journeys for each hour.
SUM(CASE WHEN DATEDIFF(MINUTE, ArrivalTime, ActualArrivalTime) > 0 THEN 1 ELSE 0 END) AS DelayedJourneys, ---Counts the number of delayed journeys for each hour.
CAST(SUM(CASE WHEN DATEDIFF(MINUTE,ArrivalTime, ActualArrivalTime) > 0 THEN 1 ELSE 0 END) AS DECIMAL) / COUNT(*) * 100 AS DelayRate  ---Calculates the delay rate as a percentage for each hour.
FROM Railway  ---Table to fetch the data from
GROUP BY DATEPART(HOUR, DepartureTime)   ---Grouping the query based on each hour of the day
ORDER BY AverageDelayMinutes DESC;       --- Arranging the same on the basis of AverageDelayMinutes in Descending so as to get peak delay.

