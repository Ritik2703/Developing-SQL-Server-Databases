USE BobsShoes;
GO

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN TRAN;

    SELECT * FROM Orders.Orders;

    SELECT * FROM Orders.Orders;

COMMIT;
