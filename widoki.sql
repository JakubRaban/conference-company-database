create view FrequentCustomers as
select firstname, lastname, companyname, count(reservationid) as NumberOfReservations
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