#!/usr/bin/env bash

##############################################################################
### NZBGET SCAN/POST-PROCESSING SCRIPT                                     ###

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
# Prints extra details such as progress information and the FFmpeg command generated.
#Verbose=false

# Debug Mode (true, false).
# Prints generated FFmpeg command ONLY, useful for debugging.
#Debug=false

# Background Mode (true, false).
# Automatically pauses any active converting if a process (determined by Processes below) is found running.
#
# NOTE: To use this in Docker, please pass /tmp to the container like so -v /tmp:/tmp
#Background=false

# Number of Threads (*).
# This is how many threads FFMPEG will use for conversion.
#Threads=auto

# Preferred Languages (*).
# This is the language(s) you prefer.
#
# NOTE: This is used for audio and subtitles. The first listed is considered the default/preferred.
#
# NOTE: Selecting "*" will allow all languages.
#
# NOTE: Use 3 digit code language code, ISO 639-2.
#
# NOTE: http://bit.ly/2nT8wUj
#Languages=

# Video Encoder (H.264, H.265, *).
# This changes which encoder to use.
#
# NOTE: Selecting "*" will allow H.264 or H.265, defaulting to H.264.
#
# NOTE: H.264 offers siginificantly more compatbility with devices.
#
# NOTE: H.265 offers 50-75% more compression efficiency.
#Encoder=H.264

# Hardware Acceleration (intel, nvidia, mac, software).
# This allows for hardware acceleration using intel or nvidia gpus.
#
# NOTE: EXPERIMENTAL!!
# NOTE: To use nvidia you must install drivers and have a ffmpeg compiled with --enable-nvenc. Docker also requires nvidia-docker-runtime.
# NOTE: Hardware Acceleration typically scarifices quality for speed.
#Acceleration=software

# Video Preset (ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow).
# This controls encoding speed to compression ratio.
#
# NOTE: http://bit.ly/2QjAVz6
#Preset=medium

# Video Profile (baseline, main, high, *).
# This defines the features / capabilities that the encoder can use.
#
# NOTE: Selecting "*" will disable this check.
#
# NOTE: http://bit.ly/2JEzFnD
#Profile=main

# Video Level (3.0, 3.1, 3.2, 4.0, 4.1, 4.2, 5.0, 5.1, 5.2, *).
# This is another form of constraints that define things like maximum bitrates, framerates and resolution etc.
#
# NOTE: Selecting "*" will disable this check.
#
# NOTE: http://bit.ly/2ALg0Qa
#Level=4.1

# Force Video Level (true, false).
# This forces video level to the specified setting above.
#Force Level=false

# Video Constant Rate Factor (0-51).
# This controls maximum compression efficiency with a single pass.
#
# NOTE: http://bit.ly/2DmOsDd
#CRF=23

# Force Pixel Format (true, false).
# This forces pixel format to match yuv420p exactly, good for converting HEVC 10bit to 8bit.
#Force Pixel=false

# Video Resolution (*).
# This will resize the video maintaining aspect ratio.
#
# NOTE: Ex. 'SD, HD, 720p, 1920x1080, 4K'
#
# NOTE: http://bit.ly/2JDL0UR
#
# NOTE: Using this option MAY cause Radarr/Sonarr to need a manual import due to file quality not matching grabbed release
#Resolution=

# File/Directory Rename (true, false).
# This will rename the file/directory when resolution is changed.
#
# NOTE: Ex. 'Video.2018.4K.UHD.King' to 'Video.2018.1080p.King' (when using the above Video Resolution option)
#
# NOTE: You must allow the script to run as a global extension (applies to all nzbs in queue) for this to work on NZBGet.
#Rename=false

# Video Bitrate (KB).
# Use this to limit video bitrate, if exceeded then video will be converted and quality downgraded.
#
# NOTE: This value is in Kilobytes, Ex. '8192' (8 Mbps)
#Video Bitrate=

# Force Video Convert (true, false).
# Use this to force the video to convert, overriding all other checks.
#Force Video=false

# Create Dual Audio Streams (true, false).
# This will create two audio streams, if possible. AAC 2.0 and AC3 5.1.
#
# NOTE: AAC will be the default for better compatability with more devices.
#Dual Audio=false

# Force Audio Convert (true, false).
# Use this to force the audio to convert, overriding all other checks.
#Force Audio=false

# Normalize Audio (true, false).
# This will normalize audio if needed due to downmixing.
#Normalize=false

# Force Normalize (true, false).
# This will force check audio levels for all supported audio streams.
#Force Normalize=false

# Copy Subtitles (true, false, extract).
# This will copy/convert subtitles of your matching language(s) into the converted file or extract them into a srt file.
#Subtitles=true

# Force Subtitle Convert (true, false).
# Use this to force the subtitles to convert, overriding all other checks.
#Force Subtitle=false

# File Format (MP4, MOV).
# MP4 is better supported universally. MOV is best with Apple devices and iTunes.
#Format=mp4

# File Extension (MP4, M4V).
# The extension applied at the end of the file, such as video.mp4.
#Extension=mp4

