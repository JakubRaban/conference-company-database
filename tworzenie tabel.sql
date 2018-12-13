use dlugosz_a

create table Customers (
	CustomerID int not null primary key identity(0,1),
	Street varchar(74),
	HouseNumber varchar(5),
	AppartmentNumber int,
	City varchar(34),
	PostalCode char(6) check(PostalCode like '[0-9][0-9]-[0-9][0-9][0-9]'),
	Phone varchar(12) unique not null check(Phone like '+%'),
	Email varchar(50)
)

create table CompanyCustomers (
	CustomerID int not null primary key foreign key references Customers(CustomerID),
	CompanyName varchar(150) not null,
	NIP char(10) unique not null
)

create table PrivateCustomers (
	CustomerID int not null primary key foreign key references Customers(CustomerID),
	FirstName varchar(30) not null,
	LastName varchar(50) not null,
	PESEL char(11) unique not null
)

create table Conferences (
	ConferenceID int not null primary key identity(0,1),
	CustomerID int not null foreign key references Customers(CustomerID),
	StartDate date not null,
	EndDate date not null,
	StudentDiscount real not null check(StudentDiscount between 0 and 1)
)

create table Employees (
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
	Phone varchar(12) unique not null check(Phone like '+%')
)

create table ConferenceDay (
	DayID int not null primary key identity(0,1),
	ConferenceID int not null foreign key references Conferences(ConferenceID),
	Day date not null,
	DayOrdinal smallint not null,
	ParticipantsLimit int not null
)

create table Participants (
	ParticipantID int not null primary key identity(0,1),
	FirstName varchar(30) not null,
	LastName varchar(50) not null,
	Phone varchar(12) unique not null check(Phone like '+%'),
	Email varchar(50)
)

create table ConferenceDayParticipants (
	DayID int not null,
	ParticipantID int not null,
	primary key clustered (DayID, ParticipantID),
	foreign key (DayID) references ConferenceDay(DayID),
	foreign key (ParticipantID) references Participants(ParticipantID)
)

create table ConferenceEmployees (
	ConferenceID int not null,
	EmployeeID int not null,
	primary key clustered (ConferenceID, EmployeeID),
	foreign key (ConferenceID) references Conferences(ConferenceID),
	foreign key (EmployeeID)   references Employees(EmployeeID)
)

create table Workshops (
	WorkshopID int not null primary key identity(0,1),
	ConferenceDayID int not null foreign key references ConferenceDay(DayID),
	Name varchar(100) not null,
	StartTime time not null,
	EndTime time not null,
	Price money not null,
	ParticipantsLimit int not null
)

create table WorkshopParticipants (
	ParticipantID int not null,
	WorkshopID int not null,
	primary key clustered (ParticipantID, WorkshopID),
	foreign key (ParticipantID) references Participants(ParticipantID),
	foreign key (WorkshopID)    references Workshops(WorkshopID)
)

create table ConferenceParticipants (
	ConferenceID int not null,
	ParticipantID int not null,
	RegistrationDate date not null,
	IsPaid bit not null,
	primary key clustered (ConferenceID, ParticipantID),
	foreign key (ConferenceID) references Conferences(ConferenceID),
	foreign key (ParticipantID) references Participants(ParticipantID)
)

create table ConferencePricetable (
	ConferenceDayID int not null primary key foreign key references ConferenceDay(DayID),
	PriceValidFrom date not null,
	PriceValidity int not null check(PriceValidity >= 0),  -- 0 czyli tylko dziœ, 1 czyli do jutra itd.
	Price money not null
)

create table ConferenceDayReservation (
	ConferenceDayID int not null,
	CompanyCustomerID int not null,
	NumberOfSeats int not null,
	primary key clustered (ConferenceDayID, CompanyCustomerID),
	foreign key (ConferenceDayID) references ConferenceDay,
	foreign key (CompanyCustomerID) references CompanyCustomers(CustomerID)
)

create table WorkshopReservation (
	WorkshopID int not null,
	CompanyCustomerID int not null,
	NumberOfSeats int not null,
	primary key clustered (WorkshopID, CompanyCustomerID),
	foreign key (WorkshopID) references ConferenceDay,
	foreign key (CompanyCustomerID) references CompanyCustomers(CustomerID)
)