#!/bin/bash
set -e

echo "RUNNING service"
#supervisord -c /usr/src/app/supervisor/supervisor.conf

if [ -z "$SERVICE_MODE" ]
then
    echo "ERROR: Must specify a serving mode: [ http | task ]"
    exit -1
else
    torchserve --start --ncs --ts-config /usr/src/app/config.properties
    if [ "$SERVICE_MODE" = "http" ]
    then
        echo "Running http server"
        python http_server/ingress.py --debug
    elif [ "$SERVICE_MODE" == "task" ]
    then
        echo "Running celery worker" 
        /usr/src/app/wait-for-it.sh $(echo $SERVICES_BROKER | cut -d'/' -f 3) --timeout=20 --strict -- echo " $SERVICES_BROKER (Service Broker) is up"
        celery --app=celery_app.celeryapp worker -n punctuation_$LANGUAGE@%h --queues=punctuation_$LANGUAGE -c $CONCURRENCY
    else
        echo "ERROR: Wrong serving command: $SERVICE_MODE"
        exit -1
    fi
    torchserve --stop
fi
