#!/bin/bash

##############################################################################
### NZBGET POST-PROCESSING SCRIPT                                          ###

# M4V-Converter (LINUX & OS X)
#
# This script converts files via post process.
#
# NOTE: This script requires FFMPEG and FFPROBE.

##############################################################################
### OPTIONS                                                                ###

# Number of threads (1-8).
# This is how many threads FFMPEG will use for conversion.
#Threads=2

# Preferred language.
# This is the language(s) you prefer.
#
# NOTE: This is used for audio and subtitles.
#Language=eng

# H264 Preset (ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow).
# This is the preset used for converting the video, if required.
#
# NOTE: Slower is more compressed.
#Preset=fast

# Create dual audio streams (yes, no).
# This will create two audio streams, if possible. Typically AAC 2.0 and AC3 5.1.
#
# NOTE: AAC will be the default for better compatability with more devices.
#DualAudio=yes

# Ignore subtitles (yes, no).
# This will ignore subtitles when converting. It is also useful if you use Plex or such to download subtitles automatically.
#
# NOTE: This does not apply to forced subtitles.
#Subtitles=yes

# File format (MP4, MOV).
# MP4 is better supported universally. MOV is best for Apple devices and iTunes.
#Format=mp4

# File extension (M4V, MP4).
#Extension=m4v

# Delete original file (yes, no).
#Delete=yes

### NZBGET POST-PROCESSING SCRIPT                                          ###
##############################################################################

POSTPROCESS_SUCCESS=93
POSTPROCESS_ERROR=94
POSTPROCESS_NONE=95

if [ "$NZBPP_PARSTATUS" -eq 1 ] || [ "$NZBPP_UNPACKSTATUS" -eq 1 ]; then
	exit $POSTPROCESS_NONE
fi

log "Searching for files..."
files=$(find "$NZBPP_DIRECTORY" -type f)
while read file; do
	ext="${file##*.}"
	if [[ "$ext" == "$NZBPO_EXTENSION" ]]; then
		continue;
	fi
	case "$file" in
		*.mkv | *.mp4 | *.m4v | *.avi)
			log "Found a file needing to be converted."
			log "File: $file"
			lsof "$file" | grep -q COMMAND &>/dev/null
			if [ $? -ne 0 ]; then
				dc="ffmpeg -threads $NZBPO_THREADS -i \"$file\""
				orig="${file%.*}"
				m4v="$orig.$NZBPO_EXTENSION"
				tm4v="$m4v.tmp"
				data=$(ffprobe "$file" 2>&1)
				v=$(echo "$data" | grep "Video:")
				if [ ! -z "$v" ]; then
					vs=$(echo "$v" | wc -l)
					if (( $vs > 1 )); then
						log "This file has multiple video streams. Skipping..."
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
						dc="$dc -map $vm -c:v libx264 -preset $NZBPO_PRESET -profile:v baseline -level 3.0"
					fi
				else
					log "The file was missing video. Skipping..."
					continue;
				fi
				xlx=$(echo "$NZBPO_LANGUAGE" | tr ',' '\n')
				a=$(echo "$data" | grep "Audio:")
				if [ ! -z "$a" ]; then
					as=$(echo "$a" | wc -l)
					agi=
					if (( $as > 1 )); then
						ag=
						agc=0
						lan=false
						while read xa; do
							if [[ "$NZBPO_LANGUAGE" != "*" ]]; then
								if [[ "$NZBPO_LANGUAGE" == *,* ]]; then
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
									if [[ "$xa" =~ "$NZBPO_LANGUAGE" ]]; then
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
								if [[ "$NZBPO_LANGUAGE" != "*" ]]; then
									if [[ "$NZBPO_LANGUAGE" == *,* ]]; then
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
								if $NZBPO_DUALAUDIO; then
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
							if $NZBPO_DUALAUDIO; then
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
						if $NZBPO_DUALAUDIO; then
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
					log "The file was missing audio. Skipping..."
					continue;
				fi
				s=$(echo "$data" | grep "Subtitle:")
				if [ ! -z "$s" ]; then
					ss=$(echo "$s" | wc -l)
					sg=
					if (( $ss > 1 )); then
						while read xs; do
							if [[ "$NZBPO_LANGUAGE" != "*" ]]; then
								if [[ "$NZBPO_LANGUAGE" == *,* ]]; then
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
									if [[ "$xs" =~ "$NZBPO_LANGUAGE" ]]; then
										if [ -z "$sg" ]; then
											sg="$xs"
										elif [[ ! "$sg" =~ "$NZBPO_LANGUAGE" ]]; then
											sg="$xs"$'\n'"$sg"
										fi
									fi
								fi
							fi
						done <<< "$s"
						if [ ! -z "$sg" ]; then
							sgc=$(echo "$sg" | wc -l)
							if (( $sgc > 1 )); then
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
							else
								sm=$(echo "$sg" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
								smc=${#sm}
								if (( $smc > 3 )); then
									sm=${sm%:*}
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
						fi
					else
						sm=$(echo "$s" | awk '{print($2)}' | sed s/#//g | sed s/\(.*//g)
						smc=$(echo "$sm" | wc -l)
						if [[ "$NZBPO_LANGUAGE" != "*" ]]; then
							if [[ "$NZBPO_LANGUAGE" == *,* ]]; then
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
								if [[ "$s" =~ "$NZBPO_LANGUAGE" ]]; then
									if [ -z "$sg" ]; then
										sg="$s"
									elif [[ ! "$sg" =~ "$NZBPO_LANGUAGE" ]]; then
										sg="$s"$'\n'"$sg"
									fi
								fi
							fi
						fi
						if [ ! -z "$sg" ]; then
							smc=${#sm}
							if (( $smc > 3 )); then
								sm=${sm%:*}
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
				if [[ "$dc" =~ "-c:s" ]]; then
					dc=$(echo "$dc" | sed s/-i/-fix_sub_duration\ -i/g)
				fi
				dc="$dc -f $NZBPO_FORMAT -movflags +faststart -strict experimental -y \"$tm4v\""
				log "Starting conversion..."
				echo "$dc" | xargs -0 bash -c &>/dev/null
				if [ $? -ne 0 ]; then
					log "Result: Failed."
					if [ -f "$tm4v" ]; then
						log "Cleaning up..."
						rm "$tm4v"
					fi
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
				if $NZBPO_DELETE; then
					rm "$file"
				fi
				mv "$tm4v" "$m4v"
			else
				log "File was in use. Skipping..."
			fi
			;;
		*) continue;
			;;
	esac
done <<< "$files"

echo "Finished!"
exit $POSTPROCESS_SUCCESS