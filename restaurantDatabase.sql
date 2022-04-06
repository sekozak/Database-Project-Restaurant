create table Categories
(
    CategoryID   int          not null
        constraint Categories_pk
            primary key,
    CategoryName nvarchar(15) not null
)
go

create table Customers
(
    CustomerID   int          not null
        constraint Customers_pk
            primary key,
    CompanyName  nvarchar(50),
    CustomerType nvarchar(10) not null,
    ContactName  nvarchar(30),
    Phone        nvarchar(24)
)
go

create table Company
(
    CompanyID            int          not null
        constraint Company_pk
            primary key,
    Customers_CustomerID int          not null
        constraint Company_Customers
            references Customers,
    NIP                  nchar(10)    not null,
    CompanyName          nvarchar(50) not null,
    Address              nchar(60)    not null
)
go

create table CustomerHis
(
    CustomerID           int   not null
        constraint CustomerHis_pk
            primary key,
    Customers_CustomerID int   not null
        constraint CustomerHis_Customers
            references Customers,
    OrderPrice           money not null,
    DiscountGranted      bit   not null
)
go

create table DiscountsDetails
(
    DiscountID  int   not null
        constraint DiscountsDetails_pk
            primary key,
    Sum         money,
    Quantity    int
        check ([Quantity] >= 0),
    Discount    float not null
        check ([Discount] >= 0 AND [Discount] <= 1),
    MinOrderVal money
)
go

create table Discounts
(
    DiscountsID                int  not null
        constraint Discounts_pk
            primary key,
    CustomerID                 int  not null
        constraint Discounts_Customers
            references Customers,
    Start                      date not null,
    Expiry                     date not null,
    DiscountDetails_DiscountId int
        constraint Discounts_DiscountsDetails_DiscountID_fk
            references DiscountsDetails
)
go

create table Menu
(
    PositionID   int          not null
        constraint Menu_pk
            primary key,
    CategoryID   int          not null
        constraint Menu_Categories
            references Categories,
    PositionName nvarchar(20) not null,
    ProductPrice money        not null,
    ActiveMenu   int          not null
)
go

create table OrderType
(
    OrderID     int not null
        constraint OrderType_pk
            primary key,
    TakeOut     bit not null,
    TakeOutDate date
)
go

create table Orders
(
    OrderID              int not null
        constraint Orders_pk
            primary key,
    OrderType_OrderID    int not null
        constraint Orders_OrderType
            references OrderType,
    Customers_CustomerID int not null
        constraint Orders_Customers
            references Customers,
    OrderDate            date
)
go

create table OrderDetails
(
    OrderID        int   not null
        constraint OrderDetails_Orders
            references Orders,
    PositionID     int   not null
        constraint OrderDetails_Menu
            references Menu,
    PositionPrice  money not null,
    Quantity       int   not null
        check ([Quantity] >= 0),
    DiscountAmount float,
    constraint OrderDetails_pk
        primary key (PositionID, OrderID)
)
go

create table Reservation
(
    ReservationID  int      not null
        constraint Reservation_pk
            primary key,
    Orders_OrderID int      not null
        constraint Reservation_Orders
            references Orders,
    Date           datetime not null
)
go

create table [Table]
(
    TableID  int not null
        constraint Table_pk
            primary key,
    Capacity int not null
        check ([Capacity] >= 2 AND [Capacity] <= 10),
    VIP      bit not null
)
go

create table TableRes
(
    TableResID                int not null
        constraint TableRes_pk
            primary key,
    TableID                   int not null
        constraint TableRes_Table
            references [Table],
    Reservation_ReservationID int not null
        constraint TableRes_Reservation
            references Reservation
)
go

CREATE VIEW COMPANIES
as
select CompanyName, CustomerID, CustomerType
from Customers
where CustomerType = 'Company'
go

CREATE VIEW COMPANY_EMPLOYEE
as
select CompanyName, CustomerID, CustomerType
from Customers
where CustomerType = 'Voucher'
go

CREATE VIEW CURRENT_MENU
as
select PositionID, PositionName, CategoryName, ProductPrice, ActiveMenu
from Menu
         INNER JOIN Categories C on C.CategoryID = Menu.CategoryID
where ActiveMenu = 1
go

