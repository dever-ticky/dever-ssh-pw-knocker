#!/bin/bash

if [ "$#" -ne 1 ]
then
    echo 'Usage: ./ssh-pw-knocker.sh /path/to/file'
    exit 1
fi

# remove commented lines from file and start reading it
grep -v '^#' $1 | while IFS= read -r LINE
do
    # validate "IP host" pattern
    REGEX_IP_HOST="\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b [^\s]+"

    if [[ $LINE =~ $REGEX_IP_HOST ]] ; then
        CURR_IP=$(echo "$LINE" | cut -d " " -f 1)
        CURR_MACHINE=$(echo "$LINE" | cut -d " " -f 2)

        # check to see if it's online firstly
        nc -z $CURR_MACHINE 22
        if [ $? == 0 ] ; then
            IS_ONLINE=true
        else
            IS_ONLINE=false
        fi

        # if online knock
        if ($IS_ONLINE) ; then
            ssh -v -n -o Batchmode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null DOES_NOT_EXIST@$CURR_MACHINE 2>&1 | grep password > /dev/null 2>&1
            if [ $? == 0 ] ; then
                echo "$CURR_IP $CURR_MACHINE - !! Password Authentication allowed !! Fix it !!"
            else
                echo "$CURR_IP $CURR_MACHINE - Password Authentication disabled"
            fi
        else
            echo "$CURR_IP $CURR_MACHINE - not online."
        fi
    fi
done

exit 0