#!/bin/sh
# Author : Akash Rawat (KalWardinX)
# date   : 19/07/2022

# Tests if exactly 2 arguments are passed 
if [ $# -ne 2 ]
then
    echo "#Error"
    echo "Usage: ./writer.sh [writefile] [writestr]"
    exit 1
fi

writefile=$1
writestr=$2

filename=$(echo ${writefile} | rev | cut -f1 -d/ | rev)
directory=$(echo ${writefile} | sed "s/\/${filename}//g")
if [ ! -d ${directory} ]
then
    mkdir -p ${directory}
fi

echo ${writestr} > ${writefile}