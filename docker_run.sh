docker network create --subnet=172.20.0.0/16 replication_nw
docker run --net=replication_nw --ip=172.20.0.10 -d -h east --name east replication/informix  --start east
sleep 10

docker run --net=replication_nw --ip=172.20.0.11 -d -h east_dr --name east_dr replication/informix  --start east_dr 

docker run --net replication_nw --ip 172.20.0.12 -d -h west --name west replication/informix --start west 
docker logs west
sleep 10
docker exec -it west /opt/ibm/boot.sh --shell onstat -

docker run --net replication_nw --ip 172.20.0.13 -d -h west_dr --name west_dr replication/informix --start west_dr 

docker run --net replication_nw --ip 172.20.0.14  -d -h south --name south replication/informix --start south 
docker logs south
sleep 10
docker exec -it south /opt/ibm/boot.sh --shell onstat -

docker run --net replication_nw --ip 172.20.0.15 -d -h south_dr --name south_dr replication/informix --start south_dr 


docker run --net replication_nw --ip 172.20.0.16 -d -h cm1 --name cm1 replication/cm  --start cm1
