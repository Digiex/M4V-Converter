#!/bin/bash

##############################################################################
### SABNZBD POST-PROCESSING SCRIPT                                          ###

# Notifies CouchPotato to scan for new files.

### SABNZBD POST-PROCESSING SCRIPT                                          ###
##############################################################################

#### EDIT THESE SETTINGS ####

ip=127.0.0.1
port=5050
apikey=1182f201774a420ea36ac39d740c4107

#### DO NOT EDIT BEYOND THIS POINT ####

if [ "$7" -eq 1 ] || [ "$7" -eq 2 ]; then
	exit 1
fi

curl -silent "http://$ip:$port/api/$apikey/renamer.scan" &>/dev/null
if [ $? -ne 0 ]; then
	echo "Failed to update CouchPotato, please check your settings."
else
	echo "Successfully notified CouchPotato to update."
fi
exit 0
