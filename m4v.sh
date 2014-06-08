#!/bin/bash

#### EDIT THESE TO MATCH YOUR SETUP ####

movies=/mnt/NAS/Movies
series=/mnt/NAS/Series
ignored=./m4v.ignored
pid=/var/run/m4v.pid
log=/var/log/m4v.log

#--CouchPotato--#
couch=false
cip=127.0.0.1
cport=5050
capikey=1182f201774a420ea36ac39d740c4107
#--CouchPotato--#

#--SickBeard--#
sick=false
sip=127.0.0.1
sport=8081
sapikey=767c23d9c22029b2048519d97d65162d
#--SickBeard--#

#--NzbDrone--#
drone=false
dip=127.0.0.1
dport=8989
dapikey=d33fbc0acd2146f2920098a57dcab923
#--NzbDrone--#

# Messages (true, false).
# Outputs any message to the console
#
# NOTE: Disable this if on OS X and using this script via crontab.
messages=true

# Logs (true, false).
# Creates log files.
logs=true

# Create dual audio streams (true, false).
# This will create two audio streams, if possible. Typically AAC 2.0 and AC3 5.1.
#
# NOTE: AAC will be the default for better compatability with more devices.
dualaudio=true

# Dry run (true, false).
# This will output the command it will issue to ffmpeg without touching anything. Useful for testing and debugging.
dryrun=true

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

# File format (mp4, mov).
# MP4 is better supported universally. MOV is best for Apple devices and iTunes.
format=mp4

# File extension (m4v, mp4).
extension=m4v

# Delete original file (true, false).
delete=false

#### DO NOT EDIT BEYOND THIS POINT ####

if [[ $(whoami) != "root" ]]; then
	echo "This script needs root permissions to run properly."
	exit 1
fi

