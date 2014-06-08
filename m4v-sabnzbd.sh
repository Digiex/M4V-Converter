#!/bin/bash

##############################################################################
### SABNZBD POST-PROCESSING SCRIPT                                         ###

# M4V-Converter (LINUX & OS X)
#
# This script converts files via post process.
#
# NOTE: This script requires FFMPEG and FFPROBE.

### SABNZBD POST PROCESSING SCRIPT                                         ###
##############################################################################

#### EDIT THESE SETTINGS ####

# Number of threads (1-8).
# This is how many threads FFMPEG will use for conversion.
threads=2

# Preferred language.
# This is the language(s) you prefer.
#
# NOTE: This is used for audio and subtitles.
language=eng

# H264 Preset (ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow).
# This is the preset used for converting the video, if required.
#
# NOTE: Slower is more compressed.
preset=fast

# Create dual audio streams (true, false).
# This will create two audio streams, if possible. Typically AAC 2.0 and AC3 5.1.
#
# NOTE: AAC will be the default for better compatability with more devices.
dualaudio=true

# Ignore subtitles (true, false).
# This will ignore subtitles when converting. This is useful if you use Plex or such to download subtitles.
#
# NOTE: This does not apply to forced subtitles.
ignoresubs=false

# Ignore image based subtitles (true, false).
# This will ignore subtitles which are not text based and thus cannot be converted. If you choose not to enable this then any file which contains these image based subtitles will fail to convert.
#
# NOTE: If you enable this I'd suggest using some other source to acquire subtitles. Such as Plex + OpenSubtitles.
ignoresubimgformat=false

# File format (mp4, mov).
# MP4 is better supported universally. MOV is best for Apple devices and iTunes.
format=mp4

# File extension (m4v, mp4).
extension=m4v

# Delete original file (true, false).
delete=true

# CouchPotato
# Notify CouchPotato to scan for new files (true, false).
#
# NOTE: Requires category
couch=false
couchip=127.0.0.1
couchport=5050
couchapikey=1182f201774a420ea36ac39d740c4107
couchcategory=movies

# NzbDrone
# Notify NzbDrone to scan for new files (true, false).
#
# NOTE: Requires category
drone=false
droneip=127.0.0.1
droneport=8989
droneapikey=d33fbc0acd2146f2920098a57dcab923
dronecategory=series

#### DO NOT EDIT BEYOND THIS POINT ####

if [ "$7" -ne 0 ]; then
	exit 0
fi

if ! hash ffmpeg &>/dev/null; then
	echo "ERROR: FFMPEG is missing. (REQUIRED)"
	exit 1
fi

if ! hash ffprobe &>/dev/null; then
	echo "ERROR: FFPROBE is missing. (REQUIRED)"
	exit 1
fi

