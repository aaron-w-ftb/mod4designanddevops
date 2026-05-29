#!/bin/bash

docker rm -f flask-app || true
docker rm -f nginx || true

docker network create silver-network || true

docker build -t flask-app .

docker build -t nginx-proxy ./nginx

docker run -d \
--name flask-app \
--network silver-network \
flask-app

docker run -d \
--name nginx \
--network silver-network \
-p 80:80 \
nginx-proxy
