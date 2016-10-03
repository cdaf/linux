#
# Script
#   ssh.sh
#
# Description
#   Installs and configures ssh for SFTP (FTP over SSH).
#
#   Note that FTPS (FTP over SSL) is not supported.
#
# Usage
#   ssh.sh [crAuth passAuth usePAM]
#       crAuth:   yes or no (lowercase only). Enables or disables ChallengeResponseAuthentication. Defaults to no if omitted.
#       passAuth: yes or no (lowercase only). Enables or disables PasswordAuthentication. Defaults to yes if omitted.
#       usePAM:   yes or no (lowercase only). Enables or disables UsePAM. Defaults to yes if omitted.
#
#   Examples
#       For an SFTP server configured with default values.
#           ssh.sh
#
#       For an SFTP server that requires challenge/response authentication for username and password.
#           ssh.sh yes no yes
#

scriptName='ssh.sh'
echo "[$scriptName] --- start ---"

crAuth=$1
passAuth=$2
usePAM=$3
    
if [ -z "$crAuth" ]; then crAuth=no; fi
if [ -z "$passAuth" ]; then passAuth=yes; fi
if [ -z "$usePAM" ]; then usePAM=yes; fi

echo "[$scriptName] SSH Parameters"
echo "  crAuth=$crAuth"
echo "  passAuth=$passAuth"
echo "  usePAM=$usePAM"

# Install from global repositories only supporting CentOS and Ubuntu
echo "[$scriptName] Determine distribution, only Ubuntu/Debian and CentOS/RHEL supported"
uname -a
centos=$(uname -a | grep el)

echo "[$scriptName] Install base software (openssh-server)"
if [ -z "$centos" ]
then
	echo "[$scriptName] Ubuntu/Debian, update repositories using apt-get"
	sudo apt-get update
	sudo apt-get install -y openssh-server
else
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	sudo yum check-update
	sudo yum install -y openssh-server
fi

# Make a readonly backup of the factory defaults.
configFilePath='/etc/ssh/sshd_config'
backupFilePath='/etc/ssh/sshd_config.factory-defaults'

echo "[$scriptName] Taking a read-only backup of ($configFilePath)."
sudo cp -v /etc/ssh/sshd_config /etc/ssh/sshd_config.factory-defaults
sudo chmod -v a-w /etc/ssh/sshd_config.factory-defaults

