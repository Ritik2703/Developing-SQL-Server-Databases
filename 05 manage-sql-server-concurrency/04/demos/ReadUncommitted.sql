USE BobsShoes;
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRAN;

    SELECT * FROM Orders.Orders;

    SELECT * FROM Orders.Orders;

COMMIT;
