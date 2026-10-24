#!/bin/bash
#The folder containing all 6 processes must be named "project1_executables" and be in the same directory as this script
#Interface and IP address must also be hardcoded per device

INTERFACE="ens192"
START=$(date +%s)
IP="192.168.195.222"
IFSID="."
cleanup() {
	kill $IFSID
	for pid in "${PIDS[@]}"
	do
		kill $pid
	done
}
trap cleanup EXIT

spawn_processes() {
	PIDS=()

	for i in {1..6}
	do
		./project1_executables/APM$i "$IP" &
		PIDS+=($!)
	done
}

#Output -> <seconds since script start>, <%CPU>, <%memory>
collect_process_metrics() {
	for pid in "${PIDS[@]}"
	do
	    ps -p $pid -o %cpu=,%mem=
	done
}

#Output -> <seconds since script start>, <RX data rate>, <TX data rate>, <disk writes>, <available disk capacity>
collect_system_metrics() {
	#RX + TX data rates
	if [ $IFSID = "." ]
	then
		ifstat -d1 "$INTERFACE"
		IFSID=$!
	else
		ifstat "$INTERFACE" | grep "$INTERFACE" | awk '{print $6,$7,$8,$9}'
	fi

	#Disk writes
	iostat -dk sda | awk '$1 == "sda" {print $4}'

	#Disk capacity
	df -B1M / | awk '/\/$/ {print $4}'
}



#Main
#Everything is being sent to terminal for debug, creating and adding to files is our last step
spawn_processes

while true
do
    echo
    SECONDS_ELAPSED=$(( $(date +%s) - START ))
    echo "Seconds since start: $SECONDS_ELAPSED"

    collect_process_metrics
    echo
    collect_system_metrics

    sleep 5
done
