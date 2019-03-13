#!/bin/bash
set -e

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#export AZURE_STORAGE_ACCOUNT=hsltiles
#export AZURE_STORAGE_ACCESS_KEY=

export CONTAINER_NAME=tiles
export BLOB_NAME=tiles.mbtiles
export FILENAME=export/tiles.mbtiles
export MIN_SIZE=660000000

rm -f export/tiles.mbtiles
rm -f import/estonia-latest.osm.pbf
curl -sSfL "http://download.geofabrik.de/europe/estonia-latest.osm.pbf" -o import/estonia-latest.osm.pbf

docker-compose stop
docker-compose rm -f

docker-compose up -d postgis

sleep 1m

docker-compose run import-external

docker-compose up import-osm

docker-compose run import-sql

docker-compose run -e BBOX="21.3144,57.4818,28.335,60.0013" -e MIN_ZOOM="0" -e MAX_ZOOM="14" export

#docker volume rm $(docker volume ls)
docker-compose down -v

if [ ! -f $FILENAME ]; then
    (>&2 echo "File not found, exiting")
    exit 1
fi

if [ $(wc -c <"$FILENAME") -lt $MIN_SIZE ]; then
    (>&2 echo "File size under minimum, exiting")
    exit 1
fi

#echo "Uploading..."
#az storage blob upload -f $FILENAME -c $CONTAINER_NAME -n $BLOB_NAME
#echo "Done"
