docker-compose down
docker-compose up -d
docker exec docker-nodejs /bin/bash src/load_nodemon.sh
docker exec -d docker-nodejs nodemon src/nodeSocketServer.js