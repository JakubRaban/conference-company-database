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
declare @ParticipantID int,
		@CompanyID int;
exec FindParticipantByPhone @Phone, @ParticipantID;
exec FindCompanyByNIP @NIP, @CompanyID;
begin
insert into EmployeesOfCompanies (ParticipantID, CompanyID)
values (
	@ParticipantID,
	@CompanyID
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
	@Region varchar(80),
	@Country varchar(80),
	@PostalCode char(6)
as
begin
declare @CityID int;
exec FindCity @City, @Region, @Country, @CityID;
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
go

create procedure AddPriceStep
	@ConferenceName varchar(200),
	@ConferenceStartDate date,
	@PriceStartsOn date,
	@PriceEndsOn date,
	@DiscountRate real
as
declare @ConferenceID int;
set @ConferenceID = (select ConferenceID
					 from Conferences
					 where Name = @ConferenceName and StartDate = @ConferenceStartDate);
begin
	if @ConferenceID is null
	begin
		print 'Nie znaleziono konferencji'
		return
	end
	if exists (select PriceEndsOn 
			   from ConferencePricetables
			   where ConferenceID = @ConferenceID and PriceEndsOn >= @PriceStartsOn and PriceEndsOn <= @PriceEndsOn)
	begin
		print 'Niepoprawna data rozpoczęcia progu cenowego'
		return
	end
	if exists (select PriceEndsOn 
			   from ConferencePricetables
			   where ConferenceID = @ConferenceID and PriceStartsOn >= @PriceStartsOn and PriceStartsOn <= @PriceEndsOn)
	begin
		print 'Niepoprawna data zakończenia progu cenowego'
		return
	end
	insert into ConferencePricetables (ConferenceID, PriceStartsOn, PriceEndsOn, DiscountRate)
	values (@ConferenceID, @PriceStartsOn, @PriceEndsOn, @DiscountRate)
end
go

create procedure MarkReservationAsPaid
	@Phone varchar(15),
	@DateOrdered date
as
declare	@ReservationID int,
		@CustomerID int;
exec FindCustomerByPhone @Phone, @CustomerID;
begin
	set @ReservationID = (select ReservationID
						  from ConferenceReservations
						  where CustomerID = @CustomerID and DateOrdered = @DateOrdered)
	update ConferenceReservations
	set DatePaid = convert (date, getdate())
	where ReservationID = @ReservationID;
end
go

create procedure AddWorkshopAtDay
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

create procedure NewConferenceReservation
	@CustomerPhone varchar(15),
	@ReservationID int output
as
begin
begin try
	begin tran tr
		declare @CustomerID int
		exec FindCustomerByPhone @CustomerPhone, @CustomerID output
		if @CustomerID is not null begin
			insert into ConferenceReservations (CustomerID, DateOrdered)
			values (@CustomerID, convert(date, getdate() ))
			set @ReservationID = @@IDENTITY
		end
	commit tran tr
end try
begin catch
	rollback tran tr
end catch
end
go

create procedure DeleteUnpaidReservations as
begin
begin try
	begin tran tr
		delete from ConferenceReservations
		where DatePaid is null and DATEDIFF(day, DateOrdered, convert(date, getdate())) > 7
	commit tran tr
end try
begin catch rollback tran tr end catch
end -- dopisać trigger usuwający rezerwację dni konferencji, warsztatów itd.
go

create procedure AddParticipantToWorkshop
	@Phone varchar(15),
	@WorkshopName varchar(100),
	@Date date,
	@StartTime time
as
begin
declare @ConferenceDayID int,
		@WorkshopID int,
		@ConferenceDayWorkshopID int,
		@ParticipantID int,
		@DayReservationID int,
		@ConferenceDayParticipantID int;
set @ConferenceDayID = (select ConferenceDayID from ConferenceDays where Date = @Date);
set @WorkshopID = (select WorkshopID from Workshops where Name = @WorkshopName);
set @ConferenceDayWorkshopID = (select ConferenceDayWorkshopID
								from ConferenceDayWorkshops
								where ConferenceDayID = @ConferenceDayID and WorkshopID = @WorkshopID);
set @ParticipantID = (select ParticipantID from Participants where Phone = @Phone);
set @DayReservationID = (select DayReservationID from ConferenceDayReservation where ConferenceDayID = @ConferenceDayID);
set @ConferenceDayParticipantID = (select ConferenceDayParticipantID
								   from ConferenceDayParticipants
								   where ConferenceDayReservationID = @DayReservationID and ParticipantID = @ParticipantID);
insert into WorkshopParticipants (ConferenceDayParticipantID, ConferenceDayWorkshopID)
values (@ConferenceDayParticipantID, @ConferenceDayWorkshopID)
end


