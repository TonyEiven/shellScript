#!/bin/bash
### BEGIN INIT INFO
# Provides:          node_exporter
# Required-Start:    $all
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start the node_exporter process
### END INIT INFO

# Command-line options that can be set in /data/node_exporter/.  These will override
# any config file values.
DEFAULT=/data/node_exporter

# Process name ( For display )
NAME=node_exporter

# Configuration file
CONFIG=/data/node_exporter

# Max open files
OPEN_FILE_LIMIT=65536

# PID file for the daemon
PIDFILE=/data/node_exporter/node_exporter.pid
PIDDIR=`dirname $PIDFILE`
if [ ! -d "$PIDDIR" ]; then
    mkdir -p $PIDDIR
    chown $USER:$GROUP $PIDDIR
fi

function log_failure_msg() {
    echo "$@" "[ FAILED ]"
}

function log_success_msg() {
    echo "$@" "[ OK ]"
}

function start() {
    # Check if config file exist
    if [ ! -r $CONFIG ]; then
        log_failure_msg "config file $CONFIG doesn't exist (or you don't have permission to view)"
        exit 4
    fi

    # Check that the PID file exists, and check the actual status of process
    if [ -f $PIDFILE ]; then
	PID="$(cat $PIDFILE)"
	if kill -0 "$PID" &>/dev/null; then
        	# Process is already up
        	log_success_msg "$NAME process is already running"
        	return 0
	fi
    else
        touch $PIDFILE &>/dev/null
        if [ $? -ne 0 ]; then
            log_failure_msg "$PIDFILE not writable, check permissions"
            exit 5
        fi
    fi

    # Bump the file limits, before launching the daemon. These will
    # carry over to launched processes.
    ulimit -n $OPEN_FILE_LIMIT
    if [ $? -ne 0 ]; then
        log_failure_msg "Unable to set ulimit to $OPEN_FILE_LIMIT"
        exit 1
    fi

    # Launch process
    echo "Starting $NAME..."
    if [ -x $DEFAULT/$NAME ]; then
            $DEFAULT/$NAME \
			--collector.buddyinfo \
			--collector.drbd \
			--collector.interrupts \
			--collector.ksmd \
			--collector.meminfo_numa \
			--collector.mountstats \
			--collector.ntp \
			--collector.qdisc \
			--collector.tcpstat \
            --log.level=debug >> $DEFAULT/node_exporter.log 2>&1 &
    fi
    # Write PID to PIDFILE
	sleep 10
    result=$(pgrep -f node_exporter)
    if [[ $result != "" ]];then
	echo $result > $PIDFILE
    fi
    # Sleep to verify process is still up
    sleep 1
    if [ -f $PIDFILE ]; then
        # PIDFILE exists
        if kill -0 $(cat $PIDFILE) &>/dev/null; then
            # PID up, service running
            log_success_msg "$NAME process was started"
            return 0
        fi
    fi
    log_failure_msg "$NAME process was unable to start"
    exit 1
}

function stop() {
    # Stop the daemon.
    if [ -f $PIDFILE ]; then
	local PID="$(cat $PIDFILE)"
        if kill -0 $PID &>/dev/null; then
            echo "Stopping $NAME..."
            # Process still up, send SIGTERM
            kill -s TERM $PID &>/dev/null
            n=0
            while true; do
                # Enter loop to ensure process is stopped
                kill -0 $PID &>/dev/null
                if [ "$?" != "0" ]; then
                    # Process stopped, break from loop
                    log_success_msg "$NAME process was stopped"
                    return 0
                fi

                # Process still up after signal, sleep and wait
                sleep 1
                n=$(expr $n + 1)
                if [ $n -eq 30 ]; then
                    # After 30 seconds, send SIGKILL
                    echo "Timeout exceeded, sending SIGKILL..."
                    kill -s KILL $PID &>/dev/null
                elif [ $? -eq 40 ]; then
                    # After 40 seconds, error out
                    log_failure_msg "could not stop $NAME process"
                    exit 1
                fi
            done
        fi
    fi
    log_success_msg "$NAME process already stopped"
}

function restart() {
    # Restart the daemon.
    stop
    start
}

function status() {
    # Check the status of the process.
    if [ -f $PIDFILE ]; then
        PID="$(cat $PIDFILE)"
        if kill -0 $PID &>/dev/null; then
            log_success_msg "$NAME process is running"
            exit 0
        fi
    fi
    log_failure_msg "$NAME process is not running"
    exit 1
}

case $1 in
    start)
        start
        ;;

    stop)
        stop
        ;;

    restart)
        restart
        ;;

    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 2
        ;;
esac
