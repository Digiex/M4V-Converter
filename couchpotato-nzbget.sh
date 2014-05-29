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

if [ "$NZBPP_PARSTATUS" -eq 1 ] || [ "$NZBPP_UNPACKSTATUS" -eq 1 ]; then
	exit 95
fi

curl -silent "http://$NZBPO_IP:$NZBPO_PORT/api/$NZBPO_KEY/renamer.scan" &>/dev/null
if [ $? -ne 0 ]; then
	echo "Failed to update CouchPotato, please check your settings."
else
	echo "Successfully notified CouchPotato to update."
fi
exit 93
