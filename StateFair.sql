USE master;
GO

IF DB_ID('StateFairDB') IS NOT NULL
BEGIN
    ALTER DATABASE StateFairDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE StateFairDB;
END;
GO

CREATE DATABASE StateFairDB;
GO

USE StateFairDB;
GO

/* =========================================
   REFERENCE TABLES
   ========================================= */

CREATE TABLE ApplicationStatus_ref (
    ApplicationStatus VARCHAR(30) NOT NULL PRIMARY KEY
);
GO

INSERT INTO ApplicationStatus_ref (ApplicationStatus)
VALUES
('Draft'),
('Submitted'),
('UnderReview'),
('Approved'),
('Rejected'),
('Withdrawn');
GO

CREATE TABLE PermitStatus_ref (
    PermitStatus VARCHAR(30) NOT NULL PRIMARY KEY
);
GO

INSERT INTO PermitStatus_ref (PermitStatus)
VALUES
('Requested'),
('Received'),
('Approved'),
('Denied');
GO

CREATE TABLE BoothAvailabilityStatus_ref (
    BoothAvailabilityStatus VARCHAR(30) NOT NULL PRIMARY KEY
);
GO

INSERT INTO BoothAvailabilityStatus_ref (BoothAvailabilityStatus)
VALUES
('Available'),
('Reserved'),
('Assigned'),
('Unavailable');
GO

CREATE TABLE BoothAssignmentStatus_ref (
    AssignmentStatus VARCHAR(30) NOT NULL PRIMARY KEY
);
GO

INSERT INTO BoothAssignmentStatus_ref (AssignmentStatus)
VALUES
('Proposed'),
('Confirmed'),
('Cancelled'),
('Reassigned');
GO

CREATE TABLE AttendanceStatus_ref (
    AttendanceStatus VARCHAR(30) NOT NULL PRIMARY KEY
);
GO

INSERT INTO AttendanceStatus_ref (AttendanceStatus)
VALUES
('NotCheckedIn'),
('CheckedIn'),
('NoShow');
GO

/* =========================================
   BASE TABLES
   ========================================= */

CREATE TABLE Vendor_tbl (
    VendorID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    VendorName VARCHAR(100) NOT NULL,
    ContactName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NULL,
    Phone VARCHAR(25) NULL,
    Category VARCHAR(50) NULL,
    InsertDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedBy VARCHAR(50) NOT NULL DEFAULT USER
);
GO

CREATE TABLE FairEvent_tbl (
    FairEventID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    FairYear INT NOT NULL,
    EventName VARCHAR(100) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    InsertDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedBy VARCHAR(50) NOT NULL DEFAULT USER
);
GO

CREATE TABLE OperationalPeriod_tbl (
    OperationalPeriodID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    FairEventID INT NOT NULL,
    PeriodName VARCHAR(50) NOT NULL,
    PeriodStart DATE NOT NULL,
    PeriodEnd DATE NOT NULL,
    InsertDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedBy VARCHAR(50) NOT NULL DEFAULT USER,
    CONSTRAINT FK_OperationalPeriod_FairEvent
        FOREIGN KEY (FairEventID) REFERENCES FairEvent_tbl(FairEventID)
);
GO

CREATE TABLE Booth_tbl (
    BoothID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    OperationalPeriodID INT NOT NULL,
    BoothCode VARCHAR(20) NOT NULL,
    Zone VARCHAR(50) NULL,
    BoothSize VARCHAR(30) NULL,
    BoothAvailabilityStatus VARCHAR(30) NOT NULL,
    InsertDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedBy VARCHAR(50) NOT NULL DEFAULT USER,
    CONSTRAINT UQ_BoothCode UNIQUE (BoothCode),
    CONSTRAINT FK_Booth_OperationalPeriod
        FOREIGN KEY (OperationalPeriodID) REFERENCES OperationalPeriod_tbl(OperationalPeriodID),
    CONSTRAINT FK_Booth_AvailabilityStatus
        FOREIGN KEY (BoothAvailabilityStatus) REFERENCES BoothAvailabilityStatus_ref(BoothAvailabilityStatus)
);
GO

