create view FrequentCustomers as
select top 10 firstname + ' ' + lastname as 'Full Name', companyname as 'Company Name', count(reservationid) as 'Number of paid reservations'
from Customers
inner join ConferenceReservations
	on Customers.CustomerID = ConferenceReservations.CustomerID
left join PrivateCustomers
	on Customers.CustomerID = PrivateCustomers.CustomerID
left join Participants
	on PrivateCustomers.ParticipantID = Participants.ParticipantID
left join Companies
	on Customers.CustomerID = Companies.CompanyID
group by firstname, lastname, companyname
order by 3
go

create view TwoWeekOldReservationsWithoutAllParticipants as
select cdp.ConferenceDayReservationID as 'Conference Day Reservation ID',
	   (select 2 from (select cdpp.ConferenceDayReservationID as x1, count(cdpp.ParticipantID) as y1
					   from ConferenceDayParticipants cdpp
					   inner join Participants p
							on P.ParticipantID = cdpp.ParticipantID
					   left join Students
							on p.ParticipantID = students.ParticipantID
					   where LastName is null and students.ParticipantID is null
					   group by cdpp.ConferenceDayReservationID) as t where t.x1 = cdp.ConferenceDayReservationID) as 'Adult Seats Left',
	   (select 2 from (select cdpp.ConferenceDayReservationID as x2, count(cdpp.ParticipantID) as y2
					   from ConferenceDayParticipants cdpp
					   inner join Participants p
							on P.ParticipantID = cdpp.ParticipantID
					   inner join Students
							on p.ParticipantID = students.ParticipantID
					   where LastName is null
					   group by cdpp.ConferenceDayReservationID) as t where t.x2 = cdp.ConferenceDayReservationID) as 'Student seats left',
	   c.Phone
from ConferenceDayParticipants cdp
inner join ConferenceDayReservation cdr
	on cdp.ConferenceDayReservationID = cdr.DayReservationID
inner join ConferenceReservations cr
	on cdr.ReservationID = cr.ReservationID
inner join Customers cust
	on cr.CustomerID = cust.CustomerID
inner join Companies c
	on c.CompanyID = cust.CustomerID
where datediff(day, cr.dateordered, convert(date, getdate())) > 14 and (
(select 2 from (select cdpp.ConferenceDayReservationID as x2, count(cdpp.ParticipantID) as y2
					   from ConferenceDayParticipants cdpp
					   inner join Participants p
							on P.ParticipantID = cdpp.ParticipantID
					   inner join Students
							on p.ParticipantID = students.ParticipantID
					   where LastName is null
					   group by cdpp.ConferenceDayReservationID) as t where t.x2 = cdp.ConferenceDayReservationID) > 0
					   or
(select 2 from (select cdpp.ConferenceDayReservationID as x1, count(cdpp.ParticipantID) as y1
					   from ConferenceDayParticipants cdpp
					   inner join Participants p
							on P.ParticipantID = cdpp.ParticipantID
					   left join Students
							on p.ParticipantID = students.ParticipantID
					   where LastName is null and students.ParticipantID is null
					   group by cdpp.ConferenceDayReservationID) as t where t.x1 = cdp.ConferenceDayReservationID) > 0)
go

create view Payments as
select ReservationID, CompanyName, DateOrdered, DatePaid,
	dbo.CalculatePriceForReservation(Companies.Phone, DateOrdered) as Price
from ConferenceReservations
join Customers
on ConferenceReservations.CustomerID = Customers.CustomerID
join Companies
on Customers.CustomerID = Companies.CompanyID
union
select ReservationID, (FirstName + ' ' + LastName), DateOrdered, DatePaid,
	dbo.CalculatePriceForReservation(Participants.Phone, DateOrdered) as Price
from ConferenceReservations
join Customers
on ConferenceReservations.CustomerID = Customers.CustomerID
join PrivateCustomers
on Customers.CustomerID = PrivateCustomers.CustomerID
join Participants
on PrivateCustomers.ParticipantID = Participants.ParticipantID
go

create view UnpaidReservations
as
select ReservationID, CompanyName, DateOrdered
from ConferenceReservations
join Customers
on ConferenceReservations.CustomerID = Customers.CustomerID
join Companies
on Customers.CustomerID = Companies.CompanyID
where DatePaid is null
union
select ReservationID, (FirstName + ' ' + LastName), DateOrdered
from ConferenceReservations
join Customers
on ConferenceReservations.CustomerID = Customers.CustomerID
join PrivateCustomers
on Customers.CustomerID = PrivateCustomers.CustomerID
join Participants
on PrivateCustomers.ParticipantID = Participants.ParticipantID
where DatePaid is null
go

create view CustomersWithPaidReservations
as
select CustomerID, CompanyName as Customer, dbo.GetNumberOfPaidReservationForCustomer(Companies.Email) as PaidReservations
from Customers
join Companies
on Customers.CustomerID = Companies.CompanyID
union
select Customers.CustomerID, (FirstName + ' ' + LastName) as Customer,
dbo.GetNumberOfPaidReservationForCustomer(Participants.Email) as PaidReservations
from Customers
join PrivateCustomers
on Customers.CustomerID = PrivateCustomers.CustomerID
join Participants
on PrivateCustomers.ParticipantID = Participants.ParticipantID
go

create view ConferencesWithAvailablePlaces
as
select Conferences.ConferenceID, Name, DayOrdinal as Day,
	ParticipantsLimit - isnull(sum(ReservedAdultSeats + ReservedStudentSeats), 0) as 'Available Places'
from Conferences
join ConferenceDays
on Conferences.ConferenceID = ConferenceDays.ConferenceID
left join ConferenceDayReservation
on ConferenceDays.ConferenceDayID = ConferenceDayReservation.ConferenceDayID
group by Conferences.ConferenceID, Name, DayOrdinal, ParticipantsLimit
go

create view WorkshopsWithAvailablePlaces
as
select Conferences.ConferenceID, Conferences.Name as 'Conference Name',
	Date, StartTime, EndTime, Workshops.Name as 'Workshop Name',
	ConferenceDayWorkshops.ParticipantsLimit - sum(ReservedSeats) as 'Available Places'
from Conferences
join ConferenceDays
on Conferences.ConferenceID = ConferenceDays.ConferenceID
join ConferenceDayWorkshops
on ConferenceDays.ConferenceDayID = ConferenceDayWorkshops.ConferenceDayID
join Workshops
on ConferenceDayWorkshops.WorkshopID = Workshops.WorkshopID
left join WorkshopReservation
on ConferenceDayWorkshops.ConferenceDayWorkshopID = WorkshopReservation.ConferenceDayWorkshopID
group by Conferences.ConferenceID, Conferences.Name, Date, StartDate, StartTime,
	EndTime, Workshops.Name, ConferenceDayWorkshops.ParticipantsLimit