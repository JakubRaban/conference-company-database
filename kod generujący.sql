USE [master]
GO
/****** Object:  Database [dlugosz_a]    Script Date: 22/01/2019 15:56:04 ******/
CREATE DATABASE [dlugosz_a]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'dlugosz_a', FILENAME = N'/var/opt/mssql/data/dlugosz_a.mdf' , SIZE = 16384KB , MAXSIZE = 30720KB , FILEGROWTH = 2048KB )
 LOG ON 
( NAME = N'dlugosz_a_log', FILENAME = N'/var/opt/mssql/data/dlugosz_a.ldf' , SIZE = 30720KB , MAXSIZE = 30720KB , FILEGROWTH = 2048KB )
GO
ALTER DATABASE [dlugosz_a] SET COMPATIBILITY_LEVEL = 140
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [dlugosz_a].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [dlugosz_a] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [dlugosz_a] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [dlugosz_a] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [dlugosz_a] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [dlugosz_a] SET ARITHABORT OFF 
GO
ALTER DATABASE [dlugosz_a] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [dlugosz_a] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [dlugosz_a] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [dlugosz_a] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [dlugosz_a] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [dlugosz_a] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [dlugosz_a] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [dlugosz_a] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [dlugosz_a] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [dlugosz_a] SET  ENABLE_BROKER 
GO
ALTER DATABASE [dlugosz_a] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [dlugosz_a] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [dlugosz_a] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [dlugosz_a] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [dlugosz_a] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [dlugosz_a] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [dlugosz_a] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [dlugosz_a] SET RECOVERY FULL 
GO
ALTER DATABASE [dlugosz_a] SET  MULTI_USER 
GO
ALTER DATABASE [dlugosz_a] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [dlugosz_a] SET DB_CHAINING OFF 
GO
ALTER DATABASE [dlugosz_a] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [dlugosz_a] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [dlugosz_a] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'dlugosz_a', N'ON'
GO
ALTER DATABASE [dlugosz_a] SET QUERY_STORE = OFF
GO
USE [dlugosz_a]
GO
/****** Object:  UserDefinedFunction [dbo].[CalculatePriceForReservation]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[CalculatePriceForReservation] (@Email varchar(100), @DateOrdered date)
returns money
as
begin
	declare @ReservationID int;
	declare @CustomerID int
	EXEC @CustomerID = dbo.FindCustomerByEmail @Email -- varchar(15)
	select @ReservationID = max(ReservationID)
	from ConferenceReservations
	where CustomerID = @CustomerID AND DateOrdered = @DateOrdered
	return (select sum(AdultPrice*ReservedAdultSeats + StudentPrice*ReservedStudentSeats)
           from dbo.ReservationPrices(@DateOrdered, @ReservationID) r
           join ConferenceDayReservation cdr
           on cdr.ReservationID = @ReservationID and cdr.ConferenceDayID in (select ConferenceDayID
                                                                from ConferenceDays cd
													            where cd.ConferenceID = r.ConferenceID))
end
GO
/****** Object:  UserDefinedFunction [dbo].[ConferenceDayReservationSize]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConferenceDayReservationSize](@ConferenceDayReservationID int)
RETURNS INT
AS
BEGIN
	DECLARE @Size INT = (SELECT SUM(c.ReservedAdultSeats )+ SUM(c.ReservedAdultSeats)
						FROM dbo.ConferenceDayReservation c
						WHERE c.DayReservationID = @ConferenceDayReservationID)
	RETURN @Size
END
GO
/****** Object:  UserDefinedFunction [dbo].[ConferenceOrderedAfterCreated]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConferenceOrderedAfterCreated] (@ConferenceDayID INT, @ReservationID INT)
RETURNS INT
BEGIN
	DECLARE @ConfCreated DATE = (SELECT Conferences.CreatedOn FROM dbo.ConferenceDays
								INNER JOIN Conferences ON Conferences.ConferenceID = ConferenceDays.ConferenceID
								WHERE ConferenceDays.ConferenceDayID = @ConferenceDayID)
	DECLARE @OrderDate DATE = (SELECT DateOrdered FROM dbo.ConferenceReservations
								WHERE ReservationID = @ReservationID)
	RETURN DATEDIFF(DAY, @ConfCreated, @OrderDate)
END
GO
/****** Object:  UserDefinedFunction [dbo].[ConferenceSize]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConferenceSize](@ConferenceDayID INT)
RETURNS int
BEGIN
	DECLARE @size int = (SELECT ParticipantsLimit FROM ConferenceDays
	INNER JOIN conferences ON Conferences.ConferenceID = ConferenceDays.ConferenceID
	WHERE ConferenceDayID = @ConferenceDayID)
	RETURN @size
END
GO
/****** Object:  UserDefinedFunction [dbo].[DayReservationTotalSeats]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[DayReservationTotalSeats](@ConferenceDayReservationID INT)
RETURNS INT
BEGIN
	DECLARE @result INT
	SELECT @result = SUM(ReservedAdultSeats) + SUM(ReservedStudentSeats)
	FROM dbo.ConferenceDayReservation cdr
	WHERE cdr.DayReservationID = @ConferenceDayReservationID
	RETURN @result
end
GO
/****** Object:  UserDefinedFunction [dbo].[DiscountForConference]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[DiscountForConference](@DateOrdered date, @ConferenceID int)
returns real
as
begin
	declare @TimeDiscount real;
	if not exists (select DiscountRate
				   from ConferencePricetables cp
			       where cp.ConferenceID = @ConferenceID and @DateOrdered between cp.PriceStartsOn and cp.PriceEndsOn)
		set @TimeDiscount = 0
	else
		set @TimeDiscount =  (select DiscountRate
							  from ConferencePricetables cp
							  where cp.ConferenceID = @ConferenceID and @DateOrdered between cp.PriceStartsOn and cp.PriceEndsOn)
	return @TimeDiscount
end
GO
/****** Object:  UserDefinedFunction [dbo].[EmptySeatsInWorkshopReservation]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[EmptySeatsInWorkshopReservation] (@DayParticipantID INT, @ConferenceDayWorkshopID int)
RETURNS INT 
BEGIN
	DECLARE @SeatsReserved INT, @SeatsOccupied INT, @DayReservationID INT
    SELECT @DayReservationID = ConferenceDayReservationID
	FROM dbo.ConferenceDayParticipants
	WHERE ConferenceDayParticipantID = @DayParticipantID
	SELECT @SeatsReserved = ReservedSeats
	FROM dbo.WorkshopReservation
	WHERE ConferenceDayReservationID = @DayReservationID AND ConferenceDayWorkshopID = @ConferenceDayWorkshopID
	SELECT @SeatsOccupied = COUNT(*)
	FROM dbo.WorkshopParticipants
	INNER JOIN dbo.ConferenceDayParticipants ON ConferenceDayParticipants.ConferenceDayParticipantID = WorkshopParticipants.ConferenceDayParticipantID
	WHERE ConferenceDayWorkshopID = @ConferenceDayWorkshopID AND ConferenceDayReservationID = @DayReservationID
	IF @SeatsReserved IS NULL RETURN -1
	RETURN @SeatsReserved - @SeatsOccupied
END
GO
/****** Object:  UserDefinedFunction [dbo].[FindCompanyByEmail]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[FindCompanyByEmail] (@Email varchar(100))
returns int
as
begin
	return (select CompanyID from Companies where Email = @Email)
end
GO
/****** Object:  UserDefinedFunction [dbo].[FindCompanyByName]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[FindCompanyByName] (@Name varchar(150))
returns int
as
begin
	return (select CompanyID from Companies where CompanyName = @Name)
end
GO
/****** Object:  UserDefinedFunction [dbo].[FindCompanyByNIP]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[FindCompanyByNIP] (@NIP char(10))
returns int
as
begin
	return (select CompanyID from Companies where NIP = @NIP)
end
GO
/****** Object:  UserDefinedFunction [dbo].[FindCompanyByPhone]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create function [dbo].[FindCompanyByPhone] (@Phone varchar(15))
returns int
as
begin
	return (select CompanyID from Companies where Phone = @Phone)
end
GO
/****** Object:  UserDefinedFunction [dbo].[FindCustomerByEmail]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[FindCustomerByEmail]	(@Email varchar(100))
returns int
as
begin
	declare @CompanyID int;
	exec @CompanyID = FindCompanyByEmail @Email;
	if @CompanyID is null
	begin
		declare @ParticipantID int;
		EXEC @ParticipantID = FindParticipantByEmail @Email;
		return (select CustomerID from PrivateCustomers where ParticipantID = @ParticipantID)
	end
	return @CompanyID
end
GO
/****** Object:  UserDefinedFunction [dbo].[FindParticipantByEmail]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[FindParticipantByEmail] (@Email varchar(100))
returns int
as
begin
	return (select ParticipantID from Participants where Email = @Email)
end
GO
/****** Object:  UserDefinedFunction [dbo].[FindParticipantByName]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create function [dbo].[FindParticipantByName] (@FirstName varchar(30), @LastName varchar(50))
returns int
as
begin
	return (select ParticipantID from Participants where FirstName = @FirstName and LastName = @LastName)
end
GO
/****** Object:  UserDefinedFunction [dbo].[FindWorkshop]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[FindWorkshop] (@Name VARCHAR(200))
RETURNS INT 
BEGIN
	DECLARE @ID INT = (SELECT WorkshopID FROM dbo.Workshops WHERE Name = @Name)
	RETURN @ID
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetConferenceStartDate]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[GetConferenceStartDate](@ConferenceID int)
returns date
as
begin
	return (select StartDate from Conferences where ConferenceID = @ConferenceID)
end
GO
/****** Object:  UserDefinedFunction [dbo].[GetLatestDiscount]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[GetLatestDiscount](@ConferenceID int)
returns real
as
begin
	declare @discount real;
	if exists (select *
			   from ConferencePricetables
			   where ConferenceID = @ConferenceID)
		set @discount = (select min(DiscountRate)
						from ConferencePricetables
						where ConferenceID = @ConferenceID)
	else
		set @discount = 1
	return @discount
end
GO
/****** Object:  UserDefinedFunction [dbo].[GetNumberOfPaidReservationForCustomer]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[GetNumberOfPaidReservationForCustomer](@Email varchar(100))
returns int
begin
	declare @CustomerID int;
	exec @CustomerID = dbo.FindCustomerByEmail @Email;
	return (select count(*)
			from ConferenceReservations
			where CustomerID = @CustomerID and DatePaid is not null)
end
GO
/****** Object:  UserDefinedFunction [dbo].[HasParticipantCollidingWorkshops]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[HasParticipantCollidingWorkshops](@NewWorkshopID INT, @ConferenceDayParticipantID int)
RETURNS BIT
BEGIN
	DECLARE @Times TABLE (
		TimeID INT PRIMARY KEY IDENTITY(0,1),
		StartTime TIME,
		EndTime time
	)
	INSERT INTO @Times
	SELECT StartTime, EndTime
	FROM dbo.WorkshopParticipants
	INNER JOIN dbo.ConferenceDayWorkshops ON ConferenceDayWorkshops.ConferenceDayWorkshopID = WorkshopParticipants.ConferenceDayWorkshopID
	WHERE ConferenceDayID = (SELECT ConferenceDayID
							FROM dbo.ConferenceDayWorkshops
							WHERE ConferenceDayWorkshopID = @NewWorkshopID)
	AND ConferenceDayParticipantID = @ConferenceDayParticipantID;

	DECLARE @has BIT = (SELECT COUNT(*) from
	(SELECT a.TimeID
	FROM @Times AS a
	INNER JOIN @Times AS b ON ((a.StartTime BETWEEN b.StartTime AND b.EndTime) OR
							   (a.EndTime BETWEEN b.StartTime AND b.EndTime) OR
							   (a.StartTime < b.StartTime AND a.EndTime > b.EndTime))
							   AND (a.TimeID != b.TimeID)) AS t)
	RETURN @has
END
GO
/****** Object:  UserDefinedFunction [dbo].[IsReservationByCompany]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[IsReservationByCompany] (@ReservationID int)
returns bit
as
begin
	declare @CompanyID int
	select @CompanyID = Companies.CompanyID
	from ConferenceReservations
	inner join Customers on ConferenceReservations.CustomerID = Customers.CustomerID
	left join Companies on customers.CustomerID = CompanyID
	where ReservationID = @ReservationID
	if @CompanyID is not null begin return 1 end
	return 0
end
GO
/****** Object:  UserDefinedFunction [dbo].[IsReservationPaid]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[IsReservationPaid](@ReservationID INT)
RETURNS BIT
begin
RETURN (SELECT COUNT(*) FROM
		(SELECT DatePaid
		FROM ConferenceReservations
		WHERE DatePaid IS NOT NULL AND ReservationID = @ReservationID) t)
END
GO
/****** Object:  UserDefinedFunction [dbo].[NewPriceAtTheDayAfterPrevious]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[NewPriceAtTheDayAfterPrevious](@ConferenceID INT)
RETURNS int
BEGIN

	IF (SELECT COUNT(*) FROM dbo.ConferencePricetables) = 1 RETURN 1

	DECLARE @Dates TABLE (
		DateID INT PRIMARY KEY IDENTITY(1,1),
		StartDate date,
		EndDate date
	)
	INSERT INTO @Dates (StartDate, EndDate)
	SELECT TOP 2 PriceStartsOn, PriceEndsOn
	FROM dbo.ConferencePricetables
	WHERE ConferenceID = @ConferenceID
	ORDER BY PriceStartsOn DESC

	DECLARE @PrevStepEnd DATE = (SELECT EndDate FROM @Dates WHERE DateID = 2)
	DECLARE @NewStepStart DATE = (SELECT StartDate FROM @Dates WHERE DateID = 1)
	RETURN DATEDIFF(DAY, @PrevStepEnd, @NewStepStart)
END
GO
/****** Object:  UserDefinedFunction [dbo].[OrganisedLaterThanHired]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[OrganisedLaterThanHired] (@EmployeeID int, @ConferenceID int)
RETURNS int
BEGIN
	DECLARE @HireDate DATE = (SELECT HireDate FROM dbo.OurEmployees WHERE EmployeeID = @EmployeeID)
	DECLARE @ConfDate DATE = (SELECT StartDate FROM Conferences WHERE ConferenceID = @ConferenceID)
	RETURN DATEDIFF(DAY, @HireDate, @ConfDate)
END
GO
/****** Object:  UserDefinedFunction [dbo].[ReservationEarlierThanConferenceDay]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ReservationEarlierThanConferenceDay](@ConferenceDayID int, @ReservationID INT)
RETURNS INT
BEGIN
	DECLARE @ConfDate DATE = (SELECT Date FROM dbo.ConferenceDays WHERE ConferenceDayID = @ConferenceDayID)
	DECLARE @Orderdate DATE = (SELECT DateOrdered FROM dbo.ConferenceReservations WHERE ReservationID = @ReservationID)
	RETURN DATEDIFF(DAY, @Orderdate, @ConfDate)
END
GO
/****** Object:  UserDefinedFunction [dbo].[ReservedSeatsForWorkshop]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ReservedSeatsForWorkshop](@ConferenceDayWorkshopID int)
RETURNS int
BEGIN
	DECLARE @Sum INT = (SELECT SUM(ReservedSeats)
						FROM WorkshopReservation
						WHERE ConferenceDayWorkshopID = @ConferenceDayWorkshopID)
	RETURN @Sum
end
GO
/****** Object:  UserDefinedFunction [dbo].[ReservedSeatsPerConferenceDay]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ReservedSeatsPerConferenceDay](@ConferenceDayID INT)
RETURNS INT
BEGIN
	DECLARE @number INT = (SELECT SUM(ReservedAdultSeats) + SUM(ReservedStudentSeats)
							FROM dbo.ConferenceDayReservation
							WHERE ConferenceDayID = @ConferenceDayID)
    IF @number IS NULL BEGIN SET @number = 0 end
	RETURN @number
END
GO
/****** Object:  UserDefinedFunction [dbo].[ViewOrdersByEmailAsCustomer]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ViewOrdersByEmailAsCustomer] (@CustomerEmail VARCHAR(100))
RETURNS @Data TABLE (
	DateOrdered DATE,
	DatePaid DATE,
	TotalAmount MONEY
)
BEGIN
	INSERT INTO @Data (DateOrdered, DatePaid, TotalAmount)
	SELECT DateOrdered, DatePaid, dbo.CalculatePriceForReservation(@CustomerEmail, DateOrdered)
	FROM dbo.ConferenceReservations
	INNER JOIN dbo.CustomerContactData ON CustomerContactData.CustomerID = ConferenceReservations.CustomerID
	WHERE Email = @CustomerEmail
	RETURN 
END
GO
/****** Object:  UserDefinedFunction [dbo].[WorkshopReservationOnDayReservationConference]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[WorkshopReservationOnDayReservationConference] (@DayReservationID INT, @WorkshopInDayID INT)
RETURNS INT
BEGIN
	DECLARE @ConferenceDayAtReservation INT = (SELECT ConferenceDayID FROM dbo.ConferenceDayReservation WHERE DayReservationID = @DayReservationID)
	DECLARE @ConferenceDayAtWorkshop INT = (SELECT ConferenceDayID FROM dbo.ConferenceDayWorkshops WHERE ConferenceDayWorkshopID = @WorkshopInDayID)
	RETURN @ConferenceDayAtReservation - @ConferenceDayAtWorkshop
END
GO
/****** Object:  UserDefinedFunction [dbo].[WorkshopSeatsLimit]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[WorkshopSeatsLimit](@WorkshopID INT)
RETURNS INT
AS
BEGIN
	DECLARE @Limit INT = (SELECT ParticipantsLimit
						 FROM dbo.ConferenceDayWorkshops
						 WHERE ConferenceDayWorkshopID = @WorkshopID)
	RETURN @Limit
end
GO
/****** Object:  Table [dbo].[PrivateCustomers]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PrivateCustomers](
	[CustomerID] [int] NOT NULL,
	[ParticipantID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UniqueParticipant] UNIQUE NONCLUSTERED 
(
	[ParticipantID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Customers]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customers](
	[CustomerID] [int] IDENTITY(0,1) NOT NULL,
	[Street] [nvarchar](74) NULL,
	[HouseNumber] [nvarchar](5) NULL,
	[AppartmentNumber] [int] NULL,
	[CityID] [int] NULL,
	[PostalCode] [char](6) NULL,
PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Companies]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Companies](
	[CompanyID] [int] NOT NULL,
	[CompanyName] [nvarchar](150) NULL,
	[NIP] [char](10) NOT NULL,
	[Phone] [varchar](15) NOT NULL,
	[Email] [varchar](100) NULL,
 CONSTRAINT [PK__Companie__2D971C4C89B49313] PRIMARY KEY CLUSTERED 
(
	[CompanyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ__Companie__5C7E359E2281BCA6] UNIQUE NONCLUSTERED 
(
	[Phone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ__Companie__C7DEC3C65B7646BC] UNIQUE NONCLUSTERED 
(
	[NIP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_EMAIL] UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Participants]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Participants](
	[ParticipantID] [int] IDENTITY(0,1) NOT NULL,
	[FirstName] [varchar](30) NULL,
	[LastName] [varchar](50) NULL,
	[Phone] [varchar](15) NULL,
	[Email] [varchar](100) NULL,
 CONSTRAINT [PK__Particip__7227997EFB4A4EAE] PRIMARY KEY CLUSTERED 
(
	[ParticipantID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ConferenceReservations]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConferenceReservations](
	[ReservationID] [int] IDENTITY(0,1) NOT NULL,
	[CustomerID] [int] NOT NULL,
	[DateOrdered] [date] NOT NULL,
	[DatePaid] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[ReservationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_ONE_DAY_ONE_CUSTOMER_ONE_ORDER] UNIQUE NONCLUSTERED 
(
	[CustomerID] ASC,
	[DateOrdered] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[Payments]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[Payments] AS
SELECT ReservationID, CompanyName, Email, DateOrdered, DatePaid,
	dbo.CalculatePriceForReservation( Companies.Email, DateOrdered) AS Price
FROM ConferenceReservations
JOIN Customers
ON ConferenceReservations.CustomerID = Customers.CustomerID
JOIN Companies
ON Customers.CustomerID = Companies.CompanyID
UNION
SELECT ReservationID, (FirstName + ' ' + LastName), Email, DateOrdered, DatePaid,
	dbo.CalculatePriceForReservation( Participants.Email, DateOrdered) AS Price
FROM ConferenceReservations
JOIN Customers
ON ConferenceReservations.CustomerID = Customers.CustomerID
JOIN PrivateCustomers
ON Customers.CustomerID = PrivateCustomers.CustomerID
JOIN Participants
ON PrivateCustomers.ParticipantID = Participants.ParticipantID
GO
/****** Object:  View [dbo].[UnpaidReservations]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[UnpaidReservations]
as
select ReservationID, CompanyName, DateOrdered
from ConferenceReservations
join Customers
on ConferenceReservations.CustomerID = Customers.CustomerID
join Companies
on Customers.CustomerID = Companies.CompanyID
where DatePaid is null
union
select ReservationID, (FirstName + ' ' + LastName), DateOrdered
from ConferenceReservations
join Customers
on ConferenceReservations.CustomerID = Customers.CustomerID
join PrivateCustomers
on Customers.CustomerID = PrivateCustomers.CustomerID
join Participants
on PrivateCustomers.ParticipantID = Participants.ParticipantID
where DatePaid is null
GO
/****** Object:  View [dbo].[CustomersWithPaidReservations]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[CustomersWithPaidReservations]
AS
SELECT CompanyName AS Customer, 'Company' AS 'Customer type', dbo.GetNumberOfPaidReservationForCustomer(Companies.Email) AS PaidReservations
FROM Customers
JOIN Companies
ON Customers.CustomerID = Companies.CompanyID
UNION
SELECT (FirstName + ' ' + LastName) AS Customer,
'Private customer' AS 'Customer type',
dbo.GetNumberOfPaidReservationForCustomer(Participants.Email) AS PaidReservations
FROM Customers
JOIN PrivateCustomers
ON Customers.CustomerID = PrivateCustomers.CustomerID
JOIN Participants
ON PrivateCustomers.ParticipantID = Participants.ParticipantID
GO
/****** Object:  Table [dbo].[Conferences]    Script Date: 22/01/2019 15:56:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Conferences](
	[ConferenceID] [int] IDENTITY(0,1) NOT NULL,
	[Name] [varchar](200) NOT NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [date] NOT NULL,
	[BasePriceForDay] [money] NULL,
	[StudentDiscount] [real] NULL,
	[ParticipantsLimit] [int] NULL,
	[Street] [varchar](74) NULL,
	[HouseNumber] [varchar](5) NULL,
	[AppartmentNumber] [int] NULL,
	[CityID] [int] NULL,
	[PostalCode] [char](6) NULL,
	[CreatedOn] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[ConferenceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ConferenceDayReservation]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConferenceDayReservation](
	[DayReservationID] [int] IDENTITY(0,1) NOT NULL,
	[ConferenceDayID] [int] NOT NULL,
	[ReservedAdultSeats] [int] NOT NULL,
	[ReservedStudentSeats] [int] NOT NULL,
	[ReservationID] [int] NOT NULL,
 CONSTRAINT [PK__Conferen__5572EBDB96C393BD] PRIMARY KEY CLUSTERED 
(
	[DayReservationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_DAY_AND_RESERVATION] UNIQUE NONCLUSTERED 
(
	[ConferenceDayID] ASC,
	[ReservationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ConferenceDays]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConferenceDays](
	[ConferenceDayID] [int] IDENTITY(0,1) NOT NULL,
	[ConferenceID] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[DayOrdinal] [smallint] NULL,
 CONSTRAINT [PK__Conferen__E57A6462D2FB2DE1] PRIMARY KEY CLUSTERED 
(
	[ConferenceDayID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [CHK_DAY_ORD_UNIQ] UNIQUE NONCLUSTERED 
(
	[ConferenceID] ASC,
	[DayOrdinal] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[ConferencesWithAvailablePlaces]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[ConferencesWithAvailablePlaces]
AS
SELECT Conferences.ConferenceID, Name, DayOrdinal AS Day, ConferenceDays.Date AS 'Date', ParticipantsLimit AS 'Seat limit', 
	ISNULL(SUM(ReservedAdultSeats), 0) AS 'Reserved adult seats',
	ISNULL(SUM(ReservedStudentSeats), 0) AS 'Reserved student seats',
	ISNULL(SUM(ReservedAdultSeats + ReservedStudentSeats), 0) AS 'Total seats reserved',
	ParticipantsLimit - ISNULL(SUM(ReservedAdultSeats + ReservedStudentSeats), 0) AS 'Available seats'
FROM Conferences
JOIN ConferenceDays
ON Conferences.ConferenceID = ConferenceDays.ConferenceID
LEFT JOIN ConferenceDayReservation
ON ConferenceDays.ConferenceDayID = ConferenceDayReservation.ConferenceDayID
WHERE Conferences.EndDate >= CONVERT(DATE, GETDATE())
GROUP BY Conferences.ConferenceID, Name, DayOrdinal, ParticipantsLimit, ConferenceDays.Date
GO
/****** Object:  Table [dbo].[ConferenceDayWorkshops]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConferenceDayWorkshops](
	[ConferenceDayWorkshopID] [int] IDENTITY(0,1) NOT NULL,
	[ConferenceDayID] [int] NOT NULL,
	[WorkshopID] [int] NOT NULL,
	[StartTime] [time](7) NOT NULL,
	[EndTime] [time](7) NOT NULL,
	[Price] [money] NULL,
	[ParticipantsLimit] [int] NULL,
 CONSTRAINT [PK__Conferen__714B153C1B305831] PRIMARY KEY CLUSTERED 
(
	[ConferenceDayWorkshopID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WorkshopReservation]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkshopReservation](
	[WorkshopReservationID] [int] IDENTITY(0,1) NOT NULL,
	[ConferenceDayWorkshopID] [int] NOT NULL,
	[ConferenceDayReservationID] [int] NOT NULL,
	[ReservedSeats] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[WorkshopReservationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_ONE_DAY_RESERV_ONE_WORKSH_RESERV] UNIQUE NONCLUSTERED 
(
	[ConferenceDayWorkshopID] ASC,
	[ConferenceDayReservationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Workshops]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Workshops](
	[WorkshopID] [int] IDENTITY(0,1) NOT NULL,
	[Name] [varchar](200) NOT NULL,
	[Description] [varchar](1000) NULL,
 CONSTRAINT [PK__Workshop__7A008C2A4FD1EE19] PRIMARY KEY CLUSTERED 
(
	[WorkshopID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_NAME] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[WorkshopsWithAvailablePlaces]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[WorkshopsWithAvailablePlaces]
AS
SELECT Conferences.Name AS 'Conference Name',
	Date, Workshops.Name AS 'Workshop Name',  StartTime, EndTime, Price,
	ConferenceDayWorkshops.ParticipantsLimit AS 'Seats limit', ISNULL(SUM(ReservedSeats),0) AS 'Reserved seats', 
	ConferenceDayWorkshops.ParticipantsLimit - ISNULL(SUM(ReservedSeats),0) AS 'Available Places', 
	Description
FROM Conferences
JOIN ConferenceDays
ON Conferences.ConferenceID = ConferenceDays.ConferenceID
JOIN ConferenceDayWorkshops
ON ConferenceDays.ConferenceDayID = ConferenceDayWorkshops.ConferenceDayID
JOIN Workshops
ON ConferenceDayWorkshops.WorkshopID = Workshops.WorkshopID
LEFT JOIN WorkshopReservation
ON ConferenceDayWorkshops.ConferenceDayWorkshopID = WorkshopReservation.ConferenceDayWorkshopID
GROUP BY Conferences.ConferenceID, Conferences.Name, Date, StartDate, StartTime,
	EndTime, Workshops.Name, Price, ConferenceDayWorkshops.ParticipantsLimit, Description
GO
/****** Object:  Table [dbo].[Students]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Students](
	[ParticipantID] [int] NOT NULL,
	[StudentCardNumber] [varchar](10) NULL,
 CONSTRAINT [PK__Student__7227997E8D9AA260] PRIMARY KEY CLUSTERED 
(
	[ParticipantID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmployeesOfCompanies]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeesOfCompanies](
	[ParticipantID] [int] NOT NULL,
	[CompanyID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ParticipantID] ASC,
	[CompanyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_EmployeesOfCompanies] UNIQUE NONCLUSTERED 
(
	[ParticipantID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ConferenceDayParticipants]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConferenceDayParticipants](
	[ConferenceDayParticipantID] [int] IDENTITY(0,1) NOT NULL,
	[ConferenceDayReservationID] [int] NOT NULL,
	[ParticipantID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ConferenceDayParticipantID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_PARTICIPANT] UNIQUE NONCLUSTERED 
(
	[ConferenceDayReservationID] ASC,
	[ParticipantID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[ParticipantIdentificators]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[ParticipantIdentificators]
AS
SELECT Name AS 'Conference Name', Date, FirstName, LastName, CompanyName, StudentCardNumber
FROM Conferences
JOIN ConferenceDays
ON Conferences.ConferenceID = ConferenceDays.ConferenceID
JOIN ConferenceDayReservation
ON ConferenceDays.ConferenceDayID = ConferenceDayReservation.ConferenceDayID
JOIN ConferenceDayParticipants
ON ConferenceDayReservation.DayReservationID = ConferenceDayParticipants.ConferenceDayReservationID
JOIN Participants
ON ConferenceDayParticipants.ParticipantID = Participants.ParticipantID
LEFT JOIN dbo.Students
ON Students.ParticipantID = Participants.ParticipantID
LEFT JOIN EmployeesOfCompanies
ON Participants.ParticipantID = EmployeesOfCompanies.ParticipantID
LEFT JOIN Companies
ON EmployeesOfCompanies.CompanyID = Companies.CompanyID
WHERE LastName IS NOT NULL AND date >= CONVERT(DATE, GETDATE())
GO
/****** Object:  Table [dbo].[WorkshopParticipants]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkshopParticipants](
	[ConferenceDayParticipantID] [int] NOT NULL,
	[ConferenceDayWorkshopID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ConferenceDayParticipantID] ASC,
	[ConferenceDayWorkshopID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[WorkshopsParticipantsList]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[WorkshopsParticipantsList]
AS
SELECT Conferences.Name AS 'Conference name', dbo.Workshops.Name AS 'Workshop name', dbo.ConferenceDays.Date, dbo.ConferenceDayWorkshops.StartTime, 
		dbo.ConferenceDayWorkshops.EndTime,
		FirstName, LastName, StudentCardNumber, CompanyName
FROM dbo.WorkshopParticipants
INNER JOIN dbo.ConferenceDayWorkshops ON ConferenceDayWorkshops.ConferenceDayWorkshopID = WorkshopParticipants.ConferenceDayWorkshopID
INNER JOIN dbo.Workshops ON Workshops.WorkshopID = ConferenceDayWorkshops.WorkshopID
INNER JOIN dbo.ConferenceDays ON ConferenceDays.ConferenceDayID = ConferenceDayWorkshops.ConferenceDayID
INNER JOIN dbo.Conferences ON Conferences.ConferenceID = ConferenceDays.ConferenceID
INNER JOIN dbo.ConferenceDayParticipants ON ConferenceDayParticipants.ConferenceDayParticipantID = WorkshopParticipants.ConferenceDayParticipantID
INNER JOIN dbo.Participants ON Participants.ParticipantID = ConferenceDayParticipants.ParticipantID
LEFT JOIN dbo.Students ON Students.ParticipantID = Participants.ParticipantID
LEFT JOIN dbo.EmployeesOfCompanies ON EmployeesOfCompanies.ParticipantID = Participants.ParticipantID
LEFT JOIN dbo.Companies ON Companies.CompanyID = EmployeesOfCompanies.CompanyID
GO
/****** Object:  Table [dbo].[Countries]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Countries](
	[CountryID] [int] IDENTITY(0,1) NOT NULL,
	[CountryName] [varchar](80) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CountryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_COUNTRY] UNIQUE NONCLUSTERED 
(
	[CountryName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Regions]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Regions](
	[RegionID] [int] IDENTITY(0,1) NOT NULL,
	[RegionName] [varchar](80) NOT NULL,
	[CountryID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RegionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_REGION] UNIQUE NONCLUSTERED 
(
	[RegionName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Cities]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cities](
	[CityID] [int] IDENTITY(0,1) NOT NULL,
	[CityName] [varchar](80) NOT NULL,
	[RegionID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[OrganisingCities]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[OrganisingCities] AS
SELECT CityName, RegionName, CountryName, COUNT(ConferenceID) AS 'Number of organised conferences'
FROM dbo.Cities
INNER JOIN dbo.Regions ON Regions.RegionID = Cities.RegionID
INNER JOIN dbo.Countries ON Countries.CountryID = Regions.CountryID
INNER JOIN dbo.Conferences ON Conferences.CityID = Cities.CityID
GROUP BY CityName, RegionName, CountryName
GO
/****** Object:  View [dbo].[OrdersToBeDeleted]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[OrdersToBeDeleted] AS
SELECT * FROM dbo.UnpaidReservations
WHERE DATEDIFF(DAY, DateOrdered, CONVERT(DATE, GETDATE())) > 7
GO
/****** Object:  View [dbo].[ParticipantData]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ParticipantData] AS
SELECT Conferences.Name AS 'Conference name', ConferenceDays.Date AS 'Date', FirstName + ' ' + LastName AS 'Name', Phone, Email
FROM dbo.ConferenceDayParticipants
INNER JOIN dbo.Participants ON Participants.ParticipantID = ConferenceDayParticipants.ParticipantID
INNER JOIN dbo.ConferenceDayReservation ON ConferenceDayReservation.DayReservationID = ConferenceDayParticipants.ConferenceDayReservationID
INNER JOIN dbo.ConferenceDays ON ConferenceDays.ConferenceDayID = ConferenceDayReservation.ConferenceDayID
INNER JOIN dbo.Conferences ON Conferences.ConferenceID = ConferenceDays.ConferenceID
WHERE LastName IS NOT NULL AND EndDate >= CONVERT(DATE, GETDATE())
GO
/****** Object:  View [dbo].[ConferencePlan]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ConferencePlan] AS
SELECT Conferences.Name AS 'Conference name', 
	   Date, 
	   ISNULL(dbo.Workshops.Name, '[No workshops at that day]') AS 'Workshop name', 
	   StartTime AS 'Start time', 
	   EndTime AS 'End time', 
	   ISNULL(Description, '---') AS 'Description'
FROM dbo.Conferences
left JOIN dbo.ConferenceDays ON ConferenceDays.ConferenceID = Conferences.ConferenceID
left JOIN dbo.ConferenceDayWorkshops ON ConferenceDayWorkshops.ConferenceDayID = ConferenceDays.ConferenceDayID
LEFT JOIN dbo.Workshops ON Workshops.WorkshopID = ConferenceDayWorkshops.WorkshopID
GO
/****** Object:  View [dbo].[CustomerContactData]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[CustomerContactData] AS
SELECT CustomerID, CompanyName AS 'Name',
	   'Company' AS 'Customer type',
	   Street + ' ' + HouseNumber + ISNULL('/' + CAST(AppartmentNumber AS VARCHAR), '') + ', ' + PostalCode + ' ' + CityName + ', ' + RegionName + ', ' + CountryName AS 'Address',
	   Phone,
	   Email
FROM dbo.Customers
INNER JOIN dbo.Companies ON Companies.CompanyID = Customers.CustomerID
INNER JOIN dbo.Cities ON Cities.CityID = Customers.CityID
INNER JOIN dbo.Regions ON Regions.RegionID = Cities.RegionID
INNER JOIN dbo.Countries ON Countries.CountryID = Regions.CountryID
UNION
SELECT Customers.CustomerID, FirstName + ' ' + LastName AS 'Name',
	   'Private Customer' AS 'Customer type',
	   Street + ' ' + HouseNumber + ISNULL('/' + CAST(AppartmentNumber AS VARCHAR), '') + ', ' + PostalCode + ' ' + CityName + ', ' + RegionName + ', ' + CountryName AS 'Address',
	   Phone,
	   Email
FROM dbo.Customers
INNER JOIN dbo.PrivateCustomers ON PrivateCustomers.CustomerID = Customers.CustomerID
INNER JOIN dbo.Participants ON Participants.ParticipantID = PrivateCustomers.ParticipantID
INNER JOIN dbo.Cities ON Cities.CityID = Customers.CityID
INNER JOIN dbo.Regions ON Regions.RegionID = Cities.RegionID
INNER JOIN dbo.Countries ON Countries.CountryID = Regions.CountryID
GO
/****** Object:  Table [dbo].[OurEmployees]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OurEmployees](
	[EmployeeID] [int] IDENTITY(0,1) NOT NULL,
	[FirstName] [varchar](30) NOT NULL,
	[LastName] [varchar](50) NOT NULL,
	[BirthDate] [date] NULL,
	[HireDate] [date] NULL,
	[Phone] [varchar](15) NOT NULL,
	[Street] [varchar](74) NULL,
	[HouseNumber] [varchar](5) NULL,
	[AppartmentNumber] [int] NULL,
	[CityID] [int] NULL,
	[PostalCode] [char](6) NULL,
	[Email] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[EmployeeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [CHK_EMP_EMAIL_UNIQ] UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [CHK_EMP_PHONE_UNIQ] UNIQUE NONCLUSTERED 
(
	[Phone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ConferenceEmployees]    Script Date: 22/01/2019 15:56:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConferenceEmployees](
	[ConferenceID] [int] NOT NULL,
	[EmployeeID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ConferenceID] ASC,
	[EmployeeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[EmployeesInDuty]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[EmployeesInDuty] AS
SELECT FirstName + ' ' + LastName AS 'Employee', Name
FROM dbo.ConferenceEmployees
INNER JOIN dbo.OurEmployees ON OurEmployees.EmployeeID = ConferenceEmployees.EmployeeID
INNER JOIN dbo.Conferences ON Conferences.ConferenceID = ConferenceEmployees.ConferenceID
GO
/****** Object:  View [dbo].[DayWorkshopReservationData]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[DayWorkshopReservationData] AS
SELECT CustomerContactData.Name AS 'Name', [Customer type], Address, Phone, Email, DateOrdered, DatePaid,
		Conferences.Name AS 'Conference name', Date, DayOrdinal,
		cdr.ReservedAdultSeats, cdr.ReservedStudentSeats, Workshops.name AS 'Workshop name', ConferenceDays.Date AS 'Workshop date',
		dbo.WorkshopReservation.ReservedSeats
FROM dbo.ConferenceReservations
INNER JOIN dbo.ConferenceDayReservation cdr ON ConferenceReservations.ReservationID = cdr.ReservationID
INNER JOIN dbo.CustomerContactData ON ConferenceReservations.CustomerID = CustomerContactData.CustomerID
INNER JOIN dbo.ConferenceDays ON ConferenceDays.ConferenceDayID = cdr.ConferenceDayID
INNER JOIN dbo.Conferences ON Conferences.ConferenceID = ConferenceDays.ConferenceID
LEFT OUTER JOIN dbo.WorkshopReservation ON WorkshopReservation.ConferenceDayReservationID = cdr.DayReservationID
LEFT OUTER JOIN dbo.ConferenceDayWorkshops ON ConferenceDayWorkshops.ConferenceDayWorkshopID = dbo.WorkshopReservation.ConferenceDayWorkshopID
LEFT OUTER JOIN dbo.Workshops ON Workshops.WorkshopID = ConferenceDayWorkshops.WorkshopID
GO
/****** Object:  View [dbo].[DayReservationData]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[DayReservationData] AS
SELECT DISTINCT Name AS 'Name', [Customer type], Address, Phone, Email, DateOrdered, DatePaid,
		[Conference name], Date, DayOrdinal,
		ReservedAdultSeats, ReservedStudentSeats
FROM DayWorkshopReservationData
GO
/****** Object:  View [dbo].[WorkshopReservationData]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[WorkshopReservationData] AS
SELECT Name AS 'Name', [Customer type], Address, Phone, Email, DateOrdered, DatePaid, 
	   [Conference name], Date, DayOrdinal,
	   [Workshop name], [Workshop date],
	   [ReservedSeats]
FROM DayWorkshopReservationData
WHERE [Workshop name] IS NOT null
GO
/****** Object:  View [dbo].[TwoWeekOldReservationsWithoutAllParticipants]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[TwoWeekOldReservationsWithoutAllParticipants] as
select cdp.ConferenceDayReservationID as 'Conference Day Reservation ID',
	   (select 2 from (select cdpp.ConferenceDayReservationID as x1, count(cdpp.ParticipantID) as y1
					   from ConferenceDayParticipants cdpp
					   inner join Participants p
							on P.ParticipantID = cdpp.ParticipantID
					   left join Students
							on p.ParticipantID = students.ParticipantID
					   where LastName is null and students.ParticipantID is null
					   group by cdpp.ConferenceDayReservationID) as t where t.x1 = cdp.ConferenceDayReservationID) as 'Adult Seats Left',
	   (select 2 from (select cdpp.ConferenceDayReservationID as x2, count(cdpp.ParticipantID) as y2
					   from ConferenceDayParticipants cdpp
					   inner join Participants p
							on P.ParticipantID = cdpp.ParticipantID
					   inner join Students
							on p.ParticipantID = students.ParticipantID
					   where LastName is null
					   group by cdpp.ConferenceDayReservationID) as t where t.x2 = cdp.ConferenceDayReservationID) as 'Student seats left',
	   c.Phone
from ConferenceDayParticipants cdp
inner join ConferenceDayReservation cdr
	on cdp.ConferenceDayReservationID = cdr.DayReservationID
inner join ConferenceReservations cr
	on cdr.ReservationID = cr.ReservationID
inner join Customers cust
	on cr.CustomerID = cust.CustomerID
inner join Companies c
	on c.CompanyID = cust.CustomerID
where datediff(day, cr.dateordered, convert(date, getdate())) > 14 and (
(select 2 from (select cdpp.ConferenceDayReservationID as x2, count(cdpp.ParticipantID) as y2
					   from ConferenceDayParticipants cdpp
					   inner join Participants p
							on P.ParticipantID = cdpp.ParticipantID
					   inner join Students
							on p.ParticipantID = students.ParticipantID
					   where LastName is null
					   group by cdpp.ConferenceDayReservationID) as t where t.x2 = cdp.ConferenceDayReservationID) > 0
					   or
(select 2 from (select cdpp.ConferenceDayReservationID as x1, count(cdpp.ParticipantID) as y1
					   from ConferenceDayParticipants cdpp
					   inner join Participants p
							on P.ParticipantID = cdpp.ParticipantID
					   left join Students
							on p.ParticipantID = students.ParticipantID
					   where LastName is null and students.ParticipantID is null
					   group by cdpp.ConferenceDayReservationID) as t where t.x1 = cdp.ConferenceDayReservationID) > 0)
GO
/****** Object:  UserDefinedFunction [dbo].[BaseDayPrices]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[BaseDayPrices] (@ReservationID INT)  
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT c.ConferenceID, c.BasePriceForDay
	FROM ConferenceDayReservation cdr
	JOIN ConferenceDays cd
	ON cd.ConferenceDayID = cdr.ConferenceDayID
	JOIN Conferences c
	ON cd.ConferenceID = c.ConferenceID
	WHERE cdr.ReservationID = @ReservationID
);
GO
/****** Object:  UserDefinedFunction [dbo].[StudentDiscountForReservations]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[StudentDiscountForReservations] (@ReservationID int)  
returns table
as
return
(
    SELECT distinct c.ConferenceID, c.StudentDiscount
	from ConferenceDayReservation cdr
	join ConferenceDays cd
	on cd.ConferenceDayID = cdr.ConferenceDayID
	join Conferences c
	on cd.ConferenceID = c.ConferenceID
	where cdr.ReservationID = @ReservationID
);
GO
/****** Object:  Table [dbo].[ConferencePricetables]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConferencePricetables](
	[PriceID] [int] IDENTITY(0,1) NOT NULL,
	[ConferenceID] [int] NOT NULL,
	[PriceStartsOn] [date] NOT NULL,
	[PriceEndsOn] [date] NOT NULL,
	[DiscountRate] [real] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PriceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[DiscountForReservations]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[DiscountForReservations] (@DateOrdered date, @ReservationID int)  
returns table
as
return
(
    SELECT distinct c.ConferenceID, dbo.DiscountForConference(@DateOrdered, c.ConferenceID) as Discount
	from ConferenceDayReservation cdr
	join ConferenceDays cd
	on cd.ConferenceDayID = cdr.ConferenceDayID
	join Conferences c
	on cd.ConferenceID = c.ConferenceID
	left join ConferencePricetables cp
	on c.ConferenceID = cp.ConferenceID
	where cdr.ReservationID = @ReservationID
	group by c.ConferenceID
);
GO
/****** Object:  UserDefinedFunction [dbo].[ReservationPrices]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[ReservationPrices] (@DateOrdered date, @ReservationID int)  
returns table
as
return
(
    select base.ConferenceID, base.BasePriceForDay * dis.Discount as AdultPrice,
			base.BasePriceForDay * dis.Discount * stdis.StudentDiscount as StudentPrice
	from dbo.BaseDayPrices(@ReservationID) base
	join dbo.DiscountForReservations(@DateOrdered, @ReservationID) dis
	on
	base.ConferenceID = dis.ConferenceID
	join dbo.StudentDiscountForReservations(@ReservationID) stdis
	on dis.ConferenceID = stdis.ConferenceID
);
GO
/****** Object:  View [dbo].[ConferencesWithTimeDiscounts]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[ConferencesWithTimeDiscounts]
as
select c.ConferenceID, Name, StartDate, DiscountRate, PriceStartsOn, PriceEndsOn
from ConferencePricetables cp
join Conferences c
on cp.ConferenceID = c.ConferenceID
GO
/****** Object:  View [dbo].[FrequentCustomers]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[FrequentCustomers] AS
SELECT TOP 10 ISNULL(companyname,'') + ISNULL(firstname + ' ','') + ISNULL(lastname,'') AS 'Customer Name', 
			  COUNT(reservationid) AS 'Number of paid reservations', 
			  ISNULL(Participants.Email,'') + ISNULL(dbo.Companies.Email,'') AS 'E-mail',
			  ISNULL(dbo.Participants.Phone,'') + ISNULL(dbo.Companies.Phone,'') AS 'Phone'
FROM Customers
INNER JOIN ConferenceReservations
	ON Customers.CustomerID = ConferenceReservations.CustomerID
LEFT JOIN PrivateCustomers
	ON Customers.CustomerID = PrivateCustomers.CustomerID
LEFT JOIN Participants
	ON PrivateCustomers.ParticipantID = Participants.ParticipantID
LEFT JOIN Companies
	ON Customers.CustomerID = Companies.CompanyID
WHERE DatePaid IS NOT NULL
GROUP BY firstname, lastname, companyname, dbo.Participants.Email, dbo.Companies.Email, dbo.Companies.Phone, dbo.Participants.Phone
ORDER by count(ReservationID) desc
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_Email]    Script Date: 22/01/2019 15:56:07 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Email] ON [dbo].[Participants]
(
	[Phone] ASC
)
WHERE ([Phone] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ConferenceDayReservation] ADD  CONSTRAINT [DEF_NUMBER_OF_STUDENT_SEATS]  DEFAULT ((0)) FOR [ReservedAdultSeats]
GO
ALTER TABLE [dbo].[ConferenceDayReservation] ADD  CONSTRAINT [DEF_NUMBER_OF_ADULT_SEATS]  DEFAULT ((0)) FOR [ReservedStudentSeats]
GO
ALTER TABLE [dbo].[ConferenceDayWorkshops] ADD  CONSTRAINT [DEF_WKSH_PRICE]  DEFAULT ((0)) FOR [Price]
GO
ALTER TABLE [dbo].[ConferencePricetables] ADD  CONSTRAINT [DEF_DISCOUNT]  DEFAULT ((0)) FOR [DiscountRate]
GO
ALTER TABLE [dbo].[ConferenceReservations] ADD  CONSTRAINT [DEF_ORDER_DATE]  DEFAULT (CONVERT([date],getdate())) FOR [DateOrdered]
GO
ALTER TABLE [dbo].[Conferences] ADD  CONSTRAINT [DEF_CONF_PRICE]  DEFAULT ((0)) FOR [BasePriceForDay]
GO
ALTER TABLE [dbo].[Conferences] ADD  CONSTRAINT [DEF_BASEPRICE]  DEFAULT ((0)) FOR [StudentDiscount]
GO
ALTER TABLE [dbo].[Conferences] ADD  CONSTRAINT [DEF_CREATE_DATE]  DEFAULT (CONVERT([date],getdate())) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[Cities]  WITH CHECK ADD  CONSTRAINT [FK__Cities__RegionID__7CD98669] FOREIGN KEY([RegionID])
REFERENCES [dbo].[Regions] ([RegionID])
GO
ALTER TABLE [dbo].[Cities] CHECK CONSTRAINT [FK__Cities__RegionID__7CD98669]
GO
ALTER TABLE [dbo].[Companies]  WITH NOCHECK ADD  CONSTRAINT [FK__Companies__Compa__1D7B6025] FOREIGN KEY([CompanyID])
REFERENCES [dbo].[Customers] ([CustomerID])
GO
ALTER TABLE [dbo].[Companies] CHECK CONSTRAINT [FK__Companies__Compa__1D7B6025]
GO
ALTER TABLE [dbo].[ConferenceDayParticipants]  WITH CHECK ADD  CONSTRAINT [FK__Conferenc__Confe__6CA31EA0] FOREIGN KEY([ConferenceDayReservationID])
REFERENCES [dbo].[ConferenceDayReservation] ([DayReservationID])
GO
ALTER TABLE [dbo].[ConferenceDayParticipants] CHECK CONSTRAINT [FK__Conferenc__Confe__6CA31EA0]
GO
ALTER TABLE [dbo].[ConferenceDayParticipants]  WITH CHECK ADD  CONSTRAINT [FK__Conferenc__Parti__6ABAD62E] FOREIGN KEY([ParticipantID])
REFERENCES [dbo].[Participants] ([ParticipantID])
GO
ALTER TABLE [dbo].[ConferenceDayParticipants] CHECK CONSTRAINT [FK__Conferenc__Parti__6ABAD62E]
GO
ALTER TABLE [dbo].[ConferenceDayReservation]  WITH CHECK ADD  CONSTRAINT [FK__Conferenc__Confe__41B8C09B] FOREIGN KEY([ConferenceDayID])
REFERENCES [dbo].[ConferenceDays] ([ConferenceDayID])
GO
ALTER TABLE [dbo].[ConferenceDayReservation] CHECK CONSTRAINT [FK__Conferenc__Confe__41B8C09B]
GO
ALTER TABLE [dbo].[ConferenceDayReservation]  WITH CHECK ADD  CONSTRAINT [FK__Conferenc__Reser__66EA454A] FOREIGN KEY([ReservationID])
REFERENCES [dbo].[ConferenceReservations] ([ReservationID])
GO
ALTER TABLE [dbo].[ConferenceDayReservation] CHECK CONSTRAINT [FK__Conferenc__Reser__66EA454A]
GO
ALTER TABLE [dbo].[ConferenceDays]  WITH CHECK ADD  CONSTRAINT [FK__Conferenc__Confe__3EDC53F0] FOREIGN KEY([ConferenceID])
REFERENCES [dbo].[Conferences] ([ConferenceID])
GO
ALTER TABLE [dbo].[ConferenceDays] CHECK CONSTRAINT [FK__Conferenc__Confe__3EDC53F0]
GO
ALTER TABLE [dbo].[ConferenceDayWorkshops]  WITH NOCHECK ADD  CONSTRAINT [FK__Conferenc__Confe__4E1E9780] FOREIGN KEY([ConferenceDayID])
REFERENCES [dbo].[ConferenceDays] ([ConferenceDayID])
GO
ALTER TABLE [dbo].[ConferenceDayWorkshops] CHECK CONSTRAINT [FK__Conferenc__Confe__4E1E9780]
GO
ALTER TABLE [dbo].[ConferenceDayWorkshops]  WITH NOCHECK ADD  CONSTRAINT [FK__Conferenc__Works__4F12BBB9] FOREIGN KEY([WorkshopID])
REFERENCES [dbo].[Workshops] ([WorkshopID])
GO
ALTER TABLE [dbo].[ConferenceDayWorkshops] CHECK CONSTRAINT [FK__Conferenc__Works__4F12BBB9]
GO
ALTER TABLE [dbo].[ConferenceEmployees]  WITH NOCHECK ADD  CONSTRAINT [FK__Conferenc__Confe__4865BE2A] FOREIGN KEY([ConferenceID])
REFERENCES [dbo].[Conferences] ([ConferenceID])
GO
ALTER TABLE [dbo].[ConferenceEmployees] CHECK CONSTRAINT [FK__Conferenc__Confe__4865BE2A]
GO
ALTER TABLE [dbo].[ConferenceEmployees]  WITH NOCHECK ADD  CONSTRAINT [FK__Conferenc__Emplo__4959E263] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[OurEmployees] ([EmployeeID])
GO
ALTER TABLE [dbo].[ConferenceEmployees] CHECK CONSTRAINT [FK__Conferenc__Emplo__4959E263]
GO
ALTER TABLE [dbo].[ConferencePricetables]  WITH CHECK ADD FOREIGN KEY([ConferenceID])
REFERENCES [dbo].[Conferences] ([ConferenceID])
GO
ALTER TABLE [dbo].[ConferenceReservations]  WITH NOCHECK ADD  CONSTRAINT [FK__Conferenc__Custo__65F62111] FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customers] ([CustomerID])
GO
ALTER TABLE [dbo].[ConferenceReservations] CHECK CONSTRAINT [FK__Conferenc__Custo__65F62111]
GO
ALTER TABLE [dbo].[Conferences]  WITH CHECK ADD FOREIGN KEY([CityID])
REFERENCES [dbo].[Cities] ([CityID])
GO
ALTER TABLE [dbo].[Customers]  WITH NOCHECK ADD FOREIGN KEY([CityID])
REFERENCES [dbo].[Cities] ([CityID])
GO
ALTER TABLE [dbo].[EmployeesOfCompanies]  WITH CHECK ADD  CONSTRAINT [FK__Employees__Compa__2CBDA3B5] FOREIGN KEY([CompanyID])
REFERENCES [dbo].[Companies] ([CompanyID])
GO
ALTER TABLE [dbo].[EmployeesOfCompanies] CHECK CONSTRAINT [FK__Employees__Compa__2CBDA3B5]
GO
ALTER TABLE [dbo].[EmployeesOfCompanies]  WITH CHECK ADD  CONSTRAINT [FK__Employees__Parti__2BC97F7C] FOREIGN KEY([ParticipantID])
REFERENCES [dbo].[Participants] ([ParticipantID])
GO
ALTER TABLE [dbo].[EmployeesOfCompanies] CHECK CONSTRAINT [FK__Employees__Parti__2BC97F7C]
GO
ALTER TABLE [dbo].[OurEmployees]  WITH NOCHECK ADD FOREIGN KEY([CityID])
REFERENCES [dbo].[Cities] ([CityID])
GO
ALTER TABLE [dbo].[PrivateCustomers]  WITH NOCHECK ADD  CONSTRAINT [FK__PrivateCu__Custo__0B27A5C0] FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customers] ([CustomerID])
GO
ALTER TABLE [dbo].[PrivateCustomers] CHECK CONSTRAINT [FK__PrivateCu__Custo__0B27A5C0]
GO
ALTER TABLE [dbo].[PrivateCustomers]  WITH NOCHECK ADD  CONSTRAINT [FK__PrivateCu__Parti__0C1BC9F9] FOREIGN KEY([ParticipantID])
REFERENCES [dbo].[Participants] ([ParticipantID])
GO
ALTER TABLE [dbo].[PrivateCustomers] CHECK CONSTRAINT [FK__PrivateCu__Parti__0C1BC9F9]
GO
ALTER TABLE [dbo].[Regions]  WITH CHECK ADD  CONSTRAINT [FK__Regions__Country__79FD19BE] FOREIGN KEY([CountryID])
REFERENCES [dbo].[Countries] ([CountryID])
GO
ALTER TABLE [dbo].[Regions] CHECK CONSTRAINT [FK__Regions__Country__79FD19BE]
GO
ALTER TABLE [dbo].[Students]  WITH CHECK ADD  CONSTRAINT [FK__Student__Partici__28ED12D1] FOREIGN KEY([ParticipantID])
REFERENCES [dbo].[Participants] ([ParticipantID])
GO
ALTER TABLE [dbo].[Students] CHECK CONSTRAINT [FK__Student__Partici__28ED12D1]
GO
ALTER TABLE [dbo].[WorkshopParticipants]  WITH CHECK ADD  CONSTRAINT [FK__WorkshopP__Confe__54CB950F] FOREIGN KEY([ConferenceDayParticipantID])
REFERENCES [dbo].[ConferenceDayParticipants] ([ConferenceDayParticipantID])
GO
ALTER TABLE [dbo].[WorkshopParticipants] CHECK CONSTRAINT [FK__WorkshopP__Confe__54CB950F]
GO
ALTER TABLE [dbo].[WorkshopParticipants]  WITH CHECK ADD  CONSTRAINT [FK__WorkshopP__Confe__55BFB948] FOREIGN KEY([ConferenceDayWorkshopID])
REFERENCES [dbo].[ConferenceDayWorkshops] ([ConferenceDayWorkshopID])
GO
ALTER TABLE [dbo].[WorkshopParticipants] CHECK CONSTRAINT [FK__WorkshopP__Confe__55BFB948]
GO
ALTER TABLE [dbo].[WorkshopReservation]  WITH CHECK ADD  CONSTRAINT [FK__WorkshopR__Confe__6F7F8B4B] FOREIGN KEY([ConferenceDayWorkshopID])
REFERENCES [dbo].[ConferenceDayWorkshops] ([ConferenceDayWorkshopID])
GO
ALTER TABLE [dbo].[WorkshopReservation] CHECK CONSTRAINT [FK__WorkshopR__Confe__6F7F8B4B]
GO
ALTER TABLE [dbo].[WorkshopReservation]  WITH CHECK ADD  CONSTRAINT [FK__WorkshopR__Confe__7073AF84] FOREIGN KEY([ConferenceDayReservationID])
REFERENCES [dbo].[ConferenceDayReservation] ([DayReservationID])
GO
ALTER TABLE [dbo].[WorkshopReservation] CHECK CONSTRAINT [FK__WorkshopR__Confe__7073AF84]
GO
ALTER TABLE [dbo].[Companies]  WITH NOCHECK ADD  CONSTRAINT [CHK_NIP] CHECK  ((NOT [NIP] like '%[^0-9]%'))
GO
ALTER TABLE [dbo].[Companies] CHECK CONSTRAINT [CHK_NIP]
GO
ALTER TABLE [dbo].[Companies]  WITH NOCHECK ADD  CONSTRAINT [EmailFormat2] CHECK  (([Email] like '%_@__%.__%'))
GO
ALTER TABLE [dbo].[Companies] CHECK CONSTRAINT [EmailFormat2]
GO
ALTER TABLE [dbo].[Companies]  WITH NOCHECK ADD  CONSTRAINT [PhoneFormat] CHECK  ((NOT [phone] like '%[^0-9]%'))
GO
ALTER TABLE [dbo].[Companies] CHECK CONSTRAINT [PhoneFormat]
GO
ALTER TABLE [dbo].[ConferenceDayReservation]  WITH CHECK ADD  CONSTRAINT [CHK_ORDER_EARLIER_THAN_CONF] CHECK  (([dbo].[ReservationEarlierThanConferenceDay]([ConferenceDayID],[ReservationID])>(0)))
GO
ALTER TABLE [dbo].[ConferenceDayReservation] CHECK CONSTRAINT [CHK_ORDER_EARLIER_THAN_CONF]
GO
ALTER TABLE [dbo].[ConferenceDayReservation]  WITH CHECK ADD  CONSTRAINT [CHK_ORDERED_AFTER_CREATED] CHECK  (([dbo].[ConferenceOrderedAfterCreated]([ConferenceDayID],[ReservationID])>=(0)))
GO
ALTER TABLE [dbo].[ConferenceDayReservation] CHECK CONSTRAINT [CHK_ORDERED_AFTER_CREATED]
GO
ALTER TABLE [dbo].[ConferenceDayReservation]  WITH CHECK ADD  CONSTRAINT [CHK_RESERVATION] CHECK  (([ReservedAdultSeats]>=(0) AND [ReservedStudentSeats]>=(0) AND ([ReservedAdultSeats]+[ReservedStudentSeats])>(0)))
GO
ALTER TABLE [dbo].[ConferenceDayReservation] CHECK CONSTRAINT [CHK_RESERVATION]
GO
ALTER TABLE [dbo].[ConferenceDayReservation]  WITH CHECK ADD  CONSTRAINT [CHK_RESERVED_BY_COMPANY_OR_ONE] CHECK  (([dbo].[IsReservationByCompany]([ReservationID])=(1) OR ([ReservedAdultSeats]+[ReservedStudentSeats])=(1)))
GO
ALTER TABLE [dbo].[ConferenceDayReservation] CHECK CONSTRAINT [CHK_RESERVED_BY_COMPANY_OR_ONE]
GO
ALTER TABLE [dbo].[ConferenceDayReservation]  WITH CHECK ADD  CONSTRAINT [CHK_SIZE_OK] CHECK  (([dbo].[ReservedSeatsPerConferenceDay]([ConferenceDayID])<=[dbo].[ConferenceSize]([ConferenceDayID])))
GO
ALTER TABLE [dbo].[ConferenceDayReservation] CHECK CONSTRAINT [CHK_SIZE_OK]
GO
ALTER TABLE [dbo].[ConferenceDays]  WITH CHECK ADD  CONSTRAINT [CHK_DAY_ORDINAL] CHECK  (([dayordinal]>(0)))
GO
ALTER TABLE [dbo].[ConferenceDays] CHECK CONSTRAINT [CHK_DAY_ORDINAL]
GO
ALTER TABLE [dbo].[ConferenceDayWorkshops]  WITH NOCHECK ADD  CONSTRAINT [CHK_SIZE_SMALLER_THAN_CONF] CHECK  (([dbo].[ConferenceSize]([ConferenceDayID])>=[ParticipantsLimit]))
GO
ALTER TABLE [dbo].[ConferenceDayWorkshops] CHECK CONSTRAINT [CHK_SIZE_SMALLER_THAN_CONF]
GO
ALTER TABLE [dbo].[ConferenceDayWorkshops]  WITH NOCHECK ADD  CONSTRAINT [CHK_SIZES_NON_NEGATIVE] CHECK  (([ParticipantsLimit]>(0) AND [price]>=(0)))
GO
ALTER TABLE [dbo].[ConferenceDayWorkshops] CHECK CONSTRAINT [CHK_SIZES_NON_NEGATIVE]
GO
ALTER TABLE [dbo].[ConferenceDayWorkshops]  WITH NOCHECK ADD  CONSTRAINT [CHK_TIME] CHECK  (([StartTime]<[EndTime]))
GO
ALTER TABLE [dbo].[ConferenceDayWorkshops] CHECK CONSTRAINT [CHK_TIME]
GO
ALTER TABLE [dbo].[ConferenceEmployees]  WITH NOCHECK ADD  CONSTRAINT [CHK_ORGANISED_NO_LATER_THAN_HIRED] CHECK  (([dbo].[OrganisedLaterThanHired]([EmployeeID],[ConferenceID])>=(0)))
GO
ALTER TABLE [dbo].[ConferenceEmployees] CHECK CONSTRAINT [CHK_ORGANISED_NO_LATER_THAN_HIRED]
GO
ALTER TABLE [dbo].[ConferencePricetables]  WITH CHECK ADD  CONSTRAINT [CHK_NEW_PRICE_AT_THE_DAY_AFTER_PREVIOUS] CHECK  (([dbo].[NewPriceAtTheDayAfterPrevious]([ConferenceID])=(1)))
GO
ALTER TABLE [dbo].[ConferencePricetables] CHECK CONSTRAINT [CHK_NEW_PRICE_AT_THE_DAY_AFTER_PREVIOUS]
GO
ALTER TABLE [dbo].[ConferencePricetables]  WITH CHECK ADD CHECK  (([DiscountRate]>=(0) AND [DiscountRate]<=(1)))
GO
ALTER TABLE [dbo].[ConferencePricetables]  WITH CHECK ADD  CONSTRAINT [CK_Date_no_further_than_conference_start_date] CHECK  (([PriceEndsOn]<=[dbo].[GetConferenceStartDate]([ConferenceID])))
GO
ALTER TABLE [dbo].[ConferencePricetables] CHECK CONSTRAINT [CK_Date_no_further_than_conference_start_date]
GO
ALTER TABLE [dbo].[ConferencePricetables]  WITH CHECK ADD  CONSTRAINT [CK_Lowering_Discount] CHECK  (([DiscountRate]<=[dbo].[GetLatestDiscount]([ConferenceID])))
GO
ALTER TABLE [dbo].[ConferencePricetables] CHECK CONSTRAINT [CK_Lowering_Discount]
GO
ALTER TABLE [dbo].[ConferenceReservations]  WITH NOCHECK ADD  CONSTRAINT [CHK_PAID_SEVEN_DAYS_OR_FASTER] CHECK  ((datediff(day,[DateOrdered],[DatePaid])<=(7)))
GO
ALTER TABLE [dbo].[ConferenceReservations] CHECK CONSTRAINT [CHK_PAID_SEVEN_DAYS_OR_FASTER]
GO
ALTER TABLE [dbo].[Conferences]  WITH CHECK ADD  CONSTRAINT [CHK_CONF_DATES] CHECK  ((datediff(day,[StartDate],[EndDate])>=(0)))
GO
ALTER TABLE [dbo].[Conferences] CHECK CONSTRAINT [CHK_CONF_DATES]
GO
ALTER TABLE [dbo].[Conferences]  WITH CHECK ADD  CONSTRAINT [CHK_CONF_PARTICIP] CHECK  (([ParticipantsLimit]>(0)))
GO
ALTER TABLE [dbo].[Conferences] CHECK CONSTRAINT [CHK_CONF_PARTICIP]
GO
ALTER TABLE [dbo].[Conferences]  WITH CHECK ADD  CONSTRAINT [CHK_CONF_PRICE] CHECK  (([BasePriceForDay]>=(0)))
GO
ALTER TABLE [dbo].[Conferences] CHECK CONSTRAINT [CHK_CONF_PRICE]
GO
ALTER TABLE [dbo].[Conferences]  WITH CHECK ADD CHECK  (([PostalCode] like '[0-9][0-9]-[0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[Conferences]  WITH CHECK ADD  CONSTRAINT [CK__Conferenc__Stude__336AA144] CHECK  (([StudentDiscount]>=(0) AND [StudentDiscount]<=(1)))
GO
ALTER TABLE [dbo].[Conferences] CHECK CONSTRAINT [CK__Conferenc__Stude__336AA144]
GO
ALTER TABLE [dbo].[Customers]  WITH NOCHECK ADD CHECK  (([PostalCode] like '[0-9][0-9]-[0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[OurEmployees]  WITH NOCHECK ADD  CONSTRAINT [CHK_EMP_PHONE] CHECK  ((NOT [Phone] like '%[^0-9]%'))
GO
ALTER TABLE [dbo].[OurEmployees] CHECK CONSTRAINT [CHK_EMP_PHONE]
GO
ALTER TABLE [dbo].[OurEmployees]  WITH NOCHECK ADD CHECK  (([Email] like '%_@_%._%'))
GO
ALTER TABLE [dbo].[OurEmployees]  WITH NOCHECK ADD CHECK  (([PostalCode] like '[0-9][0-9]-[0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[Participants]  WITH NOCHECK ADD  CONSTRAINT [EmailFormat] CHECK  (([Email] like '%_@__%.__%'))
GO
ALTER TABLE [dbo].[Participants] CHECK CONSTRAINT [EmailFormat]
GO
ALTER TABLE [dbo].[Participants]  WITH NOCHECK ADD  CONSTRAINT [PhoneFormat2] CHECK  ((NOT [phone] like '%[^0-9]%'))
GO
ALTER TABLE [dbo].[Participants] CHECK CONSTRAINT [PhoneFormat2]
GO
ALTER TABLE [dbo].[WorkshopParticipants]  WITH CHECK ADD  CONSTRAINT [CHK_FREE_SEATS] CHECK  (([dbo].[EmptySeatsInWorkshopReservation]([ConferenceDayParticipantID],[ConferenceDayWorkshopID])>=(0)))
GO
ALTER TABLE [dbo].[WorkshopParticipants] CHECK CONSTRAINT [CHK_FREE_SEATS]
GO
ALTER TABLE [dbo].[WorkshopParticipants]  WITH CHECK ADD  CONSTRAINT [CHK_PARTICIPANT_NOT_IN_ANOTHER_WORKSHOP] CHECK  (([dbo].[HasParticipantCollidingWorkshops]([ConferenceDayWorkshopID],[ConferenceDayParticipantID])=(0)))
GO
ALTER TABLE [dbo].[WorkshopParticipants] CHECK CONSTRAINT [CHK_PARTICIPANT_NOT_IN_ANOTHER_WORKSHOP]
GO
ALTER TABLE [dbo].[WorkshopReservation]  WITH CHECK ADD  CONSTRAINT [CHK_ENOUGH_FREE_SEATS] CHECK  (([dbo].[ReservedSeatsForWorkshop]([ConferenceDayWorkshopID])<=[dbo].[WorkshopSeatsLimit]([ConferenceDayWorkshopID])))
GO
ALTER TABLE [dbo].[WorkshopReservation] CHECK CONSTRAINT [CHK_ENOUGH_FREE_SEATS]
GO
ALTER TABLE [dbo].[WorkshopReservation]  WITH CHECK ADD  CONSTRAINT [CHK_RESERVING_WORKSHOP_AT_CORRECT_CONF_DAY] CHECK  (([dbo].[WorkshopReservationOnDayReservationConference]([ConferenceDayReservationID],[ConferenceDayWorkshopID])=(0)))
GO
ALTER TABLE [dbo].[WorkshopReservation] CHECK CONSTRAINT [CHK_RESERVING_WORKSHOP_AT_CORRECT_CONF_DAY]
GO
ALTER TABLE [dbo].[WorkshopReservation]  WITH CHECK ADD  CONSTRAINT [CHK_WORKSHOP_RESERV_NON_NEGATIVE] CHECK  (([ReservedSeats]>(0)))
GO
ALTER TABLE [dbo].[WorkshopReservation] CHECK CONSTRAINT [CHK_WORKSHOP_RESERV_NON_NEGATIVE]
GO
ALTER TABLE [dbo].[WorkshopReservation]  WITH CHECK ADD  CONSTRAINT [CHK_WORKSHOP_RESERV_NOT_GREATER_THAN_DAY_RESERV] CHECK  (([ReservedSeats]<=[dbo].[ConferenceDayReservationSize]([ConferenceDayReservationID])))
GO
ALTER TABLE [dbo].[WorkshopReservation] CHECK CONSTRAINT [CHK_WORKSHOP_RESERV_NOT_GREATER_THAN_DAY_RESERV]
GO
/****** Object:  StoredProcedure [dbo].[AddOurEmployee]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[AddOurEmployee]
	@FirstName varchar(30),
	@LastName varchar(50),
	@BirthDate date,
	@HireDate date,
	@Phone varchar(15),
	@Street varchar(74),
	@HouseNumber varchar(5),
	@AppartmentNumber int,
	@CityName varchar(80),
	@RegionName varchar(80),
	@CountryName varchar(80),
	@PostalCode char(6),
	@Email varchar(100)
as
begin
	declare @CityID int
	exec FindCity @CityName, @RegionName, @CountryName, @CityID
	insert into OurEmployees (FirstName, LastName, BirthDate, HireDate, Phone, Street ,HouseNumber ,AppartmentNumber ,CityID ,PostalCode ,Email)
	values (
		@FirstName, @LastName, @BirthDate, @HireDate, @Phone, @Street, @HouseNumber, @AppartmentNumber, @CityID, @PostalCode, @Email
	)
end
GO
/****** Object:  StoredProcedure [dbo].[AddParticipantToWorkshop]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddParticipantToWorkshop]
	@ParticipantEmail VARCHAR(100),
	@ConferenceName VARCHAR(200),
	@Date DATE,
	@CustomerEmail VARCHAR(100),
	@DateOrdered DATE,
	@WorkshopName VARCHAR(200),
	@StartTime TIME
AS
BEGIN
BEGIN TRY
	BEGIN TRAN tr
		DECLARE @ConferenceDayParticipantID INT, @ParticipantID INT, @ConferenceDayReservationID INT
        EXEC @ParticipantID = dbo.FindParticipantByEmail @Email = @ParticipantEmail -- varchar(100)
        EXEC dbo.FindConferenceDayReservation @ConferenceName = @ConferenceName,                                             -- varchar(200)
                                              @ConfDayDate = @Date,                                      -- date
                                              @CustomerEmail = @CustomerEmail,                                              -- varchar(100)
                                              @DateOrdered = @DateOrdered,                                      -- date
                                              @ConferenceDayReservationID = @ConferenceDayReservationID OUTPUT -- int
        -- Znaleźć ConferenceDayParticipantID do dodania
		SELECT @ConferenceDayParticipantID = ConferenceDayParticipantID
		FROM dbo.ConferenceDayParticipants
		WHERE ParticipantID = @ParticipantID AND ConferenceDayReservationID = @ConferenceDayReservationID
		PRINT 'DayParticipantID ' + CAST (@ConferenceDayParticipantID AS VARCHAR)
		-- Znaleźć ConferenceDayWorkshopID
		DECLARE @ConferenceDayWorkshopID INT;
		EXEC dbo.FindWorkshopInDay @ConferenceName = @ConferenceName,                                      -- varchar(200)
		                           @Date = @Date,                                      -- date
		                           @WorkshopName = @WorkshopName,                             -- varchar(200)
								   @StartTime = @StartTime,
		                           @ConferenceDayWorkshopID = @ConferenceDayWorkshopID OUTPUT -- int
		PRINT 'ConferenceDayWorkshopID ' + CAST(@ConferenceDayWorkshopID AS VARCHAR)
	
		INSERT INTO dbo.WorkshopParticipants
		(
		    ConferenceDayParticipantID,
		    ConferenceDayWorkshopID
		)
		VALUES
		(   @ConferenceDayParticipantID, -- ConferenceDayParticipantID - int
		    @ConferenceDayWorkshopID  -- ConferenceDayWorkshopID - int
		    )
	COMMIT TRAN tr
END TRY
BEGIN CATCH
	PRINT ERROR_MESSAGE()
	ROLLBACK TRAN tr
END CATCH
END

GO
/****** Object:  StoredProcedure [dbo].[AddPriceStep]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[AddPriceStep]
	@ConferenceName varchar(200),
	@ConferenceStartDate date,
	@PriceStartsOn date,
	@PriceEndsOn date,
	@DiscountRate real
as
declare @ConferenceID int, @c int
exec FindConference @ConferenceName, @ConferenceStartDate, @ConferenceID output, @c
begin
	if @ConferenceID is null
	begin
		print 'Nie znaleziono konferencji'
		return
	end
	insert into ConferencePricetables (ConferenceID, PriceStartsOn, PriceEndsOn, DiscountRate)
	values (@ConferenceID, @PriceStartsOn, @PriceEndsOn, @DiscountRate)
end
GO
/****** Object:  StoredProcedure [dbo].[AddPrivateCustomer]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[AddPrivateCustomer]
	@FirstName VARCHAR(30),
	@LastName VARCHAR(50),
	@ParticipantPhone nvarchar(15),
	@Email VARCHAR(100),
	@Street nvarchar(80),
	@HouseNumber nvarchar(5),
	@AppartmentNumber int,
	@PostalCode char(6),
	@CityName varchar(80),
	@RegionName varchar(80),
	@CountryName varchar(80)
as
begin
begin try
	begin tran tr
		DECLARE @NewParticipantID int
		EXEC dbo.NewParticipant @FirstName, -- varchar(30)
		                        @LastName,  -- varchar(50)
		                        @ParticipantPhone,     -- varchar(15)
		                        @Email,      -- varchar(50)
								@NewParticipantID OUTPUT
		declare @CityID int
		exec FindCity @CityName, @RegionName, @CountryName, @CityID output
		insert into Customers (Street, HouseNumber, AppartmentNumber, PostalCode, CityID)
		values (
			@Street, @HouseNumber, @AppartmentNumber, @PostalCode, @CityID
		)
		insert into PrivateCustomers (ParticipantID, CustomerID)
		values (
			@NewParticipantID, (select max(CustomerID) from Customers)
		)
	commit tran find
end try
begin catch
	rollback tran tr
end catch
end
GO
/****** Object:  StoredProcedure [dbo].[AddWorkshopAtDay]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[AddWorkshopAtDay]
	@WorkshopName varchar(100),
	@ConferenceName varchar(200),
	@Day smallint,
	@StartTime time,
	@EndTime time,
	@Price money,
	@ParticipantsLimit int
as
declare @ConferenceDayID int,
		@WorkshopID int;
begin
	set @WorkshopID = (select WorkshopID from Workshops where Name = @WorkshopName)
	if @WorkshopID is null begin
		print 'Brak warsztatu o podanej nazwie w bazie'
		return
	end
	set @ConferenceDayID = (select ConferenceDayID
							from ConferenceDays
							where DayOrdinal = @Day and
								  ConferenceID = (select ConferenceID
												  from Conferences
												  where Name = @ConferenceName))
	if @ConferenceDayID is null begin
		print 'Nie znaleziono konferencji'
		return
	end
	insert into ConferenceDayWorkshops (ConferenceDayID, WorkshopID, StartTime, EndTime, Price, ParticipantsLimit)
	values (
			@ConferenceDayID,
			@WorkshopID,
			@StartTime,
			@EndTime,
			@Price,
			@ParticipantsLimit
		   )
end
GO
/****** Object:  StoredProcedure [dbo].[BindOurEmployeeWithConference]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[BindOurEmployeeWithConference]
	@EmpEmail VARCHAR(100),
	@ConferenceName varchar(200)
as
begin
	insert into ConferenceEmployees (EmployeeID, ConferenceID) values (
		(select EmployeeID from OurEmployees where Email = @EmpEmail),
		(select ConferenceID from Conferences where Name = @ConferenceName)
	)
end
GO
/****** Object:  StoredProcedure [dbo].[BindParticipantWithCompany]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[BindParticipantWithCompany]
	@Email varchar(100),
	@NIP char(10)
as
declare @ParticipantID int,
		@CompanyID int;
exec @ParticipantID = FindParticipantByEmail @Email;
EXEC @CompanyID = dbo.FindCompanyByNIP @NIP = @NIP -- char(10)

begin
insert into EmployeesOfCompanies (ParticipantID, CompanyID)
values (
	@ParticipantID,
	@CompanyID
)
end
GO
/****** Object:  StoredProcedure [dbo].[DeleteUnpaidReservations]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[DeleteUnpaidReservations] as
begin
begin try
	begin tran tr
		delete from ConferenceReservations
		where DatePaid is null and DATEDIFF(day, DateOrdered, convert(date, getdate())) > 7
	commit tran tr
end try
begin catch rollback tran tr end catch
end -- dopisać trigger usuwający rezerwację dni konferencji, warsztatów itd.
GO
/****** Object:  StoredProcedure [dbo].[EmptySeatsInWorkshopReservation2]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[EmptySeatsInWorkshopReservation2] @DayParticipantID INT, @ConferenceDayWorkshopID INT, @SeatsReserved INT OUTPUT as
BEGIN
	DECLARE @SeatsOccupied INT, @DayReservationID INT
    SELECT @DayReservationID = ConferenceDayReservationID
	FROM dbo.ConferenceDayParticipants
	WHERE ConferenceDayParticipantID = @DayParticipantID
	PRINT CAST (@DayReservationID AS VARCHAR)
	SELECT @SeatsReserved = ReservedSeats
	FROM dbo.WorkshopReservation
	WHERE ConferenceDayReservationID = @DayReservationID AND ConferenceDayWorkshopID = @ConferenceDayWorkshopID
	PRINT CAST(@SeatsReserved AS VARCHAR)
	SELECT @SeatsOccupied = COUNT(*)
	FROM dbo.WorkshopParticipants
	WHERE ConferenceDayWorkshopID = @ConferenceDayWorkshopID
	PRINT CAST(@SeatsOccupied AS VARCHAR)
	IF @SeatsReserved IS NULL BEGIN
		SET @SeatsReserved = -1
		RETURN -1
	end
	RETURN (@SeatsReserved - @SeatsOccupied)
END
GO
/****** Object:  StoredProcedure [dbo].[FillReservation]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FillReservation]
	@CustomerEmail VARCHAR(100),
	@DateOrdered DATE,
	@ConferenceName VARCHAR(200),
	@ConfDayDate DATE,
	@FirstName VARCHAR(30),
	@LastName VARCHAR(50),
	@ParticipantPhone VARCHAR(15),
	@ParticipantEmail VARCHAR(100),
	@StudentCardNumber VARCHAR(10),
	@ParticipantID INT OUTPUT
AS
BEGIN
BEGIN TRY
	BEGIN TRANSACTION tr
		-- Wyszukaj czy w bazie nie ma już uczestnika o takim mailu
		DECLARE @FoundID int
		EXEC @FoundID = dbo.FindParticipantByEmail @Email = @ParticipantEmail -- varchar(100)

		-- Sprawdź czy dane są pełne
		IF (@FirstName IS NULL OR @LastName IS NULL OR @ParticipantEmail IS NULL) AND @FoundID IS null BEGIN
			RAISERROR ('Dane niepełne', 11,1)
		END

		-- Znajdź rezerwację dnia
		DECLARE @ReservationID INT
		EXEC FindConferenceDayReservation @ConferenceName, @ConfDayDate, @CustomerEmail, @DateOrdered, @ReservationID output
		IF @ReservationID IS NULL BEGIN 
			RAISERROR ('Nie znaleziono rezerwacji', 11,1)
		END

		-- Znajdź wszystkie nieuzupełnione ParticipantID z tej rezerwacji
		DECLARE @EmptyParticipantIDs TABLE (ParticipantID INT NOT NULL)
		INSERT INTO @EmptyParticipantIDs (ParticipantID)
			SELECT cdp.ParticipantID
			FROM dbo.ConferenceDayParticipants cdp
			INNER JOIN dbo.Participants ON Participants.ParticipantID = cdp.ParticipantID
			WHERE ConferenceDayReservationID = @ReservationID AND LastName IS NULL
		DECLARE @size INT = (SELECT COUNT(*) FROM @EmptyParticipantIDs)
		
		-- Wybierz ID które trzeba uzupełnić
		IF @StudentCardNumber IS NULL
			SET @ParticipantID = (SELECT MIN(ParticipantID) FROM (SELECT * FROM @EmptyParticipantIDs EXCEPT SELECT ParticipantID FROM dbo.Students) t);
		ELSE
			SET @ParticipantID = (SELECT MIN(ParticipantID) FROM (SELECT * FROM @EmptyParticipantIDs INTERSECT SELECT ParticipantID FROM dbo.Students) t);
		
		IF @ParticipantID IS NULL AND @StudentCardNumber IS NULL RAISERROR ('Już nie ma miejsc dla dorosłych',11,1)
		IF @ParticipantID IS NULL AND @StudentCardNumber IS NOT NULL RAISERROR ('Już nie ma miejsc dla studentów',11,1)

		-- Jeśli jest jeszcze nieuzupełniona rezerwacja
		IF @ParticipantID IS NOT NULL BEGIN 
			-- Jeśli już jest uczestnik o takim mailu
			IF @FoundID IS NOT NULL BEGIN
				UPDATE ConferenceDayParticipants
					SET ParticipantID = @FoundID
					WHERE ParticipantID = @ParticipantID AND ConferenceDayReservationID = @ReservationID
			END ELSE BEGIN 
				UPDATE dbo.Participants
					SET FirstName = @FirstName, LastName = @LastName, Email = @ParticipantEmail, Phone = @ParticipantPhone 
					WHERE ParticipantID = @ParticipantID
				UPDATE dbo.Students
					SET StudentCardNumber = @StudentCardNumber
					WHERE ParticipantID = @ParticipantID
				
			END 
		END
		
	COMMIT TRANSACTION tr
END TRY
BEGIN CATCH
	PRINT ERROR_MESSAGE()
	ROLLBACK TRAN tr
END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[FindCity]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[FindCity]
	@CityName nvarchar(80),
	@RegionName nvarchar(80),
	@CountryName nvarchar(80),
	@CityID int output
as
begin
begin try
	begin tran find
		if @RegionName is null or @CountryName is null raiserror (15600, -1,-1, 'FindCity')
		set @CityID = (select Cityid
					   from Cities
					   inner join Regions on Cities.RegionID = Regions.RegionID
					   inner join Countries on Countries.CountryID = Regions.CountryID
					   where CityName = @CityName and RegionName = @RegionName and CountryName = @CountryName)
		if @CityID is null begin
			declare @RegionID int 
			exec FindRegion @RegionName, @CountryName, @RegionID output
			insert into Cities (CityName, RegionID) values (@CityName, @RegionID)
			set @CityID = (select max(CityID) from Cities)
		end
	commit tran find
end try
begin catch
	rollback tran find
end catch
end
GO
/****** Object:  StoredProcedure [dbo].[FindConference]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[FindConference]
	@ConferenceName varchar(200),
	@Date date,
	@ConferenceID int output,
	@ConferenceDayID int output
as
begin
begin try
	begin tran tr
		select @ConferenceID = Conferences.ConferenceID
		from Conferences
		inner join ConferenceDays on Conferences.ConferenceID = ConferenceDays.ConferenceID
		where name = @ConferenceName AND (@date BETWEEN StartDate AND EndDate)
		if @ConferenceID is not null begin
			select @ConferenceDayID = ConferenceDayID
			from ConferenceDays
			where ConferenceID = @ConferenceID and Date = @Date
		end
	commit tran tr
end try
begin catch
	rollback tran tr
end catch
end
GO
/****** Object:  StoredProcedure [dbo].[FindConferenceDayReservation]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[FindConferenceDayReservation] 
	@ConferenceName VARCHAR(200), @ConfDayDate DATE, @CustomerEmail VARCHAR(100), @DateOrdered DATE,
	@ConferenceDayReservationID INT OUTPUT	
AS
BEGIN
	DECLARE @ConferenceDayID INT
	EXEC dbo.FindConference @ConferenceName = @ConferenceName,                       -- varchar(200)
	                        @Date = @ConfDayDate,                       -- date
	                        @ConferenceID = NULL,       -- int
	                        @ConferenceDayID = @ConferenceDayID OUTPUT -- int
	DECLARE @ReservationID INT;
	EXEC dbo.FindReservation @CustomerEmail = @CustomerEmail,                   -- varchar(100)
	                         @DateOrdered = @DateOrdered,           -- date
	                         @ReservationID = @ReservationID OUTPUT -- int
	(SELECT @ConferenceDayReservationID = DayReservationID
	FROM dbo.ConferenceDayReservation
	WHERE ReservationID = @ReservationID AND ConferenceDayID = @ConferenceDayID)
END	
GO
/****** Object:  StoredProcedure [dbo].[FindCountry]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[FindCountry]
	@CountryName varchar(80),
	@CountryID int OUTPUT
as
begin
	set nocount on
	begin try
		begin TRAN FIND
			SET @CountryID = (select countryID
							  from Countries
							  where countryname = @CountryName)
			if(@CountryID is null) begin
				insert into Countries (CountryName)
				values (@CountryName);
				set @CountryID = @@IDENTITY;
			end
		COMMIT TRAN FIND
	end try
	begin catch
		rollback tran FIND
	end catch
end;
GO
/****** Object:  StoredProcedure [dbo].[FindRegion]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[FindRegion]
	@RegionName nvarchar(80),
	@CountryName nvarchar(80),
	@RegionID int output
as
begin
	begin try
		begin tran find
			if @CountryName is null raiserror (15600, -1, -1, 'FindRegion')
			set @RegionID = (select RegionID
							 from Regions
							 inner join Countries on Countries.CountryID = Regions.CountryID
							 where regionname = @RegionName and CountryName = @CountryName)
			if @RegionID is null begin
				declare @CountryID int
				exec FindCountry @CountryName, @CountryID output
				insert into Regions (RegionName, CountryID) values (@RegionName, @CountryID)
				set @RegionID = (select max(RegionID) from Regions)
			end
		commit tran find
	end try
	begin catch
		rollback tran find
	end catch
end
GO
/****** Object:  StoredProcedure [dbo].[FindReservation]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[FindReservation] @CustomerEmail varchar(100), @DateOrdered DATE, @ReservationID int output as
begin
	declare @CustomerID int
	EXEC @CustomerID = dbo.FindCustomerByEmail @CustomerEmail -- varchar(15)
	select @ReservationID = max(ReservationID)
	from ConferenceReservations
	where CustomerID = @CustomerID AND DateOrdered = @DateOrdered
end
GO
/****** Object:  StoredProcedure [dbo].[FindWorkshopInDay]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FindWorkshopInDay]
	@ConferenceName VARCHAR(200),
	@Date DATE,
	@WorkshopName VARCHAR(200),
	@StartTime TIME,
	@ConferenceDayWorkshopID INT OUTPUT
AS
BEGIN
	DECLARE @WorkshopID INT, @ConferenceDayID INT 
	EXEC @WorkshopID = FindWorkshop @Name = @WorkshopName -- varchar(200)
	EXEC dbo.FindConference @ConferenceName = @ConferenceName,                       -- varchar(200)
	                        @Date = @Date,                       -- date
	                        @ConferenceID = null,       -- int
	                        @ConferenceDayID = @ConferenceDayID OUTPUT -- int
	IF @WorkshopID IS NULL RAISERROR('Nie ma tekiego warsztatu', 11,1)
	SELECT @ConferenceDayWorkshopID = ConferenceDayWorkshopID
	FROM dbo.ConferenceDayWorkshops
	WHERE WorkshopID = @WorkshopID AND ConferenceDayID = @ConferenceDayID AND StartTime = @StartTime
END
GO
/****** Object:  StoredProcedure [dbo].[Invoice]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Invoice] 
	@CustomerEmail VARCHAR(100), 
	@DateOrdered DATE,
	@InvoiceCustomerData VARCHAR(500) output
AS
BEGIN

	DECLARE @ReservationId INT
	EXEC dbo.FindReservation @CustomerEmail = @CustomerEmail,                    -- varchar(100)
	                         @DateOrdered = @DateOrdered,            -- date
	                         @ReservationID = @ReservationID OUTPUT -- int

	SELECT @InvoiceCustomerData = (Name + CHAR(10) + Address) FROM CustomerContactData WHERE CustomerID = 
	(SELECT CustomerID FROM dbo.ConferenceReservations WHERE ReservationID = @ReservationId)
	SET @InvoiceCustomerData = @InvoiceCustomerData + CHAR(10) + 'Zamówiono dnia ' + CAST(@DateOrdered AS VARCHAR)

	DECLARE @DayReservations TABLE (
		ID INT PRIMARY KEY IDENTITY(1,1),
		ConfDayID INT,
		AdultSeats INT,
		StudentSeats INT,
		DayDate DATE,
		ConfName VARCHAR(200),
		ConfID int
	) 
	INSERT INTO @DayReservations (ConfDayID, AdultSeats, StudentSeats, DayDate, ConfName, ConfID)
	SELECT ConferenceDayReservation.ConferenceDayID, ReservedAdultSeats, ReservedStudentSeats, dbo.ConferenceDays.Date, Conferences.Name, Conferences.ConferenceID
	FROM dbo.ConferenceDayReservation
	INNER JOIN dbo.ConferenceDays ON ConferenceDays.ConferenceDayID = ConferenceDayReservation.ConferenceDayID
	INNER JOIN dbo.Conferences ON Conferences.ConferenceID = ConferenceDays.ConferenceID
	WHERE ReservationID = @ReservationId

	DECLARE @WorkshopReserv TABLE (
		ID INT PRIMARY KEY IDENTITY(1,1),
		ConfDayID INT,
		Seats INT,
		DayDate date,
		ConfName VARCHAR(200),
		WorkshopName VARCHAR(200),
		Price MONEY,
		StartTime TIME
	)
	INSERT INTO @WorkshopReserv (ConfDayID, Seats, DayDate, ConfName, WorkshopName, Price, StartTime)
	SELECT dbo.ConferenceDayReservation.ConferenceDayID, dbo.WorkshopReservation.ReservedSeats, ConferenceDays.Date, Conferences.Name, Workshops.Name, Price, StartTime
	FROM dbo.ConferenceDayReservation
	INNER JOIN dbo.ConferenceDays ON ConferenceDays.ConferenceDayID = ConferenceDayReservation.ConferenceDayID
	INNER JOIN dbo.Conferences ON Conferences.ConferenceID = ConferenceDays.ConferenceID
	INNER JOIN dbo.ConferenceDayWorkshops ON ConferenceDayWorkshops.ConferenceDayID = ConferenceDays.ConferenceDayID
	INNER JOIN dbo.Workshops ON Workshops.WorkshopID = ConferenceDayWorkshops.WorkshopID
	INNER JOIN dbo.WorkshopReservation ON WorkshopReservation.ConferenceDayWorkshopID = ConferenceDayWorkshops.ConferenceDayWorkshopID AND WorkshopReservation.ConferenceDayReservationID = ConferenceDayReservation.DayReservationID
	WHERE ReservationID = @ReservationId

	DECLARE @Invoice TABLE (
		Description varchar(500),
		Quantity INT,
		BasePrice MONEY,
		OrderDiscount REAL,
		StudentDiscount REAL,
		FinalPrice REAL
	)

	DECLARE @ReservPointer INT = 1, @ReservSize INT = (SELECT COUNT(*) FROM (SELECT * FROM @DayReservations) t), @Total REAL = 0.0
	WHILE @ReservPointer <= @ReservSize BEGIN
		DECLARE @AdultSeats INT = (SELECT AdultSeats FROM @DayReservations WHERE ID = @ReservPointer)
		DECLARE @StudentSeats INT = (SELECT StudentSeats FROM @DayReservations WHERE ID = @ReservPointer)
		DECLARE @ConfName VARCHAR(200) = (SELECT ConfName FROM @DayReservations WHERE Id = @ReservPointer)
		DECLARE @ConfDate DATE = (SELECT DayDate FROM @DayReservations WHERE ID = @ReservPointer)
		DECLARE @BaseDayPrice money, @DiscountForDay REAL, @DiscountForStudent REAL
        set @BaseDayPrice = (SELECT BasePriceForDay FROM dbo.BaseDayPrices(@ReservationId) WHERE ConferenceID = (SELECT ConfID FROM @DayReservations WHERE ID = @ReservPointer))
		set @DiscountForDay = (SELECT Discount FROM dbo.DiscountForReservations(@DateOrdered, @ReservationId) WHERE ConferenceID = (SELECT ConfID FROM @DayReservations WHERE ID = @ReservPointer))
		set @DiscountForStudent = (SELECT StudentDiscount FROM dbo.StudentDiscountForReservations(@ReservationId) WHERE ConferenceID = (SELECT ConfID FROM @DayReservations WHERE ID = @ReservPointer))
		INSERT INTO @Invoice
		(
		    Description,
		    Quantity,
		    BasePrice,
		    OrderDiscount,
		    StudentDiscount,
		    FinalPrice
		)
		VALUES
		(   '"' + CAST(@ConfName AS VARCHAR) + '" ' + CAST(@ConfDate AS VARCHAR) + ' - miejsca normalne',   -- Description - varchar(400)
		    @AdultSeats,    -- Quantity - int
		    @BaseDayPrice, -- BasePrice - money
		    @DiscountForDay,  -- OrderDiscount - real
		    0,  -- StudentDiscount - real
		    @AdultSeats * @BaseDayPrice * (1 - @DiscountForDay)   -- FinalPrice - real
		    )
		INSERT INTO @Invoice
		(
		    Description,
		    Quantity,
		    BasePrice,
		    OrderDiscount,
		    StudentDiscount,
		    FinalPrice
		)
		VALUES
		(   '"' + CAST(@ConfName AS VARCHAR) + '" ' + CAST(@ConfDate AS VARCHAR) + ' - miejsca studenckie',   -- Description - varchar(400)
		    @StudentSeats,    -- Quantity - int
		    @BaseDayPrice, -- BasePrice - money
		    @DiscountForDay,  -- OrderDiscount - real
		    @DiscountForStudent,  -- StudentDiscount - real
		    @StudentSeats * (1 - @DiscountForDay) * (1 - @DiscountForStudent) * @BaseDayPrice   -- FinalPrice - real
		    )

	SET @Total = @Total + @StudentSeats * (1 - @DiscountForDay) * (1 - @DiscountForStudent) * @BaseDayPrice + @AdultSeats * @BaseDayPrice * (1 - @DiscountForDay)
	SET @ReservPointer = @ReservPointer + 1
	END

	SET @ReservPointer = 1
	SET @ReservSize = (SELECT COUNT(*) FROM (SELECT * FROM @WorkshopReserv) t)
	WHILE @ReservPointer <= @ReservSize BEGIN
		DECLARE @Seats INT = (SELECT Seats FROM @WorkshopReserv WHERE ID = @ReservPointer)
		DECLARE @ConfName2 VARCHAR(200) = (SELECT ConfName FROM @WorkshopReserv WHERE Id = @ReservPointer)
		DECLARE @ConfDate2 DATE = (SELECT DayDate FROM @WorkshopReserv WHERE ID = @ReservPointer)
		DECLARE @Time TIME = (SELECT StartTime FROM @WorkshopReserv WHERE ID = @ReservPointer)
		DECLARE @WorkName VARCHAR(200) = (SELECT WorkshopName FROM @WorkshopReserv WHERE ID = @ReservPointer)
		DECLARE @Price MONEY = (SELECT Price FROM @WorkshopReserv WHERE ID = @ReservPointer)
		INSERT INTO @Invoice
		(
		    Description,
		    Quantity,
		    BasePrice,
		    OrderDiscount,
		    StudentDiscount,
		    FinalPrice
		)
		VALUES
		(   'Miejsca na warsztat "' + @WorkName + '" podczas konferencji "' + @ConfName2 + '" ' + CAST(@ConfDate2 AS VARCHAR) + ' godz. ' + CAST(@Time AS VARCHAR(5)),
		    @Seats,    -- Quantity - int
		    @Price, -- BasePrice - money
		    0.0,  -- OrderDiscount - real
		    0.0,  -- StudentDiscount - real
		    @Seats * @Price   -- FinalPrice - real
		    )
		SET @Total = @Total + @Seats * @Price
		SET @ReservPointer = @ReservPointer + 1
	END	


	INSERT INTO @Invoice
	(
	    Description,
	    Quantity,
	    BasePrice,
	    OrderDiscount,
	    StudentDiscount,
	    FinalPrice
	)
	VALUES
	(   'Razem',   -- Description - varchar(400)
	    null,    -- Quantity - int
	    NULL, -- BasePrice - money
	    null,  -- OrderDiscount - real
	    null,  -- StudentDiscount - real
	    @Total   -- FinalPrice - real
	    )
	
	SELECT * FROM @Invoice WHERE Quantity > 0 OR Description = 'Razem'
END
GO
/****** Object:  StoredProcedure [dbo].[MarkReservationAsPaid]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[MarkReservationAsPaid]
	@Email varchar(100),
	@DateOrdered date
as
declare	@ReservationID int,
		@CustomerID int;
EXEC @CustomerID = dbo.FindCustomerByEmail @Email -- varchar(15)

begin
	EXEC dbo.FindReservation @CustomerEmail = @Email,                    -- varchar(15)
							 @DateOrdered = @DateOrdered,
	                         @ReservationID = @ReservationID OUTPUT -- int
	
	update ConferenceReservations
	set DatePaid = convert (date, getdate())
	where ReservationID = @ReservationID;
end
GO
/****** Object:  StoredProcedure [dbo].[NewCompany]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[NewCompany]
	@CompanyName NVARCHAR(150),
	@NIP CHAR(10),
	@Phone VARCHAR(15),
	@Email VARCHAR(100),
	@Street NVARCHAR(74),
	@HouseNumber VARCHAR(5),
	@AppartmentNumber INT,
	@CityName VARCHAR(80),
	@PostalCode CHAR(6),
	@RegionName VARCHAR(80),
	@CountryName VARCHAR(80)
AS
BEGIN
BEGIN TRY
	BEGIN TRAN tr
		DECLARE @cityID INT
		EXEC dbo.FindCity @CityName = @CityName,          -- nvarchar(80)
		                  @RegionName = @RegionName,        -- nvarchar(80)
		                  @CountryName = @CountryName,       -- nvarchar(80)
		                  @CityID = @CityID OUTPUT -- int
		INSERT INTO dbo.Customers
		(
		    Street,
		    HouseNumber,
		    AppartmentNumber,
		    CityID,
		    PostalCode
		)
		VALUES
		(   @Street, -- Street - nvarchar(74)
		    @HouseNumber, -- HouseNumber - nvarchar(5)
		    @AppartmentNumber,   -- AppartmentNumber - int
		    @cityID,   -- CityID - int
		    @PostalCode   -- PostalCode - char(6)
		    )
		DECLARE @CompanyID INT = (SELECT MAX(CustomerID) FROM dbo.Customers)
		INSERT INTO dbo.Companies
		(
		    CompanyID,
		    CompanyName,
		    NIP,
		    Phone,
		    Email
		)
		VALUES
		(   @CompanyID,   -- CompanyID - int
		    @CompanyName, -- CompanyName - nvarchar(150)
		    @NIP,  -- NIP - char(10)
		    @Phone,  -- Phone - varchar(12)
		    @Email   -- Email - varchar(100)
		    )
	COMMIT TRAN tr
END TRY
BEGIN CATCH
	ROLLBACK TRAN tr
END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[NewConference]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[NewConference]
	@Name varchar(200),
	@StartDate date,
	@EndDate date,
	@BasePrice money,
	@StudentDiscount real,
	@ParticipantLimit int,
	@Street varchar(74),
	@HouseNumber varchar(5),
	@AppartmentNumber int,
	@City varchar(80),
	@Region varchar(80),
	@Country varchar(80),
	@PostalCode char(6)
as
begin
declare @CityID int;
exec FindCity @City, @Region, @Country, @CityID output;
insert into Conferences (Name, StartDate, EndDate, BasePriceForDay, StudentDiscount, ParticipantsLimit,
						Street, HouseNumber, AppartmentNumber, CityID, PostalCode)
values (
		@Name,
		@StartDate,
		@EndDate,
		@BasePrice,
		@StudentDiscount,
		@ParticipantLimit,
		@Street,
		@HouseNumber,
		@AppartmentNumber,
		@CityID,
		@PostalCode
	   )
end
GO
/****** Object:  StoredProcedure [dbo].[NewConferenceReservation]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[NewConferenceReservation]
	@CustomerEmail varchar(100),
	@ReservationID int output
as
begin
begin try
	begin tran tr
		declare @CustomerID int
		EXEC @CustomerID = dbo.FindCustomerByEmail @CustomerEmail -- varchar(15)
		
		if @CustomerID is not null begin
			insert into ConferenceReservations (CustomerID)
			values (@CustomerID)
			set @ReservationID = @@IDENTITY
		end
	commit tran tr
end try
begin CATCH
	PRINT ERROR_MESSAGE()
	rollback tran tr
end catch
end
GO
/****** Object:  StoredProcedure [dbo].[NewDayReservation]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[NewDayReservation]
	@CustomerEmail varchar(100),
	@ConferenceName varchar(200),
	@ConferenceDayDate date,
	@OrderDate DATE,
	@AdultSeats int,
	@StudentSeats int
as
begin
begin try
	begin tran tr
		DECLARE @ConferenceID INT,
		        @ConferenceDayID INT;
		EXEC dbo.FindConference @ConferenceName = @ConferenceName,                      -- varchar(200)
		                        @Date = @ConferenceDayDate,                      -- date
		                        @ConferenceID = @ConferenceID OUTPUT,      -- int
		                        @ConferenceDayID = @ConferenceDayID OUTPUT -- int
		if @ConferenceDayID is not null begin
			declare @ReservationID int
			exec FindReservation @CustomerEmail, @OrderDate, @ReservationID OUTPUT
			insert into dbo.ConferenceDayReservation 
			(ConferenceDayID, ReservedAdultSeats, ReservedStudentSeats, ReservationID)
			values (@ConferenceDayID, @AdultSeats, @StudentSeats, @ReservationID)
		end
	commit tran tr
end try
begin CATCH
 PRINT ERROR_MESSAGE()
 rollback tran tr end catch
end
GO
/****** Object:  StoredProcedure [dbo].[NewDayReservationForPrivateCustomer]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[NewDayReservationForPrivateCustomer]
	@CustomerEmail VARCHAR(100),
	@ConferenceName VARCHAR(200),
	@ConferenceDayDate DATE,
	@OrderDate DATE,
	@StudentCardNumber VARCHAR(10)
AS
BEGIN
BEGIN TRY
	BEGIN TRAN tr
		IF @StudentCardNumber IS NOT NULL BEGIN 
			EXEC dbo.NewDayReservation @CustomerEmail = @CustomerEmail,               -- varchar(100)
			                           @ConferenceName = @ConferenceName,              -- varchar(200)
			                           @ConferenceDayDate = @ConferenceDayDate, -- date
			                           @OrderDate = @OrderDate,         -- date
			                           @AdultSeats = 0,                   -- int
			                           @StudentSeats = 1                 -- int
		END ELSE BEGIN 
			EXEC dbo.NewDayReservation @CustomerEmail = @CustomerEmail,               -- varchar(100)
			                           @ConferenceName = @ConferenceName,              -- varchar(200)
			                           @ConferenceDayDate = @ConferenceDayDate, -- date
			                           @OrderDate = @OrderDate,         -- date
			                           @AdultSeats = 1,                   -- int
			                           @StudentSeats = 0                  -- int
		END	
        
		DECLARE @ParticipantID INT, @ParticipantPhone VARCHAR(15), @FirstName VARCHAR(30), @LastName VARCHAR(50)
		EXEC @ParticipantID = dbo.FindCustomerByEmail @Email = @CustomerEmail -- varchar(100)
		SELECT @ParticipantPhone = Phone, @FirstName = FirstName, @LastName = LastName
		FROM dbo.Participants
		WHERE ParticipantID = @ParticipantID
		EXEC dbo.FillReservation @CustomerEmail = @CustomerEmail,                   -- varchar(100)
		                         @DateOrdered = @OrderDate,           -- date
		                         @ConferenceName = @ConferenceName,                  -- varchar(200)
		                         @ConfDayDate = @ConferenceDayDate,           -- date
		                         @FirstName = @FirstName,                       -- varchar(30)
		                         @LastName = @LastName,                        -- varchar(50)
		                         @ParticipantPhone = @ParticipantPhone,                -- varchar(15)
		                         @ParticipantEmail = @CustomerEmail,                -- varchar(100)
		                         @StudentCardNumber = @StudentCardNumber,               -- varchar(10)
		                         @ParticipantID = @ParticipantID OUTPUT -- int
		

	COMMIT TRAN tr
END TRY
BEGIN CATCH
	ROLLBACK TRAN tr
END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[NewParticipant]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[NewParticipant]
	@FirstName varchar(30),
	@LastName varchar(50),
	@Phone varchar(15),
	@Email varchar(50),
	@ParticipantID INT OUTPUT
as
begin
insert into Participants (FirstName, LastName, Phone, Email) values (@FirstName, @LastName, @Phone, @Email)
SET @ParticipantID = (SELECT MAX(ParticipantID) FROM dbo.Participants)
end
GO
/****** Object:  StoredProcedure [dbo].[NewWorkshop]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[NewWorkshop]
	@Name varchar(100),
	@Description varchar(1000)
as
begin
insert into Workshops (Name, Description) values (@Name, @Description)
end
GO
/****** Object:  StoredProcedure [dbo].[NewWorkshopReservation]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[NewWorkshopReservation]
	@ConferenceName VARCHAR(200),
	@ConfDayDate DATE,
	@WorkshopName VARCHAR(200),
	@StartTime TIME ,
	@CustomerEmail VARCHAR(100),
	@DateConferenceOrdered DATE,
	@SeatsReserved INT
AS
BEGIN
BEGIN TRY
	BEGIN TRAN TR
		DECLARE @DayReservationID INT, @WorkshopInDayID INT
		EXEC FindWorkshopInDay @ConferenceName, @ConfDayDate, @WorkshopName, @StartTime, @WorkshopInDayID OUTPUT
		EXEC dbo.FindConferenceDayReservation @ConferenceName = @ConferenceName,                                            -- varchar(200)
		                                      @ConfDayDate = @ConfDayDate,                                     -- date
		                                      @CustomerEmail = @CustomerEmail,                                             -- varchar(100)
		                                      @DateOrdered = @DateConferenceOrdered,                                     -- date
		                                      @ConferenceDayReservationID = @DayReservationID OUTPUT -- int
		IF @DayReservationID IS NULL RAISERROR('Nie znaleziono rezerwacji',11,1)
		IF @WorkshopInDayID IS NULL RAISERROR ('Nie znaleziono warsztatu',11,1)
		INSERT INTO dbo.WorkshopReservation
		(
		    ConferenceDayWorkshopID,
		    ConferenceDayReservationID,
		    ReservedSeats
		)
		VALUES
		(   @WorkshopInDayID, -- ConferenceDayWorkshopID - int
		    @DayReservationID, -- ConferenceDayReservationID - int
		    @SeatsReserved  -- ReservedSeats - int
		    )
	COMMIT TRAN TR
END TRY
BEGIN CATCH
	PRINT ERROR_MESSAGE()
	ROLLBACK TRAN TR
END CATCH
end
GO
/****** Object:  StoredProcedure [dbo].[ShowParticipantsOfConference]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[ShowParticipantsOfConference]
	@ConferenceID int
as
begin
	select FirstName, LastName, participants.Phone, CompanyName
	from ConferenceDayParticipants
	inner join Participants on Participants.ParticipantID = ConferenceDayParticipants.ParticipantID
	inner join EmployeesOfCompanies on Participants.ParticipantID = EmployeesOfCompanies.ParticipantID
	inner join Companies on EmployeesOfCompanies.CompanyID = Companies.CompanyID
	inner join ConferenceDayReservation on ConferenceDayReservationID = DayReservationID
	inner join ConferenceDays on ConferenceDayReservation.ConferenceDayID = ConferenceDays.ConferenceDayID
	where ConferenceDays.ConferenceID = @ConferenceID
end
GO
/****** Object:  StoredProcedure [dbo].[ShowParticipantsOfConferenceDay]    Script Date: 22/01/2019 15:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[ShowParticipantsOfConferenceDay]
	@ConferenceID int,
	@ConferenceDayOrdinal int
as
begin
	select FirstName, LastName, participants.Phone, CompanyName
	from ConferenceDayParticipants
	inner join Participants on Participants.ParticipantID = ConferenceDayParticipants.ParticipantID
	inner join EmployeesOfCompanies on Participants.ParticipantID = EmployeesOfCompanies.ParticipantID
	inner join Companies on EmployeesOfCompanies.CompanyID = Companies.CompanyID
	inner join ConferenceDayReservation on ConferenceDayReservationID = DayReservationID
	inner join ConferenceDays on ConferenceDayReservation.ConferenceDayID = ConferenceDays.ConferenceDayID
	where ConferenceDays.DayOrdinal = @ConferenceDayOrdinal and ConferenceDays.ConferenceID = @ConferenceID
end
GO
USE [master]
GO
ALTER DATABASE [dlugosz_a] SET  READ_WRITE 
GO
