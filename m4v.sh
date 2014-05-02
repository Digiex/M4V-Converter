#!/bin/bash

#### EDIT THESE TO MATCH YOUR SETUP ####

movies=/mnt/NAS/Movies
series=/mnt/NAS/Series
ignored="$PWD/m4v.ignored"
pid=/var/run/m4v.pid
log=/var/log/m4v.log
tmp=/tmp

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

messages=true
debug=false
logs=true
delete=false
dirty=false
dualaudio=true

threads=2
language=eng
preset=fast
format=mp4
extension=m4v

#### DO NOT EDIT BEYOND THIS POINT ####

if [[ $(whoami) != "root" ]]; then
	echo "This script needs root permissions to run properly."
	exit 1
fi

if [ -f "$pid" ]; then
    read p < "$pid"
    if ps "$p" &>/dev/null; then
    	echo "This script is already running."
        exit 2
    fi
fi

echo $$ > "$pid"
trap 'rm -f "$pid"' EXIT

if [ ! -z "$(pgrep 'Plex New Transcoder')" ]; then
	echo "Plex is currently transcoding."
    exit 3
fi

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

function debug() {
	if $debug; then
		log "Debug: $1"
	fi
}

function ignore() {
	if [ ! -f "$ignored" ]; then
		touch "$ignored"
	fi
	echo "$1" >> "$ignored"
}

