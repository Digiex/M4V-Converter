#!/bin/bash

##############################################################################
### NZBGET POST-PROCESSING SCRIPT                                          ###

# M4V-Converter (LINUX & OS X)
#
# This script converts media to mp4 format.
#
# NOTE: This script requires FFMPEG, FFPROBE and Bash 4+.

##############################################################################
### OPTIONS                                                                ###

# Verbose Mode (true, false).
# Prints extra details, useful for debugging.
#Verbose=false

# Debug Mode (true, false).
# When enabled this script does nothing.
#Debug=false

# Number of Threads (1-8).
# This is how many threads FFMPEG will use for conversion.
#Threads=auto

# Preferred Languages (*).
# This is the language(s) you prefer.
#
# English (eng), French (fre), German (ger), Italian (ita), Spanish (spa), * (all).
#
# NOTE: This is used for audio and subtitles. The first listed is considered the default/preferred.
#Languages=

# H.264 Preset (*).
# This controls encoding speed to compression ratio.
#
# NOTE: Allowed: 'ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow'
#
#
# NOTE: https://trac.ffmpeg.org/wiki/Encode/H.264
#Preset=medium

# H.264 Profile (*).
# This defines the features / capabilities that the encoder can use.
#
# NOTE: Allowed: 'baseline, main, high'
#
#
# NOTE: https://en.wikipedia.org/wiki/H.264/MPEG-4_AVC#Profiles
#Profile=main

# H.264 Level (*).
# This is another form of constraints that define things like maximum bitrates, framerates and resolution etc.
#
# NOTE: Allowed: '3.0, 3.1, 3.2, 4.0, 4.1, 4.2, 5.0, 5.1, 5.2'
#
#
# NOTE: https://en.wikipedia.org/wiki/H.264/MPEG-4_AVC#Levels
#Level=4.1

# H.264 Constant Rate Factor (*).
# This controls maximum compression efficiency with a single pass.
#
# NOTE: Allowed: '0 - 51'
#
#
# NOTE: https://trac.ffmpeg.org/wiki/Encode/H.264
#CRF=23

# Video Resolution (*).
# This will resize and convert the video if it exceeds this value.
#
# NOTE: Ex. 720p, 1280x720, 1280:720
#
#
# NOTE: https://trac.ffmpeg.org/wiki/Scaling%20%28resizing%29%20with%20ffmpeg
#Resolution=

# Video Bitrate (KB).
# Use this to limit video bitrate, if it exceeds this limit then video will be converted.
#
# NOTE: Ex. '6144' (6 Mbps)
#
#Video Bitrate=

# Create Dual Audio Streams (true, false).
# This will create two audio streams, if possible. AAC 2.0 and AC3 5.1.
#
# NOTE: AAC will be the default for better compatability with more devices.
#Dual Audio=false

# Normalize Audio (true, false).
# This will normalize audio if needed due to downmixing 5.1 to 2.0.
#Normalize=false

# Copy Subtitles (true, false).
# This will copy/convert subtitles of your matching language(s) into the converted file.
#Subtitles=true

# File Format (MP4, MOV).
# MP4 is better supported universally. MOV is best with Apple devices and iTunes.
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

# Cleanup Size (MB).
# Any file less than the specified size is deleted.
#Cleanup Size=

# Cleanup Files.
# This will delete extra files with the above file extensions
#Cleanup=.nfo, .nzb

### NZBGET POST-PROCESSING SCRIPT                                          ###
##############################################################################

NZBGET=false
SABNZBD=false

SUCCESS=0
FAILURE=1
SKIPPED=2
DEPEND=3
CONFIG=4

if [[ ! -z "${NZBOP_SCRIPTDIR}" ]]; then
	SUCCESS=93
	FAILURE=94
	SKIPPED=95
	DEPEND=94
	CONFIG=94
	NZBGET=true
else
	if (( ${#} == 7 )) || (( ${#} == 8 )); then
		if [[ -e "${1}" ]] && [[ -d "${1}" ]]; then
			if [[ "${7}" =~ ^-?[0-9]+$ ]] && (( ${7} > -1 || ${7} <= 3 )); then
				SUCCESS=0
				FAILURE=1
				SKIPPED=0
				DEPEND=2
				CONFIG=3
				SABNZBD=true
			fi
		fi
	fi
fi

usage() {
	cat <<-EOF
	USAGE: ${0} parameters

	This script is designed to convert media

	NOTE: This script requires FFMPEG, FFPROBE and BASH 4+

	OPTIONS:
	--------
	-h  --help    Show this message
	-v            Verbose Mode
	-d            Debug Mode
	-i  --input   Input file or directory
	-c  --config  Config file

	ADVANCED OPTIONS:
	-----------------
	--verbose
	--debug
	--threads
	--languages
	--preset
	--crf
	--resolution
	--videobitrate
	--dualaudio
	--subtitles
	--format
	--extension
	--delete

	EXAMPLE: ${0} -v -i ~/video.mkv
	EOF
    exit ${FAILURE}
}

force() {
	if (( PID > 0 )) && ps -p "${PID}" &>/dev/null; then
		disown "${PID}"
		kill -KILL "${PID}" &>/dev/null
	fi
	exit ${FAILURE}
}

clean() {
	for file in "${TMPFILES[@]}"; do
		if [[ -e "${file}" ]]; then
			rm "${file}"
		fi
	done
}

trap force HUP INT TERM QUIT
trap clean EXIT

if (( BASH_VERSINFO < 4 )); then
	echo "Sorry, you do not have Bash 4+"
	exit ${DEPEND}
fi
if ! hash ffmpeg 2>/dev/null; then
	echo "Sorry, you do not have FFMPEG"
	exit ${DEPEND}
fi
if ! hash ffprobe 2>/dev/null; then
	echo "Sorry, you do not have FFPROBE"
	exit ${DEPEND}
fi

if ${NZBGET}; then
	if [[ -z "${NZBPP_TOTALSTATUS}" ]]; then
		echo "Sorry, you do not have NZBGET version 13.0 or later."
		exit ${DEPEND}
	fi
	if [[ "${NZBPP_TOTALSTATUS}" != "SUCCESS" ]]; then
		exit ${SKIPPED}
	fi
	samplesize=${NZBPO_CLEANUP_SIZE:-0}
	if (( samplesize > 0 )); then
		readarray -t samples <<< "$(find "${NZBPP_DIRECTORY}" -type f -size -"${NZBPO_CLEANUP_SIZE//[!0-9]/}"M)"
		if [[ ! -z "${samples[@]}" ]]; then
			for file in "${samples[@]}"; do
				rm -f "${file}"
			done
		fi
	fi
	read -r -a extensions <<< "$(echo "${NZBPO_CLEANUP}" | sed 's/\ //g' | sed 's/,/\ /g')"
	if [[ ! -z "${extensions[@]}" ]]; then
		readarray -t files <<< "$(find "${NZBPP_DIRECTORY}" -type f)"
		if [[ ! -z "${files[@]}" ]]; then
			for file in "${files[@]}"; do
				for ext in "${extensions[@]}"; do
					if [[ "${file##*.}" == "${ext//./}" ]]; then
						rm -f "${file}"
						break
					fi
				done
			done
		fi
	fi
	process+=("${NZBPP_DIRECTORY}")
elif ${SABNZBD}; then
	if ! (( ${7} == 0 )); then
		exit ${SKIPPED}
	fi
	process+=("${1}")
else
	while getopts hvdi:c:-: opts; do
		case ${opts,,} in
			h) usage ;;
			v) CONF_VERBOSE=true ;;
			d) CONF_DEBUG=true; CONF_VERBOSE=true ;;
			i) process+=("${OPTARG}") ;;
			c) CONF_FILE="${OPTARG}" ;;
			-) arg="${OPTARG#*=}";
				case "${OPTARG,,}" in
       				help) usage ;;
					input=*) process+=("${arg}") ;;
					verbose=*) CONF_VERBOSE="${arg}" ;;
					debug=*) CONF_DEBUG="${arg}" ;;
					threads=*) CONF_THREADS="${arg}" ;;
					languages=*) CONF_LANGUAGES="${arg}" ;;
					preset=*) CONF_PRESET="${arg}" ;;
					profile=*) CONF_PROFILE="${arg}" ;;
					level=*) CONF_LEVEL="${arg}" ;;
					crf=*) CONF_CRF="${arg}" ;;
					resolution=*) CONF_RESOLUTION="${arg}" ;;
					videobitrate=*) CONF_VIDEOBITRATE="${arg}" ;;
					dualaudio=*) CONF_DUALAUDIO="${arg}" ;;
					normalize=*) CONF_NORMALIZE="${arg}" ;;
					subtitles=*) CONF_SUBTITLES="${arg}" ;;
					format=*) CONF_FORMAT="${arg}" ;;
					extension=*) CONF_EXTENSION="${arg}" ;;
					delete=*) CONF_DELETE="${arg}" ;;
					config=*) CONF_FILE="${arg}" ;;
					*) usage ;;
				esac
			;;
			*) usage ;;
		esac
	done
