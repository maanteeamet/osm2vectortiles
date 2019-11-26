#!/bin/bash
set -e

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


#export AZURE_STORAGE_ACCOUNT=hsltiles
#export AZURE_STORAGE_ACCESS_KEY=

#export AZURE_STORAGE_ACCOUNT=hslstoragekarttatuotanto

export CONTAINER_NAME=tiles
export BLOB_NAME=tiles.mbtiles
export FILENAME=export/tiles.mbtiles
export PREVIOUS_EXPORT_FILENAME=export/prev/old_tiles.mbtiles
export MIN_SIZE=660000000


rm -f export/tiles.mbtiles
rm -f import/estonia-latest.osm.pbf
if [ -f $FILENAME ]; then
    mkdir -p export/prev
    mv -f $FILENAME $PREVIOUS_EXPORT_FILENAME
fi
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
    (echo >&2 "File not found, exiting")
    exit 1
fi

if [ $(wc -c <"$FILENAME") -lt $MIN_SIZE ]; then
    (echo >&2 "File size under minimum, exiting")
    exit 1
fi

if [ -z "$AZURE_BLOB_SAS_ACCESS_KEY" ]; then
    (echo >&2 "\$AZURE_BLOB_SAS_ACCESS_KEY is empty. Cannot upload mbtiles to Blob, exiting")
    exit 1
fi

#echo "Uploading..."
#az storage blob upload -f $FILENAME -c $CONTAINER_NAME -n $BLOB_NAME
#echo "Done"

#URL="https://"$AZURE_STORAGE_ACCOUNT".blob.core.windows.net/"$CONTAINER_NAME"/tiles.mbtiles"
#URL_WITH_SAS=$URL"?"$AZURE_BLOB_SAS_ACCESS_KEY
#echo "Uploading... to " $URL
#azcopy copy $FILENAME $URL_WITH_SAS
#echo "Done."
