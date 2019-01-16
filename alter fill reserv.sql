USE [dlugosz_a]
GO
/****** Object:  StoredProcedure [dbo].[FillReservation]    Script Date: 16/01/2019 17:21:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[FillReservation]
	@CustomerEmail VARCHAR(100),
	@DateOrdered DATE,
	@ConferenceName VARCHAR(200),
	@ConfDayDate DATE,
	@FirstName VARCHAR(30),
	@LastName VARCHAR(50),
	@ParticipantPhone VARCHAR(15),
	@ParticipantEmail VARCHAR(100),
	@StudentCardNumber VARCHAR(10),
	@ParticipantID INT OUTPUT
AS
BEGIN
BEGIN TRY
	BEGIN TRANSACTION tr
		-- Wyszukaj czy w bazie nie ma już uczestnika o takim mailu
		DECLARE @FoundID int
		EXEC @FoundID = dbo.FindParticipantByEmail @Email = @ParticipantEmail -- varchar(100)

		-- Sprawdź czy dane są pełne
		IF (@FirstName IS NULL OR @LastName IS NULL OR @ParticipantEmail IS NULL) AND @FoundID IS null BEGIN
			RAISERROR ('Dane niepełne', 11,1)
		END

		-- Znajdź rezerwację dnia
		DECLARE @ReservationID INT
		EXEC FindConferenceDayReservation @ConferenceName, @ConfDayDate, @CustomerEmail, @DateOrdered, @ReservationID output
		IF @ReservationID IS NULL BEGIN 
			RAISERROR ('Nie znaleziono rezerwacji', 11,1)
		END
		PRINT 'Rezerwacja ' + CAST(@ReservationID AS VARCHAR)

		-- Znajdź wszystkie nieuzupełnione ParticipantID z tej rezerwacji
		DECLARE @EmptyParticipantIDs TABLE (ParticipantID INT NOT NULL)
		INSERT INTO @EmptyParticipantIDs (ParticipantID)
			SELECT cdp.ParticipantID
			FROM dbo.ConferenceDayParticipants cdp
			INNER JOIN dbo.Participants ON Participants.ParticipantID = cdp.ParticipantID
			WHERE ConferenceDayReservationID = @ReservationID AND LastName IS NULL
		DECLARE @size INT = (SELECT COUNT(*) FROM @EmptyParticipantIDs)
		PRINT 'rozm ' + CAST(@size AS VARCHAR)
		
		-- Wybierz ID które trzeba uzupełnić
		IF @StudentCardNumber IS NULL
			SET @ParticipantID = (SELECT MIN(ParticipantID) FROM (SELECT * FROM @EmptyParticipantIDs EXCEPT SELECT ParticipantID FROM dbo.Students) t);
		ELSE
			SET @ParticipantID = (SELECT MIN(ParticipantID) FROM (SELECT * FROM @EmptyParticipantIDs INTERSECT SELECT ParticipantID FROM dbo.Students) t);
		PRINT CAST(@ParticipantID AS VARCHAR)

		-- Jeśli jest jeszcze nieuzupełniona rezerwacja
		IF @ParticipantID IS NOT NULL BEGIN 
			-- Jeśli już jest uczestnik o takim mailu
			IF @FoundID IS NOT NULL BEGIN
				UPDATE ConferenceDayParticipants
				SET ParticipantID = @FoundID
				WHERE ParticipantID = @ParticipantID AND ConferenceDayReservationID = @ReservationID
			END ELSE BEGIN 
				UPDATE dbo.Participants
				SET FirstName = @FirstName, LastName = @LastName, Email = @ParticipantEmail, Phone = @ParticipantPhone 
				WHERE ParticipantID = @ParticipantID
				UPDATE dbo.Students
				SET StudentCardNumber = @StudentCardNumber
				WHERE ParticipantID = @ParticipantID
			END 
		END
		
	COMMIT TRANSACTION tr
END TRY
BEGIN CATCH
	PRINT ERROR_MESSAGE()
	ROLLBACK TRAN tr
END CATCH
END



DECLARE @ID int
EXEC FillReservation @CustomerEmail = 'kontakt@agh.edu.pl', 
@DateOrdered = '2019-01-16', @ConferenceName = 'SSMS w dwa dni', @ConfDayDate = '2019-03-01',
@FirstName = 'Jakub',@LastName = 'Raban', @ParticipantPhone = '668033496', @ParticipantEmail =  'jakub.raban@gmail.com',
@StudentCardNumber = '296657', @ParticipantID = @ID
PRINT CAST(@ID as varchar)