CREATE TABLE VendorApplication_tbl (
    ApplicationID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    VendorID INT NOT NULL,
    FairEventID INT NOT NULL,
    SubmittedDate DATE NOT NULL,
    ApplicationStatus VARCHAR(30) NOT NULL,
    DecisionDate DATE NULL,
    Notes VARCHAR(255) NULL,
    InsertDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedBy VARCHAR(50) NOT NULL DEFAULT USER,
    CONSTRAINT FK_VendorApplication_Vendor
        FOREIGN KEY (VendorID) REFERENCES Vendor_tbl(VendorID),
    CONSTRAINT FK_VendorApplication_FairEvent
        FOREIGN KEY (FairEventID) REFERENCES FairEvent_tbl(FairEventID),
    CONSTRAINT FK_VendorApplication_Status
        FOREIGN KEY (ApplicationStatus) REFERENCES ApplicationStatus_ref(ApplicationStatus)
);
GO

CREATE TABLE PermitType_tbl (
    PermitTypeID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PermitName VARCHAR(100) NOT NULL,
    PermitAuthority VARCHAR(100) NULL,
    InsertDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedBy VARCHAR(50) NOT NULL DEFAULT USER
);
GO

/* =========================================
   ASSOCIATIVE / TRANSACTION TABLES
   ========================================= */

CREATE TABLE ApplicationPermit_lnk (
    ApplicationPermitID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ApplicationID INT NOT NULL,
    PermitTypeID INT NOT NULL,
    PermitStatus VARCHAR(30) NOT NULL,
    ReceivedDate DATE NULL,
    InsertDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedBy VARCHAR(50) NOT NULL DEFAULT USER,
    CONSTRAINT FK_ApplicationPermit_Application
        FOREIGN KEY (ApplicationID) REFERENCES VendorApplication_tbl(ApplicationID),
    CONSTRAINT FK_ApplicationPermit_PermitType
        FOREIGN KEY (PermitTypeID) REFERENCES PermitType_tbl(PermitTypeID),
    CONSTRAINT FK_ApplicationPermit_Status
        FOREIGN KEY (PermitStatus) REFERENCES PermitStatus_ref(PermitStatus)
);
GO

CREATE TABLE BoothAssignment_tbl (
    BoothAssignmentID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ApplicationID INT NOT NULL,
    BoothID INT NOT NULL,
    AssignDate DATE NOT NULL,
    UnassignDate DATE NULL,
    AssignmentStatus VARCHAR(30) NOT NULL,
    InsertDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedBy VARCHAR(50) NOT NULL DEFAULT USER,
    CONSTRAINT FK_BoothAssignment_Application
        FOREIGN KEY (ApplicationID) REFERENCES VendorApplication_tbl(ApplicationID),
    CONSTRAINT FK_BoothAssignment_Booth
        FOREIGN KEY (BoothID) REFERENCES Booth_tbl(BoothID),
    CONSTRAINT FK_BoothAssignment_Status
        FOREIGN KEY (AssignmentStatus) REFERENCES BoothAssignmentStatus_ref(AssignmentStatus)
);
GO

CREATE TABLE ParticipationRecord_tbl (
    ParticipationID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    BoothAssignmentID INT NOT NULL,
    OperationalPeriodID INT NOT NULL,
    CheckInDate DATE NULL,
    AttendanceStatus VARCHAR(30) NOT NULL,
    Notes VARCHAR(255) NULL,
    InsertDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUpdatedBy VARCHAR(50) NOT NULL DEFAULT USER,
    CONSTRAINT FK_Participation_BoothAssignment
        FOREIGN KEY (BoothAssignmentID) REFERENCES BoothAssignment_tbl(BoothAssignmentID),
    CONSTRAINT FK_Participation_OperationalPeriod
        FOREIGN KEY (OperationalPeriodID) REFERENCES OperationalPeriod_tbl(OperationalPeriodID),
    CONSTRAINT FK_Participation_AttendanceStatus
        FOREIGN KEY (AttendanceStatus) REFERENCES AttendanceStatus_ref(AttendanceStatus)
);
GO

