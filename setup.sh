#! /bin/bash

docker compose build
docker compose up -d

sleep 20

docker compose exec engelsystem bin/migrate