fi

if [[ ! -z "${CONF_FILE}" ]]; then
	if [[ ! -f "${CONF_FILE}" ]]; then
		echo "Config is incorrectly configured."
		exit ${CONFIG}
	fi
	source "${CONF_FILE}"
else
	source="${BASH_SOURCE[0]}"
	while [ -h "${source}" ]; do
		dir="$(cd -P "$( dirname "${source}" )" && pwd)"
		source="$(readlink "${source}")"
		if [[ "${source}" != /* ]]; then
			source="${dir}/${source}"
		fi
	done
	dir="$(cd -P "$( dirname "${source}" )" && pwd)"
	file="$(basename "${0}")"
	conf="${dir}/${file//${file##*.}/conf}"
	if [[ -e "${conf}" ]]; then
		source "${conf}"
	fi
fi

CONF_VERBOSE=${CONF_VERBOSE:-${NZBPO_VERBOSE:-${VERBOSE}}}
: "${CONF_VERBOSE:=false}"
CONF_VERBOSE=${CONF_VERBOSE,,}
case "${CONF_VERBOSE}" in
	true) ;;
	false) ;;
	*) echo "Verbose is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_DEBUG=${CONF_DEBUG:-${NZBPO_DEBUG:-${DEBUG}}}
: "${CONF_DEBUG:=false}"
CONF_DEBUG=${CONF_DEBUG,,}
case "${CONF_DEBUG}" in
	true) ;;
	false) ;;
	*) echo "Debug is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_THREADS=${CONF_THREADS:-${NZBPO_THREADS:-${THREADS}}}
: "${CONF_THREADS:=auto}"
CONF_THREADS=${CONF_THREADS,,}
if [[ "${CONF_THREADS}" != "auto" ]]; then
	if [[ ! "${CONF_THREADS}" =~ ^-?[0-9]+$ ]] || (( "${CONF_THREADS}" == 0 || "${CONF_THREADS}" > 8 )); then
		echo "Threads is incorrectly configured"
		exit ${CONFIG}
	fi
fi

CONF_LANGUAGES="${CONF_LANGUAGES:-${NZBPO_LANGUAGES:-${LANGUAGES}}}"
: "${CONF_LANGUAGES:=*}"
CONF_LANGUAGES="${CONF_LANGUAGES,,}"
read -r -a CONF_LANGUAGES <<< "$(echo "${CONF_LANGUAGES}" | sed 's/\ //g' | sed 's/,/\ /g')"
CONF_DEFAULTLANGUAGE="${CONF_LANGUAGES[0]}"
: "${CONF_DEFAULTLANGUAGE:=*}"
if [[ "${CONF_LANGUAGES}" != "*" ]]; then
	for language in "${CONF_LANGUAGES[@]}"; do
		if ! (( ${#language} == 3 )); then
			echo "Languages is incorrectly configured"
			exit ${CONFIG}
		fi
	done
fi

CONF_PRESET=${CONF_PRESET:-${NZBPO_PRESET:-${PRESET}}}
: "${CONF_PRESET:=medium}"
CONF_PRESET=${CONF_PRESET,,}
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
	"*") ;;
	*) echo "Preset is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_PROFILE=${CONF_PROFILE:-${NZBPO_PROFILE:-${PROFILE}}}
: "${CONF_PROFILE:=main}"
CONF_PROFILE=${CONF_PROFILE,,}
case "${CONF_PROFILE}" in
	baseline) ;;
	main) ;;
	high) ;;
	"*") ;;
	*) echo "Profile is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_LEVEL=${CONF_LEVEL:-${NZBPO_LEVEL:-${LEVEL}}}
: "${CONF_LEVEL:=4.1}"
CONF_LEVEL=${CONF_LEVEL,,}
case "${CONF_LEVEL}" in
	3.0) ;;
	3.1) ;;
	3.2) ;;
	4.0) ;;
	4.1) ;;
	4.2) ;;
	5.0) ;;
	5.1) ;;
	5.2) ;;
	"*") ;;
	*) echo "Level is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_CRF=${CONF_CRF:-${NZBPO_CRF:-${CRF}}}
: "${CONF_CRF:=23}"
CONF_CRF=${CONF_CRF,,}
if [[ "${CONF_CRF}" != "*" ]]; then
	if [[ ! "${CONF_CRF}" =~ ^-?[0-9]+$ ]] || (( "${CONF_CRF}" < 0 )) || (( "${CONF_CRF}" > 51 )); then
		echo "CRF is incorrectly configured"
		exit ${CONFIG}
	fi
fi

CONF_RESOLUTION=${CONF_RESOLUTION:-${NZBPO_RESOLUTION:-${RESOLUTION}}}
CONF_RESOLUTION=${CONF_RESOLUTION,,}
if [[ ! -z "${CONF_RESOLUTION}" ]]; then
	case "${CONF_RESOLUTION,,}" in
		480p) CONF_RESOLUTION=640x480 ;;
		720p) CONF_RESOLUTION=1280x720 ;; 
		1080p) CONF_RESOLUTION=1920x1080 ;; 
		2160p) CONF_RESOLUTION=3840x2160 ;;
	esac
	if [[ ! "${CONF_RESOLUTION}" =~ [x|:] ]] || [[ ! "${CONF_RESOLUTION//[x|:]/}" =~ ^-?[0-9]+$ ]]; then
		echo "Resolution is incorrectly configured"
		exit ${CONFIG}
	fi
fi

CONF_VIDEOBITRATE=${CONF_VIDEOBITRATE:-${NZBPO_VIDEO_BITRATE:-${VIDEOBITRATE}}}
: "${CONF_VIDEOBITRATE:=0}"
CONF_VIDEOBITRATE=${CONF_VIDEOBITRATE,,}
if [[ ! "${CONF_VIDEOBITRATE}" =~ ^-?[0-9]+$ ]]; then
	echo "Video Bitrate is incorrectly configured"
	exit ${CONFIG}
fi

CONF_DUALAUDIO=${CONF_DUALAUDIO:-${NZBPO_DUAL_AUDIO:-${DUALAUDIO}}}
: "${CONF_DUALAUDIO:=false}"
CONF_DUALAUDIO=${CONF_DUALAUDIO,,}
case "${CONF_DUALAUDIO}" in
	true) ;;
	false) ;;
	*) echo "Dual Audio is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_NORMALIZE=${CONF_NORMALIZE:-${NZBPO_NORMALIZE:-${NORMALIZE}}}
: "${CONF_NORMALIZE:=false}"
CONF_NORMALIZE=${CONF_NORMALIZE,,}
case "${CONF_NORMALIZE}" in
	true) ;;
	false) ;;
	*) echo "Normalize is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_SUBTITLES=${CONF_SUBTITLES:-${NZBPO_SUBTITLES:-${SUBTITLES}}}
: "${CONF_SUBTITLES:=true}"
CONF_SUBTITLES=${CONF_SUBTITLES,,}
case "${CONF_SUBTITLES}" in
	true) ;;
	false) ;;
	*) echo "Subtitles is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_FORMAT=${CONF_FORMAT:-${NZBPO_FORMAT:-${FORMAT}}}
: "${CONF_FORMAT:=mp4}"
CONF_FORMAT=${CONF_FORMAT,,}
if [[ "${CONF_FORMAT}" != "mp4" ]] && [[ "${CONF_FORMAT}" != "mov" ]]; then
	echo "Format is incorrectly configured"
	exit ${CONFIG}
fi

CONF_EXTENSION=${CONF_EXTENSION:-${NZBPO_EXTENSION:-${EXTENSION}}}
: "${CONF_EXTENSION:=m4v}"
CONF_EXTENSION=${CONF_EXTENSION,,}
if [[ "${CONF_EXTENSION}" != "mp4" ]] && [[ "${CONF_EXTENSION}" != "m4v" ]]; then
	echo "Extension is incorrectly configured"
	exit ${CONFIG}
fi

CONF_DELETE=${CONF_DELETE:-${NZBPO_DELETE:-${DELETE}}}
: "${CONF_DELETE:=false}"
CONF_DELETE=${CONF_DELETE,,}
case "${CONF_DELETE}" in
	true) ;;
	false) ;;
	*) echo "Delete is incorrectly configured"; exit ${CONFIG} ;;
esac

if (( ${#process[@]} == 0 )); then
	usage
fi

progress() {
	START=$(date +%s) PROGRESSED=false CURRENTFRAME=0 PERCENTAGE=0 RATE=0 ETA=0 ELAPSED=0
	local TOTALFRAMES=${2} FRAME=0 OLDPERCENTAGE=0
	case ${1} in
		1) local TYPE="Converting" ;;
		2) local TYPE="Boosting" ;;
	esac
	while ps -p "${PID}" &>/dev/null; do
		sleep 2
		if [[ -e "${STATSFILE}" ]]; then
			FRAME=$(tac "${STATSFILE}" 2>&1 | grep -m 1 -x 'frame=.*' | sed 's/[^0-9]//g')
			if (( FRAME > CURRENTFRAME )); then
				CURRENTFRAME=${FRAME}
				PERCENTAGE=$(( 100 * CURRENTFRAME / TOTALFRAMES ))
			fi
			if (( PERCENTAGE > OLDPERCENTAGE )); then
				OLDPERCENTAGE=${PERCENTAGE}
				ELAPSED=$(( $(date +%s) - START ))
				RATE=$(( TOTALFRAMES / ELAPSED ))
				ETA=$(awk "BEGIN{print int((${ELAPSED} / ${CURRENTFRAME}) * (${TOTALFRAMES} - ${CURRENTFRAME}))}")
				case "${OSTYPE}" in
					linux-gnu)
						ETA=$(date -d @"${ETA}" -u +%H:%M:%S 2>&1)
						ELAPSED=$(date -d @"${ELAPSED}" -u +%H:%M:%S 2>&1)
					;;
					darwin*)
						ETA=$(date -r "${ETA}" -u +%H:%M:%S 2>&1)
						ELAPSED=$(date -r "${ELAPSED}" -u +%H:%M:%S 2>&1)
					;;
				esac
				echo "${TYPE}... ${PERCENTAGE}% ETA: ${ETA}"
				PROGRESSED=true
			fi
		fi
	done
}

success=false failure=false skipped=false
for input in "${process[@]}"; do
	if [[ -z "${input}" ]]; then
		continue
	fi
	if [[ ! -e "${input}" ]] || [[ "${input}" == / ]]; then
		echo "${input} is not a valid file or directory"
		continue
	fi
	if [[ -d "${input}" ]]; then
		echo "Processing directory: ${input}"
	fi
	readarray -t files <<< "$(find "${input}" -type f)"
	for file in "${files[@]}"; do
		if [[ -z "${file}" ]]; then
			continue
		fi
		skip=true
		echo "Processing file: ${file}"
		case "${file,,}" in
			*.mkv | *.mp4 | *.m4v | *.avi | *.wmv | *.xvid | *.divx | *.mpg | *.mpeg) ;;
			*)
				if [[ "$(ffprobe "${file}" 2>&1)" =~ "Invalid data found when processing input" ]]; then
					echo "File is not convertable" && continue
				else
					echo "File does not have the expected extension but is a media file. Attemtping..."
				fi
			;;
		esac
		lsof "${file}" 2>&1 | grep -q COMMAND &>/dev/null
		if [[ ${?} -eq 0 ]]; then
			echo "File is in use"
			skipped=true && continue
		fi
		command="ffmpeg -threads ${CONF_THREADS} -i \"${file}\""
		directoryname="$(dirname "${file}")"
		filename="$(basename "${file}")"
		if [[ "${filename}" == "${filename##*.}" ]]; then
			newname="${filename}.${CONF_EXTENSION}"
		else
			newname="${filename//${filename##*.}/${CONF_EXTENSION}}"
		fi
		newfile="${directoryname}/${newname}"
		tmpfile="${newfile}.tmp"
		if [[ -e "${tmpfile}" ]]; then
			rm -f "${tmpfile}"
		fi
		data="$(ffprobe "${file}" 2>&1)"
		video="$(echo "${data}" | grep 'Stream.*Video:' | sed 's/.*Stream/Stream/g')"
		if [[ -z "${video}" ]]; then
			echo "File is missing video"
			failure=true && continue
		fi
		readarray -t video <<< "${video}"
		audio="$(echo "${data}" | grep 'Stream.*Audio:' | sed 's/.*Stream/Stream/g')"
		if [[ -z "${audio}" ]]; then
			echo "File is missing audio"
			failure=true && continue
		fi
		readarray -t audio <<< "${audio}"
		subtitle="$(echo "${data}" | grep 'Stream.*Subtitle:' | sed 's/.*Stream/Stream/g')"
		if [[ ! -z "${subtitle}" ]]; then
			readarray -t subtitle <<< "${subtitle}"
		fi
		filtered=()
		for ((i = 0; i < ${#video[@]}; i++)); do
			if [[ -z "${video[${i}]}" ]]; then
				continue
			fi
			videodata=$(ffprobe "${file}" -v quiet -show_streams -select_streams v:${i} 2>&1)
			if [[ $(echo "${videodata,,}" | grep -x '.*mimetype=.*' | sed 's/.*mimetype=//g') == image/* ]]; then
				filtered+=("${video[${i}]}")
				continue
			fi
		done
		x=0
		for ((i = 0; i < ${#video[@]}; i++)); do
			if [[ -z "${video[${i}]}" ]]; then
				continue
			fi
			if ! (( ${#filtered[@]} == ${#video[@]} )); then
				allow=true
				for filter in "${filtered[@]}"; do
					if [[ "${filter}" == "${video[${i}]}" ]]; then
						allow=false
						break
					fi
				done
				if ! ${allow}; then
					continue
				fi
			fi
			convert=false
			videodata=$(ffprobe "${file}" -v quiet -show_streams -select_streams v:${i} 2>&1)
			videomap=$(echo "${video[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
			if (( ${#videomap} > 3 )); then
				videomap=${videomap%:*}
			fi
			videocodec=$(echo "${videodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
			if [[ "${videocodec}" != "h264" ]]; then
				convert=true
			fi
			profile=false
			if [[ "${CONF_PROFILE}" != "*" ]]; then
				videoprofile=$(echo "${videodata}" | grep -x 'profile=.*' | sed 's/profile=//g')
				if ! [[ "${videoprofile,,}" =~ "constrained" ]]; then
					if [[ "${videoprofile,,}" != "${CONF_PROFILE}" ]]; then
						convert=true
						profile=true
					fi
				fi
			fi
			level=false
			if [[ "${CONF_LEVEL}" != "*" ]]; then
				videolevel=$(echo "${videodata}" | grep -x 'level=.*' | sed 's/[^0-9]//g')
				if (( videolevel < 30 )) || (( videolevel > ${CONF_LEVEL//./} )); then
					convert=true
					level=true
				fi
			fi
			limit=false
			if (( CONF_VIDEOBITRATE > 0 )); then
				videobitrate=$(echo "${videodata}" | grep -x 'bit_rate=.*' | sed -E 's/[^0-9]//g')
				if (( videobitrate == 0 )); then
					globalbitrate=$(ffprobe "${file}" -v quiet -show_entries format=bit_rate -of default=nokey=1:noprint_wrappers=1 | sed -E 's/[^0-9]//g')
					if (( globalbitrate > 0 )); then
						for ((a = 0; a < ${#audio[@]}; a++)); do
							bitrate=$(ffprobe "${file}" -v quiet -select_streams a:${a} -show_entries stream=bit_rate -of default=nokey=1:noprint_wrappers=1 | sed -E 's/[^0-9]//g')
							audiobitrate=$(( audiobitrate + bitrate ))
						done
						videobitrate=$(( globalbitrate - audiobitrate ))
					fi
				fi
				videobitrate=$(( videobitrate / 1024 ))
				if (( videobitrate > CONF_VIDEOBITRATE )); then
					convert=true
					limit=true
				fi
			fi
			resize=false
			if [[ ! -z "${CONF_RESOLUTION}" ]]; then
				width=${CONF_RESOLUTION//[x|:]*/}
				height=${CONF_RESOLUTION//*[x|:]/}
				if (( width > height )); then
					scale=${width}
				else
					scale=${height}
				fi
				if [[ ! -z "${scale}" ]]; then
					videowidth=$(echo "${videodata}" | grep -x 'width=.*' | sed 's/[^0-9]//g')
					if (( videowidth > scale )); then
						convert=true
						resize=true
					fi	
				fi
			fi
			if ${CONF_VERBOSE}; then
				total=$(echo "${videodata}" | grep -x 'nb_frames=.*' | sed -E 's/[^0-9]//g')
				if [[ -z "${total}" ]]; then
					fps=$(echo "${data}" | sed -n "s/.*, \(.*\) fps.*/\1/p")
					dur=$(echo "${data}" | sed -n "s/.* Duration: \([^,]*\), .*/\1/p" | awk -F ':' '{print $1*3600+$2*60+$3}')
					total=$(echo "${dur}" "${fps}" | awk '{printf("%3.0f\n",($1*$2))}')
				fi
				if (( total > 0 )); then
					STATSFILE="${newfile}.stats"
					if [[ -e "${STATSFILE}" ]]; then
						rm -f "${STATSFILE}"
					fi
					TMPFILES+=("${STATSFILE}")
					command+=" -progress \"${STATSFILE}\""
				fi
			fi
			if ${convert}; then
				command+=" -map ${videomap} -c:v:${x} libx264"
				if ${resize}; then
					command+=" -filter_complex \"[${videomap}]scale=${scale}:trunc(ow/a/2)*2\""
				fi
				if [[ "${CONF_PRESET}" != "*" ]]; then
					command+=" -preset:${x} ${CONF_PRESET}"
				fi
				if ${profile}; then
					command+=" -profile:v:${x} ${CONF_PROFILE}"
				fi
				if ${level}; then
					command+=" -level:${x} ${CONF_LEVEL}"
				fi
				if [[ "${CONF_CRF}" != "*" ]]; then
					command+=" -crf:${x} ${CONF_CRF}"
				fi
				if ${limit}; then
					command+=" -maxrate:${x} ${CONF_VIDEOBITRATE}k -bufsize:${x} $(( CONF_VIDEOBITRATE * 2 ))k"
				fi
				skip=false
			else
				command+=" -map ${videomap} -c:v:${x} copy"
			fi
			videolang=$(echo "${videodata,,}" | grep -i "TAG:LANGUAGE=" | sed 's/tag:language=//g')
			if [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
				if [[ -z "${videolang}" ]] || [[ "${videolang}" == "und" ]] || [[ "${videolang}" == "unk" ]]; then
					videolang="${CONF_DEFAULTLANGUAGE}"
					skip=false
				fi
			fi
			command+=" -metadata:s:v:${x} \"language=${videolang}\""
			((x++))
		done
		filtered=()
		for ((i = 0; i < ${#audio[@]}; i++)); do
			if [[ -z "${audio[${i}]}" ]]; then
				continue
			fi
			audiodata=$(ffprobe "${file}" -v quiet -show_streams -select_streams a:${i} 2>&1)
			if [[ "$(echo "${audiodata,,}" | grep -i 'TAG:')" =~ commentary ]]; then
				filtered+=("${audio[${i}]}")
				continue
			fi
			audiolang=$(echo "${audiodata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
			if [[ -z "${audiolang}" ]] || [[ "${audiolang}" == "und" ]] || [[ "${audiolang}" == "unk" ]]; then
				audiolang="${CONF_DEFAULTLANGUAGE}"
			fi
			if [[ "${CONF_LANGUAGES}" != "*" ]]; then
				allow=false
				for language in "${CONF_LANGUAGES[@]}"; do
					if [[ -z "${language}" ]]; then
						continue
					fi
					if [[ "${audiolang}" == "${language}" ]]; then
						allow=true
						break
					fi
				done
				if ! ${allow}; then
					filtered+=("${audio[${i}]}")
					continue
				fi
			fi
		done
		audiostreams=() boost=false
		declare -A dualaudio=()
		for ((i = 0; i < ${#audio[@]}; i++)); do
			if [[ -z "${audio[${i}]}" ]]; then
				continue
			fi
			if ! (( ${#filtered[@]} == ${#audio[@]} )); then
				allow=true
				for filter in "${filtered[@]}"; do
					if [[ "${filter}" == "${audio[${i}]}" ]]; then
						allow=false
						break
					fi
				done
				if ! ${allow}; then
					continue
				fi
			fi
			if ! ${CONF_DUALAUDIO}; then
				if (( ${#audiostreams[@]} == 1 )); then
					continue
				fi
			fi
			audiodata=$(ffprobe "${file}" -v quiet -show_streams -select_streams a:${i} 2>&1)
			audiolang=$(echo "${audiodata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
			if [[ -z "${audiolang}" ]] || [[ "${audiolang}" == "und" ]] || [[ "${audiolang}" == "unk" ]]; then
				audiolang="${CONF_DEFAULTLANGUAGE}"
			fi
			audiocodec=$(echo "${audiodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
			audiochannels=$(echo "${audiodata}" | grep -x 'channels=.*' | sed 's/[^0-9]//g')
			audioprofile=$(echo "${audiodata}" | grep -x 'profile=.*' | sed 's/profile=//g')
			if ${CONF_DUALAUDIO}; then
				aac=false ac3=false
				if [[ ! -z "${dualaudio[${audiolang}]}" ]]; then
					aac=${dualaudio[${audiolang}]%%:*}
					ac3=${dualaudio[${audiolang}]#*:}
				fi
				if [[ "${audiocodec}" == "aac" ]] && [[ "${audioprofile}" == "LC" ]] && (( audiochannels == 2 )); then
					if ! ${aac}; then
						aac=true
						audiostreams+=("${audio[${i}]}")
						dualaudio["${audiolang}"]="${aac}:${ac3}"
					fi
					continue
				elif [[ "${audiocodec}" == "ac3" ]] && (( "${audiochannels}" == 6 )); then
					if ! ${ac3}; then
						ac3=true
						audiostreams+=("${audio[${i}]}")
						dualaudio["${audiolang}"]="${aac}:${ac3}"
					fi
					continue
				else
					aac=false ac3=false
					for ((a = 0; a < ${#audio[@]}; a++)); do
						if [[ -z "${audio[${a}]}" ]]; then
							continue
						fi
						audiodata=$(ffprobe "${file}" -v quiet -show_streams -select_streams a:${a} 2>&1)
						lang=$(echo "${audiodata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
						if [[ -z "${lang}" ]] || [[ "${lang}" == "und" ]] || [[ "${lang}" == "unk" ]]; then
							lang="${CONF_DEFAULTLANGUAGE}"
						fi
						if [[ "${lang}" != "${audiolang}" ]]; then
							continue
						fi
						audiocodec=$(echo "${audiodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
						audioprofile=$(echo "${audiodata}" | grep -x 'profile=.*' | sed 's/profile=//g')
						audiochannels=$(echo "${audiodata}" | grep -x 'channels=.*' | sed 's/[^0-9]//g')
						if [[ "${audiocodec}" == "aac" ]] && [[ "${audioprofile}" == "LC" ]] && (( audiochannels == 2 )); then
							aac=true
							break
						elif [[ "${audiocodec}" == "ac3" ]] && (( audiochannels == 6 )); then
							ac3=true
							break
						fi
					done
					if ${aac} || ${ac3}; then
						continue
					else
						if (( ${#audiostreams[@]} == 1 )); then
							continue
						fi
					fi
				fi
			else
				if [[ "${audiocodec}" != "aac" ]] || [[ "${audioprofile}" != "LC" ]] || (( audiochannels != 2 )); then
					aac=false
					for ((a = 0; a < ${#audio[@]}; a++)); do
						if [[ -z "${audio[${a}]}" ]]; then
							continue
						fi
						audiodata=$(ffprobe "${file}" -v quiet -show_streams -select_streams a:${a} 2>&1)
						lang=$(echo "${audiodata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
						if [[ -z "${lang}" ]] || [[ "${lang}" == "und" ]] || [[ "${lang}" == "unk" ]]; then
							lang="${CONF_DEFAULTLANGUAGE}"
						fi
						if [[ "${lang}" != "${audiolang}" ]]; then
							continue
						fi
						audiocodec=$(echo "${audiodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
						audioprofile=$(echo "${audiodata}" | grep -x 'profile=.*' | sed 's/profile=//g')
						audiochannels=$(echo "${audiodata}" | grep -x 'channels=.*' | sed 's/[^0-9]//g')
						if [[ "${audiocodec}" == "aac" ]] && [[ "${audioprofile}" == "LC" ]] && (( audiochannels == 2 )); then
							aac=true
							break
						fi
					done
					if ${aac}; then
						continue
					fi
				fi
			fi
			audiostreams+=("${audio[${i}]}")
		done
		streams=()
		for language in "${CONF_LANGUAGES[@]}"; do
			if [[ -z "${language}" ]]; then
				continue
			fi
			for stream in "${audiostreams[@]}"; do
				if [[ -z "${stream}" ]]; then
					continue
				fi
				for ((i = 0; i < ${#audio[@]}; i++)); do
					if [[ -z "${audio[${i}]}" ]]; then
						continue
					fi
					if [[ "${audio[${i}]}" != "${stream}" ]]; then
						continue
					fi
					audiolang=$(ffprobe "${file}" -v quiet -select_streams a:${i} -show_entries stream_tags=language -of default=nokey=1:noprint_wrappers=1)
					if [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
						if [[ -z "${audiolang}" ]] || [[ "${audiolang,,}" == "und" ]] || [[ "${audiolang,,}" == "unk" ]]; then
							audiolang="${CONF_DEFAULTLANGUAGE}"
						fi
					fi
					if [[ "${audiolang,,}" == "${language}" ]]; then
						streams+=("${stream}")
					fi
				done
			done
		done
		if [[ ! -z "${streams[@]}" ]] && [[ "${audiostreams[@]}" != "${streams[@]}" ]]; then
			audiostreams=("${streams[@]}")
			skip=false
		fi
		if ${CONF_DUALAUDIO}; then
			streams=()
			declare -A swap=()
			for ((s = 0; s < ${#audiostreams[@]}; s++)); do
				if [[ -z "${audiostreams[${s}]}" ]]; then
					continue
				fi
				for ((i = 0; i < ${#audio[@]}; i++)); do
					if [[ -z "${audio[${i}]}" ]]; then
						continue
					fi
					if [[ "${audio[${i}]}" != "${audiostreams[${s}]}" ]]; then
						continue
					fi
					audiodata=$(ffprobe "${file}" -v quiet -show_streams -select_streams a:${i} 2>&1)
					audiolang=$(echo "${audiodata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
					if [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
						if [[ -z "${audiolang}" ]] || [[ "${audiolang}" == "und" ]] || [[ "${audiolang}" == "unk" ]]; then
							audiolang="${CONF_DEFAULTLANGUAGE}"
						fi
					fi
					aac=false ac3=false
					if [[ ! -z "${dualaudio[${audiolang}]}" ]]; then
						aac=${dualaudio[${audiolang}]%%:*}
						ac3=${dualaudio[${audiolang}]#*:}
					fi
					if ${aac} && ${ac3}; then
						unset aac ac3
						if [[ ! -z "${swap[${audiolang}]}" ]]; then
							aac=${swap[${audiolang}]%%;*}
							ac3=${swap[${audiolang}]#*;}
						fi
						if [[ -z "${aac}" ]] || [[ -z "${ac3}" ]]; then
							audiocodec=$(echo "${audiodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
							if [[ "${audiocodec}" == "aac" ]]; then
								aac="${audiostreams[${s}]}"
							else
								ac3="${audiostreams[${s}]}"
							fi
							swap[${audiolang}]="${aac};${ac3}"
						fi
						if [[ ! -z "${aac}" ]] && [[ ! -z "${ac3}" ]]; then
							streams+=("${aac}")
							streams+=("${ac3}")
						fi
					else
						streams+=("${audiostreams[${s}]}")
					fi
				done
			done
			if [[ ! -z "${streams[@]}" ]] && [[ "${audiostreams[@]}" != "${streams[@]}" ]]; then
				audiostreams=("${streams[@]}")
				skip=false
			fi
		fi
		x=0
		BOOST=()
		for ((s = 0; s < ${#audiostreams[@]}; s++)); do
			if [[ -z "${audiostreams[${s}]}" ]]; then
				continue
			fi
			for ((i = 0; i < ${#audio[@]}; i++)); do
				if [[ -z "${audio[${i}]}" ]]; then
					continue
				fi
				if [[ "${audio[${i}]}" != "${audiostreams[${s}]}" ]]; then
					continue
				fi
				audiodata=$(ffprobe "${file}" -v quiet -show_streams -select_streams a:${i} 2>&1)
				audiomap=$(echo "${audio[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
				if (( ${#audiomap} > 3 )); then
					audiomap=${audiomap%:*}
				fi
				audiocodec=$(echo "${audiodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
				audioprofile=$(echo "${audiodata}" | grep -x 'profile=.*' | sed 's/profile=//g')
				audiochannels=$(echo "${audiodata}" | grep -x 'channels=.*' | sed 's/[^0-9]//g')
				audiolang=$(echo "${audiodata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
				if [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
					if [[ -z "${audiolang}" ]] || [[ "${audiolang}" == "und" ]] || [[ "${audiolang}" == "unk" ]]; then
						audiolang="${CONF_DEFAULTLANGUAGE}"
						skip=false
					fi
				fi
				audiobitrate=$(echo "${audiodata}" | grep -x 'bit_rate=.*' | sed -E 's/[^0-9]//g')
				if ${CONF_DUALAUDIO}; then
					aac=false ac3=false
					if [[ ! -z "${dualaudio[${audiolang}]}" ]]; then
						aac=${dualaudio[${audiolang}]%%:*}
						ac3=${dualaudio[${audiolang}]#*:}
					fi
					if ${aac} && ${ac3}; then
						command+=" -map ${audiomap} -c:a:${x} copy"
					else
						if [[ "${audiocodec}" == "aac" ]]; then
							if [[ "${audioprofile}" == "LC" ]]; then
								if (( audiochannels > 2 )); then
									command+=" -map ${audiomap} -c:a:${x} aac -ac:a:${x} 2"
									if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
										command+=" -ab:a:${x} 128k"
									fi
									BOOST+=("${x}")
									command+=" -metadata:s:a:${x} \"language=${audiolang}\""
									((x++))
									command+=" -map ${audiomap} -c:a:${x} ac3"
									if (( audiochannels > 6 )); then
										command+=" -ac:a:${x} 6"
									fi
									skip=false
								else
									command+=" -map ${audiomap} -c:a:${x} copy"
								fi
							else
								if (( audiochannels > 2 )); then
									command+=" -map ${audiomap} -c:a:${x} aac -ac:a:${x} 2"
									if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
										command+=" -ab:a:${x} 128k"
									fi
									BOOST+=("${x}")
									command+=" -metadata:s:a:${x} \"language=${audiolang}\""
									((x++))
									command+=" -map ${audiomap} -c:a:${x} ac3"
									if (( audiochannels > 6 )); then
										command+=" -ac:a:${x} 6"
									fi
								else
									command+=" -map ${audiomap} -c:a:${x} aac"
								fi
								skip=false
							fi
						elif [[ "${audiocodec}" == "ac3" ]]; then
							if (( audiochannels > 2 )); then
								command+=" -map ${audiomap} -c:a:${x} aac -ac:a:${x} 2"
								if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
									command+=" -ab:a:${x} 128k"
								fi
								BOOST+=("${x}")
								command+=" -metadata:s:a:${x} \"language=${audiolang}\""
								((x++))
								if (( audiochannels > 6 )); then
									command+=" -map ${audiomap} -c:a:${x} ac3 -ac:a:${x} 6"
								else
									command+=" -map ${audiomap} -c:a:${x} copy"
								fi
							else
								command+=" -map ${audiomap} -c:a:${x} aac"
								if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
									command+=" -ab:a:${x} 128k"
								fi
							fi
							skip=false
						else
							if (( audiochannels > 2 )); then
								command+=" -map ${audiomap} -c:a:${x} aac -ac:a:${x} 2"
								if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
									command+=" -ab:a:${x} 128k"
								fi
								BOOST+=("${x}")
								command+=" -metadata:s:a:${x} \"language=${audiolang}\""
								((x++))
								command+=" -map ${audiomap} -c:a:${x} ac3"
								if (( audiochannels > 6 )); then
									command+=" -ac:a:${x} 6"
								fi
							else
								command+=" -map ${audiomap} -c:a:${x} aac"
								if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
									command+=" -ab:a:${x} 128k"
								fi
							fi
							skip=false
						fi
					fi
				else
					if [[ "${audiocodec}" == "aac" ]]; then
						if [[ "${audioprofile}" == "LC" ]]; then
							if (( audiochannels > 2 )); then
								command+=" -map ${audiomap} -c:a:${x} aac -ac:a:${x} 2"
								if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
									command+=" -ab:a:${x} 128k"
								fi
								BOOST+=("${x}")
								skip=false
							else
								command+=" -map ${audiomap} -c:a:${x} copy"
							fi
						else
							command+=" -map ${audiomap} -c:a:${x} aac"
							if (( audiochannels > 2 )); then
								BOOST+=("${x}")
								command+=" -ac:a:${x} 2"
							fi
							if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
								command+=" -ab:a:${x} 128k"
							fi
							skip=false
						fi
					else
						command+=" -map ${audiomap} -c:a:${x} aac"
						if (( audiochannels > 2 )); then
							BOOST+=("${x}")
							command+=" -ac:a:${x} 2"
						fi
						if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
							command+=" -ab:a:${x} 128k"
						fi
						skip=false
					fi
				fi
				command+=" -metadata:s:a:${x} \"language=${audiolang}\""
				((x++))
			done
		done
		if ! (( ${#audio[@]} == ${#audiostreams[@]} )); then
			skip=false
		fi
		x=0
		for ((i = 0; i < ${#audio[@]}; i++)); do
			if [[ -z "${audio[${i}]}" ]]; then
				continue
			fi
			if (( $(ffprobe "${file}" -v quiet -select_streams a:${i} -show_entries stream_disposition=default -of default=nokey=1:noprint_wrappers=1) == 1 )); then
			 	((x++))
			fi
		done
		if (( x > 1 )); then
			skip=false
		fi
		if ${CONF_SUBTITLES}; then
			filtered=()
			for ((i = 0; i < ${#subtitle[@]}; i++)); do
				if [[ -z "${subtitle[${i}]}" ]]; then
					continue
				fi
				subtitledata=$(ffprobe "${file}" -v quiet -show_streams -select_streams s:${i} 2>&1)
				subtitlelang=$(echo "${subtitledata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
				if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang}" == "und" ]] || [[ "${subtitlelang}" == "unk" ]]; then
					subtitlelang="${CONF_DEFAULTLANGUAGE}"
				fi
				forced=$(echo "${subtitledata}" | grep -x 'DISPOSITION:forced=.*' | sed 's/[^0-9]//g')
				if [[ "${subtitledata,,}" =~ tag:.*forced ]] || (( forced == 1 )); then
					filtered+=("${subtitle[${i}]}")
					continue
				fi
				subtitlecodec=$(echo "${subtitledata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
				if [[ "${subtitlecodec}" == hdmv_pgs_subtitle ]]; then
					filtered+=("${subtitle[${i}]}")
					continue
				fi
				if [[ "${CONF_LANGUAGES}" != "*" ]]; then
					allow=false
					for language in "${CONF_LANGUAGES[@]}"; do
						if [[ -z "${language}" ]]; then
							continue
						fi
						if [[ "${subtitlelang}" == "${language}" ]]; then
							allow=true
							break
						fi
					done
					if ! ${allow}; then
						filtered+=("${subtitle[${i}]}")
						continue
					fi
				fi
			done
			subtitlestreams=()
			for ((i = 0; i < ${#subtitle[@]}; i++)); do
				if [[ -z "${subtitle[${i}]}" ]]; then
					continue
				fi
				allow=true
				for filter in "${filtered[@]}"; do
					if [[ "${filter}" == "${subtitle[${i}]}" ]]; then
						allow=false
						break
					fi
				done
				if ! ${allow}; then
					continue
				fi
				subtitledata=$(ffprobe "${file}" -v quiet -show_streams -select_streams s:${i} 2>&1)
				subtitlelang=$(echo "${subtitledata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
				if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang}" == "und" ]] || [[ "${subtitlelang}" == "unk" ]]; then
					subtitlelang="${CONF_DEFAULTLANGUAGE}"
				fi
				have=false
				for ((s = 0; s < ${#subtitlestreams[@]}; s++)); do
					if [[ -z "${subtitlestreams[${s}]}" ]]; then
						continue
					fi
					lang=$(ffprobe "${file}" -v quiet -select_streams s:${s} -show_entries stream_tags=language -of default=nokey=1:noprint_wrappers=1)
					if [[ -z "${lang}" ]] || [[ "${lang,,}" == "und" ]] || [[ "${lang,,}" == "unk" ]]; then
						lang="${CONF_DEFAULTLANGUAGE}"
					fi
					if [[ "${lang,,}" == "${subtitlelang}" ]]; then
						have=true
					fi
				done
				if ${have}; then
					continue
				fi
				subtitlestreams+=("${subtitle[${i}]}")
			done
			streams=()
			for language in "${CONF_LANGUAGES[@]}"; do
				if [[ -z "${language}" ]]; then
					continue
				fi
				for stream in "${subtitlestreams[@]}"; do
					if [[ -z "${stream}" ]]; then
						continue
					fi
					for ((i = 0; i < ${#subtitle[@]}; i++)); do
						if [[ -z "${subtitle[${i}]}" ]]; then
							continue
						fi
						if [[ "${subtitle[${i}]}" != "${stream}" ]]; then
							continue
						fi
						subtitlelang=$(ffprobe "${file}" -v quiet -select_streams a:${i} -show_entries stream_tags=language -of default=nokey=1:noprint_wrappers=1)
						if [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
							if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang,,}" == "und" ]] || [[ "${subtitlelang,,}" == "unk" ]]; then
								subtitlelang="${CONF_DEFAULTLANGUAGE}"
							fi
						fi
						if [[ "${subtitlelang,,}" == "${language}" ]]; then
							streams+=("${stream}")
						fi
					done
				done
			done
			if [[ ! -z "${streams[@]}" ]] && [[ "${subtitlestreams[@]}" != "${streams[@]}" ]]; then
				subtitlestreams=("${streams[@]}")
				skip=false
			fi
			x=0
			for ((s = 0; s < ${#subtitlestreams[@]}; s++)); do
				if [[ -z "${subtitlestreams[${s}]}" ]]; then
					continue
				fi
				for ((i = 0; i < ${#subtitle[@]}; i++)); do
					if [[ -z "${subtitle[${i}]}" ]]; then
						continue
					fi
					if [[ "${subtitle[${i}]}" != "${subtitlestreams[${s}]}" ]]; then
						continue
					fi
					subtitledata=$(ffprobe "${file}" -v quiet -show_streams -select_streams s:${i} 2>&1)
					subtitlemap=$(echo "${subtitle[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
					if (( ${#subtitlemap} > 3 )); then
						subtitlemap=${subtitlemap%:*}
					fi
					subtitlecodec=$(echo "${subtitledata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
					if [[ "${subtitlecodec}" == "mov_text" ]]; then
						command+=" -map ${subtitlemap} -c:s:${x} copy"
					else
						command+=" -map ${subtitlemap} -c:s:${x} mov_text"
						skip=false
					fi
					subtitlelang=$(echo "${subtitledata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
					if [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
						if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang}" == "und" ]] || [[ "${subtitlelang}" == "unk" ]]; then
							subtitlelang="${CONF_DEFAULTLANGUAGE}"
							skip=false
						fi
					fi
					command+=" -metadata:s:s:${s} \"language=${subtitlelang}\""
				done
			done
			if [[ "${command}" =~ mov_text ]]; then
				command="${command//-i ${file}/-fix_sub_duration -i ${file}}"
			fi
		else
			if [[ ! -z "${subtitle[@]}" ]] && (( ${#subtitle[@]} > 0 )); then
				command+=" -sn"
				skip=false
			fi
		fi
		title=$(ffprobe "${file}" -v quiet -show_entries format_tags=title -of default=noprint_wrappers=1)
		if [[ ! -z "${title}" ]]; then
			skip=false
		fi
		chapters=$(ffprobe "${file}" -v quiet -show_chapters)
		if [[ ! -z "${chapters}" ]]; then
			skip=false
		fi
		command+=" -map_metadata -1 -map_chapters -1 -f ${CONF_FORMAT} -flags +global_header -movflags +faststart -strict -2 -y \"${tmpfile}\""
		if ${skip}; then
			echo "File does not need to be converted"
			skipped=true && continue
		fi
		if ${CONF_VERBOSE}; then
			echo "VERBOSE: ${command}"
		fi
		if ${CONF_DEBUG}; then
			echo "Debug Mode is enabled, therefore nothing was done"
			skipped=true && continue
		fi
		echo "Converting..."
		TMPFILES+=("${tmpfile}")
		eval "${command} &" &>/dev/null
		PID=${!}
		progress 1 "${total}"
		wait ${PID} &>/dev/null
		if [[ ${?} -ne 0 ]]; then
			echo "Result: failure"
			failure=true && clean && continue
		fi
		success=true
		echo "Result: success"
		if ${PROGRESSED}; then
			echo "Time taken: ${ELAPSED} at an average rate of ${RATE}fps"
		fi
		if ${CONF_NORMALIZE} && [[ ! -z ${BOOST[@]} ]]; then
			echo "Checking audio levels..."
			boostedfile="${tmpfile}.old" data="$(ffprobe "${tmpfile}" 2>&1)" boost=false
			command="ffmpeg -threads ${CONF_THREADS} -i \"${boostedfile}\""
			readarray -t video <<< "$(echo "${data}" | grep 'Stream.*Video:' | sed 's/.*Stream/Stream/g')"
			for ((i = 0; i < ${#video[@]}; i++)); do
				if [[ -z "${video[${i}]}" ]]; then
					continue
				fi
				videomap=$(echo "${video[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
				if (( ${#videomap} > 3 )); then
					videomap=${videomap%:*}
				fi
				if ${CONF_VERBOSE}; then
					total=$(ffprobe "${tmpfile}" -v quiet -select_streams v:${i} -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1)
					if [[ -z "${total}" ]]; then
						fps=$(echo "${data}" | sed -n "s/.*, \(.*\) fps.*/\1/p")
						dur=$(echo "${data}" | sed -n "s/.* Duration: \([^,]*\), .*/\1/p" | awk -F ':' '{print $1*3600+$2*60+$3}')
						total=$(echo "${dur}" "${fps}" | awk '{printf("%3.0f\n",($1*$2))}')
					fi
					if (( total > 0 )); then
						if [[ -e "${STATSFILE}" ]]; then
							rm -f "${STATSFILE}"
						fi
						command+=" -progress \"${STATSFILE}\""
					fi
				fi
				command+=" -map ${videomap} -c:v:${i} copy"
			done
			readarray -t audio <<< "$(echo "${data}" | grep 'Stream.*Audio:' | sed 's/.*Stream/Stream/g')"
			for ((i = 0; i < ${#audio[@]}; i++)); do
				if [[ -z "${audio[${i}]}" ]]; then
					continue
				fi
				for stream in "${BOOST[@]}"; do
					if [[ -z "${stream}" ]]; then
						continue
					fi
					audiomap=$(echo "${audio[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
					if (( ${#audiomap} > 3 )); then
						audiomap=${audiomap%:*}
					fi
					if [[ "${audio[${i}]}" != "${audio[${stream}]}" ]]; then
						command+=" -map ${audiomap} -c:a:${i} copy"
						continue
					fi
					audiocodec=$(echo "${audio[${i}]}" | awk '{print($4)}')
					if [[ "${audiocodec}" == *, ]]; then
						audiocodec=${audiocodec%?}
					fi
					dB=$(ffmpeg -i "${tmpfile}" -map "${audiomap}" -filter:a:${i} volumedetect -f null /dev/null 2>&1 | \
						grep 'max_volume:' | sed -E 's/\[.*\:|[^-\.0-9]//g')
					if [[ ! -z "${dB}" ]] && (( ${dB%.*} < 0 )); then
						command+=" -map ${audiomap} -c:a:${i} ${audiocodec} -filter:a:${i} \"volume=${dB//-/+}dB\""
						boost=true
					fi
				done
			done
			readarray -t subtitle <<< "$(echo "${data}" | grep 'Stream.*Subtitle:' | sed 's/.*Stream/Stream/g')"
			for ((i = 0; i < ${#subtitle[@]}; i++)); do
				if [[ -z "${subtitle[${i}]}" ]]; then
					continue
				fi
				subtitlemap=$(echo "${subtitle[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
				if (( ${#subtitlemap} > 3 )); then
					subtitlemap=${subtitlemap%:*}
				fi
				command+=" -map ${subtitlemap} -c:s:${i} copy"
			done
			command+=" -f ${CONF_FORMAT} -flags +global_header -movflags +faststart -strict -2 -y \"${tmpfile}\""
			if ${boost}; then
				mv "${tmpfile}" "${boostedfile}"
				TMPFILES+=("${boostedfile}")
				if ${CONF_VERBOSE}; then
					echo "VERBOSE: ${command}"
				fi
				echo "Boosting..."
				eval "${command} &" &>/dev/null
				PID=${!}
				progress 2 "${total}"
				wait ${PID} &>/dev/null
				if [[ ${?} -eq 0 ]]; then
					echo "Result: success"
				else
					echo "Result: failure"
				fi
				if ${PROGRESSED}; then
					echo "Time taken: ${ELAPSED} at an average rate of ${RATE}fps"
				fi
			fi
		fi
		if ${CONF_DELETE}; then
			rm -f "${file}"
		fi
		mv "${tmpfile}" "${newfile}"
		clean
	done
done

mark() {
	if ${NZBGET} && ${NZBPO_BAD}; then
		echo "[NZB] MARK=BAD"
	fi
	exit "${1}"
}

if ${success}; then
	exit ${SUCCESS}
else
	if ${failure}; then
		mark ${FAILURE}
	else
		if ! ${skipped}; then
			mark ${FAILURE}
		fi
	fi
fi

exit ${SKIPPED}