/* =========================================
   HISTORY TABLES
   ========================================= */

CREATE TABLE Vendor_history_tbl (
    VendorID INT NOT NULL,
    VendorName VARCHAR(100) NOT NULL,
    ContactName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NULL,
    Phone VARCHAR(25) NULL,
    Category VARCHAR(50) NULL,
    InsertDateTime DATETIME NOT NULL,
    LastUpdatedDateTime DATETIME NOT NULL,
    LastUpdatedBy VARCHAR(50) NOT NULL,
    RecordAction VARCHAR(20) NOT NULL
);
GO

CREATE TABLE VendorApplication_history_tbl (
    ApplicationID INT NOT NULL,
    VendorID INT NOT NULL,
    FairEventID INT NOT NULL,
    SubmittedDate DATE NOT NULL,
    ApplicationStatus VARCHAR(30) NOT NULL,
    DecisionDate DATE NULL,
    Notes VARCHAR(255) NULL,
    InsertDateTime DATETIME NOT NULL,
    LastUpdatedDateTime DATETIME NOT NULL,
    LastUpdatedBy VARCHAR(50) NOT NULL,
    RecordAction VARCHAR(20) NOT NULL
);
GO

CREATE TABLE Booth_history_tbl (
    BoothID INT NOT NULL,
    OperationalPeriodID INT NOT NULL,
    BoothCode VARCHAR(20) NOT NULL,
    Zone VARCHAR(50) NULL,
    BoothSize VARCHAR(30) NULL,
    BoothAvailabilityStatus VARCHAR(30) NOT NULL,
    InsertDateTime DATETIME NOT NULL,
    LastUpdatedDateTime DATETIME NOT NULL,
    LastUpdatedBy VARCHAR(50) NOT NULL,
    RecordAction VARCHAR(20) NOT NULL
);
GO

CREATE TABLE BoothAssignment_history_tbl (
    BoothAssignmentID INT NOT NULL,
    ApplicationID INT NOT NULL,
    BoothID INT NOT NULL,
    AssignDate DATE NOT NULL,
    UnassignDate DATE NULL,
    AssignmentStatus VARCHAR(30) NOT NULL,
    InsertDateTime DATETIME NOT NULL,
    LastUpdatedDateTime DATETIME NOT NULL,
    LastUpdatedBy VARCHAR(50) NOT NULL,
    RecordAction VARCHAR(20) NOT NULL
);
GO

/* =========================================
   UPDATE TRIGGERS
   ========================================= */

CREATE TRIGGER trg_Vendor_update_history
ON Vendor_tbl
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Vendor_history_tbl (
        VendorID, VendorName, ContactName, Email, Phone, Category,
        InsertDateTime, LastUpdatedDateTime, LastUpdatedBy, RecordAction
    )
    SELECT
        d.VendorID, d.VendorName, d.ContactName, d.Email, d.Phone, d.Category,
        d.InsertDateTime, d.LastUpdatedDateTime, d.LastUpdatedBy, 'UPDATE'
    FROM deleted d;

    UPDATE v
    SET
        LastUpdatedDateTime = CURRENT_TIMESTAMP,
        LastUpdatedBy = USER
    FROM Vendor_tbl v
    INNER JOIN inserted i ON v.VendorID = i.VendorID;
END;
GO

