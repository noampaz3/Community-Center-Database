-- ========================================================================
-- COMMUNITY CENTER DATABASE - SCHEMA DEFINITION (DDL)
-- ========================================================================
-- Description: Table creation scripts ensuring data integrity via strict 
-- constraints, regex validations (emails, phones), and foreign keys.
-- ========================================================================

-- ------------------------------------------------------------------------
-- 1. Core Infrastructure Tables
-- ------------------------------------------------------------------------
create table communityCenter(
	centerID nvarchar(20) primary key,
	adress nvarchar(30) not null,
	phone char(10) not null check (phone like replicate('[0-9]',10) and phone like '05_%'),
	manager nvarchar (20) not null
)

create table building(
	centerID nvarchar(20) references communityCenter(centerID) on delete cascade,
	serialNum int unique check (serialNum > 0),
	isThereProjector char (1) not null check (isThereProjector in ('Y','N')),
	buildManager nvarchar(30), buildType nvarchar(20),maxCapacity int check(maxCapacity > 0),
	primary key(centerID,serialNum)
)

-- ------------------------------------------------------------------------
-- 2. Activities & Scheduling Tables
-- ------------------------------------------------------------------------
create table activity(
	activityID nvarchar(20) primary key,
	activityName nvarchar(30) not null,description nvarchar(255) not null,
	serialNum int,centerID nvarchar(20),
	foreign key (centerID,serialNum) references building(centerID, serialNum)
)

create table date(
	serialNum int,centerID nvarchar(20),
	foreign key (centerID,serialNum) references building(centerID,serialNum),
	activityID nvarchar(20) references activity(activityID),
	date date not null, startTime time not null,
	endTime time, maxCapacity int,
	primary key(centerID,serialNum,activityID,date)
)

-- ------------------------------------------------------------------------
-- 3. People & Engagement Tables
-- ------------------------------------------------------------------------
create table residents(
	resID char(9) primary key check(resID like replicate('[0-9]',9)),
	fullName nvarchar(30) not null, address nvarchar(30) not null,
	mail nvarchar(30) check (mail like '_%@_%._%') not null,
	personalPhone char(10) not null check (personalPhone like replicate('[0-9]',10) and personalPhone like '05_%'),
	homePhone nvarchar(10) not null,
	centerID nvarchar(20) references communityCenter(centerID)
)

create table volunteers(
	resID char(9) references residents(resID) primary key,
	expertiseArea nvarchar(20) not null,
	hasDriveLicense char (1) not null check (hasDriveLicense in ('Y','N'))
)

create table participant(
	resID char(9) references residents(resID),
	activityID nvarchar(20) references activity(activityID),
	primary key (resID,activityID)
)

-- ------------------------------------------------------------------------
-- 4. HR & Employees Tables
-- ------------------------------------------------------------------------
create table salariedEmployees(
	empID char(9) primary key check(empID like replicate('[0-9]',9)),
	fullName nvarchar(30) not null, address nvarchar(30) not null,
	mail nvarchar(30) check (mail like '_%@_%._%') not null,
	personalPhone char(10) not null check (personalPhone like replicate('[0-9]',10) and personalPhone like '05_%'),
	homePhone nvarchar(10) not null,
	empNumber int unique check (empNumber > 0) not null, selPerHour int check (selPerHour > 0),
	workStartDate date not null default getDate(),
	centerID nvarchar(20) references communityCenter(centerID) default 'Ruppin Hub'
)

create table accompanied(
	empIDaccompany char(9) references salariedEmployees(empID),
	empIDaccompanyby char(9) references salariedEmployees(empID),
	startAccDate date not null default getdate(),
	endAccDate date,
	primary key(empIDaccompany,empIDaccompanyby),check(empIDaccompany != empIDaccompanyby),
	check(endAccDate is null or endAccDate >= startAccDate)
)

create table donation(
	confirmationCode int primary key,
	donationAmount int check(donationAmount > 0),
	dateOfAmount date not null,
	CardNumber varchar(16) not null,
    ExpiryDate varchar(5) not null check(ExpiryDate like '_%/_%'),
    CVV char(3) not null,
	resID char(9) references residents(resID)
)

-- ------------------------------------------------------------------------
-- 5. Operations & Resources Tables
-- ------------------------------------------------------------------------
create table equipmentItem(
	serialNum int primary key check (serialNum > 0),
	name nvarchar (20) not null, description nvarchar(255), propCondition nvarchar(20) not null
)

create table borrow(
	resID char(9) references residents(resID),
	serialNum int references equipmentItem(serialNum),
	borrowDate date not null, planReturnDate date not null, check(planReturnDate > borrowDate)
)

create table task(
	taskName nvarchar(30) primary key,
	isLicenseRequired char (1) not null check (isLicenseRequired in ('Y','N'))
)

create table socialEnterprise(
	enterpriseName nvarchar(30) primary key,
	setDate date not null default getdate(),
	budget int check(budget > 0)
)

create table assign(
	resID char(9) references residents(resID),
	taskName nvarchar(30) references task(taskName),
	enterpriseName nvarchar(30) references socialEnterprise(enterpriseName),
	primary key(resID,taskName,enterpriseName)
)

-- Table Alterations for Borrow Table PK Configuration
alter table borrow
alter column resID char(9) not null
go

alter table borrow
alter column serialNum int not null
go

alter table borrow
add constraint PK_borrow primary key (resID,serialNum)
go

















