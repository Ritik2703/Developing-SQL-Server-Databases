USE Contacts;

IF EXISTS
(
	SELECT 1 FROM sys.tables WHERE [Name] = 'Roles'
)
BEGIN;
	DROP TABLE dbo.Roles;
END;

CREATE TABLE dbo.Roles
(
 RoleId				INT	IDENTITY(1,1)	NOT NULL,
 RoleTitle			VARCHAR(200)		NOT NULL,
 CONSTRAINT PK_Roles PRIMARY KEY CLUSTERED (RoleId)
);

GO