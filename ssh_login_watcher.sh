#!/bin/bash
while inotifywait -e modify /var/log/auth.log
do
	if tail -n1 /var/log/auth.log | grep dropbear | grep "Password auth succeeded for"
	then
		bash /usr/local/bin/ssh_session_check.sh
	fi
done
