create trigger InsertDaysForNewConference on Conferences
for insert
as
DECLARE @MinDate DATE,
        @MaxDate DATE,
		@DatePointer date,
		@DayOrdinal int = 1;
set @MinDate = (select startdate from inserted);
set @MaxDate = (select enddate from inserted);
set @DatePointer = @MinDate;
while @DatePointer <= @MaxDate begin
	insert into ConferenceDays (ConferenceID, Date, DayOrdinal)
	values (
		(select ConferenceID from inserted),
		@DatePointer,
		@DayOrdinal
	)
	set @DatePointer = DATEADD(day, 1, @DatePointer);
	set @DayOrdinal = @DayOrdinal + 1;
end;