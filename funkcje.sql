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