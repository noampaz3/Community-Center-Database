-- ========================================================================
-- COMMUNITY CENTER DATABASE - DATA MANIPULATION & ANALYTICS (DML)
-- ========================================================================

-- Retrieve residents who borrowed equipment in the current month
SELECT DISTINCT res .ResidentID , res .FirstName , res . LastName ,eq.SerialNumber ,eq. ItemName 
FROM Residents res RIGHT JOIN Loans lo  
      ON res .ResidentID = lo .ResidentID 
      JOIN Equipment eq ON lo .SerialNumber = eq.SerialNumber 
WHERE MONTH(lo.LoanDate) = MONTH(GETDATE())  
      AND YEAR(lo.LoanDate) = YEAR(GETDATE()) 
ORDER BY res .ResidentID 

-- Identify highly active residents who participated in more than one activity
SELECT ResidentID, FirstName+' '+LastName fullName, AssignedCenterName
FROM Residents
WHERE ResidentID IN (SELECT DISTINCT a1.ResidentID
FROM ActivityRegistrations a1 JOIN ActivityRegistrations a2
       ON a1.ResidentID = a2.ResidentID
WHERE a1.ActivityCode <> a2.ActivityCode OR a1.SessionDate <> a2.SessionDate
       OR a1.StartTime <> a2.StartTime)

-- List all facility rooms equipped with projectors, sorted by maximum capacity
SELECT CenterName, RoomNumber, ManagerID, Capacity
FROM Rooms
WHERE HasProjector = 1
ORDER BY Capacity DESC, CenterName, RoomNumber


-- ========================================================================
-- ADVANCED BUSINESS QUERIES & VIEWS
-- ========================================================================

-- Query 1: Marketing Review - Identify recent activities (last 14 days) with zero registrations
SELECT s.ActivityCode,ActivityName,s.SessionDate
FROM ActivitySessions s join Activities a on s.ActivityCode = a.ActivityCode
WHERE DATEDIFF(DAY,SessionDate,GETDATE()) BETWEEN 0 AND 14 AND NOT EXISTS(SELECT *
				 FROM ActivityRegistrations ar
				 WHERE ar.ActivityCode = s.ActivityCode and ar.SessionDate = s.SessionDate)

-- Query 2: Donor Retention - Create a dynamic view of highly engaged residents (Volunteers & Donors)
CREATE VIEW TargetedResidents AS
SELECT ResidentID, FirstName + ' ' + LastName AS FullName, Email
FROM Residents
WHERE ResidentID IN (
    SELECT ResidentID
    FROM ActivityRegistrations
    GROUP BY ResidentID
    HAVING COUNT(*) = 1)

AND ResidentID IN (
    SELECT VolunteerID 
    FROM Volunteers)

AND ResidentID IN ( 
    SELECT ResidentID 
    FROM Donations)

-- Query 3: Resource Optimization - Find the most active room in the top 3 centers with the highest equipment loan rates    
SELECT 
    TopCenters.CenterName,
    (
        SELECT TOP 1 RoomNumber
        FROM ActivitySessions s
        WHERE s.CenterName = TopCenters.CenterName
        GROUP BY RoomNumber
        ORDER BY COUNT(*) DESC
    ) AS MostActiveRoom
FROM (
    SELECT TOP 3 eq.CenterName
    FROM Equipment eq 
    JOIN Loans lo ON eq.SerialNumber = lo.SerialNumber
    GROUP BY eq.CenterName
    ORDER BY COUNT(*) DESC
) AS TopCenters

-- Query 4: Volunteer Engagement - Classify social projects based on volunteer participation levels
SELECT p.ProjectName, COUNT(distinct pv.VolunteerID) NumOfUniqueVol,
CASE 
        WHEN COUNT(DISTINCT pv.VolunteerID) > 15 THEN 'High Engagement'
        WHEN COUNT(DISTINCT pv.VolunteerID) BETWEEN 5 AND 15 THEN 'Moderate Engagement'
        WHEN COUNT(DISTINCT pv.VolunteerID) BETWEEN 1 AND 4 THEN 'Low Engagement'
        ELSE 'No Volunteers'
        END AS ProjectProfile
FROM ProjectVolunteering pv RIGHT JOIN Projects p ON pv.ProjectName = p.ProjectName
GROUP BY p.ProjectName

-- Query 5: Resident Profiling - Stored Procedure to generate a comprehensive activity profile for a specific resident
CREATE PROCEDURE GetResidentActivitySummary
    @ResID CHAR(9)
AS
BEGIN
    SELECT 
        ResidentID,
        FirstName + ' ' + LastName AS FullName,

        (SELECT COUNT(DISTINCT ActivityCode) 
         FROM ActivityRegistrations 
         WHERE ResidentID = r.ResidentID) AS TotalActivities,
        
        (SELECT COUNT(*) 
         FROM ProjectVolunteering 
         WHERE VolunteerID = r.ResidentID) AS TotalVolunteeringTasks,
       
        (SELECT COUNT(*) 
         FROM Loans 
         WHERE ResidentID = r.ResidentID) AS TotalLoans
        
    FROM Residents r
    WHERE ResidentID = @ResID
END
