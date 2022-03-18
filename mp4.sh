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

# Encoder (auto, software, VAAPI, CUDA).
#Encoder=auto

# Video Codec (source, H.264, HEVC).
#Video Codec=H.264

# Video Preset (ultrafast, superfast, veryfast, faster, fast, medium, slow,
# slower, veryslow).
#Preset=medium

# Video Profile (*).
#Profile=main

# Video Level (*).
#Level=4.1

# Force Video Level (true, false).
#Force Level=false

# Video Constant Rate Factor (0-51).
#CRF=23

# Pixel Format (*).
#Pixel Format=yuv420p

# Video Resolution (*).
#Resolution=source

# Video Bitrate (KB).
#Video Bitrate=source

# Video Tune (film, animation, grain, stillimage, fastdecode,
# zerolatency, false).
#Tune=film

# Force Video Convert (true, false).
#Force Video=false

# Audio Codec (source, AAC, AC3).
#Audio Codec=aac

# Audio Channels (*).
#Audio Channels=2

# Audio Bitrate (KB).
#Audio Bitrate=128

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

(( BASH_VERSINFO < 4 )) && \
echo "Outdated; Bash version 4 or later required" && exit "${SKIPPED}"

declare -A CONFIG=(
  [FFMPEG]=$(which ffmpeg)
  [FFPROBE]=$(which ffprobe)
  [INPUT]=
  [OUTPUT]=
  [VERBOSE]=false
  [DEBUG]=false
  [BACKGROUND]=false
  [THREADS]=auto
  [LANGUAGES]=eng
  [ENCODER]=auto
  [VIDEO_CODEC]=h264
  [PRESET]=medium
  [PROFILE]=main
  [LEVEL]=4.1
  [FORCE_LEVEL]=false
  [CRF]=23
  [PIXEL_FORMAT]=yuv420p
  [RESOLUTION]=source
  [VIDEO_BITRATE]=source
  [TUNE]=film
  [FORCE_VIDEO]=false
  [AUDIO_CODEC]=aac
  [AUDIO_BITRATE]=128
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
  [STATS]=true
  [OFS]=0
  [CFS]=0
)

setExitCodes() {
  SUCCESS=${1}; FAILURE=${2}; SKIPPED=${3};
}
[[ ! -z "${NZBPP_FINALDIR}" || ! -z "${NZBPP_DIRECTORY}" ]] && \
setExitCodes 93 94 95 || setExitCodes 0 1 0

[[ $(whoami) = "root" ]] && \
echo "It is NOT recommended that you run this script as root"

usage() {
  echo "Usage: ${0} [-c CONFIG] [-i INPUT] [ -o OUTPUT]"
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
  echo "--ffmpeg="
  echo "--ffprobe="
  echo "--threads="
  echo "--languages="
  echo "--encoder="
  echo "--video-codec="
  echo "--preset="
  echo "--profile="
  echo "--level="
  echo "--force-level="
  echo "--crf="
  echo "--pixel-format="
  echo "--resolution="
  echo "--video-bitrate="
  echo "--force-video="
  echo "--audio-codec="
  echo "--audio-bitrate="
  echo "--audio-channels="
  echo "--normalize="
  echo "--force-audio="
  echo "--dual-audio="
  echo "--subtitles="
  echo "--force-subtitles="
  echo "--format="
  echo "--extension="
  echo "--file-permission="
  echo "--directory-permission="
  echo "--delete="
  echo "--fast="
  echo "--processes="
}

loadConfig() {
  if [[ ! -z "${1}" ]]; then
    local COMMAND=$(cat "${1}")
  elif [[ ! -z "${NZBPP_TOTALSTATUS}" ]]; then
    local COMMAND=$(declare -p | grep "NZBPO_")
  elif [[ -e "${CONFIG_FILE}" ]]; then
    local COMMAND=$(cat "${CONFIG_FILE}")
  fi
  [[ ! -z "${COMMAND}" ]] && while read -r LINE; do
    [[ ! -z "${NZBPP_TOTALSTATUS}" ]] && \
    LINE="${LINE#*_}" && LINE="${LINE//\"/}"
    VAR="${LINE%%=*}"; VAL="${LINE##*=}"
    case "${VAR^^}" in
      INPUT|OUTPUT|CONFIG|FFMPEG|FFPROBE|PROCESSES)
      CONFIG["${VAR^^}"]="${VAL}" ;; *) CONFIG["${VAR^^}"]="${VAL,,}" ;;
    esac
  done <<< ${COMMAND} || \
  for VAR in "${!CONFIG[@]}"; do
    echo "${VAR}=${CONFIG[${VAR}]}" >> "${CONFIG_FILE}";
  done
}

CONFIG_FILE=$(realpath "${0}")
CONFIG_NAME=$(basename "${CONFIG_FILE}")
if [[ "${CONFIG_NAME}" = "${CONFIG_NAME##*.}" ]]; then
  CONFIG_NEW_NAME="${CONFIG_NAME}.conf"
else
  CONFIG_NEW_NAME="${CONFIG_NAME//${CONFIG_NAME##*.}/conf}"
fi
CONFIG_FILE="${CONFIG_FILE//${CONFIG_NAME}/${CONFIG_NEW_NAME}}"
loadConfig

while (( ${#} > 0 )); do
  case "${1}" in
    -h|--help) usage; shift;;
    -v|--verbose) CONFIG[VERBOSE]=true; shift;;
    -d|--debug) CONFIG[DEBUG]=true; set -ex; shift;;
    -b|--background) CONFIG[BACKGROUND]=true; shift;;
    -i|--input) INPUTS+=("${2}"); shift 2;;
    -o|--output) CONFIG[OUTPUT]="${2}"; shift 2;;
    -c|--config) loadConfig "${2}"; shift 2;;
    --config=*) loadConfig "${1##*=}"; shift;;
    --*=*) VAR="${1#--}"; VAR="${VAR%=*}"; VAR="${VAR//-/_}";
    CONFIG[${VAR^^}]="${1#--*=}"; shift;;
    *) usage; shift;;
  esac
