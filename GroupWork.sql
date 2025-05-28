use SmartOrder
select * from Orders
---Create meaningful stored procedures 
CREATE PROCEDURE ApproveOrder
 @OrderID INT
AS
BEGIN
    UPDATE Orders
    SET Status = 'Approved'
    WHERE OrderID = @OrderID;
END;
EXEC ApproveOrder @OrderID = 101;
SELECT OrderID, Status
FROM Orders
WHERE OrderID = 101;

---------------------------

ALTER PROCEDURE ApproveOrder
@OrderID INT
AS
BEGIN
    UPDATE Orders
    SET Status = 'Approved'
    WHERE OrderID = 101;
END;
------------
--Declare a variable 
DECLARE @OrderID INT;
SET @OrderID = 111;
EXEC ApproveOrder @OrderID = 111;
--------------------------------
--DROP PROCEDURE ApproveOrder;
select * from Orders
------------------------
CREATE PROCEDURE ApprovePendingOrders
AS
BEGIN
    DECLARE @OrderID INT;

    -- Cursor to iterate through all 'Preparing' orders
    DECLARE OrderCursor CURSOR FOR
    SELECT OrderID FROM Orders WHERE Status = 'Preparing';

    -- Open the cursor
    OPEN OrderCursor;

    -- Fetch the first OrderID
    FETCH NEXT FROM OrderCursor INTO @OrderID;

    -- Loop through all records
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Update the order status
        UPDATE Orders
        SET Status = 'Approved'
        WHERE OrderID = @OrderID;

        -- Fetch the next OrderID
        FETCH NEXT FROM OrderCursor INTO @OrderID;
    END;

    -- Close and deallocate the cursor
    CLOSE OrderCursor;
    DEALLOCATE OrderCursor;
END;
-------------------------
-- create table Order_Status
create table Order_Status (
StatuesID int identity primary key,
OrderID int,
oldStatues VARCHAR(20),
newStatues VARCHAR(20),
changeDate DateTime default getDate(),
FOREIGN KEY (OrderID) REFERENCES Orders (OrderID)
);

SELECT * FROM Order_Status 
-- this tragger run after update on the Order table 
create trigger trg_OrderStatus
on Orders 
After update 
as
begin
insert into Order_Status (OrderID, oldStatues, newStatues)
select D.OrderID, D.Status , I.Status 
-- inserted and deleted is temporary tables 
from inserted I  -- contains a nwe vlaue aftre update
JOIN deleted D ON I.OrderID = D.OrderID -- contains a old vlaue aftre update
WHERE D.Status <> I.Status ;
end;
-- use update 
update Orders 
set Status = 'Delivered'
where OrderID = 102;
------------------------------------
-- INSTEAD of delete menu from Restaurants
create trigger trg_PriventRestaurantsDelete
on Restaurants
instead of delete
as
begin
-- check if the restaurant that want to delete is have menu items or not
if EXISTS (
         select 1 from deleted D
		 JOIN Menu M on d.RestaurantID = M.RestaurantID
		 )
begin
-- number (16,1) means severity
RAISERROR ('Cannot delete restaurants that has menu items',16,1);
return;
end;
-- if there are no menu items exist
delete from Restaurants 
where RestaurantID in (select RestaurantID from deleted);
end;
-- test the tragger 
-- the trigger will block the delete and show error message
delete from Restaurants where RestaurantID = 1;
-- view Restaurants table
SELECT * FROM Restaurants
-- insert new Restaurants without menu
insert into Restaurants values (5,'test restaurant', 'Muscat');
-- delete a restaurant that has no menu items
delete from Restaurants where RestaurantID = 5;
-------------------------------------
-- use update trigger
-- add the Stock cloumn to the Men table with a defult value of 100 
alter table Menu 
add Stock int default 100;
-- to update the Stock column in the menu table
create trigger trg_updateMwnu 
on OrderItems
after insert 
as
begin
update Menu 
set Stock= Stock - I.Quantity
from Menu M
JOIN
inserted I ON M.ItemName = I.ItemName AND M.RestaurantID = ( select RestaurantID FROM Orders WHERE OrderID = I.OrderID);
end;
-- view a specific menu item
select * from Menu where ItemName = 'Shawarma Chicken';
-- insert a new order item
-- this is insert a new order for 3 Shawarma Chicken items at a price 1.5 
insert into OrderItems (OrderItemID, OrderID, ItemName, Quantity, Price)
VALUES (10, 101, 'Shawarma Chicken', 3, 1.500);
-- chesk all trigger on the OrderItems table
EXEC sp_helptrigger OrderItems;
-- reset ctock values to 100 where they are NULL
update Menu 
set Stock = 100
where Stock is null;
-------------------------------------------
-- create SystemAlerts table to store alert message
create table SystemAlerts (
AlertID INT IDENTITY PRIMARY KEY,
AlertMessage NVARCHAR(255),
AlertDate DATETIME DEFAULT GETDATE()
);
-- adding the OrderID column to alert table so you cas associate each alert with a specific order 
alter table SystemAlerts
add OrderID int;
-- creating a trigger for cancelled orders
create trigger trg_AlertsCancle
on Orders
after update 
as 
begin
insert into SystemAlerts ( OrderID, AlertMessage)
select I.OrderID,
'Order has been cancelled'
from inserted I
join deleted D on I.OrderID = D.OrderID
WHERE I.Status = 'Cancelled' and D.Status <> 'Cancelled';
end;
-- testing the trigger 
update Orders
set Status = 'preparing'
where OrderID = 104;
-- checking alert table 
select * from SystemAlerts;
-- checking orders table to viwe the change
select * from Orders;
-- check if trigger exist on the Orders table and confirms that trg_AlertsCancle is active
EXEC sp_helptrigger Orders;
-- manual alert insert and check that the SystemAlerts  table ts working
INSERT INTO SystemAlerts (OrderID, AlertMessage)
VALUES (102, 'the order has been canclled');

