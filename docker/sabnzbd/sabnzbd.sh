#!/usr/bin/env bash

if [[ -z "${SAB_PP_STATUS}" ]]; then
    echo "Sorry, you do not have SABnzbd version 2.0.0 or later."
    exit 2
fi

if ! (( SAB_PP_STATUS == 0 )); then
    exit 0
fi

/app/M4V-Converter/M4V-Converter.sh -c /config/M4V-Converter.conf -i "${SAB_COMPLETE_DIR}"

case ${?} in
    0) exit 0; ;;
    1) exit 1; ;;
    2) exit 0; ;;
    3) exit 2; ;;
    4) exit 3; ;;
esac