done

if [[ ! -z "${NZBPP_FINALDIR}" || ! -z "${NZBPP_DIRECTORY}" ]]; then
  [[ -z "${NZBPP_TOTALSTATUS}" ]] && \
  echo "Outdated; NZBGet version 13.0 or later required" && exit "${SKIPPED}"
  [[ "${NZBPP_TOTALSTATUS}" != "SUCCESS" ]] && exit "${SKIPPED}"
  [[ ! -z "${NZBPP_FINALDIR}" ]] && \
  DIRECTORY="${NZBPP_FINALDIR}" || DIRECTORY="${NZBPP_DIRECTORY}"
  if (( ${NZBPO_SIZE:=0} > 0 )); then
    NZBPO_SIZE=$(( ${NZBPO_SIZE//[!0-9]/} * 1024 * 1024 ))
    readarray -t CLEANUP <<< "$(find "${DIRECTORY}" -type f -size -"${NZBPO_SIZE}"c)"
    [[ ! -z "${CLEANUP[*]}" ]] && \
    for FILE in "${CLEANUP[@]}"; do rm -f "${FILE}"; done
  fi
  readarray -t FILES <<< "$(find "${DIRECTORY}" -type f)"
  if [[ ! -z "${FILES[*]}" ]]; then
    read -r -a EXTENSIONS <<< "$(echo "${NZBPO_EXTS}" | \
    sed -E 's/,|,\ /\ /g')"
    for FILE in "${FILES[@]}"; do
      [[ "${FILE,,}" =~ sample ]] && rm -f "${FILE}" && continue
      [[ ! -z "${EXTENSIONS[*]}" ]] && \
      for EXT in "${EXTENSIONS[@]}"; do
        [[ "${FILE##*.}" == "${EXT//./}" ]] && \
        rm -f "${FILE}" && break
      done
    done
  fi
  INPUTS+=("${DIRECTORY}")
fi

if [[ ! -z "${SAB_COMPLETE_DIR}" ]]; then
  [[ -z "${SAB_PP_STATUS}" ]] && \
  echo "Outdated; SABnzbd version 2.0.0 or later" && exit "${SKIPPED}"
  (( SAB_PP_STATUS == 0 )) && \
  INPUTS+=("${SAB_COMPLETE_DIR}") || exit "${SKIPPED}"
fi

INPUTS+=("${CONFIG[INPUT]}")
(( ${#INPUTS[@]} == 0 )) && \
echo "Please specify a file or directory to process" && exit "${SKIPPED}"

for INPUT in "${INPUTS[@]}"; do
  [ -z "${INPUT}" ] && continue
  [[ ! -e "${INPUT}" || "${INPUT}" == / ]] && \
  echo "${INPUT} is not a valid file or directory" && continue
  VALID+=("${INPUT}")
done
readarray -t VALID < <(for INPUT in "${VALID[@]}"; do echo "${INPUT}"; done | sort)

checkBoolean() {
  for VAR in "${@}"; do
    case "${CONFIG[${VAR}]}" in
      true|false) ;;
      *) echo "${VAR} is incorrectly configured" && exit "${SKIPPED}"
    esac
  done
}

checkBoolean VERBOSE DEBUG BACKGROUND FORCE_LEVEL FORCE_VIDEO FORCE_AUDIO \
NORMALIZE FORCE_SUBTITLES DELETE FAST DUAL_AUDIO STATS
${CONFIG[DEBUG]} && set -ex

! hash "${CONFIG[FFMPEG]}" 2>/dev/null && \
echo "Missing dependency; FFmpeg" && exit "${SKIPPED}"
${CONFIG[DEBUG]} && CONFIG[FFMPEG]="${CONFIG[FFMPEG]} -loglevel debug"

! hash "${CONFIG[FFPROBE]}" 2>/dev/null && \
echo "Missing dependency; FFprobe" && exit "${SKIPPED}"
${CONFIG[DEBUG]} && CONFIG[FFPROBE]="${CONFIG[FFPROBE]} -loglevel debug"

! hash jq 2>/dev/null && \
echo "Missing dependency; jq" && exit "${SKIPPED}"

if [[ "${CONFIG[THREADS]}" != "auto" ]]; then
  case "${OSTYPE}" in
    linux*) MAX_CORES="$(nproc)";;
    darwin*) MAX_CORES="$(sysctl -n hw.ncpu)";;
  esac
  [[ ! "${CONFIG[THREADS]}" =~ ^-?[0-9]+$ ]] || \
  (( "${CONFIG[THREADS]}" == 0 )) || \
  (( "${CONFIG[THREADS]}" > MAX_CORES )) && \
  echo "THREADS is incorrectly configured" && exit "${SKIPPED}"
fi

read -r -a CONFIG_LANGUAGES <<< "$(echo "${CONFIG[LANGUAGES]}" | \
sed -E 's/,|,\ /\ /g')"; CONFIG_DEFAULT_LANGUAGE="${CONFIG_LANGUAGES[0]}"
if [[ "${CONFIG_LANGUAGES}" != "*" ]]; then
  for LANGUAGE in "${CONFIG_LANGUAGES[@]}"; do
    (( ${#LANGUAGE} != 3 )) && \
    echo "LANGUAGES is incorrectly configured" && exit "${SKIPPED}"
  done
fi

case "${CONFIG[VIDEO_CODEC]}" in
  h.264|h264|x264|libx264)
  CONFIG_VIDEO_CODEC="h264"; CONFIG[VIDEO_CODEC]="libx264";;
  h.265|h265|x265|hevc|libx265)
  CONFIG_VIDEO_CODEC="hevc"; CONFIG[VIDEO_CODEC]="libx265";;
  source);;
  *) echo "VIDEO_CODEC is incorrectly configured"; exit "${SKIPPED}";;
esac

case "${CONFIG[ENCODER]}" in
  vaapi)
    [[ "${CONFIG[VIDEO_CODEC]}" == "libx265" ]] && \
    CONFIG[VIDEO_CODEC]="hevc_${CONFIG[ENCODER]}" || \
    CONFIG[VIDEO_CODEC]="h264_${CONFIG[ENCODER]}" ;;
  cuda)
    [[ "${CONFIG[VIDEO_CODEC]}" == "libx265" ]] && \
    CONFIG[VIDEO_CODEC]="hevc_nvenc" || \
    CONFIG[VIDEO_CODEC]="h264_nvenc" ;;
  auto|software) ;;
  *) echo "ENCODER is incorrectly configured"; exit ${CONFIG} ;;