# Delete Original File (true, false).
# If true then the original file will be deleted.
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

# Directory Permissions (*).
# This will set directory permissions in either decimal (493) or octal (leading zero: 0755).
#
# NOTE: http://permissions-calculator.org/
#Directory Permission=

# Cleanup Size (MB).
# Any file less than the specified size is deleted.
#
# NOTE: This helps to remove sample files
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

if ! [[ "${PATH}" =~ "/usr/local/bin" ]]; then
    PATH=/usr/local/bin:${PATH}
    bash "${0}" "${@}"
    exit ${?}
fi

if (( BASH_VERSINFO < 4 )); then
    echo "Sorry, you do not have Bash version 4 or later"
    exit ${DEPEND}
fi

BACKGROUNDMANAGER="/tmp/m4v.tmp"
TMPFILES+=("${BACKGROUNDMANAGER}")

force() {
    if (( CONVERTER > 0 )) && kill -0 "${CONVERTER}" &>/dev/null; then
        disown "${CONVERTER}"
        kill -9 "${CONVERTER}" &>/dev/null
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

usage() {
    local DIRECTORY=$(path ${0})
    if [[ -e "${DIRECTORY}" ]] && [[ -e "${DIRECTORY}/README.md" ]]; then
        cat "${DIRECTORY}/README.md"
    else
        echo "README.md file not found, please refer to it directly at https://github.com/Digiex/M4V-Converter/blob/master/README.md"
    fi
    exit ${CONFIG}
}

while getopts hvdi:o:c:b-: opts; do
    case ${opts,,} in
        h) usage ;;
        v) CONF_VERBOSE=true ;;
        d) CONF_DEBUG=true; CONF_VERBOSE=true ;;
        i) PROCESS+=("${OPTARG}") ;;
        o) CONF_OUTPUT="${OPTARG}" ;;
        c) CONFIG_FILE="${OPTARG}" ;;
        b) CONF_BACKGROUND=true ;;
        -) ARG="${OPTARG#*=}";
            case "${OPTARG,,}" in
                help) usage ;;
                ffmpeg=*) FFMPEG="${ARG}" ;;
                ffprobe=*) FFPROBE="${ARG}" ;;
                input=*) PROCESS+=("${ARG}") ;;
                output=*) CONF_OUTPUT="${ARG}" ;;
                config=*) CONFIG_FILE="${ARG}" ;;
                verbose) CONF_VERBOSE=true ;;
                debug) CONF_DEBUG=true; CONF_VERBOSE=true ;;
                threads=*) CONF_THREADS="${ARG}" ;;
                languages=*) CONF_LANGUAGES="${ARG}" ;;
                encoder=*) CONF_ENCODER="${ARG}" ;;
                acceleration=*) CONF_ACCELERATION="${ARG}" ;;
                preset=*) CONF_PRESET="${ARG}" ;;
                profile=*) CONF_PROFILE="${ARG}" ;;
                level=*) CONF_LEVEL="${ARG}" ;;
                force-level=*) CONF_FORCE_LEVEL="${ARG}" ;;
                crf=*) CONF_CRF="${ARG}" ;;
                force-pixel=*) CONF_FORCE_PIXEL="${ARG}" ;;
                resolution=*) CONF_RESOLUTION="${ARG}" ;;
                rename=*) CONF_RENAME="${ARG}" ;;
                video-bitrate=*) CONF_VIDEOBITRATE="${ARG}" ;;
                force-video=*) CONF_FORCE_VIDEO="${ARG}" ;;
                dual-audio=*) CONF_DUALAUDIO="${ARG}" ;;
                force-audio=*) CONF_FORCE_AUDIO="${ARG}" ;;
                normalize=*) CONF_NORMALIZE="${ARG}" ;;
                force-normalize=*) CONF_FORCE_NORMALIZE="${ARG}" ;;
                subtitles=*) CONF_SUBTITLES="${ARG}" ;;
                force-subtitles=*) CONF_FORCE_SUBTITLES="${ARG}" ;;
                format=*) CONF_FORMAT="${ARG}" ;;
                extension=*) CONF_EXTENSION="${ARG}" ;;
                delete=*) CONF_DELETE="${ARG}" ;;
                file-permission=*) CONF_FILE="${ARG}" ;;
                directory-permission=*) CONF_DIRECTORY="${ARG}" ;;
                background=*) CONF_BACKGROUND="${ARG}" ;;
                processes=*) CONF_PROCESSES="${ARG}" ;;
                *) usage ;;
            esac
        ;;
        *) usage ;;
    esac
done

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

CONF_FFPROBE=${CONF_FFPROBE:-${NZBPO_FFPROBE:-${FFPROBE}}}
: "${CONF_FFPROBE:=ffprobe}"
if ! hash "${CONF_FFPROBE}" 2>/dev/null; then
    echo "Sorry, you do not have FFprobe"
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
    true|false) ;;
    *) echo "Verbose is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_DEBUG=${CONF_DEBUG:-${NZBPO_DEBUG:-${DEBUG}}}
