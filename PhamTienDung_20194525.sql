1--Dua ra danh sach nhung nguoi co nhom mau AB va nhung lan hien mau luc tren > 30t
Đưa ra danh sách những người có nhóm máu AB và những lần hiến máu của người đó khi trên 30 tuổi

select a.Hoten, a.CCCD_HC, b.Thoigian, FLOOR(DATEDIFF(b.Thoigian,a.Ngaysinh)/365) as Tuoi from NguoiDKHM a,DangkiHM b
where (DATEDIFF(b.Thoigian,a.Ngaysinh) > 365*30) and a.CCCD_HC = b.CCCD_HC
and MaDK in
(select MSsangloc from KetquaKLS
where MSsangloc in
(select MaNHM from Nguoihienmau
where MaTM in
(select MaTM from Tuimau
where KetquaXN in
(select Maxetnghiem from Goixetnghiem
where MaXNSL in
(select MaXNSL from KetquaXNSL
where NhommauABO like "AB")))))
order by a.CCCD_HC,b.Thoigian;

2--Dua ra thanh tich lam viec cua cac can bo y te co trong 5 nam qua( duoc tinh bang tong so tui mau / 5 nam tu 2016-2020, khong tinh nam trong 2021)
Đưa ra thành tích làm việc của các cán bộ y tế trong 5 năm qua ( được tính bằng tổng số túi máu/5 năm từ 2016-2020). Múc đích để khen thưởng có những người có thành tích cao

DELIMITER $$
    CREATE FUNCTION Thanhtich(Hieusuat int) 
    RETURNS VARCHAR(20)
    DETERMINISTIC
BEGIN
    DECLARE Thanhtich VARCHAR(20);
    IF Hieusuat >= 45 THEN
		SET Thanhtich = 'Kim cuong';
    ELSEIF (Hieusuat >= 40 AND 
			Hieusuat < 45) THEN
        SET Thanhtich = 'Vang';
    ELSEIF (Hieusuat >= 35 AND 
			Hieusuat < 40) THEN
        SET Thanhtich = 'Bac';
    ELSEIF (Hieusuat >= 30 AND 
			Hieusuat < 35) THEN
        SET Thanhtich = 'Dong';
    ELSEIF Hieusuat < 30 THEN
        SET Thanhtich = 'Sat';     
    END IF;
	RETURN (Thanhtich);
END$$
DELIMITER ;

select C.MaCB,C.Hoten, Thanhtich(count(A.MaTM)/5) as Thanhtich
from DangkiHM D,KetquaKLS E, Nguoihienmau F,Tuimau A, ThuchienHM B, Canboyte C
where D.MaDK = E.MSsangloc and E.MSsangloc = F.MaNHM and F.MaTM = A.MaTM and A.MaTM = B.MaTM and B.MaCB = C.MaCB
and year(D.Thoigian) <= '2020' and year(D.Thoigian) >= '2016'
group by C.MaCB
order by count(A.MaTM);

3-- Đưa ra những người ở quận HOàn Kiếm đến đăng kí hiến máu ở các địa điểm ở quận Hoàn Kiếm khi đó trên 50 tuổi nhưng không vượt qua được vòng khám lâm sàng và nguyên nhân theo các năm
DELIMITER $$
    CREATE FUNCTION Nguyennhan(Huyetap int,Bieuhienlamsang varchar(100),Cannang int) 
    RETURNS VARCHAR(30)
    DETERMINISTIC
BEGIN
    DECLARE NN VARCHAR(20);
    IF Huyetap > 140 THEN
		SET NN = 'Huyet ap cao';
    ELSEIF Huyetap < 83 THEN
        SET NN = 'Huyet ap thap';
    ELSEIF Bieuhienlamsang = 'Kho tho' THEN
        SET NN = 'Kho tho';
    ELSEIF Bieuhienlamsang = 'Met moi' THEN
        SET NN = 'Met moi';
    ELSEIF Cannang < 47 THEN
        SET NN = 'Khong du can nang';
    END IF;
	RETURN (NN);
