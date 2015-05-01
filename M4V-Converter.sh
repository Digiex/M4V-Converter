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

# Debug Mode (true, false).
# Prints extra details, useful for debugging.
#Debug=true

# Test Mode (true, false).
# When enabled this script does nothing.
#Test=true

# Number of Threads (1-8).
# This is how many threads FFMPEG will use for conversion.
#Threads=auto

# Preferred Language.
# This is the language(s) you prefer.
#
# English (eng), French (fre), German (ger), Italian (ita), Spanish (spa), * (all).
#
# NOTE: This is used for audio and subtitles. The first listed is considered the default.
#Language=

# H264 Preset (ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow).
# This is the preset used for converting the video, if required.
#
# NOTE: Slower is more compressed and has better quality but takes more time.
#Preset=fast

# Video Bitrate (KB).
# Use this to limit video bitrate, if it exceeds this limit then video will be converted.
#Video Bitrate=8000

# Create Dual Audio Streams (true, false).
# This will create two audio streams, if possible. AAC 2.0 and AC3 5.1.
#
# NOTE: AAC will be the default for better compatability with more devices.
#Dual Audio=true

# Copy Subtitles (true, false).
# This will copy subtitles of your matching language(s) into the converted file.
#
# NOTE: Disable if you use Plex or such to download subtitles. This does not apply to forced subtitles. 
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

# Sample Size (MB).
# Any size less than the specified size is considered a sample.
#Size=200

# Delete Samples (NONE, NAME, SIZE, BOTH).
# This will delete sample files.
#  NONE - disabled.
#  NAME - deletes samples based on name.
#  SIZE - deletes samples based on size.
#  BOTH - deletes samples based on name & size.
#Samples=both

# Cleanup Files.
# This will delete extra files with the above file extensions.
#Cleanup=.nfo, .nzb

### NZBGET POST-PROCESSING SCRIPT                                          ###
##############################################################################

POSTPROCESS_SUCCESS=93
POSTPROCESS_ERROR=94
POSTPROCESS_NONE=95

success=false
failure=false

tmpFiles=()

if [[ "${NZBPP_TOTALSTATUS}" != "SUCCESS" ]]; then
	exit ${POSTPROCESS_NONE}
fi

onExit() {
	for file in "${tmpFiles[@]}"; do
		if [[ -e "${file}" ]]; then
			rm "${file}"
		fi
	done
}
trap onExit EXIT

