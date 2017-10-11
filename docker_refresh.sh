docker stop cm1
docker stop cm2
docker stop east
docker stop east_dr
docker stop west
docker stop west_dr
docker stop south
docker stop south_dr
docker rm cm1
docker rm cm2
docker rm east
docker rm east_dr
docker rm west
docker rm west_dr
docker rm south
docker rm south_dr
docker ps -a -q | xargs -n 1 -I {} docker rm {}
docker rmi $( docker images | grep '<none>' | tr -s ' ' | cut -d ' ' -f 3)
docker volume rm $(docker volume ls -qf dangling=true)
cd ./server_ctx
docker build -t replication/informix .
cd ../cm_ctx
docker build -t replication/cm .
docker network rm replication_nw
