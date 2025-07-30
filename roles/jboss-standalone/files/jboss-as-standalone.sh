#!/bin/bash
#
# JBoss standalone startup script for Ubuntu (Init.d style)
# chkconfig: 2345 80 20
# description: JBoss Application Server
# processname: jboss-as
# pidfile: /var/run/jboss-as/jboss-as.pid

### BEGIN INIT INFO
# Provides:          jboss-as
# Required-Start:    $local_fs $remote_fs $network $named $time $syslog
# Required-Stop:     $local_fs $remote_fs $network $named $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start JBoss AS in standalone mode
### END INIT INFO

# Source function library
. /lib/lsb/init-functions

JBOSS_USER=jboss
JBOSS_HOME=/opt/jboss
JBOSS_PIDFILE=/var/run/jboss-as/jboss-as.pid
JBOSS_CONSOLE_LOG=/var/log/jboss-as/console.log
JBOSS_CONFIG=standalone.xml
JBOSS_SCRIPT=$JBOSS_HOME/bin/standalone.sh
STARTUP_WAIT=30
SHUTDOWN_WAIT=30

start() {
    echo "Starting JBoss AS..."
    if [ -f $JBOSS_PIDFILE ]; then
        PID=$(cat $JBOSS_PIDFILE)
        if [ -d /proc/$PID ]; then
            echo "JBoss is already running (pid: $PID)"
            return 1
        fi
    fi

    mkdir -p $(dirname $JBOSS_PIDFILE)
    mkdir -p $(dirname $JBOSS_CONSOLE_LOG)
    chown -R $JBOSS_USER: $(dirname $JBOSS_PIDFILE)
    chown -R $JBOSS_USER: $(dirname $JBOSS_CONSOLE_LOG)

    su - $JBOSS_USER -c "LAUNCH_JBOSS_IN_BACKGROUND=1 JBOSS_PIDFILE=$JBOSS_PIDFILE $JBOSS_SCRIPT -c $JBOSS_CONFIG > $JBOSS_CONSOLE_LOG 2>&1 &"

    echo -n "Waiting for JBoss to start "
    i=0
    while [ $i -lt $STARTUP_WAIT ]; do
        grep 'JBoss.*started in' $JBOSS_CONSOLE_LOG > /dev/null
        if [ $? -eq 0 ]; then
            echo "JBoss started successfully."
            return 0
        fi
        echo -n "."
        sleep 1
        i=$((i+1))
    done
    echo "Failed to start JBoss within $STARTUP_WAIT seconds."
    return 1
}

stop() {
    echo "Stopping JBoss AS..."
    if [ ! -f $JBOSS_PIDFILE ]; then
        echo "PID file not found. Is JBoss running?"
        return 1
    fi

    PID=$(cat $JBOSS_PIDFILE)
    kill $PID

    echo -n "Waiting for JBoss to stop "
    i=0
    while [ -d /proc/$PID ]; do
        if [ $i -ge $SHUTDOWN_WAIT ]; then
            echo "Timeout: killing process."
            kill -9 $PID
        fi
        echo -n "."
        sleep 1
        i=$((i+1))
    done
    echo "JBoss stopped."
    rm -f $JBOSS_PIDFILE
    return 0
}

status() {
    if [ -f $JBOSS_PIDFILE ]; then
        PID=$(cat $JBOSS_PIDFILE)
        if [ -d /proc/$PID ]; then
            echo "JBoss is running (pid: $PID)"
            return 0
        else
            echo "JBoss PID file found but process not running"
            return 1
        fi
    else
        echo "JBoss is not running"
        return 3
    fi
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  status)
    status
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|status|restart}"
    exit 1
    ;;
esac