esac

[[ "${CONFIG[ENCODER]}" != "auto" ]] && \
[[ "${CONFIG[ENCODER]}" != "software" ]] && \
[[ ! $(ffmpeg -v quiet -hwaccels 2>&1) =~ "${CONFIG[ENCODER]}" ]] && \
echo "ENCODER selected is not available" && exit ${CONFIG}

case "${CONFIG[PRESET]}" in
  ultrafast|superfast|veryfast|faster|fast|medium|slow|slower|veryslow);;
  *) echo "PRESET is incorrectly configured"; exit "${SKIPPED}";;
esac

CONFIG[PROFILE]="${CONFIG[PROFILE]//\ /}"
case "${CONFIG[PROFILE]}" in
  source|baseline|main|main10|main12|high);;
  *) echo "PROFILE is incorrectly configured"; exit "${SKIPPED}";;
esac

case "${CONFIG[LEVEL]//./}" in
  source|30|31|32|40|41|42|50|51|52);;
  *) echo "LEVEL is incorrectly configured"; exit "${SKIPPED}";;
esac

[[ ! "${CONFIG[CRF]}" =~ ^-?[0-9]+$ ]] || \
(( "${CONFIG[CRF]}" < 0 )) || \
(( "${CONFIG[CRF]}" > 51 )) && \
echo "CRF is incorrectly configured" && exit "${SKIPPED}"

if [[ ! -z "${CONFIG[RESOLUTION]}" ]]; then
  case "${CONFIG[RESOLUTION]}" in
    480p|sd) CONFIG[RESOLUTION]=640x480;;
    720p|hd) CONFIG[RESOLUTION]=1280x720;;
    1080p) CONFIG[RESOLUTION]=1920x1080;;
    1440p|2k) CONFIG[RESOLUTION]=2560x1440;;
    2160p|4k|uhd) CONFIG[RESOLUTION]=3840x2160;;
    source);;
  esac
  [[ "${CONFIG[RESOLUTION]}" != source ]] && \
  [[ ! "${CONFIG[RESOLUTION]}" =~ x || \
  ! "${CONFIG[RESOLUTION]//x/}" =~ ^-?[0-9]+$ ]] && \
  echo "RESOLUTION is incorrectly configured" && exit "${SKIPPED}"
fi

[[ "${CONFIG[VIDEO_BITRATE]}" != source ]] && \
[[ ! "${CONFIG[VIDEO_BITRATE]}" =~ ^-?[0-9]+$ ]] && \
echo "VIDEO_BITRATE is incorrectly configured" && exit "${SKIPPED}"


case "${CONFIG[VIDEO_CODEC]}" in
  libx264)
    case "${CONFIG[TUNE]}" in
      film|animation|grain|stillimage|fastdecode|zerolatency|false) ;;
      *) echo "TUNE is incorrectly configured"; exit "${SKIPPED}";;
    esac
  ;;
  libx265)
    case "${CONFIG[TUNE]}" in
      animation|grain|fastdecode|zerolatency|false) ;;
      film|stillimage)
        echo "TUNE: ${CONFIG[TUNE]} is not available for HEVC";
        exit "${SKIPPED}";;
      *) echo "TUNE is incorrectly configured"; exit "${SKIPPED}";;
    esac
  ;;
esac

case "${CONFIG[AUDIO_CODEC]}" in
  aac|ac3|source);;
  *) echo "AUDIO_CODEC is incorrectly configured"; exit "${SKIPPED}";;
esac

case "${CONFIG[SUBTITLES]}" in
  true|false|extract);;
  *) echo "SUBTITLES is incorrectly configured"; exit "${SKIPPED}";;
esac

[[ "${CONFIG[FORMAT]}" != "mp4" ]] && \
[[ "${CONFIG[FORMAT]}" != "mov" ]] && \
echo "FORMAT is incorrectly configured" && exit "${SKIPPED}"

[[ "${CONFIG[EXTENSION]}" != "mp4" ]] && \
[[ "${CONFIG[EXTENSION]}" != "m4v" ]] && \
echo "EXTENSION is incorrectly configured" && exit "${SKIPPED}"