echo "Searching for files..."
files=$(find "$1" -type f)
while read file; do
	ext="${file##*.}"
	if [[ "$ext" == "$extension" ]]; then
		continue;
	fi
	case "$file" in
		*.mkv | *.mp4 | *.m4v | *.avi)
			echo "Found a file needing to be converted."
			echo "File: $file"
			lsof "$file" 2>&1 | grep -q COMMAND &>/dev/null
			if [ $? -ne 0 ]; then
				dc="ffmpeg -threads $threads -i \"$file\""
				orig="${file%.*}"
				m4v="$orig.$extension"
				tm4v="$m4v.tmp"
				data=$(ffprobe "$file" 2>&1)
				v=$(echo "$data" | grep "Stream" | grep "Video:")
				if [ ! -z "$v" ]; then
					vs=$(echo "$v" | wc -l)
					if (( $vs > 1 )); then
						echo "This file has multiple video streams. Skipping..."
						continue;
					fi
					vm=$(echo "$v" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
					vmc=${#vm}
					if (( $vmc > 3 )); then
						vm=${vm%:*}
					fi
					vc=$(echo "$v" | awk '{print($4)}')
					if [ "$vc" == "h264" ] || [ "$vc" == "x264" ]; then
						dc="$dc -map $vm -c:v copy"
					else
						dc="$dc -map $vm -c:v libx264 -preset $preset -profile:v baseline -level 3.0"
					fi
				else
					echo "The file was missing video. Skipping..."
					continue;
				fi
				xlx=$(echo "$language" | sed s/\ //g | tr ',' '\n')
				a=$(echo "$data" | grep "Stream" | grep "Audio:")
				if [ ! -z "$a" ]; then
					as=$(echo "$a" | wc -l)
					agi=
					if (( $as > 1 )); then
						ag=
						agc=0
						lan=false
						while read xa; do
							if [[ "$language" != "*" ]]; then
								if [[ "$language" == *,* ]]; then
									for x in $xlx; do
										if [[ "$xa" =~ "$x" ]]; then
											ao=$(ffprobe "$file" -show_streams -select_streams a:$agc 2>&1 | grep TAG:title= | sed s/TAG:title=//g | tr "A-Z" "a-z")
											if [[ "$ao" =~ "commentary" ]]; then
												continue;
											fi
											if [ -z "$ag" ]; then
												ag="$xa"
											else
												ag="$xa"$'\n'"$ag"
											fi
											lan=true
											lam=$(echo "$xa" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
											lac=${#lam}
											if (( $lac > 3 )); then
												lam="${lam%:*}"
											fi
											agi="$lam $agc"
										fi
									done
								else
									if [[ "$xa" =~ "$language" ]]; then
										ao=$(ffprobe "$file" -show_streams -select_streams a:$agc 2>&1 | grep TAG:title= | sed s/TAG:title=//g | tr "A-Z" "a-z")
										if [[ "$ao" =~ "commentary" ]]; then
											continue;
										fi
										if [ -z "$ag" ]; then
											ag="$xa"
										else
											ag="$xa"$'\n'"$ag"
										fi
										lan=true
										lam=$(echo "$xa" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
										lac=${#lam}
										if (( $lac > 3 )); then
											lam="${lam%:*}"
										fi
										agi="$lam $agc"
									fi
								fi
							fi
							agc=$(($agc+1));
						done <<< "$a"
						if ! $lan; then
							agc=0
							while read xa; do
								if [[ "$language" != "*" ]]; then
									if [[ "$language" == *,* ]]; then
										for x in $xlx; do
											if [[ "$xa" =~ "default" ]]; then
												if [ -z "$ag" ]; then
													ag="$xa"
												else
													ag="$ag"$'\n'"$xa"
												fi
												lam=$(echo "$xa" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
												lac=${#lam}
												if (( $lac > 3 )); then
													lam="${lam%:*}"
												fi
												agi="$lam $agc"
											fi
										done
									else
										if [[ "$xa" =~ "default" ]]; then
											if [ -z "$ag" ]; then
												ag="$xa"
											else
												ag="$ag"$'\n'"$xa"
											fi
											lam=$(echo "$xa" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
											lac=${#lam}
											if (( $lac > 3 )); then
												lam="${lam%:*}"
											fi
											agi="$lam $agc"
										fi
									fi
								fi
								agc=$(($agc+1));
							done <<< "$a"
						fi
						agc=$(echo "$ag" | wc -l)
						if (( $agc > 1 )); then
							acc=0
							while read xag; do
								if (( $acc > 1 )); then
									break;
								fi
								am=$(echo "$xag" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
								amc=${#am}
								if (( $amc > 3 )); then
									am=${am%:*}
								fi
								ac=$(echo "$xag" | awk '{print($4)}')
								if [[ "$ac" == *, ]]; then
									ac=${ac%?}
								fi
								ahc=0
								aic=$(echo "$agi" | wc -l)
								if (( "$aic" > 1 )); then
									while read i; do
										im=$(echo "i" | awk '{print($1)}') 
										if [ "$am" == "$im" ]; then
											ahc=$(echo "$i" | awk '{print($2)}')
										fi
									done <<< "$agi"
								else
									im=$(echo "$agi" | awk '{print($1)}') 
									if [ "$am" == "$im" ]; then
										ahc=$(echo "$agi" | awk '{print($2)}')
									fi
								fi
								ah=$(ffprobe "$file" -show_streams -select_streams a:$ahc 2>&1 | grep channels= | sed s/channels=//g)
								if $dualaudio; then
									if [ "$ac" == "ac3" ]; then
										if (( $acc == 0 )); then
											if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
												dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
											else
												dc="$dc -map $am -c:a:0 aac"
											fi
										elif (( $acc == 1 )); then
											dc="$dc -map $am -c:a:1 copy"
										fi
									elif [ "$ac" == "aac" ]; then
										if (( $acc == 0 )); then
											if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
												dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
											elif [[ "$ah" == "N/A" ]] || (( $ah == 2 )); then
												dc="$dc -map $am -c:a:0 copy"
											else
												dc="$dc -map $am -c:a:0 aac"
											fi
										elif (( $acc == 1 )); then
											dc="$dc -map $am -c:a:1 ac3"
										fi
									else
										if (( $acc == 0 )); then
											if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
												dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
											else
												dc="$dc -map $am -c:a:0 aac"
											fi
										elif (( $acc == 1 )); then
											dc="$dc -map $am -c:a:1 ac3"
										fi
									fi
								else
									if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
										dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
									else
										dc="$dc -map $am -c:a:0 aac"
									fi
									break;
								fi
								acc=$(($acc+1));
							done <<< "$ag"
						else
							am=$(echo "$ag" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
							amc=${#am}
							if (( $amc > 3 )); then
								am=${am%:*}
							fi
							ac=$(echo "$ag" | awk '{print($4)}')
							if [[ "$ac" == *, ]]; then
								ac=${ac%?}
							fi
							ahc=0
							aic=$(echo "$agi" | wc -l)
							if (( "$aic" > 1 )); then
								while read i; do
									im=$(echo "i" | awk '{print($1)}') 
									if [ "$am" == "$im" ]; then
										ahc=$(echo "$i" | awk '{print($2)}')
									fi
								done <<< "$agi"
							else
								im=$(echo "$agi" | awk '{print($1)}') 
								if [ "$am" == "$im" ]; then
									ahc=$(echo "$agi" | awk '{print($2)}')
								fi
							fi
							ah=$(ffprobe "$file" -show_streams -select_streams a:$ahc 2>&1 | grep channels= | sed s/channels=//g)
							if $dualaudio; then
								if [ "$ac" == "ac3" ]; then
									if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
										dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
										dc="$dc -map $am -c:a:1 copy"
									else
										dc="$dc -map $am -c:a:0 aac"
									fi
								elif [ "$ac" == "aac" ]; then
									if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
										dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
										dc="$dc -map $am -c:a:1 ac3"
									elif [[ "$ah" == "N/A" ]] || (( $ah == 2 )); then
										dc="$dc -map $am -c:a:0 copy"
									else
										dc="$dc -map $am -c:a:0 aac"
									fi
								else
									if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
										dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
										dc="$dc -map $am -c:a:1 ac3"
									else
										dc="$dc -map $am -c:a:0 aac"
									fi
								fi
							else
								if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
									dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
								else
									dc="$dc -map $am -c:a:0 aac"
								fi
							fi
						fi
					else
						am=$(echo "$a" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
						amc=${#am}
						if (( $amc > 3 )); then
							am=${am%:*}
						fi
						ac=$(echo "$a" | awk '{print($4)}')
						if [[ "$ac" == *, ]]; then
							ac=${ac%?}
						fi
						ah=$(ffprobe "$file" -show_streams -select_streams a:0 2>&1 | grep channels= | sed s/channels=//g)
						if $dualaudio; then
							if [ "$ac" == "ac3" ]; then
								if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
									dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
									dc="$dc -map $am -c:a:1 copy"
								else
									dc="$dc -map $am -c:a:0 aac"
								fi
							elif [ "$ac" == "aac" ]; then
								if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
									dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
									dc="$dc -map $am -c:a:1 ac3"
								elif [[ "$ah" == "N/A" ]] || (( $ah == 2 )); then
									dc="$dc -map $am -c:a:0 copy"
								else
									dc="$dc -map $am -c:a:0 aac"
								fi
							else
								if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
									dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
									dc="$dc -map $am -c:a:1 ac3"
								else
									dc="$dc -map $am -c:a:0 aac"
								fi
							fi
						else
							if [[ "$ah" == "N/A" ]] || (( $ah > 2 )); then
								dc="$dc -map $am -c:a:0 aac -ac:a:0 2 -ab:a:0 256k"
							else
								dc="$dc -map $am -c:a:0 aac"
							fi
						fi
					fi
				else
					echo "The file was missing audio. Skipping..."
					continue;
				fi
				s=$(echo "$data" | grep "Stream" | grep "Subtitle:")
				if [ ! -z "$s" ]; then
					sg=
					while read xs; do
						if $ignoresubimgformat; then
							if [[ "$xs" =~ "hdmv_pgs_subtitle" ]]; then
								continue;
							fi
						fi
						if [[ "$language" != "*" ]]; then
							for x in $xlx; do
								rx=${x:0:3}
								if [[ "$xs" =~ "$rx" ]]; then
									if [ -z "$sg" ]; then
										if $ignoresubs; then
											if [[ "$xs" =~ "forced" ]]; then
												sg="$xs"
											fi
										else
											sg="$xs"
										fi
									elif [[ ! "$sg" =~ "$rx" ]]; then
										if $ignoresubs; then
											if [[ "$xs" =~ "forced" ]]; then
												sg="$xs"$'\n'"$sg"
											fi
										else
											sg="$xs"$'\n'"$sg"
										fi
									fi
								fi
							done
						else
							if [ -z "$sg" ]; then
								if $ignoresubs; then
									if [[ "$xs" =~ "forced" ]]; then
										sg="$xs"
									fi
								else
									sg="$xs"
								fi
							elif [[ ! "$sg" =~ "$rx" ]]; then
								if $ignoresubs; then
									if [[ "$xs" =~ "forced" ]]; then
										sg="$xs"$'\n'"$sg"
									fi
								else
									sg="$xs"$'\n'"$sg"
								fi
							fi
						fi
					done <<< "$s"
					if [ ! -z "$sg" ]; then
						while read xsg; do
							sm=$(echo "$xsg" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
							smc=${#sm}
							if (( $smc > 3 )); then
								sm=${sm%:*}
							fi
							sc=$(echo "$xsg" | awk '{print($4)}')
							if [[ "$sc" == *, ]]; then
								sc=${sc%?}
							fi
							if [ "$sc" == "mov_text" ]; then
								dc="$dc -map $sm -c:s:0 copy"
							else
								dc="$dc -map $sm -c:s:0 mov_text"
							fi
						done <<< "$sg"
					fi
				fi
				if [[ "$dc" =~ "-c:s" ]]; then
					dc=$(echo "$dc" | sed s/-i/-fix_sub_duration\ -i/g)
				fi
				dc="$dc -f $format -movflags +faststart -strict experimental -y \"$tm4v\""
				echo "Starting conversion..."
				echo "$dc" | xargs -0 bash -c &>/dev/null
				if [ $? -ne 0 ]; then
					echo "Result: Failed."
					if [ -f "$tm4v" ]; then
						echo "Cleaning up..."
						rm "$tm4v"
					fi
					continue;
				fi
				echo "Result: Success."
				user=$(ls -l "$file" | awk '{print $3}')
				group=$(ls -l "$file" | awk '{print $4}')
				if [[ "$OSTYPE" == "linux-gnu" ]]; then
					perms=$(stat -c %a "$file")
				elif [[ "$OSTYPE" == "darwin"* ]]; then
					perms=$(stat -f %Lp "$file")
				fi
				chown $user:$group "$tm4v"
				chmod $perms "$tm4v"
				touch -r "$file" "$tm4v"
				echo "Cleaning up..."
				if $delete; then
					rm "$file"
				fi
				mv "$tm4v" "$m4v"
			else
				echo "File was in use. Skipping..."
			fi
			;;
		*) continue;
			;;
	esac
done <<< "$files"

if [ ! -z "$5" ]; then
	if $couch; then
		if [ "$5" == "$couchcategory" ]; then
			curl -silent "http://$couchip:$couchport/api/$couchapikey/renamer.scan" &>/dev/null
			if [ $? -ne 0 ]; then
				echo "Failed to update CouchPotato, please check your settings."
			else
				echo "Successfully notified CouchPotato to update."
			fi
		fi
	fi
	if $drone; then
		if [ "$5" == "$dronecategory" ]; then
			curl -silent "http://$droneip:$droneport/api/command" -X POST -d '{"name": "downloadedepisodesscan"}' --header "X-Api-Key:$droneapikey" &>/dev/null
			if [ $? -ne 0 ]; then
				echo "Failed to update NzbDrone, please check your settings."
			else
				echo "Successfully notified NzbDrone to update."
			fi
		fi
	fi
fi

echo "Finished!"
exit 0