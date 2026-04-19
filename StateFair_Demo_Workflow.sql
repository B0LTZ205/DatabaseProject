USE StateFairDB;
GO

/* =========================================================
   State Fair Vendor & Operations Database
   Demo Workflow Script
   Purpose: Demonstrate how the system would be used
   ========================================================= */

/* ---------------------------------------------------------
   1. View all vendors and their applications
   --------------------------------------------------------- */
SELECT 
    v.VendorID,
    v.VendorName,
    v.ContactName,
    va.ApplicationID,
    va.ApplicationStatus,
    va.SubmittedDate,
    va.DecisionDate
FROM Vendor_tbl v
JOIN VendorApplication_tbl va
    ON v.VendorID = va.VendorID
ORDER BY v.VendorName;
GO

/* ---------------------------------------------------------
   2. Show approved vendors only
   --------------------------------------------------------- */
SELECT 
    v.VendorName,
    va.ApplicationID,
    va.ApplicationStatus
FROM Vendor_tbl v
JOIN VendorApplication_tbl va
    ON v.VendorID = va.VendorID
WHERE va.ApplicationStatus = 'Approved'
ORDER BY v.VendorName;
GO

/* ---------------------------------------------------------
   3. Show available booths
   --------------------------------------------------------- */
SELECT 
    BoothID,
    BoothCode,
    Zone,
    BoothSize,
    BoothAvailabilityStatus
FROM Booth_tbl
WHERE BoothAvailabilityStatus = 'Available'
ORDER BY BoothCode;
GO

/* ---------------------------------------------------------
   4. Show permit status by vendor application
   --------------------------------------------------------- */
SELECT 
    v.VendorName,
    va.ApplicationID,
    pt.PermitName,
    ap.PermitStatus,
    ap.ReceivedDate
FROM Vendor_tbl v
JOIN VendorApplication_tbl va
    ON v.VendorID = va.VendorID
JOIN ApplicationPermit_lnk ap
    ON va.ApplicationID = ap.ApplicationID
JOIN PermitType_tbl pt
    ON ap.PermitTypeID = pt.PermitTypeID
ORDER BY v.VendorName, pt.PermitName;
GO

/* ---------------------------------------------------------
   5. Assign a booth to an approved vendor
   Note: This is a sample insert. Adjust IDs if needed.
   --------------------------------------------------------- */
INSERT INTO BoothAssignment_tbl (
    ApplicationID,
    BoothID,
    AssignDate,
    UnassignDate,
    AssignmentStatus
)
VALUES (
    1,
    1,
    GETDATE(),
    NULL,
    'Confirmed'
);
GO

/* ---------------------------------------------------------
   6. View booth assignments
   --------------------------------------------------------- */
SELECT 
    ba.BoothAssignmentID,
    v.VendorName,
    b.BoothCode,
    ba.AssignDate,
    ba.UnassignDate,
    ba.AssignmentStatus
FROM BoothAssignment_tbl ba
JOIN VendorApplication_tbl va
    ON ba.ApplicationID = va.ApplicationID
JOIN Vendor_tbl v
    ON va.VendorID = v.VendorID
JOIN Booth_tbl b
    ON ba.BoothID = b.BoothID
ORDER BY ba.BoothAssignmentID;
GO

/* ---------------------------------------------------------
   7. Record vendor participation / check-in
   Note: Adjust BoothAssignmentID if needed.
   --------------------------------------------------------- */
INSERT INTO ParticipationRecord_tbl (
    BoothAssignmentID,
    OperationalPeriodID,
    CheckInDate,
    AttendanceStatus,
    Notes
)
VALUES (
    1,
    2,
    GETDATE(),
    'CheckedIn',
    'Vendor checked in successfully.'
);
GO

/* ---------------------------------------------------------
   8. View participation records
   --------------------------------------------------------- */
SELECT 
    v.VendorName,
    b.BoothCode,
    pr.CheckInDate,
    pr.AttendanceStatus,
    pr.Notes
FROM ParticipationRecord_tbl pr
JOIN BoothAssignment_tbl ba
    ON pr.BoothAssignmentID = ba.BoothAssignmentID
JOIN VendorApplication_tbl va
    ON ba.ApplicationID = va.ApplicationID
JOIN Vendor_tbl v
    ON va.VendorID = v.VendorID
JOIN Booth_tbl b
    ON ba.BoothID = b.BoothID
ORDER BY pr.ParticipationID;
GO

/* ---------------------------------------------------------
   9. Update a vendor record to demonstrate audit/history
   Note: This should create a history row if your trigger exists.
   --------------------------------------------------------- */
UPDATE Vendor_tbl
SET Phone = '555-000-1234'
WHERE VendorID = 1;
GO

/* ---------------------------------------------------------
   10. View vendor history table
   --------------------------------------------------------- */
SELECT *
FROM Vendor_history_tbl
ORDER BY LastUpdatedDateTime DESC;
GO

/* ---------------------------------------------------------
   11. Management report: vendors, booth, participation
   --------------------------------------------------------- */
SELECT 
    v.VendorName,
    va.ApplicationStatus,
    b.BoothCode,
    ba.AssignmentStatus,
    pr.AttendanceStatus,
    pr.CheckInDate
FROM Vendor_tbl v
LEFT JOIN VendorApplication_tbl va
    ON v.VendorID = va.VendorID
LEFT JOIN BoothAssignment_tbl ba
    ON va.ApplicationID = ba.ApplicationID
LEFT JOIN Booth_tbl b
    ON ba.BoothID = b.BoothID
LEFT JOIN ParticipationRecord_tbl pr
    ON ba.BoothAssignmentID = pr.BoothAssignmentID
ORDER BY v.VendorName;
GO

/* ---------------------------------------------------------
   12. Optional test: referential integrity example
   Uncomment to test a failure case.
   --------------------------------------------------------- */
-- INSERT INTO VendorApplication_tbl (VendorID, FairEventID, SubmittedDate, ApplicationStatus)
-- VALUES (999, 1, GETDATE(), 'Submitted');
-- GO


