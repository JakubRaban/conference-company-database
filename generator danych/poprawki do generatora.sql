UPDATE dbo.Conferences SET PostalCode = NULL WHERE CityID IS NULL
UPDATE Conferences SET StudentDiscount = ROUND(StudentDiscount,2)
UPDATE Conferences SET BasePriceForDay = ROUND(BasePriceForDay,2)
DELETE FROM dbo.ConferenceDayWorkshops WHERE [dbo].[ConferenceSize]([ConferenceDayID])<[ParticipantsLimit]
UPDATE dbo.ConferenceDayWorkshops SET price = 0 WHERE price IS NULL
UPDATE dbo.ConferenceDayWorkshops SET price = ROUND(Price, 1)
UPDATE dbo.ConferenceDayWorkshops SET StartTime = CONVERT(varchar(5), StartTime)
UPDATE dbo.ConferenceDayWorkshops SET EndTime = CONVERT(VARCHAR(5), EndTime)
DELETE FROM ConferenceReservations WHERE ReservationID NOT IN (SELECT ReservationID FROM ConferenceDayReservation)
DELETE FROM ConferencePricetables WHERE DiscountRate < 0.01