if [[ ! "${CONFIG[FILE_PERMISSION]}" =~ ^-?[0-9]+$ ]] || \
  (( ${#CONFIG[FILE_PERMISSION]} > 4 || \
  ${#CONFIG[FILE_PERMISSION]} < 3 )); then
    echo "FILE_PERMISSION is incorrectly configured"; exit "${SKIPPED}"
else
  for ((i = 0; i < ${#CONFIG[FILE_PERMISSION]}; i++)); do
    (( ${CONFIG[FILE_PERMISSION]:${i}:1} < 0 || \
    ${CONFIG[FILE_PERMISSION]:${i}:1} > 7 )) && \
    echo "FILE_PERMISSION is incorrectly configured" && exit "${SKIPPED}"
  done
fi

if [[ ! "${CONFIG[DIRECTORY_PERMISSION]}" =~ ^-?[0-9]+$ ]] || \
  (( ${#CONFIG[DIRECTORY_PERMISSION]} > 4 || \
  ${#CONFIG[DIRECTORY_PERMISSION]} < 3 )); then
    echo "DIRECTORY_PERMISSION is incorrectly configured"; exit "${SKIPPED}"
else
  for ((i = 0; i < ${#CONFIG[DIRECTORY_PERMISSION]}; i++)); do
    (( ${CONFIG[DIRECTORY_PERMISSION]:${i}:1} < 0 || \
    ${CONFIG[DIRECTORY_PERMISSION]:${i}:1} > 7 )) && \
    echo "DIRECTORY_PERMISSION is incorrectly configured" && exit "${SKIPPED}"
  done
fi

IFS='|' read -r -a CONFIG_PROCESSES <<< "$(echo "${CONFIG[PROCESSES]}" | \
sed -E 's/,|,\ /|/g')"; unset IFS
[[ ! "${CONFIG_PROCESSES[*]}" =~ ffmpeg ]] && CONFIG_PROCESSES+=("ffmpeg")

if ${CONFIG[STATS]}; then
  [[ ! "${CONFIG[OFS]}" =~ ^-?[0-9]+$ ]] && \
    echo "OFS is incorrectly configured" && exit "${SKIPPED}"
  [[ ! "${CONFIG[CFS]}" =~ ^-?[0-9]+$ ]] && \
    echo "CFS is incorrectly configured" && exit "${SKIPPED}"
fi

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
        local PROCESS="${PROCESS}"; local PID="${PID}"
        local TOGGLE=true; break 2
      done
    done
    case "${OSTYPE}" in
      linux*) [[ -d /proc/${CONVERTER} ]] && \
      local STATE=$(awk '{print($3)}' < /proc/"${CONVERTER}"/stat) || break;;
      darwin*) local STATE=$(ps -o state= -p "${CONVERTER}");;
    esac
    if ${TOGGLE}; then
      [[ "${STATE}" == R* ]] || [[ "${STATE}" == S ]] && \
      log "Detected running process: ${PROCESS}; PID: ${PID}" && \
      echo "Pausing..." && kill -STOP "${CONVERTER}"
    else
      [[ "${STATE}" == T* ]] && \
      echo "Resuming..." && kill -CONT "${CONVERTER}"
    fi; sleep 60
  done
}

formatDate() {
  case "${OSTYPE}" in
    linux*) date -d @"${1}" -u +%H:%M:%S;;
    darwin*) date -r "${1}" -u +%H:%M:%S;;
  esac
}

formatBytes() {
  local i=${1:-0} d="" s=0 S=("Bytes" "KiB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB")
  while ((i > 1024 && s < ${#S[@]}-1)); do
      printf -v d ".%02d" $((i % 1024 * 100 / 1024))
      i=$((i / 1024))
      s=$((s + 1))
  done
  echo "$i$d ${S[$s]}"
}

progress() {
  local START=$(date +%s)
  while kill -0 "${CONVERTER}" 2>/dev/null; do
    sleep 30; [[ ! -f "${STATSFILE}" ]] && continue
    local FRAME=$(tail -n 12 "${STATSFILE}" 2>&1 | \
    grep -m 1 -x 'frame=.*' | sed -E 's/[^0-9]//g')
    (( FRAME > CURRENTFRAME )) && local CURRENTFRAME=${FRAME} && \
    local CURRENTPERCENTAGE=$(( 100 * CURRENTFRAME / FRAMES))
    (( CURRENTPERCENTAGE > PERCENTAGE )) && \
    local PERCENTAGE=${CURRENTPERCENTAGE} && \
    local ELAPSED=$(( $(date +%s) - START )) && \
    local RATE=$(( FRAMES / ELAPSED )) && \
    local ETA=$(awk "BEGIN{print int((${ELAPSED} / ${CURRENTFRAME}) * \
    (${FRAMES} - ${CURRENTFRAME}))}") && \
    log "Converting...${CURRENTPERCENTAGE}%; ETA: $(formatDate "${ETA}")"
  done
  (( ELAPSED > 0 )) && \
  log "Time: $(formatDate "${ELAPSED}"); FPS: ${RATE}"
}

force() {
  case "${OSTYPE}" in
    linux*) pkill -P $$;; darwin*) kill $(ps -o pid= --ppid $$);;
  esac; exit "${SKIPPED}"
}

clean() {
  for FILE in "${TMPFILES[@]}"; do [ -f "${FILE}" ] && rm -f "${FILE}"; done
}

trap force HUP INT TERM QUIT
trap clean EXIT

CURRENTINPUT=0
for INPUT in "${VALID[@]}"; do
  [[ ! -e "${INPUT}" ]] && \
  echo "Input: ${INPUT} no longer exists" && continue
  ((CURRENTINPUT++)) || true
  [[ -d "${INPUT}" ]] && \
  echo "Processing directory[${CURRENTINPUT} of ${#VALID[@]}]: ${INPUT}"
  readarray -t FILES < <(for FILE in "$(find "${INPUT}" -type f)"; do echo "${FILE}"; done | sort)
  CURRENTFILE=0; CUSTOM=false
  for FILE in "${FILES[@]}"; do
    [[ ! -e "${FILE}" ]] && \
    echo "File: ${FILE} no longer exists" && continue
    ((CURRENTFILE++)) || true
    DIRECTORY="$(dirname "${FILE}")"
    [[ -e "${DIRECTORY}/${CONFIG_NAME}" ]] && \
    loadConfig "${DIRECTORY}/${CONFIG_NAME}" && CUSTOM=true && \
    log "Found config file; ${DIRECTORY}/${CONFIG_NAME}"
    FILE_NAME="$(basename "${FILE}")"
    FILE="${DIRECTORY}/${FILE_NAME}"
    echo "Processing file[${CURRENTFILE} of ${#FILES[@]}]: ${FILE}"
    case "${FILE,,}" in
      *.mkv | *.mp4 | *.m4v | *.avi | *.wmv | *.xvid | *.divx | *.mpg | *.mpeg | *.iso);;
      *.srt | *.tmp | *.stats | .ds_store) echo "File skipped" && continue;;
      *) echo "File is not convertable" && continue;;
    esac
    lsof 2>&1 | grep "${FILE}" &>/dev/null && echo "File is in use" && continue
    [[ "${FILE_NAME}" == "${FILE_NAME##*.}" ]] && \
    NEW_FILE_NAME="${FILE_NAME}.${CONFIG[EXTENSION]}" || \
    NEW_FILE_NAME="${FILE_NAME//${FILE_NAME##*.}/${CONFIG[EXTENSION]}}"
    [[ ! -z "${CONFIG[OUTPUT]}" && "${CONFIG[OUTPUT]}" != "${INPUT}" ]] && \
    DIRECTORY="${DIRECTORY//${INPUT%/}/${CONFIG[OUTPUT]}}"
    [[ ! -e "${DIRECTORY}" ]] && mkdir -p "${DIRECTORY}"
    NEW_FILE="${DIRECTORY}/${NEW_FILE_NAME}"
    DATA=$(${CONFIG[FFPROBE]} "${FILE}" -v quiet -print_format json -show_format -show_streams 2>&1)
    [[ "${DATA}" =~ drm ]] && echo "File is DRM protected" && continue
    COMMAND="${CONFIG[FFMPEG]} -threads ${CONFIG[THREADS]}"
    if [[ "${CONFIG[ENCODER]}" != "software" ]]; then
      COMMAND+=" -hwaccel ${CONFIG[ENCODER]}"
      [[ "${CONFIG[ENCODER]}" == "vaapi" ]] && \
      COMMAND+=" -hwaccel_device /dev/dri/renderD128"
      [[ "${CONFIG[ENCODER]}" != "auto" ]] && \
      COMMAND+=" -hwaccel_output_format ${CONFIG[ENCODER]}"
    fi
    COMMAND+=" -i \"${FILE}\""
    TOTAL=$(jq '.streams | length' <<< "${DATA}");
    SKIP=true; VIDEO=0; AUDIO=0; SUBTITLE=0
    for ((i = 0; i < ${TOTAL}; i++)); do MAP="0:${i}"
      CODEC_TYPE=$(jq -r ".streams[${i}].codec_type" <<< "${DATA}")
      CODEC_NAME=$(jq -r ".streams[${i}].codec_name" <<< "${DATA}")
      MESSAGE="Stream found; map=${MAP}; type=${CODEC_TYPE}; codec=${CODEC_NAME}"
      LANGUAGE=$(jq -r ".streams[${i}].tags.language" <<< "${DATA}")
      case "${LANGUAGE,,}" in
        null|unk|und) LANGUAGE="${CONFIG_DEFAULT_LANGUAGE}";;
      esac
      [[ "${CODEC_TYPE}" == "audio" || "${CODEC_TYPE}" == "subtitle" ]] && \
      MESSAGE+="; language=${LANGUAGE}"; log "${MESSAGE}"
      [[ ! "${CONFIG_LANGUAGES[*]}" =~ ${LANGUAGE} ]] && continue
      BIT_RATE=$(jq -r ".streams[${i}].bit_rate" <<< "${DATA}")
      [[ "${BIT_RATE}" == "null" ]] && \
      BIT_RATE=$(jq -r ".streams[${i}].tags.\"BPS-${LANGUAGE}\"" <<< "${DATA}")
      BIT_RATE=$((BIT_RATE / 1024))
      if [[ "${CODEC_TYPE}" == "video" ]]; then
        ((VIDEO > 0)) && continue
        (( $(jq -r ".streams[${i}].disposition.attached_pic" <<< "${DATA}") == 1 )) && continue
        if [[ "${BIT_RATE}" == "null" ]]; then
          log "Stream issue; bit_rate=N/A; Using format.bit_rate (not accurate)"
          for ((a = 0; a < ${TYPE}; a++)); do
            [[ $(jq -r ".streams[${a}].codec_type" <<< "${DATA}") != "audio" ]] && continue
            b=$(jq -r ".streams[${a}].bit_rate" <<< "${DATA}")
            [[ "${b}" == "null" ]] && \
            b=$(jq -r ".streams[${a}].tags.\"BPS-${LANGUAGE}\"" <<< "${DATA}")
            if [[ "${b}" == "null" ]]; then
              [[ $(jq -r ".streams[${a}].codec_name" <<< "${DATA}") == "aac" ]] && \
              AUDIO_TOTAL=$((AUDIO_TOTAL + 128000)) || \
              AUDIO_TOTAL=$((AUDIO_TOTAL + 768000))
            fi
            AUDIO_TOTAL=$((AUDIO_TOTAL + b))
          done
          BIT_RATE=$(( $(jq -r ".format.bit_rate" <<< "${DATA}") - AUDIO_TOTAL / 1024))
        fi
        if ${CONFIG[VERBOSE]}; then
          FRAMES=$(jq -r ".streams[${i}].nb_frames" <<< "${DATA}")
          [[ "${FRAMES}" == "null" ]] && \
          FRAMES=$(jq -r ".streams[${i}].tags.\"NUMBER_OF_FRAMES-${LANGUAGE}\"" <<< "${DATA}")
          if [[ "${FRAMES}" == "null" ]]; then
            log "Stream issue; nb_frames=N/A; calculating based on DURATION*FPS"
            FPS=$(${CONFIG[FFPROBE]} "${FILE}" 2>&1 | \
            sed -n "s/.*, \\(.*\\) fps.*/\\1/p")
            DUR=$(${CONFIG[FFPROBE]} "${FILE}" 2>&1 | \
            sed -n "s/.* Duration: \\([^,]*\\), .*/\\1/p" | \
            awk -F ':' '{print $1*3600+$2*60+$3}')
            FRAMES=$(echo "${DUR}" "${FPS}" | \
            awk '{printf("%3.0f\n",($1*$2))}' | head -1)
          fi
          STATSFILE="${NEW_FILE}.$$.stats"
          [ -e "${STATSFILE}" ] && rm -f "${STATSFILE}"
          TMPFILES+=("${STATSFILE}")
          COMMAND+=" -progress \"${STATSFILE}\""
        fi
        COMMAND+=" -map ${MAP}"
        if [[ "${CONFIG[VIDEO_CODEC]}" != "source" ]] && \
        ! ${CONFIG[FORCE_VIDEO]}; then
          [[ "${CODEC_NAME}" != "${CONFIG_VIDEO_CODEC}" ]] && \
          log "Codec mismatch; config=${CONFIG_VIDEO_CODEC} stream=${CODEC_NAME}" && SKIP=false
          WIDTH=$(jq -r ".streams[${i}].width" <<< "${DATA}")
          HEIGHT=$(jq -r ".streams[${i}].height" <<< "${DATA}")
          [[ "${CONFIG[RESOLUTION]}" != "source" ]] && \
          (( WIDTH > ${CONFIG[RESOLUTION]%%x*} || HEIGHT > ${CONFIG[RESOLUTION]##*x} )) && \
          log "Resolution exceeded; config=${CONFIG[RESOLUTION]}; stream=${WIDTH}x${HEIGHT}" && \
          SKIP=false && COMMAND+=" -filter:v:${VIDEO} \"scale=${CONFIG[RESOLUTION]%%x*}:-2\""
          PROFILE=$(jq -r ".streams[${i}].profile" <<< "${DATA}"); PROFILE="${PROFILE,,}"
          [[ "${CONFIG[PROFILE]}" != "source" ]] && \
          [[ ! "${PROFILE}" =~ ${CONFIG[PROFILE]} ]] && \
          log "Profile mismatch; config=${CONFIG[PROFILE]}; stream=${PROFILE}" && \
          SKIP=false && COMMAND+=" -profile:v:${VIDEO} ${CONFIG[PROFILE]}"
          LEVEL=$(jq -r ".streams[${i}].level" <<< "${DATA}")
          if [[ "${CODEC_NAME}" != "hevc" ]] && \
          [[ "${CONFIG[LEVEL]}" != "source" ]] && \
          (( LEVEL > ${CONFIG[LEVEL]//./} )); then
            ${CONFIG[FORCE_LEVEL]} || ! (( LEVEL == ${CONFIG[LEVEL]//./} )) && \
            log "Level exceeded; config=${CONFIG[LEVEL]}; stream=${LEVEL}" && \
            SKIP=false && COMMAND+=" -level:${VIDEO} ${CONFIG[LEVEL]}"
          fi
          PIX_FMT=$(jq -r ".streams[${i}].pix_fmt" <<< "${DATA}")
          [[ "${CONFIG[PIXEL_FORMAT]}" != "source" ]] && \
          [[ ! "${PIX_FMT}" =~ ${CONFIG[PIXEL_FORMAT]} ]] && \
          log "Pixel format mismatch; config=${CONFIG[PIXEL_FORMAT]}; stream=${PIX_FMT}" && \
          SKIP=false && COMMAND+=" -pix_fmt:${VIDEO} ${CONFIG[PIXEL_FORMAT]}"
          [[ "${CONFIG[VIDEO_BITRATE]}" != "source" ]] && \
          (( BIT_RATE > ${CONFIG[VIDEO_BITRATE]} )) && \
          log "Bit rate exceeded; config=${CONFIG[VIDEO_BITRATE]}; stream=${BIT_RATE}" && \
          SKIP=false && COMMAND+=" -maxrate:${VIDEO} ${CONFIG[VIDEO_BITRATE]}k -bufsize:${VIDEO} $((CONFIG[VIDEO_BITRATE] * 2))k"
        fi
        if ${CONFIG[FORCE_VIDEO]} || ! ${SKIP}; then
          SKIP=false; COMMAND+=" -c:v:${VIDEO} ${CONFIG[VIDEO_CODEC]}"
          [[ "${CONFIG[TUNE]}" != "false" ]] && \
          COMMAND+=" -tune:${VIDEO} ${CONFIG[TUNE]}"
          COMMAND+=" -preset:${VIDEO} ${CONFIG[PRESET]}"
          COMMAND+=" -crf:${VIDEO} ${CONFIG[CRF]}"
        else
          COMMAND+=" -c:v:${VIDEO} copy"
        fi
        [[ "${CONFIG_VIDEO_CODEC}" == "hevc" ]] && \
        COMMAND+=" -tag:v:${VIDEO} hvc1"
        ((VIDEO++)) || true
      elif [[ "${CODEC_TYPE}" == "audio" ]]; then
        FILTER=$(jq -r ".streams[${i}]" <<< "${DATA}")
        [[ "${FILTER,,}" =~ commentary ]] && continue
        CODEC="${CONFIG[AUDIO_CODEC]}"
        [[ "${CODEC}" == "source" ]] && \
        [[ "${CODEC_NAME}" != "aac" || ! "${CODEC_NAME}" =~ ac3 ]] && CODEC="aac"
        CHANNELS=$(jq -r ".streams[${i}].channels" <<< "${DATA}");
        if ${CONFIG[DUAL_AUDIO]}; then
          (( AUDIO == ((${#CONFIG_LANGUAGES[@]} * 2)) )) && continue
          AAC=false; AC3=false; for ((a = 0; a < ${TOTAL}; a++)); do
            FILTER=$(jq -r ".streams[${a}]" <<< "${DATA}")
            [[ "${FILTER,,}" =~ commentary ]] && continue
            TYPE=$(jq -r ".streams[${a}].codec_type" <<< "${DATA}")
            if [[ "${TYPE}" == "audio" ]]; then
              LANG=$(jq -r ".streams[${i}].tags.language" <<< "${DATA}")
              case "${LANG,,}" in
                null|unk|und) LANG="${CONFIG_DEFAULT_LANGUAGE}";;
              esac
              [[ "${LANG}" != "${LANGUAGE}" ]] && continue
              NAME=$(jq -r ".streams[${a}].codec_name" <<< "${DATA}")
              [[ "${NAME}" == "aac" ]] && AAC=true && AAC_INDEX="0:${a}"
              [[ "${NAME}" =~ ac3 ]] && \
              (( $(jq -r ".streams[${a}].channels" <<< "${DATA}") > 2 )) && \
              AC3=true && AC3_INDEX="0:${a}"
            fi
          done
          if ${AAC}; then
            if ((BIT_RATE > 131072)) || ((CHANNELS > 2)); then
              SKIP=false; COMMAND+=" -map ${AAC_INDEX} -c:a:${AUDIO} aac"
              ${CONFIG[NORMALIZE]} && COMMAND+=" -filter:a:${AUDIO} loudnorm"
              ((BIT_RATE > 131072)) && COMMAND+=" -b:a:${AUDIO} 128k"
              ((CHANNELS > 2)) && COMMAND+=" -ac:a:${AUDIO} 2"
            else
              COMMAND+=" -map ${AAC_INDEX} -c:a:${AUDIO} copy"
            fi
            COMMAND+=" -metadata:s:a:${AUDIO} \"language=${LANGUAGE}\""
            (( AUDIO == 0 )) && \
            COMMAND+=" -disposition:a:${AUDIO} default" || \
            COMMAND+=" -disposition:a:${AUDIO} 0"; ((AUDIO++)) || true
          elif ! ${AAC} && ((CHANNELS >= 2)); then
            log "Dual audio; creating missing AAC from stream"
            SKIP=false; COMMAND+=" -map ${MAP} -c:a:${AUDIO} aac"
            ${CONFIG[NORMALIZE]} && COMMAND+=" -filter:a:${AUDIO} loudnorm"
            ((BIT_RATE > 131072)) && COMMAND+=" -b:a:${AUDIO} 128k"
            ((CHANNELS > 2)) && COMMAND+=" -ac:a:${AUDIO} 2"
            COMMAND+=" -metadata:s:a:${AUDIO} \"language=${LANGUAGE}\""
            (( AUDIO == 0 )) && \
            COMMAND+=" -disposition:a:${AUDIO} default" || \
            COMMAND+=" -disposition:a:${AUDIO} 0"; ((AUDIO++)) || true
          fi
          if ${AC3}; then
            COMMAND+=" -map ${AC3_INDEX} -c:a:${AUDIO} copy"
            COMMAND+=" -metadata:s:a:${AUDIO} \"language=${LANGUAGE}\""
            COMMAND+=" -disposition:a:${AUDIO} 0"; ((AUDIO++)) || true
          elif ! ${AC3} && ((CHANNELS > 2)); then
            log "Dual audio; creating missing AC3 from stream"
            SKIP=false; COMMAND+=" -map ${MAP} -c:a:${AUDIO} ac3"
            COMMAND+=" -metadata:s:a:${AUDIO} \"language=${LANGUAGE}\""
            COMMAND+=" -disposition:a:${AUDIO} 0"; ((AUDIO++)) || true
          fi
        else
          (( AUDIO == ${#CONFIG_LANGUAGES[@]} )) && continue
          if [[ ! "${CODEC_NAME}" =~ ${CONFIG[AUDIO_CODEC]} ]] || ${CONFIG[FORCE_AUDIO]}; then
            COMMAND+=" -map ${MAP} -c:a:${AUDIO} ${CODEC}"
            ${CONFIG[NORMALIZE]} && COMMAND+=" -filter:a:${AUDIO} loudnorm"
            ((BIT_RATE > CONFIG[AUDIO_BITRATE])) && \
            log "Bit rate exceeded; config=${CONFIG[AUDIO_BITRATE]}; stream=${BIT_RATE}" && \
            COMMAND+=" -b:a:${AUDIO} ${CONFIG[AUDIO_BITRATE]}k"
            ((CHANNELS > CONFIG[AUDIO_CHANNELS])) && \
            log "Channels exceeded; config=${CONFIG[AUDIO_CHANNELS]}; stream=${CHANNELS}" && \
            COMMAND+=" -ac:a:${AUDIO} ${CONFIG[AUDIO_CHANNELS]}"; SKIP=false
          else
            COMMAND+=" -map ${MAP} -c:a:${AUDIO} copy"
          fi
          COMMAND+=" -metadata:s:a:${AUDIO} \"language=${LANGUAGE}\""
          (( AUDIO == 0 )) && \
          COMMAND+=" -disposition:a:${AUDIO} default" || \
          COMMAND+=" -disposition:a:${AUDIO} 0"; ((AUDIO++)) || true
        fi
      elif [[ "${CODEC_TYPE}" == "subtitle" ]]; then
        (( SUBTITLE == ${#CONFIG_LANGUAGES[@]} )) && continue
        case "${CODEC_NAME}" in
          hdmv_pgs_subtitle|pgssub|dvb_subtitle|\
          dvd_subtitle|dvdsub|s_hdmv/pgs|dvb_teletext|subrip)
          continue;;
        esac
        (( $(jq -r ".streams[${i}].disposition.forced" <<< "${DATA}") == 1 )) && continue
        if ${CONFIG[SUBTITLES]}; then
          if [[ "${CODEC_NAME}" != "mov_text" ]] || ${CONFIG[FORCE_SUBTITLES]}; then
            log "Codec mismatch; required=mov_text; config_forced=${CONFIG[FORCE_SUBTITLES]}"
            COMMAND+=" -map ${MAP} -c:s:${SUBTITLE} mov_text"
            COMMAND="${COMMAND//\ -i\ /\ -fix_sub_duration\ -i\ }"; SKIP=false
          else
            COMMAND+=" -map ${MAP} -c:s:${SUBTITLE} copy"
          fi
          COMMAND+=" -metadata:s:s:${SUBTITLE} \"language=${LANGUAGE}\""
          ((SUBTITLE++)) || true
        else
          if [[ "${CONFIG[SUBTITLES]}" == "extract" ]]; then
            SRT_FILE="${DIRECTORY}/${FILE_NAME%.*}.${LANGUAGE}.srt"
            EXTRACT_COMMAND="${CONFIG[FFMPEG]} -i \"${FILE}\" -vn -an -map ${MAP} -c:s:${SUBTITLE} srt \"${SRT_FILE}\""
            log "${EXTRACT_COMMAND}"; echo "Extracting subtitle..."
            TMPFILES+=("${SRT_FILE}")
            ${CONFIG[DEBUG]} && eval "${EXTRACT_COMMAND} &" || eval "${EXTRACT_COMMAND} &" &>/dev/null; CONVERTER=${!}
            wait ${CONVERTER} &>/dev/null
            [[ ${?} -ne 0 ]] && echo "Result: failure" || TMPFILES=("${TMPFILES[@]//${SRT_FILE}/}")
            echo "Result: success"
            ((SUBTITLE++)) || true
          fi; COMMAND+=" -sn"; SKIP=false
        fi
      fi
    done
    ((VIDEO < 1)) && echo "No usable video streams, is this a media file?" && continue
    ((AUDIO < 1)) && echo "No usable audio streams, is this a media file?" && continue
    OUTPUT_STREAMS=$((VIDEO+AUDIO+SUBTITLE))
    [[ "${TOTAL}" != "${OUTPUT_STREAMS}" ]] && SKIP=false
    TMP_FILE="${NEW_FILE}.$$.tmp"
    [[ -e "${TMP_FILE}" ]] && rm -f "${TMP_FILE}"
    COMMAND+=" -max_muxing_queue_size 1024 -map_metadata -1"
    COMMAND+=" -f ${CONFIG[FORMAT]} -flags +global_header"
    ${CONFIG[FAST]} && COMMAND+=" -movflags +faststart"
    COMMAND+=" -strict -2 -y \"${TMP_FILE}\""
    ${SKIP} && echo "File does not need to be converted" && continue
    log "${COMMAND}"; echo "Converting..."; TMPFILES+=("${TMP_FILE}")
    ${CONFIG[DEBUG]} && eval "${COMMAND} &" || eval "${COMMAND} &" &>/dev/null; CONVERTER=${!};
    ${CONFIG[VERBOSE]} && progress &
    ${CONFIG[BACKGROUND]} && background &
    wait ${CONVERTER} &>/dev/null
    if [[ ${?} -ne 0 ]]; then
      echo "Result: failure";
      [[ ! -z "${NZBPP_TOTALSTATUS}" ]] && \
      ${NZBPO_BAD} && echo "[NZB] MARK=BAD"; exit "${FAILURE}"
    fi; echo "Result: success"
    FILE_SIZE=$(ls -l "${FILE}" 2>&1 | awk '{print($5)}')
    TMP_SIZE=$(ls -l "${TMP_FILE}" 2>&1 | awk '{print($5)}')
    EFFICIENCY=$(echo "${FILE_SIZE}" "${TMP_SIZE}" | awk \
    '{printf("%.2f\n",($2-$1)/$1*100)}')
    HFS=$(formatBytes "${FILE_SIZE}")
    HTS=$(formatBytes "${TMP_SIZE}")
    echo "Efficiency: ${EFFICIENCY}%;" \
    "Original=${HFS}; Converted=${HTS}"
    if ${CONFIG[STATS]}; then
      CONFIG[OFS]=$(( FILE_SIZE + ${CONFIG[OFS]} ))
      CONFIG[CFS]=$(( TMP_SIZE + ${CONFIG[CFS]} ))
      EFFICIENCY=$(echo "${CONFIG[OFS]}" "${CONFIG[CFS]}" | awk \
      '{printf("%.2f\n",($2-$1)/$1*100)}')
      OFS=$(formatBytes "${CONFIG[OFS]}")
      CFS=$(formatBytes "${CONFIG[CFS]}")
      sed -i "s/^OFS=.*/OFS=${CONFIG[OFS]}/" "${CONFIG_FILE}"
      sed -i "s/^CFS=.*/CFS=${CONFIG[CFS]}/" "${CONFIG_FILE}"
      echo "[STATS] Total Efficiency: ${EFFICIENCY}%"
      echo "[STATS] Total Original File Sizes: ${OFS}"
      echo "[STATS] Total Converted File Sizes: ${CFS}"
    fi
    touch -r "${FILE}" "${TMP_FILE}"
    ${CONFIG[DELETE]} && rm -f "${FILE}" && mv "${TMP_FILE}" "${NEW_FILE}" || \
    TMPFILES=("${TMPFILES[@]//${TMP_FILE}/}")
    chmod "${CONFIG[FILE_PERMISSION]}" "${NEW_FILE}"
    chmod "${CONFIG[DIRECTORY_PERMISSION]}" "${DIRECTORY}"; clean
    ${CUSTOM} && (( CURRENTFILE < ${#FILES} )) && loadConfig && CUSTOM=false
  done
done

exit "${SUCCESS}"