END$$
create procedure NguoiGiaHM(IN Nam char(4)) 
BEGIN
    select A.CCCD_HC,A.Hoten,A.Diachi DiachiNHM, D.Diachi as DiadiemDDHM,B.Thoigian,FLOOR(DATEDIFF(B.Thoigian,A.Ngaysinh) / 365) as Tuoi, Nguyennhan(C.Huyetap,C.Bieuhienlamsang,C.Cannang) as Nguyennhan
from NguoiDKHM A, DangkiHM B, KetquaKLS C, DiadiemDKHM D
where A.CCCD_HC = B.CCCD_HC and B.MaDK = C.MSsangloc  and B.MaDD = D.MaDD
and A.Diachi like '%Hoan Kiem%' and DATEDIFF(B.Thoigian,A.Ngaysinh) > 50*365
and D.Diachi like '%Hoan Kiem%'
and Nam = year(B.Thoigian)
and C.MSsangloc not in(
    select MaNHM from Nguoihienmau
)
order by year(B.Thoigian);
END$$
DELIMITER ;

call NguoiGiaHM('2019);


4-- nhung nguoi  hien mau tu 2 lan tro len nhung tui mau khong the su dung nhieu hon tu 2 lan
Những người đã hiến máu từ 2 lần trở lên, nhưng số lượng những túi máu đó không thể sử dụng nhiều hơn từ 2 lần

select A.Hoten, A.CCCD_HC, count(B.MaDK) as SLKsudung
from NguoiDKHM A, DangkiHM B, KetquaKLS C, Nguoihienmau D, Tuimau E, Goixetnghiem F, KetquaXNSL G
where A.CCCD_HC = B.CCCD_HC and B.MaDK = C.MSsangloc and C.MSsangloc = D.MaNHM and D.MaTM = E.MaTM and E.KetquaXN = F.Maxetnghiem and F.MaXNSL = G.MaXNSL
and (G.HCV_NAT = '+' or G.HBV_NAT = '+' or G.HIV_NAT = '+' or G.Giangmai = '+')
and A.CCCD_HC in(
    select A.CCCD_HC
from NguoiDKHM A, DangkiHM B, KetquaKLS C, Nguoihienmau D
where A.CCCD_HC = B.CCCD_HC and B.MaDK = C.MSsangloc and C.MSsangloc = D.MaNHM
group by B.CCCD_HC 
having count(D.MaNHM) > 1
)
group by A.CCCD_HC
having count(B.MaDK) > 1;


5--Đưa ra danh sách những người đã hiến máu lặp lại mà số lần hiến máu với lượng máu đã hiến lớn hơn lượng máu dự kiến hiến là nhiều nhất

SELECT Hoten,A.Diachi,A.Ngaysinh,A.CCCD_HC,count(Hoten)
from NguoiDKHM A, DangkiHM B, KetquaKLS C, Nguoihienmau D,Tuimau E
where A.CCCD_HC = B.CCCD_HC and B.MaDK = C.MSsangloc and C.MSsangloc = D.MaNHM and D.MaTM = E.MaTM
and B.Luongmaudukien < E.Thetich
group by A.CCCD_HC
having count(Hoten) >= all(
SELECT count(Hoten)
from NguoiDKHM A, DangkiHM B, KetquaKLS C, Nguoihienmau D,Tuimau E
where A.CCCD_HC = B.CCCD_HC and B.MaDK = C.MSsangloc and C.MSsangloc = D.MaNHM and D.MaTM = E.MaTM
and B.Luongmaudukien < E.Thetich
group by A.CCCD_HC
);





6--
Đưa ra những địa  điểm mà một người đã từng tham gia hiên máu tại điểm đó, và chỉ ra xem mức độ ưu thích của người đó với địa điểm hiển máu

select A.Hoten,B.CCCD_HC ,E.MaDD,E.TenDD, count(MaNHM)
from NguoiDKHM A, DangkiHM B, KetquaKLS C, Nguoihienmau D, DiadiemDKHM E
where A.CCCD_HC = B.CCCD_HC and B.MaDK = C.MSsangloc and C.MSsangloc = D.MaNHM and B.MaDD = E.MaDD
group by B.CCCD_HC, E.MaDD
having count(MaNHM) > 2
order by B.CCCD_HC, count(MaNHM); 
----------------------------------------
DELIMITER $$
    CREATE FUNCTION Diadiemuuthich(Solan int) 
    RETURNS VARCHAR(100)
    DETERMINISTIC
BEGIN
    DECLARE DDHM VARCHAR(100);
    IF solan >= 3 THEN
        SET DDHM = "Dia diem uu thich";
    ELSEIF (solan > 1 and solan < 3) THEN
        SET DDHM = "Chua phai dia diem uu thich";
    ELSEIF (solan > 0 and solan < 2)THEN
		SET DDHM = 'Khong phai dia diem uu thich';
    END IF;
	RETURN (DDHM);
END$$

create procedure DDHMuuthich(IN Nguoihienmau char(12)) 
BEGIN
   select A.Hoten,E.TenDD,Diadiemuuthich(count(MaNHM)) as DiadiemUT, count(MaNHM) as solan
from NguoiDKHM A, DangkiHM B, KetquaKLS C, Nguoihienmau D, DiadiemDKHM E
where A.CCCD_HC = B.CCCD_HC and B.MaDK = C.MSsangloc and C.MSsangloc = D.MaNHM and B.MaDD = E.MaDD
and Nguoihienmau = A.CCCD_HC
group by B.CCCD_HC, E.MaDD
order by B.CCCD_HC, count(MaNHM); 
END$$

DELIMITER ;

drop procedure DDHMuuthich;

call DDHMuuthich('095225858020');
call DDHMuuthich('013922232263');


7-- Địa điểm có sô lượng người đến tham gia đăng kí hiến máu nhiều nhất theo từng năm 

select  A.YEAR, E.MaDD, E.TenDD,E.Diachi, count(B.MaDK) as Soluong
from (select year(Thoigian) as YEAR from DangkiHM group by YEAR) A, DangkiHM B, DiadiemDKHM E
where B.MaDD = E.MaDD and year(B.Thoigian) = A.YEAR
group by E.MaDD,A.YEAR
having count(B.MaDK) >= all(
select count(MaDK) from DiadiemDKHM E, DangkiHM B
where B.MaDD = E.MaDD and year(B.Thoigian) = A.YEAR
group by E.MaDD
)
order by A.YEAR;



8-- Đưa ra số lượng người đăng kí hiến máu ở các ddhm theo cùng quận hoặc khác quận với ddhm

DELIMITER $$
    CREATE FUNCTION Khuvuc(QuanHuyenDDHM VARCHAR(100), QuanHuyenNHM VARCHAR(100)) 
    RETURNS VARCHAR(100)
    DETERMINISTIC
BEGIN
    DECLARE NNThanh VARCHAR(100);
    IF QuanHuyenDDHM = QuanHuyenNHM THEN
        SET NNThanh = "Noi Quan,Huyen";
    ELSE SET NNThanh = "Ngoai Quan,Huyen";
    END IF;
	RETURN (NNThanh);
END$$
DELIMITER ;

DELIMITER $$
create procedure DKHM_Khuvuc(IN Diadiem char(4)) 
BEGIN
    select B.MaDD,Khuvuc(E.Quan_HuyenDDHM, F.Quan_HuyenNHM) as Khuvuc,count(C.MaDK) as SoluongDKHM
from DiadiemDKHM B, DangkiHM C, NguoiDKHM D, (select MaDD,substring(Diachi from locate(',', Diachi) + 1) as Quan_HuyenDDHM from DiadiemDKHM) E,
(select CCCD_HC,substring(Diachi from locate(',', Diachi) + 1) as Quan_HuyenNHM from NguoiDKHM) F
where B.MaDD = C.MaDD and C.MaDD = E.MaDD and D.CCCD_HC = C.CCCD_HC and C.CCCD_HC = F.CCCD_HC and Diadiem = E.MaDD
group by B.MaDD,E.Quan_HuyenDDHM, Khuvuc;
END$$
DELIMITER ;

call DKHM_Khuvuc('DD01');

drop procedure DKHM_Khuvuc;
drop FUNCTION Khuvuc;

9-- Đưa ra các địa điểm có số lượng người đến đăng kí hiến máu tăng dần trong 3 năm liên tiếp

select Diadiem.DD as MaDD, Nam.YEAR as NamThuNhat, Nam.YEAR+1 as NamThuHai, YEAR+2 as NamThuBa
from (select year(Thoigian) as YEAR from DangkiHM group by YEAR) Nam ,
    (select MaDD as DD from DiadiemDKHM group by DD) Diadiem,DiadiemDKHM a, DangkiHM c
where a.MaDD = c.MaDD and Nam.YEAR = year(c.Thoigian) and Diadiem.DD = a.MaDD
group by Diadiem.DD, Nam.YEAR
having count(c.MaDK) < (
    select count(c.MaDK)  from DiadiemDKHM a, DangkiHM c
    where a.MaDD = c.MaDD and year(c.Thoigian) - Nam.YEAR = 1 and Diadiem.DD = a.MaDD
    group by Diadiem.DD, Nam.YEAR
    having count(c.MaDK) < (
        select count(c.MaDK)  from DiadiemDKHM a, DangkiHM c
        where a.MaDD = c.MaDD and year(c.Thoigian) - Nam.YEAR = 2 and Diadiem.DD = a.MaDD
        group by Diadiem.DD, Nam.YEAR
))
order by a.MaDD, Nam.YEAR;

10--Đưa ra thông tin Donvivanchuyen cung cấp số lượng túi máu nhóm XX nhiều nhất cho ngân hàng YY trong năm ZZZZ

DELIMITER $$
create procedure SoluongCCMax(IN NganhangM char(4), Nam char(4),Nhommau char(3))
BEGIN
    select A.Nganhang, H.MaDV, H.TenDVVC, count(F.MaTM) as SLMAX
from (select MaNH as Nganhang from Nganhangmau) A,DangkiHM B, KetquaKLS D, Nguoihienmau E,
Tuimau F, Donvanchuyen G, Donvivanchuyen H, Nganhangmau K, Goixetnghiem M, KetquaXNSL N
where B.MaDK = D.MSsangloc and D.MSsangloc = E.MaNHM and E.MaTM = F.MaTM and A.Nganhang = K.MaNH and F.MaTM = G.MaTM and G.MaDV = H.MaDV and G.MaNH = K.MaNH
and F.KetquaXN = M.Maxetnghiem and M.MaXNSL = N.MaXNSL
and Nhommau = N.NhommauABO
and NganhangM = K.MaNH
and Nam = year(B.Thoigian)
group by H.MaDV, A.Nganhang
having count(F.MaTM) >= all(
    select count(F.MaTM)
    from DangkiHM B, KetquaKLS D, Nguoihienmau E,Tuimau F, Donvanchuyen G, Donvivanchuyen H, Nganhangmau K, Goixetnghiem M, KetquaXNSL N
    where B.MaDK = D.MSsangloc and D.MSsangloc = E.MaNHM and E.MaTM = F.MaTM and A.Nganhang = K.MaNH and F.MaTM = G.MaTM and G.MaDV = H.MaDV and G.MaNH = K.MaNH
    and F.KetquaXN = M.Maxetnghiem and M.MaXNSL = N.MaXNSL
    and Nhommau = N.NhommauABO
    and NganhangM = K.MaNH
    and Nam = year(B.Thoigian)
    group by H.MaDV, A.Nganhang
);
END$$
DELIMITER ;

call SoluongCCMax('NH01','2021','AB');
drop procedure SoluongCCMax;
