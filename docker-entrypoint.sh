#!/bin/bash

echo "RUNNING service"

if [ -z "$SERVICE_MODE" ]
then
    echo "ERROR: Must specify a serving mode: [ http | task ]"
    exit -1
else
    if [ "$SERVICE_MODE" = "http" ]
    then
        echo "Running http server"
        # HTTP API
        python http_server/ingress.py --debug
    elif [ "$SERVICE_MODE" == "task" ]
    then
        echo "Running celery worker" 
        /usr/src/app/wait-for-it.sh $(echo $SERVICES_BROKER | cut -d'/' -f 3) --timeout=20 --strict -- echo " $SERVICES_BROKER (Service Broker) is up" || exit $?
        # MICRO SERVICE
        ## QUEUE NAME
        QUEUE=$(python -c "from celery_app.register import queue; exit(queue())" 2>&1)
        echo "Service set to $QUEUE"

        ## REGISTRATION
        python -c "from celery_app.register import register; register()" # || exit $?
        echo "Service registered"

        ## WORKER
        celery --app=celery_app.celeryapp worker --pool=solo -n punctuation_$SERVICE_NAME@%h --queues=$QUEUE -c $CONCURRENCY

        ## UNREGISTERING
        python -c "from celery_app.register import unregister; unregister()" || exit $?
        echo "Service unregistered"
    else
        echo "ERROR: Wrong serving command: $SERVICE_MODE"
        exit -1
    fi
fi