CREATE TRIGGER trg_VendorApplication_update_history
ON VendorApplication_tbl
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO VendorApplication_history_tbl (
        ApplicationID, VendorID, FairEventID, SubmittedDate, ApplicationStatus,
        DecisionDate, Notes, InsertDateTime, LastUpdatedDateTime, LastUpdatedBy, RecordAction
    )
    SELECT
        d.ApplicationID, d.VendorID, d.FairEventID, d.SubmittedDate, d.ApplicationStatus,
        d.DecisionDate, d.Notes, d.InsertDateTime, d.LastUpdatedDateTime, d.LastUpdatedBy, 'UPDATE'
    FROM deleted d;

    UPDATE va
    SET
        LastUpdatedDateTime = CURRENT_TIMESTAMP,
        LastUpdatedBy = USER
    FROM VendorApplication_tbl va
    INNER JOIN inserted i ON va.ApplicationID = i.ApplicationID;
END;
GO

CREATE TRIGGER trg_Booth_update_history
ON Booth_tbl
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Booth_history_tbl (
        BoothID, OperationalPeriodID, BoothCode, Zone, BoothSize, BoothAvailabilityStatus,
        InsertDateTime, LastUpdatedDateTime, LastUpdatedBy, RecordAction
    )
    SELECT
        d.BoothID, d.OperationalPeriodID, d.BoothCode, d.Zone, d.BoothSize, d.BoothAvailabilityStatus,
        d.InsertDateTime, d.LastUpdatedDateTime, d.LastUpdatedBy, 'UPDATE'
    FROM deleted d;

    UPDATE b
    SET
        LastUpdatedDateTime = CURRENT_TIMESTAMP,
        LastUpdatedBy = USER
    FROM Booth_tbl b
    INNER JOIN inserted i ON b.BoothID = i.BoothID;
END;
GO

CREATE TRIGGER trg_BoothAssignment_update_history
ON BoothAssignment_tbl
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO BoothAssignment_history_tbl (
        BoothAssignmentID, ApplicationID, BoothID, AssignDate, UnassignDate, AssignmentStatus,
        InsertDateTime, LastUpdatedDateTime, LastUpdatedBy, RecordAction
    )
    SELECT
        d.BoothAssignmentID, d.ApplicationID, d.BoothID, d.AssignDate, d.UnassignDate, d.AssignmentStatus,
        d.InsertDateTime, d.LastUpdatedDateTime, d.LastUpdatedBy, 'UPDATE'
    FROM deleted d;

    UPDATE ba
    SET
        LastUpdatedDateTime = CURRENT_TIMESTAMP,
        LastUpdatedBy = USER
    FROM BoothAssignment_tbl ba
    INNER JOIN inserted i ON ba.BoothAssignmentID = i.BoothAssignmentID;
END;
GO

/* =========================================
   DELETE TRIGGERS
   ========================================= */

CREATE TRIGGER trg_Vendor_delete_history
ON Vendor_tbl
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Vendor_history_tbl (
        VendorID, VendorName, ContactName, Email, Phone, Category,
        InsertDateTime, LastUpdatedDateTime, LastUpdatedBy, RecordAction
    )
    SELECT
        d.VendorID, d.VendorName, d.ContactName, d.Email, d.Phone, d.Category,
        d.InsertDateTime, d.LastUpdatedDateTime, d.LastUpdatedBy, 'DELETE'
    FROM deleted d;
END;
GO

CREATE TRIGGER trg_VendorApplication_delete_history
ON VendorApplication_tbl
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO VendorApplication_history_tbl (
        ApplicationID, VendorID, FairEventID, SubmittedDate, ApplicationStatus,
        DecisionDate, Notes, InsertDateTime, LastUpdatedDateTime, LastUpdatedBy, RecordAction
    )
    SELECT
        d.ApplicationID, d.VendorID, d.FairEventID, d.SubmittedDate, d.ApplicationStatus,
        d.DecisionDate, d.Notes, d.InsertDateTime, d.LastUpdatedDateTime, d.LastUpdatedBy, 'DELETE'
    FROM deleted d;
END;
GO

