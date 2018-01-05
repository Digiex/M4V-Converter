#!/usr/bin/env bash

##############################################################################
### NZBGET POST-PROCESSING SCRIPT                                          ###

# Convert media to mp4 format.
#
# This script converts media to a universal mp4 format.
#
# NOTE: This script requires FFmpeg, FFprobe and Bash 4.

##############################################################################
### OPTIONS                                                                ###

# FFmpeg.
# Use this to specify a location to the ffmpeg binary when using a non-standard setup.
#FFmpeg=ffmpeg

# FFprobe.
# Use this to specify a location to the ffprobe binary when using a non-standard setup.
#FFprobe=ffprobe

# Verbose Mode (true, false).
# Prints extra details, useful for debugging.
#Verbose=false

# Debug Mode (true, false).
# When enabled this script does nothing.
#Debug=false

# Background Mode (true, false).
# Automatically pauses transcoding if a process (determined below) is found running.
#Background=false

# Number of Threads (*).
# This is how many threads FFMPEG will use for conversion.
#Threads=auto

# Preferred Languages (*).
# This is the language(s) you prefer.
#
# NOTE: English (eng), French (fre), German (ger), Italian (ita), Spanish (spa), * (all).
# NOTE: This is used for audio and subtitles. The first listed is considered the default/preferred.
#Languages=

# Video Encoder (H.264, H.265).
# This changes which encoder to use.
#
# NOTE: H.264 offers siginificantly more compatbility with devices.
# NOTE: H.265 offers 50-75% more compression efficiency.
#Encoder=H.264

# Video Preset (ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow).
# This controls encoding speed to compression ratio.
#
# NOTE: https://trac.ffmpeg.org/wiki/Encode/H.264
#Preset=medium

# Video Profile (*).
# This defines the features / capabilities that the encoder can use.
#
# NOTE: baseline, main, high
#
# NOTE: https://en.wikipedia.org/wiki/H.264/MPEG-4_AVC#Profiles
#Profile=main

# Video Level (*).
# This is another form of constraints that define things like maximum bitrates, framerates and resolution etc.
#
# NOTE: 3.0, 3.1, 3.2, 4.0, 4.1, 4.2, 5.0, 5.1, 5.2
#
# NOTE: https://en.wikipedia.org/wiki/H.264/MPEG-4_AVC#Levels
#Level=4.1

# Video Constant Rate Factor (0-51).
# This controls maximum compression efficiency with a single pass.
#
# NOTE: https://trac.ffmpeg.org/wiki/Encode/H.264
#CRF=23

# Video Resolution (*).
# This will resize and convert the video if it exceeds this value.
#
# NOTE: Ex. 720p, 1280x720, 1280:720
#
# NOTE: https://trac.ffmpeg.org/wiki/Scaling%20%28resizing%29%20with%20ffmpeg
#Resolution=

# Video Bitrate (KB).
# Use this to limit video bitrate, if it exceeds this limit then video will be converted.
#
# NOTE: Ex. '6144' (6 Mbps)
#Video Bitrate=

# Force Video Transcode (true, false).
# Use this to force the video to transcode, overriding all other checks.
#Force Video=false

# Create Dual Audio Streams (true, false).
# This will create two audio streams, if possible. AAC 2.0 and AC3 5.1.
#
# NOTE: AAC will be the default for better compatability with more devices.
#Dual Audio=false

# Force Audio Transcode (true, false).
# Use this to force the audio to transcode, overriding all other checks.
#Force Audio=false

# Normalize Audio (true, false).
# This will normalize audio if needed due to downmixing 5.1 to 2.0.
#Normalize=false

# Force Normalize (true, false).
# This will force check audio levels for all supported audio streams.
#Force Normalize=false

# Copy Subtitles (true, false, extract).
# This will copy/convert subtitles of your matching language(s) into the converted file.
#Subtitles=true

# Force Subtitle Transcode (true, false).
# Use this to force the subtitles to transcode, overriding all other checks.
#Force Subtitle=false

# File Format (MP4, MOV).
# MP4 is better supported universally. MOV is best with Apple devices and iTunes.
#Format=mp4

# File Extension (MP4, M4V).
# The extension applied at the end of the file, such as video.mp4.
#Extension=mp4

# Delete Original File (true, false).
# If true then the original file will be deleted. Otherwise it saves both original and converted files.
#Delete=false

# Mark Bad (true, false).
# This will mark the download as bad if something goes wrong.
#
# NOTE: Helps to prevent fake releases.
#Bad=true

# File Permissions (*).
# This will set file permissions in either decimal (493) or octal (leading zero: 0755).
#
# NOTE: http://permissions-calculator.org/
#File Permission=

# Folder Permissions (*).
# This will set folder permissions in either decimal (493) or octal (leading zero: 0755).
#
# NOTE: http://permissions-calculator.org/
#Folder Permission=

# Cleanup Size (MB).
# Any file less than the specified size is deleted.
#Cleanup Size=

# Cleanup Files.
# This will delete extra files with the specified file extensions.
#Cleanup=.nfo, .nzb

# Background Processes.
# These are the processes background mode will look for and auto-pause any active transcoding if found.
#Processes=ffmpeg

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
	DEPEND=95
	CONFIG=95
	NZBGET=true
elif [[ ! -z "${SAB_VERSION}" ]]; then
	SUCCESS=0
	FAILURE=1
	SKIPPED=0
	DEPEND=2
	CONFIG=3
	SABNZBD=true
fi

usage() {
	cat <<-EOF
	USAGE: ${0} parameters

	This script converts media to a universal mp4 format.

	NOTE: This script requires FFmpeg, FFprobe and Bash 4

	OPTIONS:
	--------
	-h  --help 		Show this message
	-v  --verbose 		Verbose Mode
	-d  --debug 		Debug Mode
	-i  --input 		Input file or directory
	-o  --Output 		Output directory
	-c  --config 		Config file
	-b  --background 	Auto pauses if processes are running

	ADVANCED OPTIONS:
	-----------------

	https://github.com/Digiex/M4V-Converter/blob/master/default.conf

	--ffmpeg
	--ffprobe
	--threads
	--languages
	--encoder
	--preset
	--crf
	--resolution
	--video-bitrate
	--force-video
	--dual-audio
	--force-audio
	--normalize
	--force-normalize
	--subtitles
	--force-subtitles
	--format
	--extension
	--delete
	--file-permission
	--folder-permission
	--processes

	EXAMPLE: ${0} -v -i ~/video.mkv
	EOF
	exit ${CONFIG}
}

if (( BASH_VERSINFO < 4 )); then
	echo "Sorry, you do not have Bash 4"
	exit ${DEPEND}
fi

if [[ "${OSTYPE}" == darwin* ]]; then
	if ! [[ "${PATH}" =~ "/usr/local/bin" ]]; then
		PATH=/usr/local/bin:${PATH}
		bash "${0}" "${@}"
		exit ${?}
	fi
fi

M4VCONVERTER=()
BACKGROUNDMANAGER="/tmp/m4v.tmp"
TMPFILES+=("${BACKGROUNDMANAGER}")