: "${CONF_DEBUG:=false}"
CONF_DEBUG=${CONF_DEBUG,,}
case "${CONF_DEBUG}" in
    true|false) ;;
    *) echo "Debug is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_THREADS=${CONF_THREADS:-${NZBPO_THREADS:-${THREADS}}}
: "${CONF_THREADS:=auto}"
CONF_THREADS=${CONF_THREADS,,}
if [[ "${CONF_THREADS}" != "auto" ]]; then
    case "${OSTYPE}" in
        linux*) MAX_CORES="$(nproc)" ;;
        darwin*) MAX_CORES="$(sysctl -n hw.ncpu)" ;;
    esac
    if [[ ! "${CONF_THREADS}" =~ ^-?[0-9]+$ ]] || (( "${CONF_THREADS}" == 0 || "${CONF_THREADS}" > MAX_CORES )); then
        echo "Threads is incorrectly configured"
        exit ${CONFIG}
    fi
fi

CONF_LANGUAGES="${CONF_LANGUAGES:-${NZBPO_LANGUAGES:-${LANGUAGES}}}"
: "${CONF_LANGUAGES:=unk}"
CONF_LANGUAGES="${CONF_LANGUAGES,,}"
read -r -a CONF_LANGUAGES <<< "$(echo "${CONF_LANGUAGES}" | sed 's/\ //g' | sed 's/,/\ /g')"
CONF_DEFAULTLANGUAGE="${CONF_LANGUAGES[0]}"
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
CONF_ENCODER=${CONF_ENCODER,,}
case "${CONF_ENCODER}" in
    h.264|h264|x264|libx264) CONF_ENCODER_NAME="h264"; CONF_ENCODER="libx264" ;;
    h.265|h265|x265|hevc|libx265) CONF_ENCODER_NAME="hevc"; CONF_ENCODER="libx265" ;;
    "*") ;;
    *) echo "Encoder is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_ACCELERATION=${CONF_ACCELERATION:-${NZBPO_ACCELERATION:-${ACCELERATION}}}
: "${CONF_ACCELERATION:=software}"
CONF_ACCELERATION=${CONF_ACCELERATION,,}
case "${CONF_ACCELERATION}" in
    intel)
        if [[ "${CONF_ENCODER}" == "libx265" ]]; then
            CONF_ENCODER="hevc_vaapi"
        else
            CONF_ENCODER="h264_vaapi"
        fi
    ;;
    nvidia)
        if [[ "${CONF_ENCODER}" == "libx265" ]]; then
            CONF_ENCODER="nvenc_hevc"
        else
            CONF_ENCODER="h264_nvenc"
        fi
    ;;
    mac)
        if [[ "${CONF_ENCODER}" == "libx265" ]]; then
            CONF_ENCODER="hevc_videotoolbox"
        else
            CONF_ENCODER="h264_videotoolbox"
        fi
    ;;
    software) ;;
    *) echo "Acceleration is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_PRESET=${CONF_PRESET:-${NZBPO_PRESET:-${PRESET}}}
: "${CONF_PRESET:=medium}"
CONF_PRESET=${CONF_PRESET,,}
case "${CONF_PRESET}" in
    ultrafast|superfast|veryfast|faster|fast|medium|slow|slower|veryslow) ;;
    *) echo "Preset is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_PROFILE=${CONF_PROFILE:-${NZBPO_PROFILE:-${PROFILE}}}
: "${CONF_PROFILE:=main}"
CONF_PROFILE=${CONF_PROFILE,,}
case "${CONF_PROFILE}" in
    baseline|main|high|"*") ;;
    *) echo "Profile is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_LEVEL=${CONF_LEVEL:-${NZBPO_LEVEL:-${LEVEL}}}
: "${CONF_LEVEL:=4.1}"
CONF_LEVEL=${CONF_LEVEL,,}
case "${CONF_LEVEL}" in
    3.0|3.1|3.2|4.0|4.1|4.2|5.0|5.1|5.2|"*") ;;
    *) echo "Level is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_FORCE_LEVEL=${CONF_FORCE_LEVEL:-${NZBPO_FORCE_LEVEL:-${FORCE_LEVEL}}}
: "${CONF_FORCE_LEVEL:=false}"
CONF_FORCE_LEVEL=${CONF_FORCE_LEVEL,,}
case "${CONF_FORCE_LEVEL}" in
    true|false) ;;
    *) echo "Force Level is incorrectly configured"; exit ${CONFIG} ;;
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

CONF_FORCE_PIXEL=${CONF_FORCE_PIXEL:-${NZBPO_FORCE_PIXEL:-${FORCE_PIXEL}}}
: "${CONF_FORCE_PIXEL:=false}"
CONF_FORCE_PIXEL=${CONF_FORCE_PIXEL,,}
case "${CONF_FORCE_PIXEL}" in
    true|false) ;;
    *) echo "Force Pixel is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_RESOLUTION=${CONF_RESOLUTION:-${NZBPO_RESOLUTION:-${RESOLUTION}}}
