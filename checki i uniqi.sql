alter table ConferenceDayWorkshops
add constraint CHK_TIME check (StartTime < EndTime)

alter table ConferenceDayWorkshops
add constraint CHK_SIZES_NON_NEGATIVE check (ParticipantsLimit > 0 and price >= 0)

alter table WorkshopReservation
add constraint CHK_VALID_RESERVATION check (ReservedSeats > 0)

alter table Participants
add constraint CHK_PHONE_UNIQ unique (Phone)

alter table Participants
add constraint CHK_EMAIL_UNIQ unique (email)

alter table ConferencePricetables
add constraint CHK_DATES check (datediff(day, PriceStartsOn, PriceEndsOn) >= 0)

alter table ConferenceDays
add constraint CHK_DAY_ORDINAL check (dayordinal > 0)

alter table ConferenceDays
add constraint CHK_DAY_ORD_UNIQ unique (ConferenceID, DayOrdinal)

alter table ConferenceDayReservation
add constraint CHK_RESERVATION check(ReservedAdultSeats >= 0 and
									 ReservedStudentSeats >= 0 and
									 ReservedAdultSeats + ReservedStudentSeats > 0)

alter table OurEmployees
add constraint CHK_EMP_DATES check (BirthDate < getdate() and HireDate <= getdate())

alter table OurEmployees
add Email varchar(100) check (Email like '%_@_%._%')

alter table OurEmployees
add constraint CHK_EMP_PHONE check (Phone not like '%[^0-9]%')

alter table OurEmployees
add constraint CHK_EMP_PHONE_UNIQ unique (Phone)

alter table OurEmployees
add constraint CHK_EMP_EMAIL_UNIQ unique (email)

alter table Conferences
add constraint CHK_CONF_DATES check (datediff(day, StartDate, EndDate) >= 0)

alter table Conferences
add constraint CHK_CONF_PRICE check (BasePriceForDay >= 0)

alter table Conferences
add constraint CHK_CONF_PARTICIP check (ParticipantsLimit > 0)

alter table ConferenceReservations
add constraint CHK_PAID_AFTER_RESERVED check (DatePaid >= DateOrdered)

alter table Companies
add constraint CHK_NIP check (NIP not like '%[^0-9]%')

alter table Conferences
add constraint DEF_BASEPRICE default(0) for StudentDiscount

alter table ConferencePricetables
add constraint DEF_DISCOUNT default(0) for DiscountRate

alter table ConferenceDayWorkshops
add constraint DEF_WKSH_PRICE default(0) for Price