# A proof of concept integrating ClamAv with VirusTotal

## Prerequisits

Install ClamAv

```
sudo apt-get update && sudo apt-get install clamav clamav-freshclam clamav-testfiles
```

Create an account at https://www.virustotal.com in order to get your api key.

## Configuration

TODO

## Quick start

in order to test this clamtotal (clamav+virustotal) implemetation run the following script:

```
./multi-scan.sh /usr/share/clamav-testfiles/
```

## Clamscan

```
INFECTED_DIR=/tmp/infected
RESULTS=/tmp/$(date -Im)-clamscan.log
rm -rf ${INFECTED_DIR}
mkdir -p ${INFECTED_DIR}
nice -n -19 /usr/bin/clamscan \
  --infected \
  --recursive=yes \
  --copy=/tmp/infected \
  -l "${RESULTS}" .
```

The complete implementation can be found in the `scan.sh` script.

This will resutls in any suspicious file to be copied into /tmp/infected.
The `/tmp/$(date -Im)-$(hostname)-clamscan.log` will contain the detail.

If the clamscan return code equals 1 we should provide some checksum to the virustotal api.

## Virustotal hooking

Once your clamav scan has completed, you eventually have some suspect (infected) files in the /tmp/infected directory.

```
export VT_API_KEY=6f680a95b....
for file in $(ls ${INFECTED_DIR}); do
  ./vt-process.sh ${file}
done
```

The `vt-process.sh` script does:
 1. compute the file checksum may match a definition in the VT database.
 2. if no reference was found in the database, upload the suspected file.
    The returned scan id is intended to be used for later reporting.

In case it matches the output will be logged as the ratio of antivirus matching.

Note: Depending on the limitation of the rest API especially rate limiting.
We could use the following section to push a zip to one central server which takes the responsibility to queue the virustotal accordingly.

## Push files to remote /incoming

Additionally we can push these files to a remote directory where 3rd party virus tool also scan.
The idea here is to pack the file as zip containing the hostname.

```
zip -r $(date -Im)-$(hostname)-to-verify.zip /tmp/infected
```

## Alternative, nmap http-virustotal

Combining nmap and the http-virustotal script

```
nmap --script http-virustotal --script-args='http-virustotal.apikey="<key>",http-virustotal.checksum="275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f"'
```

in this case the checksum of a file is provied. One can also upload a file

```
nmap --script http-virustotal --script-args='http-virustotal.apikey="<key>",http-virustotal.upload="true",http-virustotal.filename="/tmp/infected/escar"'
```

