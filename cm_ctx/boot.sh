#!/bin/sh 

export INFORMIXDIR=/opt/ibm/informix
export PATH=":${INFORMIXDIR}/bin:.:${PATH}"
export INFORMIXSQLHOSTS="${INFORMIXDIR}/etc/sqlhosts"
export LD_LIBRARY_PATH="${INFORMIXDIR}/lib:${INFORMIXDIR}/lib/esql:${LD_LIBRARY_PATH}"

SLEEP_TIME=1  # Seconds
MAX_SLEEP=240 # Seconds

echoThis()
{
  timestamp=`date --rfc-3339=seconds`
  echo "[$timestamp] $@"
  echo "[$timestamp] $@" >> /tmp/informix.log
}

function clean_up {

    # Perform program exit housekeeping
    echo "${sn} stop: Shutting down CM Instance ..."
    su informix -c "${INFORMIXDIR}/bin/oncmsm -k $CM_NAME"
    echo "${sn} stop: done"
    
    exit 0
}

trap clean_up SIGHUP SIGINT SIGTERM


if [ -f /etc/profile.d/informix.sh ]; then
    . /etc/profile.d/informix.sh
fi
local_ip=`ifconfig eth0 |awk '{if(NR==2)print $2}'`

preStart()
{
setStr="
#!/bin/bash

export INFORMIXDIR=/opt/ibm/informix
export PATH="${INFORMIXDIR}/bin:\${PATH}"
export INFORMIXSERVER="west"
export INFORMIXSQLHOSTS=\"${INFORMIXSQLHOSTS}\"
export LD_LIBRARY_PATH="${INFORMIXDIR}/lib:${INFORMIXDIR}/lib/esql:${LD_LIBRARY_PATH}"
export CM_NAME=\"${CM_NAME}\"
"
   echo "${setStr}" > /etc/profile.d/informix.sh
   . /etc/profile.d/informix.sh
   chown informix:informix /etc/profile.d/informix.sh
   chmod 644 /etc/profile.d/informix.sh
   echo "g_east group - - i=1" >${INFORMIXDIR}/etc/sqlhosts
   echo "east onsoctcp 172.20.0.10 60000 g=g_east" >>${INFORMIXDIR}/etc/sqlhosts
   echo "east_dr onsoctcp 172.20.0.11 60000 g=g_east" >>${INFORMIXDIR}/etc/sqlhosts
   echo "g_west group - - i=2" >>${INFORMIXDIR}/etc/sqlhosts >>${INFORMIXDIR}/etc/sqlhosts
   echo "west onsoctcp 172.20.0.12 60000 g=g_west" >> ${INFORMIXDIR}/etc/sqlhosts
   echo "west_dr onsoctcp 172.20.0.13 60000 g=g_west" >> ${INFORMIXDIR}/etc/sqlhosts
   echo "g_south group - - i=3" >>${INFORMIXDIR}/etc/sqlhosts
   echo "south onsoctcp 172.20.0.14 60000 g=g_south" >> ${INFORMIXDIR}/etc/sqlhosts
   echo "south_dr onsoctcp 172.20.0.15 60000 g=g_south" >> ${INFORMIXDIR}/etc/sqlhosts

   chown informix:informix ${INFORMIXDIR}/etc/sqlhosts
   echo "oltp_w onsoctcp $local_ip 50000" >>${INFORMIXDIR}/etc/sqlhosts
   echo "report_w onsoctcp $local_ip 50001" >>${INFORMIXDIR}/etc/sqlhosts
   echo "oltp_e onsoctcp $local_ip 50002" >>${INFORMIXDIR}/etc/sqlhosts
   echo "report_e onsoctcp $local_ip 50003" >>${INFORMIXDIR}/etc/sqlhosts
   echo "oltp_s onsoctcp $local_ip 50004" >>${INFORMIXDIR}/etc/sqlhosts
   echo "report_s onsoctcp $local_ip 50005" >>${INFORMIXDIR}/etc/sqlhosts
   echo "grid_oltp1 onsoctcp $local_ip 50006" >>${INFORMIXDIR}/etc/sqlhosts
   echo "grid_oltp2 onsoctcp $local_ip 50007" >>${INFORMIXDIR}/etc/sqlhosts

}

