use dlugosz_a

--utw
create table Customers (
	CustomerID int not null primary key identity(0,1),
	Street varchar(74),
	HouseNumber varchar(5),
	AppartmentNumber int,
	City varchar(34),
	PostalCode char(6) check(PostalCode like '[0-9][0-9]-[0-9][0-9][0-9]'),
)

--utw
create table Companies (
	CompanyID int not null primary key foreign key references Customers(CustomerID),
	CompanyName varchar(150) not null,
	NIP char(10) unique not null,
	Phone varchar(12) unique not null check(Phone like '+%'),
	Email varchar(100)
)

--utw
create table Participants (
	ParticipantID int not null primary key identity(0,1),
	FirstName varchar(30) not null,
	LastName varchar(50) not null,
	Phone varchar(15) unique check(Phone like '+%'),
	Email varchar(50)
)

--utw
create table Student (
	ParticipantID int not null primary key foreign key references Participants(ParticipantID),
	StudentCardNumber varchar(10) not null
)

--utw
create table EmployeesOfCompanies (
	ParticipantID int not null foreign key references Participants(ParticipantID),
	CompanyID int not null foreign key references Companies(CompanyID),
	primary key clustered(ParticipantID, CompanyID)
)

--utw
create table ConferenceReservations (
	ReservationID int not null primary key identity(0,1),
	ConferenceID int not null foreign key references Conferences(ConferenceID),
	CustomerID int not null foreign key references Customers(CustomerID),
	DateOrdered date not null,
	DatePaid date
)

--utw
create table Conferences (
	ConferenceID int not null primary key identity(0,1),
	OrderID int not null foreign key references ConferenceOrders(OrderID),
	Name varchar(200) not null,
	StartDate date not null,
	EndDate date not null,
	BasePrice money,
	StudentDiscount real check(StudentDiscount between 0 and 1),
	ParticipantsLimit int
)

--utw
create table ConferencePricetables (
	PriceID int not null primary key,
	ConferenceID int not null foreign key references Conferences(ConferenceID),
	PriceStartsOn date not null,
	PriceEndsOn date not null,
	DiscountRate real not null check(DiscountRate between 0 and 1),
)

--utw
create table OurEmployees (
	EmployeeID int not null primary key identity(0,1),
	FirstName varchar(30) not null,
	LastName varchar(50) not null,
	BirthDate date,
	HireDate date,
	Street varchar(74),
	HouseNumber varchar(5),
	AppartmentNumber int,
	City varchar(34),
	PostalCode char(6) check(PostalCode like '[0-9][0-9]-[0-9][0-9][0-9]'),
	Phone varchar(15) unique not null check(Phone like '+%')
)

--utw
create table ConferenceDays (
	ConferenceDayID int not null primary key identity(0,1),
	ConferenceID int not null foreign key references Conferences(ConferenceID),
	Date date not null,
	DayOrdinal smallint not null
)

--utw
create table ConferenceDayReservation (
	DayReservationID int not null primary key identity(0,1),
	ConferenceDayID int not null foreign key references ConferenceDays(ConferenceDayID),
	ReservedSeats int not null
)

--utw
create table ConferenceDayParticipants (
	ConferenceDayParticipantID int not null primary key identity(0,1),
	ConferenceDayID int not null foreign key references ConferenceDays(ConferenceDayID),
	ParticipantID int not null foreign key references Participants(ParticipantID)
)

--utw
create table ConferenceEmployees (
	ConferenceID int not null,
	EmployeeID int not null,
	primary key clustered (ConferenceID, EmployeeID),
	foreign key (ConferenceID) references Conferences(ConferenceID),
	foreign key (EmployeeID)   references OurEmployees(EmployeeID)
)

--utw
create table Workshops (
	WorkshopID int not null primary key identity(0,1),
	Name varchar(100) not null,
	Description varchar(1000)
)

--utw
create table ConferenceDayWorkshops (
	ConferenceDayWorkshopID int not null primary key identity(0,1),
	ConferenceDayID int not null foreign key references ConferenceDays(ConferenceDayID),
	WorkshopID int not null foreign key references Workshops(WorkshopID),
	StartTime time not null,
	EndTime time not null,
	Price money,
	ParticipantsLimit int,
)

--utw
create table WorkshopReservation (
	WorkshopReservationID int not null primary key identity(0,1),
	ConferenceDayWorkshopID int not null foreign key references ConferenceDayWorkshops(ConferenceDayWorkshopID),
	ConferenceDayReservationID int not null foreign key references ConferenceDayReservation(DayReservationID),
	ReservedSeats int not null
)

--utw
create table WorkshopParticipants (
	ConferenceDayParticipantID int not null, 
	ConferenceDayWorkshopID int not null,
	primary key clustered (ConferenceDayParticipantID, ConferenceDayWorkshopID),
	foreign key (ConferenceDayParticipantID) references ConferenceDayParticipants(ConferenceDayParticipantID),
	foreign key (ConferenceDayWorkshopID) references ConferenceDayWorkshops(ConferenceDayWorkshopID)
)

create table Addresses (
	AddressID int not null primary key identity(0,1),
	Street varchar(80),
	HouseNumber varchar(5),
	AppartmentNumber int,
	City varchar(40),
	PostalCode char(6) check(PostalCode like '[0-9][0-9]-[0-9][0-9][0-9]')
)

create table Countries (
	CountryID int not null primary key identity(0,1),
	CountryName varchar(80) not null,
)

create table Regions (
	RegionID int not null primary key identity(0,1),
	RegionName varchar(80) not null,
	CountryID int not null foreign key references Countries(CountryID)
)

create table Cities (
	CityID int not null primary key identity(0,1),
	CityName varchar(80) not null,
	RegionID int not null foreign key references Regions(RegionID)
)

create table PrivateCustomers (
	CustomerID int not null primary key foreign key references Customers(CustomerID),
	ParticipantID int not null foreign key references Participants(ParticipantID)
)

select * from Participants
inner join PrivateCustomers
	on Participants.ParticipantID = PrivateCustomers.ParticipantID
inner join Customers
	on Customers.CustomerID = PrivateCustomers.CustomerID
inner join Addresses
	on Addresses.AddressID = Customers.AddressID
inner join Cities
	on Addresses.CityID = Cities.CityID
inner join Regions
	on Cities.RegionID = Regions.RegionID
inner join Countries
	on Regions.CountryID = Countries.CountryID