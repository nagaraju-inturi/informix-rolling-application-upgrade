export DEMODIR=/opt/ibm/informix/demo/dbaccess/demo_ids
dbaccess stores - <<!
set lock mode to wait;

load from "$DEMODIR/customer.unl"
   insert into customer;

load from "$DEMODIR/orders.unl"
   insert into orders;

load from "$DEMODIR/manufact.unl"
   insert into manufact;

load from "$DEMODIR/stock.unl"
   insert into stock;

load from "$DEMODIR/items.unl"
   insert into items;

load from "$DEMODIR/state.unl"
   insert into state;

load from "$DEMODIR/call_type.unl"
   insert into call_type;

load from "$DEMODIR/cust_calls.unl"
   insert into cust_calls;

update statistics;

grant resource to public;
!