CONF_RESOLUTION=${CONF_RESOLUTION,,}
if [[ ! -z "${CONF_RESOLUTION}" ]]; then
    case "${CONF_RESOLUTION,,}" in
        480p|sd) CONF_RESOLUTION=640x480; OPTIONAL+=("sd") ;;
        720p|hd) CONF_RESOLUTION=1280x720; OPTIONAL+=("hd") ;;
        1080p) CONF_RESOLUTION=1920x1080 ;;
        1440p|2k) CONF_RESOLUTION=2560x1440; OPTIONAL+=("2k") ;;
        2160p|4k|uhd) CONF_RESOLUTION=3840x2160; OPTIONAL+=("4k"); OPTIONAL+=("uhd") ;;
    esac
    if [[ ! "${CONF_RESOLUTION}" =~ [x|:] ]] || [[ ! "${CONF_RESOLUTION//[x|:]/}" =~ ^-?[0-9]+$ ]]; then
        echo "Resolution is incorrectly configured"
        exit ${CONFIG}
    fi
    WIDTH=${CONF_RESOLUTION//[x|:]*/}
    HEIGHT=${CONF_RESOLUTION//*[x|:]/}
    if (( WIDTH < HEIGHT )); then
        WIDTH=${CONF_RESOLUTION//*[x|:]/}
        HEIGHT=${CONF_RESOLUTION//[x|:]*/}
    fi
fi

CONF_RENAME=${CONF_RENAME:-${NZBPO_RENAME:-${RENAME}}}
: "${CONF_RENAME:=false}"
CONF_RENAME=${CONF_RENAME,,}
case "${CONF_RENAME}" in
    true|false) ;;
    *) echo "Rename is incorrectly configured"; exit ${CONFIG} ;;
esac

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
    true|false) ;;
    *) echo "Force Video is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_DUALAUDIO=${CONF_DUALAUDIO:-${NZBPO_DUAL_AUDIO:-${DUAL_AUDIO}}}
: "${CONF_DUALAUDIO:=false}"
CONF_DUALAUDIO=${CONF_DUALAUDIO,,}
case "${CONF_DUALAUDIO}" in
    true|false) ;;
    *) echo "Dual Audio is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_FORCE_AUDIO=${CONF_FORCE_AUDIO:-${NZBPO_FORCE_AUDIO:-${FORCE_AUDIO}}}
: "${CONF_FORCE_AUDIO:=false}"
CONF_FORCE_AUDIO=${CONF_FORCE_AUDIO,,}
case "${CONF_FORCE_AUDIO}" in
    true|false) ;;
    *) echo "Force Audio is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_NORMALIZE=${CONF_NORMALIZE:-${NZBPO_NORMALIZE:-${NORMALIZE}}}
: "${CONF_NORMALIZE:=false}"
CONF_NORMALIZE=${CONF_NORMALIZE,,}
case "${CONF_NORMALIZE}" in
    true|false) ;;
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
    true|false|extract) ;;
    *) echo "Subtitles is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_FORCE_SUBTITLES=${CONF_FORCE_SUBTITLES:-${NZBPO_FORCE_SUBTITLES:-${FORCE_SUBTITLES}}}
: "${CONF_FORCE_SUBTITLES:=false}"
CONF_FORCE_SUBTITLES=${CONF_FORCE_SUBTITLES,,}
case "${CONF_FORCE_SUBTITLES}" in
    true|false) ;;
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
: "${CONF_EXTENSION:=mp4}"
CONF_EXTENSION=${CONF_EXTENSION,,}
if [[ "${CONF_EXTENSION}" != "mp4" ]] && [[ "${CONF_EXTENSION}" != "m4v" ]]; then
    echo "Extension is incorrectly configured"
    exit ${CONFIG}
fi

CONF_DELETE=${CONF_DELETE:-${NZBPO_DELETE:-${DELETE}}}
: "${CONF_DELETE:=false}"
CONF_DELETE=${CONF_DELETE,,}
case "${CONF_DELETE}" in
    true|false) ;;
    *) echo "Delete is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_FILE=${CONF_FILE:-${NZBPO_FILE_PERMISSION:-${FILE_PERMISSION}}}