# Overwrite the configuration file with the template file.
configFileData='IyBQYWNrYWdlIGdlbmVyYXRlZCBjb25maWd1cmF0aW9uIGZpbGUKIyBTZWUgdGhlIHNzaGRfY29uZmlnKDUpIG1hbnBhZ2UgZm9yIGRldGFpbHMKCiMgV2hhdCBwb3J0cywgSVBzIGFuZCBwcm90b2NvbHMgd2UgbGlzdGVuIGZvcgpQb3J0IDIyCiMgVXNlIHRoZXNlIG9wdGlvbnMgdG8gcmVzdHJpY3Qgd2hpY2ggaW50ZXJmYWNlcy9wcm90b2NvbHMgc3NoZCB3aWxsIGJpbmQgdG8KI0xpc3RlbkFkZHJlc3MgOjoKI0xpc3RlbkFkZHJlc3MgMC4wLjAuMApQcm90b2NvbCAyCiMgSG9zdEtleXMgZm9yIHByb3RvY29sIHZlcnNpb24gMgpIb3N0S2V5IC9ldGMvc3NoL3NzaF9ob3N0X3JzYV9rZXkKSG9zdEtleSAvZXRjL3NzaC9zc2hfaG9zdF9kc2Ffa2V5Ckhvc3RLZXkgL2V0Yy9zc2gvc3NoX2hvc3RfZWNkc2Ffa2V5Ckhvc3RLZXkgL2V0Yy9zc2gvc3NoX2hvc3RfZWQyNTUxOV9rZXkKI1ByaXZpbGVnZSBTZXBhcmF0aW9uIGlzIHR1cm5lZCBvbiBmb3Igc2VjdXJpdHkKVXNlUHJpdmlsZWdlU2VwYXJhdGlvbiB5ZXMKCiMgTGlmZXRpbWUgYW5kIHNpemUgb2YgZXBoZW1lcmFsIHZlcnNpb24gMSBzZXJ2ZXIga2V5CktleVJlZ2VuZXJhdGlvbkludGVydmFsIDM2MDAKU2VydmVyS2V5Qml0cyAxMDI0CgojIExvZ2dpbmcKU3lzbG9nRmFjaWxpdHkgQVVUSApMb2dMZXZlbCBJTkZPCgojIEF1dGhlbnRpY2F0aW9uOgpMb2dpbkdyYWNlVGltZSAxMjAKUGVybWl0Um9vdExvZ2luIHdpdGhvdXQtcGFzc3dvcmQKU3RyaWN0TW9kZXMgeWVzCgpSU0FBdXRoZW50aWNhdGlvbiB5ZXMKUHVia2V5QXV0aGVudGljYXRpb24geWVzCiNBdXRob3JpemVkS2V5c0ZpbGUJJWgvLnNzaC9hdXRob3JpemVkX2tleXMKCiMgRG9uJ3QgcmVhZCB0aGUgdXNlcidzIH4vLnJob3N0cyBhbmQgfi8uc2hvc3RzIGZpbGVzCklnbm9yZVJob3N0cyB5ZXMKIyBGb3IgdGhpcyB0byB3b3JrIHlvdSB3aWxsIGFsc28gbmVlZCBob3N0IGtleXMgaW4gL2V0Yy9zc2hfa25vd25faG9zdHMKUmhvc3RzUlNBQXV0aGVudGljYXRpb24gbm8KIyBzaW1pbGFyIGZvciBwcm90b2NvbCB2ZXJzaW9uIDIKSG9zdGJhc2VkQXV0aGVudGljYXRpb24gbm8KIyBVbmNvbW1lbnQgaWYgeW91IGRvbid0IHRydXN0IH4vLnNzaC9rbm93bl9ob3N0cyBmb3IgUmhvc3RzUlNBQXV0aGVudGljYXRpb24KI0lnbm9yZVVzZXJLbm93bkhvc3RzIHllcwoKIyBUbyBlbmFibGUgZW1wdHkgcGFzc3dvcmRzLCBjaGFuZ2UgdG8geWVzIChOT1QgUkVDT01NRU5ERUQpClBlcm1pdEVtcHR5UGFzc3dvcmRzIG5vCgojIENoYW5nZSB0byB5ZXMgdG8gZW5hYmxlIGNoYWxsZW5nZS1yZXNwb25zZSBwYXNzd29yZHMgKGJld2FyZSBpc3N1ZXMgd2l0aAojIHNvbWUgUEFNIG1vZHVsZXMgYW5kIHRocmVhZHMpCkNoYWxsZW5nZVJlc3BvbnNlQXV0aGVudGljYXRpb24gJWNyQXV0aCUKCiMgQ2hhbmdlIHRvIG5vIHRvIGRpc2FibGUgdHVubmVsbGVkIGNsZWFyIHRleHQgcGFzc3dvcmRzClBhc3N3b3JkQXV0aGVudGljYXRpb24gJXBhc3NBdXRoJQoKIyBLZXJiZXJvcyBvcHRpb25zCiNLZXJiZXJvc0F1dGhlbnRpY2F0aW9uIG5vCiNLZXJiZXJvc0dldEFGU1Rva2VuIG5vCiNLZXJiZXJvc09yTG9jYWxQYXNzd2QgeWVzCiNLZXJiZXJvc1RpY2tldENsZWFudXAgeWVzCgojIEdTU0FQSSBvcHRpb25zCiNHU1NBUElBdXRoZW50aWNhdGlvbiBubwojR1NTQVBJQ2xlYW51cENyZWRlbnRpYWxzIHllcwoKWDExRm9yd2FyZGluZyB5ZXMKWDExRGlzcGxheU9mZnNldCAxMApQcmludE1vdGQgbm8KUHJpbnRMYXN0TG9nIHllcwpUQ1BLZWVwQWxpdmUgeWVzCiNVc2VMb2dpbiBubwoKI01heFN0YXJ0dXBzIDEwOjMwOjYwCiNCYW5uZXIgL2V0Yy9pc3N1ZS5uZXQKCiMgQWxsb3cgY2xpZW50IHRvIHBhc3MgbG9jYWxlIGVudmlyb25tZW50IHZhcmlhYmxlcwpBY2NlcHRFbnYgTEFORyBMQ18qCgpTdWJzeXN0ZW0gc2Z0cCAvdXNyL2xpYi9vcGVuc3NoL3NmdHAtc2VydmVyCgojIFNldCB0aGlzIHRvICd5ZXMnIHRvIGVuYWJsZSBQQU0gYXV0aGVudGljYXRpb24sIGFjY291bnQgcHJvY2Vzc2luZywKIyBhbmQgc2Vzc2lvbiBwcm9jZXNzaW5nLiBJZiB0aGlzIGlzIGVuYWJsZWQsIFBBTSBhdXRoZW50aWNhdGlvbiB3aWxsCiMgYmUgYWxsb3dlZCB0aHJvdWdoIHRoZSBDaGFsbGVuZ2VSZXNwb25zZUF1dGhlbnRpY2F0aW9uIGFuZAojIFBhc3N3b3JkQXV0aGVudGljYXRpb24uICBEZXBlbmRpbmcgb24geW91ciBQQU0gY29uZmlndXJhdGlvbiwKIyBQQU0gYXV0aGVudGljYXRpb24gdmlhIENoYWxsZW5nZVJlc3BvbnNlQXV0aGVudGljYXRpb24gbWF5IGJ5cGFzcwojIHRoZSBzZXR0aW5nIG9mICJQZXJtaXRSb290TG9naW4gd2l0aG91dC1wYXNzd29yZCIuCiMgSWYgeW91IGp1c3Qgd2FudCB0aGUgUEFNIGFjY291bnQgYW5kIHNlc3Npb24gY2hlY2tzIHRvIHJ1biB3aXRob3V0CiMgUEFNIGF1dGhlbnRpY2F0aW9uLCB0aGVuIGVuYWJsZSB0aGlzIGJ1dCBzZXQgUGFzc3dvcmRBdXRoZW50aWNhdGlvbgojIGFuZCBDaGFsbGVuZ2VSZXNwb25zZUF1dGhlbnRpY2F0aW9uIHRvICdubycuClVzZVBBTSAldXNlUEFNJQo='
echo "[$scriptName] Writing openssh-server configuration data to $configFilePath"
sudo echo "$configFileData" | base64 --decode > "$configFilePath"

echo "[$scriptName] Detokenizing $configFilePath"
sudo perl -i -pe "s/%crAuth%/$crAuth/g; s/%passAuth%/$passAuth/g; s/%usePAM%/$usePAM/g" "$configFilePath"

echo "[$scriptName] Restart the openssh-server service"
sudo service ssh restart

echo "[$scriptName] --- end ---"
exit 0
