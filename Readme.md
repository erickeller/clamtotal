# A proof of concept integrating ClamAv with VirusTotal

## Prerequisits

Install ClamAv

```
sudo apt-get update && sudo apt-get install clamav clamav-freshclam clamav-testfiles
```

Create an account at https://www.virustotal.com in order to get your api key.

## Configuration


## Clamscan

```
RESULTS=/tmp/$(date -Im)-clamscan.log
mkdir -p /tmp/infected
nice -n -19 /usr/bin/clamscan \
  --infected \
  --recursive=yes \
  --copy=/tmp/infected
  -l "${RESULTS}" .
```

This will resutls in any suspicious file to be copied into /tmp/infected.
The `/tmp/$(date -Im)-clamscan.log` will contain the detail.

If the clamscan return code equals 1 we should provide some checksum to the virustotal api.

## nmap http-virustotal

Combining nmap and the http-virustotal script

```
nmap --script http-virustotal --script-args='http-virustotal.apikey="<key>",http-virustotal.checksum="275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f"'
```

in this case the checksum of a file is provied. One can also upload a file

```
nmap --script http-virustotal --script-args='http-virustotal.apikey="<key>",http-virustotal.upload="true",http-virustotal.filename="/tmp/infected/escar"'
```

## push files to remote /incoming

Additionally we can push these files to a remote directory where 3rd party virus tool also scan.
The idea here is to pack the file as zip containing the hostname.

```
zip -r $(date -Im)-$(hostname)-to-verify.zip /tmp/infected
```

