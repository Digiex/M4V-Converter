#!/usr/bin/env bash

################################################################################
### NZBGET POST-PROCESSING SCRIPT                                            ###

# Convert media to mp4 format.
#
# This script converts media to a universal mp4 format.

################################################################################
### OPTIONS                                                                  ###

# PATH to FFmpeg.
#FFmpeg=ffmpeg

# PATH to FFprobe.
#FFprobe=ffprobe

# PATH to jq.
#JQ=jq

# Output Directory.
#Output=

# Verbose Mode (true, false).
#Verbose=false

# Debug Mode (true, false).
#Debug=false

# Background Mode (true, false).
#Background=false

# Number of Threads (*).
#Threads=auto

# Preferred Languages (*).
#Languages=eng

# Encoder (auto, software, vaapi, nvenc, videotoolbox).
#Encoder=auto

# VideoToolBox Quality (1-100).
#VTBQ=65

# Video Codec (source, h264, hevc).
#Video Codec=h264

# Video Preset (ultrafast, superfast, veryfast, faster, fast, medium, slow,
# slower, veryslow).
#Preset=medium

# Video Profile (*).
#Profile=main

# Video Level (*).
#Level=4.1

# Video Constant Rate Factor (0-51).
#CRF=23

# Pixel Format (*).
#Pixel Format=yuv420p

# Video Resolution (*).
#Resolution=source

# Video Bitrate (Kbps).
#Video Bitrate=source

# Video Tune (*).
#Tune=false

# Force Video Convert (true, false).
#Force Video=false

# Audio Codec (source, AAC, AC3).
#Audio Codec=aac

# Audio Channels (*).
#Audio Channels=2

# Audio Bitrate (Kbps).
#Audio Bitrate=128k

# Dual Audio (true, false).
#Dual Audio=false

# Force Audio Convert (true, false).
#Force Audio=false

# Normalize Audio (true, false).
#Normalize=false

# Copy Subtitles (true, false, extract).
#Subtitles=true

# Force Subtitle Convert (true, false).
#Force Subtitle=false

# File Format (MP4, MOV).
#Format=mp4

# File Extension (MP4, M4V).
#Extension=mp4

# File Permissions (*).
#File Permission=0644

# Directory Permissions (*).
#Directory Permission=0755

# Delete Original File (true, false).
#Delete=false

# Fast Start (true, false).
#Fast=true

# Background Processes.
#Processes=ffmpeg

### Extras ###

# Mark bad (true, false).
#BAD=true

# Cleanup files (MB).
#SIZE=50

# Cleanup files.
#EXTS=.nfo,.nzb

### NZBGET POST-PROCESSING SCRIPT                                            ###
################################################################################

((BASH_VERSINFO < 4)) &&
  echo "Outdated; Bash version 4 or later required" && exit 1

declare -A CONFIG=(
  [FFMPEG]=$(which ffmpeg)
  [FFPROBE]=$(which ffprobe)
  [JQ]=$(which jq)
  [INPUT]=
  [OUTPUT]=
  [VERBOSE]=false
  [DEBUG]=false
  [BACKGROUND]=false
  [THREADS]=auto
  [LANGUAGES]=eng
  [ENCODER]=auto
  [VTBQ]=65
  [VIDEO_CODEC]=h264
  [PRESET]=medium
  [PROFILE]=main
  [LEVEL]=4.1
  [CRF]=23
  [PIXEL_FORMAT]=yuv420p
  [RESOLUTION]=source
  [VIDEO_BITRATE]=source
  [TUNE]=film
  [FORCE_VIDEO]=false
  [AUDIO_CODEC]=aac
  [AUDIO_BITRATE]=128k
  [AUDIO_CHANNELS]=2
  [NORMALIZE]=false
  [FORCE_AUDIO]=false
  [DUAL_AUDIO]=false
  [SUBTITLES]=true
  [FORCE_SUBTITLES]=false
  [FORMAT]=mp4
  [EXTENSION]=mp4
  [FILE_PERMISSION]=0644
  [DIRECTORY_PERMISSION]=0755
  [DELETE]=false
  [FAST]=true
  [PROCESSES]=ffmpeg
)

declare -A SAVE=(
  [TOTAL_PROCCESSED]=0
  [TOTAL_SAVED]=0
)

setExitCodes() {
  SUCCESS=${1}
  FAILURE=${2}
  SKIPPED=${3}
}
[[ ! -z "${NZBPP_FINALDIR}" || ! -z "${NZBPP_DIRECTORY}" ]] &&
  setExitCodes 93 94 95 || setExitCodes 0 1 0

[[ $(whoami) = "root" ]] &&
  echo "It is NOT recommended that you run this script as root"

usage() {
  echo "Usage: ${0} [-i INPUT]"
  echo
  echo "This script automates media conversion to a universal MP4 format using FFmpeg."
  echo
  echo "optional arguments:"
  echo "-h, --help  Shows this help message."
  echo "-v, --verbose  Prints extra details."
  echo "-d, --debug  Prints even more details than verbose."
  echo "-b, --background  Automatically pauses ffmpeg when needed."
  echo "-i INPUT, --input=INPUT  Sets a file or directory as INPUT."
  echo "-o OUTPUT, --output=OUTPUT  Sets a directory as OUTPUT."
  echo "-c CONFIG, --config=CONFIG  Sets CONFIG file location."
  echo
  echo "advanced optional arguments: (Use ONLY if you know what you are doing)"
  for ARG in "${!CONFIG[@]}"; do
    ARG="${ARG//_/-}"
    echo "--${ARG,,}="
  done
}

loadConfig() {
  if [[ ! -z "${1}" ]]; then
    LOAD=$(cat "${1}")
  elif [[ ! -z "${NZBPP_TOTALSTATUS}" ]]; then
    LOAD=$(declare -p | grep "NZBPO_")
  elif [[ -e "${CONFIG_FILE}" ]]; then
    LOAD=$(cat "${CONFIG_FILE}")
  fi
  [[ ! -z "${LOAD}" ]] && while read -r LINE; do
    [[ ! -z "${NZBPP_TOTALSTATUS}" ]] &&
      LINE="${LINE#*_}" && LINE="${LINE//\"/}"
    VAR="${LINE%%=*}"
    VAL="${LINE##*=}"
    case "${VAR^^}" in
    INPUT | OUTPUT | CONFIG | FFMPEG | FFPROBE | PROCESSES)
      CONFIG["${VAR^^}"]="${VAL}"
      ;;
    *) CONFIG["${VAR^^}"]="${VAL,,}" ;;
    esac
  done <<<${LOAD} || for VAR in "${!CONFIG[@]}"; do echo "${VAR}=${CONFIG[${VAR}]}" >>"${CONFIG_FILE}"; done
}

CONFIG_FILE="${0}"
CONFIG_NAME="${CONFIG_FILE##*/}"
[[ "${CONFIG_NAME}" = "${CONFIG_NAME##*.}" ]] &&
  CONFIG_NEW_NAME="${CONFIG_NAME}.conf" || CONFIG_NEW_NAME="${CONFIG_NAME//${CONFIG_NAME##*.}/conf}"
