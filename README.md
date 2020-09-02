# docker_tests
docker ile ilgili testleri barındırıyor


docker run --rm --privileged -i -t --memory="1g" --memory-swap="2g" --memory-reservation="750m" --cpus="1.0" --cpu-shares="700" -p "4999:5000" -v //d/shared/mediacontent:/app/mediacontent --name appserver_container appserver:1.0
