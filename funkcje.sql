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

create function FindParticipantByPhone (@Phone varchar(15))
returns int
as
begin
	return (select ParticipantID from Participants where Phone = @Phone)
end
go

create function FindCustomerByPhone	(@Phone varchar(15))
returns int
as
begin
	declare @CompanyID int;
	exec @CompanyID = FindCompanyByPhone @Phone;
	if @CompanyID is null
	begin
		declare @ParticipantID int;
		exec FindParticipantByPhone @Phone;
		return (select CustomerID from PrivateCustomers where ParticipantID = @ParticipantID)
	end
	return @CompanyID
end
go

--create function CalculatePriceForReservation (


CREATE FUNCTION ConferenceSize(@ConferenceDayID INT)
RETURNS int
BEGIN
	DECLARE @size int = (SELECT ParticipantsLimit FROM ConferenceDays
	INNER JOIN conferences ON Conferences.ConferenceID = ConferenceDays.ConferenceID
	WHERE ConferenceDayID = @ConferenceDayID)
	RETURN @size
END

create function CalculatePriceForReservation (@Phone varchar(15), @DateOrdered date)
returns money
as
begin
	declare @CustomerID int,
			@ReservationID int,
			@ConferenceID int,
			@ReservedAdults int,
			@ReservedStudents int,
			@PriceForWorkshops money,
			@PriceForDay money,
			@StudentDiscount real;
	exec @CustomerID = FindCustomerByPhone @Phone;
	set @ReservationID = (select ReservationID
						  from ConferenceReservations
						  where CustomerID = @CustomerID and DateOrdered = @DateOrdered);
	set @ConferenceID = (select ConferenceID
						 from ConferenceDays cd
						 join ConferenceDayReservation cdr
						 on cd.ConferenceDayID = cdr.ConferenceDayID
						 group by ConferenceID);
	set @ReservedAdults = (select sum(ReservedAdultSeats)
						   from ConferenceDayReservation
						   where ReservationID = @ReservationID);
	set @ReservedStudents = (select sum(ReservedAdultSeats)
							 from ConferenceDayReservation
							 where ReservationID = @ReservationID);
	set @PriceForWorkshops = (select sum(cdw.Price * wr.ReservedSeats)
							  from WorkshopReservation wr
							  join ConferenceDayWorkshops cdw
							  on wr.ConferenceDayWorkshopID = cdw.ConferenceDayWorkshopID)
	set @PriceForDay = (select (1 - DiscountRate) * (select BasePriceForDay from Conferences where ConferenceID = @ConferenceID)
						from ConferencePricetables
						where @DateOrdered between PriceStartsOn and PriceEndsOn and ConferenceID = @C
						,
	return @PriceForWorkshops + (1 - @StudentDiscount) * @PriceForDay * @ReservedStudents + @PriceForDay * @ReservedAdults
end
go
