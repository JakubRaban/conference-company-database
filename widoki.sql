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