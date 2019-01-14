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
end
go

create trigger InsertParticipantsForReservation on ConferenceDayReservation
for insert
as
declare @AdultPointer int = 1,
		@StudentPointer int = 1,
		@NumberOfAdults int = (select ReservedAdultSeats from inserted),
		@NumberOfStudents int = (Select ReservedStudentSeats from inserted),
		@NewParticipantID int;
while @AdultPointer <= @NumberOfAdults begin
	insert into Participants default values
	set @NewParticipantID = (select max(ParticipantID) from Participants)
	insert into ConferenceDayParticipants (ConferenceDayReservationID, ConferenceDayParticipantID)
	values ((select DayReservationID from inserted), @NewParticipantID)
	set @AdultPointer = @AdultPointer + 1
end
while @StudentPointer <= @NumberOfStudents begin
	insert into Participants default values
	set @NewParticipantID = (select max(ParticipantID) from Participants)
	insert into Students (ParticipantID) values (@NewParticipantID)
	insert into ConferenceDayParticipants (ConferenceDayReservationID, ConferenceDayParticipantID)
	values ((select DayReservationID from inserted), @NewParticipantID)
	set @StudentPointer = @StudentPointer + 1
end
go