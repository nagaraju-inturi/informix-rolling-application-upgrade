dbaccess stores - <<!
set lock mode to wait;
--Load data into coupons table
load from coupons.unl insert into coupons;

-- Update Frank and Chris email and twitter ids.
update customer set (email, twitter) = ("Frank_Lessor@gmail.com", "@Frank_Lessor") where customer_num=128;
update customer set (email, twitter) = ("Chris_Putnum@gmail.com", "@Chris_Putnum") where customer_num=124;

-- Add new customer records
insert into customer (customer_num, fname, lname, company, address1, address2, city, state, zipcode, phone, email, twitter) values(130, "Sam", "Hill", "IBM", "11200 Lakeview ave", "", "Lenexa", "KS", 66219, "913-222-444", "sam_hill@us.ibm.com", "@sam_hill");
insert into customer (customer_num, fname, lname, company, address1, address2, city, state, zipcode, phone, email, twitter) values(131, "Alex", "Smith", "Chiefs", "1 Arrowhead Dr", "", "Kansas city", "MO", 64129, "816-232-474", "alex_smith@us.ibm.com", "@alex_smith");
!