CREATE VIEW CUSTOMER_ORDERS
as
select Customers.ContactName,
       Customers.CompanyName,
       Customers_CustomerID,
       Orders.OrderID,
       OrderType.TakeOut,
       OrderType.TakeOutDate
from Orders
         inner join Customers on Customers.CustomerID = Orders.Customers_CustomerID
         inner join OrderType on OrderType.OrderID = Orders.OrderType_OrderID
go

CREATE VIEW DISCOUNT
as
select CustomerID, DiscountsDetails.Discount
from Discounts
         inner join DiscountsDetails on Discounts.DiscountDetails_DiscountId = DiscountsDetails.DiscountID
where Expiry > getdate()
go

CREATE VIEW FOOD_FROM_VOUCHERS
as
select C.ContactName, C.CompanyName, M.PositionID, M.PositionName
from Orders
         INNER JOIN Customers C on C.CustomerID = Orders.Customers_CustomerID
         INNER JOIN OrderDetails OD on Orders.OrderID = OD.OrderID
         INNER JOIN Menu M on OD.PositionID = M.PositionID
where CustomerType = 'Voucher'
go

CREATE VIEW PRIVATE_CUSTOMERS
as
select CompanyName, CustomerID, CustomerType
from Customers
where CustomerType = 'Private'
go

CREATE VIEW ProductSoldsPerYear
as
SELECT YEAR(O.OrderDate) as Year, M.PositionID, PositionName, Sum(Quantity) as Sold
from OrderDetails
         inner join Orders O on OrderDetails.OrderID = O.OrderID
         inner join Menu M on M.PositionID = OrderDetails.PositionID
group by YEAR(O.OrderDate), M.PositionID, PositionName
go

CREATE VIEW SEA_FOOD
as
select PositionID, PositionName, CategoryName, ProductPrice, ActiveMenu
from Menu
         INNER JOIN Categories C on C.CategoryID = Menu.CategoryID
where CategoryName = 'Seafood'
go

CREATE VIEW VIP_TABLES
as
select TableID, Capacity, Vip
from [Table]
where Vip = 1
go

CREATE PROCEDURE [dbo].[AddCategory] @CategoryName nvarchar(15)
AS
BEGIN
    DECLARE @CategoryID int;
    SELECT @CategoryID = ISNULL(MAX(CategoryID), 0) + 1
    FROM Categories
    INSERT INTO Categories(CategoryID, CategoryName) VALUES (@CategoryID, @CategoryName)
END
go

CREATE Procedure [dbo].[AddOrder](
    @CustomerID INT,
    @OrderType varchar,
    @Date datetime
)
AS
BEGIN
    IF (@OrderType IS NULL)
        BEGIN
            SET @OrderType = 1
        END
    ELSE
        BEGIN
            SET @OrderType = 2
        END
    DECLARE @OrderId INT
    SELECT @OrderId = ISNULL(MAX(OrderId), 0) + 1 FROM Orders
    INSERT INTO dbo."Orders"
    (OrderID,
     OrderType_OrderID,
     Customers_CustomerID,
     OrderDate)
    VALUES (@OrderId,
            @OrderType,
            @CustomerID,
            @Date)
END
go

CREATE Procedure [dbo].[AddPositionToOrder](
    @PositionID SMALLINT,
    @Quantity TINYINT,
    @OrderID SMALLINT
)
AS
BEGIN
    DECLARE @PositionPrice SMALLINT
    SET @PositionPrice = (SELECT ProductPrice FROM Menu WHERE PositionID = @PositionID)
    INSERT INTO dbo.OrderDetails
    (OrderID,
     PositionID,
     PositionPrice,
     Quantity)
    VALUES (@OrderID,
            @PositionID,
            @PositionPrice,
            @Quantity)
END
go