function main() {
	files="$(find $1 -type f)"
	while read file; do
		case "$file" in
			*.mkv | *.mp4 | *.avi) skip=false
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
				lsof "$file" | grep -q COMMAND &>/dev/null
				if [ $? -ne 0 ]; then
					dc="ffmpeg -threads $threads -i \"$file\""
					orig="${file%.*}"
					m4v="$orig.$extension"
					nm4v=$(basename "$m4v")
					tm4v="$tmp/$nm4v"
					if [ -f "$m4v" ]; then
						rm "$m4v"
					fi
					data=$(ffprobe "$file" 2>&1)
					v=$(echo "$data" | grep "Video:")
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
							vm="${vm%:*}"
						fi
						vc=$(echo "$v" | awk '{print($4)}')
						if [ "$vc" == "h264" ] || [ "$vc" == "x264" ]; then
							dc="$dc -map $vm -c:v copy"
						else
							dc="$dc -map $vm -c:v libx264 -preset $preset -profile:v baseline -level 3.0"
						fi
					fi
					xlx=$(echo "$language" | tr ',' '\n')
					a=$(echo "$data" | grep "Audio:")
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
										am="${am%:*}"
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
									am="${am%:*}"
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
								am="${am%:*}"
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
					fi
					s=$(echo "$data" | grep "Subtitle:")
					if [ ! -z "$s" ]; then
						ss=$(echo "s" | wc -l)
						if (( $ss > 1 )); then
							sg=
							while read xs; do
								if [[ "$language" != "*" ]]; then
									if [[ "$language" == *,* ]]; then
										for x in $xlx; do
											if [[ "$xs" =~ "$x" ]]; then
												if [ -z "$sg" ]; then
													sg="$xs"
												elif [[ ! "$sg" =~ "$x" ]]; then
													sg="$xs"$'\n'"$sg"
												fi
											fi
										done
									else
										if [[ "$xs" =~ "$language" ]]; then
											if [ -z "$sg" ]; then
												sg="$xs"
											elif [[ ! "$sg" =~ "$language" ]]; then
												sg="$xs"$'\n'"$sg"
											fi
										fi
									fi
								fi
							done <<< "$s"
							sgc=$(echo "$sg" | wc -l)
							if (( $sgc > 1 )); then
								while read xsg; do
									sm=$(echo "$xsg" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
									smc=${#sm}
									if (( $sm > 3 )); then
										sm="${sm%:*}"
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
							else
								sm=$(echo "$sg" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
								smc=${#sm}
								if (( $sm > 3 )); then
									sm="${sm%:*}"
								fi
								sc=$(echo "$sg" | awk '{print($4)}')
								if [[ "$sc" == *, ]]; then
									sc=${sc%?}
								fi
								if [ "$sc" == "mov_text" ]; then
									dc="$dc -map $sm -c:s:0 copy"
								else
									dc="$dc -map $sm -c:s:0 mov_text"
								fi
							fi
						else
							sm=$(echo "$s" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
							smc=$(echo "$sm" | wc -l)
							sg=
							if (( $smc > 1 )); then
								while read xss; do
									smm=$(echo "$s" | grep "Stream #$xss")
									if [[ "$language" != "*" ]]; then
										if [[ "$language" == *,* ]]; then
											for x in $xlx; do
												if [[ "$smm" =~ "$x" ]]; then
													if [ -z "$sg" ]; then
														sg="$smm"
													elif [[ ! "$sg" =~ "$x" ]]; then
														sg="$smm"$'\n'"$sg"
													fi
												fi
											done
										else
											if [[ "$smm" =~ "$language" ]]; then
												if [ -z "$sg" ]; then
													sg="$smm"
												elif [[ ! "$sg" =~ "$language" ]]; then
													sg="$smm"$'\n'"$sg"
												fi
											fi
										fi
									fi
								done <<< "$sm"
								sgc=$(echo "$sg" | wc -l)
								if (( $sgc > 1 )); then
									while read xsg; do
										sm=$(echo "$xsg" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
										smc=${#sm}
										if (( $smc > 3 )); then
											sm="${sm%:*}"
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
								else
									sm=$(echo "$sg" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
									smc=${#sm}
									if (( $smc > 3 )); then
										sm="${sm%:*}"
									fi
									sc=$(echo "$sg" | awk '{print($4)}')
									if [[ "$sc" == *, ]]; then
										sc=${sc%?}
									fi
									if [ "$sc" == "mov_text" ]; then
										dc="$dc -map $sm -c:s:0 copy"
									else
										dc="$dc -map $sm -c:s:0 mov_text"
									fi
								fi
							else
								if [[ "$language" != "*" ]]; then
									if [[ "$language" == *,* ]]; then
										for x in $xlx; do
											if [[ "$s" =~ "$x" ]]; then
												if [ -z "$sg" ]; then
													sg="$s"
												elif [[ ! "$sg" =~ "$x" ]]; then
													sg="$s"$'\n'"$sg"
												fi
											fi
										done
									else
										if [[ "$s" =~ "$language" ]]; then
											if [ -z "$sg" ]; then
												sg="$s"
											elif [[ ! "$sg" =~ "$language" ]]; then
												sg="$s"$'\n'"$sg"
											fi
										fi
									fi
								fi
								if [ ! -z "$sg" ]; then
									smc=${#sm}
									if (( $smc > 3 )); then
										sm="${sm%:*}"
									fi
									sc=$(echo "$s" | awk '{print($4)}')
									if [[ "$sc" == *, ]]; then
										sc=${sc%?}
									fi
									if [ "$sc" == "mov_text" ]; then
										dc="$dc -map $sm -c:s:0 copy"
									else
										dc="$dc -map $sm -c:s:0 mov_text"
									fi
								fi
							fi
						fi
					fi
					dc="$dc -f $format -movflags +faststart -strict experimental -y \"$tm4v\""
					log "Starting conversion..."
					result=$(eval "$dc" 2>&1)
					if [ $? -ne 0 ]; then
						log "Result: Failed."
						debug "$dc"
						debug "$result"
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
					log "File was in use, skipping..."
				fi
				;;
			*.jpg | *.nfo | *.txt | *sample*) if $dirty; then rm "$file"; fi;
				;;
			*) continue;
				;;
		esac
	done <<< "$files"

	if $update; then
		if $couch; then
			log "Updating CouchPotato..."
			curl -silent -f 'http://$cip:$cport/api/$capikey/manage.update' &>/dev/null
		fi
		if $sick; then
			log "Updating SickBeard..."
			shows=$(curl -silent -f 'http://$sip:$sport/api/$sapikey/?cmd=shows&sort=id');
			tvdb=$(echo "$shows" | sed '/tvdbid/!d' | sed s/\'tvdbid\'://g | sed s/\'//g | sed s/\ //g | sed s/,//g);
			echo "$tvdb" | tr ' ' '\n' | while read id; do curl -silent -f 'http://$sip:$sport/api/$sapikey/?cmd=show.refresh&tvdbid=$id' &>/dev/null; done;
		fi
	fi
}

log "Searching for files..."

main "$movies"
main "$series"

log "Finished."

exit 0
