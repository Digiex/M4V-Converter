#!/bin/bash

##############################################################################
### NZBGET POST-PROCESSING SCRIPT                                          ###

# M4V-Converter (LINUX & OS X)
#
# This script converts files on post process.
#
# NOTE: This script requires FFMPEG, FFPROBE and Bash 4+.

##############################################################################
### OPTIONS                                                                ###

# Verbose Mode (true, false).
# Prints extra details, useful for debugging.
#Verbose=false

# Test Mode (true, false).
# When enabled this script does nothing.
#Test=false

# Number of Threads (1-8).
# This is how many threads FFMPEG will use for conversion.
#Threads=auto

# H264 Preset (ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow).
# This is the preset used for converting the video, if required.
#
# NOTE: Slower is more compressed and has better quality but takes more time.
#Preset=medium

# Constant Rate Factor (0-51).
# This controls compression efficiency.
#
# NOTE: Refer to the Wiki for help. https://trac.ffmpeg.org/wiki/Encode/H.264 .
#CRF=23

# Video Bitrate (KB).
# Use this to limit video bitrate, if it exceeds this limit then video will be converted.
#Video Bitrate=

# Preferred Languages.
# This is the language(s) you prefer.
#
# English (eng), French (fre), German (ger), Italian (ita), Spanish (spa), * (all).
#
# NOTE: This is used for audio and subtitles. The first listed is considered the default.
#Languages=

# Create Dual Audio Streams (true, false).
# This will create two audio streams, if possible. AAC 2.0 and AC3 5.1.
#
# NOTE: AAC will be the default for better compatability with more devices.
#Dual Audio=false

# Normalize Audio (true, false).
# This will normalize audio if needed due to downmixing 5.1 to 2.0.
#Normalize=true

# Copy Subtitles (true, false).
# This will copy/convert subtitles of your matching language(s) into the converted file.
#
# NOTE: Disable if you use Plex or such to download subtitles. This does NOT apply to forced subtitles. 
#Subtitles=true

# File Format (MP4, MOV).
# MP4 is better supported universally. MOV is best for Apple devices and iTunes.
#Format=mp4

# File Extension (MP4, M4V).
# The extension applied at the end of the file, such as video.mp4.
#Extension=m4v

# Delete Original File (true, false).
# If true then the original file will be deleted. Otherwise it saves both original and converted files.
#Delete=false

# Mark Bad (true, false).
# This will mark the download as bad if something goes wrong.
#
# NOTE: Helps to prevent fake releases.
#Bad=true

# Delete Samples (NONE, NAME, SIZE, BOTH).
# This will delete sample files.
#  NONE - disabled.
#  NAME - deletes samples based on name.
#  SIZE - deletes samples based on size, configure below.
#  BOTH - does both name & size.
#Samples=none

# Sample Size (MB).
# Any size less than the specified size is considered a sample.
#Sample Size=

# Cleanup Files.
# This will delete extra files with the above file extensions.
#Cleanup=.nfo, .nzb

### NZBGET POST-PROCESSING SCRIPT                                          ###
##############################################################################

TMPFILES=()

force() {
	if [[ ! -z ${PID} ]] && (( PID > 0 )) && [[ -e /proc/${PID} ]]; then
		disown "${PID}"
		kill -9 "${PID}" &>/dev/null
	fi
	exit 1
}

onexit() {
	for file in "${TMPFILES[@]}"; do
		if [[ -e "${file}" ]]; then
			rm "${file}"
		fi
	done
	return 0
}

trap force SIGINT
trap onexit EXIT

usage() {
	cat <<-EOF
	USAGE: ${0} parameters

	A script designed to convert media.

	NOTE: This script requires FFMPEG, FFPROBE and BASH 4+

	OPTIONS:
	-h            Show this message
	-v            Verbose Mode
	-t            Test Mode
	-p            Process file or directory

	--help           Same as -h
	--process        Same as -p

	ADVANCED OPTIONS:
	--verbose
	--test
	--threads
	--preset
	--crf
	--videobitrate
	--languages
	--dualaudio
	--subtitles
	--format
	--extension
	--delete
	--size
	--samples

	EXAMPLE: ${0} -v -p ~/video.mkv
	EOF
    exit 1
}