CONFIG_FILE="${CONFIG_FILE//${CONFIG_NAME}/${CONFIG_NEW_NAME}}"
loadConfig

if ${CONFIG[VERBOSE]}; then
  SAVE_FILE="${0}"
  SAVE_NAME="${SAVE_FILE##*/}"
  [[ "${SAVE_NAME}" = "${SAVE_NAME##*.}" ]] &&
    SAVE_NEW_NAME="${SAVE_NAME}.sav" || SAVE_NEW_NAME="${SAVE_NAME//${SAVE_NAME##*.}/sav}"
  SAVE_FILE="${SAVE_FILE//${SAVE_NAME}/${SAVE_NEW_NAME}}"
  [[ -e "${SAVE_FILE}" ]] && source "${SAVE_FILE}"
fi

while ((${#} > 0)); do
  case "${1}" in
  -h | --help)
    usage
    shift
    ;;
  -v | --verbose)
    CONFIG[VERBOSE]=true
    shift
    ;;
  -d | --debug)
    CONFIG[DEBUG]=true
    set -ex
    shift
    ;;
  -b | --background)
    CONFIG[BACKGROUND]=true
    shift
    ;;
  -i | --input)
    INPUTS+=("${2}")
    shift 2
    ;;
  -o | --output)
    CONFIG[OUTPUT]="${2}"
    shift 2
    ;;
  -c | --config)
    loadConfig "${2}"
    shift 2
    ;;
  --config=*)
    loadConfig "${1##*=}"
    shift
    ;;
  --*=*)
    VAR="${1#--}"
    VAR="${VAR%=*}"
    VAR="${VAR//-/_}"
    CONFIG[${VAR^^}]="${1#--*=}"
    shift
    ;;
  *)
    [[ -z "${SAB_VERSION}" ]] && usage
    shift
    ;;
  esac
done

if [[ ! -z "${NZBPP_FINALDIR}" || ! -z "${NZBPP_DIRECTORY}" ]]; then
  [[ -z "${NZBPP_TOTALSTATUS}" ]] &&
    echo "Outdated; NZBGet version 13.0 or later required" && exit "${SKIPPED}"
  [[ "${NZBPP_TOTALSTATUS}" != "SUCCESS" ]] && exit "${SKIPPED}"
  [[ ! -z "${NZBPP_FINALDIR}" ]] &&
    DIRECTORY="${NZBPP_FINALDIR}" || DIRECTORY="${NZBPP_DIRECTORY}"
  if ((${NZBPO_SIZE:=0} > 0)); then
    NZBPO_SIZE=$((${NZBPO_SIZE//[!0-9]/} * 1024 * 1024))
    readarray -t CLEANUP <<<"$(find "${DIRECTORY}" -type f -size -"${NZBPO_SIZE}"c)"
    [[ ! -z "${CLEANUP[*]}" ]] &&
      for FILE in "${CLEANUP[@]}"; do rm -f "${FILE}"; done
  fi
  readarray -t FILES <<<"$(find "${DIRECTORY}" -type f)"
  if [[ ! -z "${FILES[*]}" ]]; then
    read -r -a EXTENSIONS <<<"$(echo "${NZBPO_EXTS}" |
      sed -E 's/,|,\ /\ /g')"
    for FILE in "${FILES[@]}"; do
      [[ "${FILE,,}" =~ sample ]] && rm -f "${FILE}" && continue
      [[ ! -z "${EXTENSIONS[*]}" ]] &&
        for EXT in "${EXTENSIONS[@]}"; do
          [[ "${FILE##*.}" == "${EXT//./}" ]] &&
            rm -f "${FILE}" && break
        done
    done
  fi
  INPUTS+=("${DIRECTORY}")
fi

if [[ ! -z "${SAB_COMPLETE_DIR}" ]]; then
  [[ -z "${SAB_PP_STATUS}" ]] &&
    echo "Outdated; SABnzbd version 2.0.0 or later" && exit "${SKIPPED}"
  ((SAB_PP_STATUS == 0)) &&
    INPUTS+=("${SAB_COMPLETE_DIR}") || exit "${SKIPPED}"
fi

INPUTS+=("${CONFIG[INPUT]}")
((${#INPUTS[@]} == 0)) &&
  echo "Please specify a file or directory to process" && exit "${SKIPPED}"

for INPUT in "${INPUTS[@]}"; do
  [ -z "${INPUT}" ] && continue
  [[ ! -e "${INPUT}" || "${INPUT}" == / ]] &&
    echo "${INPUT} is not a valid file or directory" && continue
  VALID+=("${INPUT}")
done
readarray -t VALID < <(for INPUT in "${VALID[@]}"; do echo "${INPUT}"; done | sort)

checkBoolean() {
  for VAR in "${@}"; do
    case "${CONFIG[${VAR}]}" in
    true | false) ;;
    *) echo "${VAR} is incorrectly configured" && exit "${SKIPPED}" ;;
    esac
  done
}

checkBoolean VERBOSE DEBUG BACKGROUND FORCE_VIDEO FORCE_AUDIO DUAL_AUDIO NORMALIZE FORCE_SUBTITLES DELETE FAST
${CONFIG[DEBUG]} && set -ex && declare -p

! hash "${CONFIG[FFMPEG]}" 2>/dev/null &&
  echo "Missing dependency; FFmpeg" && exit "${SKIPPED}"

! hash "${CONFIG[FFPROBE]}" 2>/dev/null &&
  echo "Missing dependency; FFprobe" && exit "${SKIPPED}"

! hash "${CONFIG[JQ]}" 2>/dev/null &&
  echo "Missing dependency; jq" && exit "${SKIPPED}"

if [[ "${CONFIG[THREADS]}" != "auto" ]]; then
  case "${OSTYPE}" in
  linux*) MAX_CORES="$(nproc)" ;;
  darwin*) MAX_CORES="$(sysctl -n hw.ncpu)" ;;
  esac
  [[ ! "${CONFIG[THREADS]}" =~ ^-?[0-9]+$ ]] ||
    (("${CONFIG[THREADS]}" == 0)) ||
    (("${CONFIG[THREADS]}" > MAX_CORES)) &&
    echo "THREADS is incorrectly configured" && exit "${SKIPPED}"
fi

read -r -a CONFIG_LANGUAGES <<<"$(echo "${CONFIG[LANGUAGES]}" |
  sed -E 's/,|,\ /\ /g')"
CONFIG_DEFAULT_LANGUAGE="${CONFIG_LANGUAGES[0]}"
for LANGUAGE in "${CONFIG_LANGUAGES[@]}"; do
  ((${#LANGUAGE} != 3)) &&
    echo "LANGUAGES is incorrectly configured" && exit "${SKIPPED}"
done

case "${CONFIG[VIDEO_CODEC]}" in
h.264 | h264 | x264 | libx264) CONFIG[VIDEO_CODEC]="h264" ;;
h.265 | h265 | x265 | hevc | libx265) CONFIG[VIDEO_CODEC]="hevc" ;;
source) ;;
*)
  echo "VIDEO_CODEC is incorrectly configured"
  exit "${SKIPPED}"
  ;;
