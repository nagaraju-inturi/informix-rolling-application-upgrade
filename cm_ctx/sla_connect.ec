/**************************************************************************
*  Licensed Materials - Property of IBM                                  
*                                                                        
*  "Restricted Materials of IBM"                                        
*                                                                       
*  IBM Informix Dynamic Server                                          
*                                                                       
*  (c) Copyright IBM Corporation 1996, 2007 All rights reserved.         
*
*  Title:	 cm_connect.ec
*  Author:   Nilesh Ozarkar
*  Description:  Issue connect statement, and check where connected. 
*
**************************************************************************
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

EXEC SQL include sqlca;

#define SLEEPTIME 2
#define MAXRETRY  5
#define SUCCESS 0
#define INVALID_ARG 1

//EXEC SQL include qaincl.h;
//EXEC SQL include "veresqlc.h";

int error_flag = 0;

char* slaname = NULL;
void 
usage(char *const *argv)
{
	printf("Usage: %s -s SLA [-h] \n", argv[0]);
	printf("\n", argv[0]);
	printf("\t-s  SLA name to use as INFORMIXSERVER\n");
	printf("\t-h  Print this message\n");
}


int
process_cmdline(int argc, char *const *argv)
{
	int optcount;
	char *optptr;

	slaname = NULL;

	/* Process the command line options */
	for (optcount = 1; optcount < argc; optcount++)
	{
		optptr = argv[optcount];
		if (*optptr == '-')
		{
			switch (*++optptr)
			{
				case 'h':
				case '?':
					usage(argv);
					exit(0);
					break;
				case 's':	/* SLA name */
					if (!argv[optcount+1])
						return INVALID_ARG;
					slaname = (char *)strdup(argv[++optcount]);
					break;
				default :
					printf("Invalid command line option specified\n");
					return INVALID_ARG;
			}
		}
	}
	if (!slaname) 
		{
		printf("SLA name is not specified\n");
		return INVALID_ARG;
		}

	return SUCCESS;
}

int 
main(int argc, char *argv[])
{
	$char dbservername[128];
	$char DBVAR[128];
	int  retry=0, connected=0;
    int space=' ';
     char *space_ptr;

	/* Parse the command line options */
	if (process_cmdline(argc, argv) != SUCCESS)
	{
		usage(argv);
		exit(-1);
	}

    printf("===== %s =====\n", argv[0]);
    printf("Client's SLA  : %s\n",slaname);
    //printf("INFORMIXSERVER: %s\n",getenv("INFORMIXSERVER"));

    for (retry=0; retry < MAXRETRY && !connected; retry++)
	{

        sprintf(DBVAR, "@%s", slaname);
        $ connect to :DBVAR;

	    if (SQLCODE == 0) 
		{
		    connected = 1;
			
		    $database sysmaster;
	        $ select first 1 DBSERVERNAME into :dbservername from sysdatabases;
            space_ptr=strchr(dbservername,space); 
			if (space_ptr)
                 dbservername[space_ptr-dbservername]='\0';
			printf("Client Redirected to: [%s]\n", dbservername);

			$ disconnect current;
		}
		else {
		   error_flag++;
	       printf("SQLCODE = %d, Sleeping for %d seconds\n", SQLCODE, SLEEPTIME);
		   sleep (SLEEPTIME);
		}
	}

    printf("==========================\n", argv[0]);

	return(error_flag);
}

