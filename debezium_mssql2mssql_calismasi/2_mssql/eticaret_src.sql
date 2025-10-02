-- Veritabanını oluştur
CREATE DATABASE eticaret;
GO

-- eticaret veritabanına geç
USE eticaret;
GO

-- 1. Customer tablosu
CREATE TABLE Customer (
    Id INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 2. Product tablosu
CREATE TABLE Product (
    Id INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2),
    Stock INT,
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 3. Order tablosu
CREATE TABLE [Order] (
    Id INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2),
    FOREIGN KEY (CustomerId) REFERENCES Customer(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

-- 4. Order_Detail tablosu
CREATE TABLE Order_Detail (
    Id INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    FOREIGN KEY (OrderId) REFERENCES [Order](Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (ProductId) REFERENCES Product(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

-- -------------------------
-- ÖRNEK KAYITLAR
-- -------------------------

-- Müşteri ekle
INSERT INTO Customer (FirstName, LastName, Email) VALUES
('Ahmet', 'Yılmaz', 'ahmet@example.com'),
('Ayşe', 'Kara', 'ayse@example.com');

-- Ürün ekle
INSERT INTO Product (ProductName, Price, Stock) VALUES
('Laptop', 15000.00, 10),
('Mouse', 200.00, 100),
('Klavye', 500.00, 50);

-- Sipariş ekle (CustomerId: 1 = Ahmet, 2 = Ayşe)
INSERT INTO [Order] (CustomerId, TotalAmount) VALUES
(1, 15200.00),
(2, 700.00);

-- Sipariş detayları ekle
INSERT INTO Order_Detail (OrderId, ProductId, Quantity, UnitPrice) VALUES
(1, 1, 1, 15000.00),  -- Ahmet - Laptop
(1, 2, 1, 200.00),    -- Ahmet - Mouse
(2, 3, 1, 500.00),    -- Ayşe - Klavye
(2, 2, 1, 200.00);    -- Ayşe - Mouse
GO

-- CDC kullanmak için sa gibi yetkili bir kullanıcıyla bağlanıyor olman gerekir.

-- EXEC sys.sp_cdc_enable_db;

-- EXECUTE sp_configure 'clr enabled'; -- configurasyon okunuyor
-- EXECUTE sp_configure 'clr enabled', '1'; --clr enable ediliyor. disable icin 0 olmali
--RECONFIGURE; --ayarin yuklenmesi saglaniyor

-- -- Order tablosu için
-- EXEC sys.sp_cdc_enable_table  
    -- @source_schema = N'dbo',  
    -- @source_name   = N'Order',  
    -- @role_name     = NULL

-- -- Order_Detail tablosu için
-- EXEC sys.sp_cdc_enable_table  
    -- @source_schema = N'dbo',  
    -- @source_name   = N'Order_Detail',  
    -- @role_name     = NULL;

-- -- Product tablosu için
-- EXEC sys.sp_cdc_enable_table  
    -- @source_schema = N'dbo',  
    -- @source_name   = N'Product',  
    -- @role_name     = NULL;

--EXEC sys.sp_cdc_disable_table
--    @source_schema = N'dbo',
--    @source_name   = N'Order',
--    @capture_instance = N'dbo_Order'

    
--EXEC sys.sp_cdc_disable_table
--    @source_schema = N'dbo',
--    @source_name   = N'Order_Detail',
--    @capture_instance = N'dbo_Order_Detail'

    
--EXEC sys.sp_cdc_disable_table
--    @source_schema = N'dbo',
--    @source_name   = N'Product',
--    @capture_instance = N'dbo_Product'


--EXEC sys.sp_cdc_disable_db
--GO