force() {
	if (( CONVERTER > 0 )) && kill -0 "${CONVERTER}" &>/dev/null; then
		disown "${CONVERTER}"
		kill -KILL "${CONVERTER}" &>/dev/null
		M4VCONVERTER=("${M4VCONVERTER[@]//${CONVERTER}/}")
		echo "M4VCONVERTER=(${M4VCONVERTER[*]})" > "${BACKGROUNDMANAGER}"
	fi
	exit ${SKIPPED}
}

clean() {
	for file in "${TMPFILES[@]}"; do
		if [[ -e "${file}" ]]; then
			if [[ "${file}" == "${BACKGROUNDMANAGER}" ]]; then
				source "${file}"
				if (( ${#M4VCONVERTER[@]} > 0 )); then
					continue
				fi
			fi
			rm -f "${file}"
		fi
	done
}

trap force HUP INT TERM QUIT
trap clean EXIT

validate() {
	if [[ -e "${BACKGROUNDMANAGER}" ]]; then
		source "${BACKGROUNDMANAGER}"
		EDITED=false
		for PID in "${M4VCONVERTER[@]}"; do
			if ! kill -0 "${PID}" &>/dev/null; then
				M4VCONVERTER=("${M4VCONVERTER[@]//${PID}/}")
				EDITED=true
			fi
		done
		if ${EDITED}; then
			if (( ${#M4VCONVERTER[@]} >= 1 )); then
				echo "M4VCONVERTER=(${M4VCONVERTER[*]})" > "${BACKGROUNDMANAGER}"
			else
				rm -f "${BACKGROUNDMANAGER}"
			fi
		fi
	fi
}

if ${NZBGET}; then
	if [[ -z "${NZBPP_TOTALSTATUS}" ]]; then
		echo "Sorry, you do not have NZBGet version 13.0 or later."
		exit ${DEPEND}
	fi
	if [[ "${NZBPP_TOTALSTATUS}" != "SUCCESS" ]]; then
		exit ${SKIPPED}
	fi
	samplesize=${NZBPO_CLEANUP_SIZE:-0}
	if (( samplesize > 0 )); then
		SIZE=$(( ${NZBPO_CLEANUP_SIZE//[!0-9]/} * 1024 * 1024 ))
		readarray -t samples <<< "$(find "${NZBPP_DIRECTORY}" -type f -size -"${SIZE}"c)"
		if [[ ! -z "${samples[*]}" ]]; then
			for file in "${samples[@]}"; do
				rm -f "${file}"
			done
		fi
	fi
	read -r -a extensions <<< "$(echo "${NZBPO_CLEANUP}" | sed 's/\ //g' | sed 's/,/\ /g')"
	if [[ ! -z "${extensions[*]}" ]]; then
		readarray -t files <<< "$(find "${NZBPP_DIRECTORY}" -type f)"
		if [[ ! -z "${files[*]}" ]]; then
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
	PROCESS+=("${NZBPP_DIRECTORY}")
elif ${SABNZBD}; then
	if [[ -z "${SAB_PP_STATUS}" ]]; then
		echo "Sorry, you do not have SABnzbd version 2.0.0 or later."
		exit ${DEPEND}
	fi
	if ! (( SAB_PP_STATUS == 0 )); then
		exit ${SKIPPED}
	fi
	PROCESS+=("${SAB_COMPLETE_DIR}")
else
	while getopts hvdi:o:c:b-: opts; do
		case ${opts,,} in
			h) usage ;;
			v) CONF_VERBOSE=true ;;
			d) CONF_DEBUG=true; CONF_VERBOSE=true ;;
			i) PROCESS+=("${OPTARG}") ;;
			o) CONF_OUTPUT="${OPTARG}" ;;
			c) CONFIG_FILE="${OPTARG}" ;;
			b) CONF_BACKGROUND=true ;;
			-) arg="${OPTARG#*=}";
				case "${OPTARG,,}" in
       				help) usage ;;
					ffmpeg=*) FFMPEG="${ARG}" ;;
					ffprobe=*) FFPROBE="${ARG}" ;;
					input=*) PROCESS+=("${arg}") ;;
					output=*) CONF_OUTPUT="${arg}" ;;
					config=*) CONFIG_FILE="${arg}" ;;
					verbose=*) CONF_VERBOSE="${arg}" ;;
					debug=*) CONF_DEBUG="${arg}" ;;
					threads=*) CONF_THREADS="${arg}" ;;
					languages=*) CONF_LANGUAGES="${arg}" ;;
					encoder=*) CONF_ENCODER="${arg}" ;;
					preset=*) CONF_PRESET="${arg}" ;;
					profile=*) CONF_PROFILE="${arg}" ;;
					level=*) CONF_LEVEL="${arg}" ;;
					crf=*) CONF_CRF="${arg}" ;;
					resolution=*) CONF_RESOLUTION="${arg}" ;;
					video-bitrate=*) CONF_VIDEOBITRATE="${arg}" ;;
					force-video=*) CONF_FORCE_VIDEO="${arg}" ;;
					dual-audio=*) CONF_DUALAUDIO="${arg}" ;;
					force-audio=*) CONF_FORCE_AUDIO="${arg}" ;;
					normalize=*) CONF_NORMALIZE="${arg}" ;;
					force-normalize=*) CONF_FORCE_NORMALIZE="${arg}" ;;
					subtitles=*) CONF_SUBTITLES="${arg}" ;;
					force-subtitles=*) CONF_FORCE_SUBTITLES="${arg}" ;;
					format=*) CONF_FORMAT="${arg}" ;;
					extension=*) CONF_EXTENSION="${arg}" ;;
					delete=*) CONF_DELETE="${arg}" ;;
					file-permission=*) CONF_FILE="${arg}" ;;
					folder-permission=*) CONF_FOLDER="${arg}" ;;
					background=*) CONF_BACKGROUND="${arg}" ;;
					processes=*) CONF_PROCESSES="${arg}" ;;
					*) usage ;;
				esac
			;;
			*) usage ;;
		esac
	done
fi

