#!/bin/bash

UPTIME=`uptime`
logger -t cronexe "Performing action at: $UPTIME"

# Get commands
IN=wget_execute_script.sh
OUT=wget_script.sh
rm -rf $OUT
wget https://raw.githubusercontent.com/tlinnet/hotspotsystem/master/$IN  -O $OUT

# See file commands
CONTENT=`cat $OUT`
echo "Cronexe script contains:"
echo "$CONTENT"

logger -t cronexe "Cronexe script contains:"
logger -t cronexe "$CONTENT"

# Execute
source $OUT