#!/bin/bash

# required commands used in this bash script
REQUIRED_COMMANDS="ping nc ssh grep sed cut cat"

# regex to validate "IP hostname" e.g. "192.168.1.224 desktop-pc"
REGEX_IP_HOST="\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b[[:blank:]]+[^[:blank:]]+"

# temporary file to echo stuff into and along the way and cat at the end
TMPFILE=$(mktemp /tmp/ssh-pw-knocker-script.XXXXXXXXXX)

# pids list used for wating forked processes
PIDS=()

# knock and check if password authentication is allowed
knock_ssh_pw () {
    IP=$1
    MACHINE=$2
    # firstly check to see if it's online
    ping -i 0.2 -c 1 -W 1 $IP > /dev/null 2>&1
    if [ $? == 0 ] ; then
        # secondly check to see if ssh is open on standard port
        nc -z $IP 22
        if [ $? == 0 ] ; then
            # if ssh open knock
            ssh -v -n -o Batchmode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null DOES_NOT_EXIST@$IP 2>&1 | grep password > /dev/null 2>&1
            if [ $? == 0 ] ; then
                echo "$IP $MACHINE - !! password authentication allowed !! Fix it !!" >> $TMPFILE
            else
                echo "$IP $MACHINE - password authentication disabled" >> $TMPFILE
            fi
        else
            echo "$IP $MACHINE - SSH standard port not open" >> $TMPFILE
        fi
    else
        echo "$IP $MACHINE - offline" >> $TMPFILE
    fi
    exit 0
}

# usage
if [ "$#" -ne 1 ] ; then
    echo "Usage: ./ssh-pw-knocker.sh /path/to/file"
    echo "E.g. usage: ./ssh-pw-knocker.sh /etc/hosts"
    exit 1
fi

# check to see if file is accessible
if [ ! -r "$1" ] ; then
    echo "File $1 not readable"
    exit 2
else
    INPUT_FILE="$1"
fi

# check if required tools are installed (ping, nc, ssh)
for COMMAND in $REQUIRED_COMMANDS
do
    if ! command -v $COMMAND > /dev/null 2>&1 ; then
        echo "$COMMAND is not installed, but the script uses it"
        echo "Please install $COMMAND"
        echo "The required commands are: $REQUIRED_COMMANDS"
        exit 3
    fi
done

# read input file
while IFS= read -r LINE
do
    # validate "IP host" pattern and knock
    if [[ $LINE =~ $REGEX_IP_HOST ]] ; then
        CURR_IP=$(echo "$LINE" | sed 's/\t/ /g' | cut -d " " -f 1)
        CURR_MACHINE=$(echo "$LINE" | sed 's/\t/ /g' | cut -d " " -f 2)
        # knock
        knock_ssh_pw "$CURR_IP" "$CURR_MACHINE" &
        PIDS[${#PIDS[@]}]="$!"
    else
        echo "Ignore invalid line - $LINE"
    fi
done<"$INPUT_FILE"

# wait for all subprocesses to finish
for PID in "${PIDS[@]}"
do
    wait $PID
done

# cat and remove the temporary file
cat "$TMPFILE"
rm "$TMPFILE"

exit 0