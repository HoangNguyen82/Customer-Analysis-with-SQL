

-- take note dòng này

/* dòng 1
dòng 2
dòng 3
dòng 5
*/

-- LESSON 1: SIMPLE QUERY --
-- 1. Hiển thị kết quả: SELECT

SELECT 'Toi ten la Hieu'

SELECT N'Tôi tên là Hiếu', N'Tôi tên là Huy'

-- 2. Hiển thị data từ bảng trong DB: Select + From

SELECT CustomerID
, FirstName
,MiddleName
,LastName
 -- show tất cả các cột của bản
FROM salesLT.Customer -- tên bảng -- 847 dòng ~847 Khách hàng


-- 3. Đặt tên lại để show ra
-- 3 cách đặt tên chuẩn:
    -- Canel: tenKhachHang
    -- snake: ten_Khach_Hang
    -- pascal: TenKhachHang

    --> SQL không phân biệt hoa thường

-- column AS new_name

SELECT CustomerID
, FirstName
,MiddleName
,LastName AS ten_khach_hang
FROM salesLT.Customer

-- 4. Sắp xếp kết quả hiển thị
SELECT CustomerID
, FirstName
,MiddleName
,LastName AS ten_khach_hang
FROM salesLT.Customer
ORDER BY LastName ASC, CustomerID DESC

-- Được quyền dùng tên alias để ORDER BY
SELECT CustomerID
, FirstName
,MiddleName
,LastName AS ten_khach_hang
FROM salesLT.Customer
ORDER BY ten_khach_hang ASC, CustomerID DESC
--> Do thứ tự thực hiện SQL :FROM --> SELECT -->ORDER BY

-- 5. Lọc dữ liệu WHERE

-- show ra những KH có mã ID > 1000
SELECT CustomerID
, FirstName
,MiddleName
,LastName AS ten_khach_hang
FROM salesLT.Customer
WHERE CustomerID > 1000 -- Điều kiện
ORDER BY CustomerID ASC -- Sắp xếp tăng or giảm dần

--> 407 KH thỏa điều kiện

-- Đặt điều kiện theo logic muốn lấy data

-- Lấy các sản phẩm có màu đen và có gtri < 1000 đồng

SELECT TOP 5 * -- show ra 5 dòng đầu tiên
FROM salesLT.Product
WHERE Color = 'Black' AND ListPrice < 1000

-- 5.1 so sánh với Between ... and

SELECT TOP 5 * -- show ra 5 dòng đầu tiên
FROM salesLT.Product
WHERE ListPrice BETWEEN 1000 AND 2000

-- 5.2 so sánh với IN (tập hợp nhiều giá trị)

SELECT TOP 5 * -- show ra 5 dòng đầu tiên
FROM salesLT.Product
WHERE Color IN ('Black', 'White', 'Red') OR ListPrice BETWEEN 1000 and 2000

-- 5.3 So sánh gần giống LIKE

-- máy show ra các sản phẩm có chưa 'Road'

SELECT *
FROM salesLT.Product
WHERE Name LIKE '%Road%'

-- %: đại điện cho không có hoặc có nhiều kí tự

-- hãy show ra các sản phẩm có tên bắt đầu bằng chữ "H" với kí tự thứ 3 là khoảng trắng

SELECT * 
FROM salesLT.Product
WHERE Name LIKE 'H_ %' -- bắt đầu là chữ H, thứ 2 là gì cũng được, thứ 3 là khoảng trống, phần còn lại là gì cũng được 


SELECT * 
FROM salesLT.Product
WHERE Name LIKE 'HL_%' -- Bắt đâu bằng chữ HL và có ít nhất 3 kí tự

-- Hãy show ra các sản phẩm có tên bắt đầu là 'HL' và kí tự 4 là chữ cái trong dãy A --> M

SELECT * 
FROM salesLT.Product
WHERE Name LIKE 'HL_[A-M]%'

-- Hãy show ra các sản phẩm có tên bắt đầu là 'HL' và kí tự 4 là chữ cái là chữ cái khác chữ 'M'
SELECT * 
FROM salesLT.Product
WHERE Name NOT LIKE 'HL_[M-Z]%'

-- Show loại bỏ trùng lặp
SELECT Distinct Color -- distinct loại bỏ trùng lặp
FROM salesLT.Product


