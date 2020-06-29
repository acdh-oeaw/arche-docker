#!/bin/bash

# Database connection config
if [ ! -z "$PG_HOST" ]; then
    export PG_EXTERNAL=1
else
    PG_USER=www-data
    PG_DBNAME=www-data
fi
export PG_HOST=${PG_HOST:=127.0.0.1}
export PG_PORT=${PG_PORT:=5432}
export PG_USER=${PG_USER:=postgres}
export PG_DBNAME=${PG_DBNAME:=postgres}
export PG_CONN="-h $PG_HOST -p $PG_PORT -U $PG_USER $PG_DBNAME"

