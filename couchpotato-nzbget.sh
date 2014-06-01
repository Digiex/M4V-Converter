#!/bin/bash

##############################################################################
### NZBGET POST-PROCESSING SCRIPT                                          ###

# Notifies CouchPotato to scan for new files.

##############################################################################
### OPTIONS                                                                ###

#IP=127.0.0.1
#Port=5050
#Key=1182f201774a420ea36ac39d740c4107

### NZBGET POST-PROCESSING SCRIPT                                          ###
##############################################################################

POSTPROCESS_SUCCESS=93
POSTPROCESS_ERROR=94
POSTPROCESS_NONE=95

if [ "$NZBPP_TOTALSTATUS" != "SUCCESS" ]; then
	exit $POSTPROCESS_NONE
fi

if [ "$NZBPP_SCRIPTSTATUS" != "SUCCESS" ]; then
	exit $POSTPROCESS_NONE
fi

curl -silent "http://$NZBPO_IP:$NZBPO_PORT/api/$NZBPO_KEY/renamer.scan" &>/dev/null
if [ $? -ne 0 ]; then
	echo "Failed to update CouchPotato, please check your settings."
else
	echo "Successfully notified CouchPotato to update."
fi
exit $POSTPROCESS_SUCCESS