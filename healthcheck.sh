#!/usr/bin/env bash

set -eax

if [ "$SERVICE_MODE" = "http" ]
then
    curl --fail http://localhost:80/healthcheck || exit 1
else
    celery --app=celery_app.celeryapp inspect ping -d punctuation_$LANGUAGE@$HOSTNAME || exit 1
fi
