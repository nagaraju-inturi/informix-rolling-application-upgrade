#!/bin/sh
#This script will force kill servers within a certain range of server numbers
#Also depending on the option, it could be used to clean up all shared memory
#created by any Informix server instance and all oninit processes. Since the
#latter behavior is somewhat drastic, it should be used with care. Also, will
#kill qa processes, keying from runqa and descending down to its children. Will
#revisit this description once I have a better idea of what I want to do.
#
#Revision history
#================
#
#04/28/04 FR	Initial development of this script

usage()
{
   echo "Usage: server_kill.sh"
   echo "         -brute | -srvnum <srv. num to kill> [-num_sess <no. of srvs>]" 
   echo "         -y"
   echo "Notes"
   echo "====="
   echo "-brute and -srvnum options are mutually exclusive. Use one or the"
   echo "other, but not both"
   echo ""
   echo "-num_sess is used with -srvnum to provide number of servers to kill"
   echo "starting from the server number provided by argument to -srvnum option"
   echo "If -num_sess is not provided, it defaults to 1 server session"
   echo ""
   echo "-y option is used to avoid the script from executing interactively"
   echo "If -y is left out, every action will require the user to respond with"
   echo "y|Y or n|N"
   exit 1
}

yesno()
{
   #This function retrieves a yes or no response 
   yn="" 
   while [ "$yn" != 'Y' -a "$yn" != 'y' -a "$yn" != 'N' -a "$yn" != 'n' ]
   do
     echo "$message"
     read yn < /dev/tty
   done 

   if [ "$yn" = 'Y' -o "$yn" = 'y' ] ; then
      yn=0
   else
      yn=1
   fi
}