esac

case "${CONFIG[ENCODER]}" in
vaapi | videotoolbox | nvenc)
  [[ "${CONFIG[VIDEO_CODEC]}" == "h264" ]] &&
    CONFIG[VIDEO_CODEC]="h264_${CONFIG[ENCODER]}" ||
    CONFIG[VIDEO_CODEC]="hevc_${CONFIG[ENCODER]}"
  ;;
auto | software) ;;
*)
  echo "ENCODER is incorrectly configured"
  exit ${SKIPPED}
  ;;
esac

ENCODERS=$(${CONFIG[FFMPEG]} -v quiet -encoders)
ENCODERS="${ENCODERS,,}"
[[ "${CONFIG[ENCODER]}" != "auto" ]] &&
  [[ "${CONFIG[ENCODER]}" != "software" ]] &&
  [[ ! "${ENCODERS}" =~ "${CONFIG[ENCODER]}" ]] &&
  echo "ENCODER selected is not available" && exit ${SKIPPED}

[[ ! "${CONFIG[VTBQ]}" =~ ^-?[0-9]+$ ]] ||
  (("${CONFIG[VTBQ]}" < 1)) ||
  (("${CONFIG[VTBQ]}" > 100)) &&
  echo "VTBQ (VideoToolBox Quality) is incorrectly configured" && exit "${SKIPPED}"

case "${CONFIG[PRESET]}" in
ultrafast | superfast | veryfast | faster | fast | medium | slow | slower | veryslow) ;;
*)
  echo "PRESET is incorrectly configured"
  exit "${SKIPPED}"
  ;;
esac

CONFIG[PROFILE]="${CONFIG[PROFILE]//\ /}"
case "${CONFIG[PROFILE]}" in
source | baseline | main | main10 | main12 | high) ;;
*)
  echo "PROFILE is incorrectly configured"
  exit "${SKIPPED}"
  ;;
esac

case "${CONFIG[LEVEL]//./}" in
source | 30 | 31 | 32 | 40 | 41 | 42 | 50 | 51 | 52 | 60 | 61 | 62) ;;
*)
  echo "LEVEL is incorrectly configured"
  exit "${SKIPPED}"
  ;;
esac

[[ ! "${CONFIG[CRF]}" =~ ^-?[0-9]+$ ]] ||
  (("${CONFIG[CRF]}" < 0)) ||
  (("${CONFIG[CRF]}" > 51)) &&
  echo "CRF is incorrectly configured" && exit "${SKIPPED}"

if [[ ! -z "${CONFIG[RESOLUTION]}" ]]; then
  case "${CONFIG[RESOLUTION]}" in
  480p | sd) CONFIG[RESOLUTION]=640x480 ;;
  720p | hd) CONFIG[RESOLUTION]=1280x720 ;;
  1080p) CONFIG[RESOLUTION]=1920x1080 ;;
  1440p | 2k) CONFIG[RESOLUTION]=2560x1440 ;;
  2160p | 4k | uhd) CONFIG[RESOLUTION]=3840x2160 ;;
  source) ;;
  esac
  [[ "${CONFIG[RESOLUTION]}" != source ]] &&
    [[ ! "${CONFIG[RESOLUTION]}" =~ x ||
      ! "${CONFIG[RESOLUTION]//x/}" =~ ^-?[0-9]+$ ]] &&
    echo "RESOLUTION is incorrectly configured" && exit "${SKIPPED}"
fi

[[ "${CONFIG[VIDEO_BITRATE]}" != source ]] &&
  [[ ! "${CONFIG[VIDEO_BITRATE]}" =~ ^-?[0-9]+$ ]] &&
  echo "VIDEO_BITRATE is incorrectly configured" && exit "${SKIPPED}"

case "${CONFIG[VIDEO_CODEC]}" in
h264*)
  case "${CONFIG[TUNE]}" in
  film | animation | grain | stillimage | fastdecode | zerolatency | false) ;;
  *)
    echo "TUNE is incorrectly configured"
    exit "${SKIPPED}"
    ;;
  esac
  ;;
hevc*)
  case "${CONFIG[TUNE]}" in
  animation | grain | fastdecode | zerolatency | false) ;;
  film | stillimage)
    echo "TUNE: ${CONFIG[TUNE]} is not available for HEVC"
    exit "${SKIPPED}"
    ;;
  *)
    echo "TUNE is incorrectly configured"
    exit "${SKIPPED}"
    ;;
  esac
  ;;
esac

case "${CONFIG[AUDIO_CODEC]}" in
aac | ac3 | source) ;;
*)
  echo "AUDIO_CODEC is incorrectly configured"
  exit "${SKIPPED}"
  ;;
esac

if [[ "${CONFIG[AUDIO_BITRATE]}" != source ]]; then
  CONFIG[AUDIO_BITRATE]="${CONFIG[AUDIO_BITRATE]//k/}"
  [[ ! "${CONFIG[AUDIO_BITRATE]}" =~ ^-?[0-9]+$ ]] &&
    echo "AUDIO_BITRATE is incorrectly configured" && exit "${SKIPPED}"
fi

[[ "${CONFIG[AUDIO_CHANNELS]}" != source ]] &&
  [[ ! "${CONFIG[AUDIO_CHANNELS]}" =~ ^-?[0-9]+$ ]] &&
  echo "AUDIO_CHANNELS is incorrectly configured" && exit "${SKIPPED}"

case "${CONFIG[SUBTITLES]}" in
true | false | extract) ;;
*)
  echo "SUBTITLES is incorrectly configured"
  exit "${SKIPPED}"
  ;;
esac

[[ "${CONFIG[FORMAT]}" != "mp4" ]] &&
  [[ "${CONFIG[FORMAT]}" != "mov" ]] &&
  echo "FORMAT is incorrectly configured" && exit "${SKIPPED}"

[[ "${CONFIG[EXTENSION]}" != "mp4" ]] &&
  [[ "${CONFIG[EXTENSION]}" != "m4v" ]] &&
  echo "EXTENSION is incorrectly configured" && exit "${SKIPPED}"

