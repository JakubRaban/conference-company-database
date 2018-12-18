use dlugosz_a

create table Students (
	ParticipantID int not null primary key foreign key references Participants(ParticipantID),
	StudentID varchar(10) not null
)

alter table Participants
drop column IsStudent;

alter table Participants
drop column Studentid

EXEC sp_rename 'Conferences.ConferenceName' , 'Name', 'COLUMN'

EXEC sp_rename 'Students.StudentID' , 'StudentCardID', 'COLUMN'

EXEC sp_rename 'ConferenceDay.Day' , 'Date', 'COLUMN'

select * from Customers