path() {
	local SOURCE="${1}" DIRECTORY
	while [ -h "${SOURCE}" ]; do
		DIRECTORY="$(cd -P "$(dirname "${SOURCE}")" && pwd)"
		SOURCE="$(readlink "${SOURCE}")"
		[[ "${SOURCE}" != /* ]] && SOURCE="${DIRECTORY}/${SOURCE}"
	done
	DIRECTORY="$(cd -P "$(dirname "${SOURCE}")" && pwd)"
	echo "${DIRECTORY}"
}

if [[ ! -z "${CONFIG_FILE}" ]]; then
	if [[ ! -f "${CONFIG_FILE}" ]]; then
		echo "Config file is incorrectly configured."
		exit ${CONFIG}
	fi
	source "${CONFIG_FILE}"
else
	SOURCE_DIRECTORY=$(path "${BASH_SOURCE[0]}")
	SOURCE_FILE=$(basename "${0}")
	CONFIG_FILE="${SOURCE_DIRECTORY}/${SOURCE_FILE//${SOURCE_FILE##*.}/conf}"
	if [[ -e "${CONFIG_FILE}" ]]; then
		source "${CONFIG_FILE}"
	fi
fi

CONF_FFMPEG=${CONF_FFMPEG:-${NZBPO_FFMPEG:-${FFMPEG}}}
: "${CONF_FFMPEG:=ffmpeg}"
if ! hash "${CONF_FFMPEG}" 2>/dev/null; then
	echo "Sorry, you do not have FFmpeg"
	exit ${DEPEND}
fi

if [[ "$(ffmpeg 2>&1 | grep 'configuration:')" =~ "--enable-small" ]]; then
	echo "While you do have FFmpeg installed, it has been compiled with the \"--enable-small\" option and this will cause issues. Please reinstall without this option"
	exit ${DEPEND}
fi

CONF_FFPROBE=${CONF_FFPROBE:-${NZBPO_FFPROBE:-${FFPROBE}}}
: "${CONF_FFPROBE:=ffprobe}"
if ! hash "${CONF_FFPROBE}" 2>/dev/null; then
	echo "Sorry, you do not have FFprobe"
	exit ${DEPEND}
fi

if [[ "$(ffprobe 2>&1 | grep 'configuration:')" =~ "--enable-small" ]]; then
	echo "While you do have FFprobe installed, it has been compiled with the \"--enable-small\" option and this will cause issues. Please reinstall without this option"
	exit ${DEPEND}
fi

if [[ ! -z "${CONF_OUTPUT}" ]]; then
	CONF_OUTPUT="${CONF_OUTPUT%/}"
	if [[ ! -d "${CONF_OUTPUT}" ]]; then
		echo "Output is incorrectly configured"
		exit ${CONFIG}
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
	case "${OSTYPE}" in
		linux-gnu) MAX_CORES="$(nproc)" ;;
		darwin*) MAX_CORES="$(sysctl -n hw.ncpu)" ;;
	esac
	if [[ ! "${CONF_THREADS}" =~ ^-?[0-9]+$ ]] || (( "${CONF_THREADS}" == 0 || "${CONF_THREADS}" > MAX_CORES )); then
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

CONF_ENCODER=${CONF_ENCODER:-${NZBPO_ENCODER:-${ENCODER}}}
: "${CONF_ENCODER:=H.264}"
CONF_ENCODER=${CONF_ENCODER^^}
case "${CONF_ENCODER}" in
	H.264) CONF_ENCODER_NAME="h264"; CONF_ENCODER="libx264" ;;
	H.265) CONF_ENCODER_NAME="hevc"; CONF_ENCODER="libx265" ;;
	*) echo "Encoder is incorrectly configured"; exit ${CONFIG} ;;
esac

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
case "${CONF_ENCODER_NAME}" in
	h264) : "${CONF_CRF:=23}" ;;
	hevc) : "${CONF_CRF:=28}" ;;
esac
CONF_CRF=${CONF_CRF,,}
if [[ ! "${CONF_CRF}" =~ ^-?[0-9]+$ ]] || (( "${CONF_CRF}" < 0 )) || (( "${CONF_CRF}" > 51 )); then
	echo "CRF is incorrectly configured"
	exit ${CONFIG}
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

CONF_VIDEOBITRATE=${CONF_VIDEOBITRATE:-${NZBPO_VIDEO_BITRATE:-${VIDEO_BITRATE}}}
: "${CONF_VIDEOBITRATE:=0}"
CONF_VIDEOBITRATE=${CONF_VIDEOBITRATE,,}
if [[ ! "${CONF_VIDEOBITRATE}" =~ ^-?[0-9]+$ ]]; then
	echo "Video Bitrate is incorrectly configured"
	exit ${CONFIG}
fi

CONF_FORCE_VIDEO=${CONF_FORCE_VIDEO:-${NZBPO_FORCE_VIDEO:-${FORCE_VIDEO}}}
: "${CONF_FORCE_VIDEO:=false}"
CONF_FORCE_VIDEO=${CONF_FORCE_VIDEO,,}
case "${CONF_FORCE_VIDEO}" in
	true) ;;
	false) ;;
	*) echo "Force Video is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_DUALAUDIO=${CONF_DUALAUDIO:-${NZBPO_DUAL_AUDIO:-${DUAL_AUDIO}}}
: "${CONF_DUALAUDIO:=false}"
CONF_DUALAUDIO=${CONF_DUALAUDIO,,}
case "${CONF_DUALAUDIO}" in
	true) ;;
	false) ;;
	*) echo "Dual Audio is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_FORCE_AUDIO=${CONF_FORCE_AUDIO:-${NZBPO_FORCE_AUDIO:-${FORCE_AUDIO}}}
: "${CONF_FORCE_AUDIO:=false}"
CONF_FORCE_AUDIO=${CONF_FORCE_AUDIO,,}
case "${CONF_FORCE_AUDIO}" in
	true) ;;
	false) ;;
	*) echo "Force Audio is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_NORMALIZE=${CONF_NORMALIZE:-${NZBPO_NORMALIZE:-${NORMALIZE}}}
: "${CONF_NORMALIZE:=false}"
CONF_NORMALIZE=${CONF_NORMALIZE,,}
case "${CONF_NORMALIZE}" in
	true) ;;
	false) ;;
	*) echo "Normalize is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_FORCE_NORMALIZE=${CONF_FORCE_NORMALIZE:-${NZBPO_FORCE_NORMALIZE:-${FORCE_NORMALIZE}}}
: "${CONF_FORCE_NORMALIZE:=false}"
CONF_FORCE_NORMALIZE=${CONF_FORCE_NORMALIZE,,}
case "${CONF_FORCE_NORMALIZE}" in
	true) ;;
	false) ;;
	*) echo "Force Normalize is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_SUBTITLES=${CONF_SUBTITLES:-${NZBPO_SUBTITLES:-${SUBTITLES}}}
: "${CONF_SUBTITLES:=true}"
CONF_SUBTITLES=${CONF_SUBTITLES,,}
case "${CONF_SUBTITLES}" in
	true) ;;
	false) ;;
	extract) ;;
	*) echo "Subtitles is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_FORCE_SUBTITLES=${CONF_FORCE_SUBTITLES:-${NZBPO_FORCE_SUBTITLES:-${FORCE_SUBTITLES}}}
: "${CONF_FORCE_SUBTITLES:=false}"
CONF_FORCE_SUBTITLES=${CONF_FORCE_SUBTITLES,,}
case "${CONF_FORCE_SUBTITLES}" in
	true) ;;
	false) ;;
	*) echo "Force Subtitles is incorrectly configured"; exit ${CONFIG} ;;
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

CONF_FILE=${CONF_FILE:-${NZBPO_FILE_PERMISSION:-${FILE_PERMISSION}}}
if [[ ! -z "${CONF_FILE}" ]]; then
	if [[ ! "${CONF_FILE}" =~ ^-?[0-9]+$ ]] || (( ${#CONF_FILE} > 4 || ${#CONF_FILE} < 3 )); then
		echo "File is incorretly configured"
		exit ${CONFIG}
	else
		for ((i = 0; i < ${#CONF_FILE}; i++)); do
			if (( ${CONF_FILE:${i}:1} < 0 || ${CONF_FILE:${i}:1} > 7 )); then
				echo "File is incorretly configured"
				exit ${CONFIG}
			fi
		done
	fi
fi

CONF_FOLDER=${CONF_FOLDER:-${NZBPO_FOLDER_PERMISSION:-${FOLDER_PERMISSION}}}
if [[ ! -z "${CONF_FOLDER}" ]]; then
	if [[ ! "${CONF_FOLDER}" =~ ^-?[0-9]+$ ]] || (( ${#CONF_FOLDER} > 4 || ${#CONF_FOLDER} < 3 )); then
		echo "Folder is incorretly configured"
		exit ${CONFIG}
	else
		for ((i = 0; i < ${#CONF_FOLDER}; i++)); do
			if (( ${CONF_FOLDER:${i}:1} < 0 || ${CONF_FOLDER:${i}:1} > 7 )); then
				echo "Folder is incorretly configured"
				exit ${CONFIG}
			fi
		done
	fi
fi

CONF_BACKGROUND=${CONF_BACKGROUND:-${NZBPO_BACKGROUND:-${BACKGROUND}}}
: "${CONF_BACKGROUND:=false}"
CONF_BACKGROUND=${CONF_BACKGROUND,,}
case "${CONF_BACKGROUND}" in
	true) ;;
	false) ;;
	*) echo "Background is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_PROCESSES=${CONF_PROCESSES:-${NZBPO_PROCESSES:-${PROCESSES}}}
: "${CONF_PROCESSES:=ffmpeg}"
readarray -t CONF_PROCESSES <<< "$(echo "${CONF_PROCESSES}" | sed 's/,\ /\n/g' | sed 's/,/\n/g')"
if [[ ! "${CONF_PROCESSES[*]}" =~ "ffmpeg" ]]; then
	CONF_PROCESSES+=("ffmpeg")
fi

if (( ${#PROCESS[@]} == 0 )); then
	usage
fi

background() {
	echo "Running in background mode..."
	if hash getconf; then
		HZ=$(getconf CLK_TCK)
	fi
	: "${HZ:=100}"
	while kill -0 "${CONVERTER}" &>/dev/null; do
		validate
		if [[ -e "${BACKGROUNDMANAGER}" ]]; then
			source "${BACKGROUNDMANAGER}"
		else
			M4VCONVERTER=()
		fi
		TOGGLE=false
		for PROCESS in "${CONF_PROCESSES[@]}"; do
			if [[ -z "${PROCESS}" ]]; then
				continue
			fi
			readarray -t PIDS <<< "$(pgrep ^"${PROCESS}")"
			for PID in "${PIDS[@]}"; do
				if [[ -z "${PID}" ]]; then
					continue
				fi
				if [[ "${PROCESS}" == "ffmpeg" ]]; then
					if (( ${#PIDS[@]} == 1 )); then
						continue
					fi
					UPTIME=$(awk '{print($1)}' < "/proc/uptime")
					CONVERTERELAPSED=$(( ${UPTIME%.*} - $(awk '{print($22)}' < "/proc/${CONVERTER}/stat") / HZ ))
					PIDELAPSED=$(( ${UPTIME%.*} - $(awk '{print($22)}' < "/proc/${PID}/stat") / HZ ))
					if (( CONVERTERELAPSED > PIDELAPSED )); then
						PARENT=$(awk '{print($4)}' < "/proc/${PID}/stat")
						if grep -q $(basename "${0}") "/proc/${PARENT}/cmdline"; then
							continue
						fi
					elif (( CONVERTERELAPSED == PIDELAPSED )); then
						if [[ ! -z "${M4VCONVERTER[*]}" ]]; then
							SKIP=false
							for APP in "${M4VCONVERTER[@]}"; do
								if [[ -z "${APP}" ]]; then
									continue
								fi
								if [[ "${APP}" == "${PID}" ]]; then
									SKIP=true
									break
								fi
							done
							if ${SKIP}; then
								continue
							fi
						else
							continue
						fi
					fi
				fi
				PROCESS="${PROCESS}"
				PID="${PID}"
				TOGGLE=true
				break
			done
			if ${TOGGLE}; then
				break
			fi
		done
		STATE=$(awk '{print($3)}' < "/proc/${CONVERTER}/stat")
		if ${TOGGLE}; then
			if [[ "${STATE}" == "R" ]] || [[ "${STATE}" == "S" ]]; then
				echo "Detected running process ${PROCESS}; pid=${PID}"
				echo "Pausing..."
				kill -STOP "${CONVERTER}"
			fi
		else
			if [[ "${STATE}" == "T" ]]; then
				echo "Resuming..."
				kill -CONT "${CONVERTER}"
			fi
		fi
		sleep 5
	done
}

formatDate() {
	case "${OSTYPE}" in
		linux*) date -d @"${1}" -u +%H:%M:%S ;;
		darwin*) date -r "${1}" -u +%H:%M:%S ;;
	esac
}

progress() {
	START=$(date +%s) PROGRESSED=false CURRENTFRAME=0 PERCENTAGE=0 RATE=0 ETA=0 ELAPSED=0
	TOTALFRAMES=${2} FRAME=0 OLDPERCENTAGE=0
	case ${1} in
		1) local TYPE="Converting" ;;
		2) local TYPE="Normalizing" ;;
	esac
	while kill -0 "${CONVERTER}" &>/dev/null; do
		sleep 2
		if [[ -e "${STATSFILE}" ]]; then
			FRAME=$(tail -n 11 "${STATSFILE}" 2>&1 | grep -m 1 -x 'frame=.*' | sed -E 's/[^0-9]//g')
			if (( FRAME > CURRENTFRAME )); then
				CURRENTFRAME=${FRAME}
				PERCENTAGE=$(( 100 * CURRENTFRAME / TOTALFRAMES ))
			fi
			if (( PERCENTAGE > OLDPERCENTAGE )); then
				OLDPERCENTAGE=${PERCENTAGE}
				ELAPSED=$(( $(date +%s) - START ))
				RATE=$(( TOTALFRAMES / ELAPSED ))
				ETA=$(awk "BEGIN{print int((${ELAPSED} / ${CURRENTFRAME}) * (${TOTALFRAMES} - ${CURRENTFRAME}))}")
				echo "${TYPE}... ${PERCENTAGE}% ETA: $(formatDate "${ETA}")"
				PROGRESSED=true
			fi
			if (( PERCENTAGE == 99 )); then
				echo "Finishing up, this may take a moment..."
				break
			fi
		fi
	done
	if ${PROGRESSED}; then
		ELAPSED=$(formatDate "${ELAPSED}")
	fi
}

VALID=() success=false failure=false skipped=false
for process in "${PROCESS[@]}"; do
	if [[ -z "${process}" ]]; then
		continue
	fi
	if [[ ! -e "${process}" ]] || [[ "${process}" == / ]]; then
		echo "${process} is not a valid file or directory"
		continue
	fi
	VALID+=("${process}")
done

CURRENTDIRECTORY=0
for valid in "${VALID[@]}"; do
	if [[ -z "${valid}" ]]; then
		continue
	fi
	((CURRENTDIRECTORY++))
	if [[ -d "${valid}" ]]; then
		echo "Processing directory[${CURRENTDIRECTORY} of ${#VALID[@]}]: ${valid}"
	fi
	readarray -t files <<< "$(find "${valid}" -type f)"
	CURRENTFILE=0
	for file in "${files[@]}"; do
		if [[ -z "${file}" ]]; then
			continue
		fi
		((CURRENTFILE++))
		skip=true
		DIRECTORY=$(path "${file}")
		FILE_NAME="$(basename "${file}")"
		file="${DIRECTORY}/${FILE_NAME}"
		case "${file,,}" in
			*.mkv | *.mp4 | *.m4v | *.avi | *.wmv | *.xvid | *.divx | *.mpg | *.mpeg)
				echo "Processing file[${CURRENTFILE} of ${#files[@]}]: ${file}"
			;;
			*.srt | *.tmp | *.stats) continue ;;
			*)
				if [[ "$(${CONF_FFPROBE} "${file}" 2>&1)" =~ "Invalid data found when processing input" ]]; then
					echo "File is not convertable" && continue
				else
					echo "File does not have the expected extension, attempting..."
				fi
			;;
		esac
		if lsof "${file}" 2>&1 | grep -q COMMAND &>/dev/null; then
			echo "File is in use"
			skipped=true && continue
		fi
		if [[ "${FILE_NAME}" == "${FILE_NAME##*.}" ]]; then
			newname="${FILE_NAME}.${CONF_EXTENSION}"
		else
			newname="${FILE_NAME//${FILE_NAME##*.}/${CONF_EXTENSION}}"
		fi
		if [[ "${FILE_NAME}" != "${newname}" ]]; then
			skip=false
		fi
		DIRECTORY="${CONF_OUTPUT:-${DIRECTORY}}"
		newfile="${DIRECTORY}/${newname}"
		tmpfile="${newfile}.tmp"
		if [[ -e "${tmpfile}" ]]; then
			rm -f "${tmpfile}"
		fi
		command="${CONF_FFMPEG} -threads ${CONF_THREADS} -i \"${file}\""
		data="$(${CONF_FFPROBE} "${file}" 2>&1)"
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
		DRM=false
		for ((i = 0; i < ${#video[@]}; i++)); do
			if [[ -z "${video[${i}]}" ]]; then
				continue
			fi
			videodata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams v:${i} 2>&1)
			if [[ "${videodata,,}" =~ "drm" ]]; then
				echo "File is DRM Protected"
				DRM=true && break
			fi
		done
		if ${DRM}; then
			continue
		fi
		filtered=()
		for ((i = 0; i < ${#video[@]}; i++)); do
			if [[ -z "${video[${i}]}" ]]; then
				continue
			fi
			if (( $(${CONF_FFPROBE} "${file}" -v quiet -select_streams v:${i} -show_entries stream_disposition=attached_pic -of default=nokey=1:noprint_wrappers=1) == 1 )); then
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
			videodata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams v:${i} 2>&1)
			videomap=$(echo "${video[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*|\[.*//g')
			videocodec=$(echo "${videodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
			if [[ "${videocodec}" != "${CONF_ENCODER_NAME}" ]]; then
				convert=true
			fi
			profile=false
			if [[ "${CONF_PROFILE}" != "*" ]] && [[ "${CONF_ENCODER_NAME}" == "h264" ]]; then
				videoprofile=$(echo "${videodata}" | grep -x 'profile=.*' | sed 's/profile=//g')
				if ! [[ "${videoprofile,,}" =~ "constrained" ]]; then
					if [[ "${videoprofile,,}" != "${CONF_PROFILE}" ]]; then
						convert=true
						profile=true
					fi
				fi
			fi
			level=false
			if [[ "${CONF_LEVEL}" != "*" ]] && [[ "${CONF_ENCODER_NAME}" == "h264" ]]; then
				videolevel=$(echo "${videodata}" | grep -x 'level=.*' | sed -E 's/[^0-9]//g')
				if (( videolevel < 30 )) || (( videolevel > ${CONF_LEVEL//./} )); then
					convert=true
					level=true
				fi
			fi
			limit=false
			if (( CONF_VIDEOBITRATE > 0 )); then
				videobitrate=$(echo "${videodata}" | grep -x 'bit_rate=.*' | sed -E 's/[^0-9]//g')
				if (( videobitrate == 0 )); then
					globalbitrate=$(${CONF_FFPROBE} "${file}" -v quiet -show_entries format=bit_rate -of default=nokey=1:noprint_wrappers=1 | sed -E 's/[^0-9]//g')
					if (( globalbitrate > 0 )); then
						for ((a = 0; a < ${#audio[@]}; a++)); do
							bitrate=$(${CONF_FFPROBE} "${file}" -v quiet -select_streams a:${a} -show_entries stream=bit_rate -of default=nokey=1:noprint_wrappers=1 | sed -E 's/[^0-9]//g')
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
					videowidth=$(echo "${videodata}" | grep -x 'width=.*' | sed -E 's/[^0-9]//g')
					if (( videowidth > scale )); then
						convert=true
						resize=true
					fi
				fi
			fi
			pixel=false
			videopixel=$(echo "${videodata}" | grep -x 'pix_fmt=.*' | sed 's/pix_fmt=//g')
			if ! [[ "${videopixel}" =~ "yuv420p" ]]; then
				convert=true
				pixel=true
			fi
			if ${CONF_VERBOSE}; then
				total=$(echo "${videodata}" | grep -x 'nb_frames=.*' | sed -E 's/[^0-9]//g')
				if [[ -z "${total}" ]]; then
					fps=$(echo "${data}" | sed -n "s/.*, \\(.*\\) fps.*/\\1/p")
					dur=$(echo "${data}" | sed -n "s/.* Duration: \\([^,]*\\), .*/\\1/p" | awk -F ':' '{print $1*3600+$2*60+$3}')
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
			if ${CONF_FORCE_VIDEO}; then
				convert=true
			fi
			if ${convert}; then
				command+=" -map ${videomap} -c:v:${x} ${CONF_ENCODER}"
				if ${resize}; then
					command+=" -filter_complex \"[${videomap}]scale=${scale}:trunc(ow/a/2)*2\""
				fi
				command+=" -preset:${x} ${CONF_PRESET}"
				if ${profile}; then
					command+=" -profile:v:${x} ${CONF_PROFILE}"
				fi
				if ${pixel}; then
					command+=" -pix_fmt:${x} yuv420p"
				fi
				if ${level}; then
					command+=" -level:${x} ${CONF_LEVEL}"
				fi
				command+=" -crf:${x} ${CONF_CRF}"
				if ${limit}; then
					command+=" -maxrate:${x} ${CONF_VIDEOBITRATE}k -bufsize:${x} $(( CONF_VIDEOBITRATE * 2 ))k"
				fi
				skip=false
			else
				command+=" -map ${videomap} -c:v:${x} copy"
			fi
			if ! [[ -z "${CONF_DEFAULTLANGUAGE}" ]] && [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
				videolang=$(echo "${videodata,,}" | grep -i "TAG:LANGUAGE=" | sed 's/tag:language=//g')
				if [[ -z "${videolang}" ]] || [[ "${videolang}" == "und" ]] || [[ "${videolang}" == "unk" ]]; then
					videolang="${CONF_DEFAULTLANGUAGE}"
					skip=false
				fi
				if ! [[ -z "${videolang}" ]]; then
					command+=" -metadata:s:v:${x} \"language=${videolang}\""
				fi
			fi
			((x++))
		done
		filtered=()
		for ((i = 0; i < ${#audio[@]}; i++)); do
			if [[ -z "${audio[${i}]}" ]]; then
				continue
			fi
			audiodata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams a:${i} 2>&1)
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
		audiostreams=()
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
			audiodata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams a:${i} 2>&1)
			audiolang=$(echo "${audiodata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
			if [[ -z "${audiolang}" ]] || [[ "${audiolang}" == "und" ]] || [[ "${audiolang}" == "unk" ]]; then
				audiolang="${CONF_DEFAULTLANGUAGE}"
			fi
			audiocodec=$(echo "${audiodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
			audiochannels=$(echo "${audiodata}" | grep -x 'channels=.*' | sed -E 's/[^0-9]//g')
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
						audiodata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams a:${a} 2>&1)
						lang=$(echo "${audiodata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
						if [[ -z "${lang}" ]] || [[ "${lang}" == "und" ]] || [[ "${lang}" == "unk" ]]; then
							lang="${CONF_DEFAULTLANGUAGE}"
						fi
						if [[ "${lang}" != "${audiolang}" ]]; then
							continue
						fi
						audiocodec=$(echo "${audiodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
						audioprofile=$(echo "${audiodata}" | grep -x 'profile=.*' | sed 's/profile=//g')
						audiochannels=$(echo "${audiodata}" | grep -x 'channels=.*' | sed -E 's/[^0-9]//g')
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
						audiodata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams a:${a} 2>&1)
						lang=$(echo "${audiodata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
						if [[ -z "${lang}" ]] || [[ "${lang}" == "und" ]] || [[ "${lang}" == "unk" ]]; then
							lang="${CONF_DEFAULTLANGUAGE}"
						fi
						if [[ "${lang}" != "${audiolang}" ]]; then
							continue
						fi
						audiocodec=$(echo "${audiodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
						audioprofile=$(echo "${audiodata}" | grep -x 'profile=.*' | sed 's/profile=//g')
						audiochannels=$(echo "${audiodata}" | grep -x 'channels=.*' | sed -E 's/[^0-9]//g')
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
					audiolang=$(${CONF_FFPROBE} "${file}" -v quiet -select_streams a:${i} -show_entries stream_tags=language -of default=nokey=1:noprint_wrappers=1)
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
		if [[ ! -z "${streams[*]}" ]] && [[ "${audiostreams[*]}" != "${streams[*]}" ]]; then
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
					audiodata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams a:${i} 2>&1)
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
			if [[ ! -z "${streams[*]}" ]] && [[ "${audiostreams[*]}" != "${streams[*]}" ]]; then
				audiostreams=("${streams[@]}")
				skip=false
			fi
		fi
		x=0
		NORMALIZE=()
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
				audiodata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams a:${i} 2>&1)
				audiomap=$(echo "${audio[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*|\[.*//g')
				audiocodec=$(echo "${audiodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
				audioprofile=$(echo "${audiodata}" | grep -x 'profile=.*' | sed 's/profile=//g')
				audiochannels=$(echo "${audiodata}" | grep -x 'channels=.*' | sed -E 's/[^0-9]//g')
				audiolang=$(echo "${audiodata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
				if ! [[ -z "${CONF_DEFAULTLANGUAGE}" ]] && [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
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
						if ${CONF_FORCE_AUDIO}; then
							if [[ "${audiocodec}" == "aac" ]]; then
								command+=" -map ${audiomap} -c:a:${x} aac"
								if (( audiochannels > 2 )); then
									command+=" -ac:a:${x} 2"
									if (( audiobitrate > 128000 )); then
										command+=" -ab:a:${x} 128k"
									fi
								fi
								skip=false
							elif [[ "${audiocodec}" == "ac3" ]]; then
								command+=" -map ${audiomap} -c:a:${x} ac3"
								if (( audiochannels > 6 )); then
									command+=" -ac:a:${x} 6"
								fi
								skip=false
							fi
						else
							command+=" -map ${audiomap} -c:a:${x} copy"
							if [[ "${audiocodec}" == "aac" ]]; then
								if ${CONF_FORCE_NORMALIZE}; then
									NORMALIZE+=("${x}")
								fi
							fi
						fi
					else
						if [[ "${audiocodec}" == "aac" ]]; then
							if [[ "${audioprofile}" == "LC" ]]; then
								if (( audiochannels > 2 )) || ${CONF_FORCE_AUDIO}; then
									command+=" -map ${audiomap} -c:a:${x} aac -ac:a:${x} 2"
									NORMALIZE+=("${x}")
									if (( audiobitrate > 128000 )); then
										command+=" -ab:a:${x} 128k"
									fi
									if ! [[ -z "${audiolang}" ]]; then
										command+=" -metadata:s:a:${x} \"language=${audiolang}\""
									fi
									((x++))
									command+=" -map ${audiomap} -c:a:${x} ac3"
									if (( audiochannels > 6 )); then
										command+=" -ac:a:${x} 6"
									fi
									skip=false
								else
									command+=" -map ${audiomap} -c:a:${x} copy"
									if ${CONF_FORCE_NORMALIZE}; then
										NORMALIZE+=("${x}")
									fi
								fi
							else
								command+=" -map ${audiomap} -c:a:${x} aac"
								if (( audiochannels > 2 )); then
									command+=" -ac:a:${x} 2"
									NORMALIZE+=("${x}")
									if (( audiobitrate > 128000 )); then
										command+=" -ab:a:${x} 128k"
									fi
									if ! [[ -z "${audiolang}" ]]; then
										command+=" -metadata:s:a:${x} \"language=${audiolang}\""
									fi
									((x++))
									command+=" -map ${audiomap} -c:a:${x} ac3"
									if (( audiochannels > 6 )); then
										command+=" -ac:a:${x} 6"
									fi
								else
									if (( audiobitrate > 128000 )); then
										command+=" -ab:a:${x} 128k"
									fi
									if ${CONF_FORCE_NORMALIZE}; then
										NORMALIZE+=("${x}")
									fi
								fi
								skip=false
							fi
						elif [[ "${audiocodec}" == "ac3" ]]; then
							command+=" -map ${audiomap} -c:a:${x} aac"
							if (( audiochannels > 2 )); then
								command+=" -ac:a:${x} 2"
								NORMALIZE+=("${x}")
								if (( audiobitrate > 128000 )); then
									command+=" -ab:a:${x} 128k"
								fi
								if ! [[ -z "${audiolang}" ]]; then
									command+=" -metadata:s:a:${x} \"language=${audiolang}\""
								fi
								((x++))
								if (( audiochannels > 6 )) || ${CONF_FORCE_AUDIO}; then
									command+=" -map ${audiomap} -c:a:${x} ac3 -ac:a:${x} 6"
								else
									command+=" -map ${audiomap} -c:a:${x} copy"
								fi
							else
								if (( audiobitrate > 128000 )); then
									command+=" -ab:a:${x} 128k"
								fi
								if ${CONF_FORCE_NORMALIZE}; then
									NORMALIZE+=("${x}")
								fi
							fi
							skip=false
						else
							command+=" -map ${audiomap} -c:a:${x} aac"
							if (( audiochannels > 2 )); then
								command+=" -ac:a:${x} 2"
								NORMALIZE+=("${x}")
								if (( audiobitrate > 128000 )); then
									command+=" -ab:a:${x} 128k"
								fi
								if ! [[ -z "${audiolang}" ]]; then
									command+=" -metadata:s:a:${x} \"language=${audiolang}\""
								fi
								((x++))
								command+=" -map ${audiomap} -c:a:${x} ac3"
								if (( audiochannels > 6 )); then
									command+=" -ac:a:${x} 6"
								fi
							else
								if (( audiobitrate > 128000 )); then
									command+=" -ab:a:${x} 128k"
								fi
								if ${CONF_FORCE_NORMALIZE}; then
									NORMALIZE+=("${x}")
								fi
							fi
							skip=false
						fi
					fi
				else
					if [[ "${audiocodec}" == "aac" ]]; then
						if [[ "${audioprofile}" == "LC" ]]; then
							if (( audiochannels > 2 )) || ${CONF_FORCE_AUDIO}; then
								command+=" -map ${audiomap} -c:a:${x} aac -ac:a:${x} 2"
								if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
									command+=" -ab:a:${x} 128k"
								fi
								NORMALIZE+=("${x}")
								skip=false
							else
								command+=" -map ${audiomap} -c:a:${x} copy"
							fi
						else
							command+=" -map ${audiomap} -c:a:${x} aac"
							if (( audiochannels > 2 )); then
								NORMALIZE+=("${x}")
								command+=" -ac:a:${x} 2"
							fi
							if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
								command+=" -ab:a:${x} 128k"
							fi
							if ${CONF_FORCE_NORMALIZE}; then
								NORMALIZE+=("${x}")
							fi
							skip=false
						fi
					else
						command+=" -map ${audiomap} -c:a:${x} aac"
						if (( audiochannels > 2 )); then
							NORMALIZE+=("${x}")
							command+=" -ac:a:${x} 2"
						fi
						if (( audiobitrate > 128000 )) || (( audiobitrate == 0 )); then
							command+=" -ab:a:${x} 128k"
						fi
						if ${CONF_FORCE_NORMALIZE}; then
							NORMALIZE+=("${x}")
						fi
						skip=false
					fi
				fi
				if ! [[ -z "${audiolang}" ]]; then
					command+=" -metadata:s:a:${x} \"language=${audiolang}\""
				fi
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
			if (( $(${CONF_FFPROBE} "${file}" -v quiet -select_streams a:${i} -show_entries stream_disposition=default -of default=nokey=1:noprint_wrappers=1) == 1 )); then
			 	((x++))
			fi
		done
		if (( x > 1 )); then
			skip=false
		fi
		if [[ ${CONF_SUBTITLES} == "extract" ]] || ${CONF_SUBTITLES}; then
			filtered=()
			for ((i = 0; i < ${#subtitle[@]}; i++)); do
				if [[ -z "${subtitle[${i}]}" ]]; then
					continue
				fi
				subtitledata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams s:${i} 2>&1)
				subtitlelang=$(echo "${subtitledata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
				if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang}" == "und" ]] || [[ "${subtitlelang}" == "unk" ]]; then
					subtitlelang="${CONF_DEFAULTLANGUAGE}"
				fi
				forced=$(echo "${subtitledata}" | grep -x 'DISPOSITION:forced=.*' | sed -E 's/[^0-9]//g')
				if [[ ! -z "$(echo "${subtitledata}" | grep -i 'TAG:.*forced')" ]] || (( forced == 1 )); then
					filtered+=("${subtitle[${i}]}")
					continue
				fi
				subtitlecodec=$(echo "${subtitledata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
				if [[ "${subtitlecodec}" == hdmv_pgs_subtitle ]] || [[ "${subtitlecodec}" == pgssub ]] || [[ "${subtitlecodec}" == dvbsub ]]; then
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
				subtitledata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams s:${i} 2>&1)
				subtitlelang=$(echo "${subtitledata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
				if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang}" == "und" ]] || [[ "${subtitlelang}" == "unk" ]]; then
					subtitlelang="${CONF_DEFAULTLANGUAGE}"
				fi
				have=false
				for ((s = 0; s < ${#subtitlestreams[@]}; s++)); do
					if [[ -z "${subtitlestreams[${s}]}" ]]; then
						continue
					fi
					lang=$(${CONF_FFPROBE} "${file}" -v quiet -select_streams s:${s} -show_entries stream_tags=language -of default=nokey=1:noprint_wrappers=1)
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
						subtitlelang=$(${CONF_FFPROBE} "${file}" -v quiet -select_streams s:${i} -show_entries stream_tags=language -of default=nokey=1:noprint_wrappers=1)
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
			if [[ ! -z "${streams[*]}" ]] && [[ "${subtitlestreams[*]}" != "${streams[*]}" ]]; then
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
					subtitledata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams s:${i} 2>&1)
					subtitlemap=$(echo "${subtitle[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*|\[.*//g')
					subtitlelang=$(echo "${subtitledata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
					if ! [[ -z "${CONF_DEFAULTLANGUAGE}" ]] && [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
						if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang}" == "und" ]] || [[ "${subtitlelang}" == "unk" ]]; then
							subtitlelang="${CONF_DEFAULTLANGUAGE}"
							if [[ "${CONF_SUBTITLES}" != "extract" ]]; then
								skip=false
							fi
						fi
					fi
					if [[ "${CONF_SUBTITLES}" == "extract" ]]; then
						SRTFILE="${DIRECTORY}/${FILE_NAME%.*}.${subtitlelang}.srt"
						if [[ -e "${SRTFILE}" ]]; then
							echo "Unable to extract (${subtitlelang}) subtitle, file already exists"
						else
							EXTRACT_COMMAND="${CONF_FFMPEG} -i \"${file}\" -vn -an -map ${subtitlemap} -c:s:${x} srt \"${SRTFILE}\""
							((x++))
							if ${CONF_VERBOSE}; then
								echo "VERBOSE: ${EXTRACT_COMMAND}"
							fi
							if ${CONF_DEBUG}; then
								continue
							fi
							echo "Extracting..."
							TMPFILES+=("${SRTFILE}")
							eval "${EXTRACT_COMMAND} &" &>/dev/null
							CONVERTER=${!}
							wait ${CONVERTER} &>/dev/null
							if [[ ${?} -ne 0 ]]; then
								echo "Result: failure"
							else
								echo "Result: success"
								TMPFILES=("${TMPFILES[@]//${SRTFILE}/}")
							fi
						fi
					else
						subtitlecodec=$(echo "${subtitledata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
						if [[ "${subtitlecodec}" != "mov_text" ]] || ${CONF_FORCE_SUBTITLES}; then
							command+=" -map ${subtitlemap} -c:s:${x} mov_text"
							skip=false
						else
							command+=" -map ${subtitlemap} -c:s:${x} copy"
						fi
						if ! [[ -z "${subtitlelang}" ]]; then
							command+=" -metadata:s:s:${x} \"language=${subtitlelang}\""
						fi
						((x++))
					fi
				done
			done
			if [[ "${command}" =~ mov_text ]]; then
				command="${command//-i ${file}/-fix_sub_duration -i ${file}}"
			fi
		else
			if [[ ! -z "${subtitle[*]}" ]] && (( ${#subtitle[@]} > 0 )); then
				command+=" -sn"
				skip=false
			fi
		fi
		if [[ ! -z "$(${CONF_FFPROBE} "${file}" -v quiet -show_entries format_tags=title -of default=nokey=1:noprint_wrappers=1)" ]]; then
			skip=false
		fi
		if [[ ! -z "$(${CONF_FFPROBE} "${file}" -v quiet -show_chapters)" ]]; then
			skip=false
		fi
		if [[ "$(${CONF_FFPROBE} "${file}" -v quiet -show_entries format=format_name -of default=nokey=1:noprint_wrappers=1)" != "mov,mp4,m4a,3gp,3g2,mj2" ]]; then
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
		CONVERTER=${!}
		if ! ${CONF_BACKGROUND}; then
			if [[ -e "${BACKGROUNDMANAGER}" ]]; then
				source "${BACKGROUNDMANAGER}"
			fi
			M4VCONVERTER+=("${CONVERTER}")
			echo "M4VCONVERTER=(${M4VCONVERTER[*]})" > "${BACKGROUNDMANAGER}"
		else
			background &
		fi
		progress 1 "${total}"
		wait ${CONVERTER} &>/dev/null
		if [[ ${?} -ne 0 ]]; then
			echo "Result: failure"
			failure=true && clean && continue
		fi
		success=true
		echo "Result: success"
		if ${PROGRESSED}; then
			echo "Time taken: ${ELAPSED} at an average rate of ${RATE}fps"
		fi
		M4VCONVERTER=("${M4VCONVERTER[@]//${CONVERTER}/}")
		echo "M4VCONVERTER=(${M4VCONVERTER[*]})" > "${BACKGROUNDMANAGER}"
		if ${CONF_NORMALIZE} && [[ ! -z "${NORMALIZE[*]}" ]]; then
			echo "Checking audio levels..."
			normalizedfile="${tmpfile}.old" data="$(${CONF_FFPROBE} "${tmpfile}" 2>&1)" normalize=false
			command="${CONF_FFMPEG} -threads ${CONF_THREADS} -i \"${normalizedfile}\""
			readarray -t video <<< "$(echo "${data}" | grep 'Stream.*Video:' | sed 's/.*Stream/Stream/g')"
			for ((i = 0; i < ${#video[@]}; i++)); do
				if [[ -z "${video[${i}]}" ]]; then
					continue
				fi
				videomap=$(echo "${video[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*|\[.*//g')
				if ${CONF_VERBOSE}; then
					total=$(${CONF_FFPROBE} "${tmpfile}" -v quiet -select_streams v:${i} -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1)
					if [[ -z "${total}" ]]; then
						fps=$(echo "${data}" | sed -n "s/.*, \\(.*\\) fps.*/\\1/p")
						dur=$(echo "${data}" | sed -n "s/.* Duration: \\([^,]*\\), .*/\\1/p" | awk -F ':' '{print $1*3600+$2*60+$3}')
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
				for stream in "${NORMALIZE[@]}"; do
					if [[ -z "${stream}" ]]; then
						continue
					fi
					audiomap=$(echo "${audio[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*|\[.*//g')
					if [[ "${audio[${i}]}" != "${audio[${stream}]}" ]]; then
						command+=" -map ${audiomap} -c:a:${i} copy"
						continue
					fi
					audiocodec=$(echo "${audio[${i}]}" | awk '{print($4)}')
					if [[ "${audiocodec}" == *, ]]; then
						audiocodec=${audiocodec%?}
					fi
					dB=$(${CONF_FFMPEG} -i "${tmpfile}" -map "${audiomap}" -filter:a:${i} volumedetect -f null /dev/null 2>&1 | \
						grep 'max_volume:' | sed -E 's/\[.*\:|[^-\.0-9]//g')
					if [[ ! -z "${dB}" ]] && ! (( ${dB%.*} == 0 )); then
						if (( ${dB%.*} < 0 )); then
							dB=${dB//-/}
						elif (( ${dB%.*} > 0 )); then
							dB=-${dB}
						fi
						command+=" -map ${audiomap} -c:a:${i} ${audiocodec} -filter:a:${i} \"volume=${dB}dB\""
						normalize=true
					fi
				done
			done
			readarray -t subtitle <<< "$(echo "${data}" | grep 'Stream.*Subtitle:' | sed 's/.*Stream/Stream/g')"
			for ((i = 0; i < ${#subtitle[@]}; i++)); do
				if [[ -z "${subtitle[${i}]}" ]]; then
					continue
				fi
				subtitlemap=$(echo "${subtitle[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*|\[.*//g')
				command+=" -map ${subtitlemap} -c:s:${i} copy"
			done
			command+=" -f ${CONF_FORMAT} -flags +global_header -movflags +faststart -strict -2 -y \"${tmpfile}\""
			if ${normalize}; then
				mv "${tmpfile}" "${normalizedfile}"
				TMPFILES+=("${normalizedfile}")
				if ${CONF_VERBOSE}; then
					echo "VERBOSE: ${command}"
				fi
				echo "Normalizing..."
				eval "${command} &" &>/dev/null
				CONVERTER=${!}
				if ! ${CONF_BACKGROUND}; then
					if [[ -e "${BACKGROUNDMANAGER}" ]]; then
						source "${BACKGROUNDMANAGER}"
					fi
					M4VCONVERTER+=("${CONVERTER}")
					echo "M4VCONVERTER=(${M4VCONVERTER[*]})" > "${BACKGROUNDMANAGER}"
				else
					background &
				fi
				progress 2 "${total}"
				wait ${CONVERTER} &>/dev/null
				if [[ ${?} -eq 0 ]]; then
					echo "Result: success"
				else
					echo "Result: failure"
					rm -f "${tmpfile}"
					mv "${normalizedfile}" "${tmpfile}"
				fi
				if ${PROGRESSED}; then
					echo "Time taken: ${ELAPSED} at an average rate of ${RATE}fps"
				fi
				M4VCONVERTER=("${M4VCONVERTER[@]//${CONVERTER}/}")
				echo "M4VCONVERTER=(${M4VCONVERTER[*]})" > "${BACKGROUNDMANAGER}"
			fi
		fi
		echo "Conversion efficiency at $(( $(wc -c "${file}" 2>&1 | awk '{print($1)}') * -100 / $(wc -c "${tmpfile}" 2>&1 | awk '{print($1)}') ))%; Original=$(du -sh "${file}" 2>&1 | awk '{print($1)}')B; Converted=$(du -sh "${tmpfile}" 2>&1 | awk '{print($1)}')B"
		if ${CONF_DELETE}; then
			rm -f "${file}"
		fi
		mv "${tmpfile}" "${newfile}"
		if [[ ! -z "${CONF_FILE}" ]]; then
			chmod "${CONF_FILE}" "${newfile}"
		fi
		if [[ ! -z "${CONF_FOLDER}" ]]; then
			chmod "${CONF_FOLDER}" "${DIRECTORY}"
		fi
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