echo "Searching for files..."
files=$(find "${NZBPP_DIRECTORY}" -type f)
if [[ ! -z "${files}" ]]; then
	if ! ${NZBPO_TEST}; then
		case "${NZBPO_SAMPLES^^}" in
			NAME)
				while read file; do
					if [[ "${file,,}" =~ sample ]] || [[ "${file,,}" =~ trailer ]]; then
						rm "${file}"
					fi
				done <<< "${files}"
			;;
			SIZE)
				samples=$(find "${NZBPP_DIRECTORY}" -type f -size -"${NZBPO_SIZE//[^0-9]*/}"M)
				if [[ ! -z "${samples}" ]]; then
					nzbsize=$(du -sb "${NZBPP_DIRECTORY}" | awk '{print($1)}')
					samplesize=$(( NZBPO_SIZE * 1024 * 1024 ))
					if (( nzbsize > samplesize )); then
						while read file; do
							rm "${file}"
						done <<< "${samples}"
					fi
				fi
			;;
			BOTH)
				while read file; do
					if [[ "${file,,}" =~ sample ]] || [[ "${file,,}" =~ trailer ]]; then
						rm "${file}"
					fi
				done <<< "${files}"
				samples=$(find "${NZBPP_DIRECTORY}" -type f -size -"${NZBPO_SIZE//[^0-9]*/}"M)
				if [[ ! -z "${samples}" ]]; then
					nzbsize=$(du -sb "${NZBPP_DIRECTORY}" | awk '{print($1)}')
					samplesize=$(( NZBPO_SIZE * 1024 * 1024 ))
					if (( nzbsize > samplesize )); then
						while read file; do
							rm "${file}"
						done <<< "${samples}"
					fi
				fi
			;;
		esac
		read -a extensions <<< "$(echo "${NZBPO_CLEANUP}" | sed s/\ //g | sed s/\\.//g | sed s/,/\ /g)"
		if (( ${#extensions[@]} > 0 )); then
			while read file; do
				for ((i = 0; i < ${#extensions[@]}; i++)); do
					if [[ "${file##*.}" == "${extensions[${i}]}" ]]; then
						rm "${file}"
					fi
				done
			done <<< "${files}"
		fi
	fi

	if [[ -z "${NZBPO_LANGUAGE}" ]]; then
		NZBPO_LANGUAGE="*"
	fi
	read -a languages <<< "$(echo "${NZBPO_LANGUAGE}" | sed s/\ //g | sed s/,/\ /g)"
	defaultlanguage="${languages[0]}"

	while read file; do
		case "${file}" in
			*.mkv | *.mp4 | *.m4v | *.avi | *.wmv | *.xvid | *.divx | *.mpg | *.mpeg)
				echo "Found a file needing to be converted."
				echo "File: ${file}"
				lsof "${file}" 2>&1 | grep -q COMMAND &>/dev/null
				if [[ $? -ne 0 ]]; then
					command="ffmpeg -threads ${NZBPO_THREADS} -i \"${file}\""
					newfile="${file//${file##*.}/${NZBPO_EXTENSION,,}}"
					tmpfile="${newfile}.tmp"
					tmpFiles+=("${tmpfile}")
					data="$(ffprobe "${file}" 2>&1)"

					cv="$(echo "${data}" | grep "Video:" | sed s/\ \ \ \ \ //g)"
					if [[ -z "${cv}" ]]; then
						echo "The file was missing video. Fake? Skipping..."
						failure=true
						continue
					fi

					video=()
					readarray -t video <<< "${cv}"
					for ((i = 0; i < ${#video[@]}; i++)); do
						if [[ -z "${video[${i}]}" ]]; then
							continue
						fi
						if [[ $(ffprobe "${file}" -show_streams -select_streams v:${i} 2>&1 | grep -i "TAG:mimetype=" | tr '[:upper:]' '[:lower:]' | sed s/tag:mimetype=//g) == "image/jpeg" ]]; then
							continue
						fi
						videomap=$(echo "${video[${i}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
						if (( ${#videomap} > 3 )); then
							videomap=${videomap%:*}
						fi
						videocodec=$(echo "${video[${i}]}" | awk '{print($4)}')
						vb=$(ffprobe "${file}" -show_streams -select_streams v:${i} 2>&1 | grep -i "BIT_RATE=" | tr '[:upper:]' '[:lower:]' | sed s/bit_rate=//g | sed s/[^0-9]*//g)
						if [[ -z ${vb} ]]; then
							vb=0
						fi
						videobitratelimit="${NZBPO_VIDEO_BITRATE//[^0-9]*/}"
						videobitrate=$(( vb / 1024 ))
						if [[ "${videocodec}" == "h264" ]] || [[ "${videocodec}" == "x264" ]]; then
							if (( videobitrate > videobitratelimit )); then
								command+=" -map ${videomap} -c:v libx264 -preset ${NZBPO_PRESET} -profile:v baseline -level 3.0 -b:v:${i} ${videobitratelimit}k"
							else 
								command+=" -map ${videomap} -c:v copy"
							fi
						else
							command+=" -map ${videomap} -c:v libx264 -preset ${NZBPO_PRESET} -profile:v baseline -level 3.0"
							if (( videobitrate > videobitratelimit )); then
								command+=" -b:v:${i} ${videobitratelimit}k"
							fi
						fi
						if [[ "${defaultlanguage}" != "*" ]]; then
							videolang=$(ffprobe "${file}" -show_streams -select_streams v:${i} 2>&1 | grep -i "TAG:LANGUAGE=" | tr '[:upper:]' '[:lower:]' | sed s/tag:language=//g)
							if [[ -z "${videolang}" ]] || [[ "${videolang}" == "und" ]] || [[ "${videolang}" == "unk" ]]; then
								command+=" -metadata:s:v:${i} language=${defaultlanguage}"
							fi
						fi
					done

					ca="$(echo "${data}" | grep "Audio:" | sed s/\ \ \ \ \ //g)"
					if [[ -z "${ca}" ]]; then
						echo "The file was missing audio. Fake? Skipping..."
						failure=true
						continue
					fi

					audio=()
					audiostreams=()
					declare -A dualaudio
					readarray -t audio <<< "$(echo "${data}" | grep "Audio:" | sed s/\ \ \ \ \ //g)"
					for ((i = 0; i < ${#audio[@]}; i++)); do
						if [[ -z "${audio[${i}]}" ]]; then
							continue
						fi
						audiodata=$(ffprobe "${file}" -show_streams -select_streams a:${i} 2>&1)
						audiolang="$(echo "${audiodata}" | grep -i "TAG:LANGUAGE=" | tr '[:upper:]' '[:lower:]' | sed s/tag:language=//g)"
						audiocodec="$(echo "${audiodata}" | grep -i "CODEC_NAME=" | tr '[:upper:]' '[:lower:]' | sed s/codec_name=//g)"
						audiochannels=$(echo "${audiodata}" | grep -i "CHANNELS=" | tr '[:upper:]' '[:lower:]' | sed s/channels=//g)
						if [[ -z "${audiolang}" ]] || [[ "${audiolang}" == "und" ]] || [[ "${audiolang}" == "unk" ]]; then
							audiolang="${defaultlanguage}"
						fi
						if [[ "$(echo "${audiodata}" | tr '[:upper:]' '[:lower:]')" =~ commentary ]]; then # Check more
							continue
						fi
						if [[ "${NZBPO_LANGUAGE}" != "*" ]]; then
							allowed=false
							for ((l = 0; l < ${#languages[@]}; l++)); do
								if [[ -z "${languages[${l}]}" ]]; then
									continue
								fi
								if [[ "${audiolang}" != "${languages[${l}]}" ]]; then
									continue
								fi
								allowed=true
							done
							if ! ${allowed}; then
								continue
							fi
						fi
						if ${NZBPO_DUAL_AUDIO}; then
							aac=false
							ac3=false
							if [[ ! -z "${dualaudio[${audiolang}]}" ]]; then
								aac=${dualaudio[${audiolang}]%%:*}
								ac3=${dualaudio[${audiolang}]#*:}
							fi
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
								continue
							fi
							dualaudio["${audiolang}"]="${aac}:${ac3}"
						else
							have=false
							for ((s = 0; s < ${#audiostreams[@]}; s++)); do
								if [[ -z "${audiostreams[${s}]}" ]]; then
									continue
								fi
								lang=$(ffprobe "${file}" -show_streams -select_streams a:${s} 2>&1 | grep -i "TAG:LANGUAGE=" | tr '[:upper:]' '[:lower:]' | sed s/tag:language=//g)
								if [[ -z "${lang}" ]] || [[ "${lang}" == "und" ]] || [[ "${lang}" == "unk" ]]; then
									lang="${defaultlanguage}"
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
					a=0
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
							audiomap=$(echo "${audiostreams[${s}]}" | awk '{print($2)}' | sed -E 's/#|\(.*//g')
							if (( ${#audiomap} > 3 )); then
								audiomap=${audiomap%:*}
							fi
							audiocodec=$(echo "${audiostreams[${s}]}" | awk '{print($4)}')
							if [[ "${audiocodec}" == *, ]]; then
								audiocodec=${audiocodec%?}
							fi
							audiochannels=$(ffprobe "${file}" -show_streams -select_streams a:${i} 2>&1 | grep -i "CHANNELS=" | tr '[:upper:]' '[:lower:]' | sed s/channels=//g)
							audiolang=$(ffprobe "${file}" -show_streams -select_streams a:${i} 2>&1 | grep -i "TAG:LANGUAGE=" | tr '[:upper:]' '[:lower:]' | sed s/tag:language=//g)
							tag=false
							if [[ -z "${audiolang}" ]] || [[ "${audiolang}" == "und" ]] || [[ "${audiolang}" == "unk" ]]; then
								audiolang="${defaultlanguage}"
								tag=true
							fi
							if ${NZBPO_DUAL_AUDIO}; then
								aac=false
								ac3=false
								if [[ ! -z "${dualaudio[${audiolang}]}" ]]; then
									aac=${dualaudio[${audiolang}]%%:*}
									ac3=${dualaudio[${audiolang}]#*:}
								fi
								if ${aac} && ${ac3}; then
									command+=" -map ${audiomap} -c:a:${a} copy"
								else
									if [[ "${audiocodec}" == "aac" ]]; then
										if (( audiochannels > 2 )); then
											command+=" -map ${audiomap} -c:a:${a} aac -ac:a:${a} 2 -ab:a:0 256k"
											if ${tag} && [[ "${defaultlanguage}" != "*" ]]; then
												command+=" -metadata:s:a:${a} language=${defaultlanguage}"
											fi
											((a++))
											command+=" -map ${audiomap} -c:a:${a} ac3"
										elif (( audiochannels == 2 )); then
											command+=" -map ${audiomap} -c:a:${a} copy"
										else
											command+=" -map ${audiomap} -c:a:${a} aac"
										fi
									elif [[ "${audiocodec}" == "ac3" ]]; then
										if (( audiochannels > 2 )); then
											command+=" -map ${audiomap} -c:a:${a} aac -ac:a:${a} 2 -ab:a:0 256k"
											if ${tag} && [[ "${defaultlanguage}" != "*" ]]; then
												command+=" -metadata:s:a:${a} language=${defaultlanguage}"
											fi
											((a++))
											command+=" -map ${audiomap} -c:a:${a} copy"
										else
											command+=" -map ${audiomap} -c:a:${a} aac"
										fi
									else
										if (( audiochannels > 2 )); then
											command+=" -map ${audiomap} -c:a:${a} aac -ac:a:${a} 2 -ab:a:0 256k"
											if ${tag} && [[ "${defaultlanguage}" != "*" ]]; then
												command+=" -metadata:s:a:${a} language=${defaultlanguage}"
											fi
											((a++))
											command+=" -map ${audiomap} -c:a:${a} ac3"
										else
											command+=" -map ${audiomap} -c:a:${a} aac"
										fi
									fi
								fi
							else
								if [[ "${audiocodec}" == "aac" ]]; then
									if (( audiochannels > 2 )); then
										command+=" -map ${audiomap} -c:a:${a} aac -ac:a:${a} 2 -ab:a:${a} 256k"
									elif (( audiochannels == 2 )); then
										command+=" -map ${audiomap} -c:a:${a} copy"
									else
										command+=" -map ${audiomap} -c:a:${a} aac"
									fi
								else
									command+=" -map ${audiomap} -c:a:${a} aac"
								fi
							fi
							if ${tag} && [[ "${defaultlanguage}" != "*" ]]; then
								command+=" -metadata:s:a:${a} language=${defaultlanguage}"
							fi
							((a++))
						done
					done
					unset dualaudio

					if ${NZBPO_SUBTITLES}; then
						subtitle=()
						subtitlestreams=()
						readarray -t subtitle <<< "$(echo "${data}" | grep "Subtitle:" | sed s/\ \ \ \ \ //g)"
						for ((i = 0; i < ${#subtitle[@]}; i++)); do
							if [[ -z "${subtitle[${i}]}" ]]; then
								continue
							fi
							if [[ "${NZBPO_LANGUAGE}" != "*" ]]; then
								subtitledata=$(ffprobe "${file}" -show_streams -select_streams s:${i} 2>&1)
								subtitlelang=$(echo "${subtitledata}" | grep -i "TAG:LANGUAGE=" | tr '[:upper:]' '[:lower:]' | sed s/tag:language=//g)
								if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang}" == "und" ]] || [[ "${subtitlelang}" == "unk" ]]; then
									subtitlelang="${defaultlanguage}"
								fi
								if [[ "${subtitle[${i}]}" =~ hdmv_pgs_subtitle ]]; then
									continue
								fi
								have=false
								for ((s = 0; s < ${#subtitlestreams[@]}; s++)); do
									if [[ -z "${subtitlestreams[${s}]}" ]]; then
										continue
									fi
									lang=$(ffprobe "${file}" -show_streams -select_streams s:${s} 2>&1 | grep -i "TAG:LANGUAGE=" | tr '[:upper:]' '[:lower:]' | sed s/tag:language=//g)
									if [[ -z "${lang}" ]] || [[ "${lang}" == "und" ]] || [[ "${lang}" == "unk" ]]; then
										lang="${defaultlanguage}"
									fi
									if [[ "${lang}" == "${subtitlelang}" ]]; then
										have=true
									fi
								done
								if ${have}; then
									continue
								fi
								if [[  "${subtitlelang}" == "${defaultlanguage}" ]] && [[ ${subtitle[${i}],,} =~ forced ]] || [[ "${subtitlelang}" == "${defaultlanguage}" ]] && [[ $(echo "${subtitledata}" | grep -i "TAG:TITLE=" | tr '[:upper:]' '[:lower:]' | sed s/tag:title=//g) =~ forced ]]; then
									subtitlestreams+=("${subtitle[${i}]}")
									continue
								fi
								for ((l = 0; l < ${#languages[@]}; l++)); do
									if [[ -z "${languages[${l}]}" ]]; then
										continue
									fi
									if [[ "${subtitlelang}" == "${languages[${l}]}" ]]; then
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
								if [[ "${defaultlanguage}" != "*" ]]; then
									subtitlelang=$(ffprobe "${file}" -show_streams -select_streams s:${i} 2>&1 | grep -i "TAG:LANGUAGE=" | tr '[:upper:]' '[:lower:]' | sed s/tag:language=//g)
									if [[ -z "${subtitlelang}" ]] || [[ "${subtitlelang}" == "und" ]] || [[ "${subtitlelang}" == "unk" ]]; then
										command+=" -metadata:s:s:${s} language=${defaultlanguage}"
									fi
								fi
							done
						done
						if [[ "${command}" =~ -c:s ]]; then
							command="${command//-i/-fix_sub_duration\ -i}"
						fi
					fi

					command+=" -f ${NZBPO_FORMAT,,} -movflags +faststart -strict experimental -y \"${tmpfile}\""
					if ${NZBPO_DEBUG}; then
						echo "DEBUG: ${command}"
					fi
					if ${NZBPO_TEST}; then
						continue
					fi
					echo "Converting..."
					echo "${command}" | xargs -0 bash -c &>/dev/null
					if [[ $? -ne 0 ]]; then
						failure=true
						continue
					fi
					if ${NZBPO_DELETE}; then
						rm "${file}"
					fi
					mv "${tmpfile}" "${newfile}"
					success=true
				else
					echo "File was in use. Skipping..."
				fi
			;;
		esac
	done <<< "${files}"
else
	echo "Could not find any files to convert."
fi

if ${success}; then
	exit ${POSTPROCESS_SUCCESS}
else
	if ${failure}; then
		if ${NZBPO_BAD}; then
			echo "[NZB] MARK=BAD"
		fi
		exit ${POSTPROCESS_ERROR}
	else
		exit ${POSTPROCESS_NONE}
	fi
fi