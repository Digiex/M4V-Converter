#!/bin/bash

##############################################################################
### NZBGET POST-PROCESSING SCRIPT                                          ###

# Notifies NzbDrone to scan for new files.

##############################################################################
### OPTIONS                                                                ###

#IP=127.0.0.1
#Port=8989
#Key=d33fbc0acd2146f2920098a57dcab923

### NZBGET POST-PROCESSING SCRIPT                                          ###
##############################################################################

if [ "$NZBPP_PARSTATUS" -eq 1 ] || [ "$NZBPP_UNPACKSTATUS" -eq 1 ]; then
	exit 95
fi

curl -silent "http://$NZBPO_IP:$NZBPO_PORT/api/command" -X POST -d '{"name": "downloadedepisodesscan"}' --header "X-Api-Key:$NZBPO_KEY" &>/dev/null
if [ $? -ne 0 ]; then
	echo "Failed to update NzbDrone, please check your settings."
else
	echo "Successfully notified NzbDrone to update."
fi
exit 93
