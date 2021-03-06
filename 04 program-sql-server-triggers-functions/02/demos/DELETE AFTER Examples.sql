USE [WideWorldImporters]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
  Prep for demo
*/
ALTER TABLE [Sales].[OrderLines] DROP CONSTRAINT [FK_Sales_OrderLines_OrderID_Sales_Orders]
GO

ALTER TABLE [Sales].[OrderLines]  WITH CHECK ADD  CONSTRAINT [FK_Sales_OrderLines_OrderID_Sales_Orders] FOREIGN KEY([OrderID])
REFERENCES [Sales].[Orders] ([OrderID]) ON DELETE CASCADE
GO

ALTER TABLE [Sales].[OrderLines] CHECK CONSTRAINT [FK_Sales_OrderLines_OrderID_Sales_Orders]
GO


/*
  Add in the Boilerplate code to verify that data
  was actually modified. If not, return and save
  the work of the Trigger.

  With this change, we won't see the message when
  no data is modified.
*/
CREATE OR ALTER TRIGGER [Sales].[TD_Orders_AFTER]ON 
	[Sales].[Orders]AFTER DELETEAS
	BEGIN
		RAISERROR('The TD_Orders_AFTER trigger was fired',1,1);
	END;
GO

/*
 The Trigger will be fired REGARDLESS of actual data manipulation.
 Remember, it is the DML Action being called which causes 
 the Trigger to execute
*/
DELETE FROM Sales.Orders WHERE OrderID = 0;
GO

DROP TRIGGER Sales.TD_Orders_AFTER;
GO
/******************************************
 *
 * Prevent data deletion based on criteria
 *
 *****************************************/


/*
   Prevent deletions of Orders if PickingCompletedWhen is NOT NULL
*/
CREATE OR ALTER TRIGGER [Sales].[TD_OrdersLines_AFTER]ON 
	[Sales].[OrderLines]AFTER DELETEAS
	BEGIN
		IF (ROWCOUNT_BIG() = 0)
			RETURN;

		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM DELETED)
			RETURN;
		
		-- Has the order been picked for delivery yet?
		IF EXISTS 
		(
			SELECT 1 FROM DELETED d WHERE d.PickingCompletedWhen is not null
		)
		BEGIN
			RAISERROR('The OrderLine has been fulfilled and cannot be deleted',16,1);
			ROLLBACK TRAN;
			RETURN;
		END;
	END;
GO

/*
  Attempt to delete data from Sales.Orders where PickingCompletedWhen is not NULL
*/
DELETE FROM Sales.OrderLines WHERE OrderID=1;

DROP TRIGGER Sales.TD_OrdersLines_AFTER;
DROP TABLE Application.AuditLog;


/******************************************
 *
 * Logging Deletion of Data From a table
 *
 *****************************************/

/*
   Create a simple logging table
*/
CREATE TABLE Application.AuditLog (
	AuditLogID int identity,
	ModifiedTime DATETIME,
	ModifiedBy nvarchar(100),
	Operation nvarchar(16),
	SchemaName nvarchar(64),
	TableName nvarchar(64),
	TableID int,
	LogData nvarchar(max)
);
GO


CREATE OR ALTER TRIGGER [Sales].[TD_Orders_AFTER]ON 
	[Sales].[Orders]AFTER DELETEAS
	BEGIN
		IF (ROWCOUNT_BIG() = 0)
			RETURN;

		SET NOCOUNT ON;

		IF NOT EXISTS (SELECT 1 FROM DELETED)
			RETURN;
		
		DECLARE @operationType nvarchar(16) = 'DELETE';

		/*
		  Using the Temp table that has the deleted rows
		*/
		INSERT INTO Application.AuditLog 
				([ModifiedTime], [ModifiedBy], [Operation], [SchemaName], [TableName], [TableID], [LogData])
			SELECT GETDATE(), SYSTEM_USER, @operationType, 'Sales','Orders',D1.OrderId, D2.LogData
				FROM DELETED D1
				CROSS APPLY (
					SELECT LogData=(select * from DELETED WHERE 
									DELETED.OrderID = D1.OrderID FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
				) AS D2
	END;
GO

/*
  See what has been logged already
*/
SELECT * FROM Application.AuditLog;

/*
  Allow an Order to be deleted to log changes
*/
UPDATE Sales.Invoices SET OrderID=NULL where OrderID < 10;

/*
  Delete an Order
*/
DELETE FROM Sales.Orders where orderId < 10;

/*
  See what was logged
*/
SELECT * FROM Application.AuditLog;

/*
  Find a DELETE operation for a specific order
*/
SELECT * FROM Application.AuditLog where Operation='DELETE' AND TableName='Orders' AND JSON_VALUE(LogData, '$.OrderID')='4';

