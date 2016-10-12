#
# Script
#   ssh-keyfiles.sh
#
# Description
#   Overwrites default keyfiles for ssh and restarts the ssh service.
#
#   Note that FTPS (FTP over SSL) is not supported.
#
# Usage
#   ssh-keyfiles.sh type privatekeyfile publickeyfile
#       type:           Required. Specify DSA, ECDSA, ED25519, or RSA. Will update the corresponding keyfile pair.
#       privatekeyfile: Required. A base64 encoded string that provides the private keyfile data.
#       publickeyfile:  Required. A base64 encoded string that provides the public keyfile data.
#

scriptName='ssh-keyfiles.sh'
echo "[$scriptName] --- start ---"

type=$1
privatekeyfile=$2
publickeyfile=$3

if [ ${#privatekeyfile} -le 30 ]
then
    privatekeyfileTrunc="$privatekeyfile"
else
    privatekeyfileTrunc="$(echo "$privatekeyfile" | cut -c 1-27)...";
fi

if [ ${#publickeyfile} -le 30 ]
then
    publickeyfileTrunc="$publickeyfile"
else
    publickeyfileTrunc="$(echo "$publickeyfile" | cut -c 1-27)...";
fi

if [ "$type" = "DSA" ]
then
    privatekeyfileName='ssh_host_dsa_key'
    publickeyfileName='ssh_host_dsa_key.pub'
elif [ "$type" = "ECDSA" ]
then
    privatekeyfileName='ssh_host_ecdsa_key'
    publickeyfileName='ssh_host_ecdsa_key.pub'
elif [ "$type" = "ED25519" ]
then
    privatekeyfileName='ssh_host_ed25519_key'
    publickeyfileName='ssh_host_ed25519_key.pub'
elif [ "$type" = "RSA" ]
then
    privatekeyfileName='ssh_host_rsa_key'
    publickeyfileName='ssh_host_rsa_key.pub'
fi

echo "[$scriptName] SSH Keyfile Parameters"
echo "  type:               $type"
echo "  privatekeyfile:     $privatekeyfileTrunc"
echo "  publickeyfile:      $publickeyfileTrunc"
echo "  privatekeyfileName: $privatekeyfileName"
echo "  publickeyfileName:  $publickeyfileName"
    
if [ -z "$type" ] || [ -z "$privatekeyfile" ] || [ -z "$publickeyfile" ]
then
    >&2 echo "[$scriptName] The arguments for type, privatekeyfile and publickeyfile are all required. Please refer to $scriptName inline documentation for usage"
    exit 1
fi

if [ "$type" != "DSA" ] && [ "$type" != "ECDSA" ] && [ "$type" != "ED25519" ] && [ "$type" != "RSA" ]
then
    >&2 echo "[$scriptName] The supplied value of \"$type\" for type is invalid. Only the following values are accepted: DSA, ECDSA, ED25519, RSA"
    exit 1
fi

privatekeyfilePath="/etc/ssh/$privatekeyfileName"
publickeyfilePath="/etc/ssh/$publickeyfileName"

privatekeyfileBackupPath="/etc/ssh/$privatekeyfileName.original"
publickeyfileBackupPath="/etc/ssh/$publickeyfileName.original"

echo "[$scriptName] Taking a read-only backup of original $privatekeyfileName"
sudo cp -v "$privatekeyfilePath" "$privatekeyfileBackupPath"
sudo chmod -v a-w "$privatekeyfileBackupPath"

echo "[$scriptName] Taking a read-only backup of original $publickeyfilePath"
sudo cp -v "$publickeyfilePath" "$publickeyfileBackupPath"
sudo chmod -v a-w "$publickeyfileBackupPath"

echo "[$scriptName] Writing privatekeyfile data to $privatekeyfilePath"
sudo echo "$privatekeyfile" | base64 --decode > "$privatekeyfilePath"

echo "[$scriptName] Writing privatekeyfile data to $publickeyfilePath"
sudo echo "$publickeyfile" | base64 --decode > "$publickeyfilePath"

echo "[$scriptName] Restart the openssh-server service"
sudo service ssh restart

echo "[$scriptName] --- end ---"
exit 0
