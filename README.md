# informix-rolling-application-upgrade
Zero downtime rolling schema and application upgrade

This lab is based on docker images. 

Download and install docker : https://www.docker.com/get-docker

Run docker_refresh.sh command to build docker images. NOTE: This script removes all existing images on the system. You may not want to comment that out if you have other images on the system that you do not want to delete.

Run docker_run.sh to start dococker containers.

Follow instructions in rolling_schema_upgrade_instructions.pdf to go through the process of zero downtime upgrade for database schema and applications.


![alt text](block_diagram.png "Block Diagram for the demo scenario")
