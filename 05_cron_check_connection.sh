#!/bin/ash

# Get the external IP:
EXTIP=`wget http://ipinfo.io/ip -qO -`
SUCCESS=$?

if [ "$SUCCESS" == "0" ]; then
    echo "External connection returned IP: $EXTIP . And exit code: $SUCCESS"
    logger -t connection "External connection returned IP: $EXTIP . And exit code: $SUCCESS"


    # Check if it should reboot
    # "10#$H" is the contents of the variable, in base 10.
    H=$(date +%H)
    if (( 8 <= 10#$H && 10#$H < 13 )); then
        echo between 8AM and 1PM
    elif (( 13 <= 10#$H && 10#$H < 23 )); then
        echo between 1PM and 11PM
    else
        echo go to bed
    fi

else
    echo "No external connection found! Returned IP was: $EXTIP . And exit code: $SUCCESS"
    echo "I will perform a 'reboot' now!!!"

    logger -t connection "No external connection found! Returned IP was: $EXTIP . And exit code: $SUCCESS"
    logger -t connection "I will perform a 'reboot' now!!!"

    # Reboot
    /bin/sleep 3
    /sbin/reboot
fi