CREATE Procedure [dbo].[AddReservation](
    @CustomerID INT,
    @Table INT,
    @DateReservation DATETIME,
    @OrderId INT,
    @OrderType varchar
)
AS
BEGIN
    DECLARE @ReservationID INT
    SELECT @ReservationID = ISNULL(MAX(ReservationID), 0) + 1 FROM Reservation
    DECLARE @orderhis INT
    SELECT @orderhis = count(OrderID) FROM Orders WHERE Customers_CustomerID = @CustomerID GROUP BY Customers_CustomerID
    DECLARE @occupied INT
    SELECT @occupied = count(TableResID)
    from TableRes
             INNER JOIN dbo.[Reservation] ON TableRes.Reservation_ReservationID = Reservation.ReservationID
    WHERE TableID = @Table
      and DAY(@DateReservation) = DAY(Reservation.Date)
    IF (@occupied = 0 and @orderhis > 5)
        BEGIN
            INSERT INTO dbo."Reservation"
            (ReservationID,
             Orders_OrderID,
             Date)
            VALUES (@ReservationID,
                    @OrderId,
                    @DateReservation)
            EXECUTE AddTableToRes @ReservationID, @Table
            EXECUTE AddOrder @CustomerID, @OrderType, @DateReservation
        END
END
go

CREATE Procedure [dbo].[AddTableToRes](
    @ReservationID INT,
    @TableID SMALLINT
)
AS
BEGIN
    DECLARE @TableResId SMALLINT
    SELECT @TableResId = ISNULL(MAX(TableResID), 0) + 1 FROM TableRes

    BEGIN
        INSERT INTO [dbo].[TableRes]
        (TableResID,
         TableID,
         Reservation_ReservationID)
        VALUES (@TableResId,
                @TableID,
                @ReservationID)
    END
END
go

CREATE FUNCTION [dbo].[CountConstDis](@CustomerId int)
    RETURNS table as return
        SELECT Customers_CustomerID, (SELECT Discount FROM DiscountsDetails WHERE Sum is NULL) as dis
        FROM (
                 SElECT Customers_CustomerID, count(Orders.OrderID) AS OrdersOverMin
                 FROM (
                          SELECT Orders.OrderID, SUM(Quantity * PositionPrice) as sum
                          FROM Orders
                                   INNER JOIN OrderDetails OD on Orders.OrderID = OD.OrderID
                          GROUP BY Orders.OrderID) as OrdersSum
                          INNER JOIN Orders on Orders.OrderID = OrdersSum.OrderID
                 where sum > (SELECT MinOrderVal FROM DiscountsDetails WHERE Sum is NULL)
                 group by Customers_CustomerID) as tab
        WHERE OrdersOverMin >= (SELECT Quantity FROM DiscountsDetails WHERE Sum is NULL)
          and Customers_CustomerID = @CustomerId
go

CREATE FUNCTION [dbo].[CountOne_TimeDis](@CustomerId int)
    RETURNS table as return
        SELECT Customers_CustomerID, (SELECT Discount FROM DiscountsDetails WHERE Sum is not NULL) as dis
        FROM (
                 SElECT Customers_CustomerID, SUM(sums) AS OrdersSum
                 FROM (
                          SELECT Orders.OrderID, SUM(Quantity * PositionPrice) as sums
                          FROM Orders
                                   INNER JOIN OrderDetails OD on Orders.OrderID = OD.OrderID
                          GROUP BY Orders.OrderID) as OrdersSum
                          INNER JOIN Orders on Orders.OrderID = OrdersSum.OrderID
                 group by Customers_CustomerID) as tab
        WHERE OrdersSum >= (SELECT Sum FROM DiscountsDetails WHERE Sum is NOT NULL)
          and Customers_CustomerID = @CustomerId
go

CREATE FUNCTION [dbo].[GetAllActivePositions]()
    RETURNS table AS
        RETURN
        select PositionID, CategoryID, PositionName, ProductPrice, ActiveMenu
        from Menu
        where Menu.ActiveMenu = 1
go

CREATE FUNCTION [dbo].[GetAllCustomersOfCompany](@companyname nvarchar(50))
    RETURNS table AS
        RETURN
        select CustomerID, CompanyName, CustomerType, ContactName, Phone
        from Customers
        where Customers.CompanyName = @companyname
go

CREATE FUNCTION [dbo].[GetIndividualCustomerStatistics]()
    RETURNS table as return
        SElECT Customers_CustomerID, AVG(sum) AS AvgOrders
        FROM (
                 SELECT Orders.OrderID, Quantity * PositionPrice as sum
                 FROM Orders
                          INNER JOIN OrderDetails OD on Orders.OrderID = OD.OrderID
             ) as OrdersSum

                 INNER JOIN Orders on Orders.OrderID = OrdersSum.OrderID
        group by Customers_CustomerID