echo $1
case "$1" in
    '--start')
	    if [ -e /etc/profile.d/informix.sh ]; then
                su informix -c "${INFORMIXDIR}/bin/oncmsm -c ${INFORMIXDIR}/etc/cmsm_demo.cfg"  && tail -f /dev/null
                exit 0
            fi
            CM_NAME=$2
            if [ "a$CM_NAME" = "a" ]; then
                CM_NAME="cm1"
             fi
            preStart
            echo "su informix -c \"${INFORMIXDIR}/bin/oncmsm -c ${INFORMIXDIR}/etc/cmsm_demo.cfg\" " >/opt/ibm/start_cm.sh
            echo "su informix -c \"${INFORMIXDIR}/bin/oncmsm -k $CM_NAME\"" >/opt/ibm/stop_cm.sh
            #sleep 5
            echo "${sn} start: done"
            tail -f /dev/null
        ;;
    '--initIP')
	if [ -e /etc/profile.d/informix.sh ]; then
            su informix -c "${INFORMIXDIR}/bin/oncmsm -c ${INFORMIXDIR}/etc/cmsm_demo.cfg"  && tail -f /dev/null
	     exit 0
	else
            echo "${sn} Local container ip address=$local_ip" && tail -f  /dev/null
	fi
        ;;
    '--getInfo')
        echo "${sn} Local container ip address=$local_ip"
        ;;
    '--initCM')
	    if [ -e /etc/profile.d/informix.sh ]; then
                su informix -c "${INFORMIXDIR}/bin/oncmsm -c ${INFORMIXDIR}/etc/cmsm_demo.cfg"  && tail -f /dev/null
                exit 0
            fi
            PRIMARY=$2
            PRIMARY_IP=$3
            CM_NAME=$4
            PRIORITY=$5
            if [ "a$CM_NAME" = "a" ]; then
                CM_NAME="cm1"
             fi
            if [ "a$PRIORITY" = "a" ]; then
                PRIORITY="1"
             fi
            if [ "a$PRIMARY" = "a" ]; then
               echo "Usage: ${sn} --initCM <primary name> <primary ip> [<cm name>] [<priority>]}"
               exit 1
            fi
            if [ "a$PRIMARY_IP" = "a" ]; then
               echo "Usage: ${sn} --initCM <primary name> <primary ip> [<cm name>] [<priority>]}"
               exit 1
            fi
            preStart
            echo "${sn} Local container ip address=$local_ip"  
            su informix -c "${INFORMIXDIR}/bin/oncmsm -c ${INFORMIXDIR}/etc/cmsm_demo.cfg"  && tail -f /dev/null
        exit 0
        ;;
    '--stop')
            echo "${sn} stop: Shutting down CM ..."
            su informix -c "${INFORMIXDIR}/bin/oncmsm -k $CM_NAME"
            echo "${sn} stop: done"
        ;;

    '--status')
        s="down"
        ps -ef|grep oncmsm|grep -v grep
        if [ $? -eq 0 ]; then
           s="up"
        fi
        echo "${sn} status: CM $CM_NAME Instance is ${s}"
        ;;

    '--addHost')
         host2add=$2
         serv2add=$3
         if [[ "a$host2add" != "a" && "a$serv2add" != "a" ]]; then
             echo "$serv2add onsoctcp $host2add 60000" >>${INFORMIXDIR}/etc/sqlhosts
         fi
        ;;
    '--shell')
        /bin/bash -c "$2 $3 $4 $5 $6"
        ;;
    *)
        echo "Usage: ${sn} {--start|--stop|--status|--addHost <server ip><server name>|--getInfo|--initCM <primary name> <primary ip addr> [<cm name>]}"
        ;;
esac

exit 0
