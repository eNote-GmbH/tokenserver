#!/bin/sh

cd $(dirname $0)
case "$1" in
    server)
        _SETTINGS_FILE=${TOKENSERVER_SETTINGS_FILE:-"/app/tokenserver/tests/test_sql.ini"}

        if [ ! -e $_SETTINGS_FILE ]; then
            echo "Could not find ini file: $_SETTINGS_FILE"
            exit 1
        fi

        echo "Starting gunicorn with config: $_SETTINGS_FILE"

        exec gunicorn \
            --paste "$_SETTINGS_FILE" \
            --bind ${HOST-127.0.0.1}:${PORT-8000}\
            --worker-class mozsvc.gunicorn_worker.MozSvcGeventWorker \
            --timeout ${TOKENSERVER_TIMEOUT-600} \
            --workers ${WEB_CONCURRENCY-1}\
            --graceful-timeout ${TOKENSERVER_GRACEFUL_TIMEOUT-660}\
            --max-requests ${TOKENSERVER_MAX_REQUESTS-5000}\
            --log-config "$_SETTINGS_FILE"
        ;;

    test_all)
        $0 test_flake8
        $0 test_nose
        ;;

    test_flake8)
        echo "test - flake8"
        flake8 tokenserver
        ;;

    test_nose)
        echo "test - nose"
        nosetests --verbose --nocapture tokenserver/tests
        ;;

    *)
        echo "Unknown CMD, $1"
        exit 1
        ;;
esac
