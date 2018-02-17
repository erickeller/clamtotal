#!/bin/sh

test -z ${INFECTED_DIR} && INFECTED_DIR=/tmp/infected
test -z ${SCAN_RESULTS} && SCAN_RESULTS=/tmp/$(date -Im)-$(hostname)-clamscan.log
rm -rf ${INFECTED_DIR}
mkdir -p ${INFECTED_DIR}
sudo nice -n -19 /usr/bin/clamscan \
  --infected \
  --recursive=yes \
  --copy=/tmp/infected \
  -l "${SCAN_RESULTS}" $@
