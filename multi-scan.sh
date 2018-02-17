#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
export INFECTED_DIR=/tmp/infected
export SCAN_RESULTS=/tmp/$(date -Im)-$(hostname)-clamscan.log

if [ $# -lt 1 ]; then
    echo "usage: $0 /path/to/scan [clamscan options]"
    exit 1
fi
if [ ! -d $1 ]; then
    echo "$1 is not a directory"
    exit 1
fi
${SCRIPT_DIR}/scan.sh $@
if [ $? -ne 0 ]; then
    # gather files
    sudo chmod -R 755 ${INFECTED_DIR}
    zip -r $(date -Im)-$(hostname)-to-verify.zip ${INFECTED_DIR}
    for file in $(ls ${INFECTED_DIR}); do
        ./vt-process.sh ${INFECTED_DIR}/${file}
        # VT it is limited to at most 4 requests of any nature in any given 1 minute time frame.
        #60/4*2=30 (at maximum we do 1 request for the checksum and another if nothing was found)
        sleep 30
    done
fi
