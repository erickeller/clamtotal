#!/bin/bash
#set -x #DEBUG

if [ $# -ne 1 ]; then
    echo "usage: $0 /path/to/suspicious/file"
    echo "you provided $# parameters
E: missing input file"
    exit 1
elif [ ! -f $1 ]; then
    echo "E: $1 is not a file"
    exit 1
fi

if [ -z "${VT_API_KEY}" ]; then
    echo "no VT_API_KEY variable for accessing VT was defined"
    exit 2
fi

#TODO: replace it with some other dependency management
check_deps()
{
    local DEP=$1
    if ! which ${DEP} > /dev/null; then
        echo "E: missing ${DEP}, sudo sh -c 'apt-get update && apt install ${DEP}'"
        exit 1
    fi
}

check_deps curl
check_deps jq

INPUT_FILE=$1
INPUT_FILE_CHECKSUM=$(sha256sum ${INPUT_FILE}| awk '{print $1}')

search_checksum()
{
    local CHECKSUM=$1
    set -e
    RESULT=$(curl -s --request POST \
        --url 'https://www.virustotal.com/vtapi/v2/file/report' \
        -d apikey=${VT_API_KEY} \
        -d "resource=${CHECKSUM}")
    set +e

    echo ${RESULT}
}

upload_file()
{
    local FILEPATH=$(readlink -f ${INPUT_FILE})
    set -e
    RESULT=$(curl -s -F "file=@${FILEPATH}" -F \
        apikey=${VT_API_KEY} --url 'https://www.virustotal.com/vtapi/v2/file/scan')
    set +e

    echo ${RESULT}
}

OUTPUT=$(search_checksum ${INPUT_FILE_CHECKSUM} | python -m json.tool)
RETURN_CODE=$(echo ${OUTPUT} | jq '.response_code')
# if return code is 0 it means the checksum was not found on the vt backend
# if the return code is 1 it means it was found and we can check the positive field
#echo $RETURN_CODE #DEBUG

if [ "1" = "${RETURN_CODE}" ]; then
    POSITIVE=$(echo ${OUTPUT} | jq -r '.positives, .total, .scan_id' | tr '\n' '/' | cut -d "/" -f1-2)
    echo "${INPUT_FILE} (${INPUT_FILE_CHECKSUM})
positive match(s): ${POSITIVE}"
elif [ "0" = "${RETURN_CODE}" ]; then
    echo "the file hash (${INPUT_FILE_CHECKSUM}) is unknown to VT database"
    OUTPUT=$(upload_file ${INPUT_FILE} | python -m json.tool)
    RETURN_CODE=$(echo ${OUTPUT} | jq '.response_code')
    SCANID=$(echo ${OUTPUT} | jq -r '.scan_id')
    echo "uploaded ${INPUT_FILE} (${INPUT_FILE_CHECKSUM})
scan_id: $SCANID"
fi

exit 0
