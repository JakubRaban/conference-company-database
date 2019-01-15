

EXEC dbo.AddPrivateCustomer @ParticipantPhone = '123456789', -- nvarchar(15)
                            @Street = 'Leœmiana',           -- nvarchar(80)
                            @HouseNumber = N'4',      -- nvarchar(5)
                            @AppartmentNumber = null,   -- int
                            @PostalCode = '40-334',        -- char(6)
                            @CityName = 'Oleœnica',          -- varchar(80)
                            @RegionName = 'Dolnoœl¹skie',        -- varchar(80)
                            @CountryName = 'Polska',        -- varchar(80)
							@FirstName = 'Pawe³',
							@LastName = 'D³ugosz',
							@Email = 'jp2137@gmail.com'

EXEC dbo.NewCompany @CompanyName = N'AGH',    -- nvarchar(150)
                    @NIP = '4287924822',             -- char(10)
                    @Phone = '23456789',           -- varchar(15)
                    @Email = 'kontakt@agh.edu.pl',           -- varchar(100)
                    @Street = N'Mickiewicza',         -- nvarchar(74)
                    @HouseNumber = '30',     -- varchar(5)
                    @AppartmentNumber = NULL, -- int
                    @CityName = 'Kraków',        -- varchar(80)
                    @PostalCode = '22-333',      -- char(6)
                    @RegionName = 'Ma³opolskie',      -- varchar(80)
                    @CountryName = 'Polska'      -- varchar(80)

EXEC dbo.NewConferenceReservation @CustomerPhone = '23456789',                   -- varchar(15)
                                  @ReservationID = null

SELECT * FROM dbo.ConferenceReservations

SELECT * FROM dbo.Customers
SELECT * FROM dbo.Participants
SELECT * FROM dbo.PrivateCustomers
SELECT * FROM dbo.Companies

EXEC dbo.MarkReservationAsPaid @Phone = '23456789',                -- varchar(15)
                               @DateOrdered = '2019-01-15' -- date

EXEC dbo.NewDayReservation @CustomerPhone = '23456789',  -- varchar(15)
                           @ConferenceName = 'SSMS w dwa dni', -- varchar(200)
                           @Date = '2019-03-02', -- date
                           @AdultSeats = 3,      -- int
                           @StudentSeats = 2     -- int

SELECT * FROM dbo.ConferenceDayReservation

DECLARE @ConferenceID INT,
        @ConferenceDayID INT;
EXEC dbo.FindConference @ConferenceName = 'SSMS w dwa dni',                      -- varchar(200)
                        @Date = '2019-03-02',                      -- date
                        @ConferenceID = @ConferenceID OUTPUT,      -- int
                        @ConferenceDayID = @ConferenceDayID OUTPUT -- int

PRINT CAST(@ConferenceID AS VARCHAR)
PRINT CAST (@ConferenceDayID AS VARCHAR)

DECLARE @ReservationID INT;
EXEC dbo.FindReservation @CustomerPhone = '23456789',                   -- varchar(15)
                         @ReservationID = @ReservationID OUTPUT -- int
PRINT CAST (@ReservationID AS VARCHAR)

SELECT * FROM dbo.ConferenceDayParticipants
INNER JOIN dbo.Participants ON Participants.ParticipantID = ConferenceDayParticipants.ParticipantID
LEFT JOIN dbo.Students ON Students.ParticipantID = Participants.ParticipantID

EXEC dbo.AddWorkshopAtDay @WorkshopName = 'Naucz sie baz danych z Anna Zygmunt',      -- varchar(100)
                          @ConferenceName = 'SSMS w dwa dni',    -- varchar(200)
                          @Day = 2,                -- smallint
                          @StartTime = '10:00:00', -- time(7)
                          @EndTime = '11:30:00',   -- time(7)
                          @Price = 49.99,           -- money
                          @ParticipantsLimit = 50   -- int

SELECT * FROM dbo.ConferenceDayWorkshops

SELECT * FROM dbo.Workshops