#! /usr/bin/env bash

(
  echo '[global]'
  echo 'server.socket_host: "0.0.0.0"'
  echo 'server.socket_port: 25080'
  echo 'server.thread_pool: 100'
  echo ''
  echo '[database]'
  echo 'uri: "mongodb://localhost:25123/sumoGirderDev"'
  echo 'replica_set: None'
  echo ''
  echo '[server]'
  echo 'mode: "development"'
) > girder/girder/conf/girder.local.cfg

(
  echo '[celery]'
  echo 'app_main=girder_worker'
  echo 'broker=mongodb://localhost:25123/sumoBroker'
  echo ''
  echo '[girder_worker]'
  echo 'plugins_enabled=r,girder_io'
) > girder_worker/girder_worker/worker.local.cfg

source scripts/env

if [ '!' -d girder/plugins/osumo ] ; then
  girder-install plugin osumo
fi
girder-install web

if [ '!' -d "cache/girder-post-install" ] ; then
    mkdir -p "cache/girder-post-install"
    girder-server &
    girder_pid=$!
    sleep 5

    python scripts/dev/post-install-0.py
    sleep 5

    kill -s SIGTERM $girder_pid
    wait

    girder-install web
    sleep 5

    girder-server &
    girder_pid=$!
    sleep 5

    python scripts/dev/post-install-1.py
    sleep 5

    kill -s SIGTERM $girder_pid
    wait
fi

