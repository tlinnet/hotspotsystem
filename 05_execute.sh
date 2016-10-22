#!/bin/bash

UPTIME=`uptime`
logger -t cronexe "Performing action at: $UPTIME"

# Get commands
OUT=06_execute.sh
rm -rf $OUT
wget https://raw.githubusercontent.com/tlinnet/hotspotsystem/master/$OUT

# See file commands
echo -e "Content of: $OUT\n"
CONTENT=`cat $OUT`
echo $CONTENT
logger -t cronexe "Cronexe script contains: $CONTENT"
source $OUT