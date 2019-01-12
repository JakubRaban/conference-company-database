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

create procedure FindRegion
	@RegionName nvarchar(80),
	@CountryName nvarchar(80),
	@RegionID int output
as
begin
	begin try
		begin tran find
			if @CountryName is null rollback tran find
			set @RegionID = (select RegionID
							 from Regions
							 inner join Countries on Countries.CountryID = Regions.CountryID
							 where regionname = @RegionName and CountryName = @CountryName)
			if @RegionID is null begin
				declare @CountryID int
				exec FindCountry @CountryName, @CountryID
				insert into Regions (RegionName, CountryID) values (@RegionName, @CountryID)
				set @RegionID = (select max(RegionID) from Regions)
			end
		commit tran find
	end try
	begin catch
		rollback tran find
	end catch
end
go

create procedure FindCity
	@CityName nvarchar(80),
	@RegionName nvarchar(80),
	@CountryName nvarchar(80),
	@CityID int output
as
begin
begin try
	begin tran find
		if @RegionName is null or @CountryName is null rollback tran find
		set @CityID = (select Cityid
					   from Cities
					   inner join Regions on Cities.RegionID = Regions.RegionID
					   inner join Countries on Countries.CountryID = Regions.CountryID
					   where CityName = @CityName and RegionName = @RegionName and CountryName = @CountryName)
		if @CityID is null begin
			declare @RegionID int
			exec FindRegion @RegionName, @CountryName, @RegionID
			insert into Cities (CityName, RegionID) values (@CityName, @RegionID)
			set @CityID = (select max(CityID) from Cities)
		end
	commit tran find
end try
begin catch
	rollback tran find
end catch
end
go


create procedure AddPrivateCustomer
	@ParticipantPhone nvarchar(15),
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
		declare @ParticipantID int = (select ParticipantID
									  from Participants
									  where Phone = @ParticipantPhone)
		declare @CityID int
		exec FindCity @CityName, @RegionName, @CountryName, @CityID
		insert into Customers (Street, HouseNumber, AppartmentNumber, PostalCode, CityID)
		values (
			@Street, @HouseNumber, @AppartmentNumber, @PostalCode, @CityID
		)
		insert into PrivateCustomers (ParticipantID, CustomerID)
		values (
			@ParticipantID, (select max(CustomerID) from Customers)
		)
	commit tran find
end try
begin catch
	rollback tran tr
end catch
end
go

create procedure AddOurEmployee
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
go

create procedure BindOurEmployeeWithConference
	@EmpPhone varchar(15),
	@ConferenceName varchar(200)
as
begin
	insert into ConferenceEmployees (EmployeeID, ConferenceID) values (
		(select EmployeeID from OurEmployees where Phone = @EmpPhone),
		(select ConferenceID from Conferences where Name = @ConferenceName)
	)
end
go

create procedure ShowParticipantsOfConferenceDay
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
go

create procedure ShowParticipantsOfConference
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
go