CREATE TRIGGER trg_Booth_delete_history
ON Booth_tbl
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Booth_history_tbl (
        BoothID, OperationalPeriodID, BoothCode, Zone, BoothSize, BoothAvailabilityStatus,
        InsertDateTime, LastUpdatedDateTime, LastUpdatedBy, RecordAction
    )
    SELECT
        d.BoothID, d.OperationalPeriodID, d.BoothCode, d.Zone, d.BoothSize, d.BoothAvailabilityStatus,
        d.InsertDateTime, d.LastUpdatedDateTime, d.LastUpdatedBy, 'DELETE'
    FROM deleted d;
END;
GO

CREATE TRIGGER trg_BoothAssignment_delete_history
ON BoothAssignment_tbl
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO BoothAssignment_history_tbl (
        BoothAssignmentID, ApplicationID, BoothID, AssignDate, UnassignDate, AssignmentStatus,
        InsertDateTime, LastUpdatedDateTime, LastUpdatedBy, RecordAction
    )
    SELECT
        d.BoothAssignmentID, d.ApplicationID, d.BoothID, d.AssignDate, d.UnassignDate, d.AssignmentStatus,
        d.InsertDateTime, d.LastUpdatedDateTime, d.LastUpdatedBy, 'DELETE'
    FROM deleted d;
END;
GO

/* =========================================
   SAMPLE DATA
   ========================================= */

INSERT INTO Vendor_tbl (VendorName, ContactName, Email, Phone, Category)
VALUES
('North Star Foods', 'Jamie Carter', 'jamie@northstarfoods.com', '555-111-2222', 'Food'),
('Prairie Crafts', 'Morgan Lee', 'morgan@prairiecrafts.com', '555-333-4444', 'Crafts');
GO

INSERT INTO FairEvent_tbl (FairYear, EventName, StartDate, EndDate)
VALUES
(2026, 'Minnesota State Fair 2026', '2026-08-20', '2026-09-06');
GO

INSERT INTO OperationalPeriod_tbl (FairEventID, PeriodName, PeriodStart, PeriodEnd)
VALUES
(1, 'Setup', '2026-08-15', '2026-08-19'),
(1, 'Fair Days', '2026-08-20', '2026-09-06'),
(1, 'Tear Down', '2026-09-07', '2026-09-10');
GO

INSERT INTO Booth_tbl (OperationalPeriodID, BoothCode, Zone, BoothSize, BoothAvailabilityStatus)
VALUES
(2, 'A101', 'North Wing', '10x10', 'Available'),
(2, 'B205', 'Food Court', '20x20', 'Available');
GO

INSERT INTO VendorApplication_tbl (VendorID, FairEventID, SubmittedDate, ApplicationStatus, DecisionDate, Notes)
VALUES
(1, 1, '2026-04-01', 'Approved', '2026-04-15', 'Approved for food vendor space'),
(2, 1, '2026-04-03', 'Submitted', NULL, 'Awaiting review');
GO

INSERT INTO PermitType_tbl (PermitName, PermitAuthority)
VALUES
('Food Safety Permit', 'State Health Department'),
('Fire Safety Permit', 'Fire Marshal');
GO

INSERT INTO ApplicationPermit_lnk (ApplicationID, PermitTypeID, PermitStatus, ReceivedDate)
VALUES
(1, 1, 'Approved', '2026-04-20'),
(1, 2, 'Requested', NULL);
GO

INSERT INTO BoothAssignment_tbl (ApplicationID, BoothID, AssignDate, UnassignDate, AssignmentStatus)
VALUES
(1, 2, '2026-05-01', NULL, 'Confirmed');
GO

INSERT INTO ParticipationRecord_tbl (BoothAssignmentID, OperationalPeriodID, CheckInDate, AttendanceStatus, Notes)
VALUES
(1, 2, '2026-08-20', 'CheckedIn', 'Vendor arrived on opening day');
GO

/* =========================================
   TEST UPDATES FOR HISTORY
   ========================================= */

UPDATE Vendor_tbl
SET Phone = '555-999-8888'
WHERE VendorID = 1;
GO

UPDATE Booth_tbl
SET BoothAvailabilityStatus = 'Assigned'
WHERE BoothID = 2;
GO

