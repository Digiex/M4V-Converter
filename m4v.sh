#!/usr/local/bin/bash

#### EDIT THESE TO MATCH YOUR SETUP ####

movies=/Volumes/NAS/Movies
series=/Volumes/NAS/Series
ignored=./m4v.ignored
pid=/tmp/m4v.pid

#--CouchPotato--#
couch=true
cip=10.0.1.3
cport=5050
capikey=1182f201774a420ea36ac39d740c4107
#--CouchPotato--#

#--SickBeard--#
sick=true
sip=10.0.1.3
sport=8081
sapikey=767c23d9c22029b2048519d97d65162d
#--SickBeard--#

threads=2
dirty=true
debug=false
messages=true

#### DO NOT EDIT BEYOND THIS POINT ####

if [ -f $pid ]; then
    read p < $pid
    if ps "$p" &>/dev/null; then
        exit 1
    fi
fi

echo $$ > $pid
trap "rm -f $pid" EXIT

if [ ! -z "$(pgrep 'Plex New Transcoder')" ]; then
	sendMessage "Plex is currently transcoding. Exiting."
    exit 2
fi

cm=0
cmf=0
cs=0
csf=0

function sendMessage() {
	if $messages; then
		echo $1
	fi
}

function process() {
	upc=false
	ups=false
	if (( $1 == 1 )); then
		sendMessage "Searching for Movies..."
	elif (( $1 == 2 )); then
		sendMessage "Searching for Series..."
	fi
	shopt -s globstar
	for f in "$2"/**; do
		if [ -f "$f" ]; then
			case "$f" in
				*.mkv | *.mp4 | *.avi)	if [ -f $ignored ]; then
						skip=false
						while read ignore; do 
							if [[ "$ignore" == *"$f"* ]]; then
								skip=true
								break;
							fi
						done <<<$ignored
						if $skip; then
							continue;
						fi
					fi
					lsof "$f" | grep -q COMMAND &>/dev/null
					if [ $? -ne 0 ]; then
						sendMessage "Found a file needing to be converted."
						sendMessage "File: $f"
						orig=${f%.*}
						m4v=$orig".m4v"
						if [ -f "$m4v" ]; then
							rm "$m4v"
						fi
						vc=$(ffprobe "$f" 2>&1 | grep "Video:")
						vcount=$(echo "$vc" | wc -l)
						vstream="$vc"
						if (( $vcount > 1 )); then
							sendMessage "This file has multiple video streams. Ignoring..."
							if [ ! -f $ignored ]; then
								touch $ignored
							fi
							echo "$f" >> $ignored
							continue;
						fi
						v=$(echo "$vstream" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
						cv=${#v}
						if (( $cv > 3 )); then
							v="${v%:*}"
						fi
						ac=$(ffprobe "$f" 2>&1 | grep "Audio:")
						acount=$(echo "$ac" | wc -l)
						astream="$ac"
						if (( $acount > 1 )); then
							sendMessage "This file has multiple audio streams. Searching for an English stream..."
							english=false
							while read as; do
								if [[ "$as" == *eng* ]]; then
									astream="$as"
									english=true
									break;
								fi
							done <<<"$ac"
							if $english; then
								sendMessage "Found an English stream! Proceeding..."
							else
								sendMessage "Was unable to find an English stream. Proceeding with the files default stream..."
								default=false
								while read as; do
									if [[ "$as" == *default* ]]; then
										astream="$as"
										default=true
										break;
									fi
								done <<<"$ac"
								if ! $default; then
									sendMessage "Cannot find an english or default audio stream. Ignoring..."
									if [ ! -f $ignored ]; then
										touch $ignored
									fi
									echo "$f" >> $ignored
								fi
							fi
						fi
						a=$(echo "$astream" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
						ca=${#a}
						if (( $ca > 3 )); then
							a="${a%:*}"
						fi
						sendMessage "Starting conversion..."
						result=$(ffmpeg -threads $threads -i "$f" -map $v -map $a -c:v copy -c:a:0 aac -ac:a:0 2 -b:a:0 512k -strict experimental -f mov -movflags faststart -y "$m4v" 2>&1)
						if [ $? -ne 0 ]; then
							if (( $1 == 1 )); then
								cmf=$(($cmf + 1));
							elif (( $1 == 2 )); then
								csf=$(($csf + 1));
							fi
							sendMessage "Result: Failed."
							if $messages && $debug; then
								sendMessage "Debug: ffmpeg -threads $threads -i $f -map $v -map $a -c:v copy -c:a:0 aac -ac:a:0 2 -b:a:0 512k -strict experimental -f mov -movflags faststart -y $m4v"
								echo -e "Debug:\n$result"
							fi
							if [ -f "$m4v" ]; then
								sendMessage "Cleaning up..."
								rm "$m4v"
							fi
							sendMessage "Adding file to ignore list..."
							if [ ! -f $ignored ]; then
								touch $ignored
							fi
							echo "$f" >> $ignored
							continue;
						fi
						if (( $1 == 1 )); then
							cm=$(($cm + 1));
							if $couch; then
								upc=true;
							fi
						elif (( $1 == 2 )); then
							cs=$(($cs + 1));
							if $sick; then
								ups=true;
							fi
						fi
						sendMessage "Result: Success."
						sendMessage "Cleaning up..."
						rm "$f"
					fi
					;;
				*.srt | *.idx | *.sub) if $dirty; then rm "$f"; fi;
					;;
				*) continue;
					;;
			esac
		fi
	done

	if $upc; then
		sendMessage "Updating CouchPotato..."
    	curl -silent -f "http://$cip:$cport/api/$capikey/manage.update" &>/dev/null
	fi

	if $ups; then
		sendMessage "Updating SickBeard..."
    	shows=$(curl -silent -f "http://$sip:$sport/api/$sapikey/?cmd=shows&sort=id");
    	tvdb=$(echo "$shows" | sed '/tvdbid/!d' | sed s/\"tvdbid\"://g | sed s/\"//g | sed s/\ //g | sed s/,//g);
    	echo "$tvdb" | tr ' ' '\n' | while read id; do curl -silent -f "http://$sip:$sport/api/$sapikey/?cmd=show.refresh&tvdbid=$id" &>/dev/null; done;
    fi
}

process 1 "$movies" &
process 2 "$series" &
wait

if (( $cm > 0 )) || (( $cs > 0 )) || (( $cmf > 0 )) || (( $csf > 0 )); then
	sendMessage "Finished. Results: Movies, $cm succeeded and $smf failed. Series, $cs succeeded and $csf failed."
else
	sendMessage "Finished. There was nothing found that needed to be converted."
fi

exit 0