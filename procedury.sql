create procedure FindCountry
	@CountryName varchar(80),
	@CountryID int OUTPUT
as
begin
	begin try
		begin TRAN FIND
			SET @CountryID = (select countryID
							  from Countries
							  where countryname = @CountryName)
			if(@CountryID is null) begin
				insert into Countries (CountryName)
				values (@CountryName)
				set @CountryID = (select max(countryid)
								  from Countries)
			end
		COMMIT TRAN FIND
	end try
	begin catch
		rollback tran FIND
	end catch
end
go

create procedure NewWorkshop
	@Name varchar(100),
	@Description varchar(1000)
as
begin
insert into Workshops (Name, Description) values (@Name, @Description)
end
go

create procedure NewParticipant
	@FirstName varchar(30),
	@LastName varchar(50),
	@Phone varchar(15),
	@Email varchar(50)
as
begin
insert into Participants (FirstName, LastName, Phone, Email) values (@FirstName, @LastName, @Phone, @Email)
end
go

create procedure BoundParticipantWithCompany
	@Phone varchar(15),
	@NIP char(10)
as
begin
insert into EmployeesOfCompanies (ParticipantID, CompanyID)
values (
	(select ParticipantID from Participants where Phone = @Phone),
	(select CompanyID from Companies where NIP = @NIP)
)
end
go

create procedure NewConference
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
	@PostalCode char(6)
as
declare @CityID int;
set @CityID = FindCity(CityName = @City);
begin
insert into 