if [[ ! -z "${CONF_FILE}" ]]; then
    if [[ ! "${CONF_FILE}" =~ ^-?[0-9]+$ ]] || (( ${#CONF_FILE} > 4 || ${#CONF_FILE} < 3 )); then
        echo "File is incorrectly configured"
        exit ${CONFIG}
    else
        for ((i = 0; i < ${#CONF_FILE}; i++)); do
            if (( ${CONF_FILE:${i}:1} < 0 || ${CONF_FILE:${i}:1} > 7 )); then
                echo "File is incorrectly configured"
                exit ${CONFIG}
            fi
        done
    fi
fi

CONF_DIRECTORY=${CONF_DIRECTORY:-${NZBPO_DIRECTORY_PERMISSION:-${DIRECTORY_PERMISSION}}}
if [[ ! -z "${CONF_DIRECTORY}" ]]; then
    if [[ ! "${CONF_DIRECTORY}" =~ ^-?[0-9]+$ ]] || (( ${#CONF_DIRECTORY} > 4 || ${#CONF_DIRECTORY} < 3 )); then
        echo "Directory is incorrectly configured"
        exit ${CONFIG}
    else
        for ((i = 0; i < ${#CONF_DIRECTORY}; i++)); do
            if (( ${CONF_DIRECTORY:${i}:1} < 0 || ${CONF_DIRECTORY:${i}:1} > 7 )); then
                echo "Directory is incorrectly configured"
                exit ${CONFIG}
            fi
        done
    fi
fi

CONF_BACKGROUND=${CONF_BACKGROUND:-${NZBPO_BACKGROUND:-${BACKGROUND}}}
: "${CONF_BACKGROUND:=false}"
CONF_BACKGROUND=${CONF_BACKGROUND,,}
case "${CONF_BACKGROUND}" in
    true|false) ;;
    *) echo "Background is incorrectly configured"; exit ${CONFIG} ;;
esac

CONF_PROCESSES=${CONF_PROCESSES:-${NZBPO_PROCESSES:-${PROCESSES}}}
: "${CONF_PROCESSES:=ffmpeg}"
IFS='|' read -r -a CONF_PROCESSES <<< "$(echo "${CONF_PROCESSES}" | sed 's/,\ /|/g')"
[[ ! "${CONF_PROCESSES[*]}" =~ "ffmpeg" ]] && CONF_PROCESSES+=("ffmpeg")

if ${NZBGET}; then
    if [[ -z "${NZBOP_VERSION}" ]]; then
        echo "Sorry, you do not have NZBGet version 11.1 or later."
        exit ${DEPEND}
    fi
    if [[ ! -z "${NZBNP_NZBNAME}" ]]; then
        # Workaround till Radarr/Sonarr support NZBPP_FINALDIR
        if ${CONF_RENAME}; then
            NAME=$(echo "${NZBNP_NZBNAME}")
            for OPT in "${OPTIONAL[@]}"; do
                NAME=$(echo "${NAME}" | sed -i -E "s/${OPTIONAL}//g")
            done
            RESOLUTION=$(echo "${NZBNP_NZBNAME}" | grep -oE "[0-9]{3,4}[p|P]")
            if [[ ! -z "${RESOLUTION}" ]] && (( ${RESOLUTION//[p|P]/} > HEIGHT )); then
                NAME=$(echo "${NAME}" | sed -E "s/${RESOLUTION}/${HEIGHT}p/g")
            fi
            if [[ "${NZBNP_NZBNAME}" != "${NAME}" ]]; then
                echo "[NZB] NZBNAME=${NAME}"
            fi
        fi
        exit 0
    fi
    if [[ "${NZBPP_TOTALSTATUS}" != "SUCCESS" ]]; then
        exit ${SKIPPED}
    fi
    if [[ ! -z "${NZBPP_FINALDIR}" ]]; then
        DIRECTORY="${NZBPP_FINALDIR}"
    else
        DIRECTORY="${NZBPP_DIRECTORY}"
    fi
    samplesize=${NZBPO_CLEANUP_SIZE:-0}
    if (( samplesize > 0 )); then
        SIZE=$(( ${NZBPO_CLEANUP_SIZE//[!0-9]/} * 1024 * 1024 ))
        readarray -t samples <<< "$(find "${DIRECTORY}" -type f -size -"${SIZE}"c)"
        if [[ ! -z "${samples[*]}" ]]; then
            for file in "${samples[@]}"; do
                rm -f "${file}"
            done
        fi
    fi
    read -r -a extensions <<< "$(echo "${NZBPO_CLEANUP}" | sed 's/\ //g' | sed 's/,/\ /g')"
    if [[ ! -z "${extensions[*]}" ]]; then
        readarray -t files <<< "$(find "${DIRECTORY}" -type f)"
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
    PROCESS+=("${DIRECTORY}")
elif ${SABNZBD}; then
    if [[ -z "${SAB_PP_STATUS}" ]]; then
        echo "Sorry, you do not have SABnzbd version 2.0.0 or later."
        exit ${DEPEND}
    fi
    if ! (( SAB_PP_STATUS == 0 )); then
        exit ${SKIPPED}
    fi
    PROCESS+=("${SAB_COMPLETE_DIR}")
elif (( ${#} == 0 )); then
    usage
fi

(( ${#PROCESS[@]} == 0 )) && usage

background() {
    echo "Running in background mode..."
    while ps -p ${CONVERTER} &>/dev/null; do
        if [[ -e "${BACKGROUNDMANAGER}" ]]; then
            source "${BACKGROUNDMANAGER}"
        fi
        TOGGLE=false
        for PROCESS in "${CONF_PROCESSES[@]}"; do
            if [[ -z "${PROCESS}" ]]; then
                continue
            fi
            readarray -t PIDS <<< "$(pgrep "${PROCESS}")"
            if [[ "${PROCESS}" == "ffmpeg" ]] && [[ ! -z "${M4VCONVERTER[*]}" ]]; then
                PIDS=("${PIDS[@]}" "${M4VCONVERTER[@]}")
            fi
            for PID in "${PIDS[@]}"; do
                if [[ -z "${PID}" ]]; then
                    continue
                fi
                if [[ "${PROCESS}" == "ffmpeg" ]]; then
                    if (( ${#PIDS[@]} == 1 )); then
                        continue
                    fi
                    if [[ "${PID}" == "${CONVERTER}" ]]; then
                        continue
                    fi
                    CONVERTERELAPSED=$(ps -o etime= -p ${CONVERTER} 2>&1 | awk -F: '{print ($1*3600) + ($2*60) + $3}')
                    PIDELAPSED=$(ps -o etime= -p ${PID} 2>&1 | awk -F: '{print ($1*3600) + ($2*60) + $3}')
                    if (( CONVERTERELAPSED > PIDELAPSED )); then
                        continue
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
        STATE=$(ps -o state= -p ${CONVERTER})
        if ${TOGGLE}; then
            case "${STATE}" in
                R*|S)
                    echo "Detected running process ${PROCESS}; pid=${PID}"
                    echo "Pausing..."
                    kill -STOP "${CONVERTER}"
                ;;
            esac
        else
            case "${STATE}" in
                T*)
                    echo "Resuming..."
                    kill -CONT "${CONVERTER}"
                ;;
            esac
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
    while kill -0 "${CONVERTER}" 2>/dev/null; do
        sleep 2
        if [[ -e "${STATSFILE}" ]]; then
            FRAME=$(tail -n 12 "${STATSFILE}" 2>&1 | grep -m 1 -x 'frame=.*' | sed -E 's/[^0-9]//g')
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
    if [[ ! -e "${valid}" ]]; then
        echo "Directory: ${valid} no longer exists"
        continue
    fi
    readarray -t files <<< "$(find "${valid}" -type f)"
    CURRENTFILE=0
    for file in "${files[@]}"; do
        if [[ -z "${file}" ]]; then
            continue
        fi
        if [[ ! -e "${file}" ]]; then
            echo "File: ${file} no longer exists"
            continue
        fi
        ((CURRENTFILE++))
        skip=true
        DIRECTORY=$(path "${file}")
        FILE_NAME="$(basename "${file}")"
        file="${DIRECTORY}/${FILE_NAME}"
        echo "Processing file[${CURRENTFILE} of ${#files[@]}]: ${file}"
        case "${file,,}" in
            *.mkv | *.mp4 | *.m4v | *.avi | *.wmv | *.xvid | *.divx | *.mpg | *.mpeg) ;;
            *.srt | *.tmp | *.stats | .DS_Store) echo "File skipped" && continue ;;
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
        DIRECTORY="${CONF_OUTPUT:-${DIRECTORY}}"
        newfile="${DIRECTORY}/${newname}"
        command="${CONF_FFMPEG} -threads ${CONF_THREADS}"
        if [[ "${CONF_ACCELERATION}" == "intel" ]]; then
            command+=" -vaapi_device /dev/dri/renderD128"
        fi
        command+=" -i \"${file}\""
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
            if (( x > 0 )); then
                continue
            fi
            convert=false
            videodata=$(${CONF_FFPROBE} "${file}" -v quiet -show_streams -select_streams v:${i} 2>&1)
            videomap=$(echo "${video[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*|\[.*//g')
            videomap=${videomap%:}
            videocodec=$(echo "${videodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
            if [[ "${CONF_ENCODER}" == "*" ]]; then
                case "${videocodec}" in
                    h264) : "${CONF_CRF:=23}" ;;
                    hevc) : "${CONF_CRF:=28}" ;;
                    *) : "${CONF_CRF:=23}"; CONF_ENCODER=libx264; convert=true ;;
                esac
            elif [[ "${videocodec}" != "${CONF_ENCODER_NAME}" ]]; then
                convert=true
            fi
            profile=false
            if (( CONF_CRF != 0 )) && [[ "${CONF_PROFILE}" != "*" ]] && [[ "${CONF_ENCODER_NAME}" == "h264" ]]; then
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
                if ${CONF_FORCE_LEVEL} || (( videolevel < 30 )) || (( videolevel > ${CONF_LEVEL//./} )); then
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
                            bitrate=$(${CONF_FFPROBE} "${file}" -v quiet -select_streams a:${a} -show_entries stream=bit_rate -of default=nokey=1:noprint_wrappers=1 | sed -E 's/[^0-9]//g' | head -1)
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
                videowidth=$(echo "${videodata}" | grep -x 'width=.*' | sed -E 's/[^0-9]//g')
                if (( videowidth > WIDTH )); then
                    convert=true
                    resize=true
                fi
                if ${CONF_RENAME}; then
                    if ! ${SABNZBD}; then
                        RESOLUTION=$(echo "${DIRECTORY}" | grep -oE "[0-9]{3,4}[p|P]")
                        if [[ ! -z "${RESOLUTION}" ]] && (( ${RESOLUTION//[p|P]/} > HEIGHT )); then
                            DIRECTORY=$(echo "${DIRECTORY}" | sed -E "s/${RESOLUTION}/${HEIGHT}p/g")
                            for OPT in "${OPTIONAL[@]}"; do
                                DIRECTORY=$(echo "${DIRECTORY}" | sed -i -E "s/${OPTIONAL}//g")
                            done
                            if [[ ! -e "${DIRECTORY}" ]]; then
                                mkdir "${DIRECTORY}"
                            fi
                            # Needs Sonarr/Radarr support
                            #if ${NZBGET}; then
                            #    echo "[NZB] FINALDIR=${DIRECTORY}"
                            #fi
                        fi
                    fi
                    RESOLUTION=$(echo "${newname}" | grep -oE "[0-9]{3,4}[p|P]")
                    if [[ ! -z "${RESOLUTION}" ]] && (( ${RESOLUTION//[p|P]/} > HEIGHT )); then
                        newname=$(echo "${newname}" | sed -E "s/${RESOLUTION}/${HEIGHT}p/g")
                        for OPT in "${OPTIONAL[@]}"; do
                            newname=$(echo "${newname}" | sed -i -E "s/${OPTIONAL}//g")
                        done
                    fi
                fi
                newfile="${DIRECTORY}/${newname}"
            fi
            pixel=false
            videopixel=$(echo "${videodata}" | grep -x 'pix_fmt=.*' | sed 's/pix_fmt=//g')
            if ${CONF_FORCE_PIXEL} && ! [[ "${videopixel}" == "yuv420p" ]] || ! [[ "${videopixel}" =~ "yuv420p" ]]; then
                convert=true
                pixel=true
            fi
            if ${CONF_VERBOSE}; then
                total=$(echo "${videodata}" | grep -x 'nb_frames=.*' | sed -E 's/[^0-9]//g')
                if [[ -z "${total}" ]]; then
                    fps=$(echo "${data}" | sed -n "s/.*, \\(.*\\) fps.*/\\1/p")
                    dur=$(echo "${data}" | sed -n "s/.* Duration: \\([^,]*\\), .*/\\1/p" | awk -F ':' '{print $1*3600+$2*60+$3}')
                    total=$(echo "${dur}" "${fps}" | awk '{printf("%3.0f\n",($1*$2))}' | head -1)
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
                    command+=" -filter_complex \"[${videomap}]scale=${WIDTH}:trunc(ow/a/2)*2\""
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
            videocodectag=$(echo "${videodata}" | grep -x 'codec_tag_string=.*' | sed 's/codec_tag_string=//g')
            if [[ "${videocodectag}" != "hvc1" ]] && [[ "${CONF_ENCODER}" == "libx265" ]]; then
                command+=" -tag:v:${x} hvc1"
                skip=false
            fi
            if [[ ! -z "${CONF_DEFAULTLANGUAGE}" ]] && [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
                videolang=$(echo "${videodata,,}" | grep -i "TAG:LANGUAGE=" | sed 's/tag:language=//g')
                if [[ -z "${videolang}" ]] || [[ "${videolang}" == "und" ]] || [[ "${videolang}" == "unk" ]]; then
                    if [[ "${videolang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                        videolang="${CONF_DEFAULTLANGUAGE}"
                        skip=false
                    fi
                fi
                if [[ ! -z "${videolang}" ]]; then
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
                if [[ "${audiolang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                    audiolang="${CONF_DEFAULTLANGUAGE}"
                fi
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
                if [[ "${audiolang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                    audiolang="${CONF_DEFAULTLANGUAGE}"
                fi
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
                            if [[ "${lang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                                lang="${CONF_DEFAULTLANGUAGE}"
                            fi
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
                            if [[ "${lang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                                lang="${CONF_DEFAULTLANGUAGE}"
                            fi
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
                            if [[ "${audiolang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                                audiolang="${CONF_DEFAULTLANGUAGE}"
                            fi
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
                            if [[ "${audiolang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                                audiolang="${CONF_DEFAULTLANGUAGE}"
                            fi
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
                audiomap=${audiomap%:}
                audiocodec=$(echo "${audiodata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
                audioprofile=$(echo "${audiodata}" | grep -x 'profile=.*' | sed 's/profile=//g')
                audiochannels=$(echo "${audiodata}" | grep -x 'channels=.*' | sed -E 's/[^0-9]//g')
                audiolang=$(echo "${audiodata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
                if [[ ! -z "${CONF_DEFAULTLANGUAGE}" ]] && [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
                    if [[ -z "${audiolang}" ]] || [[ "${audiolang}" == "und" ]] || [[ "${audiolang}" == "unk" ]]; then
                        if [[ "${audiolang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                            audiolang="${CONF_DEFAULTLANGUAGE}"
                            skip=false
                        fi
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
                                    if [[ ! -z "${audiolang}" ]]; then
                                        command+=" -metadata:s:a:${x} \"language=${audiolang}\""
                                    fi
                                    if (( x == 0 )); then
                                        command+=" -disposition:a:${x} default"
                                    else
                                        command+=" -disposition:a:${x} 0"
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
                                    if [[ ! -z "${audiolang}" ]]; then
                                        command+=" -metadata:s:a:${x} \"language=${audiolang}\""
                                    fi
                                    if (( x == 0 )); then
                                        command+=" -disposition:a:${x} default"
                                    else
                                        command+=" -disposition:a:${x} 0"
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
                                if [[ ! -z "${audiolang}" ]]; then
                                    command+=" -metadata:s:a:${x} \"language=${audiolang}\""
                                fi
                                if (( x == 0 )); then
                                    command+=" -disposition:a:${x} default"
                                else
                                    command+=" -disposition:a:${x} 0"
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
                                if [[ ! -z "${audiolang}" ]]; then
                                    command+=" -metadata:s:a:${x} \"language=${audiolang}\""
                                fi
                                if (( x == 0 )); then
                                    command+=" -disposition:a:${x} default"
                                else
                                    command+=" -disposition:a:${x} 0"
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
                if [[ ! -z "${audiolang}" ]]; then
                    command+=" -metadata:s:a:${x} \"language=${audiolang}\""
                fi
                if (( x == 0 )); then
                    command+=" -disposition:a:${x} default"
                else
                    command+=" -disposition:a:${x} 0"
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
                    if [[ "${subtitlelang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                        subtitlelang="${CONF_DEFAULTLANGUAGE}"
                    fi
                fi
                forced=$(echo "${subtitledata}" | grep -x 'DISPOSITION:forced=.*' | sed -E 's/[^0-9]//g')
                if [[ ! -z "$(echo "${subtitledata}" | grep -i 'TAG:.*forced')" ]] || (( forced == 1 )); then
                    filtered+=("${subtitle[${i}]}")
                    continue
                fi
                subtitlecodec=$(echo "${subtitledata}" | grep -x 'codec_name=.*' | sed 's/codec_name=//g')
                case "${subtitlecodec}" in
                    hdmv_pgs_subtitle|pgssub|dvb_subtitle|dvd_subtitle|dvdsub|s_hdmv/pgs|dvb_teletext)
                        filtered+=("${subtitle[${i}]}");
                        continue;
                    ;;
                esac
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
                    if [[ "${subtitlelang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                        subtitlelang="${CONF_DEFAULTLANGUAGE}"
                    fi
                fi
                have=false
                for ((s = 0; s < ${#subtitlestreams[@]}; s++)); do
                    if [[ -z "${subtitlestreams[${s}]}" ]]; then
                        continue
                    fi
                    lang=$(${CONF_FFPROBE} "${file}" -v quiet -select_streams s:${s} -show_entries stream_tags=language -of default=nokey=1:noprint_wrappers=1)
                    if [[ -z "${lang}" ]] || [[ "${lang,,}" == "und" ]] || [[ "${lang,,}" == "unk" ]]; then
                        if [[ "${lang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                            lang="${CONF_DEFAULTLANGUAGE}"
                        fi
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
                                if [[ "${subtitlelang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                                    subtitlelang="${CONF_DEFAULTLANGUAGE}"
                                fi
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
                    subtitlemap=${subtitlemap%:}
                    subtitlelang=$(echo "${subtitledata,,}" | grep -i 'TAG:LANGUAGE=' | sed 's/tag:language=//g')
                    if [[ ! -z "${CONF_DEFAULTLANGUAGE}" ]] && [[ "${CONF_DEFAULTLANGUAGE}" != "*" ]]; then
                        if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang}" == "und" ]] || [[ "${subtitlelang}" == "unk" ]]; then
                            if [[ "${subtitlelang}" != "${CONF_DEFAULTLANGUAGE}" ]]; then
                                subtitlelang="${CONF_DEFAULTLANGUAGE}"
                            fi
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
                        if [[ ! -z "${subtitlelang}" ]]; then
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
        if [[ "${FILE_NAME}" != "${newname}" ]]; then
            skip=false
        fi
        tmpfile="${newfile}.tmp"
        if [[ -e "${tmpfile}" ]]; then
            rm "${tmpfile}"
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
                videomap=${videomap%:}
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
                    audiomap=${audiomap%:}
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
                subtitlemap=${subtitlemap%:}
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
        echo "Conversion efficiency at $(echo $(wc -c "${file}" 2>&1 | awk '{print($1)}') $(wc -c "${tmpfile}" 2>&1 | awk '{print($1)}') | awk '{printf("%.2f\n",($2-$1)/$1*100)}')%; Original=$(du -sh "${file}" 2>&1 | awk '{print($1)}')B; Converted=$(du -sh "${tmpfile}" 2>&1 | awk '{print($1)}')B"
        if ${CONF_DELETE}; then
            rm -f "${file}"
        fi
        mv "${tmpfile}" "${newfile}"
        if [[ ! -z "${CONF_FILE}" ]]; then
            chmod "${CONF_FILE}" "${newfile}"
        fi
        if [[ ! -z "${CONF_DIRECTORY}" ]]; then
            chmod "${CONF_DIRECTORY}" "${DIRECTORY}"
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
