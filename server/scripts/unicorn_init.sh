#!/bin/sh
set -e

TIMEOUT=${TIMEOUT-60}
APP_ROOT=/caishuo/web/current
PID=$APP_ROOT/tmp/pids/unicorn.pid
CMD="unicorn_rails -E production -D -c $APP_ROOT/config/unicorn.rb"
action="$1"
set -u

cd $APP_ROOT || exit 1

sig () {
	test -s "$PID" && kill -$1 `cat $PID`
}

case $action in
	start)
		sig 0 && echo >&2 "Already running" && exit 0
		$CMD
		;;
	stop)
		sig QUIT && echo stoped OK && exit 0
		echo >&2 "Not running"
		;;
	force-stop)
		sig TERM && exit 0
		echo >&2 "Not running"
		;;
	restart|reload)
		sig USR2 && echo reloaded OK && exit 0
		echo >&2 "Couldn't reload, starting '$CMD' instead"
		$CMD
		;;
	reopen-logs)
		sig USR1
		;;
	*)
		echo >&2 "Usage: $0 <start|stop|restart|force-stop|reopen-logs>"
		exit 1
		;;
esac
