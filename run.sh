#!/bin/bash

# hack: call mariadb entrypoint to run db init and db
/docker-entrypoint.sh mysqld &
MYPID=$!

# wait for db to initialise
sleep $WAIT_FOR_DB_INIT

/usr/local/tomcat/bin/catalina.sh run &
TOMPID=$!

trap "{ kill -TERM $TOMPID; wait $TOMPID; kill -TERM $MYPID; wait; }" SIGTERM SIGINT
trap "{ kill -KILL $TOMPID; wait $TOMPID; kill -KILL $MYPID; wait; }" SIGKILL


wait
