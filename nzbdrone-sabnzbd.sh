#!/bin/bash

##############################################################################
### NZBGET POST-PROCESSING SCRIPT                                          ###

# Notifies NzbDrone to scan for new files.

### NZBGET POST-PROCESSING SCRIPT                                          ###
##############################################################################

#### EDIT THESE SETTINGS ####

ip=127.0.0.1
port=8989
apikey=d33fbc0acd2146f2920098a57dcab923

#### DO NOT EDIT BEYOND THIS POINT ####

if [ "$7" -eq 1 ] || [ "$7" -eq 2 ]; then
	exit 1
fi

curl -silent "http://$ip:$port/api/command" -X POST -d '{"name": "downloadedepisodesscan"}' --header "X-Api-Key:$apikey" &>/dev/null
if [ $? -ne 0 ]; then
	echo "Failed to update NzbDrone, please check your settings."
else
	echo "Successfully notified NzbDrone to update."
fi
exit 93