go

CREATE FUNCTION [dbo].[GetPositionsWithPriceHigherThan](@price money)
    RETURNS table AS
        RETURN
        select PositionID, CategoryID, PositionName, ProductPrice, ActiveMenu
        from Menu
        where Menu.ProductPrice > @price
go

CREATE FUNCTION IssueAnInvoiceToClient(@id int)
    RETURNS table AS
        RETURN
        select O.OrderID,
               O.Customers_CustomerID,
               PositionID,
               PositionPrice,
               Quantity,
               (Quantity * PositionPrice) as Summary,
               DiscountAmount
        FROM OrderDetails
                 inner join Orders O on O.OrderID = OrderDetails.OrderID
        WHERE O.OrderID = @id
go

CREATE PROCEDURE [dbo].[uspAddNewCustomer] @CompanyName nvarchar(40),
                                           @CustomerType nvarchar(10), @ContactName nvarchar(30), @Phone nvarchar(24),
                                           @NIP nchar(10), @Address nchar(60)
AS
BEGIN
    DECLARE @CustomerID INT
    IF EXISTS(
            SELECT *
            FROM Company
            WHERE CompanyName = @CompanyName
        )
        BEGIN
            SELECT @CustomerID = ISNULL(MAX(CustomerID), 0) + 1
            FROM Customers
            INSERT INTO Customers(CustomerID, CompanyName, CustomerType, ContactName, Phone)
            VALUES (@CustomerID, @CompanyName, @CustomerType, @ContactName, @Phone)
        end

    ELSE
        BEGIN
            SELECT @CustomerID = ISNULL(MAX(CustomerID), 0) + 1
            FROM Customers
            INSERT INTO Customers(CustomerID, CompanyName, CustomerType, ContactName, Phone)
            VALUES (@CustomerID, @CompanyName, @CustomerType, @ContactName, @Phone)

            DECLARE @CompanyID INT
            SELECT @CompanyID = ISNULL(MAX(CompanyID), 0) + 1
            FROM Company
            INSERT INTO Company(CompanyID, NIP, CompanyName, Address, Customers_CustomerID)
            VALUES (@CompanyID, @NIP, @CompanyName, @Address, @CustomerID)
        end

end
go

CREATE PROCEDURE [dbo].[uspAddPosition] @PositionName nvarchar(20),
                                        @CategoryName nvarchar(15), @ProductPrice money
AS
BEGIN
    DECLARE @CategoryID INT
    SELECT @CategoryID = CategoryID
    FROM Categories
    WHERE CategoryName = @CategoryName
    DECLARE @PositionID INT
    SELECT @PositionID = ISNULL(MAX(PositionID), 0) + 1
    FROM Menu
    INSERT INTO Menu(PositionID, CategoryID, PositionName, ProductPrice, ActiveMenu)
    VALUES (@PositionID, @CategoryID, @PositionName, @ProductPrice, 0)
end
go

CREATE PROCEDURE [dbo].[uspAddTable] @Capacity int,
                                     @Vip bit
AS
BEGIN
    DECLARE @TableID INT
    SELECT @TableID = ISNULL(MAX(TableID), 0) + 1
    FROM [Table]
    INSERT INTO [Table](TableID, Capacity, Vip)
    VALUES (@TableID, @Capacity, @Vip)
end
go

CREATE FUNCTION [dbo].[uspGetPositionByCategory](@CategoryName nvarchar(15))
    RETURNS TABLE AS
        RETURN
        SELECT PositionName, ProductPrice
        FROM Menu
                 INNER JOIN dbo.Categories C on C.CategoryID = Menu.CategoryID
        WHERE C.CategoryName = @CategoryName
go

CREATE PROCEDURE [dbo].[uspRemoveCategory] @categoryName nvarchar(15)
AS
BEGIN
    DELETE
    FROM Categories
    WHERE CategoryName = @categoryName
end
go

CREATE PROCEDURE [dbo].[uspRemovePosition] @PositionName nvarchar(20)
AS
BEGIN
    DELETE
    FROM Menu
    WHERE PositionName = @PositionName
end
go

CREATE PROCEDURE [dbo].[uspRemoveTable] @TableID int
AS
BEGIN
    DELETE
    FROM [Table]
    WHERE TableID = @TableID
end
go

