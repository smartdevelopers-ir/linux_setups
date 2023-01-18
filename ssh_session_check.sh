#! /bin/bash
RED='\033[0;31m'
NC='\033[0m' # No Color
#group session limit, To define more groups limit add [groupname]=limit_count to the GROUP_LIMITS array
declare -A GROUP_LIMITS
GROUP_LIMITS=([twologin]=2 [threelogin]=3)
#first arg search var second arg is array
contains(){
	search=$1
	shift
	arr=("$@")
	for i in ${arr[@]}
	do
		if [[ $i = $search ]]
		then
			true
			return
		fi
	done
	false
}
# 1st param is search member 2st param is array
find_member_count(){
	USR=$1
	shift
	ARR=("$@")
	count=0
	for i in ${ARR[@]}
	do
		if [[ $i = $USR ]]
		then
			((count=count+1))
		fi
		
	done
	echo $count
}
#first arg is user name
find_user_group(){
	local user_name=$1
	local groups=($(id -Gn $user_name))
	echo ${groups[@]}
}
#pass user_name to get login session count
#it return number of session allowed for user
#if there is no limit it returns -1
calculate_session_count(){
	user_name=$1
	
	user_groups=($(find_user_group $user_name))
	
	for user_group in ${user_groups[@]}
	do
		#For every groups that user contains it, find group limit
		if contains $user_group ${!GROUP_LIMITS[@]}
		then
			echo "${GROUP_LIMITS[$user_group]}"
			return
		fi
	done
	
	echo "-1"
	
}
#first arg is user_name
#second arg is extra session
#third arg is users key array
#returns deleted pid
kill_proc(){
	echo "killed $1"
}
PIDS_STRING=$(ps -C dropbear | grep dropbear | awk '{print $1}');
PID_ARRAY=($PIDS_STRING);
declare -A USERS
for i in ${PID_ARRAY[@]}
do
	TMP_USER=$(grep -a "\\[$i\\]" /var/log/auth.log | awk '/Password auth succeeded for/{print $10}')
	if [[ ! -z $TMP_USER ]]
	then
		#remove single cotation from user name and put to users array
		USERS["$i"]="${TMP_USER//[^a-zA-Z0-9_]/''}"
	fi
	
done
PIDS_STRING="${!USERS[*]}"
SORTED_PIDS=($(echo -e "${PIDS_STRING//' '/'\n'}" | sort -n))
#echo "SORTED_PIDS = " "${SORTED_PIDS[@]}"
for PID in ${SORTED_PIDS[@]}
do
	#echo "current pid = $PID"
	usr=${USERS[$PID]}
	user_count=$(find_member_count $usr ${USERS[@]})
	allowed_session=$(calculate_session_count $usr)
	echo "Session allowed for user $usr is : $allowed_session. $usr is logged in $user_count time(s)"
	if [[ $allowed_session -ge 0 ]]
	then
		let diff=$user_count-$allowed_session
		#there is more than allowed session
		if [[ $diff -gt 0 ]]
		then 
			echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] There is more than allowed session for $usr, killing session $PID ${NC}"
			kill $PID
			unset USERS[$PID]
		fi
	fi
	
done

