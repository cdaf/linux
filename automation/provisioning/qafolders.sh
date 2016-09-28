#
# Script
#   qafolders.sh
#
# Current Version
#   v1.0
#
# Description
#   Creates a default QA folder structure under the supplied user's home directory. The vagrant user is presumed if omitted.
#
# Dependencies
#   This script presumes Ubuntu/Debian. CentOS/RHEL may not be supported - untested at time of writing.
#
# Arguments
#   qafolders.sh [user]
#
#   user: Optional
#     The name of the user under which to create the QA folder structure. If omitted the default value of 'vagrant' will be used.
#
# Contributors
#   Daniel Schealler, daniel.schealler@gmail.com
#
# Version History
#   Date        Version  Author            Comments
#   2016-09-16  v1.0     Daniel Schealler  First Cut
#

scriptName='qafolders.sh'
echo "[$scriptName] --- start ---"

user=$1
echo "[$scriptName] user: $user"

if [ -z $user ]
then
    echo "[$scriptName] No user submitted. Setting to default value: vagrant"
    user="vagrant";
fi

echo "[$scriptName] user: $user"

echo "[$scriptName] Creating QA folders for user"
mkdir -v /home/$user/QA
mkdir -v /home/$user/QA/AUDIT
mkdir -v /home/$user/QA/ERROR
mkdir -v /home/$user/QA/TEMP

echo "[$scriptName] Changing ownership of QA folders to user"
sudo chown -R -v $user /home/$user/QA

echo "[$scriptName] --- end ---"
