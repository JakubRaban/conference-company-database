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

