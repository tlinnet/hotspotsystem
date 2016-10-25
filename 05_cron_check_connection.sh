#!/bin/ash

# Get the external IP:
EXTIP=`wget http://ipinfo.io/ip -qO -`
SUCCESS=$?

if [ "$SUCCESS" == "0" ]; then
    echo "External connection returned IP: $EXTIP . And exit code: $SUCCESS"
    logger -t connection "External connection returned IP: $EXTIP . And exit code: $SUCCESS"
else
    echo "No external connection found! Returned IP was: $EXTIP . And exit code: $SUCCESS"
    echo "I will perform a 'reboot' now!!!"

    logger -t connection "No external connection found! Returned IP was: $EXTIP . And exit code: $SUCCESS"
    logger -t connection "I will perform a 'reboot' now!!!"

    # Reboot
    /sbin/reboot
fi