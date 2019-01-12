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