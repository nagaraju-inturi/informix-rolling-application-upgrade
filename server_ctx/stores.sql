set lock mode to wait;
create table customer
        (
        customer_num            serial(101),
        fname                   char(15),
        lname                   char(15),
        company                 char(20),
        address1                char(20),
        address2                char(20),
        city                    char(15),
        state                   char(2),
        zipcode                 char(5),
        phone                   char(18),
       primary key (customer_num)
        ) with crcols;
  create table orders
        (
        order_num               serial(1001),
        order_date              date,
        customer_num            integer not null,
        ship_instruct           char(40),
        backlog                 char(1),
        po_num                  char(10),
        ship_date               date,
        ship_weight             decimal(8,2),
        ship_charge             money(6),
        paid_date               date,
        primary key (order_num),
        foreign key (customer_num) references customer (customer_num)
        ) with crcols;
create table manufact
        (
        manu_code               char(3),
        manu_name               char(15),
        lead_time               interval day(3) to day,
        primary key (manu_code)
        ) with crcols;
create table stock
        (
        stock_num               smallint,
        manu_code               char(3),
        description             char(15),
        unit_price              money(6),
        unit                    char(4),
        unit_descr              char(15),
       primary key (stock_num, manu_code),
       foreign key (manu_code) references manufact
         ) with crcols;
   create table items
        (
        item_num                smallint,
        order_num               integer,
        stock_num               smallint not null,
        manu_code               char(3) not null,
        quantity                smallint check (quantity >= 1),
        total_price             money(8),
       primary key (item_num, order_num),
       foreign key (order_num) references orders (order_num),
       foreign key (stock_num, manu_code) references stock (stock_num, manu_code)
	 ) with crcols;
create table state
        (
        code                    char(2),
        sname                   char(15),
        primary key (code)       
        ) with crcols;
create table call_type
       (
       call_code                        char(1),
       code_descr                       char(30),
       primary key (call_code)
       ) with crcols;
create table cust_calls
       (
       customer_num            integer,
       call_dtime              datetime year to minute,
       user_id                 char(32) default user,
       call_code               char(1),
       call_descr              char(240),
       res_dtime               datetime year to minute,
       res_descr               char(240),
       primary key (customer_num, call_dtime),
       foreign key (customer_num) references customer (customer_num),
       foreign key (call_code) references call_type (call_code)
        ) with crcols;
create index zip_ix on customer (zipcode);
create table catalog
       (
       catalog_num              serial(10001),
       stock_num                smallint not null,
       manu_code                char(3) not null,
       cat_descr                text,
       cat_picture              byte,
       cat_advert               varchar(255, 65),
       primary key (catalog_num),
       foreign key (stock_num, manu_code) references stock constraint aa
       ) with crcols;
