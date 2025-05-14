#!/usr/bin/env bash
function executeExpression {
	echo "[$scriptName]   $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  
scriptName='extendDisk.sh'
echo
echo "[$scriptName] --- start ---"
diskdevice=$1
if [ -z "$diskdevice" ]; then
	diskdevice='/dev/sdb'
	echo "[$scriptName]   diskdevice : $diskdevice (default)"
else
	echo "[$scriptName]   diskdevice : $diskdevice"
fi

vgName=$2
if [ -z "$vgName" ]; then
	groups=$(sudo vgdisplay -s)
	IFS=' ' read -ra ADDR <<< $groups
	vgName=${ADDR[0]}
	vgName="${vgName%\"}"
	vgName="${vgName#\"}"
	echo "[$scriptName]   vgName     : $vgName (derived from vgdisplay)"
else
	echo "[$scriptName]   vgName     : $vgName"
fi
echo
echo "[$scriptName] List the disk devices before partitioning"
executeExpression "ls -l /dev/sd*"
echo
echo "[$scriptName] List disk capacity"
executeExpression "df"
echo
echo "[$scriptName] List Volume Groups (VG)"
executeExpression "sudo vgdisplay -s"

if [ -f /etc/disk_added_date ]
then
   echo "[$scriptName] disk already added so exiting."
   exit 0
fi
echo
echo "[$scriptName] Create a new (n) primary partition (p) for entire capacity of disk"
sudo fdisk -u $diskdevice <<EOF
n
p
1


t
8e
w
EOF
# (t) is selected to change to a partitions system ID, (8e) hex code shows that it is a Linux LVM
echo
echo "[$scriptName] List partitioned disk"
executeExpression "sudo fdisk -l $diskdevice"
echo
echo "[$scriptName] List disks physical volumes (PV)"
executeExpression "sudo pvscan"
echo
echo "[$scriptName] Add disk to the Logical Volume (${vgName})"
# References to 1 is the partition number, as per fdisk above
executeExpression "sudo pvcreate ${diskdevice}1"
executeExpression "sudo vgextend ${vgName} ${diskdevice}1"

# Derive LVM path from DF, e.g. /dev/mapper/ubuntuLVM--vg-root
# Perhaps it is /dev/${vgName}/lv_root
# This is wrong but for the life of me I cannot get path from Volume Group
#lvmPath=$(df | grep $vgName)
lvmPath=$(df | grep 'root')
IFS=' ' read -ra ADDR <<< $lvmPath
lvmPath=${ADDR[0]}

executeExpression "sudo lvextend ${lvmPath} ${diskdevice}1"
executeExpression "sudo resize2fs ${lvmPath}"
echo
echo "[$scriptName] List the disk devices after partitioning"
executeExpression "ls -l /dev/sd*"
echo
echo "[$scriptName] List disk capacity after"
executeExpression "df"
echo
echo "[$scriptName] Create a marker to avoid duplicate attempt"
date > /etc/disk_added_date
echo
echo "[$scriptName] --- end ---"
