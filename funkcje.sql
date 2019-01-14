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

--create function CalculatePriceForReservation (