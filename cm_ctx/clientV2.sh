#!/bin/bash

# This script updates customer records in a loop

if [ $# -ne 1 ];
   then
   echo "Error: SLA name is required..."
   echo "$0 <sla>"
   exit 1
fi

i="0"

while [ 1 ]
do
dbaccess -e stores@$1 - <<!
set lock mode to wait;
select dbservername from sysmaster:sysdual;
update customer set email=email where customer_num=120;
update coupons set discount = discount + 5 where coupon_code=3;
update coupons set discount = discount - 5 where coupon_code=3;
!
i=$[$i+1]
echo "clientV2.sh:Loop count $i, enter 'Control-C' to stop script"
sleep 1
done
