#!/bin/bash
#The folder containing all 6 processes must be named "project1_executables" and be in the same directory as this script
#Interface and IP address must also be hardcoded per device

INTERFACE="ens192"
START=$(date +%s)
IP="192.168.195.222"
IFSID="."

cleanup() {
	echo
	echo "Script was run for $SECONDS_ELAPSED seconds."
	pkill ifstat
	for i in {1..6}
	do
		pkill "APM$i"
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
	SECONDS_ELAPSED=$(( $(date +%s) - START ))
	for pid in "${PIDS[@]}"
	do
		CPU=$(ps -p $pid -o%cpu=)
		MEM=$(ps -p $pid -o%mem=)

		#Found on StackOverflow, removes all leading spaces from the CPU and MEM outputs
		CPU=${CPU//[[:space:]]/}
		MEM=${MEM//[[:space:]]/}
		echo "$SECONDS_ELAPSED,$CPU,$MEM" >> "$pid"_metrics.csv
	done
}
# Create system metrics CSV file
echo "seconds_since_start,rx_rate,tx_rate,disk_writes,available_disk_capacity" > system_metrics.csv

#Output -> <seconds since script start>, <RX data rate>, <TX data rate>, <disk writes>, <available disk capacity>
collect_system_metrics() {
    SECONDS_ELAPSED=$(( $(date +%s) - START ))
    # RX + TX data rates
    if [ "$IFSID" = "." ]
    then
        ifstat -d1 "$INTERFACE" &
        IFSID=$!
    fi

    NETWORK=$(ifstat "$INTERFACE" | tail -1)
    RX_RATE=$(echo "$NETWORK" | awk '{print $6}')
    TX_RATE=$(echo "$NETWORK" | awk '{print $8}')
    # Disk writes
    DISK_WRITES=$(iostat -dk sda | awk '$1 == "sda" {print $4}')
    # Disk capacity
    DISK_CAPACITY=$(df -B1M / | awk '/\/$/ {print $4}')
    # Write metrics to CSV
    echo "$SECONDS_ELAPSED,$RX_RATE,$TX_RATE,$DISK_WRITES,$DISK_CAPACITY" >> system_metrics.csv
}

#Main
#Everything is being sent to terminal for debug, creating and adding to files is our last step
spawn_processes

for pid in "${PIDS[@]}"
do
	echo "seconds_since_start,%CPU,%memory" > "$pid"_metrics.csv
done
	
while true
do
    echo
    SECONDS_ELAPSED=$(( $(date +%s) - START ))
    echo "Seconds since start: $SECONDS_ELAPSED"

    collect_process_metrics
    collect_system_metrics

    sleep 5
done