if [[ ! "${CONFIG[FILE_PERMISSION]}" =~ ^-?[0-9]+$ ]] ||
  ((${#CONFIG[FILE_PERMISSION]} > 4 || \
  ${#CONFIG[FILE_PERMISSION]} < 3)); then
  echo "FILE_PERMISSION is incorrectly configured"
  exit "${SKIPPED}"
else
  for ((i = 0; i < ${#CONFIG[FILE_PERMISSION]}; i++)); do
    ((${CONFIG[FILE_PERMISSION]:${i}:1} < 0 || \
    ${CONFIG[FILE_PERMISSION]:${i}:1} > 7)) &&
      echo "FILE_PERMISSION is incorrectly configured" && exit "${SKIPPED}"
  done
fi

if [[ ! "${CONFIG[DIRECTORY_PERMISSION]}" =~ ^-?[0-9]+$ ]] ||
  ((${#CONFIG[DIRECTORY_PERMISSION]} > 4 || \
  ${#CONFIG[DIRECTORY_PERMISSION]} < 3)); then
  echo "DIRECTORY_PERMISSION is incorrectly configured"
  exit "${SKIPPED}"
else
  for ((i = 0; i < ${#CONFIG[DIRECTORY_PERMISSION]}; i++)); do
    ((${CONFIG[DIRECTORY_PERMISSION]:${i}:1} < 0 || \
    ${CONFIG[DIRECTORY_PERMISSION]:${i}:1} > 7)) &&
      echo "DIRECTORY_PERMISSION is incorrectly configured" && exit "${SKIPPED}"
  done
fi

IFS='|' read -r -a CONFIG_PROCESSES <<<"$(echo "${CONFIG[PROCESSES]}" |
  sed -E 's/,|,\ /|/g')"
unset IFS
[[ ! "${CONFIG_PROCESSES[*]}" =~ ffmpeg ]] && CONFIG_PROCESSES+=("ffmpeg")

log() {
  ${CONFIG[VERBOSE]} && echo "${1}" || true
}

background() {
  echo "Running in background mode..."
  while kill -0 "${CONVERTER}" 2>/dev/null; do
    local TOGGLE=false
    for PROCESS in "${CONFIG_PROCESSES[@]}"; do
      [[ -z "${PROCESS}" ]] && continue
      readarray -t PIDS < <(pgrep "${PROCESS}")
      for PID in "${PIDS[@]}"; do
        [[ -z "${PID}" ]] && continue
        [[ "${PID}" == "${CONVERTER}" ]] && continue
        local PROCESS="${PROCESS}"
        local PID="${PID}"
        local TOGGLE=true
        break 2
      done
    done
    case "${OSTYPE}" in
    linux*) [[ -d /proc/${CONVERTER} ]] &&
      local STATE=$(awk '{print($3)}' </proc/"${CONVERTER}"/stat) || break ;;
    darwin*) local STATE=$(ps -o state= -p "${CONVERTER}") ;;
    esac
    if ${TOGGLE}; then
      [[ "${STATE}" == R* ]] || [[ "${STATE}" == S ]] &&
        log "Detected running process: ${PROCESS}; PID: ${PID}" &&
        echo "Pausing..." && kill -STOP "${CONVERTER}"
    else
      [[ "${STATE}" == T* ]] &&
        echo "Resuming..." && kill -CONT "${CONVERTER}"
    fi
    sleep 60
  done
}

formatDate() {
  case "${OSTYPE}" in
  linux*) date -d @"${1}" -u +%H:%M:%S ;;
  darwin*) date -r "${1}" -u +%H:%M:%S ;;
  esac
}

formatBytes() {
  local i=${1:-0} d="" s=0 S=("Bytes" "KiB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB")
  while ((i > 1024 && s < ${#S[@]} - 1)); do
    printf -v d ".%02d" $((i % 1024 * 100 / 1024))
    i=$((i / 1024))
    s=$((s + 1))
  done
  echo "$i$d ${S[$s]}"
}

markBad() {
  [[ ! -z "${NZBPP_TOTALSTATUS}" ]] && ${NZBPO_BAD} && echo "[NZB] MARK=BAD"
}

progress() {
  local START=$(date +%s)
  while kill -0 "${CONVERTER}" 2>/dev/null; do
    sleep 30
    [[ ! -f "${STATSFILE}" ]] && continue
    local FRAME=$(tail -n 12 "${STATSFILE}" 2>&1 |
      grep -m 1 -x 'frame=.*' | sed -E 's/[^0-9]//g')
    ((FRAME > CURRENTFRAME)) && local CURRENTFRAME=${FRAME} &&
      local CURRENTPERCENTAGE=$((100 * CURRENTFRAME / FRAMES))
    ((CURRENTPERCENTAGE > PERCENTAGE)) &&
      local PERCENTAGE=${CURRENTPERCENTAGE} &&
      local ELAPSED=$(($(date +%s) - START)) &&
      local RATE=$((FRAMES / ELAPSED)) &&
      local ETA=$(awk "BEGIN{print int((${ELAPSED} / ${CURRENTFRAME}) * \
    (${FRAMES} - ${CURRENTFRAME}))}") &&
      log "Converting...${CURRENTPERCENTAGE}%; ETA: $(formatDate "${ETA}")"
  done
  ((ELAPSED > 0)) &&
    log "Time: $(formatDate "${ELAPSED}"); FPS: ${RATE}"
}

force() {
  pkill -P ${CONVERTER} &>/dev/null
  wait ${CONVERTER} &>/dev/null
  exit ${FAILURE}
}

clean() {
  for FILE in "${TMPFILES[@]}"; do
    [[ -f "${FILE}" ]] && rm -f "${FILE}"
    [[ ! -z "${NZBPP_TOTALSTATUS}" ]] && [[ -d "${FILE}" ]] &&
      [[ -z "$(ls -A "${FILE}")" ]] && rmdir "${FILE}"
  done
}

trap force INT
trap clean EXIT

lang() {
  local LANGUAGE=$("${CONFIG[JQ]}" -r ".streams[${1}].tags.language" <<<"${DATA}")
  case "${LANGUAGE,,}" in
  null | unk | und) LANGUAGE="${CONFIG_DEFAULT_LANGUAGE}" ;;
  esac
  echo "${LANGUAGE}"
}

CURRENTINPUT=0
PROCESSED=0
for INPUT in "${VALID[@]}"; do
  ((CURRENTINPUT++))
  [[ ! -e "${INPUT}" ]] &&
    echo "Input: ${INPUT} no longer exists" && continue
  if [[ -d "${INPUT}" ]]; then
    echo "Processing directory[${CURRENTINPUT} of ${#VALID[@]}]: ${INPUT}"
    CUSTOM=false
    CUSTOM_CONFIG="${INPUT}/${CONFIG_NEW_NAME}"
    [[ "${CONFIG_FILE}" != "${CUSTOM_CONFIG}" ]] && [[ -e "${CUSTOM_CONFIG}" ]] &&
      loadConfig "${CUSTOM_CONFIG}" && CUSTOM=true &&
      log "Found config file; ${CUSTOM_CONFIG}"
    if [[ ! -z "${CONFIG[OUTPUT]}" ]] &&
      [[ -d "${CONFIG[OUTPUT]}" ]] &&
      [[ "${CONFIG[OUTPUT]}" != "${INPUT}" ]]; then
      [[ ! -z "${NZBPP_TOTALSTATUS}" ]] && TMPFILES+=("${INPUT}")
      [[ ! -z "${NZBPP_CATEGORY}" ]] &&
        OUTPUT="${CONFIG[OUTPUT]}/${NZBPP_CATEGORY}/${INPUT##*/}" && echo "[NZB] DIRECTORY=${OUTPUT}" ||
        OUTPUT="${CONFIG[OUTPUT]}/${INPUT##*/}"
      [[ ! -e "${OUTPUT}" ]] && mkdir -p "${OUTPUT}"
      chmod "${CONFIG[DIRECTORY_PERMISSION]}" "${OUTPUT}"
    fi
  fi
  readarray -t FILES < <(for FILE in "$(find "${INPUT}" -type f)"; do echo "${FILE}"; done | sort)
  CURRENTFILE=0
  for FILE in "${FILES[@]}"; do
    ((CURRENTFILE++))
    [[ ! -e "${FILE}" ]] &&
      echo "File: ${FILE} no longer exists" && continue
    DIRECTORY="$(dirname "${FILE}")"
    FILE_NAME="$(basename "${FILE}")"
    FILE="${DIRECTORY}/${FILE_NAME}"
    echo "Processing file[${CURRENTFILE} of ${#FILES[@]}]: ${FILE}"
    case "${FILE,,}" in
    *.mkv | *.mp4 | *.m4v | *.avi | *.wmv | *.xvid | *.divx | *.mpg | *.mpeg | *.iso) ;;
    *.srt | *.tmp | *.stats | *.sav | *.ds_store) echo "File skipped" && continue ;;
    *) echo "File is not convertable" && continue ;;
    esac
    [[ "${FILE_NAME}" == "${FILE_NAME##*.}" ]] &&
      NEW_FILE_NAME="${FILE_NAME}.${CONFIG[EXTENSION]}" ||
      NEW_FILE_NAME="${FILE_NAME//${FILE_NAME##*.}/${CONFIG[EXTENSION]}}"
    NEW_FILE="${DIRECTORY}/${NEW_FILE_NAME}"
    DATA=$("${CONFIG[FFPROBE]}" "${FILE}" -v quiet -print_format json -show_format -show_streams 2>&1)
    ${CONFIG[DEBUG]} && echo "${DATA}"
    [[ "${DATA}" =~ drm ]] && echo "File is DRM protected" && continue
    COMMAND="${CONFIG[FFMPEG]} -loglevel error -threads ${CONFIG[THREADS]}"
    [[ "${CONFIG[ENCODER]}" == "vaapi" ]] && COMMAND+=" -hwaccel_device /dev/dri/renderD128"
    COMMAND+=" -i \"${FILE}\""
    TOTAL=$("${CONFIG[JQ]}" '.streams | length' <<<"${DATA}")
    SKIP=true
    VIDEO=0
    for ((v = 0; v < ${TOTAL}; v++)); do
      ((VIDEO == 1)) && break
      CODEC_TYPE=$("${CONFIG[JQ]}" -r ".streams[${v}].codec_type" <<<"${DATA}")
      [[ "${CODEC_TYPE}" != "video" ]] && continue
      FILTER=$("${CONFIG[JQ]}" -r ".streams[${v}].disposition.attached_pic" <<<"${DATA}")
      ((FILTER == 1)) && continue
      CODEC_NAME=$("${CONFIG[JQ]}" -r ".streams[${v}].codec_name" <<<"${DATA}")
      log "Stream found @${v}; type=${CODEC_TYPE}; codec=${CODEC_NAME}"
      BIT_RATE=$("${CONFIG[JQ]}" -r ".streams[${v}].bit_rate" <<<"${DATA}")
      if [[ "${BIT_RATE}" == "null" ]]; then
        log "Stream issue; bit_rate=N/A; calculating based on FORMAT_BITRATE-STREAM_BITRATE"
        for ((s = 0; s < ${TOTAL}; s++)); do
          [[ $("${CONFIG[JQ]}" -r ".streams[${v}].codec_type" <<<"${DATA}") == "video" ]] && continue
          STREAMS=$((STREAMS + $("${CONFIG[JQ]}" -r ".streams[${v}].bit_rate" <<<"${DATA}")))
        done
        BIT_RATE=$(($("${CONFIG[JQ]}" -r ".format.bit_rate" <<<"${DATA}") - STREAMS))
      fi
      BIT_RATE=$((BIT_RATE / 1000))
      if ${CONFIG[VERBOSE]}; then
        FRAMES=$("${CONFIG[JQ]}" -r ".streams[${v}].nb_frames" <<<"${DATA}")
        if [[ "${FRAMES}" == "null" ]]; then
          log "Stream issue; nb_frames=N/A; calculating based on DURATION*FPS"
          FPS=$("${CONFIG[FFPROBE]}" "${FILE}" 2>&1 |
            sed -n "s/.*, \\(.*\\) fps.*/\\1/p")
          DUR=$("${CONFIG[FFPROBE]}" "${FILE}" 2>&1 |
            sed -n "s/.* Duration: \\([^,]*\\), .*/\\1/p" |
            awk -F ':' '{print $1*3600+$2*60+$3}')
          FRAMES=$(echo "${DUR}" "${FPS}" |
            awk '{printf("%3.0f\n",($1*$2))}' | head -1)
        fi
        STATSFILE="${NEW_FILE}.$$.stats"
        [[ -e "${STATSFILE}" ]] && rm -f "${STATSFILE}"
        TMPFILES+=("${STATSFILE}")
        COMMAND+=" -progress \"${STATSFILE}\""
      fi
      VIDEO_CODEC=false VIDEO_RESOLUTION=false VIDEO_BITRATE=false \
        VIDEO_PROFILE=false VIDEO_LEVEL=false VIDEO_PIXFMT=false
      COMMAND+=" -map 0:${v}"
      [[ "${CONFIG[VIDEO_CODEC]}" == "source" ]] &&
        DESIRED_CODEC="${CODEC_NAME}" || DESIRED_CODEC="${CONFIG[VIDEO_CODEC]}"
      WIDTH=$("${CONFIG[JQ]}" -r ".streams[${v}].width" <<<"${DATA}")
      HEIGHT=$("${CONFIG[JQ]}" -r ".streams[${v}].height" <<<"${DATA}")
      [[ "${CONFIG[RESOLUTION]}" == "source" ]] &&
        DESIRED_RESOLUTION="${WIDTH}x${HEIGHT}" || DESIRED_RESOLUTION="${CONFIG[RESOLUTION]}"
      [[ "${CONFIG[VIDEO_BITRATE]}" == "source" ]] &&
        DESIRED_BITRATE="${BIT_RATE}" || DESIRED_BITRATE="${CONFIG[VIDEO_BITRATE]}"
      PROFILE=$("${CONFIG[JQ]}" -r ".streams[${v}].profile" <<<"${DATA}")
      [[ "${CONFIG[PROFILE]}" == "source" ]] &&
        DESIRED_PROFILE="${PROFILE}" || DESIRED_PROFILE="${CONFIG[PROFILE]}"
      LEVEL=$("${CONFIG[JQ]}" -r ".streams[${v}].level" <<<"${DATA}")
      [[ "${CONFIG[LEVEL]}" == "source" ]] &&
        DESIRED_LEVEL="${LEVEL}" || DESIRED_LEVEL="${CONFIG[LEVEL]//./}"
      PIX_FMT=$("${CONFIG[JQ]}" -r ".streams[${v}].pix_fmt" <<<"${DATA}")
      [[ "${CONFIG[PIXEL_FORMAT]}" == "source" ]] &&
        DESIRED_PIXFMT="${PIX_FMT}" || DESIRED_PIXFMT="${CONFIG[PIXEL_FORMAT]}"
      [[ ! "${DESIRED_CODEC}" =~ ${CODEC_NAME} ]] &&
        log "Codec mismatch; config=${DESIRED_CODEC//_*/} stream=${CODEC_NAME}" && VIDEO_CODEC=true
      ((WIDTH > ${DESIRED_RESOLUTION%%x*} || HEIGHT > ${DESIRED_RESOLUTION##*x})) &&
        log "Resolution exceeded; config=${DESIRED_RESOLUTION}; stream=${WIDTH}x${HEIGHT}" && VIDEO_RESOLUTION=true
      ((BIT_RATE - 2048 > DESIRED_BITRATE)) &&
        log "Bit rate exceeded; config=${DESIRED_BITRATE}; stream=${BIT_RATE}" && VIDEO_BITRATE=true
      [[ "${PROFILE}" != "${DESIRED_PROFILE}" ]] &&
        log "Profile mismatch; config=${DESIRED_PROFILE}; stream=${PROFILE}" && VIDEO_PROFILE=true
      [[ "${LEVEL}" != "${DESIRED_LEVEL}" ]] &&
        log "Level exceeded; config=${DESIRED_LEVEL}; stream=${LEVEL}" && VIDEO_LEVEL=true
      [[ "${PIX_FMT}" != "${DESIRED_PIXFMT}" ]] &&
        log "Pixel format mismatch; config=${DESIRED_PIXFMT}; stream=${PIX_FMT}" && VIDEO_PIXFMT=true
      if ${VIDEO_CODEC} || ${VIDEO_RESOLUTION} || ${VIDEO_BITRATE} ||
        ${VIDEO_PROFILE} || ${VIDEO_LEVEL} || ${VIDEO_PIXFMT} || ${CONFIG[FORCE_VIDEO]}; then
        SKIP=false
        COMMAND+=" -c:v:${VIDEO} ${DESIRED_CODEC}"
        [[ "${CONFIG[TUNE]}" != "false" ]] && COMMAND+=" -tune:${VIDEO} ${CONFIG[TUNE]}"
        COMMAND+=" -preset:${VIDEO} ${CONFIG[PRESET]}"
        [[ "${CONFIG[ENCODER]}" != "videotoolbox" ]] &&
          COMMAND+=" -crf:${VIDEO} ${CONFIG[CRF]}" || COMMAND+=" -q:v:${VIDEO} ${CONFIG[VTBQ]}"
        ${VIDEO_RESOLUTION} && COMMAND+=" -filter:v:${VIDEO} \"scale=${DESIRED_RESOLUTION%%x*}:-2\""
        ${VIDEO_BITRATE} && COMMAND+=" -maxrate:${VIDEO} ${DESIRED_BITRATE} -bufsize:${VIDEO} $((DESIRED_BITRATE * 2))"
        ${VIDEO_PROFILE} && COMMAND+=" -profile:v:${VIDEO} ${DESIRED_PROFILE}"
        ${VIDEO_LEVEL} && COMMAND+=" -level:${VIDEO} ${DESIRED_LEVEL}"
        ${VIDEO_PIXFMT} && COMMAND+=" -pix_fmt:${VIDEO} ${DESIRED_PIXFMT}"
      else
        COMMAND+=" -c:v:${VIDEO} copy"
      fi
      [[ "${DESIRED_CODEC}" =~ hevc ]] &&
        COMMAND+=" -tag:v:${VIDEO} hvc1"
      ((VIDEO++))
    done
    ((VIDEO < 1)) && echo "No usable video streams" && continue
    AUDIO=0
    for LANGUAGES in "${CONFIG_LANGUAGES[@]}"; do
      ${CONFIG[DUAL_AUDIO]} && declare -A DESIRED_STREAMS["${LANGUAGES}"]=2 || declare -A DESIRED_STREAMS["${LANGUAGES}"]=1
      FILTERED=()
      for ((a = 0; a < ${TOTAL}; a++)); do
        CODEC_TYPE=$("${CONFIG[JQ]}" -r ".streams[${a}].codec_type" <<<"${DATA}")
        [[ "${CODEC_TYPE}" != "audio" ]] && continue
        CODEC_NAME=$("${CONFIG[JQ]}" -r ".streams[${a}].codec_name" <<<"${DATA}")
        log "Stream found @${a}; type=audio; codec=${CODEC_NAME}"
        FILTER=$("${CONFIG[JQ]}" -r ".streams[${a}].tags.title" <<<"${DATA}")
        [[ "${FILTER,,}" =~ commentary ]] && 
          echo "Skipping; commentary" && continue
        LANGUAGE=$(lang "${a}")
        [[ ${LANGUAGE} != "${LANGUAGES}" ]] &&
          echo "Skipping; config=${LANGUAGES}; language=${LANGUAGE}" && continue
        FILTERED+=("${a}")
      done
      [[ -z "${FILTERED[@]}" ]] && continue
      SELECTED=()
      for STREAM in "${FILTERED[@]}"; do
        LANGUAGE=$(lang "${STREAM}")
        [[ "${LANGUAGE}" != "${LANGUAGES}" ]] && continue
        ((${#SELECTED[@]} == ${DESIRED_STREAMS[${LANGUAGES}]})) && continue
        CHANNELS=$("${CONFIG[JQ]}" -r ".streams[${STREAM}].channels" <<<"${DATA}")
        MAX_CHANNELS=0
        for INDEX in "${FILTERED[@]}"; do
          [[ "${LANGUAGE}" != $(lang "${INDEX}") ]] && continue
          CH=$("${CONFIG[JQ]}" -r ".streams[${INDEX}].channels" <<<"${DATA}")
          ((CH > MAX_CHANNELS)) && MAX_CHANNELS="${CH}" && MAX_CHANNELS_INDEX="${INDEX}"
        done
        BIT_RATE=$("${CONFIG[JQ]}" -r ".streams[${STREAM}].bit_rate" <<<"${DATA}")
        [[ "${BIT_RATE}" == "null" ]] &&
          BIT_RATE=$("${CONFIG[JQ]}" -r ".streams[${STREAM}].tags.\"BPS-${LANGUAGE}\"" <<<"${DATA}")
        [[ "${BIT_RATE}" == "null" ]] && BIT_RATE=0
        MAX_BITRATE=0
        for INDEX in "${FILTERED[@]}"; do
          [[ "${LANGUAGE}" != $(lang "${INDEX}") ]] && continue
          [[ "${MAX_CHANNELS}" != $("${CONFIG[JQ]}" -r ".streams[${INDEX}].channels" <<<"${DATA}") ]] && continue
          BR=$("${CONFIG[JQ]}" -r ".streams[${INDEX}].bit_rate" <<<"${DATA}")
          [[ "${BIT_RATE}" == "null" ]] &&
            BR=$("${CONFIG[JQ]}" -r ".streams[${INDEX}].tags.\"BPS-${LANGUAGE}\"" <<<"${DATA}")
          [[ "${BIT_RATE}" == "null" ]] &&
            BR=0
          ((BR > MAX_BITRATE)) && MAX_BITRATE="${BR}" && MAX_BITRATE_INDEX="${INDEX}"
        done
        if [[ ! -z "${MAX_BITRATE}" ]]; then
          SELECTED+=("${MAX_BITRATE_INDEX}")
        elif [[ ! -z "${MAX_CHANNELS}" ]]; then
          SELECTED+=("${MAX_CHANNELS_INDEX}")
        fi
      done
      [[ -z "${SELECTED}" ]] && SELECTED=("${FILTERED[@]}")
      while ((AUDIO < ${DESIRED_STREAMS[${LANGUAGES}]})); do
        for SELECTION in "${SELECTED[@]}"; do
          LANGUAGE=$(lang "${SELECTION}")
          [[ ${LANGUAGE} != "${LANGUAGES}" ]] && continue
          ((AUDIO == ${DESIRED_STREAMS[${LANGUAGES}]})) && continue
          CODEC_NAME=$("${CONFIG[JQ]}" -r ".streams[${SELECTION}].codec_name" <<<"${DATA}")
          CHANNELS=$("${CONFIG[JQ]}" -r ".streams[${SELECTION}].channels" <<<"${DATA}")
          BIT_RATE=$("${CONFIG[JQ]}" -r ".streams[${SELECTION}].bit_rate" <<<"${DATA}")

          if ((AUDIO % 2 == 0)) && ${CONFIG[DUAL_AUDIO]}; then
            DESIRED_CODEC=aac DESIRED_CHANNELS=2 DESIRED_BITRATE=128000
            ! ${CONFIG[NORMALIZE]} && [[ "${ENCODERS}" =~ audiotoolbox ]] && DESIRED_CODEC+="_at"
          else
            [[ "${CONFIG[AUDIO_CODEC]}" == "source" ]] &&
              DESIRED_CODEC="${CODEC_NAME}" || DESIRED_CODEC="${CONFIG[AUDIO_CODEC]}"
            [[ "${CONFIG[AUDIO_CHANNELS]}" == "source" ]] && ((MAX_CHANNELS > 0)) &&
              DESIRED_CHANNELS="${CHANNELS}" || DESIRED_CHANNELS="${CONFIG[AUDIO_CHANNELS]}"
            [[ "${CONFIG[AUDIO_BITRATE]}" == "source" ]] && ((MAX_BITRATE > 0)) &&
              DESIRED_BITRATE="${BIT_RATE}" || DESIRED_BITRATE="${CONFIG[AUDIO_BITRATE]}"
          fi

          [[ "${BIT_RATE}" == "null" ]] &&
            BIT_RATE=$("${CONFIG[JQ]}" -r ".streams[${SELECTION}].tags.\"BPS-${LANGUAGE}\"" <<<"${DATA}")
          [[ "${BIT_RATE}" == "null" ]] && BIT_RATE=0
          AUDIO_CODEC=false AUDIO_BITRATE=false AUDIO_CHANNELS=false
          COMMAND+=" -map 0:${SELECTION}"
          [[ ! "${DESIRED_CODEC}" =~ ${CODEC_NAME} ]] &&
            log "Codec mismatch; config=${DESIRED_CODEC}; stream=${CODEC_NAME}" && AUDIO_CODEC=true
          ((BIT_RATE - 2048 > DESIRED_BITRATE)) &&
            log "Bit rate exceeded; config=${DESIRED_BITRATE}; stream=${BIT_RATE}" && AUDIO_BITRATE=true
          ((CHANNELS > DESIRED_CHANNELS)) &&
            log "Channels exceeded; config=${DESIRED_CHANNELS}; stream=${CHANNELS}" && AUDIO_CHANNELS=true
          if ${AUDIO_CODEC} || ${AUDIO_BITRATE} || ${AUDIO_CHANNELS} || ${CONFIG[FORCE_AUDIO]}; then
            SKIP=false
            COMMAND+=" -c:a:${AUDIO} ${DESIRED_CODEC}"
            ${AUDIO_CHANNELS} && COMMAND+=" -ac:a:${AUDIO} ${DESIRED_CHANNELS}"
            ${AUDIO_BITRATE} && COMMAND+=" -b:a:${AUDIO} ${DESIRED_BITRATE}"
            ${AUDIO_CHANNELS} && ${CONFIG[NORMALIZE]} && COMMAND+=" -filter:a:${AUDIO} loudnorm"
          else
            COMMAND+=" -c:a:${AUDIO} copy"
          fi
          ((AUDIO == 0)) && COMMAND+=" -disposition:a:${AUDIO} default" || COMMAND+=" -disposition:a:${AUDIO} 0"
          COMMAND+=" -metadata:s:a:${AUDIO} \"language=${LANGUAGE}\""
          ((AUDIO++))
        done
      done
    done
    ((AUDIO < 1)) && echo "No usable audio streams" && continue
    SUBTITLE=0
    for LANGUAGES in "${CONFIG_LANGUAGES[@]}"; do
      declare -A DESIRED_STREAMS["${LANGUAGES}"]=1
      FILTERED=()
      for ((s = 0; s < ${TOTAL}; s++)); do
        CODEC_TYPE=$("${CONFIG[JQ]}" -r ".streams[${s}].codec_type" <<<"${DATA}")
        [[ "${CODEC_TYPE}" != "subtitle" ]] && continue
        CODEC_NAME=$("${CONFIG[JQ]}" -r ".streams[${s}].codec_name" <<<"${DATA}")
        log "Stream found @${s}; type=${CODEC_TYPE}; codec=${CODEC_NAME}"
        case "${CODEC_NAME}" in
        hdmv_pgs_subtitle | pgssub | dvb_subtitle | \
          dvd_subtitle | dvdsub | s_hdmv/pgs | dvb_teletext)
          echo "Skipping; image based" && continue
          ;;
        esac
        LANGUAGE=$(lang "${s}")
        [[ ${LANGUAGE} != "${LANGUAGES}" ]] &&
          echo "Skipping; config=${LANGUAGES}; language=${LANGUAGE}" && continue
        FILTERED+=("${s}")
      done
      [[ -z "${FILTERED[@]}" ]] && continue
      SELECTED=()
      for STREAM in "${FILTERED[@]}"; do
        LANGUAGE=$(lang "${STREAM}")
        [[ ${LANGUAGE} != "${LANGUAGES}" ]] && continue
        FORCED=$("${CONFIG[JQ]}" -r ".streams[${STREAM}].tags.title" <<<"${DATA}")
        [[ "${FORCED,,}" =~ forced ]] ||
          [[ $("${CONFIG[JQ]}" -r ".streams[${STREAM}].disposition.forced" <<<"${DATA}") == 1 ]] &&
          log "Selecting stream @${STREAM}; disposition=forced; config=${LANGUAGES}; language=${LANGUAGE}" && SELECTED+=("${STREAM}")
      done
      [[ -z "${SELECTED[@]}" ]] && SELECTED=("${FILTERED[@]}")
      for SELECTION in "${SELECTED[@]}"; do
        LANGUAGE=$(lang "${SELECTION}")
        [[ ${LANGUAGE} != "${LANGUAGES}" ]] && continue
        ((SUBTITLE == ${DESIRED_STREAMS[${LANGUAGES}]})) && continue
        if ${CONFIG[SUBTITLES]}; then
          CODEC_NAME=$("${CONFIG[JQ]}" -r ".streams[${SELECTION}].codec_name" <<<"${DATA}")
          SUBTITLE_CODEC_NAME=false
          COMMAND+=" -map 0:${SELECTION}"
          [[ "${CODEC_NAME}" != "mov_text" ]] &&
            log "Codec mismatch; required=mov_text; stream=${CODEC_NAME}" && SUBTITLE_CODEC_NAME=true
          if ${SUBTITLE_CODEC_NAME} || ${CONFIG[FORCE_SUBTITLES]}; then
            SKIP=false
            COMMAND+=" -c:s:${SUBTITLE} mov_text"
            COMMAND="${COMMAND//\ -i\ /\ -fix_sub_duration\ -i\ }"
          else
            COMMAND+=" -c:s:${SUBTITLE} copy"
          fi
          COMMAND+=" -metadata:s:s:${SUBTITLE} \"language=${LANGUAGE}\""
          ((SUBTITLE++))
        elif [[ "${CONFIG[SUBTITLES]}" == "extract" ]]; then
          SRT_NAME="${FILE_NAME%.*}.${LANGUAGE}.srt"
          SRT_FILE="${DIRECTORY}/${SRT_NAME}"
          TMP_FILE="${SRT_FILE}.$$.tmp"
          [[ -e "${TMP_FILE}" ]] && rm -f "${TMP_FILE}"
          EXTRACT_COMMAND="${CONFIG[FFMPEG]} -i \"${FILE}\" -vn -an -map 0:${SELECTION} -c:s:${SUBTITLE} srt \"${TMP_FILE}\""
          log "${EXTRACT_COMMAND}"
          echo "Extracting subtitle..."
          TMPFILES+=("${TMP_FILE}")
          eval "${EXTRACT_COMMAND} &"
          CONVERTER=${!}
          if wait ${CONVERTER}; then
            echo "Result: success"
          else
            echo "Result: failure"
            continue
          fi
          TMPFILES=("${TMPFILES[@]//${TMP_FILE}/}")
          if [[ ! -z "${OUTPUT}" ]]; then
            SRT_FILE="${OUTPUT}/${SRT_NAME}"
            log "Output enabled; config=${CONFIG[OUTPUT]} output=${SRT_FILE}"
          fi
          mv "${TMP_FILE}" "${SRT_FILE}"
          chmod "${CONFIG[FILE_PERMISSION]}" "${SRT_FILE}"
          clean
        fi
      done
    done
    OUTPUT_STREAMS=$((VIDEO + AUDIO + SUBTITLE))
    [[ "${TOTAL}" != "${OUTPUT_STREAMS}" ]] && SKIP=false
    TMP_FILE="${NEW_FILE}.$$.tmp"
    [[ -e "${TMP_FILE}" ]] && rm -f "${TMP_FILE}"
    COMMAND+=" -max_muxing_queue_size 1024 -map_metadata -1"
    COMMAND+=" -f ${CONFIG[FORMAT]} -flags +global_header"
    ${CONFIG[FAST]} && COMMAND+=" -movflags +faststart"
    COMMAND+=" -strict -2 -y \"${TMP_FILE}\""
    ${SKIP} && echo "File does not need to be converted" && continue
    log "${COMMAND}"
    echo "Converting..."
    TMPFILES+=("${TMP_FILE}")
    eval "${COMMAND} &"
    CONVERTER=${!}
    ${CONFIG[VERBOSE]} && eval "progress &" && PROGRESS=${!}
    ${CONFIG[BACKGROUND]} && eval "background &" && BACKGROUND=${!}
    if wait "${CONVERTER}"; then
      echo "Result: success"
    else
      echo "Result: failure"
      markBad
      exit "${FAILURE}"
    fi
    pkill -P ${PROGRESS} &>/dev/null
    pkill -P ${BACKGROUND} &>/dev/null
    FILE_SIZE=$(ls -l "${FILE}" 2>&1 | awk '{print($5)}')
    TMP_SIZE=$(ls -l "${TMP_FILE}" 2>&1 | awk '{print($5)}')
    echo "Efficiency: $(echo "${FILE_SIZE}" "${TMP_SIZE}" | awk \
      '{printf("%.2f\n",($2-$1)/$1*100)}')%;" \
      "Original=$(formatBytes "${FILE_SIZE}"); Converted=$(formatBytes "${TMP_SIZE}")"
    if ${CONFIG[VERBOSE]}; then
      SAVE[TOTAL_PROCCESSED]=$((FILE_SIZE + SAVE[TOTAL_PROCCESSED]))
      SAVE[TOTAL_SAVED]=$((TMP_SIZE + SAVE[TOTAL_SAVED]))
      echo "Total Processed: $(formatBytes "${SAVE[TOTAL_PROCCESSED]}")"
      echo "Total Saved: $(formatBytes "${SAVE[TOTAL_SAVED]}")"
      echo "Total Efficiency: $(echo "${SAVE[TOTAL_PROCCESSED]}" "${SAVE[TOTAL_SAVED]}" | awk \
        '{printf("%.2f\n",($2-$1)/$1*100)}')%"
      declare -p SAVE >"${SAVE_FILE}"
    fi
    touch -r "${FILE}" "${TMP_FILE}"
    if ${CONFIG[DELETE]}; then
      rm -f "${FILE}"
    else
      TMPFILES=("${TMPFILES[@]//${TMP_FILE}/}")
      NEW_FILE="${TMP_FILE}"
    fi
    if [[ ! -z "${OUTPUT}" ]]; then
      NEW_FILE="${OUTPUT}/${NEW_FILE_NAME}"
      log "Output enabled; config=${CONFIG[OUTPUT]} output=${NEW_FILE}"
    fi
    mv "${TMP_FILE}" "${NEW_FILE}"
    chmod "${CONFIG[FILE_PERMISSION]}" "${NEW_FILE}"
    clean
    ((PROCESSED++))
  done
  ${CUSTOM} && loadConfig && CUSTOM=false
done

! ${SKIP} && ((PROCESSED == 0)) && markBad
exit "${SUCCESS}"
