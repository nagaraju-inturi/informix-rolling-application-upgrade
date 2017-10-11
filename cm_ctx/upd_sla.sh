#!/bin/bash

# This script updates customer records in a loop

if [ $# -ne 2 ];
   then
   echo "Usage: $0 <sla> <server list>"
   exit 1
fi

sla=$1
server_list=$2
sed -i "s/^ .*SLA $sla.* .*/  SLA $sla         DBSERVERS=\($server_list\) POLICY=LATENCY/g" ${INFORMIXDIR}/etc/cmsm_demo.cfg

echo -n "New SLA definition:"
grep "^ .*SLA $sla.* .*" ${INFORMIXDIR}/etc/cmsm_demo.cfg

echo "Reloading connection manager configuration file..."
su informix -c "/opt/ibm/informix/bin/oncmsm -r cm1"
