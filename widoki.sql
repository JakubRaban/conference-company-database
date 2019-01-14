create view FrequentCustomers as
select firstname + lastname as 'Full Name', companyname as 'Company Name', count(reservationid) as 'Number of paid reservations'
from Customers
inner join ConferenceReservations
	on Customers.CustomerID = ConferenceReservations.CustomerID
left join PrivateCustomers
	on Customers.CustomerID = PrivateCustomers.CustomerID
left join Participants
	on PrivateCustomers.ParticipantID = Participants.ParticipantID
left join Companies
	on Customers.CustomerID = Companies.CompanyID
group by firstname, lastname, CompanyName
go

create view TwoWeekOldReservationsWithoutAllParticipants as
select DayReservationID as 'Day Reservation ID', 
       (ReservedAdultSeats - (select count(*)
							 from (select ParticipantID
								   from ConferenceDayParticipants as cdp1
								   where cdr.DayReservationID = cdp1.ConferenceDayReservationID
								   except
								   select ParticipantID
								   from Participants
								   left join Students on Participants.ParticipantID = Students.ParticipantID
								   where FirstName is not null and LastName is not null and Students.ParticipantID is null) as xd)) as 'Adult seats left',
	   (ReservedStudentSeats - (select count(*)
							   from (select ParticipantID
								   from ConferenceDayParticipants as cdp1
								   where cdr.DayReservationID = cdp1.ConferenceDayReservationID
								   except
								   select ParticipantID
								   from Participants
								   left join Students on Participants.ParticipantID = Students.ParticipantID
								   where FirstName is not null and LastName is not null and Students.ParticipantID is not null) as xd)) as 'Student seats left'
from ConferenceDayReservation as cdr
inner join ConferenceReservations as cr
	on cdr.ReservationID = cr.ReservationID
inner join ConferenceDayParticipants as cdp
	on cdp.ParticipantID = cdr.DayReservationID