brute_clean()
{
  #This function will clean up all shared memory and semaphores that
  #belong to user informix or group informix. It will also cleanup 
  #disk space and QA processes. The right order is QA processes,
  #servers and then disk space.

  #First cleanup QA processes. Start with runqa and drill down 2 levels
  #or until no spawned children are found
  /bin/ps -ef | grep runqa | grep -v grep | awk '{ print $2 }' > /tmp/runqa_pids.$$
  if [ -s /tmp/runqa_pids.$$ ] ; then
     cat /dev/null > /tmp/runqa_kids.$$
     #There are runqa processes running, so now find their children and    
     #store those in another file
     while read runqa_pid
     do
       /bin/ps -ef | grep $runqa_pid | awk '{ print $2 }' | grep -v $runqa_pid >> /tmp/runqa_kids.$$
     done < /tmp/runqa_pids.$$
     if [ -s /tmp/runqa_kids.$$ ] ; then
        cat /dev/null > /tmp/runqa_kids_kids.$$
        while read runqa_kid_pid
        do
          /bin/ps -ef | grep $runqa_kid_pid | awk '{ print $2 }' | grep -v $runqa_kid_pid >> /tmp/runqa_kids_kids.$$
        done < /tmp/runqa_kids.$$
        #append pids in /tmp/runqa_kids_kids.$$ to /tmp/runqa_kids.$$
        cat /tmp/runqa_kids_kids.$$ >> /tmp/runqa_kids.$$
        rm -f /tmp/runqa_kids_kids.$$
     fi
     #append pids in /tmp/runqa_kids.$$ to /tmp/runqa_pids.$$
     cat /tmp/runqa_kids.$$ >> /tmp/runqa_pids.$$
     rm -f /tmp/runqa_kids.$$

     #Now that all the pids are in /tmp/runqa_pids.$$, loop through this file
     #and systematically kill these processes.
     while read pid_to_kill
     do
       if [ $noask_opt -eq 0 ] ; then
          message=`/bin/ps -ef | grep $pid_to_kill | grep -v grep` 
          if [ -n "$message" ] ; then
             message="Do you wish to kill,\n    $message?"
             yesno
          else
             yn=1
          fi
          if [ $yn -eq 1 ] ; then
             continue
          fi
       fi
       kill -9 $pid_to_kill > /dev/null 2>&1 
     done < /tmp/runqa_pids.$$
     rm -f /tmp/runqa_pids.$$
  else
     echo "No runqa (and children) to kill"
  fi

  #Now remove any shared memory segments, semaphores etc.
  ipcs | egrep "0x52|0x53" | egrep "informix" > /tmp/ipcs.$$
  if [ -s /tmp/ipcs.$$ ] ; then
     while read input_line
     do
       ipc_type=`echo $input_line | cut -f1 -d' '`
       if [ "$ipc_type" = "m" ] ; then
          ipc_id=`echo $input_line | cut -f2 -d' '`
          if [ -n "$ipc_id" ] ; then
             if [ $noask_opt -eq 0 ] ; then
                message="Do you wish to remove shared mem. seg.,\n  $input_line?" 
                yesno
                if [ $yn -eq 1 ] ; then
                   continue
                fi
             fi
             ipcrm -m $ipc_id > /dev/null 2>&1
          fi
       fi
     done < /tmp/ipcs.$$
  else
     echo "No Shared memory segments to remove"
  fi
  rm -f /tmp/ipcs.$$

  #Now that we have removed all the shared memory segments that belong
  #to user informix, we need to remove semaphores that belong to user
  #informix or group informix.
  ipcs | grep "informix" > /tmp/ipcs.$$
  if [ -s /tmp/ipcs.$$ ] ; then
     while read input_line
     do
       ipc_type=`echo $input_line | cut -f1 -d' '`
       if [ "$ipc_type" = "s" ] ; then
          ipc_id=`echo $input_line | cut -f2 -d' '`
          if [ -n "$ipc_id" ] ; then
             if [ $noask_opt -eq 0 ] ; then
                message="Do you wish to remove semaphore,\n  $input_line?"
                yesno
                if [ $yn -eq 1 ] ; then
                   continue
                fi
             fi
             ipcrm -s $ipc_id > /dev/null 2>&1
          fi
       fi
     done < /tmp/ipcs.$$
  else
     echo "No Semaphores to remove"
  fi
  rm -f /tmp/ipcs.$$

  #Now that we are done bringing down the informix servers, we can cleanup
  #diskspace. I will assume that all diskspace being used for dbspaces and
  #such will be found under directories of the format /ATM/*/dbspaces/*
  #Furthermore, will assume that anyfile >= 5M is a dbspace and will be
  #zeroed out.
  ls -d -1 /ATM/*/dbspaces/* > /tmp/dbspace_dirs.$$
  if [ -s /tmp/dbspace_dirs.$$ ] ; then
     while read dbspace_dir
     do
       ls -lL $dbspace_dir | grep -v "^d" | /bin/awk '{print $9}' | sed '/^$/d'> /tmp/dbspaces.$$
       if [ -s /tmp/dbspaces.$$ ] ; then
          while read dbspaces
          do
            file_path=$dbspace_dir/$dbspaces
            file_type=`file $file_path`
            echo $file_type | grep -i "data" > /dev/null
            if [ $? -eq 0 ] ; then
               #Only consider files that show up as data. This will avoid
               #messing up logiles, scripts, binaries etc.
               #dbspace_size=`ls -l $file_path | awk '{print $5}'`
               #if [ $dbspace_size -ge 1000000 ] ; then
               if [ $noask_opt -eq 0 ] ; then
                  message="Do you wish to zero file,\n  $file_path?"
                  yesno
                  if [ $yn -eq 1 ] ; then
                     continue
                  fi
               fi
               #At this point it appears pretty safe to zero out the
               #contents of the file
               chmod 666 $file_path > /dev/null 2>&1
               cat /dev/null > $file_path 
               #fi
            fi
          done <  /tmp/dbspaces.$$
       fi
     done < /tmp/dbspace_dirs.$$
  else
     echo "No dbspaces to zero out"
  fi
  rm -f /tmp/dbspaces.$$ /tmp/dbspace_dirs.$$
}


servnum_clean()
{
  #This function will take the server number supllied and delete all the
  #shared memory segments connected with it. If -num_sess option is used
  #it will increment server number and do the same until all servers are
  #(in the range) are brought down.
  server_number=$SERVER_NUMBER
  number_of_sessions=$NUMBER_OF_SESSIONS

  while [ $number_of_sessions -gt 0 ]
  do
    shmkey=`expr $SHMKEY_BASE + $server_number`
    shmkey_hex=`printf "%x" $shmkey`
    shmkey_hex=0x$shmkey_hex
    ipcs -m | grep $shmkey_hex > /tmp/ipcs.$$
    if [ -s /tmp/ipcs.$$ ] ; then
       while read input_line
       do
#         ipc_type=`echo $input_line | cut -f1 -d' '`
#         if [ "$ipc_type" = "m" ] ; then
            ipc_id=`echo $input_line | cut -f2 -d' '`
            if [ -n "$ipc_id" ] ; then
               if [ $noask_opt -eq 0 ] ; then
                  message="Do you wish to remove shared mem. seg.,\n  $input_line?"
                  yesno
                  if [ $yn -eq 1 ] ; then
                     continue
                  fi
               fi
               #Find out the creator pid and kill that process. This will be
               #the parent oninit.
               ipc_crid=`echo $input_line | awk '{print $11}'`
               kill -9 $ipc_crid > /dev/null 2>&1
               ipcrm -m $ipc_id > /dev/null 2>&1 
            fi
#         fi
       done < /tmp/ipcs.$$
    else
       echo "Server number: $server_number, not running. No shared mem. segs. found"
    fi
    rm -f /tmp/ipcs.$$
    server_number=`expr $server_number + 1`
    if [ $server_number -gt 255 ] ; then
       break
    fi
    number_of_sessions=`expr $number_of_sessions - 1`
  done 
}


#main starts here
SHMKEY_BASE=21078

#What platform is the script running on?
PLATFORM=`uname`

#Who is running the script
if [ $PLATFORM = "SunOS" -o $PLATFORM = "UnixWare" ] ; then
   OWNER=`/usr/ucb/whoami`
else
   OWNER=`whoami`
fi

#initialize variables for detecting various options
brute_opt=0
servnum_opt=0
numsess_opt=0
noask_opt=0

#parse the command line
if [ $# -eq 0 ] ; then
   usage
   exit 1
else
   while [ $# -ne 0 ]
   do
     case $1 in
       -brute)brute_opt=1;;
       -srvnum)servnum_opt=1;SERVER_NUMBER=$2;shift;;
       -num_sess)numsess_opt=1;NUMBER_OF_SESSIONS=$2;shift;;
       -y)noask_opt=1;;
       *)echo "Invalid option: $1"; echo; usage;;
     esac
     shift
   done
fi

#Do some error checking 
if [ $brute_opt -eq 1 -a \( $servnum_opt -eq 1 -o $numsess_opt -eq 1 \) ] ; then
   echo "-brute option cannot be used with -srvnum or -num_sess option"
   usage
   exit 1
fi
 
if [ $numsess_opt -eq 1 -a $servnum_opt -eq 0 ] ; then
   echo "-num_sess option cannot be used without -srvnum option"
   usage
   exit 1
fi

if [ $noask_opt -eq 1 -a $servnum_opt -eq 0 -a $brute_opt -eq 0 ] ; then
   echo "Nothing to do. Please use -srvnum or -brute option along with -y option"
   usage
   exit 1
fi

if [ $servnum_opt -eq 1 ] ; then
   if [ $SERVER_NUMBER -lt 0 -o $SERVER_NUMBER -gt 255 ] ; then
      echo "Invalid server number. Please enter a server number bet. 0 and 255."
      exit 1
   elif [ $numsess_opt -eq 0 ] ; then
      NUMBER_OF_SESSIONS=1
   elif [ $NUMBER_OF_SESSIONS -lt 1 -o $NUMBER_OF_SESSIONS -gt 255 ] ; then
      echo "Invalid number of server sessions to kill. Should be between 1 & 255."
      exit 1
   fi
fi 

#Now the work begins

if [ $brute_opt -eq 1 ] ; then
   brute_clean
elif [ $servnum_opt -eq 1 ] ; then
   servnum_clean
else
   echo "Did not have anything to do! Check options supplied"
   exit 1
fi
