#!/bin/bash

UPTIME=`uptime`
logger -t cronexe "Performing action at: $UPTIME"

# Get commands
IN=06_execute.sh
OUT=06_commands.sh
rm -rf $OUT
wget https://raw.githubusercontent.com/tlinnet/hotspotsystem/master/$IN  -O $OUT

# See file commands
echo -e "Content of: $OUT\n"
CONTENT=`cat $OUT`
echo $CONTENT
logger -t cronexe "Cronexe script contains:\n $CONTENT"
source $OUT