#
# Script
#   skel.sh
#
# Description
#   Configures a resource under the /etc/skel directory. Purpose is to specify the default folder layout for new users.
#
# Usage
#   skel.sh type path [data]
#       type: FILE or DIR. Required.
#       path: The path of the resource to be created. Required.
#       data: The data of a file to be created in Base64 encoding.
#               Ignored under DIR.
#               Optional under FILE.
#                 If omitted under FILE, an empty file will be created.
#
#   Examples
#       For the folder path /etc/skel/QA/AUDIT
#           skel.sh DIR QA/AUDIT
#
#       For a file under path /etc/skel/readme.txt
#           skel.sh FILE readme.txt Base64DataString==
#
#       For an empty file under path /etc/skel/QA/default.csv
#           skel.sh FILE QA/default.csv
#

scriptName='skel.sh'
echo "[$scriptName] --- start ---"

type=$1
path=$2
data=$3

if [ ${#data} -le 10 ]
then
    dataOutput="$data"
else
    dataOutput="$(echo "$data" | cut -c 0-7)...";
fi

echo "[$scriptName] Parameters"
echo "  type: $type"
echo "  path: $path"
echo "  data: $dataOutput"

if [ -z "$type" ]
then
    >&2 echo "[$scriptName] The type argument is required."
    exit 1
fi

if [ -z "$path" ]
then
    >&2 echo "[$scriptName] The path argument is required."
    exit 1    
fi

if [ "$type" != "FILE" ] && [ "$type" != "DIR" ]
then
    >&2 echo "[$scriptName] Valid values for type are 'FILE' and 'DIR'. Submitted value of '$type' is invalid."
    exit 1
fi

if [ "$type" = "DIR" ]
then    
    dirpath="/etc/skel/$path"
    
    if [ -d "$dirpath" ]
    then
        echo "[$scriptName] The directory $dirpath already exists!"  
        
        echo "[$scriptName] --- end ---"
        exit 0
    fi
    
    echo "[$scriptName] Creating directory $dirpath"
    sudo mkdir --verbose --parents "$dirpath"
    
    echo "[$scriptName] --- end ---"
    exit 0
fi

if [ "$type" = "FILE" ]
then
    filepath="/etc/skel/$path"
    dirpath=$(dirname "$filepath")
        
    if [ ! -d "$dirpath" ]
    then
        echo "[$scriptName] Creating directory $dirpath"
        sudo mkdir --verbose --parents "$dirpath"
    fi
    
    if [ -n "$data" ]
    then        
        echo "[$scriptName] Creating file from supplied data at: $filepath"
        echo "$data" | base64 --decode > "$filepath"
    
        echo "[$scriptName] --- end ---"
        exit 0
    else        
        echo "[$scriptName] Creating empty file $filepath"
        touch "$filepath"
    
        echo "[$scriptName] --- end ---"
        exit 0
    fi
fi

echo "[$scriptName] --- end ---"
exit 0
