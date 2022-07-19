#!/bin/sh
# Author : Akash Rawat (KalWardinX)
# date   : 19/07/2022

# Tests if exactly 2 arguments are passed 
if [ $# -ne 2 ]
then
    echo "#ERROR"
    echo "Usage: ./finder.sh [filesdir] [searchstr]"
    exit 1
fi

filesdir=$1
searchstr=$2

# Tests if files_dir exists and is a dir
if [ ! -d ${filesdir} ]
then
    echo "#Error"
    echo "${filedir} doesn't exist or isn't a directory!!"
    exit 1
else
    no_of_matches=$(grep -r "${searchstr}" "${filesdir}" | wc -l)
    no_of_files=$(grep -r "${searchstr}" "${filesdir}" | cut -f 1 -d: | uniq | wc -l)
    echo "The number of files are ${no_of_files} and the number of matching lines are ${no_of_matches}"
fi