#! /usr/bin/env bash

(
  echo '[global]'
  echo 'server.socket_host: "0.0.0.0"'
  echo 'server.socket_port: 8080'
  echo 'server.thread_pool: 100'
  echo ''
  echo '[database]'
  echo 'uri: "mongodb://localhost:27017/girder"'
  echo 'replica_set: None'
  echo ''
  echo '[server]'
  echo 'mode: "development"'
) > girder/girder/conf/girder.local.cfg

(
  echo '[celery]'
  echo 'app_main=girder_worker'
  echo 'broker=mongodb://localhost/sumoBroker'
  echo ''
  echo '[girder_worker]'
  echo 'plugins_enabled=r,girder_io'
) > girder_worker/girder_worker/worker.local.cfg

source scripts/env

( cd girder ; npm install )

if [ '!' -d girder/plugins/osumo ] ; then
  girder-install plugin osumo
fi

if [ '!' -d "cache/girder-post-install" ] ; then
    mkdir -p "cache/girder-post-install"
    girder-server &
    girder_pid=$!
    sleep 5

    (
      echo "import json"
      echo "import os.path"
      echo ""
      echo "from girder.constants import AssetstoreType"
      echo "from girder_client import GirderClient"
      echo ""
      echo "def find_user(username):"
      echo "    result = None"
      echo "    offset = 0"
      echo "    while True:"
      echo "        users = client.get("
      echo "            'user',"
      echo "            parameters=dict("
      echo "                text=username,"
      echo "                limit=50,"
      echo "                offset=offset,"
      echo "                sort='login'"
      echo "            )"
      echo "        )"
      echo ""
      echo "        if not users: break"
      echo ""
      echo "        for user in users:"
      echo "            if user['login'] == username:"
      echo "                result = user"
      echo "                break"
      echo ""
      echo "        if result:"
      echo "            break"
      echo ""
      echo "        offset += 50"
      echo ""
      echo "    return result"
      echo ""
      echo "def ensure_user(client, **kwds):"
      echo "    username = kwds['login']"
      echo "    password = kwds['password']"
      echo ""
      echo "    user = find_user(username)"
      echo "    if user:"
      echo "        client.put("
      echo "            'user/{}'.format(user['_id']),"
      echo "            parameters=dict(email=kwds['email'],"
      echo "                            firstName=kwds['firstName'],"
      echo "                            lastName=kwds['lastName']))"
      echo ""
      echo "        client.put("
      echo "            'user/{}/password'.format(user['_id']),"
      echo "            parameters=dict(password=password))"
      echo "    else:"
      echo "        client.post('user', parameters=dict("
      echo "                                login=username,"
      echo "                                password=password,"
      echo "                                email=kwds['email'],"
      echo "                                firstName=kwds['firstName'],"
      echo "                                lastName=kwds['lastName']))"
      echo ""
      echo "client = GirderClient(host='localhost', port=8080)"
      echo ""
      echo "if find_user('girder'):"
      echo "    client.authenticate('girder', 'girder')"
      echo "    ensure_user(client,"
      echo "                login='girder',"
      echo "                password='girder',"
      echo "                email='girder@girder.girder',"
      echo "                firstName='girder',"
      echo "                lastName='girder')"
      echo ""
      echo "client.authenticate('girder', 'girder')"
      echo ""
      echo "client.put("
      echo "    'system/plugins',"
      echo "    parameters=dict(plugins=json.dumps(['jobs',"
      echo "                                        'worker',"
      echo "                                        'osumo']))"
      echo ")"
    ) | python

    sleep 5
    kill -s SIGTERM $girder_pid
    wait
    girder-server &
    girder_pid=$!
    sleep 5

    (
      echo "import json"
      echo "import os.path"
      echo ""
      echo "from girder.constants import AssetstoreType"
      echo "from girder_client import GirderClient"
      echo ""
      echo "def find_user(username):"
      echo "    result = None"
      echo "    offset = 0"
      echo "    while True:"
      echo "        users = client.get("
      echo "            'user',"
      echo "            parameters=dict("
      echo "                text=username,"
      echo "                limit=50,"
      echo "                offset=offset,"
      echo "                sort='login'"
      echo "            )"
      echo "        )"
      echo ""
      echo "        if not users: break"
      echo ""
      echo "        for user in users:"
      echo "            if user['login'] == username:"
      echo "                result = user"
      echo "                break"
      echo ""
      echo "        if result:"
      echo "            break"
      echo ""
      echo "        offset += 50"
      echo ""
      echo "    return result"
      echo ""
      echo "def ensure_user(client, **kwds):"
      echo "    username = kwds['login']"
      echo "    password = kwds['password']"
      echo ""
      echo "    user = find_user(username)"
      echo "    if user:"
      echo "        client.put("
      echo "            'user/{}'.format(user['_id']),"
      echo "            parameters=dict(email=kwds['email'],"
      echo "                            firstName=kwds['firstName'],"
      echo "                            lastName=kwds['lastName']))"
      echo ""
      echo "        client.put("
      echo "            'user/{}/password'.format(user['_id']),"
      echo "            parameters=dict(password=password))"
      echo "    else:"
      echo "        client.post('user', parameters=dict("
      echo "                                login=username,"
      echo "                                password=password,"
      echo "                                email=kwds['email'],"
      echo "                                firstName=kwds['firstName'],"
      echo "                                lastName=kwds['lastName']))"
      echo ""
      echo "client = GirderClient(host='localhost', port=8080)"
      echo ""
      echo "if find_user('girder'):"
      echo "    client.authenticate('girder', 'girder')"
      echo "    ensure_user(client,"
      echo "                login='girder',"
      echo "                password='girder',"
      echo "                email='girder@girder.girder',"
      echo "                firstName='girder',"
      echo "                lastName='girder')"
      echo ""
      echo "client.authenticate('girder', 'girder')"
      echo ""
      echo "client.put('system/setting',"
      echo "           parameters=dict(list=json.dumps(["
      echo "               dict(key='worker.broker',"
      echo "                    value='mongodb://localhost/sumoBroker'),"
      echo "               dict(key='worker.backend',"
      echo "                    value='mongodb://localhost/sumoBackend'),"
      echo "               dict(key='core.route_table',"
      echo "                    value=dict("
      echo "                        core_girder='/girder',"
      echo "                        core_static_root='/static',"
      echo "                        osumo='/'))])))"
    ) | python

    sleep 5
    kill -s SIGTERM $girder_pid
    wait
fi

girder-install web

