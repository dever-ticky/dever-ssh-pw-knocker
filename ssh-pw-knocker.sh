#!/bin/bash

REGEX_IP_HOST="\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b[[:blank:]]+[^[:blank:]]+"

# knock and check password authentication is allowed
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
                echo "$IP $MACHINE - !! password authentication allowed !! Fix it !!"
            else
                echo "$IP $MACHINE - password authentication disabled"
            fi
        else
            echo "$IP $MACHINE - SSH standard port not open"
        fi
    else
        echo "$IP $MACHINE - offline"
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
if [ ! -r $1 ] ; then
    echo "File $1 not readable"
    exit 2
fi

# remove commented lines from file and start reading it
grep -v '^#' $1 | while IFS= read -r LINE
do
    # validate "IP host" pattern and knock
    if [[ $LINE =~ $REGEX_IP_HOST ]] ; then
        CURR_IP=$(echo "$LINE" | sed 's/\t/ /g' | cut -d " " -f 1)
        CURR_MACHINE=$(echo "$LINE" | sed 's/\t/ /g' | cut -d " " -f 2)
        # knock
        knock_ssh_pw "$CURR_IP" "$CURR_MACHINE" &
    else
        echo "Ignore invalid line - $LINE"
    fi
done

wait

exit 0