CREATE FUNCTION HasParticipantCollidingWorkshops(@NewWorkshopID INT) 
RETURNS BIT
BEGIN
	DECLARE @Times TABLE (
		StartTime TIME,
		EndTime time
	)
	INSERT INTO @Times
	SELECT StartTime, EndTime
	FROM dbo.WorkshopParticipants
	INNER JOIN dbo.ConferenceDayWorkshops ON ConferenceDayWorkshops.ConferenceDayWorkshopID = WorkshopParticipants.ConferenceDayWorkshopID
	WHERE ConferenceDayID = (SELECT ConferenceDayID
							FROM dbo.ConferenceDayWorkshops
							WHERE ConferenceDayWorkshopID = @NewWorkshopID)
	ORDER BY StartTime


END
GO
