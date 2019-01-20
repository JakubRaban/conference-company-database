create function FindCompanyByNIP (@NIP char(10))
returns int
as
begin
	return (select CompanyID from Companies where NIP = @NIP)
end
go

create function FindCompanyByName (@Name varchar(150))
returns int
as
begin
	return (select CompanyID from Companies where CompanyName = @Name)
end
go

create function FindCompanyByPhone (@Phone varchar(15))
returns int
as
begin
	return (select CompanyID from Companies where Phone = @Phone)
end
go

create function FindParticipantByName (@FirstName varchar(30), @LastName varchar(50))
returns int
as
begin
	return (select ParticipantID from Participants where FirstName = @FirstName and LastName = @LastName)
end
go

CREATE FUNCTION ConferenceSize(@ConferenceDayID INT)
RETURNS int
BEGIN
	DECLARE @size int = (SELECT ParticipantsLimit FROM ConferenceDays
	INNER JOIN conferences ON Conferences.ConferenceID = ConferenceDays.ConferenceID
	WHERE ConferenceDayID = @ConferenceDayID)
	RETURN @size
END
GO

CREATE FUNCTION ReservedSeatsPerConferenceDay(@ConferenceDayID INT)
RETURNS INT
BEGIN
	DECLARE @number INT = (SELECT SUM(ReservedAdultSeats) + SUM(ReservedStudentSeats)
							FROM dbo.ConferenceDayReservation
							WHERE ConferenceDayID = @ConferenceDayID)
	RETURN @number
END
go

CREATE FUNCTION FindConferenceDayReservation (@ConferenceName VARCHAR(200), @ConfDayDate DATE, @CustomerEmail VARCHAR(100), @DateOrdered DATE)
RETURNS INT
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
	DECLARE @ConferenceDayReservationID INT =
	(SELECT DayReservationID
	FROM dbo.ConferenceDayReservation
	WHERE ReservationID = @ReservationID AND ConferenceDayID = @ConferenceDayID)
	RETURN @ConferenceDayReservationID
END
GO

CREATE FUNCTION WorkshopSeatsLimit(@WorkshopID INT)
RETURNS INT
AS
BEGIN
	DECLARE @Limit INT = (SELECT ParticipantsLimit
						 FROM dbo.ConferenceDayWorkshops
						 WHERE WorkshopID = @WorkshopID)
	RETURN @Limit
END
GO

CREATE FUNCTION ConferenceDayReservationSize(@ConferenceDayReservationID int)
RETURNS INT
AS
BEGIN
	DECLARE @Size INT = (SELECT SUM(c.ReservedAdultSeats )+ SUM(c.ReservedAdultSeats)
						FROM dbo.ConferenceDayReservation c
						WHERE c.DayReservationID = @ConferenceDayReservationID)
	RETURN @Size
END
GO

CREATE FUNCTION ReservedSeatsForWorkshop(@ConferenceDayWorkshopID int)
RETURNS int
BEGIN
	DECLARE @Sum INT = (SELECT SUM(ReservedSeats)
						FROM WorkshopReservation
						WHERE ConferenceDayWorkshopID = @ConferenceDayWorkshopID)
	RETURN @Sum
end

alter function FindWorkshop (@Name VARCHAR(200))
RETURNS INT 
BEGIN
	DECLARE @ID INT = (SELECT WorkshopID FROM dbo.Workshops WHERE Name = @Name)
	RETURN @ID
END
GO

CREATE FUNCTION DayReservationTotalSeats(@ConferenceDayReservationID INT)
RETURNS INT
BEGIN
	DECLARE @result INT
	SELECT @result = SUM(ReservedAdultSeats) + SUM(ReservedStudentSeats)
	FROM dbo.ConferenceDayReservation cdr
	WHERE cdr.DayReservationID = @ConferenceDayReservationID
	RETURN @result
end
go

create function GetNumberOfPaidReservationForCustomer(@Email varchar(100))
returns int
begin
	declare @CustomerID int;
	exec @CustomerID = FindCustomerByEmail @Email;
	return (select count(*)
			from ConferenceReservations
			where CustomerID = @CustomerID and DatePaid is not null)
end
go

create function GetConferenceStartDate(@ConferenceID int)
returns date
as
begin
	return (select StartDate from Conferences where ConferenceID = @ConferenceID)
end
go

create function GetLatestDiscount(@ConferenceID int)
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
go

create function BaseDayPrices (@ReservationID int)  
returns table
as
return
(
    select c.ConferenceID, c.BasePriceForDay
	from ConferenceDayReservation cdr
	join ConferenceDays cd
	on cd.ConferenceDayID = cdr.ConferenceDayID
	join Conferences c
	on cd.ConferenceID = c.ConferenceID
	where cdr.ReservationID = @ReservationID
);
go

create function StudentDiscountForReservations (@ReservationID int)  
returns table
as
return
(
    select c.ConferenceID, c.StudentDiscount
	from ConferenceDayReservation cdr
	join ConferenceDays cd
	on cd.ConferenceDayID = cdr.ConferenceDayID
	join Conferences c
	on cd.ConferenceID = c.ConferenceID
	where cdr.ReservationID = @ReservationID
);
go

create function DiscountForReservations (@DateOrdered date, @ReservationID int)  
returns table
as
return
(
    select c.ConferenceID, dbo.DiscountForConference(@DateOrdered, c.ConferenceID) as Discount
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
go

create function ReservationPrices (@DateOrdered date, @ReservationID int)  
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
go