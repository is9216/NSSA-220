#!/bin/bash

INTERFACE="ens33"
START=$(date +%s)

spawn_processes() {
    sleep 100000 &
    PROCESS_PID=$!
}

collect_process_metrics() {
    ps -p "$PROCESS_PID" -o %cpu=,%mem=
}

collect_system_metrics() {
    ifstat -i "$INTERFACE" 1 2
}


while true
do
    SECONDS_ELAPSED=(((date +%s) - START))

    echo "Seconds since start: $SECONDS_ELAPSED"

    collect_process_metrics
    collect_system_metrics

    sleep 5
done