process() {
	case "${1}" in
		*.mkv | *.mp4 | *.m4v | *.avi | *.wmv | *.xvid | *.divx | *.mpg | *.mpeg)
			echo "Processing file: ${1}"
			lsof "${1}" 2>&1 | grep -q COMMAND &>/dev/null
			if [[ ${?} -ne 0 ]]; then
				local command="ffmpeg -threads ${CONF_THREADS} -i \"${1}\""
				local newfile="${1//${1##*.}/${CONF_EXTENSION,,}}"
				local tmpfile="${newfile}.tmp"
				TMPFILES+=("${tmpfile}")

				local data v a
				data="$(ffprobe "${1}" 2>&1)"
				
				v="$(echo "${data}" | grep 'Video:' | sed 's/\ \ \ \ \ //g')"
				if [[ -z "${v}" ]]; then
					echo "File is missing video."
					return 1
				fi

				local video=()
				readarray -t video <<< "${v}"
				for ((i = 0; i < ${#video[@]}; i++)); do
					if [[ -z "${video[${i}]}" ]]; then
						continue
					fi
					local convert=false videodata videomap videocodec videobitrate
					videodata=$(ffprobe "${1}" -show_streams -select_streams v:${i} 2>&1)
					if [[ $(echo "${videodata}" | grep -i "TAG:mimetype=" | tr '[:upper:]' '[:lower:]' | sed 's/tag:mimetype=//g') == "image/jpeg" ]]; then
						continue
					fi
					videomap=$(echo "${video[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
					if (( ${#videomap} > 3 )); then
						videomap=${videomap%:*}
					fi
					videocodec=$(echo "${video[${i}]}" | awk '{print($4)}')
					if [[ "${videocodec}" != "h264" ]]; then
						convert=true
					fi
					videolevel=$(echo "${videodata}" | grep -i "LEVEL=" | tr '[:upper:]' '[:lower:]' | sed 's/level=//g')
					if (( videolevel > 30 )); then
						convert=true
					fi
					videobitrate=$(echo "${videodata}" | grep -i "BIT_RATE=" | tr '[:upper:]' '[:lower:]' | sed 's/bit_rate=//g' | sed 's/[^0-9]*//g')
					videobitrate=$(( ${videobitrate:-0} / 1024 ))
					if (( CONF_VIDEOBITRATE > 0 )) && (( videobitrate > CONF_VIDEOBITRATE )); then
						convert=true
					fi
					if ${convert}; then
						command+=" -map ${videomap} -c:v:${i} libx264 -crf ${CONF_CRF} -preset ${CONF_PRESET} -profile:v baseline -level 3.0"
						if (( CONF_VIDEOBITRATE > 0 )); then
							command+=" -maxrate ${CONF_VIDEOBITRATE}k -bufsize ${CONF_VIDEOBITRATE}k"
						fi
						if ${CONF_VERBOSE}; then
							local fps dur hrs min sec total vstatsfile
							fps=$(echo "${data}" | sed -n "s/.*, \(.*\) tbr.*/\1/p")
    						dur=$(echo "${data}" | sed -n "s/.* Duration: \([^,]*\), .*/\1/p")
    						hrs=$(echo "${dur}" | cut -d":" -f1)
    						min=$(echo "${dur}" | cut -d":" -f2)
    						sec=$(echo "${dur}" | cut -d":" -f3)
    						total=$(echo "(${hrs}*3600+${min}*60+${sec})*${fps}" | bc | cut -d"." -f1)
    						if (( total > 0 )); then
    							vstatsfile="${1}.vstats"
    							TMPFILES+=("${vstatsfile}")
    							command="${command//-threads ${CONF_THREADS}/-threads ${CONF_THREADS} -vstats_file \"${vstatsfile}\"}"
    						fi
						fi
					else
						command+=" -map ${videomap} -c:v:${i} copy"
					fi
					if [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
						local videolang
						videolang=$(echo "${videodata}" | grep -i "TAG:LANGUAGE=" | tr '[:upper:]' '[:lower:]' | sed 's/tag:language=//g')
						if [[ -z "${videolang}" ]] || [[ "${videolang}" == "und" ]] || [[ "${videolang}" == "unk" ]]; then
							command+=" -metadata:s:v:${i} language=${CONF_DEFAULTLANGUAGE}"
						fi
					fi
				done

				a="$(echo "${data}" | grep 'Audio:' | sed 's/\ \ \ \ \ //g')"
				if [[ -z "${a}" ]]; then
					echo "File is missing audio."
					return 1
				fi

				local boost=false audio=() audiostreams=()
				local -A dualaudio=()
				readarray -t audio <<< "${a}"
				for ((i = 0; i < ${#audio[@]}; i++)); do
					if [[ -z "${audio[${i}]}" ]]; then
						continue
					fi
					local audiodata audiolang
					audiodata=$(ffprobe "${1}" -show_streams -select_streams a:${i} 2>&1)
					audiolang=$(echo "${audiodata}" | grep -i 'TAG:LANGUAGE=' | tr '[:upper:]' '[:lower:]' | sed 's/tag:language=//g')
					if [[ -z "${audiolang}" ]] || [[ "${audiolang}" == "und" ]] || [[ "${audiolang}" == "unk" ]]; then
						audiolang="${CONF_DEFAULTLANGUAGE}"
					fi
					if [[ "$(echo "${audiodata}" | grep -i 'TAG:' | tr '[:upper:]' '[:lower:]')" =~ commentary ]]; then
						continue
					fi
					if [[ "${CONF_LANGUAGES}" != "*" ]]; then
						local allowed=false
						for ((l = 0; l < ${#CONF_LANGUAGES[@]}; l++)); do
							if [[ -z "${CONF_LANGUAGES[${l}]}" ]]; then
								continue
							fi
							if [[ "${audiolang}" != "${CONF_LANGUAGES[${l}]}" ]]; then
								continue
							fi
							allowed=true
						done
						if ! ${allowed}; then
							continue
						fi
					fi
					if ${CONF_DUALAUDIO}; then
						local aac=false ac3=false audiocodec audiochannels
						if [[ ! -z "${dualaudio[${audiolang}]}" ]]; then
							aac=${dualaudio[${audiolang}]%%:*}
							ac3=${dualaudio[${audiolang}]#*:}
						fi
						audiocodec=$(echo "${audiodata}" | grep -i 'CODEC_NAME=' | tr '[:upper:]' '[:lower:]' | sed 's/codec_name=//g')
						audiochannels=$(echo "${audiodata}" | grep -i 'CHANNELS=' | tr '[:upper:]' '[:lower:]' | sed 's/channels=//g')
						if [[ "${audiocodec}" == "aac" ]] && (( audiochannels == 2 )); then
							if ${aac}; then
								continue
							else
								aac=true
							fi
						elif [[ "${audiocodec}" == "ac3" ]] && (( audiochannels == 6 )); then
							if ${ac3}; then
								continue
							else
								ac3=true
							fi
						else
							local have=false
							for ((s = 0; s < ${#audiostreams[@]}; s++)); do
								if [[ -z "${audiostreams[${s}]}" ]]; then
									continue
								fi
								local lang
								lang=$(ffprobe "${1}" -show_streams -select_streams a:${s} 2>&1 | grep -i 'TAG:LANGUAGE=' | tr '[:upper:]' '[:lower:]' | sed 's/tag:language=//g')
								if [[ -z "${lang}" ]] || [[ "${lang}" == "und" ]] || [[ "${lang}" == "unk" ]]; then
									lang="${CONF_DEFAULTLANGUAGE}"
								fi
								if [[ "${lang}" == "${audiolang}" ]]; then
									have=true
								fi
							done
							if ${have}; then
								continue
							fi
						fi
						dualaudio["${audiolang}"]="${aac}:${ac3}"
					else
						local have=false
						for ((s = 0; s < ${#audiostreams[@]}; s++)); do
							if [[ -z "${audiostreams[${s}]}" ]]; then
								continue
							fi
							local lang
							lang=$(ffprobe "${1}" -show_streams -select_streams a:${s} 2>&1 | grep -i 'TAG:LANGUAGE=' | tr '[:upper:]' '[:lower:]' | sed 's/tag:language=//g')
							if [[ -z "${lang}" ]] || [[ "${lang}" == "und" ]] || [[ "${lang}" == "unk" ]]; then
								lang="${CONF_DEFAULTLANGUAGE}"
							fi
							if [[ "${lang}" == "${audiolang}" ]]; then
								have=true
							fi
						done
						if ${have}; then
							continue
						fi
					fi
					audiostreams+=("${audio[${i}]}")
				done
				if (( ${#audiostreams} == 0 )); then
					for ((i = 0; i < ${#audio[@]}; i++)); do
						if [[ -z "${audio[${i}]}" ]]; then
							continue
						fi
						audiostreams+=("${audio[${i}]}")
					done
				fi
				local x=0
				for ((i = 0; i < ${#audio[@]}; i++)); do
					if [[ -z "${audio[${i}]}" ]]; then
						continue
					fi
					for ((s = 0; s < ${#audiostreams[@]}; s++)); do
						if [[ -z "${audiostreams[${s}]}" ]]; then
							continue
						fi
						if [[ "${audio[${i}]}" != "${audiostreams[${s}]}" ]]; then
							continue
						fi
						local tag=false audiomap audiocodec audiochannels audiolang
						audiomap=$(echo "${audiostreams[${s}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
						if (( ${#audiomap} > 3 )); then
							audiomap=${audiomap%:*}
						fi
						audiocodec=$(echo "${audiostreams[${s}]}" | awk '{print($4)}')
						if [[ "${audiocodec}" == *, ]]; then
							audiocodec=${audiocodec%?}
						fi
						audiochannels=$(ffprobe "${1}" -show_streams -select_streams a:${i} 2>&1 | grep -i 'CHANNELS=' | tr '[:upper:]' '[:lower:]' | sed 's/channels=//g')
						audiolang=$(ffprobe "${1}" -show_streams -select_streams a:${i} 2>&1 | grep -i 'TAG:LANGUAGE=' | tr '[:upper:]' '[:lower:]' | sed 's/tag:language=//g')
						if [[ -z "${audiolang}" ]] || [[ "${audiolang}" == "und" ]] || [[ "${audiolang}" == "unk" ]]; then
							audiolang="${CONF_DEFAULTLANGUAGE}"
							tag=true
						fi
						if ${CONF_DUALAUDIO}; then
							local aac=false ac3=false
							if [[ ! -z "${dualaudio[${audiolang}]}" ]]; then
								aac=${dualaudio[${audiolang}]%%:*}
								ac3=${dualaudio[${audiolang}]#*:}
							fi
							if ${aac} && ${ac3}; then
								command+=" -map ${audiomap} -c:a:${x} copy"
							else
								if [[ "${audiocodec}" == "aac" ]]; then
									if (( audiochannels > 2 )); then
										command+=" -map ${audiomap} -c:a:${x} aac -ac:a:${x} 2 -ab:a:0 256k"
										boost=true
										if ${tag} && [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
											command+=" -metadata:s:a:${x} language=${CONF_DEFAULTLANGUAGE}"
										fi
										((x++))
										command+=" -map ${audiomap} -c:a:${x} ac3"
									elif (( audiochannels == 2 )); then
										command+=" -map ${audiomap} -c:a:${x} copy"
									else
										command+=" -map ${audiomap} -c:a:${x} aac"
									fi
								elif [[ "${audiocodec}" == "ac3" ]]; then
									if (( audiochannels > 2 )); then
										command+=" -map ${audiomap} -c:a:${x} aac -ac:a:${x} 2 -ab:a:0 256k"
										boost=true
										if ${tag} && [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
											command+=" -metadata:s:a:${x} language=${CONF_DEFAULTLANGUAGE}"
										fi
										((x++))
										command+=" -map ${audiomap} -c:a:${x} copy"
									else
										command+=" -map ${audiomap} -c:a:${x} aac"
									fi
								else
									if (( audiochannels > 2 )); then
										command+=" -map ${audiomap} -c:a:${x} aac -ac:a:${x} 2 -ab:a:0 256k"
										boost=true
										if ${tag} && [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
											command+=" -metadata:s:a:${x} language=${CONF_DEFAULTLANGUAGE}"
										fi
										((x++))
										command+=" -map ${audiomap} -c:a:${x} ac3"
									else
										command+=" -map ${audiomap} -c:a:${x} aac"
									fi
								fi
							fi
						else
							if [[ "${audiocodec}" == "aac" ]]; then
								if (( audiochannels > 2 )); then
									command+=" -map ${audiomap} -c:a:${x} aac -ac:a:${x} 2 -ab:a:${x} 256k"
									boost=true
								elif (( audiochannels == 2 )); then
									command+=" -map ${audiomap} -c:a:${x} copy"
								else
									command+=" -map ${audiomap} -c:a:${x} aac"
								fi
							else
								command+=" -map ${audiomap} -c:a:${x} aac"
							fi
						fi
						if ${tag} && [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
							command+=" -metadata:s:a:${x} language=${CONF_DEFAULTLANGUAGE}"
						fi
						((x++))
					done
				done

				if ${CONF_SUBTITLES}; then
					local subtitle=() subtitlestreams=()
					readarray -t subtitle <<< "$(echo "${data}" | grep 'Subtitle:' | sed 's/\ \ \ \ \ //g')"
					for ((i = 0; i < ${#subtitle[@]}; i++)); do
						if [[ -z "${subtitle[${i}]}" ]]; then
							continue
						fi
						if [[ "${CONF_LANGUAGES}" != "*" ]]; then
							local subtitledata subtitlelang
							subtitledata=$(ffprobe "${1}" -show_streams -select_streams s:${i} 2>&1)
							subtitlelang=$(echo "${subtitledata}" | grep -i 'TAG:LANGUAGE=' | tr '[:upper:]' '[:lower:]' | sed 's/tag:language=//g')
							if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang}" == "und" ]] || [[ "${subtitlelang}" == "unk" ]]; then
								subtitlelang="${CONF_DEFAULTLANGUAGE}"
							fi
							if [[ "${subtitle[${i}]}" =~ hdmv_pgs_subtitle ]]; then
								continue
							fi
							local have=false
							for ((s = 0; s < ${#subtitlestreams[@]}; s++)); do
								if [[ -z "${subtitlestreams[${s}]}" ]]; then
									continue
								fi
								lang=$(ffprobe "${1}" -show_streams -select_streams s:${s} 2>&1 | grep -i 'TAG:LANGUAGE=' | tr '[:upper:]' '[:lower:]' | sed 's/tag:language=//g')
								if [[ -z "${lang}" ]] || [[ "${lang}" == "und" ]] || [[ "${lang}" == "unk" ]]; then
									lang="${CONF_DEFAULTLANGUAGE}"
								fi
								if [[ "${lang}" == "${subtitlelang}" ]]; then
									have=true
								fi
							done
							if ${have}; then
								continue
							fi
							if [[  "${subtitlelang}" == "${CONF_DEFAULTLANGUAGE}" ]] && [[ ${subtitle[${i}],,} =~ forced ]] || [[ "${subtitlelang}" == "${CONF_DEFAULTLANGUAGE}" ]] && [[ $(echo "${subtitledata}" | grep -i 'TAG:TITLE=' | tr '[:upper:]' '[:lower:]' | sed 's/tag:title=//g') =~ forced ]]; then
								subtitlestreams+=("${subtitle[${i}]}")
								continue
							fi
							for ((l = 0; l < ${#CONF_LANGUAGES[@]}; l++)); do
								if [[ -z "${CONF_LANGUAGES[${l}]}" ]]; then
									continue
								fi
								if [[ "${subtitlelang}" == "${CONF_LANGUAGES[${l}]}" ]]; then
									subtitlestreams+=("${subtitle[${i}]}")
								fi
							done
						else
							subtitlestreams+=("${subtitle[${i}]}")
						fi
					done
					for ((i = 0; i < ${#subtitle[@]}; i++)); do
						if [[ -z "${subtitle[${i}]}" ]]; then
							continue
						fi
						for ((s = 0; s < ${#subtitlestreams[@]}; s++)); do
							if [[ -z "${subtitlestreams[${s}]}" ]]; then
								continue
							fi
							if [[ "${subtitle[${i}]}" != "${subtitlestreams[${s}]}" ]]; then
								continue
							fi
							local subtitlemap subtitlecodec
							subtitlemap=$(echo "${subtitlestreams[${s}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
							if (( ${#subtitlemap} > 3 )); then
								subtitlemap=${subtitlemap%:*}
							fi
							subtitlecodec=$(echo "${subtitlestreams[${s}]}" | awk '{print($4)}')
							if [[ "${subtitlecodec}" == *, ]]; then
								subtitlecodec=${subtitlecodec%?}
							fi
							if [[ "${subtitlecodec}" == "mov_text" ]]; then
								command+=" -map ${subtitlemap} -c:s:${s} copy"
							else
								command+=" -map ${subtitlemap} -c:s:${s} mov_text"
							fi
							if [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
								local subtitlelang
								subtitlelang=$(ffprobe "${1}" -show_streams -select_streams s:${i} 2>&1 | grep -i 'TAG:LANGUAGE=' | tr '[:upper:]' '[:lower:]' | sed 's/tag:language=//g')
								if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang}" == "und" ]] || [[ "${subtitlelang}" == "unk" ]]; then
									command+=" -metadata:s:s:${s} language=${CONF_DEFAULTLANGUAGE}"
								fi
							fi
						done
					done
					if [[ "${command}" =~ -c:s ]]; then
						command="${command//-i/-fix_sub_duration\ -i}"
					fi
				fi

				command+=" -f ${CONF_FORMAT,,} -movflags +faststart -strict experimental -y \"${tmpfile}\""
				if ${CONF_VERBOSE}; then
					echo "VERBOSE: ${command}"
				fi
				if ${CONF_TEST}; then
					echo "Test Mode is enabled, therefore nothing was done."
					return 2
				fi
				echo "Converting..."
				eval "${command} &" &>/dev/null
				PID=${!}
				if [[ ! -z "${vstatsfile}" ]]; then
					progress "${vstatsfile}" "${total}"
				fi
				wait ${PID}
				if [[ ${?} -ne 0 ]]; then
					echo "Result: failure"
					return 1
				fi
				echo "Result: success"
				if ${CONF_NORMALIZE} && ${boost}; then
					echo "Checking audio levels..."
					normalize "${tmpfile}"
				fi
				if ${CONF_DELETE}; then
					rm "${1}"
				fi
				mv "${tmpfile}" "${newfile}"
				echo "Conversion successful!"
			else
				echo "File was in use."
			fi
		;;
		*) echo "File: ${1} is not convertable."; return 1 ;;
	esac
	return 0
}

normalize() {
	local newfile="${1}.old" boost=false video=() audio=() subtitle=() data
	local command="ffmpeg -threads ${CONF_THREADS} -i \"${newfile}\""
	data="$(ffprobe "${1}" 2>&1)"
	readarray -t video <<< "$(echo "${data}" | grep 'Video:' | sed 's/\ \ \ \ \ //g')"
	for ((i = 0; i < ${#video[@]}; i++)); do
		if [[ -z "${video[${i}]}" ]]; then
			continue
		fi
		local videomap
		videomap=$(echo "${video[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
		if (( ${#videomap} > 3 )); then
			videomap=${videomap%:*}
		fi
		command+=" -map ${videomap} -c:v:${i} copy"
	done
	readarray -t audio <<< "$(echo "${data}" | grep 'Audio:' | sed 's/\ \ \ \ \ //g')"
	for ((i = 0; i < ${#audio[@]}; i++)); do
		if [[ -z "${audio[${i}]}" ]]; then
			continue
		fi
		local audiocodec audiomap
		audiocodec=$(echo "${audio[${i}]}" | awk '{print($4)}')
		if [[ "${audiocodec}" == *, ]]; then
			audiocodec=${audiocodec%?}
		fi
		audiomap=$(echo "${audio[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
		if (( ${#audiomap} > 3 )); then
			audiomap=${audiomap%:*}
		fi
		if [[ "${audiocodec}" != "aac" ]]; then
			command+=" -map ${audiomap} -c:a:${i} copy"
			continue
		fi
		local dB=0 a=0
		dB=$(ffmpeg -i "${1}" -map "${audiomap}" -filter:a:${i} "volumedetect" -f null /dev/null 2>&1 | grep 'max_volume:' | sed 's/.*]\ //g' | sed 's/max_volume:\ //g' | sed 's/\ dB//g')
		if (( ${#dB} == 4 )); then
			a=${dB:1:1}
		fi
		if (( a > 1 )); then
			command+=" -map ${audiomap} -c:a:${i} aac -filter:a:${i} \"volume=${a}dB\""
			boost=true
		fi
	done
	readarray -t subtitle <<< "$(echo "${data}" | grep 'Subtitle:' | sed 's/\ \ \ \ \ //g')"
	for ((i = 0; i < ${#subtitle[@]}; i++)); do
		if [[ -z "${subtitle[${i}]}" ]]; then
			continue
		fi
		local subtitlemap
		subtitlemap=$(echo "${subtitle[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
		if (( ${#subtitlemap} > 3 )); then
			subtitlemap=${subtitlemap%:*}
		fi
		command+=" -map ${subtitlemap} -c:s:${i} copy"
	done
	command+=" -f ${CONF_FORMAT,,} -movflags +faststart -strict experimental -y \"${1}\""
	if ${boost}; then
		mv "${1}" "${newfile}"
		TMPFILES+=("${newfile}")
		if ${CONF_VERBOSE}; then
			echo "VERBOSE: ${command}"
		fi
		echo "Boosting audio..."
		eval "${command} &" &>/dev/null
		PID=${!}
		wait ${PID}
		if [[ ${?} -ne 0 ]]; then
			echo "Result: failure"
			return 1
		fi
		echo "Result: success"
	fi
	return 0
}

progress() {
	local totalframes="${2}" currentframe=0 eta=0 elapsed=0 oldpercentage=0
	local start vstats percentage
	start=$(date +%s)
	while [[ -e /proc/$PID ]]; do
		if [[ -e "${1}" ]]; then
			vstats=$(awk '{gsub(/frame=/, "")}/./{line=$1-1} END{print line}' "${1}")
			if (( vstats > currentframe )); then
				currentframe=${vstats}
				percentage=$(( 100 * currentframe / totalframes ))
				elapsed=$(( $(date +%s) - start ))
				eta=$(date -d @"$(awk "BEGIN{print int((${elapsed} / ${currentframe}) * \
					(${totalframes} - ${currentframe}))}")" -u +%H:%M:%S)
			fi
			if (( percentage > oldpercentage )); then
				oldpercentage=${percentage}
    			echo "Converting... ${percentage}% ETA: ${eta}"
    		fi
    	fi
    	sleep 2
	done
}

cleanup() {
	if ! ${NZBPO_TEST}; then
		local files samples nzbsize samplesize extensions=()
		readarray -t files < <(find "${NZBPP_DIRECTORY}" -type f)
		case "${NZBPO_SAMPLES^^}" in
			NAME)
				for file in "${files[@]}"; do
					if [[ "${file,,}" =~ sample ]] || [[ "${file,,}" =~ trailer ]]; then
						rm "${file}"
					fi
				done
			;;
			SIZE)
				readarray -t samples < <(find "${NZBPP_DIRECTORY}" -type f -size -"${NZBPO_SAMPLE_SIZE//[!0-9]/}"M)
				if (( ${#samples[@]} > 0 )); then
					nzbsize=$(du -s "${NZBPP_DIRECTORY}" | awk '{print($1)}')
					nzbsize=$(( nzbsize * 1024 ))
					samplesize=$(( ${NZBPO_SIZE:-0} * 1024 * 1024 ))
					if (( nzbsize > samplesize )); then
						for file in "${samples[@]}"; do
							rm "${file}"
						done
					fi
				fi
			;;
			BOTH)
				for file in "${files[@]}"; do
					if [[ "${file,,}" =~ sample ]] || [[ "${file,,}" =~ trailer ]]; then
						rm "${file}"
					fi
				done
				readarray -t samples < <(find "${NZBPP_DIRECTORY}" -type f -size -"${NZBPO_SAMPLE_SIZE//[!0-9]/}"M)
				if (( ${#samples[@]} > 0 )); then
					nzbsize=$(du -s "${NZBPP_DIRECTORY}" | awk '{print($1)}')
					nzbsize=$(( nzbsize * 1024 ))
					samplesize=$(( ${NZBPO_SIZE:-0} * 1024 * 1024 ))
					if (( nzbsize > samplesize )); then
						for file in "${samples[@]}"; do
							rm "${file}"
						done
					fi
				fi
			;;
		esac
		read -a extensions <<< "$(echo "${NZBPO_CLEANUP}" | sed 's/\ //g' | sed 's/\\.//g' | sed 's/,/\ /g')"
		if (( ${#extensions[@]} > 0 )); then
			for file in "${files[@]}"; do
				for ext in "${extensions[@]}"; do
					if [[ "${file##*.}" == "${ext}" ]]; then
						rm "${file}"
					fi
				done
			done
		fi
	fi
	return 0
}

depend() {
	if (( BASH_VERSINFO < 4 )); then
		echo "Sorry, you do not have Bash 4+."
		return 3
	fi
	if ! hash ffmpeg 2>/dev/null; then
		echo "Sorry, you do not have FFMPEG."
		return 4
	fi
	if ! hash ffprobe 2>/dev/null; then
		echo "Sorry, you do not have FFPROBE."
		return 5
	fi
	return 0
}

configure() {
	local file dir source="${BASH_SOURCE[0]}"
	while [ -h "${source}" ]; do
  		dir="$(cd -P "$( dirname "${source}" )" && pwd)"
  		source="$(readlink "${source}")"
  		if [[ "${source}" != /* ]]; then
  			source="${dir}/${source}"
  		fi
	done
	dir="$(cd -P "$( dirname "${source}" )" && pwd)"
	file="$(basename "${0}")"
	local conf="${dir}/${file//${file##*.}/conf}"
	if [[ -e "${conf}" ]]; then
		source "${conf}"
	fi
	CONF_VERBOSE=${NZBPO_VERBOSE:-${VERBOSE}}
	CONF_VERBOSE=${CONF_VERBOSE,,}
	: "${CONF_VERBOSE:=false}"
	CONF_TEST=${NZBPO_TEST:-${TEST}}
	CONF_TEST=${CONF_TEST,,}
	: "${CONF_TEST:=false}"
	CONF_THREADS=${NZBPO_THREADS:-${THREADS}}
	CONF_THREADS=${CONF_THREADS,,}
	: "${CONF_THREADS:=auto}"
	CONF_PRESET=${NZBPO_PRESET:-${PRESET}}
	CONF_PRESET=${CONF_PRESET,,}
	: "${CONF_PRESET:=medium}"
	CONF_CRF=${NZBPO_CRF:-${CRF}}
	CONF_CRF=${CONF_CRF,,}
	: "${CONF_CRF:=23}"
	CONF_VIDEOBITRATE=${NZBPO_VIDEO_BITRATE:-${VIDEOBITRATE}}
	CONF_VIDEOBITRATE=${CONF_VIDEOBITRATE,,}
	: "${CONF_VIDEOBITRATE:=0}"
	CONF_DUALAUDIO=${NZBPO_DUAL_AUDIO:-${DUALAUDIO}}
	CONF_DUALAUDIO=${CONF_DUALAUDIO,,}
	: "${CONF_DUALAUDIO:=false}"
	CONF_NORMALIZE=${NZBPO_NORMALIZE:-${NORMALIZE}}
	CONF_NORMALIZE=${CONF_NORMALIZE,,}
	: "${CONF_NORMALIZE:-true}"
	CONF_SUBTITLES=${NZBPO_SUBTITLES:-${SUBTITLES}}
	CONF_SUBTITLES=${CONF_SUBTITLES,,}
	: "${CONF_SUBTITLES:=true}"
	CONF_FORMAT=${NZBPO_FORMAT:-${FORMAT}}
	CONF_FORMAT=${CONF_FORMAT,,}
	: "${CONF_FORMAT:=mp4}"
	CONF_EXTENSION=${NZBPO_EXTENSION:-${EXTENSION}}
	CONF_EXTENSION=${CONF_EXTENSION,,}
	: "${CONF_EXTENSION:=m4v}"
	CONF_DELETE=${NZBPO_DELETE:-${DELETE}}
	CONF_DELETE=${CONF_DELETE,,}
	: "${CONF_DELETE:=false}"
	CONF_LANGUAGES="${NZBPO_LANGUAGES:-${LANGUAGES}}"
	CONF_LANGUAGES="${CONF_LANGUAGES,,}"
	: "${CONF_LANGUAGES:=*}"
	read -a CONF_LANGUAGES <<< "$(echo "${CONF_LANGUAGES}" | sed 's/\ //g' | sed 's/,/\ /g')"
	CONF_DEFAULTLANGUAGE="${CONF_LANGUAGES[0]}"
	return 0
}

verify() {
	case "${CONF_VERBOSE}" in
		true) ;;
		false) ;;
		*) echo "VERBOSE is incorrectly configured."; return 1 ;;
	esac
	case "${CONF_TEST}" in
		true) ;;
		false) ;;
		*) echo "Test is incorrectly configured."; return 1 ;;
	esac
	if [[ "${CONF_THREADS}" != "auto" ]]; then
		if [[ ! "${CONF_THREADS}" =~ ^-?[0-9]+$ ]] || (( "${CONF_THREADS}" == 0 || "${CONF_THREADS}" > 8 )); then
			echo "Threads is incorrectly configured."
			return 1
		fi
	fi
	case "${CONF_PRESET}" in
		ultrafast) ;;
		superfast) ;;
		veryfast) ;;
		faster) ;;
		fast) ;;
		medium) ;;
		slow) ;;
		slower) ;;
		veryslow) ;;
		*) echo "Preset is incorrectly configured."; return 1 ;;
	esac
	if [[ ! "${CONF_CRF}" =~ ^-?[0-9]+$ ]] || (( "${CONF_CRF}" > 51 )); then
		echo "CRF is incorrectly configured."
		return 1
	fi
	if [[ ! "${CONF_VIDEOBITRATE}" =~ ^-?[0-9]+$ ]]; then
		echo "Video Bitrate is incorrectly configured."
		return 1
	fi
	case "${CONF_DUALAUDIO}" in
		true) ;;
		false) ;;
		*) echo "Dual Audio is incorrectly configured."; return 1 ;;
	esac
	case "${CONF_NORMALIZE}" in
		true) ;;
		false) ;;
		*) echo "Normalize is incorrectly configured."; return 1 ;;
	esac
	case "${CONF_SUBTITLES}" in
		true) ;;
		false) ;;
		*) echo "Subtitles is incorrectly configured."; return 1 ;;
	esac
	if [[ "${CONF_FORMAT}" != "mp4" ]] && [[ "${CONF_FORMAT}" != "mov" ]]; then
		echo "Format is incorrectly configured. ${CONF_FORMAT}"
		return 1
	fi
	if [[ "${CONF_EXTENSION}" != "mp4" ]] && [[ "${CONF_EXTENSION}" != "m4v" ]]; then
		echo "Extension is incorrectly configured."
		return 1
	fi
	case "${CONF_DELETE}" in
		true) ;;
		false) ;;
		*) echo "Delete is incorrectly configured."; return 1 ;;
	esac
	if [[ "${CONF_LANGUAGES}" != "*" ]]; then
		local incorrect=false
		for ((l = 0; l < ${#CONF_LANGUAGES[@]}; l++)); do
			if (( ${#CONF_LANGUAGES[${l}]} > 3 )); then
				incorrect=true
			fi
		done
		if ${incorrect}; then
			echo "Languages is incorrectly configured."
			return 1
		fi
	fi
	return 0
}

status() {
    "${@}"
    if [[ ${?} -ne 0 ]]; then
    	if [[ ! -z "${NZBOP_SCRIPTDIR}" ]]; then
    		exit 94
    	else
    		exit 1
    	fi
    fi
    return 0
}

main() {
	status depend
	if [[ ! -z "${NZBOP_SCRIPTDIR}" ]]; then
		local postprocess_success=93 postprocess_error=94 postprocess_none=95
		if [[ "${NZBPP_TOTALSTATUS}" != "SUCCESS" ]]; then
			exit ${postprocess_none}
		fi
		configure
		status verify
		cleanup
		local success=false failure=false files
		echo "Processing directory: ${NZBPP_DIRECTORY}"
		readarray -t files < <(find "${NZBPP_DIRECTORY}" -type f)
		for file in "${files[@]}"; do
			process "${file}"
			case ${?} in
				0) success=true; ;;
				1) failure=true; ;;
				*) ;;
			esac
		done
		if ${success}; then
			return ${postprocess_success}
		else
			if ${failure}; then
				${NZBPO_BAD} && echo "[NZB] MARK=BAD"
				return ${postprocess_error}
			else
				return ${postprocess_none}
			fi
		fi
	else
		configure
		local process=() temp
		temp=$(getopt -o hvtp: --long help,process:,verbose:,test:,threads:,preset:,crf:,videobitrate:,languages:,dualaudio:,normalize:,subtitles:,format:,extension:,delete: -- "${@}")
		if [[ ${?} -ne 0 ]]; then
			usage
		fi
		eval set -- "${temp}"
		while true; do
			case "${1}" in
				-h|--help) usage ;;
				-v) CONF_VERBOSE=true; shift ;;
				-t) CONF_TEST=true; CONF_VERBOSE=true; shift ;;
				-p|--process) process+=("${2}"); shift 2 ;;
				--verbose) CONF_VERBOSE="${2,,}"; shift 2 ;;
				--test) CONF_TEST="${2,,}"; shift 2 ;;
				--threads) CONF_THREADS="${2,,}"; shift 2 ;;
				--preset) CONF_PRESET="${2,,}"; shift 2 ;;
				--crf) CONF_CRF="${2,,}"; shift 2 ;;
				--videobitrate) CONF_VIDEOBITRATE="${2,,}"; shift 2 ;;
				--languages)
					read -a CONF_LANGUAGES <<< "$(echo "${2,,}" | sed 's/\ //g' | sed 's/,/\ /g')"
					CONF_DEFAULTLANGUAGE=${CONF_LANGUAGES[0]}; shift 2 ;;
				--dualaudio) CONF_DUALAUDIO="${2,,}"; shift 2 ;;
				--normalize) CONF_NORMALIZE="${2,,}"; shift 2 ;;
				--subtitles) CONF_SUBTITLES="${2,,}"; shift 2 ;;
				--format) CONF_FORMAT="${2,,}"; shift 2 ;;
				--extension) CONF_EXTENSION="${2,,}"; shift 2 ;;
				--delete) CONF_DELETE="${2,,}"; shift 2 ;;
				--) shift; break ;;
				*) usage ;;
			esac
		done
		if (( ${#process} == 0 )); then
			usage
		fi
		status verify
		local success=false failure=false
		for ((i = 0; i < ${#process[@]}; i++)); do
			if [[ -f "${process[${i}]}" ]]; then
				process "${process[${i}]}"
				case ${?} in
					0) success=true; ;;
					1) failure=true; ;;
					*) ;;
				esac
			elif [[ -d "${process[${i}]}" ]]; then
				local dir="${process[${i}]}" files
				echo "Processing directory: ${dir}"
				readarray -t files < <(find "${dir}" -type f)
				for file in "${files[@]}"; do
					process "${file}"
					case ${?} in
						0) success=true; ;;
						1) failure=true; ;;
						*) ;;
					esac
				done
			else
				echo "${process[${i}]} is not a valid file or directory."
			fi
		done
		if ${success}; then
			return 0
		else
			if ${failure}; then
				return 1
			else
				return 2
			fi
		fi
	fi
}

main "${@}"
exit ${?}