UPDATE BoothAssignment_tbl
SET AssignmentStatus = 'Reassigned',
    UnassignDate = '2026-08-25'
WHERE BoothAssignmentID = 1;
GO

/* =========================================
   VIEW HISTORY RESULTS
   ========================================= */

SELECT * FROM Vendor_history_tbl;
SELECT * FROM Booth_history_tbl;
SELECT * FROM BoothAssignment_history_tbl;
SELECT * FROM VendorApplication_history_tbl;
GO

INSERT INTO Vendor_tbl (VendorName, ContactName, Email, Phone, Category)
VALUES
('Twin Cities BBQ', 'Alex Johnson', 'alex@tcbbq.com', '555-222-1111', 'Food'),
('Midwest Sweets', 'Taylor Smith', 'taylor@sweets.com', '555-333-2222', 'Food'),
('Handmade Crafts Co', 'Jordan Lee', 'jordan@crafts.com', '555-444-3333', 'Crafts'),
('North Woods Apparel', 'Chris Miller', 'chris@apparel.com', '555-555-4444', 'Retail'),
('Fresh Farm Produce', 'Sam Wilson', 'sam@farm.com', '555-666-5555', 'Food'),
('Artisan Jewelry', 'Casey Brown', 'casey@jewelry.com', '555-777-6666', 'Crafts'),
('Lakeside Coffee', 'Jamie Green', 'jamie@coffee.com', '555-888-7777', 'Food'),
('Vintage Goods', 'Pat Taylor', 'pat@vintage.com', '555-999-8888', 'Retail');

INSERT INTO VendorApplication_tbl (VendorID, FairEventID, SubmittedDate, ApplicationStatus)
VALUES
(3, 1, GETDATE(), 'Submitted'),
(4, 1, GETDATE(), 'Approved'),
(5, 1, GETDATE(), 'Rejected'),
(6, 1, GETDATE(), 'Approved'),
(7, 1, GETDATE(), 'UnderReview'),
(8, 1, GETDATE(), 'Approved'),
(9, 1, GETDATE(), 'Submitted'),
(10, 1, GETDATE(), 'Approved');

INSERT INTO Booth_tbl (OperationalPeriodID, BoothCode, Zone, BoothSize, BoothAvailabilityStatus)
VALUES
(2, 'C301', 'East Wing', '10x10', 'Available'),
(2, 'D410', 'West Wing', '15x15', 'Available'),
(2, 'E515', 'Main Street', '20x20', 'Available'),
(2, 'F620', 'Food Court', '25x25', 'Available');

INSERT INTO BoothAssignment_tbl (ApplicationID, BoothID, AssignDate, AssignmentStatus)
VALUES
(4, 3, GETDATE(), 'Confirmed'),
(6, 4, GETDATE(), 'Confirmed'),
(8, 5, GETDATE(), 'Confirmed'),
(10, 6, GETDATE(), 'Confirmed');


INSERT INTO ParticipationRecord_tbl (BoothAssignmentID, OperationalPeriodID, CheckInDate, AttendanceStatus, Notes)
VALUES
(2, 2, GETDATE(), 'CheckedIn', 'On time'),
(3, 2, GETDATE(), 'CheckedIn', 'Set up early'),
(4, 2, GETDATE(), 'CheckedIn', 'Busy booth'),
(5, 2, GETDATE(), 'NoShow', 'Did not arrive');

SELECT 
    v.VendorName,
    va.ApplicationStatus,
    b.BoothCode,
    pr.AttendanceStatus
FROM Vendor_tbl v
JOIN VendorApplication_tbl va ON v.VendorID = va.VendorID
LEFT JOIN BoothAssignment_tbl ba ON va.ApplicationID = ba.ApplicationID
LEFT JOIN Booth_tbl b ON ba.BoothID = b.BoothID
LEFT JOIN ParticipationRecord_tbl pr ON ba.BoothAssignmentID = pr.BoothAssignmentID;