if (( $# == 0 )); then
	if [ ! -d "$movies" ]; then
		echo "Invalid: $movies"
		echo "Please check script settings."
		exit 2
	fi
	if [[ "$movies" == */ ]]; then
		movies="${movies%?}"
	fi

	if [ ! -d "$series" ]; then
		echo "Invalid: $series"
		echo "Please check script settings."
		exit 2
	fi
	if [[ "$series" == */ ]]; then
		series="${series%?}"
	fi
fi

if [ "$ignored" != "$PWD/m4v.ignored" ]; then
	if [ ! -d $(dirname "$ignored") ]; then
		echo "Invalid: $ignored"
		echo "Please check script settings."
		exit 2
	fi
fi

if [ ! -d $(dirname "$pid") ]; then
	echo "Invalid: $pid"
	echo "Please check script settings."
	exit 2
fi

if [ ! -d $(dirname "$log") ]; then
	echo "Invalid: $log"
	echo "Please check script settings."
	exit 2
fi

if [ -f "$pid" ]; then
    read p < "$pid"
    if ps "$p" &>/dev/null; then
    	echo "This script is already running."
        exit 3
    fi
fi

if [ ! -z $(pgrep 'Plex New Transcoder') ]; then
	echo "Plex is currently transcoding."
    exit 4
fi

if ! hash ffmpeg &>/dev/null; then
	echo "ERROR: FFMPEG is missing. (REQUIRED)"
	exit 5
fi

if ! hash ffprobe &>/dev/null; then
	echo "ERROR: FFPROBE is missing. (REQUIRED)"
	exit 5
fi

echo $$ > "$pid"
trap 'rm -f "$pid"' EXIT

function log() {
	if $messages; then
		echo "$1"
	fi
	if $logs; then
		if [ ! -f "$log" ]; then
			touch "$log"
		fi
		echo "$1" >> "$log"
	fi
}

function ignore() {
	if [ ! -f "$ignored" ]; then
		touch "$ignored"
	fi
	echo "$1" >> "$ignored"
}

function main() {
	update=false
	log "Searching for files..."
	files=$(find "$1" -type f)
	while read file; do
		ext="${file##*.}"
		if [[ "$ext" == "$extension" ]]; then
			continue;
		fi
		case "$file" in
			*.mkv | *.mp4 | *.m4v | *.avi) skip=false
				if [ -f "$ignored" ]; then
					while read ignore; do 
						if [[ "$ignore" == *"$file"* ]]; then
							skip=true
							break;
						fi
					done < "$ignored"
					if $skip; then
						continue;
					fi
				fi
				log "Found a file needing to be converted."
				log "File: $file"
				lsof "$file" 2>&1 | grep -q COMMAND &>/dev/null
				if [ $? -ne 0 ]; then
					dc="ffmpeg -threads $threads -i \"$file\""
					orig="${file%.*}"
					m4v="$orig.$extension"
					tm4v="$m4v.tmp"
					if ! $dryrun && [ -f "$m4v" ]; then
						rm "$m4v"
					fi
					if ! $dryrun && [ -f "$tm4v" ]; then
						rm "$tm4v"
					fi
					data=$(ffprobe "$file" 2>&1)
					v=$(echo "$data" | grep "Stream" | grep "Video:")
					if [ ! -z "$v" ]; then
						vs=$(echo "$v" | wc -l)
						if (( $vs > 1 )); then
							log "This file has multiple video streams. Ignoring..."
							ignore "$file"
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
						log "The file was missing video. Ignoring..."
						ignore "$file"
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
						log "The file was missing audio. Ignoring..."
						ignore "$file"
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
					if $dryrun; then
						echo "Dry Run: $dc"
						continue;
					fi
					log "Starting conversion..."
					echo "$dc" | xargs -0 bash -c &>/dev/null
					if [ $? -ne 0 ]; then
						log "Result: Failed."
						if [ -f "$tm4v" ]; then
							log "Cleaning up..."
							rm "$tm4v"
						fi
						log "Adding file to ignore list..."
						ignore "$file"
						continue;
					fi
					log "Result: Success."
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
					log "Cleaning up..."
					if $delete; then
						rm "$file"
					else
						ignore "$file"
					fi
					mv "$tm4v" "$m4v"
					update=true
				else
					log "File was in use. Skipping..."
				fi
				;;
			*) continue;
				;;
		esac
	done <<< "$files"

	if $update; then
		if $couch; then
			if [ "$movies" == "$1" ]; then
				log "Updating CouchPotato..."
				curl -silent -f "http://$cip:$cport/api/$capikey/manage.update" &>/dev/null
			fi
		fi
		if $sick; then
			if [ "$series" == "$1" ]; then
				log "Updating SickBeard..."
				shows=$(curl -silent -f "http://$sip:$sport/api/$sapikey/?cmd=shows&sort=id");
				tvdb=$(echo "$shows" | sed '/tvdbid/!d' | sed s/\'tvdbid\'://g | sed s/\'//g | sed s/\ //g | sed s/,//g | tr ' ' '\n');
				while read id; do curl -silent -f "http://$sip:$sport/api/$sapikey/?cmd=show.refresh&tvdbid=$id" &>/dev/null; done <<< "$tvdb";
			fi
		fi
		if $drone; then
			if [ "$series" == "$1" ]; then
				log "Updating NzbDrone..."
				curl -silent -f "http://$dip:$dport/api/command" -X POST -d '{"name": "RescanSeries"}' --header "X-Api-Key:$dapikey" &>/dev/null
			fi
		fi
	fi
}

if (( $# > 0 )); then
	for p in "$@"; do
		if [ -d "$p" ]; then
			if [[ "$p" == */ ]]; then
				p="${p%?}"
			fi
			main "$p"
		else
			log "Directory $p does not exist."
		fi
	done
else
	if [[ "$movies" != "$series" ]]; then
		main "$movies"
		main "$series"
	else
		main "$movies"
	fi
fi

log "Finished!"

exit 0