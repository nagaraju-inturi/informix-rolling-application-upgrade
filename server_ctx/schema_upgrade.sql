-- Set grid context for the client, 
-- required to replicate DDLs and update replicate definitions
--execute procedure ifx_grid_connect('grid1', 'schema_upgrade', 1);

--Add email and twitter id columns to customer table
alter table customer add email char(100);
alter table customer add twitter char(100);

-- Increase customer first and last name length from 15 to 128 characters.
alter table customer modify fname char(128);
alter table customer modify lname char(128);

-- Create new coupons table for promotion offers.
create table coupons (coupon_code int primary key, 
                      coupon_desc char(512),
                      discount int, 
                      start_date date, 
                      end_date date) with crcols lock mode row;
