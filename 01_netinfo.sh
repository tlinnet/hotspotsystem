#!/bin/bash

echo "The command 'info' can be a help for seeing info of the system"
info() {
    echo -e "\nCommand: 'logread'"
    logread

    echo -e "\nCommand: 'ifconfig'"
    ifconfig

    echo -e "\nCommand: 'netstat -nr'"
    netstat -nr

    echo -e "\nShow external IP"
    echo -e "Command: 'wget http://ipinfo.io/ip -qO -'"
    wget http://ipinfo.io/ip -qO -
}

# Perform
info

