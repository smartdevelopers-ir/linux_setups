#!/bin/bash
if [[ ! "$1" ]] 
then
	 read -r username
else
	username="$1"
fi
expire_date=$(awk -v uname="$username" '$1 == uname {print $2}' /etc/acc-expire/users)
echo $expire_date
